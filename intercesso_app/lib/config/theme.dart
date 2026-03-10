import 'package:flutter/material.dart';

class AppTheme {
  // ── 모듈별 시그니처 컬러 (디자인 가이드 기준) ────────────────────────
  static const Color primary = Color(0xFF2F6FED);       // 메인 Primary - Deep Blue
  static const Color gamsa = Color(0xFFF59E08);         // 감사 (Gamsa) - Golden Amber
  static const Color seonggadae = Color(0xFF885CF6);    // 성가대 - Purple
  static const Color simbang = Color(0xFFF97316);       // 심방 - Orange
  static const Color guyeok = Color(0xFF108981);        // 구역 - Green
  static const Color gyojeok = Color(0xFF3B82F6);       // 교적 - Navy Blue

  // ── 보조 컬러 ────────────────────────────────────────────────
  static const Color primaryDark = Color(0xFF1E56C8);
  static const Color primaryLight = Color(0xFFEEF4FD);
  static const Color secondary = Color(0xFF00C9A7);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // ── 텍스트 (디자인 가이드) ──────────────────────────────────
  static const Color textPrimary = Color(0xFF1F2D3D);
  static const Color textSecondary = Color(0xFF6B7C93);
  static const Color textLight = Color(0xFFADB5BD);

  // ── 배경 (디자인 가이드) ────────────────────────────────────
  static const Color background = Color(0xFFF4F6FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE4E9F2);
  static const Color cardShadow = Color(0x14000000);

  // ── 감사 모듈 전용 컬러 ────────────────────────────────────
  static const Color gamsaLight = Color(0xFFFFFBEB);
  static const Color gamsaDark = Color(0xFFD97706);
  static const Color gamsaBorder = Color(0xFFFDE68A);

  // ── 그라디언트 ──────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2F6FED), Color(0xFF1E56C8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF2F6FED), Color(0xFF4A90E2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gamsaGradient = LinearGradient(
    colors: [Color(0xFFF59E08), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

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
            letterSpacing: -0.3,
          ),
          iconTheme: IconThemeData(color: textPrimary),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: primary,
            side: const BorderSide(color: primary, width: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
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
            borderRadius: BorderRadius.circular(18),
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

  // ── 카드 데코레이션 (디자인 가이드: radius 18px, shadow) ────
  static BoxDecoration get cardDecoration => BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 30,
            offset: Offset(0, 10),
          ),
        ],
      );

  static BoxDecoration get cardDecorationSmall => BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      );

  static BoxDecoration get highlightCardDecoration => BoxDecoration(
        color: primaryLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Color.fromRGBO(47, 111, 237, 0.15)),
      );

  // ── 그라디언트 카드 데코레이션 ───────────────────────────────
  static BoxDecoration get primaryCardDecoration => BoxDecoration(
        gradient: primaryGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x332F6FED),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      );

  // ── 감사 카드 데코레이션 ──────────────────────────────────
  static BoxDecoration get gamsaCardDecoration => BoxDecoration(
        color: gamsaLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: gamsaBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14F59E0B),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      );

  // ── 감사 그라디언트 카드 ──────────────────────────────────
  static BoxDecoration get gamsaGradientDecoration => BoxDecoration(
        gradient: gamsaGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33F59E0B),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      );

  // ── 섹션 헤더 스타일 ─────────────────────────────────────
  static TextStyle get sectionTitle => const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: -0.3,
      );

  static TextStyle get cardTitle => const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: -0.2,
      );

  static TextStyle get cardSubtitle => const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: textSecondary,
      );

  static TextStyle get badgeText => const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: 0.2,
      );
}
