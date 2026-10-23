import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../core/constants/app_constants.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';
import 'mock_data_service.dart';

// ---------------------------------------------------------------------------
// Result types
// ---------------------------------------------------------------------------

class OrderValidationResult {
  final bool isValid;
  final String? errorMessage;
  final double verifiedSubtotal;
  final double verifiedTax;
  final double verifiedDeliveryFee;
  final double verifiedTotalAmount;
  final List<OrderItem> verifiedItems;

  OrderValidationResult({
    required this.isValid,
    this.errorMessage,
    required this.verifiedSubtotal,
    required this.verifiedTax,
    required this.verifiedDeliveryFee,
    required this.verifiedTotalAmount,
    required this.verifiedItems,
  });
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

class OrderService {
  FirebaseFirestore? _firestore;

  FirebaseFirestore get firestore {
    _firestore ??= FirebaseFirestore.instance;
    return _firestore!;
  }

  bool get _isFirebaseAvailable {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // 1. Trusted Backend Validation
  //    All security checks happen here — NOT only in the UI.
  // ---------------------------------------------------------------------------
  OrderValidationResult validateOrder({
    required UserModel user,
    required List<CartItemModel> cartItems,
    required List<ProductModel> trustedCatalog,
    required double claimedTotal,
  }) {
    // ── Dealer authorization check (Firestore rules mirror this) ────────────
    // A dealer whose KYC is pending or rejected MUST NOT place wholesale orders.
    if (user.role == UserRole.dealer) {
      final dealerStatus = user.dealerProfile?.status ?? 'pending';
      if (dealerStatus != 'approved') {
        return OrderValidationResult(
          isValid: false,
          errorMessage:
              dealerStatus == 'rejected'
                  ? 'Your dealer application was rejected. Contact Califnco support to re-apply.'
                  : 'Your dealer account is pending Admin approval. You cannot place wholesale orders yet.',
          verifiedSubtotal: 0,
          verifiedTax: 0,
          verifiedDeliveryFee: 0,
          verifiedTotalAmount: 0,
          verifiedItems: [],
        );
      }
    }

    // ── Empty cart ──────────────────────────────────────────────────────────
    if (cartItems.isEmpty) {
      return OrderValidationResult(
        isValid: false,
        errorMessage: 'Cannot place order: Cart is empty.',
        verifiedSubtotal: 0,
        verifiedTax: 0,
        verifiedDeliveryFee: 0,
        verifiedTotalAmount: 0,
        verifiedItems: [],
      );
    }

    double computedSubtotal = 0.0;
    final List<OrderItem> orderItems = [];

    for (final item in cartItems) {
      // ── Locate product in trusted catalog (tamper protection) ───────────
      final ProductModel trustedProduct;
      try {
        trustedProduct = trustedCatalog.firstWhere((p) => p.id == item.product.id);
      } catch (_) {
        return OrderValidationResult(
          isValid: false,
          errorMessage: 'Product "${item.product.title}" not found in catalog.',
          verifiedSubtotal: 0,
          verifiedTax: 0,
          verifiedDeliveryFee: 0,
          verifiedTotalAmount: 0,
          verifiedItems: [],
        );
      }

      // ── Stock check ───────────────────────────────────────────────────
      if (trustedProduct.stockQuantity < item.quantity) {
        return OrderValidationResult(
          isValid: false,
          errorMessage:
              'Insufficient stock for "${trustedProduct.title}". '
              'Only ${trustedProduct.stockQuantity} units available.',
          verifiedSubtotal: 0,
          verifiedTax: 0,
          verifiedDeliveryFee: 0,
          verifiedTotalAmount: 0,
          verifiedItems: [],
        );
      }

      // ── Price selection (tamper-proof from server catalog) ────────────
      // SECURITY: Customers are ALWAYS charged retail, even if isWholesale
      // flag was tampered on client side.
      final bool isWholesaleOrder =
          user.role == UserRole.dealer &&
          item.isWholesale &&
          (user.dealerProfile?.status ?? '') == 'approved';

      final double verifiedUnitPrice =
          isWholesaleOrder ? trustedProduct.wholesalePrice : trustedProduct.retailPrice;

      // ── Wholesale MOQ validation ──────────────────────────────────────
      if (isWholesaleOrder && item.quantity < trustedProduct.wholesaleMoq) {
        return OrderValidationResult(
          isValid: false,
          errorMessage:
              '"${trustedProduct.title}" requires a minimum wholesale '
              'order quantity of ${trustedProduct.wholesaleMoq} units.',
          verifiedSubtotal: 0,
          verifiedTax: 0,
          verifiedDeliveryFee: 0,
          verifiedTotalAmount: 0,
          verifiedItems: [],
        );
      }

      final lineTotal = verifiedUnitPrice * item.quantity;
      computedSubtotal += lineTotal;

      orderItems.add(OrderItem(
        productId: trustedProduct.id,
        title: trustedProduct.title,
        imageUrl: trustedProduct.imageUrl,
        quantity: item.quantity,
        unitPrice: verifiedUnitPrice,
        totalPrice: lineTotal,
        isWholesale: isWholesaleOrder,
      ));
    }

    // ── GST (18%) + delivery ───────────────────────────────────────────────
    final computedTax = computedSubtotal * AppConstants.gstRate;
    final computedDelivery = computedSubtotal > 1000 ? 0.0 : 99.0;
    final computedGrandTotal = computedSubtotal + computedTax + computedDelivery;

    // ── Price-tamper guard (≤₹0.05 floating-point tolerance) ─────────────
    if ((computedGrandTotal - claimedTotal).abs() > 0.05) {
      return OrderValidationResult(
        isValid: false,
        errorMessage:
            'Price verification mismatch. '
            'Server computed ₹${computedGrandTotal.toStringAsFixed(2)} '
            'but received ₹${claimedTotal.toStringAsFixed(2)}.',
        verifiedSubtotal: computedSubtotal,
        verifiedTax: computedTax,
        verifiedDeliveryFee: computedDelivery,
        verifiedTotalAmount: computedGrandTotal,
        verifiedItems: orderItems,
      );
    }

    return OrderValidationResult(
      isValid: true,
      verifiedSubtotal: computedSubtotal,
      verifiedTax: computedTax,
      verifiedDeliveryFee: computedDelivery,
      verifiedTotalAmount: computedGrandTotal,
      verifiedItems: orderItems,
    );
  }

  // ---------------------------------------------------------------------------
  // 2. Create & Persist Order (with atomic stock decrement)
  // ---------------------------------------------------------------------------
  Future<OrderModel> createAndPersistOrder({
    required UserModel user,
    required List<CartItemModel> cartItems,
    required List<ProductModel> trustedCatalog,
    required double claimedTotal,
    required UserAddress shippingAddress,
    required String paymentMethod,
    String? razorpayPaymentId,
  }) async {
    // SECURITY: Never accept raw card numbers — only tokenized Razorpay IDs.

    final validation = validateOrder(
      user: user,
      cartItems: cartItems,
      trustedCatalog: trustedCatalog,
      claimedTotal: claimedTotal,
    );

    if (!validation.isValid) {
      throw OrderException(validation.errorMessage ?? 'Order validation failed.');
    }

    final ts = DateTime.now();
    final orderId = 'ord-${ts.millisecondsSinceEpoch}';
    final orderNumber =
        'AQ-${ts.year}-${(1000 + ts.millisecondsSinceEpoch % 9000)}';

    // Persist to Firestore including dealerId field for scoped history queries.
    final order = OrderModel(
      id: orderId,
      orderNumber: orderNumber,
      userId: user.uid,
      dealerId: user.role == UserRole.dealer ? user.uid : null,
      dealerCompanyName: user.dealerProfile?.companyName,
      wholesaleTier: user.dealerProfile?.wholesaleTier,
      userRole: user.role,
      items: validation.verifiedItems,
      subtotal: validation.verifiedSubtotal,
      tax: validation.verifiedTax,
      deliveryFee: validation.verifiedDeliveryFee,
      totalAmount: validation.verifiedTotalAmount,
      shippingAddress: shippingAddress,
      paymentStatus: PaymentStatus.paid,
      paymentMethod: paymentMethod,
      razorpayPaymentId: razorpayPaymentId,
      orderStatus: OrderStatus.placed,
      createdAt: ts,
      estimatedDelivery: ts.add(
        user.role == UserRole.dealer
            ? const Duration(days: 5) // Bulk dispatch takes longer
            : const Duration(days: 3),
      ),
    );

    if (_isFirebaseAvailable) {
      try {
        final batch = firestore.batch();

        // Save order document (Firestore rules enforce userId == auth.uid)
        final orderDoc = firestore.collection('orders').doc(order.id);
        batch.set(orderDoc, order.toMap());

        // Atomic stock decrement for each ordered SKU
        for (final item in validation.verifiedItems) {
          final prodDoc = firestore.collection('products').doc(item.productId);
          batch.update(prodDoc, {
            'stockQuantity': FieldValue.increment(-item.quantity),
          });
        }

        await batch.commit();
      } catch (e) {
        throw OrderException('Failed to persist order to Firestore: $e');
      }
    }

    return order;
  }

  // ---------------------------------------------------------------------------
  // 3. Fetch Order History — scoped strictly to the requesting user's UID
  //    Dealers see only their own wholesale orders.
  // ---------------------------------------------------------------------------
  Future<List<OrderModel>> fetchOrdersForUser(String userId) async {
    if (!_isFirebaseAvailable) {
      return MockDataService.mockOrders
          .where((o) => o.userId == userId)
          .toList();
    }

    try {
      final snapshot = await firestore
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => OrderModel.fromMap(doc.data())).toList();
    } catch (e) {
      throw OrderException('Failed to load order history: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // 4. Fetch ALL orders (Admin only) — enforced at Firestore rules level too
  // ---------------------------------------------------------------------------
  Future<List<OrderModel>> fetchAllOrdersForAdmin() async {
    if (!_isFirebaseAvailable) {
      return List.from(MockDataService.mockOrders);
    }

    try {
      final snapshot = await firestore
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => OrderModel.fromMap(doc.data())).toList();
    } catch (e) {
      throw OrderException('Failed to load all orders: $e');
    }
  }
}

class OrderException implements Exception {
  final String message;
  OrderException(this.message);
  @override
  String toString() => message;
}
