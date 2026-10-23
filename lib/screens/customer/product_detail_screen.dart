import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/currency_formatter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/app_button.dart';
import 'cart_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final productProv = Provider.of<ProductProvider>(context, listen: false);
    final product = productProv.getProductById(widget.productId);
    if (auth.isDealer && product != null) {
      _quantity = product.wholesaleMoq;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final productProv = Provider.of<ProductProvider>(context);
    final cartProv = Provider.of<CartProvider>(context);

    final product = productProv.getProductById(widget.productId);
    if (product == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Product not found')),
      );
    }

    final isDealer = auth.isDealer;
    final unitPrice = isDealer ? product.wholesalePrice : product.retailPrice;
    final subtotal = unitPrice * _quantity;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          product.title,
          style: const TextStyle(fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CartScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Hero Image
            Container(
              height: 280,
              width: double.infinity,
              color: AppColors.background,
              child: Image.network(
                product.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) => const Center(
                  child: Icon(Icons.water_drop, size: 80, color: AppColors.primary),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dealer Wholesale Alert Banner
                  if (isDealer)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.dealerBadge.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.dealerBadge.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified, color: AppColors.dealerBadge, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'B2B Wholesale Pricing Active',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: AppColors.dealerBadge,
                                  ),
                                ),
                                Text(
                                  'Minimum Order Quantity: ${product.wholesaleMoq} units. You save ${CurrencyFormatter.format(product.mrp - product.wholesalePrice)} per unit!',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Rating & Review
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star, size: 14, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              product.rating.toString(),
                              style: TextStyle(
                                color: Colors.amber.shade900,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${product.reviewCount} Verified Ratings',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          AppConstants.categoryLabels[product.category] ?? '',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Title & Subtitle
                  Text(
                    product.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    product.subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Price breakdown
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        CurrencyFormatter.format(unitPrice),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: isDealer ? AppColors.dealerBadge : AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'MRP ${CurrencyFormatter.format(product.mrp)}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textMuted,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Text(
                          '${isDealer ? product.wholesaleDiscountPercentage : product.retailDiscountPercentage}% OFF',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Inclusive of all taxes & free standard delivery',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 10),
                  // Live Stock Availability Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: product.stockQuantity > 5
                          ? Colors.green.shade50
                          : product.stockQuantity > 0
                              ? Colors.amber.shade50
                              : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: product.stockQuantity > 5
                            ? Colors.green.shade300
                            : product.stockQuantity > 0
                                ? Colors.amber.shade300
                                : Colors.red.shade300,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          product.stockQuantity > 0 ? Icons.check_circle_outline : Icons.cancel_outlined,
                          size: 14,
                          color: product.stockQuantity > 5
                              ? Colors.green.shade800
                              : product.stockQuantity > 0
                                  ? Colors.amber.shade900
                                  : Colors.red.shade800,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          product.stockStatus,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: product.stockQuantity > 5
                                ? Colors.green.shade800
                                : product.stockQuantity > 0
                                    ? Colors.amber.shade900
                                    : Colors.red.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 32),
                  // Product Description
                  const Text(
                    'About this Water Purifier',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Technical Specifications Card
                  const Text(
                    'Technical Specifications',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        _specRow('Purification Stages', '${product.specs.stages} Stages (Sediment + Carbon + RO + UV + UF + Alkaline)'),
                        const Divider(height: 18),
                        _specRow('Purification Capacity', product.specs.capacity),
                        const Divider(height: 18),
                        _specRow('Membrane Type', product.specs.membraneType),
                        const Divider(height: 18),
                        _specRow('TDS Reduction Limit', product.specs.tdsReduction),
                        const Divider(height: 18),
                        _specRow('Warranty & AMC', product.specs.warranty),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Quantity stepper
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 16),
                      onPressed: () {
                        final minQty = isDealer ? product.wholesaleMoq : 1;
                        if (_quantity > minQty) {
                          setState(() => _quantity--);
                        }
                      },
                    ),
                    Text(
                      '$_quantity',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 16),
                      onPressed: _quantity < product.stockQuantity
                          ? () => setState(() => _quantity++)
                          : () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Cannot add more. Available stock is ${product.stockQuantity} units.'),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              // Add to cart button with out-of-stock guard
              Expanded(
                child: AppButton(
                  text: !product.isInStock
                      ? 'Out of Stock'
                      : 'Add to Cart (${CurrencyFormatter.format(subtotal)})',
                  gradient: isDealer ? AppColors.dealerGradient : AppColors.aquaGradient,
                  onPressed: !product.isInStock
                      ? null
                      : () {
                          final added = cartProv.addToCart(
                            product,
                            isWholesale: isDealer,
                            customQuantity: _quantity,
                          );
                          if (!added) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Capped at maximum available stock (${product.stockQuantity} units).'),
                              ),
                            );
                          }
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const CartScreen()),
                          );
                        },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _specRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
