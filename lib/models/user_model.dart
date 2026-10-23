import '../core/constants/app_constants.dart';

class DealerProfile {
  final String companyName;
  final String gstNumber;
  final String tradeLicense;
  final String status; // 'pending', 'approved', 'rejected'
  final String wholesaleTier; // 'Silver', 'Gold', 'Platinum'
  final double creditLimit;

  DealerProfile({
    required this.companyName,
    required this.gstNumber,
    required this.tradeLicense,
    this.status = 'approved',
    this.wholesaleTier = 'Gold',
    this.creditLimit = 150000.0,
  });

  factory DealerProfile.fromMap(Map<String, dynamic> map) {
    return DealerProfile(
      companyName: map['companyName'] ?? '',
      gstNumber: map['gstNumber'] ?? '',
      tradeLicense: map['tradeLicense'] ?? '',
      status: map['status'] ?? 'pending',
      wholesaleTier: map['wholesaleTier'] ?? 'Silver',
      creditLimit: (map['creditLimit'] ?? 50000.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'companyName': companyName,
      'gstNumber': gstNumber,
      'tradeLicense': tradeLicense,
      'status': status,
      'wholesaleTier': wholesaleTier,
      'creditLimit': creditLimit,
    };
  }
}

class UserAddress {
  final String id;
  final String label;
  final String street;
  final String city;
  final String state;
  final String pincode;
  final bool isDefault;

  UserAddress({
    required this.id,
    required this.label,
    required this.street,
    required this.city,
    required this.state,
    required this.pincode,
    this.isDefault = false,
  });

  factory UserAddress.fromMap(Map<String, dynamic> map) {
    return UserAddress(
      id: map['id'] ?? '',
      label: map['label'] ?? 'Home',
      street: map['street'] ?? '',
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      pincode: map['pincode'] ?? '',
      isDefault: map['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'street': street,
      'city': city,
      'state': state,
      'pincode': pincode,
      'isDefault': isDefault,
    };
  }

  String get fullAddress => '$street, $city, $state - $pincode';
}

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String phone;
  final UserRole role;
  final DealerProfile? dealerProfile;
  final List<UserAddress> addresses;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.phone,
    required this.role,
    this.dealerProfile,
    this.addresses = const [],
    required this.createdAt,
  });

  bool get isCustomer => role == UserRole.customer;
  bool get isDealer => role == UserRole.dealer;
  bool get isAdmin => role == UserRole.admin;

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      phone: map['phone'] ?? '',
      role: _parseRole(map['role']),
      dealerProfile: map['dealerProfile'] != null
          ? DealerProfile.fromMap(Map<String, dynamic>.from(map['dealerProfile']))
          : null,
      addresses: (map['addresses'] as List<dynamic>?)
              ?.map((a) => UserAddress.fromMap(Map<String, dynamic>.from(a)))
              .toList() ??
          [],
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'phone': phone,
      'role': role.name,
      'dealerProfile': dealerProfile?.toMap(),
      'addresses': addresses.map((a) => a.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static UserRole _parseRole(dynamic roleStr) {
    if (roleStr == 'dealer') return UserRole.dealer;
    if (roleStr == 'admin') return UserRole.admin;
    return UserRole.customer;
  }
}
