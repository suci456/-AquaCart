// ignore_for_file: library_annotations
/// Trusted Backend Order Validation Tests
///
/// These tests exercise OrderService.validateOrder to confirm that the
/// server-side guard:
///  - Rejects orders when a product has insufficient stock.
///  - Rejects orders when the client-claimed total is tampered.
///  - Rejects empty carts immediately.
///  - Enforces wholesale MOQ for dealer orders.
///  - Correctly computes subtotal, 18% GST, delivery fee, and grand total.
///  - Accepts legitimate orders with exactly-matching totals.
import 'package:flutter_test/flutter_test.dart';
import 'package:aquacart/core/constants/app_constants.dart';
import 'package:aquacart/models/product_model.dart';
import 'package:aquacart/models/cart_item_model.dart';
import 'package:aquacart/models/user_model.dart';
import 'package:aquacart/services/order_service.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Minimal [ProductModel] factory for test use.
ProductModel _makeProduct({
  required String id,
  required double retail,
  required double wholesale,
  int stock = 50,
  int moq = 5,
}) {
  return ProductModel(
    id: id,
    title: 'Test Product $id',
    subtitle: 'Subtitle',
    description: 'A test product for unit testing.',
    category: ProductCategory.roPurifiers,
    mrp: retail * 1.2,
    retailPrice: retail,
    wholesalePrice: wholesale,
    wholesaleMoq: moq,
    stockQuantity: stock,
    imageUrl: 'https://via.placeholder.com/300',
    rating: 4.5,
    specs: ProductSpecs(),
  );
}

/// Minimal [UserModel] factory for test use.
UserModel _makeUser({UserRole role = UserRole.customer}) {
  return UserModel(
    uid: 'test-user-001',
    email: 'test@aquacart.com',
    displayName: 'Test User',
    role: role,
    phone: '9876543210',
    addresses: [],
  );
}

