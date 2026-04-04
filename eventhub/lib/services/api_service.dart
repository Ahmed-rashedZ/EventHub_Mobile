import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class ApiService {
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Check if response indicates token expiration
  bool isTokenExpired(http.Response response) {
    return response.statusCode == 401;
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final headers = await _getHeaders();
    return await http.post(url, headers: headers, body: jsonEncode(body));
  }

  Future<http.Response> get(String endpoint) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final headers = await _getHeaders();
    return await http.get(url, headers: headers);
  }

  Future<http.Response> put(String endpoint, [Map<String, dynamic>? body]) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final headers = await _getHeaders();
    return await http.put(url, headers: headers, body: body != null ? jsonEncode(body) : null);
  }

  Future<http.Response> delete(String endpoint) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final headers = await _getHeaders();
    return await http.delete(url, headers: headers);
  }
}
