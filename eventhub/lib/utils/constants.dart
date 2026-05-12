import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

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
  // TIP: For testing on mobile data or other networks, use Ngrok:
  // 1. Run 'ngrok http 8000'
  // 2. Change '_pcIp' below to your ngrok URL (e.g., 'a1b2.ngrok.io') 
  // 3. Remove 'http://' from the string if you do.
  static const String _pcIp = '192.168.110.127';

  static String get _host {
    if (kIsWeb) return 'localhost';
    // Check if running on Android
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Note: We can't easily detect if it's an emulator or real device at compile time
      // but 10.0.2.2 is the standard for emulators. 
      // If you are using a real device with 'adb reverse', use 'localhost'.
      // For now, we'll keep the IP as the primary for real devices.
      return _pcIp; 
    }
    return 'localhost';
  }

  static String get baseUrl => 'http://$_host:8000/api';
  static String get imageUrl => 'http://$_host:8000/api/storage-proxy/';

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
