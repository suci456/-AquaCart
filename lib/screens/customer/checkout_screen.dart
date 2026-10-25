import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/product_provider.dart';
import '../../services/mock_data_service.dart';
import '../../services/razorpay_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/maps_address_picker_sheet.dart';
import '../../providers/notification_provider.dart';
import 'order_success_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final RazorpayService _razorpayService = RazorpayService();
  String _selectedPaymentMethod = 'razorpay_test'; // 'razorpay_test', 'cod', 'dealer_credit'
  bool _isProcessing = false;
  late UserAddress _selectedAddress;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _selectedAddress = (auth.user?.addresses.isNotEmpty ?? false)
        ? auth.user!.addresses.first
        : MockDataService.defaultAddress;
  }

  void _processPayment() async {
    final cartProv = Provider.of<CartProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final orderProv = Provider.of<OrderProvider>(context, listen: false);
    final productProv = Provider.of<ProductProvider>(context, listen: false);

    if (cartProv.itemList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart is empty. Please add items before checkout.')),
      );
      return;
    }

    if (_selectedPaymentMethod == 'razorpay_test') {
      final orderNumber = 'AQ-${DateTime.now().year}-${1000 + orderProv.allOrders.length + 1}';

      await _razorpayService.openTestCheckout(
        context: context,
        amount: cartProv.totalAmount,
        orderNumber: orderNumber,
        customerEmail: auth.user!.email,
        customerPhone: auth.user!.phone,
        onSuccess: (paymentId, orderId) async {
          setState(() => _isProcessing = true);
          try {
            // Validate on trusted backend rules & persist
            // SECURITY: Never stores card details; only tokenized payment ID is persisted
            final placedOrder = await orderProv.placeOrder(
              user: auth.user!,
              cartItems: cartProv.itemList,
              trustedCatalog: productProv.allProducts,
              claimedTotal: cartProv.totalAmount,
              shippingAddress: _selectedAddress,
              paymentMethod: 'razorpay_test',
              razorpayPaymentId: paymentId,
            );

            // Decrement stock in catalog
            for (final item in cartProv.itemList) {
              productProv.decrementStock(item.product.id, item.quantity);
            }

            // Dispatch in-app / FCM notification
            if (mounted) {
              Provider.of<NotificationProvider>(context, listen: false)
                  .notifyOrderPlaced(placedOrder);
            }

            cartProv.clearCart();
            setState(() => _isProcessing = false);

            if (!mounted) return;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => OrderSuccessScreen(order: placedOrder),
              ),
            );
          } catch (e) {
            setState(() => _isProcessing = false);
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Order processing failed: $e'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        onFailure: (code, message) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment Failed: $message'),
              backgroundColor: AppColors.error,
            ),
          );
        },
      );
    } else {
      // Cash on Delivery (COD) or Dealer Credit
      setState(() => _isProcessing = true);
      try {
        final placedOrder = await orderProv.placeOrder(
          user: auth.user!,
          cartItems: cartProv.itemList,
          trustedCatalog: productProv.allProducts,
          claimedTotal: cartProv.totalAmount,
          shippingAddress: _selectedAddress,
          paymentMethod: _selectedPaymentMethod,
        );

        // Decrement stock
        for (final item in cartProv.itemList) {
          productProv.decrementStock(item.product.id, item.quantity);
        }

        // Dispatch in-app / FCM notification
        if (mounted) {
          Provider.of<NotificationProvider>(context, listen: false)
              .notifyOrderPlaced(placedOrder);
        }

        cartProv.clearCart();
        setState(() => _isProcessing = false);

        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => OrderSuccessScreen(order: placedOrder),
          ),
        );
      } catch (e) {
        setState(() => _isProcessing = false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order creation failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final cartProv = Provider.of<CartProvider>(context);
    final isDealer = auth.isDealer;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Checkout & Payment'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Delivery Address Card
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.location_on, color: AppColors.primary, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Delivery & Installation Address',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          final updated = await MapsAddressPickerSheet.show(
                            context,
                            initialAddress: _selectedAddress,
                          );
                          if (updated != null) {
                            setState(() => _selectedAddress = updated);
                          }
                        },
                        icon: const Icon(Icons.edit_location_alt, size: 14),
                        label: const Text('Change / Map Pin', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Text(
                    auth.user?.displayName ?? 'AquaCart Customer',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    auth.user?.phone ?? '+91 98765 43210',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _selectedAddress.fullAddress,
                    style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.3),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Payment Method Selection
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
                    'Select Payment Mode',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  // Razorpay Test
                  _paymentOption(
                    id: 'razorpay_test',
                    title: 'Razorpay Online Payment (Test Mode)',
                    subtitle: 'UPI, Credit/Debit Cards, Netbanking sandbox',
                    icon: Icons.bolt,
                    badge: 'INSTANT CONFIRMATION',
                    badgeColor: Colors.blue,
                  ),
                  const SizedBox(height: 10),
                  // Cash on Delivery
                  _paymentOption(
                    id: 'cod',
                    title: 'Cash on Delivery / Pay on Installation',
                    subtitle: 'Pay technician via cash or QR after setup',
                    icon: Icons.payments_outlined,
                  ),
                  if (isDealer) ...[
                    const SizedBox(height: 10),
                    // Dealer Credit
                    _paymentOption(
                      id: 'dealer_credit',
                      title: 'Dealer 15-Day Credit Line',
                      subtitle: 'Available Credit: ₹2,50,000 (Gold Partner terms)',
                      icon: Icons.account_balance_wallet_outlined,
                      badge: 'B2B ONLY',
                      badgeColor: AppColors.dealerBadge,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Order Review Summary
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
                    'Order Summary',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  ...cartProv.itemList.map(
                    (item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${item.quantity}x ${item.product.title}',
                              style: const TextStyle(fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.format(item.totalPrice),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Amount Payable', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        CurrencyFormatter.format(cartProv.totalAmount),
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: isDealer ? AppColors.dealerBadge : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            AppButton(
              text: _selectedPaymentMethod == 'razorpay_test'
                  ? 'Pay with Razorpay Test Mode (${CurrencyFormatter.format(cartProv.totalAmount)})'
                  : 'Place Order (${CurrencyFormatter.format(cartProv.totalAmount)})',
              isLoading: _isProcessing,
              gradient: isDealer ? AppColors.dealerGradient : AppColors.aquaGradient,
              onPressed: _processPayment,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _paymentOption({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    String? badge,
    Color? badgeColor,
  }) {
    final isSelected = _selectedPaymentMethod == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethod = id),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.04) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: (badgeColor ?? AppColors.primary).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              color: badgeColor ?? AppColors.primary,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: id,
              groupValue: _selectedPaymentMethod,
              activeColor: AppColors.primary,
              onChanged: (val) {
                if (val != null) setState(() => _selectedPaymentMethod = val);
              },
            ),
          ],
        ),
      ),
    );
  }
}
