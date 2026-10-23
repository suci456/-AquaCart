import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/currency_formatter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../widgets/product_card.dart';
import '../../widgets/role_badge.dart';
import '../customer/customer_home_screen.dart';
import '../customer/cart_screen.dart';
import '../customer/product_detail_screen.dart';
import '../customer/order_tracking_screen.dart';
import '../profile_screen.dart';
import 'dealer_bulk_order_screen.dart';

class DealerDashboardScreen extends StatelessWidget {
  const DealerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final productProv = Provider.of<ProductProvider>(context);
    final cartProv = Provider.of<CartProvider>(context);
    final orderProv = Provider.of<OrderProvider>(context);

    final dealerProfile = auth.user.dealerProfile;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B), // Dark slate for B2B portal
        foregroundColor: Colors.white,
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.storefront, color: AppColors.dealerBadge, size: 20),
                const SizedBox(width: 8),
                Text(
                  dealerProfile?.companyName.isNotEmpty == true
                      ? dealerProfile!.companyName
                      : 'AquaTech Dealer Portal',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            Text(
              'GSTIN: ${dealerProfile?.gstNumber ?? "29AABCU9603R1ZM"} • ${dealerProfile?.wholesaleTier ?? "Gold Partner"}',
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          // Role switcher chip
          TextButton.icon(
            onPressed: () {
              auth.switchRole(UserRole.customer);
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const CustomerHomeScreen()),
              );
            },
            icon: const Icon(Icons.swap_horiz, size: 16, color: Colors.amberAccent),
            label: const Text(
              'Switch to Retail',
              style: TextStyle(color: Colors.amberAccent, fontSize: 11),
            ),
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CartScreen()),
                  );
                },
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
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Text(
                      '${cartProv.itemCount}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // B2B Wholesale Perks & Credit Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppColors.dealerGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.dealerBadge.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Wholesale Credit Line',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '₹2,50,000.00',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '15-Day Terms',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white24, height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tier: Gold Wholesale Partner',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Up to 40% Margin Active',
                        style: TextStyle(color: Colors.amber.shade100, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Quick metrics row
            Row(
              children: [
                Expanded(
                  child: _metricCard(
                    title: 'Active Orders',
                    value: '${orderProv.allOrders.length}',
                    icon: Icons.local_shipping_outlined,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _metricCard(
                    title: 'Avg Margin',
                    value: '35.4%',
                    icon: Icons.trending_up,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _metricCard(
                    title: 'Catalog Items',
                    value: '${productProv.allProducts.length}',
                    icon: Icons.inventory_2_outlined,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Quick Actions ──────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.dealerBadge,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.playlist_add_check, size: 20),
                    label: const Text(
                      'Bulk Order\nQuick Entry',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const DealerBulkOrderScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.dealerBadge,
                      side: const BorderSide(color: AppColors.dealerBadge),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.receipt_long, size: 20),
                    label: const Text(
                      'Order\nHistory',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const OrderTrackingScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Wholesale Catalog Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Wholesale Price List (B2B)',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Prices reflect tiered factory rates with enforced MOQ',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.receipt_long, color: AppColors.dealerBadge),
                  tooltip: 'Order History',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const OrderTrackingScreen()),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Wholesale Products Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: productProv.allProducts.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.58,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (ctx, index) {
                final product = productProv.allProducts[index];
                return ProductCard(
                  product: product,
                  userRole: UserRole.dealer,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ProductDetailScreen(productId: product.id),
                      ),
                    );
                  },
                  onAddToCart: () {
                    cartProv.addToCart(product, isWholesale: true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Added ${product.wholesaleMoq}x ${product.title} (MOQ satisfied)'),
                        backgroundColor: AppColors.dealerBadge,
                        action: SnackBarAction(
                          label: 'View Cart',
                          textColor: Colors.white,
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const CartScreen()),
                            );
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _metricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
