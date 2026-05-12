import 'package:flutter/material.dart';

class AppColors {
  static const Color bgDark = Color(0xFF070B14);
  static const Color bgCard = Color(0xFF121826);
  static const Color bgCard2 = Color(0xFF1A2235);
  static const Color border = Color(0x1AFFFFFF);
  static const Color borderLight = Color(0x33FFFFFF);
  static const Color accent = Color(0xFF7B4DFF); // More vibrant purple
  static const Color accentDark = Color(0xFF5A32D8);
  static const Color accent2 = Color(0xFF00E5FF); // Vibrant Cyan
  static const Color success = Color(0xFF00E676);
  static const Color warning = Color(0xFFFFC107);
  static const Color danger = Color(0xFFFF5252);
  static const Color textPrimary = Color(0xFFE6EDF3);
  static const Color textMuted = Color(0xFF7D8590);
  static const Color bgSidebar = Color(0xFF21262D);

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, Color(0xFF9D7AFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradientH = LinearGradient(
    colors: [accent, Color(0xFF8B5CF6)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1A1F2E), Color(0xFF161B22)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class ApiConstants {
  // Since you are using USB, run: adb reverse tcp:8000 tcp:8000
  static const String baseUrl = 'http://192.168.1.209:8000/api';
  static const String imageUrl = 'http://192.168.1.209:8000/api/storage-proxy/';

  /// Safely builds a full image URL handling slashes and absolute URLs
  static String? buildImageUrl(dynamic path) {
    if (path == null || path.toString().isEmpty) return null;
    final String pathStr = path.toString();
    
    // If it's already a full URL, return it
    if (pathStr.startsWith('http')) return pathStr;
    
    // Clean up slashes: remove leading slash from path and ensure base has trailing slash
    final String cleanPath = pathStr.startsWith('/') ? pathStr.substring(1) : pathStr;
    final String base = imageUrl.endsWith('/') ? imageUrl : '$imageUrl/';
    
    return '$base$cleanPath';
  }
}
