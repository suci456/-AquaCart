import 'package:flutter/foundation.dart';
import '../core/constants/app_constants.dart';
import '../models/product_model.dart';
import '../services/mock_data_service.dart';

class ProductProvider extends ChangeNotifier {
  List<ProductModel> _products = List.from(MockDataService.products);
  ProductCategory _selectedCategory = ProductCategory.all;
  String _searchQuery = '';
  bool _isLoading = false;

  List<ProductModel> get allProducts => _products;
  ProductCategory get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;

  List<ProductModel> get featuredProducts =>
      _products.where((p) => p.isFeatured).toList();

  // Filtered list based on category and search query
  List<ProductModel> get filteredProducts {
    return _products.where((product) {
      final matchesCategory = _selectedCategory == ProductCategory.all ||
          product.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          product.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          product.subtitle.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          product.description.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  void setCategory(ProductCategory category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  ProductModel? getProductById(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  // Admin capability: Add product
  void addProduct(ProductModel product) {
    _products.insert(0, product);
    notifyListeners();
  }

  // Admin capability: Update product stock or prices
  void updateProduct(ProductModel updated) {
    final index = _products.indexWhere((p) => p.id == updated.id);
    if (index != -1) {
      _products[index] = updated;
      notifyListeners();
    }
  }

  // Admin capability: Delete product
  void deleteProduct(String productId) {
    _products.removeWhere((p) => p.id == productId);
    notifyListeners();
  }
}
