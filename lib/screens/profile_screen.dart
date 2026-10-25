import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/role_badge.dart';
import 'customer/customer_home_screen.dart';
import 'dealer/dealer_dashboard_screen.dart';
import 'customer/order_tracking_screen.dart';
import 'customer/service_booking_screen.dart';
import 'auth/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Account & Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // User Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: auth.isDealer ? AppColors.dealerBadge.withOpacity(0.15) : AppColors.primary.withOpacity(0.15),
                    child: Icon(
                      auth.isDealer ? Icons.storefront : Icons.person,
                      size: 32,
                      color: auth.isDealer ? AppColors.dealerBadge : AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.displayName ?? 'AquaCart User',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.email ?? 'support@aquacart.in',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 6),
                        RoleBadge(role: user?.role ?? UserRole.customer, isCompact: true),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Fast Role Switcher Box for Califnco Assignment Testing
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.tune, color: AppColors.primary, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Assignment Persona Switcher',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Toggle between Customer, Dealer Wholesale, and Admin perspectives:',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _roleOption(
                          context: context,
                          label: 'Customer',
                          role: UserRole.customer,
                          isSelected: auth.isCustomer,
                          onTap: () {
                            auth.switchRole(UserRole.customer);
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (_) => const CustomerHomeScreen()),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _roleOption(
                          context: context,
                          label: 'Dealer B2B',
                          role: UserRole.dealer,
                          isSelected: auth.isDealer,
                          onTap: () {
                            auth.switchRole(UserRole.dealer);
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (_) => const DealerDashboardScreen()),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _roleOption(
                          context: context,
                          label: 'Admin',
                          role: UserRole.admin,
                          isSelected: auth.isAdmin,
                          onTap: () {
                            auth.switchRole(UserRole.admin);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Navigation Links
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _menuTile(
                    icon: Icons.receipt_long_outlined,
                    title: 'My Orders & Purchases',
                    subtitle: 'Order tracking, delivery status & GST invoices',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const OrderTrackingScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  _menuTile(
                    icon: Icons.handyman_outlined,
                    title: 'Service & Maintenance Requests',
                    subtitle: 'Track installation & filter replacement tickets',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ServiceBookingScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  _menuTile(
                    icon: Icons.location_on_outlined,
                    title: 'Saved Installation Addresses',
                    subtitle: (user?.addresses.isNotEmpty ?? false) ? user!.addresses.first.city : 'Bengaluru',
                    onTap: () {},
                  ),
                  if (auth.isDealer && user?.dealerProfile != null) ...[
                    const Divider(height: 1),
                    _menuTile(
                      icon: Icons.verified_outlined,
                      title: 'Dealer Wholesale Credentials',
                      subtitle: 'GST: ${user!.dealerProfile!.gstNumber} • ${user.dealerProfile!.wholesaleTier}',
                      onTap: () {},
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () async {
                await auth.signOut();
                if (!context.mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.logout, size: 18, color: AppColors.error),
              label: const Text('Sign Out', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                side: const BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _roleOption({
    required BuildContext context,
    required String label,
    required UserRole role,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _menuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      trailing: const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
      onTap: onTap,
    );
  }
}
