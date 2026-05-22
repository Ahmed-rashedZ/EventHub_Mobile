import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class NotificationProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = false;
  int _unreadCount = 0;

  List<Map<String, dynamic>> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _unreadCount;
  bool get hasUnreadNotifications => _unreadCount > 0;

  /// Map from backend 'type' string to Flutter icon + color
  static IconData iconFor(String type) {
    switch (type) {
      case 'ticket':
        return Icons.confirmation_number_rounded;
      case 'event':
        return Icons.event_available_rounded;
      case 'assistant_request':
        return Icons.mail_rounded;
      case 'sponsorship':
        return Icons.handshake_rounded;
      case 'verification':
        return Icons.verified_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  static Color colorFor(String type) {
    switch (type) {
      case 'ticket':
        return AppColors.success;
      case 'event':
        return AppColors.warning;
      case 'sponsorship':
        return AppColors.accent2;
      case 'verification':
        return AppColors.accent;
      default:
        return AppColors.textMuted;
    }
  }

  /// GET /api/notifications
  Future<void> fetchNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _api.get('/notifications');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List rawList = (data is Map && data['notifications'] != null)
            ? data['notifications']
            : (data is List ? data : []);

        _unreadCount = (data is Map) ? (data['unread_count'] ?? 0) : 0;

        _notifications = rawList.map<Map<String, dynamic>>((n) {
          final type = n['type'] ?? 'system';
          return {
            'id': n['id'],
            'title': n['title'] ?? '',
            'message': n['message'] ?? '',
            'type': type,
            'icon': iconFor(type),
            'color': colorFor(type),
            'isRead': n['is_read'] ?? false,
            'time': _formatTime(n['created_at']),
            'actionType': _actionTypeFor(type, n['related_id']),
            'relatedId': n['related_id'],
          };
        }).toList();
      }
    } catch (_) {
      // Keep previous data on error
    }

    _isLoading = false;
    notifyListeners();
  }

  /// PUT /api/notifications/{id}/read
  Future<void> markAsRead(int index) async {
    if (index < 0 || index >= _notifications.length) return;
    final notification = _notifications[index];
    if (notification['isRead'] == true) return;

    _notifications[index]['isRead'] = true;
    if (_unreadCount > 0) _unreadCount--;
    notifyListeners();

    try {
      await _api.put('/notifications/${notification['id']}/read', {});
    } catch (_) {}
  }

  /// PUT /api/notifications/read-all
  Future<void> markAllAsRead() async {
    for (var n in _notifications) {
      n['isRead'] = true;
    }
    _unreadCount = 0;
    notifyListeners();

    try {
      await _api.put('/notifications/read-all', {});
    } catch (_) {}
  }

  String _formatTime(String? isoStr) {
    if (isoStr == null) return '';
    final dt = DateTime.tryParse(isoStr);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  String _actionTypeFor(String type, dynamic relatedId) {
    switch (type) {
      case 'ticket':
        return 'tickets';
      case 'event':
        return relatedId != null ? 'event_details' : 'explore';
      default:
        return 'none';
    }
  }
}
