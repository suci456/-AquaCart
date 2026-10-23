import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../customer/cart_screen.dart';
import 'dealer_approval_pending_screen.dart';

/// Dealer Bulk Order Screen
///
/// A quick-order grid tailored for high-volume B2B dealers.
/// Shows wholesale prices, MOQ, available stock, and a quantity
/// stepper for each SKU. Dealers can bulk-add multiple products
/// at once and proceed to the shared CartScreen / CheckoutScreen.
class DealerBulkOrderScreen extends StatefulWidget {
  const DealerBulkOrderScreen({super.key});

  @override
  State<DealerBulkOrderScreen> createState() => _DealerBulkOrderScreenState();
}

class _DealerBulkOrderScreenState extends State<DealerBulkOrderScreen> {
  // Per-product quantity controllers: productId -> quantity
  final Map<String, int> _quantities = {};
  ProductCategory _selectedCategory = ProductCategory.all;
  String _searchQuery = '';
  bool _showInStockOnly = false;

  @override
  void initState() {
    super.initState();
    // Pre-populate quantities with MOQ for each product
    final products =
        Provider.of<ProductProvider>(context, listen: false).allProducts;
    for (final p in products) {
      _quantities[p.id] = p.wholesaleMoq;
    }
  }

  void _incrementQty(ProductModel product) {
    setState(() {
      final current = _quantities[product.id] ?? product.wholesaleMoq;
      final next = current + 1;
      _quantities[product.id] =
          next > product.stockQuantity ? product.stockQuantity : next;
    });
  }

  void _decrementQty(ProductModel product) {
    setState(() {
      final current = _quantities[product.id] ?? product.wholesaleMoq;
      // Never go below MOQ
      final next = current - 1;
      _quantities[product.id] =
          next < product.wholesaleMoq ? product.wholesaleMoq : next;
    });
  }

