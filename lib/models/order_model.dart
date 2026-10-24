import '../core/constants/app_constants.dart';
import 'user_model.dart';

class OrderItem {
  final String productId;
  final String title;
  final String imageUrl;
  final String? localAssetImage;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final bool isWholesale;

  OrderItem({
    required this.productId,
    required this.title,
    required this.imageUrl,
    this.localAssetImage,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.isWholesale = false,
  });

  bool get hasLocalAsset => localAssetImage != null && localAssetImage!.isNotEmpty;

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'] ?? '',
      title: map['title'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      localAssetImage: map['localAssetImage'],
      quantity: map['quantity'] ?? 1,
      unitPrice: (map['unitPrice'] ?? 0.0).toDouble(),
      totalPrice: (map['totalPrice'] ?? 0.0).toDouble(),
      isWholesale: map['isWholesale'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'title': title,
      'imageUrl': imageUrl,
      'localAssetImage': localAssetImage,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'isWholesale': isWholesale,
    };
  }
}

class OrderModel {
  final String id;
  final String orderNumber;
  final String userId; // Always the auth UID of whoever placed the order
  final UserRole userRole;

  // ── Dealer-specific fields (null for customer orders) ───────────────────
  /// Same as userId when placed by a dealer — stored redundantly for
  /// indexed Firestore queries on the `orders` collection.
  final String? dealerId;
  final String? dealerCompanyName;
  final String? wholesaleTier;

  final List<OrderItem> items;
  final double subtotal;
  final double discount;
  final double tax; // 18% GST
  final double deliveryFee;
  final double totalAmount;
  final UserAddress shippingAddress;
  final PaymentStatus paymentStatus;
  final String paymentMethod; // 'razorpay_test', 'cod', 'dealer_credit'
  final String? razorpayPaymentId;
  final OrderStatus orderStatus;
  final DateTime createdAt;
  final DateTime? estimatedDelivery;

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.userId,
    required this.userRole,
    this.dealerId,
    this.dealerCompanyName,
    this.wholesaleTier,
    required this.items,
    required this.subtotal,
    this.discount = 0.0,
    required this.tax,
    this.deliveryFee = 0.0,
    required this.totalAmount,
    required this.shippingAddress,
    this.paymentStatus = PaymentStatus.paid,
    this.paymentMethod = 'razorpay_test',
    this.razorpayPaymentId,
    this.orderStatus = OrderStatus.placed,
    required this.createdAt,
    this.estimatedDelivery,
  });

  bool get isWholesaleOrder => userRole == UserRole.dealer && dealerId != null;

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      id: map['id'] ?? '',
      orderNumber: map['orderNumber'] ?? '',
      userId: map['userId'] ?? '',
      userRole: map['userRole'] == 'dealer'
          ? UserRole.dealer
          : map['userRole'] == 'admin'
              ? UserRole.admin
              : UserRole.customer,
      dealerId: map['dealerId'],
      dealerCompanyName: map['dealerCompanyName'],
      wholesaleTier: map['wholesaleTier'],
      items: (map['items'] as List<dynamic>?)
              ?.map((item) => OrderItem.fromMap(Map<String, dynamic>.from(item)))
              .toList() ??
          [],
      subtotal: (map['subtotal'] ?? 0.0).toDouble(),
      discount: (map['discount'] ?? 0.0).toDouble(),
      tax: (map['tax'] ?? 0.0).toDouble(),
      deliveryFee: (map['deliveryFee'] ?? 0.0).toDouble(),
      totalAmount: (map['totalAmount'] ?? 0.0).toDouble(),
      shippingAddress: UserAddress.fromMap(
        Map<String, dynamic>.from(map['shippingAddress'] ?? {}),
      ),
      paymentStatus: _parsePaymentStatus(map['paymentStatus']),
      paymentMethod: map['paymentMethod'] ?? 'razorpay_test',
      razorpayPaymentId: map['razorpayPaymentId'],
      orderStatus: _parseOrderStatus(map['orderStatus']),
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      estimatedDelivery: map['estimatedDelivery'] != null
          ? DateTime.tryParse(map['estimatedDelivery'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderNumber': orderNumber,
      'userId': userId,
      'userRole': userRole.name,
      'dealerId': dealerId,
      'dealerCompanyName': dealerCompanyName,
      'wholesaleTier': wholesaleTier,
      'items': items.map((i) => i.toMap()).toList(),
      'subtotal': subtotal,
      'discount': discount,
      'tax': tax,
      'deliveryFee': deliveryFee,
      'totalAmount': totalAmount,
      'shippingAddress': shippingAddress.toMap(),
      'paymentStatus': paymentStatus.name,
      'paymentMethod': paymentMethod,
      'razorpayPaymentId': razorpayPaymentId,
      'orderStatus': orderStatus.name,
      'createdAt': createdAt.toIso8601String(),
      'estimatedDelivery': estimatedDelivery?.toIso8601String(),
    };
  }

  static PaymentStatus _parsePaymentStatus(dynamic s) {
    for (var val in PaymentStatus.values) {
      if (val.name == s) return val;
    }
    return PaymentStatus.pending;
  }

  static OrderStatus _parseOrderStatus(dynamic s) {
    for (var val in OrderStatus.values) {
      if (val.name == s) return val;
    }
    return OrderStatus.placed;
  }
}
