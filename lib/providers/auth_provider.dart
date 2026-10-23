import 'package:flutter/foundation.dart';
import '../core/constants/app_constants.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get user => _authService.currentUser;
  bool get isAuthenticated => _authService.isAuthenticated;
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  UserRole? get currentRole => user?.role;
  bool get isCustomer => user?.isCustomer ?? false;
  bool get isDealer => user?.isDealer ?? false;
  bool get isAdmin => user?.isAdmin ?? false;

  // Initialize session from SharedPreferences on app startup
  Future<void> initializeAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.restoreSession();
    } catch (e) {
      debugPrint('Error restoring auth session: $e');
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  // Clear any active error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Sign In with email & password
  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.signIn(email: email, password: password);
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _isLoading = false;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'An unexpected error occurred. Please try again.';
      notifyListeners();
      return false;
    }
  }

  // Register Customer (Role is strictly locked to Customer)
  Future<bool> registerCustomer({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.registerCustomer(
        displayName: name,
        email: email,
        phone: phone,
        password: password,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _isLoading = false;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to create customer account: $e';
      notifyListeners();
      return false;
    }
  }

  // Register Dealer with business & GST verification (Role is strictly locked to Dealer)
  Future<bool> registerDealer({
    required String name,
    required String email,
    required String phone,
    required String companyName,
    required String gstNumber,
    required String tradeLicense,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.registerDealer(
        displayName: name,
        email: email,
        phone: phone,
        companyName: companyName,
        gstNumber: gstNumber,
        tradeLicense: tradeLicense,
        password: password,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _isLoading = false;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to submit dealer registration: $e';
      notifyListeners();
      return false;
    }
  }

  // Instant role switch for evaluator review
  void switchRole(UserRole role) {
    _authService.switchRole(role);
    notifyListeners();
  }

  // Sign out and wipe session
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.signOut();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
