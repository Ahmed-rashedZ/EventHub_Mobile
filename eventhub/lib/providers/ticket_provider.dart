import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class TicketProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<dynamic> _myTickets = [];
  bool _isLoadingTickets = false;

  List<dynamic> get myTickets => _myTickets;
  bool get isLoadingTickets => _isLoadingTickets;

  /// Upcoming tickets (events not yet passed & ticket unused)
  List<dynamic> get upcomingTickets {
    final now = DateTime.now();
    return _myTickets.where((t) {
      final event = t['event'];
      if (event == null) return false;
      final startTime = event['start_time'];
      if (startTime == null) return true;
      final dt = DateTime.tryParse(startTime);
      return dt != null && dt.isAfter(now);
    }).toList();
  }

  /// Past tickets (events already passed)
  List<dynamic> get pastTickets {
    final now = DateTime.now();
    return _myTickets.where((t) {
      final event = t['event'];
      if (event == null) return false;
      final startTime = event['start_time'];
      if (startTime == null) return false;
      final dt = DateTime.tryParse(startTime);
      return dt != null && dt.isBefore(now);
    }).toList();
  }

  /// Total attended events (used tickets)
  int get totalAttended {
    return _myTickets.where((t) => t['status'] == 'used').length;
  }

  /// GET /api/my-tickets
  Future<void> fetchMyTickets() async {
    _isLoadingTickets = true;
    notifyListeners();

    try {
      final res = await _api.get('/my-tickets');
      if (res.statusCode == 200) {
        _myTickets = jsonDecode(res.body);
        // Cache tickets locally for offline viewing
        _cacheTickets();
      }
    } catch (_) {
      // On network error, try loading from cache
      await _loadCachedTickets();
    }

    _isLoadingTickets = false;
    notifyListeners();
  }

  /// POST /api/tickets — Book a ticket
  Future<String?> bookTicket(int eventId) async {
    try {
      final res = await _api.post('/tickets', {'event_id': eventId});
      final data = jsonDecode(res.body);

      if (res.statusCode == 201) {
        await fetchMyTickets(); // Refresh tickets
        return null; // success
      } else {
        return data['message'] ?? 'Failed to book ticket';
      }
    } catch (e) {
      return 'Connection error: $e';
    }
  }

  /// POST /api/checkin — Assistant scans QR code
  /// Backend expects: { "qr_code": "THE_QR_STRING" }
  Future<Map<String, dynamic>> processCheckIn(String qrCode) async {
    try {
      final res = await _api.post('/checkin', {'qr_code': qrCode});
      final data = jsonDecode(res.body);

      return {
        'success': res.statusCode == 200,
        'message': data['message'] ?? (res.statusCode == 200 ? 'Check-in successful' : 'Validation failed'),
        'statusCode': res.statusCode,
        'data': data,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error. Check your network.',
        'statusCode': 0,
      };
    }
  }

  /// Cache tickets to SharedPreferences
  Future<void> _cacheTickets() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_tickets', jsonEncode(_myTickets));
  }

  /// Load cached tickets
  Future<void> _loadCachedTickets() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('cached_tickets');
    if (cached != null) {
      _myTickets = jsonDecode(cached);
    }
  }
}
