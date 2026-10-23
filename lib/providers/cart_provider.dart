import 'package:flutter/foundation.dart';
import '../core/constants/app_constants.dart';
import '../models/product_model.dart';
import '../models/cart_item_model.dart';

class CartProvider extends ChangeNotifier {
  final Map<String, CartItemModel> _items = {};

  Map<String, CartItemModel> get items => {..._items};
  List<CartItemModel> get itemList => _items.values.toList();
  int get itemCount => _items.values.fold(0, (sum, item) => sum + item.quantity);

  // Subtotal before tax
  double get subtotal {
    return _items.values.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  // 18% GST calculation
  double get taxAmount {
    return subtotal * AppConstants.gstRate;
  }

  // Shipping fee (Free above ₹1000)
  double get deliveryFee {
    if (subtotal == 0) return 0.0;
    return subtotal > 1000 ? 0.0 : 99.0;
  }

  // Final Total
  double get totalAmount {
    return subtotal + taxAmount + deliveryFee;
  }

  // Check if all wholesale items in cart meet MOQ
  bool get allWholesaleMoqMet {
    return _items.values.every((item) => item.meetsWholesaleMoq);
  }

  // Get list of items failing MOQ
  List<CartItemModel> get itemsFailingMoq {
    return _items.values.where((item) => !item.meetsWholesaleMoq).toList();
  }

  // Add to cart with stock validation
  // Returns true if added fully, false if capped by stock or out of stock
  bool addToCart(ProductModel product, {bool isWholesale = false, int? customQuantity}) {
    if (!product.isInStock) return false;

    final int defaultQty = isWholesale ? product.wholesaleMoq : 1;
    final int requestedQty = customQuantity ?? defaultQty;

    final int existingQty = _items[product.id]?.quantity ?? 0;
    final int newQty = existingQty + requestedQty;

    // Enforce stock ceiling
    final int finalQty = newQty > product.stockQuantity ? product.stockQuantity : newQty;

    if (_items.containsKey(product.id)) {
      _items[product.id]!.quantity = finalQty;
    } else {
      _items[product.id] = CartItemModel(
        product: product,
        quantity: finalQty,
        isWholesale: isWholesale,
      );
    }
    notifyListeners();
    return newQty <= product.stockQuantity;
  }

  // Update item quantity with stock boundary check
  bool updateQuantity(String productId, int newQuantity) {
    if (!_items.containsKey(productId)) return false;

    if (newQuantity <= 0) {
      _items.remove(productId);
      notifyListeners();
      return true;
    }

    final item = _items[productId]!;
    if (newQuantity > item.product.stockQuantity) {
      // Cap at available stock
      item.quantity = item.product.stockQuantity;
      notifyListeners();
      return false; // Indicates capped
    }

    item.quantity = newQuantity;
    notifyListeners();
    return true;
  }

  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
