import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import 'customer_home_screen.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String? selectedOrderId;

  const OrderTrackingScreen({super.key, this.selectedOrderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final orderProv = Provider.of<OrderProvider>(context, listen: false);
      if (auth.user != null) {
        orderProv.loadOrdersForUser(auth.user!.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final orderProv = Provider.of<OrderProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final uid = auth.user?.uid ?? 'usr-customer-1';
    final userOrders = orderProv.getOrdersForUser(uid);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Orders & Tracking'),
      ),
      body: orderProv.isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Loading your order history...'),
                ],
              ),
            )
          : orderProv.errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                        const SizedBox(height: 12),
                        Text(
                          orderProv.errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => orderProv.loadOrdersForUser(uid),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry Loading'),
                        ),
                      ],
                    ),
                  ),
                )
              : userOrders.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 72,
                              color: AppColors.textMuted.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No Orders Found',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'You have not placed any water purifier or spare parts orders yet.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(builder: (_) => const CustomerHomeScreen()),
                                  (route) => false,
                                );
                              },
                              child: const Text('Explore Water Purifiers'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => orderProv.loadOrdersForUser(uid),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: userOrders.length,
                        itemBuilder: (ctx, index) {
                          final order = userOrders[index];
                          return _buildOrderCard(context, order);
                        },
                      ),
                    ),
    );
  }

  Widget _buildOrderCard(BuildContext context, OrderModel order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order number + status pill
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.orderNumber,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.primary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.formatDate(order.createdAt),
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
                _buildStatusPill(order.orderStatus),
              ],
            ),
            const Divider(height: 20),
            // Items
            ...order.items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          item.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => const Icon(Icons.water_drop, size: 20, color: AppColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          Text(
                            'Qty: ${item.quantity} × ${CurrencyFormatter.format(item.unitPrice)}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(item.totalPrice),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 20),
            // Order Tracking Stepper
            const Text(
              'Fulfillment Progress',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildTimeline(order.orderStatus),
            const Divider(height: 20),
            // Payment & Delivery details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment: ${order.paymentMethod.toUpperCase()}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                    if (order.razorpayPaymentId != null)
                      Text(
                        'Ref: ${order.razorpayPaymentId}',
                        style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                      ),
                  ],
                ),
                Text(
                  CurrencyFormatter.format(order.totalAmount),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPill(OrderStatus status) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case OrderStatus.placed:
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade700;
        label = 'Placed';
        break;
      case OrderStatus.confirmed:
        bg = Colors.indigo.shade50;
        fg = Colors.indigo.shade700;
        label = 'Confirmed';
        break;
      case OrderStatus.dispatched:
        bg = Colors.amber.shade50;
        fg = Colors.amber.shade800;
        label = 'Dispatched';
        break;
      case OrderStatus.outForDelivery:
        bg = Colors.orange.shade50;
        fg = Colors.orange.shade800;
        label = 'Out for Delivery';
        break;
      case OrderStatus.delivered:
        bg = Colors.green.shade50;
        fg = Colors.green.shade700;
        label = 'Delivered & Installed';
        break;
      case OrderStatus.cancelled:
        bg = Colors.red.shade50;
        fg = Colors.red.shade700;
        label = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }

  Widget _buildTimeline(OrderStatus currentStatus) {
    final steps = [
      {'title': 'Order Placed', 'status': OrderStatus.placed},
      {'title': 'Confirmed', 'status': OrderStatus.confirmed},
      {'title': 'Dispatched', 'status': OrderStatus.dispatched},
      {'title': 'Delivered', 'status': OrderStatus.delivered},
    ];

    int activeIndex = 0;
    if (currentStatus == OrderStatus.confirmed) activeIndex = 1;
    if (currentStatus == OrderStatus.dispatched || currentStatus == OrderStatus.outForDelivery) activeIndex = 2;
    if (currentStatus == OrderStatus.delivered) activeIndex = 3;

    return Row(
      children: List.generate(steps.length, (i) {
        final isCompleted = i <= activeIndex;
        final isCurrent = i == activeIndex;

        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 3,
                      color: i == 0 ? Colors.transparent : (i <= activeIndex ? AppColors.primary : AppColors.border),
                    ),
                  ),
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: isCompleted ? AppColors.primary : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isCompleted ? AppColors.primary : AppColors.border,
                        width: 2,
                      ),
                    ),
                    child: isCompleted
                        ? const Icon(Icons.check, size: 12, color: Colors.white)
                        : null,
                  ),
                  Expanded(
                    child: Container(
                      height: 3,
                      color: i == steps.length - 1 ? Colors.transparent : (i < activeIndex ? AppColors.primary : AppColors.border),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                steps[i]['title'] as String,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                  color: isCompleted ? AppColors.textPrimary : AppColors.textMuted,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
