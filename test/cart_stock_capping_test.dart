// ignore_for_file: library_annotations
/// Cart Stock Capping & Quantity Boundary Tests
///
/// Tests for CartProvider ensuring:
///  - Out-of-stock products cannot be added.
///  - Quantity is capped at available stock ceiling.
///  - Quantity update below 1 removes the item.
///  - Wholesale MOQ items are detected correctly.
///  - GST, delivery fee, and grand total calculations are accurate.
///  - clearCart resets all state.
import 'package:flutter_test/flutter_test.dart';
import 'package:aquacart/core/constants/app_constants.dart';
import 'package:aquacart/models/product_model.dart';
import 'package:aquacart/providers/cart_provider.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Builds a [ProductModel] with controllable stock for boundary testing.
ProductModel _product({
  String id = 'prod-test-01',
  double retail = 5000,
  double wholesale = 3500,
  int stock = 10,
  int moq = 5,
}) {
  return ProductModel(
    id: id,
    title: 'Test Purifier $id',
    subtitle: 'Test subtitle',
    description: 'A unit-test product.',
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

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late CartProvider cart;

  setUp(() {
    cart = CartProvider();
  });

  group('CartProvider — Stock Capping & Quantity Controls', () {
    // -----------------------------------------------------------------------
    // 1. Out-of-stock products
    // -----------------------------------------------------------------------
    test('Cannot add an out-of-stock product', () {
      final product = _product(id: 'oos-01', stock: 0);

      final wasAdded = cart.addToCart(product);

      expect(wasAdded, isFalse);
      expect(cart.itemCount, equals(0));
      expect(cart.items, isEmpty);
    });

    // -----------------------------------------------------------------------
    // 2. Stock ceiling enforcement on addToCart
    // -----------------------------------------------------------------------
    test('Quantity is capped at available stock when adding beyond stock', () {
      final product = _product(id: 'cap-01', stock: 3);

      // Attempt to add 10, but only 3 available
      cart.addToCart(product, customQuantity: 10);

      expect(cart.items['cap-01']!.quantity, equals(3));
      expect(cart.itemCount, equals(3));
    });

    test('Adds exact stock quantity when requesting exactly stock amount', () {
      final product = _product(id: 'exact-01', stock: 5);

      final result = cart.addToCart(product, customQuantity: 5);

      expect(result, isTrue); // not capped
      expect(cart.items['exact-01']!.quantity, equals(5));
    });

    test('Returns false when addToCart caps the quantity', () {
      final product = _product(id: 'cap-ret-01', stock: 2);

      final result = cart.addToCart(product, customQuantity: 10);

      expect(result, isFalse); // capped
      expect(cart.items['cap-ret-01']!.quantity, equals(2));
    });

    // -----------------------------------------------------------------------
    // 3. Cumulative add stays within stock ceiling
    // -----------------------------------------------------------------------
    test('Successive adds are capped cumulatively at stock ceiling', () {
      final product = _product(id: 'cum-01', stock: 5);

      cart.addToCart(product, customQuantity: 3); // qty = 3
      cart.addToCart(product, customQuantity: 4); // 3 + 4 = 7, capped at 5

      expect(cart.items['cum-01']!.quantity, equals(5));
    });

    // -----------------------------------------------------------------------
    // 4. updateQuantity boundary checks
    // -----------------------------------------------------------------------
    test('updateQuantity caps at stock ceiling when new quantity exceeds stock', () {
      final product = _product(id: 'upd-01', stock: 4);
      cart.addToCart(product, customQuantity: 2);

      final result = cart.updateQuantity('upd-01', 10); // exceeds stock of 4

      expect(result, isFalse); // indicates capped
      expect(cart.items['upd-01']!.quantity, equals(4));
    });

    test('updateQuantity to exactly stock limit is accepted', () {
      final product = _product(id: 'upd-02', stock: 8);
      cart.addToCart(product, customQuantity: 2);

      final result = cart.updateQuantity('upd-02', 8);

      expect(result, isTrue);
      expect(cart.items['upd-02']!.quantity, equals(8));
    });

    test('updateQuantity to 0 removes the item', () {
      final product = _product(id: 'rm-01', stock: 10);
      cart.addToCart(product, customQuantity: 3);

      cart.updateQuantity('rm-01', 0);

      expect(cart.items, doesNotContain('rm-01'));
      expect(cart.itemCount, equals(0));
    });

    test('updateQuantity to negative value removes the item', () {
      final product = _product(id: 'rm-02', stock: 10);
      cart.addToCart(product, customQuantity: 2);

      cart.updateQuantity('rm-02', -5);

      expect(cart.items, doesNotContain('rm-02'));
    });

    // -----------------------------------------------------------------------
    // 5. removeItem
    // -----------------------------------------------------------------------
    test('removeItem deletes the specific product from cart', () {
      final p1 = _product(id: 'rem-p1', stock: 10);
      final p2 = _product(id: 'rem-p2', stock: 10);

      cart.addToCart(p1);
      cart.addToCart(p2);

      expect(cart.itemCount, equals(2));

      cart.removeItem('rem-p1');

      expect(cart.items, doesNotContain('rem-p1'));
      expect(cart.items, contains('rem-p2'));
      expect(cart.itemCount, equals(1));
    });

    // -----------------------------------------------------------------------
    // 6. Wholesale MOQ detection
    // -----------------------------------------------------------------------
    test('Wholesale item below MOQ is flagged in itemsFailingMoq', () {
      final product = _product(id: 'moq-01', stock: 50, moq: 10);

      // Add with isWholesale=true but only 3 units (below MOQ of 10)
      cart.addToCart(product, isWholesale: true, customQuantity: 3);

      expect(cart.allWholesaleMoqMet, isFalse);
      expect(cart.itemsFailingMoq.length, equals(1));
      expect(cart.itemsFailingMoq.first.product.id, equals('moq-01'));
    });

    test('Wholesale item meeting MOQ passes allWholesaleMoqMet check', () {
      final product = _product(id: 'moq-02', stock: 50, moq: 5);

      // Add exactly MOQ quantity
      cart.addToCart(product, isWholesale: true, customQuantity: 5);

      expect(cart.allWholesaleMoqMet, isTrue);
      expect(cart.itemsFailingMoq, isEmpty);
    });

    // -----------------------------------------------------------------------
    // 7. Financial calculations
    // -----------------------------------------------------------------------
    test('Subtotal sums correctly for multiple items at retail price', () {
      final p1 = _product(id: 'fin-01', retail: 5000, stock: 10);
      final p2 = _product(id: 'fin-02', retail: 2000, stock: 10);

      cart.addToCart(p1, customQuantity: 2); // 10000
      cart.addToCart(p2, customQuantity: 3); // 6000

      expect(cart.subtotal, equals(16000.0));
    });

    test('GST is exactly 18% of subtotal', () {
      final product = _product(id: 'gst-01', retail: 1000, stock: 10);
      cart.addToCart(product, customQuantity: 2); // subtotal = 2000

      // Tax = 2000 * 0.18 = 360
      expect(cart.taxAmount, closeTo(360.0, 0.01));
    });

    test('Delivery is FREE when subtotal exceeds ₹1000', () {
      final product = _product(id: 'del-01', retail: 1001, stock: 5);
      cart.addToCart(product, customQuantity: 1); // subtotal = 1001

      expect(cart.deliveryFee, equals(0.0));
    });

    test('Delivery fee is ₹99 when subtotal is ₹1000 or less', () {
      final product = _product(id: 'del-02', retail: 400, stock: 10);
      cart.addToCart(product, customQuantity: 2); // subtotal = 800

      expect(cart.deliveryFee, equals(99.0));
    });

    test('Delivery fee is ₹0 when cart is empty', () {
      expect(cart.deliveryFee, equals(0.0));
    });

    test('Grand total equals subtotal + 18% GST + delivery fee', () {
      final product = _product(id: 'total-01', retail: 500, stock: 10);
      cart.addToCart(product, customQuantity: 2); // subtotal = 1000

      final expectedSubtotal = 1000.0;
      final expectedTax = expectedSubtotal * AppConstants.gstRate; // 180
      const expectedDelivery = 99.0; // subtotal NOT above ₹1000 (exactly 1000)
      final expectedTotal = expectedSubtotal + expectedTax + expectedDelivery;

      expect(cart.totalAmount, closeTo(expectedTotal, 0.01));
    });

    // -----------------------------------------------------------------------
    // 8. clearCart
    // -----------------------------------------------------------------------
    test('clearCart removes all items and resets all totals to zero', () {
      final p1 = _product(id: 'clr-01', stock: 10);
      final p2 = _product(id: 'clr-02', stock: 10);

      cart.addToCart(p1, customQuantity: 3);
      cart.addToCart(p2, customQuantity: 2);

      expect(cart.itemCount, greaterThan(0));

      cart.clearCart();

      expect(cart.itemCount, equals(0));
      expect(cart.items, isEmpty);
      expect(cart.subtotal, equals(0.0));
      expect(cart.taxAmount, equals(0.0));
      expect(cart.totalAmount, equals(0.0));
    });

    // -----------------------------------------------------------------------
    // 9. Default retail wholesale add
    // -----------------------------------------------------------------------
    test('addToCart with isWholesale=true defaults to wholesaleMoq quantity', () {
      final product = _product(id: 'ws-01', stock: 100, moq: 8);

      cart.addToCart(product, isWholesale: true);

      // Default qty for wholesale = product.wholesaleMoq = 8
      expect(cart.items['ws-01']!.quantity, equals(8));
      expect(cart.items['ws-01']!.isWholesale, isTrue);
    });

    test('addToCart with isWholesale=false defaults to 1 unit', () {
      final product = _product(id: 'ret-01', stock: 10);

      cart.addToCart(product);

      expect(cart.items['ret-01']!.quantity, equals(1));
      expect(cart.items['ret-01']!.isWholesale, isFalse);
    });
  });
}
