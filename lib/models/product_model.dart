import '../core/constants/app_constants.dart';

class ProductSpecs {
  final int stages;
  final String capacity;
  final String tdsReduction;
  final String warranty;
  final String membraneType;

  ProductSpecs({
    this.stages = 7,
    this.capacity = '12 L/hr',
    this.tdsReduction = 'Up to 2000 ppm',
    this.warranty = '1 Year Comprehensive',
    this.membraneType = 'RO + UV + UF + Copper Alkaline',
  });

  factory ProductSpecs.fromMap(Map<String, dynamic> map) {
    return ProductSpecs(
      stages: map['stages'] ?? 7,
      capacity: map['capacity'] ?? '12 L/hr',
      tdsReduction: map['tdsReduction'] ?? 'Up to 2000 ppm',
      warranty: map['warranty'] ?? '1 Year',
      membraneType: map['membraneType'] ?? 'RO+UV+UF',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'stages': stages,
      'capacity': capacity,
      'tdsReduction': tdsReduction,
      'warranty': warranty,
      'membraneType': membraneType,
    };
  }
}

class ProductModel {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final ProductCategory category;
  final double mrp;
  final double retailPrice;
  final double wholesalePrice;
  final int wholesaleMoq;
  final int stockQuantity;
  final String imageUrl;
  final String? localAssetImage; // Optional: AI-generated local asset path (assets/images/...)
  final double rating;
  final int reviewCount;
  final bool isFeatured;
  final ProductSpecs specs;

  ProductModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.category,
    required this.mrp,
    required this.retailPrice,
    required this.wholesalePrice,
    this.wholesaleMoq = 5,
    this.stockQuantity = 50,
    required this.imageUrl,
    this.localAssetImage,
    this.rating = 4.8,
    this.reviewCount = 124,
    this.isFeatured = false,
    required this.specs,
  });

  /// Returns true if this product has an AI-generated local asset image
  bool get hasLocalAsset => localAssetImage != null && localAssetImage!.isNotEmpty;

  // Calculate discount percentage for retail
  int get retailDiscountPercentage {
    if (mrp <= 0) return 0;
    return (((mrp - retailPrice) / mrp) * 100).round();
  }

  // Calculate dealer wholesale discount percentage
  int get wholesaleDiscountPercentage {
    if (mrp <= 0) return 0;
    return (((mrp - wholesalePrice) / mrp) * 100).round();
  }

  // Helper to fetch unit price based on user role
  double getPriceForRole(UserRole role) {
    if (role == UserRole.dealer) {
      return wholesalePrice;
    }
    return retailPrice;
  }

  // Restrict wholesale price: Only Dealers & Admins can access wholesale prices
  double? getWholesalePriceForRole(UserRole role) {
    if (role == UserRole.dealer || role == UserRole.admin) {
      return wholesalePrice;
    }
    return null; // Masked for standard customers
  }

  // Stock availability helper
  bool get isInStock => stockQuantity > 0;

  String get stockStatus {
    if (stockQuantity <= 0) return 'Out of Stock';
    if (stockQuantity <= 5) return 'Only $stockQuantity left in stock!';
    return 'In Stock ($stockQuantity units available)';
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      subtitle: map['subtitle'] ?? '',
      description: map['description'] ?? '',
      category: _parseCategory(map['category']),
      mrp: (map['mrp'] ?? 0.0).toDouble(),
      retailPrice: (map['retailPrice'] ?? 0.0).toDouble(),
      wholesalePrice: (map['wholesalePrice'] ?? 0.0).toDouble(),
      wholesaleMoq: map['wholesaleMoq'] ?? 5,
      stockQuantity: map['stockQuantity'] ?? 0,
      imageUrl: map['imageUrl'] ?? '',
      rating: (map['rating'] ?? 4.5).toDouble(),
      reviewCount: map['reviewCount'] ?? 0,
      isFeatured: map['isFeatured'] ?? false,
      specs: map['specs'] != null
          ? ProductSpecs.fromMap(Map<String, dynamic>.from(map['specs']))
          : ProductSpecs(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'description': description,
      'category': category.name,
      'mrp': mrp,
      'retailPrice': retailPrice,
      'wholesalePrice': wholesalePrice,
      'wholesaleMoq': wholesaleMoq,
      'stockQuantity': stockQuantity,
      'imageUrl': imageUrl,
      'rating': rating,
      'reviewCount': reviewCount,
      'isFeatured': isFeatured,
      'specs': specs.toMap(),
    };
  }

  static ProductCategory _parseCategory(dynamic catStr) {
    for (var cat in ProductCategory.values) {
      if (cat.name == catStr) return cat;
    }
    return ProductCategory.roPurifiers;
  }
}
