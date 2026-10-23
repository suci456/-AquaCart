import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import '../models/order_model.dart';
import '../models/service_request_model.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _service = NotificationService();

  List<NotificationModel> get notifications => _service.notifications;
  int get unreadCount => _service.unreadCount;

  void markAllAsRead() {
    _service.markAllAsRead();
    notifyListeners();
  }

  void notifyOrderPlaced(OrderModel order) {
    _service.notifyOrderPlaced(order);
    notifyListeners();
  }

  void notifyOrderStatus(String orderNumber, String status) {
    _service.notifyOrderStatus(orderNumber, status);
    notifyListeners();
  }

  void notifyServiceBooked(ServiceRequestModel request) {
    _service.notifyServiceBooked(request);
    notifyListeners();
  }

  void notifyTechnicianAssigned(ServiceRequestModel request, String techName, String phone) {
    _service.notifyTechnicianAssigned(request, techName, phone);
    notifyListeners();
  }

  void notifyDealerStatus(String status) {
    _service.notifyDealerStatus(status);
    notifyListeners();
  }
}
