import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/currency_formatter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/service_provider.dart';
import '../../models/order_model.dart';
import '../../models/service_request_model.dart';
import '../../widgets/product_image.dart';
import '../customer/customer_home_screen.dart';
import '../auth/login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAssignTechDialog(BuildContext context, ServiceRequestModel req) {
    final techNameCtrl = TextEditingController(text: 'Ramesh Gowda');
    final techPhoneCtrl = TextEditingController(text: '+91 98860 99887');
    final serviceProv = Provider.of<ServiceProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Assign Technician: ${req.requestNumber}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: techNameCtrl,
              decoration: const InputDecoration(labelText: 'Technician Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: techPhoneCtrl,
              decoration: const InputDecoration(labelText: 'Contact Phone'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              serviceProv.assignTechnician(
                req.id,
                techNameCtrl.text.trim(),
                techPhoneCtrl.text.trim(),
                'TECH-${DateTime.now().millisecond}',
              );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Technician assigned successfully!'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Confirm Dispatch'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final orderProv = Provider.of<OrderProvider>(context);
    final serviceProv = Provider.of<ServiceProvider>(context);
    final productProv = Provider.of<ProductProvider>(context);

    // Route Guard check
    if (!auth.isAdmin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Access Denied: Admin authorization required.'),
            backgroundColor: AppColors.error,
          ),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const CustomerHomeScreen()),
        );
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final totalRevenue = orderProv.allOrders.fold(0.0, (sum, o) => sum + o.totalAmount);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1B4B), // Deep indigo
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.admin_panel_settings, color: Colors.purpleAccent, size: 20),
                SizedBox(width: 8),
                Text(
                  'Admin Operations Console',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
            Text(
              '${auth.user?.displayName ?? "Admin"} (Authorized Root)',
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            tooltip: 'Sign Out',
            onPressed: () async {
              await auth.signOut();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.purpleAccent,
          isScrollable: true,
          tabs: [
            const Tab(text: 'Overview KPIs'),
            Tab(text: 'Orders (${orderProv.allOrders.length})'),
            Tab(text: 'Service Queue (${serviceProv.allRequests.length})'),
            Tab(text: 'Products (${productProv.allProducts.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Overview KPIs
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Metrics grid
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.4,
                  children: [
                    _kpiTile('Platform Revenue', CurrencyFormatter.format(totalRevenue), Icons.account_balance_wallet, Colors.blue),
                    _kpiTile('Total Orders', '${orderProv.allOrders.length}', Icons.shopping_bag, Colors.green),
                    _kpiTile('Service Tickets', '${serviceProv.allRequests.length}', Icons.handyman, Colors.amber),
                    _kpiTile('Catalog SKUs', '${productProv.allProducts.length}', Icons.inventory_2, Colors.purple),
                  ],
                ),
                const SizedBox(height: 24),
                // Security Notice
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.purple.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.shield_outlined, color: Colors.deepPurple, size: 24),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Admin Security Rule Active: Self-assigned Admin registration is strictly blocked by Cloud Firestore rules and client validation.',
                          style: TextStyle(fontSize: 12, color: Colors.deepPurple, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tab 2: Orders
          ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orderProv.allOrders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (ctx, index) {
              final o = orderProv.allOrders[index];
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(o.orderNumber, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                        Text(
                          CurrencyFormatter.format(o.totalAmount),
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('${o.items.length} item(s) • Method: ${o.paymentMethod}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Status: ${o.orderStatus.name.toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                        PopupMenuButton<OrderStatus>(
                          onSelected: (newStatus) => orderProv.updateOrderStatus(o.id, newStatus),
                          itemBuilder: (c) => OrderStatus.values.map(
                            (s) => PopupMenuItem(value: s, child: Text(s.name)),
                          ).toList(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              children: [
                                Text('Update', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                                Icon(Icons.arrow_drop_down, color: AppColors.primary, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),

          // Tab 3: Service Queue
          ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: serviceProv.allRequests.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (ctx, index) {
              final req = serviceProv.allRequests[index];
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(req.requestNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: req.status == ServiceStatus.assigned ? Colors.green.shade50 : Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            req.status.name.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: req.status == ServiceStatus.assigned ? Colors.green.shade700 : Colors.amber.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('${req.customerName} (${req.customerPhone})', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    Text('Model: ${req.purifierBrandModel} • Slot: ${req.preferredSlot}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    if (req.assignedTechnician != null)
                      Text('Assigned Tech: ${req.assignedTechnician!.name} (${req.assignedTechnician!.phone})', style: const TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.bold))
                    else
                      ElevatedButton(
                        onPressed: () => _showAssignTechDialog(context, req),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: Size.zero,
                        ),
                        child: const Text('Assign Technician', style: TextStyle(fontSize: 11)),
                      ),
                  ],
                ),
              );
            },
          ),

          // Tab 4: Products Catalog List
          ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: productProv.allProducts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (ctx, index) {
              final p = productProv.allProducts[index];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    ProductImageThumb(
                      imageUrl: p.imageUrl,
                      localAsset: p.localAssetImage,
                      size: 50,
                      radius: 8,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('Retail: ${CurrencyFormatter.format(p.retailPrice)} • Wholesale: ${CurrencyFormatter.format(p.wholesalePrice)}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          Text('Stock: ${p.stockQuantity} • Wholesale MOQ: ${p.wholesaleMoq}', style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _kpiTile(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: color)),
          const SizedBox(height: 2),
          Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
