import '../models/notification_model.dart';
import '../models/order_model.dart';
import '../models/service_request_model.dart';
import 'mock_data_service.dart';

/// Firebase Cloud Messaging (FCM) & In-App Notification Service
///
/// Dispatches push notifications and records them in the user's notification center.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final List<NotificationModel> _inAppNotifications =
      List.from(MockDataService.mockNotifications);

  List<NotificationModel> get notifications => List.unmodifiable(_inAppNotifications);

  int get unreadCount => _inAppNotifications.where((n) => !n.isRead).length;

  /// FCM Token Registration (simulated or real depending on platform)
  String get fcmToken => 'fcm_tok_califnco_${DateTime.now().millisecondsSinceEpoch}';

  NotificationModel dispatchNotification({
    required String title,
    required String body,
    required String type,
  }) {
    final notif = NotificationModel(
      id: 'notif-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      type: type,
      isRead: false,
      createdAt: DateTime.now(),
    );

    _inAppNotifications.insert(0, notif);
    return notif;
  }

  void markAllAsRead() {
    for (int i = 0; i < _inAppNotifications.length; i++) {
      final current = _inAppNotifications[i];
      _inAppNotifications[i] = NotificationModel(
        id: current.id,
        title: current.title,
        body: current.body,
        type: current.type,
        isRead: true,
        createdAt: current.createdAt,
      );
    }
  }

  // ── Trigger helpers ────────────────────────────────────────────────────────

  NotificationModel notifyOrderPlaced(OrderModel order) {
    return dispatchNotification(
      title: 'Order Confirmed: ${order.orderNumber}',
      body: order.isWholesaleOrder
          ? 'Wholesale bulk order for ₹${order.totalAmount.toStringAsFixed(0)} has been recorded under invoice #${order.orderNumber}.'
          : 'Thank you! Your water purifier order #${order.orderNumber} is confirmed and sent for dispatch.',
      type: 'order_update',
    );
  }

  NotificationModel notifyOrderStatus(String orderNumber, String status) {
    return dispatchNotification(
      title: 'Order Status Update: $orderNumber',
      body: 'Your order is now marked as "${status.toUpperCase()}". Track delivery in real time.',
      type: 'order_update',
    );
  }

  NotificationModel notifyServiceBooked(ServiceRequestModel request) {
    return dispatchNotification(
      title: 'Service Booked: ${request.requestNumber}',
      body: 'Your ${request.serviceType.name} request has been scheduled for ${request.preferredSlot}.',
      type: 'service_update',
    );
  }

  NotificationModel notifyTechnicianAssigned(ServiceRequestModel request, String techName, String phone) {
    return dispatchNotification(
      title: 'Technician Assigned: ${request.requestNumber}',
      body: '$techName (Ph: $phone) has been assigned for your doorstep service visit.',
      type: 'service_update',
    );
  }

  NotificationModel notifyDealerStatus(String status) {
    final isApproved = status.toLowerCase() == 'approved';
    return dispatchNotification(
      title: isApproved ? 'Wholesale Account Approved! 🎉' : 'Dealer KYC Update',
      body: isApproved
          ? 'Your B2B dealer wholesale portal is now active with tiered discounts & credit lines.'
          : 'Your dealer verification application is currently under compliance review.',
      type: 'dealer_status',
    );
  }
}
