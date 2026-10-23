import 'package:flutter/foundation.dart';
import '../core/constants/app_constants.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';
import '../models/cart_item_model.dart';
import '../services/mock_data_service.dart';

class OrderProvider extends ChangeNotifier {
  final List<OrderModel> _orders = List.from(MockDataService.mockOrders);

  List<OrderModel> get allOrders => _orders;

  List<OrderModel> getOrdersForUser(String userId) {
    return _orders.where((o) => o.userId == userId).toList();
  }

  OrderModel? getOrderById(String orderId) {
    try {
      return _orders.firstWhere((o) => o.id == orderId);
    } catch (_) {
      return null;
    }
  }

  // Create a new order upon checkout completion
  Future<OrderModel> placeOrder({
    required UserModel user,
    required List<CartItemModel> cartItems,
    required double subtotal,
    required double tax,
    required double deliveryFee,
    required double totalAmount,
    required UserAddress shippingAddress,
    required String paymentMethod,
    String? razorpayPaymentId,
  }) async {
    final orderId = 'ord-${DateTime.now().millisecondsSinceEpoch}';
    final orderNumber = 'AQ-${DateTime.now().year}-${(1000 + _orders.length + 1)}';

    final orderItems = cartItems.map((item) {
      return OrderItem(
        productId: item.product.id,
        title: item.product.title,
        imageUrl: item.product.imageUrl,
        quantity: item.quantity,
        unitPrice: item.unitPrice,
        totalPrice: item.totalPrice,
        isWholesale: item.isWholesale,
      );
    }).toList();

    final newOrder = OrderModel(
      id: orderId,
      orderNumber: orderNumber,
      userId: user.uid,
      userRole: user.role,
      items: orderItems,
      subtotal: subtotal,
      tax: tax,
      deliveryFee: deliveryFee,
      totalAmount: totalAmount,
      shippingAddress: shippingAddress,
      paymentStatus: PaymentStatus.paid,
      paymentMethod: paymentMethod,
      razorpayPaymentId: razorpayPaymentId,
      orderStatus: OrderStatus.placed,
      createdAt: DateTime.now(),
      estimatedDelivery: DateTime.now().add(const Duration(days: 3)),
    );

    _orders.insert(0, newOrder);
    notifyListeners();
    return newOrder;
  }

  // Admin capability: Update order progress
  void updateOrderStatus(String orderId, OrderStatus newStatus) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      final current = _orders[index];
      _orders[index] = OrderModel(
        id: current.id,
        orderNumber: current.orderNumber,
        userId: current.userId,
        userRole: current.userRole,
        items: current.items,
        subtotal: current.subtotal,
        discount: current.discount,
        tax: current.tax,
        deliveryFee: current.deliveryFee,
        totalAmount: current.totalAmount,
        shippingAddress: current.shippingAddress,
        paymentStatus: current.paymentStatus,
        paymentMethod: current.paymentMethod,
        razorpayPaymentId: current.razorpayPaymentId,
        orderStatus: newStatus,
        createdAt: current.createdAt,
        estimatedDelivery: current.estimatedDelivery,
      );
      notifyListeners();
    }
  }
}
