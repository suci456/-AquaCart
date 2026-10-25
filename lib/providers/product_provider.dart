import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../core/constants/app_constants.dart';
import '../models/product_model.dart';
import '../services/mock_data_service.dart';

enum ProductSortOption {
  featured,
  priceLowToHigh,
  priceHighToLow,
  rating,
  stockOnly,
}

class ProductProvider extends ChangeNotifier {
  List<ProductModel> _products = List.from(MockDataService.products);
  ProductCategory _selectedCategory = ProductCategory.all;
  ProductSortOption _sortOption = ProductSortOption.featured;
  String _searchQuery = '';
  double? _minPrice;
  double? _maxPrice;
  bool _isLoading = false;
  String? _errorMessage;

  List<ProductModel> get allProducts => _products;
  ProductCategory get selectedCategory => _selectedCategory;
  ProductSortOption get sortOption => _sortOption;
  String get searchQuery => _searchQuery;
  double? get minPrice => _minPrice;
  double? get maxPrice => _maxPrice;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get _isFirebaseAvailable {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  List<ProductModel> get featuredProducts =>
      _products.where((p) => p.isFeatured).toList();

  // Filtered & Sorted list based on active category, query, price bounds, and sort option
  List<ProductModel> getFilteredProductsForRole(UserRole role) {
    List<ProductModel> list = _products.where((product) {
      final matchesCategory = _selectedCategory == ProductCategory.all ||
          product.category == _selectedCategory;

      final query = _searchQuery.trim().toLowerCase();
      final matchesSearch = query.isEmpty ||
          product.title.toLowerCase().contains(query) ||
          product.subtitle.toLowerCase().contains(query) ||
          product.description.toLowerCase().contains(query) ||
          product.specs.membraneType.toLowerCase().contains(query);

      final price = product.getPriceForRole(role);
      final matchesMin = _minPrice == null || price >= _minPrice!;
      final matchesMax = _maxPrice == null || price <= _maxPrice!;

      return matchesCategory && matchesSearch && matchesMin && matchesMax;
    }).toList();

    // Sort order
    switch (_sortOption) {
      case ProductSortOption.priceLowToHigh:
        list.sort((a, b) => a.getPriceForRole(role).compareTo(b.getPriceForRole(role)));
        break;
      case ProductSortOption.priceHighToLow:
        list.sort((a, b) => b.getPriceForRole(role).compareTo(a.getPriceForRole(role)));
        break;
      case ProductSortOption.rating:
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case ProductSortOption.stockOnly:
        list = list.where((p) => p.isInStock).toList();
        list.sort((a, b) => b.stockQuantity.compareTo(a.stockQuantity));
        break;
      case ProductSortOption.featured:
      default:
        // Featured products first, then by rating
        list.sort((a, b) {
          if (a.isFeatured && !b.isFeatured) return -1;
          if (!a.isFeatured && b.isFeatured) return 1;
          return b.rating.compareTo(a.rating);
        });
        break;
    }

    return list;
  }

  // Default filter for current customer role
  List<ProductModel> get filteredProducts => getFilteredProductsForRole(UserRole.customer);

  void setCategory(ProductCategory category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSortOption(ProductSortOption option) {
    _sortOption = option;
    notifyListeners();
  }

  void setPriceRange(double? min, double? max) {
    _minPrice = min;
    _maxPrice = max;
    notifyListeners();
  }

  void clearFilters() {
    _selectedCategory = ProductCategory.all;
    _sortOption = ProductSortOption.featured;
    _searchQuery = '';
    _minPrice = null;
    _maxPrice = null;
    notifyListeners();
  }

  ProductModel? getProductById(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  // Load products from Cloud Firestore (with fallback to MockDataService)
  Future<void> fetchProductsFromFirestore() async {
    if (!_isFirebaseAvailable) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final snapshot = await FirebaseFirestore.instance.collection('products').get();
      if (snapshot.docs.isNotEmpty) {
        _products = snapshot.docs
            .map((doc) => ProductModel.fromMap(doc.data()))
            .toList();
      }
    } catch (e) {
      _errorMessage = 'Failed to fetch products: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Alias for loading / refreshing products
  Future<void> loadProducts() => fetchProductsFromFirestore();

  // Stock Decrementer (called when an order is verified and placed)
  void decrementStock(String productId, int quantity) {
    final index = _products.indexWhere((p) => p.id == productId);
    if (index != -1) {
      final current = _products[index];
      final newStock = (current.stockQuantity - quantity).clamp(0, 99999);
      _products[index] = ProductModel(
        id: current.id,
        title: current.title,
        subtitle: current.subtitle,
        description: current.description,
        category: current.category,
        mrp: current.mrp,
        retailPrice: current.retailPrice,
        wholesalePrice: current.wholesalePrice,
        wholesaleMoq: current.wholesaleMoq,
        stockQuantity: newStock,
        imageUrl: current.imageUrl,
        rating: current.rating,
        reviewCount: current.reviewCount,
        isFeatured: current.isFeatured,
        specs: current.specs,
      );

      // If Firestore is available, persist new stock quantity
      if (_isFirebaseAvailable) {
        FirebaseFirestore.instance.collection('products').doc(productId).update({
          'stockQuantity': newStock,
        }).catchError((_) {});
      }

      notifyListeners();
    }
  }

  // Admin capability: Add product
  void addProduct(ProductModel product) {
    _products.insert(0, product);
    if (_isFirebaseAvailable) {
      FirebaseFirestore.instance.collection('products').doc(product.id).set(product.toMap()).catchError((_) {});
    }
    notifyListeners();
  }

  // Admin capability: Update product
  void updateProduct(ProductModel updated) {
    final index = _products.indexWhere((p) => p.id == updated.id);
    if (index != -1) {
      _products[index] = updated;
      if (_isFirebaseAvailable) {
        FirebaseFirestore.instance.collection('products').doc(updated.id).update(updated.toMap()).catchError((_) {});
      }
      notifyListeners();
    }
  }

  // Admin capability: Delete product
  void deleteProduct(String productId) {
    _products.removeWhere((p) => p.id == productId);
    if (_isFirebaseAvailable) {
      FirebaseFirestore.instance.collection('products').doc(productId).delete().catchError((_) {});
    }
    notifyListeners();
  }

  // Seed all 50 products to Cloud Firestore
  Future<int> seedInitialProductsToFirestore() async {
    if (!_isFirebaseAvailable) return 0;
    int count = 0;
    final batch = FirebaseFirestore.instance.batch();
    for (final prod in MockDataService.products) {
      final docRef = FirebaseFirestore.instance.collection('products').doc(prod.id);
      batch.set(docRef, prod.toMap());
      count++;
    }
    await batch.commit();
    return count;
  }
}
