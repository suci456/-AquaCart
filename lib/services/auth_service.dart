import 'package:flutter/foundation.dart';
import '../core/constants/app_constants.dart';
import '../models/user_model.dart';
import 'mock_data_service.dart';

class AuthService {
  // Pre-configured demo users for instant testing
  static final UserModel demoCustomer = UserModel(
    uid: 'usr-customer-1',
    email: 'customer@aquacart.in',
    displayName: 'Rahul Sharma',
    phone: '+91 98765 43210',
    role: UserRole.customer,
    addresses: [MockDataService.defaultAddress],
    createdAt: DateTime.now().subtract(const Duration(days: 30)),
  );

  static final UserModel demoDealer = UserModel(
    uid: 'usr-dealer-1',
    email: 'dealer@aquatechsolutions.com',
    displayName: 'Vikram Patel',
    phone: '+91 98220 54321',
    role: UserRole.dealer,
    dealerProfile: DealerProfile(
      companyName: 'AquaTech Water Solutions Pvt Ltd',
      gstNumber: '29AABCU9603R1ZM',
      tradeLicense: 'TL-BLR-2024-8849',
      status: 'approved',
      wholesaleTier: 'Gold Partner',
      creditLimit: 250000.0,
    ),
    addresses: [MockDataService.dealerAddress],
    createdAt: DateTime.now().subtract(const Duration(days: 60)),
  );

  static final UserModel demoAdmin = UserModel(
    uid: 'usr-admin-1',
    email: 'admin@aquacart.in',
    displayName: 'Califnco Admin HQ',
    phone: '+91 99000 88888',
    role: UserRole.admin,
    addresses: [MockDataService.defaultAddress],
    createdAt: DateTime.now().subtract(const Duration(days: 120)),
  );

  UserModel _currentUser = demoCustomer;

  UserModel get currentUser => _currentUser;
  bool get isAuthenticated => true;

  // Sign in with credentials
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));

    if (email.contains('dealer')) {
      _currentUser = demoDealer;
    } else if (email.contains('admin')) {
      _currentUser = demoAdmin;
    } else {
      _currentUser = UserModel(
        uid: 'usr-${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        displayName: email.split('@').first,
        phone: '+91 98765 00000',
        role: UserRole.customer,
        addresses: [MockDataService.defaultAddress],
        createdAt: DateTime.now(),
      );
    }
    return _currentUser;
  }

  // Register Customer
  Future<UserModel> registerCustomer({
    required String displayName,
    required String email,
    required String phone,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    _currentUser = UserModel(
      uid: 'usr-${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      displayName: displayName,
      phone: phone,
      role: UserRole.customer,
      addresses: [MockDataService.defaultAddress],
      createdAt: DateTime.now(),
    );
    return _currentUser;
  }

  // Register Dealer with B2B verification documents
  Future<UserModel> registerDealer({
    required String displayName,
    required String email,
    required String phone,
    required String companyName,
    required String gstNumber,
    required String tradeLicense,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    _currentUser = UserModel(
      uid: 'dlr-${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      displayName: displayName,
      phone: phone,
      role: UserRole.dealer,
      dealerProfile: DealerProfile(
        companyName: companyName,
        gstNumber: gstNumber,
        tradeLicense: tradeLicense,
        status: 'approved', // Auto-approved in test mode for immediate evaluation
        wholesaleTier: 'Gold Partner',
        creditLimit: 150000.0,
      ),
      addresses: [MockDataService.dealerAddress],
      createdAt: DateTime.now(),
    );
    return _currentUser;
  }

  // Quick Switcher for evaluation / pair programming
  void switchRole(UserRole targetRole) {
    switch (targetRole) {
      case UserRole.customer:
        _currentUser = demoCustomer;
        break;
      case UserRole.dealer:
        _currentUser = demoDealer;
        break;
      case UserRole.admin:
        _currentUser = demoAdmin;
        break;
    }
  }

  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = demoCustomer;
  }
}
