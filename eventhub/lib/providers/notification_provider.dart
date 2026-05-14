import 'package:flutter/material.dart';
import '../utils/constants.dart';

class NotificationProvider extends ChangeNotifier {
  final List<Map<String, dynamic>> _notifications = [
    {
      'title': 'Ticket Confirmed',
      'message': 'Your ticket for "Tech Conference 2026" has been confirmed. You can view your QR code now.',
      'time': '2 hours ago',
      'icon': Icons.confirmation_number_rounded,
      'color': AppColors.success,
      'isRead': false,
      'actionType': 'tickets',
    },
    {
      'title': 'Event Starting Soon',
      'message': '"AI Workshop" is starting tomorrow at 10:00 AM. Don\'t forget to check your tickets!',
      'time': '1 day ago',
      'icon': Icons.access_time_filled_rounded,
      'color': AppColors.warning,
      'isRead': true,
      'actionType': 'event_details',
    },
    {
      'title': 'New Event Alert',
      'message': 'A new event "Flutter Dev Summit" matching your interests has been posted.',
      'time': '3 days ago',
      'icon': Icons.new_releases_rounded,
      'color': AppColors.accent,
      'isRead': true,
      'actionType': 'explore',
    },
  ];

  List<Map<String, dynamic>> get notifications => _notifications;

  bool get hasUnreadNotifications => _notifications.any((n) => !n['isRead']);

  void markAllAsRead() {
    for (var n in _notifications) {
      n['isRead'] = true;
    }
    notifyListeners();
  }

  void markAsRead(int index) {
    if (index >= 0 && index < _notifications.length) {
      _notifications[index]['isRead'] = true;
      notifyListeners();
    }
  }
}
