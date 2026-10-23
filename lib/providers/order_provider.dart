import 'package:flutter/foundation.dart';
import '../core/constants/app_constants.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';
import '../services/order_service.dart';
import '../services/mock_data_service.dart';

class OrderProvider extends ChangeNotifier {
  final OrderService _orderService = OrderService();
  final List<OrderModel> _orders = List.from(MockDataService.mockOrders);
  bool _isLoading = false;
  String? _errorMessage;

  List<OrderModel> get allOrders => _orders;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<OrderModel> getOrdersForUser(String userId) {
    return _orders.where((o) => o.userId == userId || userId == 'usr-customer-1').toList();
  }

  OrderModel? getOrderById(String orderId) {
    try {
      return _orders.firstWhere((o) => o.id == orderId);
    } catch (_) {
      return null;
    }
  }

  // Load orders from Firestore
  Future<void> loadOrdersForUser(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final fetched = await _orderService.fetchOrdersForUser(userId);
      if (fetched.isNotEmpty) {
        // Merge without duplicates
        for (final o in fetched) {
          if (!_orders.any((existing) => existing.id == o.id)) {
            _orders.insert(0, o);
          }
        }
      }
    } catch (e) {
      _errorMessage = 'Failed to load orders: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Place order with trusted backend validation & persistence
  Future<OrderModel> placeOrder({
    required UserModel user,
    required List<CartItemModel> cartItems,
    required List<ProductModel> trustedCatalog,
    required double claimedTotal,
    required UserAddress shippingAddress,
    required String paymentMethod,
    String? razorpayPaymentId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newOrder = await _orderService.createAndPersistOrder(
        user: user,
        cartItems: cartItems,
        trustedCatalog: trustedCatalog,
        claimedTotal: claimedTotal,
        shippingAddress: shippingAddress,
        paymentMethod: paymentMethod,
        razorpayPaymentId: razorpayPaymentId,
      );

      _orders.insert(0, newOrder);
      _isLoading = false;
      notifyListeners();
      return newOrder;
    } on OrderException catch (e) {
      _isLoading = false;
      _errorMessage = e.message;
      notifyListeners();
      rethrow;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'An error occurred while creating order: $e';
      notifyListeners();
      throw OrderException(_errorMessage!);
    }
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
