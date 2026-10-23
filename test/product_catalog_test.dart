import 'package:flutter_test/flutter_test.dart';
import 'package:aquacart/core/constants/app_constants.dart';
import 'package:aquacart/models/product_model.dart';
import 'package:aquacart/providers/product_provider.dart';
import 'package:aquacart/services/mock_data_service.dart';

void main() {
  group('Product Catalog & Role Pricing Restriction Tests', () {
    late ProductProvider productProvider;

    setUp(() {
      productProvider = ProductProvider();
    });

    test('Catalog contains at least 50 meaningful water purifier products', () {
      expect(MockDataService.products.length, greaterThanOrEqualTo(50));
      expect(productProvider.allProducts.length, greaterThanOrEqualTo(50));
    });

    test('All product categories are populated with rich specifications', () {
      for (final cat in [
        ProductCategory.roPurifiers,
        ProductCategory.commercialPurifiers,
        ProductCategory.spareFilters,
        ProductCategory.accessories,
        ProductCategory.amcPlans,
      ]) {
        final items = productProvider.allProducts.where((p) => p.category == cat).toList();
        expect(items, isNotEmpty, reason: 'Category ${cat.name} should have products');
      }

      // Check integrity of every product
      for (final p in productProvider.allProducts) {
        expect(p.id, isNotEmpty);
        expect(p.title, isNotEmpty);
        expect(p.description, isNotEmpty);
        expect(p.imageUrl, startsWith('http'));
        expect(p.retailPrice, greaterThan(0));
        expect(p.wholesalePrice, greaterThan(0));
        expect(p.wholesalePrice, lessThanOrEqualTo(p.retailPrice));
        expect(p.stockQuantity, greaterThanOrEqualTo(0));
        expect(p.rating, inInclusiveRange(1.0, 5.0));
      }
    });

    test('STRICT SECURITY: Wholesale price is restricted and masked for Customer role', () {
      final product = productProvider.allProducts.first;

      // Customer view
      expect(product.getPriceForRole(UserRole.customer), equals(product.retailPrice));
      expect(product.getWholesalePriceForRole(UserRole.customer), isNull);

      // Dealer view
      expect(product.getPriceForRole(UserRole.dealer), equals(product.wholesalePrice));
      expect(product.getWholesalePriceForRole(UserRole.dealer), equals(product.wholesalePrice));

      // Admin view
      expect(product.getWholesalePriceForRole(UserRole.admin), equals(product.wholesalePrice));
    });

    test('Search filter matches title, subtitle, and specs', () {
      productProvider.setSearchQuery('Copper');
      final results = productProvider.getFilteredProductsForRole(UserRole.customer);

      expect(results, isNotEmpty);
      for (final r in results) {
        final matches = r.title.toLowerCase().contains('copper') ||
            r.subtitle.toLowerCase().contains('copper') ||
            r.description.toLowerCase().contains('copper') ||
            r.specs.membraneType.toLowerCase().contains('copper');
        expect(matches, isTrue);
      }
    });

    test('Category filtering isolates targeted product category', () {
      productProvider.setCategory(ProductCategory.commercialPurifiers);
      final commercial = productProvider.getFilteredProductsForRole(UserRole.customer);

      expect(commercial, isNotEmpty);
      for (final p in commercial) {
        expect(p.category, equals(ProductCategory.commercialPurifiers));
      }
    });

    test('Sorting by Price Low to High and High to Low functions accurately', () {
      productProvider.setCategory(ProductCategory.all);
      productProvider.setSearchQuery('');

      // Low to High
      productProvider.setSortOption(ProductSortOption.priceLowToHigh);
      final lowToHigh = productProvider.getFilteredProductsForRole(UserRole.customer);
      for (int i = 0; i < lowToHigh.length - 1; i++) {
        expect(lowToHigh[i].retailPrice, lessThanOrEqualTo(lowToHigh[i + 1].retailPrice));
      }

      // High to Low
      productProvider.setSortOption(ProductSortOption.priceHighToLow);
      final highToLow = productProvider.getFilteredProductsForRole(UserRole.customer);
      for (int i = 0; i < highToLow.length - 1; i++) {
        expect(highToLow[i].retailPrice, greaterThanOrEqualTo(highToLow[i + 1].retailPrice));
      }
    });

    test('In Stock Only sorting excludes out of stock items', () {
      productProvider.setSortOption(ProductSortOption.stockOnly);
      final inStock = productProvider.getFilteredProductsForRole(UserRole.customer);
      for (final p in inStock) {
        expect(p.isInStock, isTrue);
        expect(p.stockQuantity, greaterThan(0));
      }
    });
  });
}
