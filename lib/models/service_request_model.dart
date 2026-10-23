import '../core/constants/app_constants.dart';
import 'user_model.dart';

class TechnicianInfo {
  final String name;
  final String phone;
  final String badgeId;

  TechnicianInfo({
    required this.name,
    required this.phone,
    required this.badgeId,
  });

  factory TechnicianInfo.fromMap(Map<String, dynamic> map) {
    return TechnicianInfo(
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      badgeId: map['badgeId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'badgeId': badgeId,
    };
  }
}

class ServiceRequestModel {
  final String id;
  final String requestNumber;
  final String userId;
  final String customerName;
  final String customerPhone;
  final UserAddress serviceAddress;
  final ServiceType serviceType;
  final String purifierBrandModel;
  final String issueDescription;
  final DateTime preferredDate;
  final String preferredSlot; // 'Morning (9AM-1PM)', 'Afternoon (1PM-5PM)', 'Evening (5PM-8PM)'
  final ServiceStatus status;
  final TechnicianInfo? assignedTechnician;
  final String? technicianNotes;
  final DateTime createdAt;

  ServiceRequestModel({
    required this.id,
    required this.requestNumber,
    required this.userId,
    required this.customerName,
    required this.customerPhone,
    required this.serviceAddress,
    required this.serviceType,
    required this.purifierBrandModel,
    this.issueDescription = '',
    required this.preferredDate,
    required this.preferredSlot,
    this.status = ServiceStatus.requested,
    this.assignedTechnician,
    this.technicianNotes,
    required this.createdAt,
  });

  factory ServiceRequestModel.fromMap(Map<String, dynamic> map) {
    return ServiceRequestModel(
      id: map['id'] ?? '',
      requestNumber: map['requestNumber'] ?? '',
      userId: map['userId'] ?? '',
      customerName: map['customerName'] ?? '',
      customerPhone: map['customerPhone'] ?? '',
      serviceAddress: UserAddress.fromMap(
        Map<String, dynamic>.from(map['serviceAddress'] ?? {}),
      ),
      serviceType: _parseServiceType(map['serviceType']),
      purifierBrandModel: map['purifierBrandModel'] ?? 'AquaPure RO',
      issueDescription: map['issueDescription'] ?? '',
      preferredDate: map['preferredDate'] != null
          ? DateTime.tryParse(map['preferredDate']) ?? DateTime.now().add(const Duration(days: 1))
          : DateTime.now().add(const Duration(days: 1)),
      preferredSlot: map['preferredSlot'] ?? 'Morning (9AM-1PM)',
      status: _parseServiceStatus(map['status']),
      assignedTechnician: map['assignedTechnician'] != null
          ? TechnicianInfo.fromMap(Map<String, dynamic>.from(map['assignedTechnician']))
          : null,
      technicianNotes: map['technicianNotes'],
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'requestNumber': requestNumber,
      'userId': userId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'serviceAddress': serviceAddress.toMap(),
      'serviceType': serviceType.name,
      'purifierBrandModel': purifierBrandModel,
      'issueDescription': issueDescription,
      'preferredDate': preferredDate.toIso8601String(),
      'preferredSlot': preferredSlot,
      'status': status.name,
      'assignedTechnician': assignedTechnician?.toMap(),
      'technicianNotes': technicianNotes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static ServiceType _parseServiceType(dynamic s) {
    for (var val in ServiceType.values) {
      if (val.name == s) return val;
    }
    return ServiceType.filterReplacement;
  }

  static ServiceStatus _parseServiceStatus(dynamic s) {
    for (var val in ServiceStatus.values) {
      if (val.name == s) return val;
    }
    return ServiceStatus.requested;
  }
}
