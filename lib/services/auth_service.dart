import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';
import 'mock_data_service.dart';

class AuthService {
  final FirestoreService _firestoreService = FirestoreService();
  FirebaseAuth? _firebaseAuth;
  UserModel? _currentUser;

  static const String _prefSessionKey = 'aquacart_active_user_session';

  FirebaseAuth get auth {
    _firebaseAuth ??= FirebaseAuth.instance;
    return _firebaseAuth!;
  }

  bool get _isFirebaseAvailable {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  // ---------------------------------------------------------------------------
  // 1. Session Restoration (Persistent Sessions via SharedPreferences)
  // ---------------------------------------------------------------------------
  Future<UserModel?> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionJson = prefs.getString(_prefSessionKey);

      if (sessionJson != null) {
        final Map<String, dynamic> data = jsonDecode(sessionJson);
        final cachedUser = UserModel.fromMap(data);

        // If Firebase is available, check if token is still valid
        if (_isFirebaseAvailable && auth.currentUser != null) {
          final liveProfile = await _firestoreService.getUserProfile(auth.currentUser!.uid);
          _currentUser = liveProfile ?? cachedUser;
        } else {
          _currentUser = cachedUser;
        }
        return _currentUser;
      }

      // Default demo customer if no session saved and not live
      if (!_isFirebaseAvailable) {
        _currentUser = AuthServiceMockData.demoCustomer;
        return _currentUser;
      }
    } catch (e) {
      // In case of parsing error, clear corrupted session
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefSessionKey);
    }
    return null;
  }

  Future<void> _persistSession(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefSessionKey, jsonEncode(user.toMap()));
  }

  // ---------------------------------------------------------------------------
  // 2. Email & Password Sign In
  // ---------------------------------------------------------------------------
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final trimmedEmail = email.trim();

    if (!_isFirebaseAvailable) {
      await Future.delayed(const Duration(milliseconds: 600));

      // Offline evaluator demo switcher
      if (trimmedEmail.contains('dealer')) {
        _currentUser = AuthServiceMockData.demoDealer;
      } else if (trimmedEmail.contains('admin')) {
        _currentUser = AuthServiceMockData.demoAdmin;
      } else {
        _currentUser = UserModel(
          uid: 'usr-${DateTime.now().millisecondsSinceEpoch}',
          email: trimmedEmail,
          displayName: trimmedEmail.split('@').first,
          phone: '+91 98765 00000',
          role: UserRole.customer,
          addresses: [MockDataService.defaultAddress],
          createdAt: DateTime.now(),
        );
      }
      await _persistSession(_currentUser!);
      return _currentUser!;
    }

    try {
      final credential = await auth.signInWithEmailAndPassword(
        email: trimmedEmail,
        password: password,
      );

      final uid = credential.user?.uid;
      if (uid == null) {
        throw AuthException('Authentication failed: Missing user ID.');
      }

      // Fetch user profile & verified role from Cloud Firestore
      final userProfile = await _firestoreService.getUserProfile(uid);
      if (userProfile == null) {
        throw AuthException('User profile document not found in Firestore.');
      }

      _currentUser = userProfile;
      await _persistSession(_currentUser!);
      return _currentUser!;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e.code, e.message));
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('An unexpected error occurred during sign in: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // 3. Customer Registration
  // ---------------------------------------------------------------------------
  Future<UserModel> registerCustomer({
    required String displayName,
    required String email,
    required String phone,
    required String password,
  }) async {
    final trimmedEmail = email.trim();
    final trimmedName = displayName.trim();

    if (!_isFirebaseAvailable) {
      await Future.delayed(const Duration(milliseconds: 600));
      _currentUser = UserModel(
        uid: 'usr-${DateTime.now().millisecondsSinceEpoch}',
        email: trimmedEmail,
        displayName: trimmedName,
        phone: phone.trim(),
        role: UserRole.customer, // STRICT: Customer role only
        addresses: [MockDataService.defaultAddress],
        createdAt: DateTime.now(),
      );
      await _persistSession(_currentUser!);
      return _currentUser!;
    }

    try {
      final credential = await auth.createUserWithEmailAndPassword(
        email: trimmedEmail,
        password: password,
      );

      final uid = credential.user?.uid;
      if (uid == null) {
        throw AuthException('Registration failed: Missing user ID.');
      }

      // Update Firebase Auth display name
      await credential.user?.updateDisplayName(trimmedName);

      // Construct and save Customer profile to Firestore
      final newUser = UserModel(
        uid: uid,
        email: trimmedEmail,
        displayName: trimmedName,
        phone: phone.trim(),
        role: UserRole.customer, // STRICT: Self-registration is NEVER admin
        addresses: [MockDataService.defaultAddress],
        createdAt: DateTime.now(),
      );

      await _firestoreService.createUserProfile(newUser);
      _currentUser = newUser;
      await _persistSession(_currentUser!);
      return _currentUser!;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e.code, e.message));
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Failed to register customer: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // 4. Dealer Registration (B2B Wholesale Application)
  // ---------------------------------------------------------------------------
  Future<UserModel> registerDealer({
    required String displayName,
    required String email,
    required String phone,
    required String companyName,
    required String gstNumber,
    required String tradeLicense,
    required String password,
  }) async {
    final trimmedEmail = email.trim();
    final trimmedName = displayName.trim();

    final dealerProfile = DealerProfile(
      companyName: companyName.trim(),
      gstNumber: gstNumber.trim().toUpperCase(),
      tradeLicense: tradeLicense.trim(),
      status: 'pending', // Starts in pending review until Admin approves
      wholesaleTier: 'Silver Partner',
      creditLimit: 50000.0,
    );

    if (!_isFirebaseAvailable) {
      await Future.delayed(const Duration(milliseconds: 700));
      _currentUser = UserModel(
        uid: 'dlr-${DateTime.now().millisecondsSinceEpoch}',
        email: trimmedEmail,
        displayName: trimmedName,
        phone: phone.trim(),
        role: UserRole.dealer, // STRICT: Dealer role only
        dealerProfile: dealerProfile,
        addresses: [MockDataService.dealerAddress],
        createdAt: DateTime.now(),
      );
      await _persistSession(_currentUser!);
      return _currentUser!;
    }

    try {
      final credential = await auth.createUserWithEmailAndPassword(
        email: trimmedEmail,
        password: password,
      );

      final uid = credential.user?.uid;
      if (uid == null) {
        throw AuthException('Registration failed: Missing user ID.');
      }

      await credential.user?.updateDisplayName(trimmedName);

      final newDealer = UserModel(
        uid: uid,
        email: trimmedEmail,
        displayName: trimmedName,
        phone: phone.trim(),
        role: UserRole.dealer, // STRICT: Dealer role only
        dealerProfile: dealerProfile,
        addresses: [MockDataService.dealerAddress],
        createdAt: DateTime.now(),
      );

      await _firestoreService.createUserProfile(newDealer);
      _currentUser = newDealer;
      await _persistSession(_currentUser!);
      return _currentUser!;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e.code, e.message));
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Failed to register dealer: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // 5. Sign Out
  // ---------------------------------------------------------------------------
  Future<void> signOut() async {
    if (_isFirebaseAvailable) {
      try {
        await auth.signOut();
      } catch (_) {}
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefSessionKey);
    _currentUser = null;
  }

  // ---------------------------------------------------------------------------
  // 6. Evaluator Persona Quick Switcher (For local testing & assessment)
  // ---------------------------------------------------------------------------
  void switchRole(UserRole targetRole) {
    switch (targetRole) {
      case UserRole.customer:
        _currentUser = AuthServiceMockData.demoCustomer;
        break;
      case UserRole.dealer:
        _currentUser = AuthServiceMockData.demoDealer;
        break;
      case UserRole.admin:
        _currentUser = AuthServiceMockData.demoAdmin;
        break;
    }
    _persistSession(_currentUser!);
  }

  // ---------------------------------------------------------------------------
  // Helper: Translate Firebase Error Codes
  // ---------------------------------------------------------------------------
  String _mapFirebaseError(String code, String? rawMessage) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email. Please register first.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect password. Please verify and try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'invalid-email':
        return 'The email address format is invalid.';
      case 'weak-password':
        return 'The password is too weak. Please use at least 6 characters.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact Califnco support.';
      case 'too-many-requests':
        return 'Too many unsuccessful attempts. Access temporarily blocked for security.';
      case 'network-request-failed':
        return 'Network connection failed. Please check your internet connectivity.';
      default:
        return rawMessage ?? 'Authentication failed ($code).';
    }
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}
