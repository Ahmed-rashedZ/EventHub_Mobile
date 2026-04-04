import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  
  bool _isAuthenticated = false;
  bool _isLoading = true;
  Map<String, dynamic>? _user;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  Map<String, dynamic>? get user => _user;
  String? get role => _user?['role'];
  String get userName => _user?['name'] ?? 'User';
  String get userEmail => _user?['email'] ?? '';
  int get userId => _user?['id'] ?? 0;

  AuthProvider() {
    checkAuth();
  }

  Future<void> checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userData = prefs.getString('user');

    if (token != null && userData != null) {
      _user = jsonDecode(userData);
      _isAuthenticated = true;
    } else {
      _user = null;
      _isAuthenticated = false;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<String?> login(String email, String password) async {
    try {
      final res = await _api.post('/login', {
        'email': email,
        'password': password,
      });

      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('user', jsonEncode(data['user']));
        
        _user = data['user'];
        _isAuthenticated = true;
        notifyListeners();
        return null; // Success
      } else {
        final message = data['message'] ?? 'Login failed';
        if (data['errors'] != null) {
          final firstErrorList = data['errors'].values.first;
          if (firstErrorList is List && firstErrorList.isNotEmpty) {
            return firstErrorList[0].toString();
          }
        }
        return message;
      }
    } catch (e) {
      return 'Connection error. Make sure the server is running.';
    }
  }

  Future<String?> register(String name, String email, String password) async {
    try {
      final res = await _api.post('/register', {
        'name': name,
        'email': email,
        'password': password,
        'role': 'User',
      });

      final data = jsonDecode(res.body);
      if (res.statusCode == 200 || res.statusCode == 201) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('user', jsonEncode(data['user']));

        _user = data['user'];
        _isAuthenticated = true;
        notifyListeners();
        return null; // Success
      } else {
        final message = data['message'] ?? 'Registration failed';
        if (data['errors'] != null) {
          final errors = data['errors'] as Map<String, dynamic>;
          final firstErrorList = errors.values.first;
          if (firstErrorList is List && firstErrorList.isNotEmpty) {
            return firstErrorList[0].toString();
          }
        }
        return message;
      }
    } catch (e) {
      return 'Connection error. Make sure the server is running.';
    }
  }

  Future<void> logout() async {
    try {
      await _api.post('/logout', {});
    } catch (_) {
      // Ignore network errors on logout
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
    await prefs.remove('cached_tickets');
    _user = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  /// Force logout on token expiration
  Future<void> forceLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
    await prefs.remove('cached_tickets');
    _user = null;
    _isAuthenticated = false;
    notifyListeners();
  }
}
