import 'package:flutter/material.dart';

class AppColors {
  static const Color bgDark = Color(0xFF0D1117);
  static const Color bgCard = Color(0xFF161B22);
  static const Color bgCard2 = Color(0xFF1C2333);
  static const Color border = Color(0x14FFFFFF);
  static const Color borderLight = Color(0x22FFFFFF);
  static const Color accent = Color(0xFF6E40F2);
  static const Color accentDark = Color(0xFF5A32D8);
  static const Color accent2 = Color(0xFF22D3EE);
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color textPrimary = Color(0xFFE6EDF3);
  static const Color textMuted = Color(0xFF7D8590);
  static const Color bgSidebar = Color(0xFF21262D);

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, accent2],
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
  static const String baseUrl = 'http://127.0.0.1:8000/api';
}
