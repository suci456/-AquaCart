import 'product_model.dart';
import '../core/constants/app_constants.dart';

class CartItemModel {
  final ProductModel product;
  int quantity;
  final bool isWholesale;

  CartItemModel({
    required this.product,
    this.quantity = 1,
    this.isWholesale = false,
  });

  // Effective unit price depending on wholesale vs retail
  double get unitPrice {
    return isWholesale ? product.wholesalePrice : product.retailPrice;
  }

  // Line item subtotal
  double get totalPrice {
    return unitPrice * quantity;
  }

  // Checks if dealer MOQ requirement is satisfied
  bool get meetsWholesaleMoq {
    if (!isWholesale) return true;
    return quantity >= product.wholesaleMoq;
  }

  int get requiredMoqDifference {
    if (!isWholesale || meetsWholesaleMoq) return 0;
    return product.wholesaleMoq - quantity;
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': product.id,
      'title': product.title,
      'unitPrice': unitPrice,
      'quantity': quantity,
      'isWholesale': isWholesale,
      'totalPrice': totalPrice,
    };
  }
}
