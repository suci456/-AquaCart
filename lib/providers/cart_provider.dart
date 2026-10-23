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

  void addToCart(ProductModel product, {bool isWholesale = false, int? customQuantity}) {
    final int defaultQty = isWholesale ? product.wholesaleMoq : 1;
    final int qtyToAdd = customQuantity ?? defaultQty;

    if (_items.containsKey(product.id)) {
      _items[product.id]!.quantity += qtyToAdd;
    } else {
      _items[product.id] = CartItemModel(
        product: product,
        quantity: qtyToAdd,
        isWholesale: isWholesale,
      );
    }
    notifyListeners();
  }

  void updateQuantity(String productId, int newQuantity) {
    if (!_items.containsKey(productId)) return;

    if (newQuantity <= 0) {
      _items.remove(productId);
    } else {
      _items[productId]!.quantity = newQuantity;
    }
    notifyListeners();
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
