import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/user_model.dart';
import '../core/constants/app_constants.dart';
import 'mock_data_service.dart';

class FirestoreService {
  FirebaseFirestore? _firestore;

  FirebaseFirestore get firestore {
    _firestore ??= FirebaseFirestore.instance;
    return _firestore!;
  }

  bool get _isFirebaseAvailable {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // Save new user profile to Firestore
  Future<void> createUserProfile(UserModel user) async {
    // SECURITY CHECK: Disallow self-assigned admin creation
    if (user.role == UserRole.admin) {
      throw SecurityException(
        'Self-assigned Admin registration is strictly prohibited. Admin access must be explicitly authorized.',
      );
    }

    if (!_isFirebaseAvailable) {
      // In offline/test mode, user is retained in memory/SharedPreferences
      return;
    }

    try {
      await firestore.collection('users').doc(user.uid).set(user.toMap());
    } catch (e) {
      throw FirestoreException('Failed to create user profile in Firestore: $e');
    }
  }

  // Fetch user profile from Firestore by UID
  Future<UserModel?> getUserProfile(String uid) async {
    if (!_isFirebaseAvailable) {
      if (uid.contains('dealer')) return AuthServiceMockData.demoDealer;
      if (uid.contains('admin')) return AuthServiceMockData.demoAdmin;
      return AuthServiceMockData.demoCustomer;
    }

    try {
      final doc = await firestore.collection('users').doc(uid).get();
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return UserModel.fromMap(doc.data()!);
    } catch (e) {
      throw FirestoreException('Failed to fetch user profile: $e');
    }
  }

  // Update profile details (Name, Phone, Address)
  // Protected: Users cannot modify their role through this method
  Future<void> updateUserProfile({
    required String uid,
    String? displayName,
    String? phone,
    List<UserAddress>? addresses,
  }) async {
    if (!_isFirebaseAvailable) return;

    try {
      final updates = <String, dynamic>{};
      if (displayName != null) updates['displayName'] = displayName;
      if (phone != null) updates['phone'] = phone;
      if (addresses != null) {
        updates['addresses'] = addresses.map((a) => a.toMap()).toList();
      }

      await firestore.collection('users').doc(uid).update(updates);
    } catch (e) {
      throw FirestoreException('Failed to update profile: $e');
    }
  }

  // Explicit Admin Authorization: Can only be called by an existing Admin
  Future<void> assignAdminRole({
    required String callerAdminUid,
    required String targetUserUid,
  }) async {
    if (!_isFirebaseAvailable) return;

    // Verify caller is actually an admin
    final callerDoc = await firestore.collection('users').doc(callerAdminUid).get();
    if (!callerDoc.exists || callerDoc.data()?['role'] != 'admin') {
      throw SecurityException('Unauthorized: Only an existing Admin can grant Admin rights.');
    }

    await firestore.collection('users').doc(targetUserUid).update({
      'role': 'admin',
    });
  }

  // Dealer Status Update (Approve / Reject) by Admin
  Future<void> updateDealerStatus({
    required String callerAdminUid,
    required String dealerUid,
    required String newStatus, // 'approved', 'rejected'
    String? wholesaleTier,
  }) async {
    if (!_isFirebaseAvailable) return;

    final callerDoc = await firestore.collection('users').doc(callerAdminUid).get();
    if (!callerDoc.exists || callerDoc.data()?['role'] != 'admin') {
      throw SecurityException('Unauthorized: Only Admin can review dealer applications.');
    }

    final updates = <String, dynamic>{
      'dealerProfile.status': newStatus,
    };
    if (wholesaleTier != null) {
      updates['dealerProfile.wholesaleTier'] = wholesaleTier;
    }

    await firestore.collection('users').doc(dealerUid).update(updates);
  }
}

class SecurityException implements Exception {
  final String message;
  SecurityException(this.message);
  @override
  String toString() => message;
}

class FirestoreException implements Exception {
  final String message;
  FirestoreException(this.message);
  @override
  String toString() => message;
}

class AuthServiceMockData {
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
}
