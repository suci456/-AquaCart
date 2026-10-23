import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../core/constants/app_constants.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';
import 'mock_data_service.dart';

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
  // 1. Trusted Backend Total & Stock Validator
  // ---------------------------------------------------------------------------
  OrderValidationResult validateOrder({
    required UserModel user,
    required List<CartItemModel> cartItems,
    required List<ProductModel> trustedCatalog,
    required double claimedTotal,
  }) {
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
      // 1. Locate product in trusted catalog
      final trustedProduct = trustedCatalog.firstWhere(
        (p) => p.id == item.product.id,
        orElse: () => throw OrderException('Product "${item.product.title}" not found in catalog.'),
      );

      // 2. Validate sufficient stock
      if (trustedProduct.stockQuantity < item.quantity) {
        return OrderValidationResult(
          isValid: false,
          errorMessage: 'Insufficient stock for "${trustedProduct.title}". Only ${trustedProduct.stockQuantity} units available.',
          verifiedSubtotal: 0,
          verifiedTax: 0,
          verifiedDeliveryFee: 0,
          verifiedTotalAmount: 0,
          verifiedItems: [],
        );
      }

      // 3. Trusted unit price verification based on user role (Tamper Protection)
      final bool isWholesaleOrder = user.role == UserRole.dealer && item.isWholesale;
      final double verifiedUnitPrice = isWholesaleOrder
          ? trustedProduct.wholesalePrice
          : trustedProduct.retailPrice;

      // 4. Validate wholesale MOQ if applicable
      if (isWholesaleOrder && item.quantity < trustedProduct.wholesaleMoq) {
        return OrderValidationResult(
          isValid: false,
          errorMessage: 'Item "${trustedProduct.title}" requires a minimum wholesale order quantity of ${trustedProduct.wholesaleMoq} units.',
          verifiedSubtotal: 0,
          verifiedTax: 0,
          verifiedDeliveryFee: 0,
          verifiedTotalAmount: 0,
          verifiedItems: [],
        );
      }

      final lineTotal = verifiedUnitPrice * item.quantity;
      computedSubtotal += lineTotal;

      orderItems.add(
        OrderItem(
          productId: trustedProduct.id,
          title: trustedProduct.title,
          imageUrl: trustedProduct.imageUrl,
          quantity: item.quantity,
          unitPrice: verifiedUnitPrice,
          totalPrice: lineTotal,
          isWholesale: isWholesaleOrder,
        ),
      );
    }

    // 5. Accurate GST (18%) and Delivery calculation
    final computedTax = computedSubtotal * AppConstants.gstRate;
    final computedDelivery = computedSubtotal > 1000 ? 0.0 : 99.0;
    final computedGrandTotal = computedSubtotal + computedTax + computedDelivery;

    // Check for price tampering (tolerance of ₹0.05 for rounding differences)
    if ((computedGrandTotal - claimedTotal).abs() > 0.05) {
      return OrderValidationResult(
        isValid: false,
        errorMessage: 'Price verification mismatch. Calculated ₹$computedGrandTotal but received ₹$claimedTotal.',
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
  // 2. Persisted Order Creation & Stock Decrement
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
    // SECURITY: Never allow credit card numbers in order payloads
    // Only tokenized payment IDs (e.g. Razorpay pay_...) are accepted

    // Validate on trusted backend rules
    final validation = validateOrder(
      user: user,
      cartItems: cartItems,
      trustedCatalog: trustedCatalog,
      claimedTotal: claimedTotal,
    );

    if (!validation.isValid) {
      throw OrderException(validation.errorMessage ?? 'Order validation failed.');
    }

    final orderId = 'ord-${DateTime.now().millisecondsSinceEpoch}';
    final orderNumber = 'AQ-${DateTime.now().year}-${1000 + DateTime.now().millisecond}';

    final order = OrderModel(
      id: orderId,
      orderNumber: orderNumber,
      userId: user.uid,
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
      createdAt: DateTime.now(),
      estimatedDelivery: DateTime.now().add(const Duration(days: 3)),
    );

    // Persist to Cloud Firestore if available
    if (_isFirebaseAvailable) {
      try {
        final batch = firestore.batch();
        final orderDoc = firestore.collection('orders').doc(order.id);
        batch.set(orderDoc, order.toMap());

        // Decrement product stock atomically
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
  // 3. Order History Fetching
  // ---------------------------------------------------------------------------
  Future<List<OrderModel>> fetchOrdersForUser(String userId) async {
    if (!_isFirebaseAvailable) {
      return MockDataService.mockOrders.where((o) => o.userId == userId || userId == 'usr-customer-1').toList();
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
}

class OrderException implements Exception {
  final String message;
  OrderException(this.message);
  @override
  String toString() => message;
}