/// Computes the expected total the same way OrderService does.
double _expectedTotal({required double subtotal}) {
  final tax = subtotal * AppConstants.gstRate; // 18%
  final delivery = subtotal > 1000 ? 0.0 : 99.0;
  return subtotal + tax + delivery;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late OrderService orderService;

  setUp(() {
    orderService = OrderService();
  });

  group('OrderService.validateOrder — Trusted Backend Guard', () {
    // -----------------------------------------------------------------------
    // 1. Empty cart
    // -----------------------------------------------------------------------
    test('Rejects empty cart immediately with descriptive error', () {
      final user = _makeUser();
      final result = orderService.validateOrder(
        user: user,
        cartItems: [],
        trustedCatalog: [],
        claimedTotal: 0,
      );

      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('empty'));
      expect(result.verifiedTotalAmount, equals(0));
      expect(result.verifiedItems, isEmpty);
    });

    // -----------------------------------------------------------------------
    // 2. Insufficient stock rejection
    // -----------------------------------------------------------------------
    test('Rejects order when requested quantity exceeds available stock', () {
      final product =
          _makeProduct(id: 'prod-ro-01', retail: 8999, wholesale: 6500, stock: 3);
      final user = _makeUser();

      // 5 requested > stock of 3
      final cartItem = CartItemModel(product: product, quantity: 5);
      final catalog = [product];

      final result = orderService.validateOrder(
        user: user,
        cartItems: [cartItem],
        trustedCatalog: catalog,
        claimedTotal: 0, // irrelevant — fails before total check
      );

      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('Insufficient stock'));
      expect(result.errorMessage, contains('3'));
    });

    // -----------------------------------------------------------------------
    // 3. Price tampering rejection
    // -----------------------------------------------------------------------
    test('Rejects order when claimed total is higher than computed total', () {
      final product =
          _makeProduct(id: 'prod-ro-02', retail: 5000, wholesale: 3500, stock: 20);
      final user = _makeUser();
      final cartItem = CartItemModel(product: product, quantity: 1);
      final catalog = [product];

      final correctTotal = _expectedTotal(subtotal: 5000);
      final tamperedTotal = correctTotal + 500.0;

      final result = orderService.validateOrder(
        user: user,
        cartItems: [cartItem],
        trustedCatalog: catalog,
        claimedTotal: tamperedTotal,
      );

      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('mismatch'));
    });

    test('Rejects order when claimed total is lower (price injection attack)', () {
      final product =
          _makeProduct(id: 'prod-ro-03', retail: 12000, wholesale: 8500, stock: 15);
      final user = _makeUser();
      final cartItem = CartItemModel(product: product, quantity: 2);
      final catalog = [product];

      final result = orderService.validateOrder(
        user: user,
        cartItems: [cartItem],
        trustedCatalog: catalog,
        claimedTotal: 1000.0, // injected low value
      );

      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('mismatch'));
    });

    // -----------------------------------------------------------------------
    // 4. Dealer wholesale MOQ enforcement
    // -----------------------------------------------------------------------
    test('Rejects dealer wholesale order below MOQ', () {
      final product = _makeProduct(
        id: 'prod-filter-01',
        retail: 1200,
        wholesale: 850,
        stock: 100,
        moq: 10, // minimum 10 units
      );
      final dealer = _makeUser(role: UserRole.dealer);
      // Only 4 ordered — below MOQ of 10
      final cartItem =
          CartItemModel(product: product, quantity: 4, isWholesale: true);
      final catalog = [product];

      final result = orderService.validateOrder(
        user: dealer,
        cartItems: [cartItem],
        trustedCatalog: catalog,
        claimedTotal: 0,
      );

      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('minimum wholesale order quantity'));
      expect(result.errorMessage, contains('10'));
    });

    // -----------------------------------------------------------------------
    // 5. Customer always pays retail — isWholesale flag is ignored
    // -----------------------------------------------------------------------
    test('Customer is always charged retail price regardless of isWholesale flag', () {
      final product =
          _makeProduct(id: 'prod-ro-04', retail: 8000, wholesale: 5500, stock: 30);
      final customer = _makeUser(role: UserRole.customer);

      // Malicious client sets isWholesale = true
      final cartItem =
          CartItemModel(product: product, quantity: 1, isWholesale: true);
      final catalog = [product];

      // Valid total uses retail price
      final retailTotal = _expectedTotal(subtotal: 8000);

      final result = orderService.validateOrder(
        user: customer,
        cartItems: [cartItem],
        trustedCatalog: catalog,
        claimedTotal: retailTotal,
      );

      expect(result.isValid, isTrue);
      expect(result.verifiedItems.first.unitPrice, equals(8000.0));
      expect(result.verifiedItems.first.unitPrice, isNot(equals(5500.0)));
    });

    // -----------------------------------------------------------------------
    // 6. Accurate GST (18%) and delivery calculation
    // -----------------------------------------------------------------------
    test('Correctly computes 18% GST — subtotal above ₹1000 waives delivery', () {
      final product =
          _makeProduct(id: 'prod-acc-01', retail: 500, wholesale: 350, stock: 100);
      final user = _makeUser();
      // 4 units × ₹500 = ₹2000 subtotal
      final cartItem = CartItemModel(product: product, quantity: 4);
      final catalog = [product];

      const subtotal = 2000.0;
      final expectedTax = subtotal * 0.18; // ₹360
      const expectedDelivery = 0.0; // free (subtotal > ₹1000)
      final expectedTotal = subtotal + expectedTax + expectedDelivery;

      final result = orderService.validateOrder(
        user: user,
        cartItems: [cartItem],
        trustedCatalog: catalog,
        claimedTotal: expectedTotal,
      );

      expect(result.isValid, isTrue);
      expect(result.verifiedSubtotal, equals(subtotal));
      expect(result.verifiedTax, closeTo(expectedTax, 0.01));
      expect(result.verifiedDeliveryFee, equals(0.0));
      expect(result.verifiedTotalAmount, closeTo(expectedTotal, 0.01));
    });

    test('Charges ₹99 delivery fee when subtotal is below ₹1000', () {
      final product =
          _makeProduct(id: 'prod-filter-02', retail: 200, wholesale: 140, stock: 50);
      final user = _makeUser();
      // 2 × ₹200 = ₹400 subtotal
      final cartItem = CartItemModel(product: product, quantity: 2);

      const subtotal = 400.0;
      final expectedTax = subtotal * 0.18; // ₹72
      const expectedDelivery = 99.0;
      final expectedTotal = subtotal + expectedTax + expectedDelivery;

      final result = orderService.validateOrder(
        user: user,
        cartItems: [cartItem],
        trustedCatalog: [product],
        claimedTotal: expectedTotal,
      );

      expect(result.isValid, isTrue);
      expect(result.verifiedDeliveryFee, equals(99.0));
      expect(result.verifiedTotalAmount, closeTo(expectedTotal, 0.01));
    });

    // -----------------------------------------------------------------------
    // 7. Multi-item dealer wholesale order
    // -----------------------------------------------------------------------
    test('Accepts valid multi-item dealer wholesale order with correct total', () {
      final p1 = _makeProduct(
          id: 'prod-ro-05', retail: 10000, wholesale: 7200, stock: 50, moq: 5);
      final p2 = _makeProduct(
          id: 'prod-filter-03', retail: 1500, wholesale: 950, stock: 200, moq: 10);
      final dealer = _makeUser(role: UserRole.dealer);

      final cart = [
        CartItemModel(product: p1, quantity: 5, isWholesale: true), // 36000
        CartItemModel(product: p2, quantity: 10, isWholesale: true), // 9500
      ];
      final catalog = [p1, p2];

      const subtotal = 36000.0 + 9500.0; // 45500
      final expectedTotal = _expectedTotal(subtotal: subtotal);

      final result = orderService.validateOrder(
        user: dealer,
        cartItems: cart,
        trustedCatalog: catalog,
        claimedTotal: expectedTotal,
      );

      expect(result.isValid, isTrue);
      expect(result.verifiedItems.length, equals(2));
      expect(result.verifiedSubtotal, equals(45500.0));
      expect(result.verifiedDeliveryFee, equals(0.0)); // free delivery

      for (final item in result.verifiedItems) {
        expect(item.isWholesale, isTrue);
      }
    });

    // -----------------------------------------------------------------------
    // 8. Floating-point tolerance boundary
    // -----------------------------------------------------------------------
    test('Accepts total within ₹0.05 floating-point rounding tolerance', () {
      final product =
          _makeProduct(id: 'prod-ro-06', retail: 3333, wholesale: 2400, stock: 20);
      final user = _makeUser();
      final cartItem = CartItemModel(product: product, quantity: 3); // 9999

      const subtotal = 9999.0;
      final exactTotal = _expectedTotal(subtotal: subtotal);
      final slightlyRounded = exactTotal + 0.04; // within tolerance

      final result = orderService.validateOrder(
        user: user,
        cartItems: [cartItem],
        trustedCatalog: [product],
        claimedTotal: slightlyRounded,
      );

      expect(result.isValid, isTrue);
    });

    test('Rejects total exceeding ₹0.05 tolerance', () {
      final product =
          _makeProduct(id: 'prod-ro-07', retail: 3333, wholesale: 2400, stock: 20);
      final user = _makeUser();
      final cartItem = CartItemModel(product: product, quantity: 3);

      const subtotal = 9999.0;
      final exactTotal = _expectedTotal(subtotal: subtotal);
      final outsideTolerance = exactTotal + 0.10; // exceeds tolerance

      final result = orderService.validateOrder(
        user: user,
        cartItems: [cartItem],
        trustedCatalog: [product],
        claimedTotal: outsideTolerance,
      );

      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('mismatch'));
    });
  });
}
