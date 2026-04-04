import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class EventProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  
  List<dynamic> _events = [];
  bool _isLoadingEvents = false;
  Map<String, dynamic>? _selectedEventDetail;
  List<dynamic> _eventSponsors = [];

  List<dynamic> get events => _events;
  bool get isLoadingEvents => _isLoadingEvents;
  Map<String, dynamic>? get selectedEventDetail => _selectedEventDetail;
  List<dynamic> get eventSponsors => _eventSponsors;

  /// GET /api/events — public approved events
  Future<void> fetchEvents() async {
    _isLoadingEvents = true;
    notifyListeners();

    try {
      final res = await _api.get('/events');
      if (res.statusCode == 200) {
        _events = jsonDecode(res.body);
      }
    } catch (_) {}

    _isLoadingEvents = false;
    notifyListeners();
  }

  /// GET /api/events/{id} — single event detail
  Future<Map<String, dynamic>?> fetchEventDetail(int eventId) async {
    try {
      final res = await _api.get('/events/$eventId');
      if (res.statusCode == 200) {
        _selectedEventDetail = jsonDecode(res.body);
        notifyListeners();
        return _selectedEventDetail;
      }
    } catch (_) {}
    return null;
  }

  /// Fetch sponsors for an event
  /// Uses the event_sponsor pivot relationship loaded with the event
  Future<void> fetchEventSponsors(int eventId) async {
    _eventSponsors = [];
    notifyListeners();
    // Sponsors come with the event detail via the sponsors relationship
    // We'll parse them from the event data if available
  }
}
