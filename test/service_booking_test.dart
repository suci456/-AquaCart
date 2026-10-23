import 'package:flutter_test/flutter_test.dart';
import 'package:aquacart/core/constants/app_constants.dart';
import 'package:aquacart/models/user_model.dart';
import 'package:aquacart/models/service_request_model.dart';
import 'package:aquacart/providers/service_provider.dart';

void main() {
  group('Service Booking & Management Lifecycle Tests', () {
    late ServiceProvider serviceProvider;
    late UserModel customer;
    late UserAddress testAddress;

    setUp(() {
      serviceProvider = ServiceProvider();
      testAddress = UserAddress(
        id: 'addr-01',
        label: 'Home',
        street: 'Flat 402, Green Glen Layout',
        city: 'Bengaluru',
        state: 'Karnataka',
        pincode: '560103',
        landmark: 'Opp. Ecospace',
        latitude: 12.9279,
        longitude: 77.6271,
        isDefault: true,
      );
      customer = UserModel(
        uid: 'usr-cust-test-101',
        email: 'customer.test@aquacart.in',
        displayName: 'Rahul Test User',
        role: UserRole.customer,
        phone: '+91 98765 43210',
        addresses: [testAddress],
      );
    });

    test('Customer can book a new service with type, address, date, time, and model', () async {
      final scheduledDate = DateTime.now().add(const Duration(days: 2));

      final request = await serviceProvider.bookNewService(
        user: customer,
        serviceType: ServiceType.filterReplacement,
        purifierBrandModel: 'AquaPure Alkaline RO 12L',
        issueDescription: 'Sediment and carbon filters need replacement, TDS reading 380 ppm',
        preferredDate: scheduledDate,
        preferredSlot: 'Morning (9AM-1PM)',
        address: testAddress,
      );

      expect(request.id, isNotEmpty);
      expect(request.requestNumber, startsWith('SR-'));
      expect(request.userId, equals(customer.uid));
      expect(request.customerName, equals(customer.displayName));
      expect(request.customerPhone, equals(customer.phone));
      expect(request.serviceType, equals(ServiceType.filterReplacement));
      expect(request.purifierBrandModel, equals('AquaPure Alkaline RO 12L'));
      expect(request.preferredSlot, equals('Morning (9AM-1PM)'));
      expect(request.status, equals(ServiceStatus.requested));
      expect(request.serviceAddress.pincode, equals('560103'));
      expect(request.serviceAddress.latitude, equals(12.9279));
      expect(request.assignedTechnician, isNull);
    });

    test('Customer can view only their own service booking history (scoped access)', () async {
      final scheduledDate = DateTime.now().add(const Duration(days: 1));

      // Customer 1 books
      final req1 = await serviceProvider.bookNewService(
        user: customer,
        serviceType: ServiceType.newInstallation,
        purifierBrandModel: 'HydroShield Under-Sink RO',
        issueDescription: 'New kitchen installation',
        preferredDate: scheduledDate,
        preferredSlot: 'Evening (5PM-8PM)',
        address: testAddress,
      );

      // Customer 2 books
      final customer2 = UserModel(
        uid: 'usr-cust-test-202',
        email: 'other.cust@aquacart.in',
        displayName: 'Other Customer',
        role: UserRole.customer,
        phone: '+91 91234 56789',
        addresses: [],
      );
      await serviceProvider.bookNewService(
        user: customer2,
        serviceType: ServiceType.tdsCheckRepair,
        purifierBrandModel: 'AquaElite Mineral RO',
        issueDescription: 'Checking water hardness',
        preferredDate: scheduledDate,
        preferredSlot: 'Afternoon (1PM-5PM)',
        address: testAddress,
      );

      // Verify scoping: Customer 1 sees only their request
      final cust1History = serviceProvider.getRequestsForUser(customer.uid);
      expect(cust1History.any((r) => r.id == req1.id), isTrue);
      expect(cust1History.every((r) => r.userId == customer.uid), isTrue);

      final cust2History = serviceProvider.getRequestsForUser(customer2.uid);
      expect(cust2History.every((r) => r.userId == customer2.uid), isTrue);
    });

    test('Admin assigns certified technician: updates status to assigned with technician details', () async {
      final request = await serviceProvider.bookNewService(
        user: customer,
        serviceType: ServiceType.newInstallation,
        purifierBrandModel: 'AquaPure Alkaline RO 12L',
        issueDescription: 'New installation on kitchen wall',
        preferredDate: DateTime.now().add(const Duration(days: 1)),
        preferredSlot: 'Morning (9AM-1PM)',
        address: testAddress,
      );

      serviceProvider.assignTechnician(
        request.id,
        'Suresh Kumar',
        '+91 98450 11223',
        'TECH-BLR-041',
      );

      final updatedList = serviceProvider.getRequestsForUser(customer.uid);
      final updatedReq = updatedList.firstWhere((r) => r.id == request.id);

      expect(updatedReq.status, equals(ServiceStatus.assigned));
      expect(updatedReq.assignedTechnician, isNotNull);
      expect(updatedReq.assignedTechnician!.name, equals('Suresh Kumar'));
      expect(updatedReq.assignedTechnician!.phone, equals('+91 98450 11223'));
      expect(updatedReq.assignedTechnician!.badgeId, equals('TECH-BLR-041'));
    });

    test('Admin transitions service status to inProgress and completed', () async {
      final request = await serviceProvider.bookNewService(
        user: customer,
        serviceType: ServiceType.amcService,
        purifierBrandModel: 'AquaCommercial 50 LPH SS RO',
        issueDescription: 'Routine quarterly membrane inspection',
        preferredDate: DateTime.now().add(const Duration(days: 1)),
        preferredSlot: 'Afternoon (1PM-5PM)',
        address: testAddress,
      );

      // In Progress
      serviceProvider.updateStatus(request.id, ServiceStatus.inProgress, notes: 'Technician on-site');
      var updated = serviceProvider.allRequests.firstWhere((r) => r.id == request.id);
      expect(updated.status, equals(ServiceStatus.inProgress));
      expect(updated.technicianNotes, equals('Technician on-site'));

      // Completed
      serviceProvider.updateStatus(request.id, ServiceStatus.completed, notes: 'Membrane flushed, TDS 42 ppm');
      updated = serviceProvider.allRequests.firstWhere((r) => r.id == request.id);
      expect(updated.status, equals(ServiceStatus.completed));
      expect(updated.technicianNotes, equals('Membrane flushed, TDS 42 ppm'));
    });

    test('Customer can cancel service request if still in requested state', () async {
      final request = await serviceProvider.bookNewService(
        user: customer,
        serviceType: ServiceType.filterReplacement,
        purifierBrandModel: 'AquaPure Alkaline RO 12L',
        issueDescription: 'Changed mind, moving to another apartment',
        preferredDate: DateTime.now().add(const Duration(days: 3)),
        preferredSlot: 'Morning (9AM-1PM)',
        address: testAddress,
      );

      serviceProvider.cancelRequest(request.id);

      final cancelled = serviceProvider.allRequests.firstWhere((r) => r.id == request.id);
      expect(cancelled.status, equals(ServiceStatus.cancelled));
    });
  });
}
