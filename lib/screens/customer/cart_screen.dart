import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/currency_formatter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/product_image.dart';
import 'checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cartProv = Provider.of<CartProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final isDealer = auth.isDealer;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isDealer ? 'Wholesale Bulk Cart' : 'My Shopping Cart'),
        actions: [
          if (cartProv.itemList.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => cartProv.clearCart(),
            ),
        ],
      ),
      body: cartProv.itemList.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.remove_shopping_cart_outlined,
                    size: 72,
                    color: AppColors.textMuted.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Your cart is empty',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Browse our high-performance water purifiers and filters.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Start Shopping'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dealer MOQ warning if any item fails MOQ
                  if (isDealer && !cartProv.allWholesaleMoqMet)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Wholesale MOQ Required',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Colors.amber.shade900,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Some items are below their minimum wholesale order quantity. Increase quantities to proceed with dealer pricing.',
                                  style: TextStyle(fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Cart item list
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: cartProv.itemList.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, index) {
                      final item = cartProv.itemList[index];
                      final meetsMoq = item.meetsWholesaleMoq;

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: !meetsMoq ? Colors.amber.shade400 : AppColors.border,
                            width: !meetsMoq ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                             // Product Thumbnail
                            ProductImageThumb(
                              product: item.product,
                              size: 72,
                              radius: 10,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.product.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    CurrencyFormatter.format(item.unitPrice),
                                    style: TextStyle(
                                      color: item.isWholesale ? AppColors.dealerBadge : AppColors.primary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (item.isWholesale) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'Wholesale MOQ: ${item.product.wholesaleMoq} units',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: meetsMoq ? AppColors.success : AppColors.error,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  // Stepper & Delete
                                  Row(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(color: AppColors.border),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            InkWell(
                                              onTap: () => cartProv.updateQuantity(
                                                item.product.id,
                                                item.quantity - 1,
                                              ),
                                              child: const Padding(
                                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                child: Icon(Icons.remove, size: 14),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 8),
                                              child: Text(
                                                '${item.quantity}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                            InkWell(
                                              onTap: () {
                                                final success = cartProv.updateQuantity(
                                                  item.product.id,
                                                  item.quantity + 1,
                                                );
                                                if (!success) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text('Maximum available stock for ${item.product.title} is ${item.product.stockQuantity} units.'),
                                                      duration: const Duration(seconds: 1),
                                                    ),
                                                  );
                                                }
                                              },
                                              child: const Padding(
                                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                child: Icon(Icons.add, size: 14),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        CurrencyFormatter.format(item.totalPrice),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  // Bill Summary Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Price Details & Taxes',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 12),
                        _billRow('Items Subtotal', CurrencyFormatter.format(cartProv.subtotal)),
                        const SizedBox(height: 8),
                        _billRow('18% GST (Tax Invoice)', CurrencyFormatter.format(cartProv.taxAmount)),
                        const SizedBox(height: 8),
                        _billRow(
                          'Delivery Fee',
                          cartProv.deliveryFee == 0 ? 'FREE' : CurrencyFormatter.format(cartProv.deliveryFee),
                          valueColor: cartProv.deliveryFee == 0 ? AppColors.success : null,
                        ),
                        const Divider(height: 24),
                        _billRow(
                          'Grand Total',
                          CurrencyFormatter.format(cartProv.totalAmount),
                          isBold: true,
                          valueColor: isDealer ? AppColors.dealerBadge : AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
      bottomNavigationBar: cartProv.itemList.isEmpty
          ? null
          : Container(
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
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Payable',
                          style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                        Text(
                          CurrencyFormatter.format(cartProv.totalAmount),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: isDealer ? AppColors.dealerBadge : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AppButton(
                        text: isDealer && !cartProv.allWholesaleMoqMet
                            ? 'Fix MOQ Quantities'
                            : 'Proceed to Checkout',
                        gradient: isDealer ? AppColors.dealerGradient : AppColors.aquaGradient,
                        onPressed: isDealer && !cartProv.allWholesaleMoqMet
                            ? null
                            : () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const CheckoutScreen()),
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

  Widget _billRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 14 : 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: isBold ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 16 : 13,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w600,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