  void _addAllSelected() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isApprovedDealer) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wholesale orders require Admin approval. Access blocked.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final cartProv = Provider.of<CartProvider>(context, listen: false);
    final productProv = Provider.of<ProductProvider>(context, listen: false);
    final filtered = _filteredProducts(productProv.allProducts);
    int addedCount = 0;

    for (final product in filtered) {
      final qty = _quantities[product.id] ?? product.wholesaleMoq;
      if (product.isInStock && qty >= product.wholesaleMoq) {
        cartProv.addToCart(product, isWholesale: true, customQuantity: qty);
        addedCount++;
      }
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$addedCount SKU(s) added to wholesale cart'),
        backgroundColor: AppColors.dealerBadge,
        action: SnackBarAction(
          label: 'View Cart',
          textColor: Colors.white,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CartScreen()),
          ),
        ),
      ),
    );
  }

  List<ProductModel> _filteredProducts(List<ProductModel> all) {
    return all.where((p) {
      final catMatch = _selectedCategory == ProductCategory.all ||
          p.category == _selectedCategory;
      final query = _searchQuery.trim().toLowerCase();
      final searchMatch = query.isEmpty ||
          p.title.toLowerCase().contains(query) ||
          p.subtitle.toLowerCase().contains(query);
      final stockMatch = !_showInStockOnly || p.isInStock;
      return catMatch && searchMatch && stockMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    if (!auth.isApprovedDealer) {
      return const DealerApprovalPendingScreen();
    }

    final productProv = Provider.of<ProductProvider>(context);
    final cartProv = Provider.of<CartProvider>(context);
    final allProducts = productProv.allProducts;
    final filtered = _filteredProducts(allProducts);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bulk Order — Quick Entry',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.white),
            ),
            Text(
              auth.user.displayName,
              style: const TextStyle(fontSize: 11, color: Colors.white60),
            ),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined,
                    color: Colors.white),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CartScreen()),
                ),
              ),
              if (cartProv.itemCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.dealerBadge,
                      shape: BoxShape.circle,
                    ),
                    constraints:
                        const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Text(
                      '${cartProv.itemCount}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search + Filter Bar ─────────────────────────────────────────
          Container(
            color: const Color(0xFF1E293B),
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              children: [
                // Search
                TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search SKU / product name…',
                    hintStyle: const TextStyle(color: Colors.white54),
                    prefixIcon:
                        const Icon(Icons.search, color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white12,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Category chips + in-stock toggle
                SizedBox(
                  height: 34,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _categoryChip(ProductCategory.all, 'All'),
                      _categoryChip(
                          ProductCategory.roPurifiers, 'RO Purifiers'),
                      _categoryChip(ProductCategory.commercialPurifiers,
                          'Commercial'),
                      _categoryChip(
                          ProductCategory.spareFilters, 'Filters'),
                      _categoryChip(
                          ProductCategory.accessories, 'Accessories'),
                      _categoryChip(ProductCategory.amcPlans, 'AMC Plans'),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('In Stock Only',
                            style: TextStyle(fontSize: 11)),
                        selected: _showInStockOnly,
                        onSelected: (v) =>
                            setState(() => _showInStockOnly = v),
                        selectedColor: AppColors.dealerBadge.withOpacity(0.3),
                        checkmarkColor: Colors.white,
                        labelStyle: TextStyle(
                          color:
                              _showInStockOnly ? Colors.white : Colors.white70,
                        ),
                        backgroundColor: Colors.white12,
                        side: BorderSide.none,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Summary Strip ───────────────────────────────────────────────
          if (cartProv.itemCount > 0)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppColors.dealerBadge.withOpacity(0.1),
              child: Row(
                children: [
                  const Icon(Icons.inventory_2_outlined,
                      color: AppColors.dealerBadge, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${cartProv.itemCount} units across '
                      '${cartProv.items.length} SKUs  •  '
                      'Total: ${CurrencyFormatter.format(cartProv.totalAmount)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.dealerBadge,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CartScreen()),
                    ),
                    child: const Text('Review Cart →',
                        style: TextStyle(
                            color: AppColors.dealerBadge, fontSize: 12)),
                  ),
                ],
              ),
            ),

          // ── Product Count Label ─────────────────────────────────────────
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${filtered.length} SKU${filtered.length != 1 ? 's' : ''} shown',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
                if (filtered.isNotEmpty)
                  TextButton.icon(
                    onPressed: _addAllSelected,
                    icon: const Icon(Icons.add_shopping_cart,
                        size: 16, color: AppColors.dealerBadge),
                    label: const Text(
                      'Add All to Cart',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.dealerBadge),
                    ),
                  ),
              ],
            ),
          ),

          // ── Product List ────────────────────────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 56, color: AppColors.textMuted),
                        SizedBox(height: 12),
                        Text('No SKUs match your filters',
                            style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 15)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) =>
                        _BulkOrderRow(
                          product: filtered[i],
                          quantity:
                              _quantities[filtered[i].id] ??
                                  filtered[i].wholesaleMoq,
                          inCart: cartProv.items.containsKey(filtered[i].id),
                          cartQty:
                              cartProv.items[filtered[i].id]?.quantity ?? 0,
                          onIncrement: () => _incrementQty(filtered[i]),
                          onDecrement: () => _decrementQty(filtered[i]),
                          onAddToCart: () {
                            final qty = _quantities[filtered[i].id] ??
                                filtered[i].wholesaleMoq;
                            final added = cartProv.addToCart(
                              filtered[i],
                              isWholesale: true,
                              customQuantity: qty,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  added
                                      ? '${filtered[i].title} × $qty added'
                                      : 'Capped at stock limit for ${filtered[i].title}',
                                ),
                                backgroundColor: added
                                    ? AppColors.dealerBadge
                                    : AppColors.warning,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _categoryChip(ProductCategory cat, String label) {
    final selected = _selectedCategory == cat;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 11)),
        selected: selected,
        onSelected: (_) => setState(() => _selectedCategory = cat),
        selectedColor: AppColors.dealerBadge,
        labelStyle: TextStyle(
          color: selected ? Colors.white : Colors.white70,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
        backgroundColor: Colors.white12,
        side: BorderSide.none,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Row widget for a single SKU in the bulk order list
// ---------------------------------------------------------------------------

class _BulkOrderRow extends StatelessWidget {
  final ProductModel product;
  final int quantity;
  final bool inCart;
  final int cartQty;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onAddToCart;

  const _BulkOrderRow({
    required this.product,
    required this.quantity,
    required this.inCart,
    required this.cartQty,
    required this.onIncrement,
    required this.onDecrement,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final isOutOfStock = !product.isInStock;
    final isAtStockCeiling = quantity >= product.stockQuantity;
    final isAtMoqFloor = quantity <= product.wholesaleMoq;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: inCart ? AppColors.dealerBadge : AppColors.border,
          width: inCart ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Product image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              product.imageUrl,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 60,
                height: 60,
                color: AppColors.surfaceLight,
                child: const Icon(Icons.water_drop,
                    color: AppColors.primary, size: 28),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Title + pricing info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                // Wholesale price (only visible to dealers)
                Text(
                  '${CurrencyFormatter.format(product.wholesalePrice)} / unit',
                  style: const TextStyle(
                    color: AppColors.dealerBadge,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    // MOQ badge
                    _tag('MOQ: ${product.wholesaleMoq}', Colors.purple),
                    const SizedBox(width: 6),
                    // Stock badge
                    if (isOutOfStock)
                      _tag('Out of Stock', AppColors.error)
                    else
                      _tag(
                        product.stockQuantity <= 10
                            ? 'Only ${product.stockQuantity} left'
                            : '${product.stockQuantity} in stock',
                        product.stockQuantity <= 10
                            ? AppColors.warning
                            : AppColors.success,
                      ),
                    if (inCart) ...[
                      const SizedBox(width: 6),
                      _tag('In Cart ($cartQty)', AppColors.dealerBadge),
                    ],
                  ],
                ),
                // Line total preview
                const SizedBox(height: 4),
                Text(
                  'Line total: ${CurrencyFormatter.format(product.wholesalePrice * quantity)}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Quantity stepper + add button
          Column(
            children: [
              // Quantity stepper
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _StepButton(
                      icon: Icons.remove,
                      onTap: isOutOfStock || isAtMoqFloor ? null : onDecrement,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        '$quantity',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                    _StepButton(
                      icon: Icons.add,
                      onTap: isOutOfStock || isAtStockCeiling
                          ? null
                          : onIncrement,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              // Add to cart button
              SizedBox(
                width: 90,
                child: ElevatedButton(
                  onPressed: isOutOfStock ? null : onAddToCart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: inCart
                        ? AppColors.dealerBadge
                        : AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    textStyle: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(inCart ? 'Update' : 'Add'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _StepButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(
          icon,
          size: 16,
          color: onTap == null ? AppColors.textMuted : AppColors.textPrimary,
        ),
      ),
    );
  }
}
