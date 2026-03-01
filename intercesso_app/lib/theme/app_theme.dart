import 'package:flutter/material.dart';

/// 앱 전체에서 사용하는 색상 및 테마 상수
class AppTheme {
  // ── 주요 색상 ────────────────────────────────────────────
  static const Color primary   = Color(0xFF00AAFF);
  static const Color secondary = Color(0xFF00C9A7);
  static const Color success   = Color(0xFF10B981);
  static const Color warning   = Color(0xFFF59E0B);
  static const Color error     = Color(0xFFEF4444);
  static const Color danger    = Color(0xFFEF4444);

  // ── 배경 / 텍스트 ────────────────────────────────────────
  static const Color background  = Color(0xFFF8FAFC);
  static const Color surface     = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSub     = Color(0xFF6B7280);
  static const Color border      = Color(0xFFE5E7EB);

  // ── MaterialApp.theme ────────────────────────────────────
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        colorSchemeSeed: primary,
        scaffoldBackgroundColor: background,
        fontFamily: 'pretendard',
        appBarTheme: const AppBarTheme(
          backgroundColor: surface,
          foregroundColor: textPrimary,
          elevation: 0,
        ),
      );
}
