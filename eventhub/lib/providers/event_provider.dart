import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class EventProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  
  List<dynamic> _events = [];
  bool _isLoadingEvents = false;
  String? _errorMessage;

  List<dynamic> get events => _events;
  bool get isLoadingEvents => _isLoadingEvents;
  String? get errorMessage => _errorMessage;

  /// GET /api/events — public approved events
  Future<void> fetchEvents() async {
    _isLoadingEvents = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.get('/events');
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is List) {
          _events = decoded;
        } else {
          _events = [];
        }
        _errorMessage = null;
      } else {
        _errorMessage = 'Server error: ${res.statusCode}';
      }
    } catch (e) {
      _errorMessage = 'Connection error: $e';
    }

    _isLoadingEvents = false;
    notifyListeners();
  }

  /// GET /api/events/{id} — single event detail
  Future<Map<String, dynamic>?> fetchEventDetail(int eventId) async {
    try {
      final res = await _api.get('/events/$eventId');
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (_) {}
    return null;
  }
}
