import 'package:flutter_test/flutter_test.dart';
import 'package:aquacart/core/constants/app_constants.dart';
import 'package:aquacart/models/product_model.dart';
import 'package:aquacart/models/cart_item_model.dart';
import 'package:aquacart/models/user_model.dart';
import 'package:aquacart/models/order_model.dart';
import 'package:aquacart/services/order_service.dart';
import 'package:aquacart/services/firestore_service.dart';
import 'package:aquacart/services/mock_data_service.dart';
import 'package:aquacart/providers/auth_provider.dart';
import 'package:aquacart/providers/order_provider.dart';

ProductModel _createTestProduct({
  required String id,
  required double retail,
  required double wholesale,
  int stock = 100,
  int moq = 5,
}) {
  return ProductModel(
    id: id,
    title: 'Test Purifier $id',
    subtitle: 'High capacity RO',
    description: 'Unit test product description',
    category: ProductCategory.roPurifiers,
    mrp: retail * 1.25,
    retailPrice: retail,
    wholesalePrice: wholesale,
    wholesaleMoq: moq,
    stockQuantity: stock,
    imageUrl: 'https://example.com/p.jpg',
    rating: 4.8,
    specs: ProductSpecs(),
  );
}

void main() {
  group('Dealer Wholesale Authorization & Gate Tests', () {
    late OrderService orderService;
    late ProductModel testProduct;
    late List<ProductModel> catalog;

    setUp(() {
      orderService = OrderService();
      testProduct = _createTestProduct(
        id: 'prod-test-01',
        retail: 15000.0,
        wholesale: 9500.0,
        stock: 50,
        moq: 5,
      );
      catalog = [testProduct];
    });

    test('Pending dealer is strictly BLOCKED from placing orders', () {
      final pendingDealer = AuthServiceMockData.demoPendingDealer;

      final items = [
        CartItemModel(
          product: testProduct,
          quantity: 10,
          isWholesale: true,
        ),
      ];

      expect(
        () => orderService.validateOrder(
          user: pendingDealer,
          cartItems: items,
          trustedCatalog: catalog,
          claimedTotal: 100000.0,
        ),
        throwsA(
          isA<OrderException>().having(
            (e) => e.message,
            'message',
            contains('pending Admin approval'),
          ),
        ),
      );
    });

    test('Rejected dealer is strictly BLOCKED from placing orders', () {
      final rejectedDealer = AuthServiceMockData.demoRejectedDealer;

      final items = [
        CartItemModel(
          product: testProduct,
          quantity: 10,
          isWholesale: true,
        ),
      ];

      expect(
        () => orderService.validateOrder(
          user: rejectedDealer,
          cartItems: items,
          trustedCatalog: catalog,
          claimedTotal: 100000.0,
        ),
        throwsA(
          isA<OrderException>().having(
            (e) => e.message,
            'message',
            contains('rejected'),
          ),
        ),
      );
    });

    test('Approved dealer with valid MOQ and matching claimed total succeeds', () {
      final approvedDealer = AuthServiceMockData.demoDealer;

      // 10 units of testProduct @ wholesale (₹9,500)
      // Subtotal = 10 * 9,500 = 95,000
      // Tax (18% GST) = 95,000 * 0.18 = 17,100
      // Delivery fee = 0 (orders >= ₹999 are free)
      // Total = 95,000 + 17,100 = 1,12,100
      const subtotal = 95000.0;
      final tax = (subtotal * 0.18).roundToDouble();
      final expectedTotal = subtotal + tax;

      final items = [
        CartItemModel(
          product: testProduct,
          quantity: 10,
          isWholesale: true,
        ),
      ];

      final result = orderService.validateOrder(
        user: approvedDealer,
        cartItems: items,
        trustedCatalog: catalog,
        claimedTotal: expectedTotal,
      );

      expect(result.isValid, isTrue);
      expect(result.subtotal, equals(95000.0));
      expect(result.tax, equals(17100.0));
      expect(result.deliveryFee, equals(0.0));
      expect(result.computedTotal, equals(expectedTotal));
      expect(result.validatedItems.first.unitPrice, equals(9500.0));
      expect(result.validatedItems.first.isWholesale, isTrue);
    });

    test('Approved dealer below wholesale MOQ is rejected', () {
      final approvedDealer = AuthServiceMockData.demoDealer;

      // MOQ is 5, but dealer attempts to buy only 2
      final items = [
        CartItemModel(
          product: testProduct,
          quantity: 2,
          isWholesale: true,
        ),
      ];

      expect(
        () => orderService.validateOrder(
          user: approvedDealer,
          cartItems: items,
          trustedCatalog: catalog,
          claimedTotal: 19000.0,
        ),
        throwsA(
          isA<OrderException>().having(
            (e) => e.message,
            'message',
            contains('Minimum order quantity for wholesale'),
          ),
        ),
      );
    });

    test('Customer claiming wholesale price is forced to retail price by trusted backend', () {
      final customer = AuthServiceMockData.demoCustomer;

      // Customer attempts client-side tamper: submits isWholesale: true with wholesale price total
      const tamperedWholesaleSubtotal = 9500.0 * 5;
      final tamperedTotal = tamperedWholesaleSubtotal * 1.18;

      final items = [
        CartItemModel(
          product: testProduct,
          quantity: 5,
          isWholesale: true, // Tampered client flag
        ),
      ];

      // Trusted backend ignores isWholesale for customer and computes retail (5 * 15,000 = 75,000)
      // Claimed total based on wholesale (56,050) fails validation!
      expect(
        () => orderService.validateOrder(
          user: customer,
          cartItems: items,
          trustedCatalog: catalog,
          claimedTotal: tamperedTotal,
        ),
        throwsA(
          isA<OrderException>().having(
            (e) => e.message,
            'message',
            contains('Order total mismatch'),
          ),
        ),
      );
    });

    test('Order persistence populates dealerId, companyName, and wholesaleTier', () async {
      final approvedDealer = AuthServiceMockData.demoDealer;
      const subtotal = 95000.0;
      final tax = (subtotal * 0.18).roundToDouble();
      final total = subtotal + tax;

      final items = [
        CartItemModel(
          product: testProduct,
          quantity: 10,
          isWholesale: true,
        ),
      ];

      final order = await orderService.createAndPersistOrder(
        user: approvedDealer,
        cartItems: items,
        trustedCatalog: catalog,
        claimedTotal: total,
        shippingAddress: MockDataService.defaultAddress,
        paymentMethod: 'dealer_credit',
      );

      expect(order.userId, equals(approvedDealer.uid));
      expect(order.userRole, equals(UserRole.dealer));
      expect(order.dealerId, equals(approvedDealer.uid));
      expect(order.dealerCompanyName, equals('Suraj Water Enterprises'));
      expect(order.wholesaleTier, equals('Gold Partner'));
      expect(order.isWholesaleOrder, isTrue);
      expect(order.paymentMethod, equals('dealer_credit'));
    });

    test('Strict user scoping: Dealer sees only their own orders in order history', () {
      final orderProvider = OrderProvider();

      // Ensure mock orders are filtered strictly by userId
      final dealerOrders = orderProvider.getOrdersForUser('usr-dealer-1');
      for (final order in dealerOrders) {
        expect(order.userId, equals('usr-dealer-1'));
      }

      // Check another dealer's or non-existent dealer's query returns empty
      final emptyOrders = orderProvider.getOrdersForUser('usr-dealer-other-999');
      expect(emptyOrders, isEmpty);
    });

    test('AuthProvider persona switching correctly updates isApprovedDealer and dealerStatus', () {
      final authProvider = AuthProvider();

      // Test Approved
      authProvider.switchToDealer(status: 'approved');
      expect(authProvider.isDealer, isTrue);
      expect(authProvider.isApprovedDealer, isTrue);
      expect(authProvider.dealerStatus, equals('approved'));

      // Test Pending
      authProvider.switchToDealer(status: 'pending');
      expect(authProvider.isDealer, isTrue);
      expect(authProvider.isApprovedDealer, isFalse);
      expect(authProvider.dealerStatus, equals('pending'));

      // Test Rejected
      authProvider.switchToDealer(status: 'rejected');
      expect(authProvider.isDealer, isTrue);
      expect(authProvider.isApprovedDealer, isFalse);
      expect(authProvider.dealerStatus, equals('rejected'));

      // Test Customer
      authProvider.switchRole(UserRole.customer);
      expect(authProvider.isDealer, isFalse);
      expect(authProvider.isApprovedDealer, isFalse);
    });
  });
}
