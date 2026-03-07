import 'package:flutter/material.dart';

class AppTheme {
  // ── 모듈별 시그니처 컬러 (시안 기준) ────────────────────────
  static const Color primary = Color(0xFF00AAFF);       // 기도 (Gido) - Sky Blue
  static const Color gamsa = Color(0xFFF59E08);         // 감사 (Gamsa) - Golden Amber
  static const Color seonggadae = Color(0xFF885CF6);    // 성가대 - Purple
  static const Color simbang = Color(0xFFF97316);       // 심방 - Orange
  static const Color guyeok = Color(0xFF108981);        // 구역 - Green
  static const Color gyojeok = Color(0xFF3B82F6);       // 교적 - Navy Blue

  // 기존 호환성 유지
  static const Color primaryDark = Color(0xFF0088DD);
  static const Color primaryLight = Color(0xFFE6F6FF);
  static const Color secondary = Color(0xFF00C9A7);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // ── 텍스트 ───────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1A1A2E);     // Dark Navy
  static const Color textSecondary = Color(0xFF687280);   // Medium Gray
  static const Color textLight = Color(0xFFADB5BD);

  // ── 배경 ─────────────────────────────────────────────────────
  static const Color background = Color(0xFFF8F9FA);      // Off-White
  static const Color surface = Color(0xFFFFFFFF);         // White
  static const Color border = Color(0xFFE8ECEF);          // Light Gray
  static const Color cardShadow = Color(0x0F000000);

  // ── 감사 모듈 전용 컬러 ────────────────────────────────────
  static const Color gamsaLight = Color(0xFFFFFBEB);
  static const Color gamsaDark = Color(0xFFD97706);
  static const Color gamsaBorder = Color(0xFFFDE68A);

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        fontFamily: 'Pretendard',
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          primary: primary,
          secondary: gamsa,
          surface: surface,
          error: error,
        ),
        scaffoldBackgroundColor: background,
        appBarTheme: const AppBarTheme(
          backgroundColor: surface,
          foregroundColor: textPrimary,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
          iconTheme: IconThemeData(color: textPrimary),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50), // pill 형태
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: primary,
            side: const BorderSide(color: primary, width: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: primary,
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: border, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: border, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: error, width: 1),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          hintStyle: const TextStyle(color: textLight, fontSize: 14),
        ),
        cardTheme: CardThemeData(
          color: surface,
          elevation: 0,
          shadowColor: cardShadow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        dividerTheme: const DividerThemeData(color: border, space: 1),
        chipTheme: ChipThemeData(
          backgroundColor: primaryLight,
          selectedColor: primary,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        ),
      );

  // ── 카드 데코레이션 ─────────────────────────────────────────
  static BoxDecoration get cardDecoration => BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      );

  static BoxDecoration get highlightCardDecoration => BoxDecoration(
        color: primaryLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color.fromRGBO(0, 170, 255, 0.2)),
      );

  // ── 감사 카드 데코레이션 ──────────────────────────────────
  static BoxDecoration get gamsaCardDecoration => BoxDecoration(
        color: gamsaLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: gamsaBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0AF59E0B),
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      );
}
