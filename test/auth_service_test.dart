import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aquacart/core/constants/app_constants.dart';
import 'package:aquacart/models/user_model.dart';
import 'package:aquacart/services/auth_service.dart';
import 'package:aquacart/services/firestore_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthService & Role Security Tests', () {
    late AuthService authService;
    late FirestoreService firestoreService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      authService = AuthService();
      firestoreService = FirestoreService();
    });

    test('Customer registration produces a verified user with role customer', () async {
      final user = await authService.registerCustomer(
        displayName: 'Rahul Sharma',
        email: 'rahul.test@aquacart.in',
        phone: '9876543210',
        password: 'password123',
      );

      expect(user.displayName, equals('Rahul Sharma'));
      expect(user.email, equals('rahul.test@aquacart.in'));
      expect(user.role, equals(UserRole.customer));
      expect(user.isCustomer, isTrue);
      expect(user.isDealer, isFalse);
      expect(user.isAdmin, isFalse);
      expect(authService.currentUser, equals(user));
      expect(authService.isAuthenticated, isTrue);
    });

    test('Dealer registration produces a verified user with role dealer and wholesale profile', () async {
      final dealer = await authService.registerDealer(
        displayName: 'Vikram Patel',
        email: 'dealer.test@aquatech.com',
        phone: '9822054321',
        companyName: 'AquaTech Water Solutions Pvt Ltd',
        gstNumber: '29AABCU9603R1ZM',
        tradeLicense: 'TL-BLR-2024-8849',
        password: 'dealerPass123',
      );

      expect(dealer.displayName, equals('Vikram Patel'));
      expect(dealer.role, equals(UserRole.dealer));
      expect(dealer.isDealer, isTrue);
      expect(dealer.dealerProfile, isNotNull);
      expect(dealer.dealerProfile!.companyName, equals('AquaTech Water Solutions Pvt Ltd'));
      expect(dealer.dealerProfile!.gstNumber, equals('29AABCU9603R1ZM'));
    });

    test('CRITICAL SECURITY: Self-assigned Admin registration is strictly blocked', () async {
      final fakeAdmin = UserModel(
        uid: 'hacker-uid',
        email: 'attacker@malicious.com',
        displayName: 'Fake Admin',
        phone: '9999999999',
        role: UserRole.admin, // Attempting self-assignment
        createdAt: DateTime.now(),
      );

      expect(
        () => firestoreService.createUserProfile(fakeAdmin),
        throwsA(isA<SecurityException>()),
      );
    });

    test('User login restores role and session state', () async {
      final user = await authService.signIn(
        email: 'customer@aquacart.in',
        password: 'password123',
      );

      expect(user.email, equals('customer@aquacart.in'));
      expect(authService.isAuthenticated, isTrue);
    });

    test('Sign out clears session and resets currentUser to null', () async {
      // First sign in
      await authService.signIn(
        email: 'customer@aquacart.in',
        password: 'password123',
      );
      expect(authService.isAuthenticated, isTrue);

      // Now sign out
      await authService.signOut();
      expect(authService.currentUser, isNull);
      expect(authService.isAuthenticated, isFalse);
    });

    test('Session persistence restores user on app reboot', () async {
      // Register a customer
      final originalUser = await authService.registerCustomer(
        displayName: 'Session User',
        email: 'session@aquacart.in',
        phone: '9876543210',
        password: 'password123',
      );

      // Create new AuthService instance simulating app reboot
      final rebootAuthService = AuthService();
      final restoredUser = await rebootAuthService.restoreSession();

      expect(restoredUser, isNotNull);
      expect(restoredUser!.email, equals(originalUser.email));
      expect(restoredUser.role, equals(originalUser.role));
    });

    test('Evaluation persona switcher correctly sets Customer, Dealer, and Admin roles', () {
      authService.switchRole(UserRole.customer);
      expect(authService.currentUser?.role, equals(UserRole.customer));
      expect(authService.currentUser?.isCustomer, isTrue);

      authService.switchRole(UserRole.dealer);
      expect(authService.currentUser?.role, equals(UserRole.dealer));
      expect(authService.currentUser?.isDealer, isTrue);

      authService.switchRole(UserRole.admin);
      expect(authService.currentUser?.role, equals(UserRole.admin));
      expect(authService.currentUser?.isAdmin, isTrue);
    });
  });
}
