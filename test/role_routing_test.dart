import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aquacart/core/constants/app_constants.dart';
import 'package:aquacart/providers/auth_provider.dart';
import 'package:aquacart/providers/product_provider.dart';
import 'package:aquacart/providers/cart_provider.dart';
import 'package:aquacart/providers/order_provider.dart';
import 'package:aquacart/providers/service_provider.dart';
import 'package:aquacart/screens/auth/role_gate.dart';
import 'package:aquacart/screens/auth/login_screen.dart';
import 'package:aquacart/screens/customer/customer_home_screen.dart';
import 'package:aquacart/screens/dealer/dealer_dashboard_screen.dart';
import 'package:aquacart/screens/admin/admin_dashboard_screen.dart';

Widget createTestApp({required AuthProvider authProvider, Widget? child}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
      ChangeNotifierProvider<ProductProvider>(create: (_) => ProductProvider()),
      ChangeNotifierProvider<CartProvider>(create: (_) => CartProvider()),
      ChangeNotifierProvider<OrderProvider>(create: (_) => OrderProvider()),
      ChangeNotifierProvider<ServiceProvider>(create: (_) => ServiceProvider()),
    ],
    child: MaterialApp(
      home: child ?? const RoleGate(),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RoleGate & Dashboard Routing Widget Tests', () {
    late AuthProvider authProvider;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      authProvider = AuthProvider();
    });

    testWidgets('Unauthenticated user is routed to LoginScreen', (tester) async {
      await authProvider.initializeAuth();
      await authProvider.signOut();

      await tester.pumpWidget(createTestApp(authProvider: authProvider));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Sign In to AquaCart'), findsOneWidget);
    });

    testWidgets('Authenticated Customer is routed to CustomerHomeScreen', (tester) async {
      await authProvider.initializeAuth();
      authProvider.switchRole(UserRole.customer);

      await tester.pumpWidget(createTestApp(authProvider: authProvider));
      await tester.pumpAndSettle();

      expect(find.byType(CustomerHomeScreen), findsOneWidget);
      expect(find.text('AquaCart'), findsOneWidget);
    });

    testWidgets('Authenticated Dealer is routed to DealerDashboardScreen', (tester) async {
      await authProvider.initializeAuth();
      authProvider.switchRole(UserRole.dealer);

      await tester.pumpWidget(createTestApp(authProvider: authProvider));
      await tester.pumpAndSettle();

      expect(find.byType(DealerDashboardScreen), findsOneWidget);
      expect(find.text('Wholesale Price List (B2B)'), findsOneWidget);
    });

    testWidgets('Authenticated Admin is routed to AdminDashboardScreen', (tester) async {
      await authProvider.initializeAuth();
      authProvider.switchRole(UserRole.admin);

      await tester.pumpWidget(createTestApp(authProvider: authProvider));
      await tester.pumpAndSettle();

      expect(find.byType(AdminDashboardScreen), findsOneWidget);
      expect(find.text('Admin Operations Console'), findsOneWidget);
    });
  });
}
