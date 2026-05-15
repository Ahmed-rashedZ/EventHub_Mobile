import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/fcm_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isAuthenticated = false;
  bool _isLoading = true;
  Map<String, dynamic>? _user;
  int? _pendingEventId; // Event to navigate to after login

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  Map<String, dynamic>? get user => _user;
  String? get role => _user?['role'];
  String get userName => _user?['name'] ?? 'User';
  String get userEmail => _user?['email'] ?? '';
  int get userId => _user?['id'] ?? 0;
  int? get pendingEventId => _pendingEventId;

  set pendingEventId(int? id) {
    _pendingEventId = id;
    notifyListeners();
  }

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

  Future<void> refreshUser() async {
    try {
      final res = await _api.get('/profile');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final newUser = data['user'] ?? data;
        await updateUser(newUser);
      }
    } catch (_) {}
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
        // Save FCM token to backend after login
        FCMService.refreshAndSaveToken();
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
        // Save FCM token to backend after register
        FCMService.refreshAndSaveToken();
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

  /// Update local user data and persist to SharedPreferences
  Future<void> updateUser(Map<String, dynamic> newUser) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(newUser));
    _user = newUser;
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

  Future<String?> forgotPassword(String email) async {
    try {
      final res = await _api.post('/password/forgot', {'email': email});
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) return null; // Success

      return data['message'] ?? 'Failed to send OTP';
    } catch (e) {
      return 'Connection error.';
    }
  }

  Future<Map<String, dynamic>> verifyCode(String email, String code) async {
    try {
      final res = await _api.post('/password/verify-code', {
        'email': email,
        'code': code,
      });
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return {'success': true, 'reset_token': data['reset_token']};
      }

      return {'success': false, 'message': data['message'] ?? 'Invalid or expired OTP'};
    } catch (e) {
      return {'success': false, 'message': 'Connection error.'};
    }
  }

  Future<String?> resetPassword(
    String email,
    String code,
    String password,
  ) async {
    try {
      final res = await _api.post('/password/reset', {
        'email': email,
        'reset_token': code,
        'password': password,
        'password_confirmation': password,
      });
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) return null; // Success

      if (data['errors'] != null) {
        final errors = data['errors'] as Map<String, dynamic>;
        final firstErrorList = errors.values.first;
        if (firstErrorList is List && firstErrorList.isNotEmpty) {
          return firstErrorList[0].toString();
        }
      }
      return data['message'] ?? 'Failed to reset password';
    } catch (e) {
      return 'Connection error.';
    }
  }
}
