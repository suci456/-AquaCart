import 'package:flutter/foundation.dart';
import '../core/constants/app_constants.dart';
import '../models/service_request_model.dart';
import '../models/user_model.dart';
import '../services/mock_data_service.dart';

class ServiceProvider extends ChangeNotifier {
  final List<ServiceRequestModel> _requests =
      List.from(MockDataService.mockServiceRequests);

  List<ServiceRequestModel> get allRequests => _requests;

  List<ServiceRequestModel> getRequestsForUser(String userId) {
    return _requests.where((r) => r.userId == userId).toList();
  }

  Future<ServiceRequestModel> bookNewService({
    required UserModel user,
    required ServiceType serviceType,
    required String purifierBrandModel,
    required String issueDescription,
    required DateTime preferredDate,
    required String preferredSlot,
    required UserAddress address,
  }) async {
    final requestId = 'sr-${DateTime.now().millisecondsSinceEpoch}';
    final requestNumber = 'SR-${1000 + _requests.length + 1}';

    final newRequest = ServiceRequestModel(
      id: requestId,
      requestNumber: requestNumber,
      userId: user.uid,
      customerName: user.displayName,
      customerPhone: user.phone,
      serviceAddress: address,
      serviceType: serviceType,
      purifierBrandModel: purifierBrandModel,
      issueDescription: issueDescription,
      preferredDate: preferredDate,
      preferredSlot: preferredSlot,
      status: ServiceStatus.requested,
      createdAt: DateTime.now(),
    );

    _requests.insert(0, newRequest);
    notifyListeners();
    return newRequest;
  }

  // Admin capability: Assign technician
  void assignTechnician(
    String requestId,
    String technicianName,
    String technicianPhone,
    String badgeId,
  ) {
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      final current = _requests[index];
      _requests[index] = ServiceRequestModel(
        id: current.id,
        requestNumber: current.requestNumber,
        userId: current.userId,
        customerName: current.customerName,
        customerPhone: current.customerPhone,
        serviceAddress: current.serviceAddress,
        serviceType: current.serviceType,
        purifierBrandModel: current.purifierBrandModel,
        issueDescription: current.issueDescription,
        preferredDate: current.preferredDate,
        preferredSlot: current.preferredSlot,
        status: ServiceStatus.assigned,
        assignedTechnician: TechnicianInfo(
          name: technicianName,
          phone: technicianPhone,
          badgeId: badgeId,
        ),
        technicianNotes: current.technicianNotes,
        createdAt: current.createdAt,
      );
      notifyListeners();
    }
  }

  // Update status (inProgress, completed)
  void updateStatus(String requestId, ServiceStatus newStatus, {String? notes}) {
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      final current = _requests[index];
      _requests[index] = ServiceRequestModel(
        id: current.id,
        requestNumber: current.requestNumber,
        userId: current.userId,
        customerName: current.customerName,
        customerPhone: current.customerPhone,
        serviceAddress: current.serviceAddress,
        serviceType: current.serviceType,
        purifierBrandModel: current.purifierBrandModel,
        issueDescription: current.issueDescription,
        preferredDate: current.preferredDate,
        preferredSlot: current.preferredSlot,
        status: newStatus,
        assignedTechnician: current.assignedTechnician,
        technicianNotes: notes ?? current.technicianNotes,
        createdAt: current.createdAt,
      );
      notifyListeners();
    }
  }

  // Cancel service booking
  void cancelRequest(String requestId) {
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      final current = _requests[index];
      _requests[index] = ServiceRequestModel(
        id: current.id,
        requestNumber: current.requestNumber,
        userId: current.userId,
        customerName: current.customerName,
        customerPhone: current.customerPhone,
        serviceAddress: current.serviceAddress,
        serviceType: current.serviceType,
        purifierBrandModel: current.purifierBrandModel,
        issueDescription: current.issueDescription,
        preferredDate: current.preferredDate,
        preferredSlot: current.preferredSlot,
        status: ServiceStatus.cancelled,
        assignedTechnician: current.assignedTechnician,
        technicianNotes: current.technicianNotes,
        createdAt: current.createdAt,
      );
      notifyListeners();
    }
  }
}
