import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../customer/customer_home_screen.dart';
import '../dealer/dealer_dashboard_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import 'login_screen.dart';

class RoleGate extends StatelessWidget {
  const RoleGate({super.key});

  // Static helper to route a user directly to their authorized dashboard
  static void navigateForRole(BuildContext context, UserRole role) {
    Widget destination;
    switch (role) {
      case UserRole.customer:
        destination = const CustomerHomeScreen();
        break;
      case UserRole.dealer:
        destination = const DealerDashboardScreen();
        break;
      case UserRole.admin:
        destination = const AdminDashboardScreen();
        break;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => destination),
      (route) => false,
    );
  }

  // Route Guard: Enforces that the current user has one of the allowed roles
  static bool guardRoute(BuildContext context, {required List<UserRole> allowedRoles}) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAuthenticated || auth.user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      });
      return false;
    }

    if (!allowedRoles.contains(auth.user!.role)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Access Restricted: ${auth.user!.role.name.toUpperCase()} role is not authorized for this view.',
            ),
            backgroundColor: AppColors.error,
          ),
        );
        navigateForRole(context, auth.user!.role);
      });
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    // Initializing session from storage
    if (!auth.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Initializing AquaCart Session...',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Unauthenticated state
    if (!auth.isAuthenticated || auth.user == null) {
      return const LoginScreen();
    }

    // Authenticated role-based dashboard routing
    switch (auth.user!.role) {
      case UserRole.customer:
        return const CustomerHomeScreen();
      case UserRole.dealer:
        return const DealerDashboardScreen();
      case UserRole.admin:
        return const AdminDashboardScreen();
    }
  }
}
