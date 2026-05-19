import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AssistantProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  // ─── State ──────────────────────────────────────────────────────────────────
  List<dynamic> _requests = [];
  List<dynamic> _workEvents = [];
  List<dynamic> _historyEvents = [];
  bool _isAvailable = false;
  bool _isLoading = false;

  List<dynamic> get requests => _requests;
  List<dynamic> get workEvents => _workEvents;
  List<dynamic> get historyEvents => _historyEvents;
  bool get isAvailable => _isAvailable;
  bool get isLoading => _isLoading;

  /// Load availability from user data (call after login/checkAuth)
  void loadAvailabilityFromUser(Map<String, dynamic>? user) {
    if (user != null && user['profile'] != null) {
      _isAvailable = user['profile']['is_available'] == true || user['profile']['is_available'] == 1;
      notifyListeners();
    }
  }

  void setAvailability(bool value) {
    _isAvailable = value;
    notifyListeners();
  }

  // ─── Fetch pending invitations ──────────────────────────────────────────────
  Future<void> fetchRequests() async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _api.get('/assistant/requests');
      if (res.statusCode == 200) {
        _requests = jsonDecode(res.body) as List<dynamic>;
      }
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  // ─── Respond to invitation (accept/reject) ─────────────────────────────────
  Future<String?> respondToRequest(int id, String status) async {
    try {
      final res = await _api.post('/assistant/requests/$id/respond', {
        'status': status,
      });
      final data = jsonDecode(res.body);

      if (res.statusCode == 200) {
        // Remove from local list
        _requests.removeWhere((r) => r['id'] == id);
        notifyListeners();

        // If accepted, refresh work events
        if (status == 'accepted') {
          fetchWorkEvents();
        }
        return null; // success
      }
      return data['message'] ?? 'Failed to respond';
    } catch (e) {
      return 'Connection error: $e';
    }
  }

  // ─── Toggle availability ────────────────────────────────────────────────────
  Future<String?> toggleAvailability(bool value) async {
    try {
      // Use PUT as PATCH equivalent (Laravel handles both)
      final res = await _api.put('/assistant/availability', {
        'is_available': value,
      });

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _isAvailable = data['is_available'] ?? value;
        notifyListeners();
        return null;
      }
      final data = jsonDecode(res.body);
      return data['message'] ?? 'Failed to update availability';
    } catch (e) {
      return 'Connection error: $e';
    }
  }

  // ─── Fetch accepted work events ─────────────────────────────────────────────
  Future<void> fetchWorkEvents() async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _api.get('/assistant/work');
      if (res.statusCode == 200) {
        _workEvents = jsonDecode(res.body) as List<dynamic>;
      }
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  // ─── Fetch event work details (participants + stats) ────────────────────────
  Future<Map<String, dynamic>?> fetchEventWorkDetails(int eventId) async {
    try {
      final res = await _api.get('/assistant/work/$eventId');
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  // ─── Fetch history events ───────────────────────────────────────────────────
  Future<void> fetchHistory({String? search}) async {
    _isLoading = true;
    notifyListeners();

    try {
      String endpoint = '/assistant/history';
      if (search != null && search.isNotEmpty) {
        endpoint += '?search=${Uri.encodeComponent(search)}';
      }
      final res = await _api.get(endpoint);
      if (res.statusCode == 200) {
        _historyEvents = jsonDecode(res.body) as List<dynamic>;
      }
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  // ─── Fetch event stats for history ──────────────────────────────────────────
  Future<Map<String, dynamic>?> fetchEventStats(int eventId) async {
    try {
      final res = await _api.get('/assistant/history/$eventId/stats');
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }
}
