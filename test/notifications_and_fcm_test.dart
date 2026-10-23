import 'package:flutter_test/flutter_test.dart';
import 'package:aquacart/core/constants/app_constants.dart';
import 'package:aquacart/models/order_model.dart';
import 'package:aquacart/models/service_request_model.dart';
import 'package:aquacart/models/user_model.dart';
import 'package:aquacart/services/notification_service.dart';
import 'package:aquacart/providers/notification_provider.dart';

void main() {
  group('Firebase Cloud Messaging & Notifications Tests', () {
    late NotificationService notificationService;
    late NotificationProvider notificationProvider;

    setUp(() {
      notificationService = NotificationService();
      notificationProvider = NotificationProvider();
    });

    test('FCM token is registered and initialized', () {
      expect(notificationService.fcmToken, isNotEmpty);
      expect(notificationService.fcmToken, startsWith('fcm_tok_califnco_'));
    });

    test('Order placement triggers order confirmation notification', () {
      final order = OrderModel(
        id: 'ord-test-notif-01',
        orderNumber: 'AQ-2026-9999',
        userId: 'usr-customer-1',
        userRole: UserRole.customer,
        items: [],
        subtotal: 14999.0,
        tax: 2700.0,
        totalAmount: 17699.0,
        shippingAddress: UserAddress(
          id: 'addr-1',
          label: 'Home',
          street: '123 Main St',
          city: 'Bengaluru',
          state: 'Karnataka',
          pincode: '560103',
        ),
        createdAt: DateTime.now(),
      );

      final notif = notificationService.notifyOrderPlaced(order);

      expect(notif.title, contains('AQ-2026-9999'));
      expect(notif.type, equals('order_update'));
      expect(notif.isRead, isFalse);
    });

    test('Admin order status change triggers status update notification', () {
      final notif = notificationService.notifyOrderStatus('AQ-2026-9999', 'dispatched');

      expect(notif.title, contains('AQ-2026-9999'));
      expect(notif.body, contains('DISPATCHED'));
      expect(notif.type, equals('order_update'));
    });

    test('Customer service booking triggers service confirmation notification', () {
      final request = ServiceRequestModel(
        id: 'sr-notif-01',
        requestNumber: 'SR-1099',
        userId: 'usr-customer-1',
        customerName: 'Rahul',
        customerPhone: '+91 98765 43210',
        serviceAddress: UserAddress(
          id: 'addr-1',
          label: 'Home',
          street: '123 Main St',
          city: 'Bengaluru',
          state: 'Karnataka',
          pincode: '560103',
        ),
        serviceType: ServiceType.filterReplacement,
        purifierBrandModel: 'AquaPure Alkaline RO 12L',
        preferredDate: DateTime.now().add(const Duration(days: 1)),
        preferredSlot: 'Morning (9AM-1PM)',
        createdAt: DateTime.now(),
      );

      final notif = notificationService.notifyServiceBooked(request);

      expect(notif.title, contains('SR-1099'));
      expect(notif.type, equals('service_update'));
      expect(notif.body, contains('Morning (9AM-1PM)'));
    });

    test('Admin assigning technician triggers technician details notification', () {
      final request = ServiceRequestModel(
        id: 'sr-notif-02',
        requestNumber: 'SR-1100',
        userId: 'usr-customer-1',
        customerName: 'Deepika',
        customerPhone: '+91 97412 88990',
        serviceAddress: UserAddress(
          id: 'addr-1',
          label: 'Home',
          street: '123 Main St',
          city: 'Bengaluru',
          state: 'Karnataka',
          pincode: '560103',
        ),
        serviceType: ServiceType.newInstallation,
        purifierBrandModel: 'HydroShield RO',
        preferredDate: DateTime.now().add(const Duration(days: 1)),
        preferredSlot: 'Afternoon (1PM-5PM)',
        createdAt: DateTime.now(),
      );

      final notif = notificationService.notifyTechnicianAssigned(
        request,
        'Suresh Kumar',
        '+91 98450 11223',
      );

      expect(notif.title, contains('SR-1100'));
      expect(notif.body, contains('Suresh Kumar'));
      expect(notif.body, contains('+91 98450 11223'));
    });

    test('Dealer KYC approval triggers wholesale activation notification', () {
      final notif = notificationService.notifyDealerStatus('approved');

      expect(notif.title, contains('Approved'));
      expect(notif.body, contains('B2B dealer wholesale portal'));
      expect(notif.type, equals('dealer_status'));
    });

    test('NotificationProvider unread count and markAllAsRead reactive state', () {
      notificationProvider.notifyOrderStatus('AQ-2026-1001', 'delivered');
      expect(notificationProvider.unreadCount, greaterThan(0));

      notificationProvider.markAllAsRead();
      expect(notificationProvider.unreadCount, equals(0));
    });
  });
}
