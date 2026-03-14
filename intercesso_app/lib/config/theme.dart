// ============================================
// Flutter 앱 테마 설정 파일
// HTML 디자인 시스템(docs/앱가이드.html)과 동일한 값 사용
// 기존 AppTheme.xxx 참조 호환용 getter 포함
// ============================================

import 'package:flutter/material.dart';

/// 앱 전체에서 사용할 색상 정의
/// HTML의 :root CSS 변수와 동일
class AppColors {
  // ===== Primary Colors (주요 브랜드 색상) =====
  static const Color primaryMain = Color(0xFF4A7FFF);      // #4A7FFF
  static const Color primaryLight = Color(0xFF7BA3FF);    // #7BA3FF
  static const Color primaryDark = Color(0xFF2E5FCC);    // #2E5FCC
  static const Color primaryContrast = Color(0xFFFFFFFF);

  // ===== Secondary Colors (보조 색상 / 감사 등) =====
  static const Color secondaryMain = Color(0xFFFF9D3D);    // #FF9D3D
  static const Color secondaryLight = Color(0xFFFFB76B);
  static const Color secondaryDark = Color(0xFFE68429);

  // ===== Background Colors =====
  static const Color bgPrimary = Color(0xFFFFFFFF);
  /// 화면 배경 (연한 블루 톤 — 흰 카드/파란 버튼과 구분되며 조화)
  static const Color bgSecondary = Color(0xFFEEF2FF);
  static const Color bgTertiary = Color(0xFFE8ECFA);

  // ===== Text Colors =====
  static const Color textPrimary = Color(0xFF212529);
  static const Color textSecondary = Color(0xFF6C757D);
  static const Color textDisabled = Color(0xFFADB5BD);
  static const Color textHint = Color(0xFFCED4DA);

  // ===== Border & Divider =====
  static const Color borderLight = Color(0xFFE9ECEF);
  static const Color borderMain = Color(0xFFDEE2E6);
  static const Color borderDark = Color(0xFFCED4DA);
  static const Color divider = Color(0xFFE9ECEF);

  // ===== Semantic Colors =====
  static const Color success = Color(0xFF4CAF50);
  static const Color successBg = Color(0xFFE8F5E9);
  static const Color successText = Color(0xFF2E7D32);

  static const Color warning = Color(0xFFFFC107);
  static const Color warningBg = Color(0xFFFFF8E1);
  static const Color warningText = Color(0xFFF57F17);

  static const Color error = Color(0xFFF44336);
  static const Color errorBg = Color(0xFFFFEBEE);
  static const Color errorText = Color(0xFFC62828);

  static const Color info = Color(0xFF2196F3);
  static const Color infoBg = Color(0xFFE3F2FD);
  static const Color infoText = Color(0xFF1565C0);
}

/// 간격 시스템 (HTML --spacing-* 와 동일)
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

/// Border Radius (HTML --radius-* 와 동일)
class AppRadius {
  static const double sm = 4.0;
  static const double md = 8.0;
  static const double lg = 12.0;
  static const double xl = 16.0;
  static const double full = 999.0;
}

/// 그림자(Elevation)
class AppElevation {
  static const double none = 0.0;
  static const double sm = 1.0;
  static const double md = 2.0;
  static const double lg = 4.0;
  static const double xl = 8.0;
}

/// 애니메이션 Duration
class AppDuration {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
}

/// 앱 테마 + 기존 코드 호환 (const 유지로 const TextStyle(color: AppTheme.primary) 등 사용 가능)
class AppTheme {
  // ----- 호환용: 기존 AppTheme.primary 등 그대로 사용 (const) -----
  static const Color primary = AppColors.primaryMain;
  static const Color gamsa = AppColors.secondaryMain;
  static const Color primaryDark = AppColors.primaryDark;
  static const Color primaryLight = AppColors.primaryLight;
  static const Color secondary = AppColors.secondaryMain;
  static const Color success = AppColors.success;
  static const Color warning = AppColors.warning;
  static const Color error = AppColors.error;

  static const Color textPrimary = AppColors.textPrimary;
  static const Color textSecondary = AppColors.textSecondary;
  static const Color textLight = AppColors.textDisabled;
  static const Color background = AppColors.bgSecondary;
  static const Color surface = AppColors.bgPrimary;
  static const Color border = AppColors.borderMain;

  // 감사/모듈 전용 (Secondary 계열)
  static const Color gamsaLight = Color(0xFFFFF4E6);
  static const Color gamsaDark = Color(0xFFE68429);
  static const Color gamsaBorder = Color(0xFFFFD9B3);

  // 모듈 시그니처 (찬양대/심방/구역/교적) — 필요 시 유지
  static const Color seonggadae = Color(0xFF885CF6);
  static const Color seonggadaeDark = Color(0xFF6D3FD4); // 그라디언트 끝색
  static const Color seonggadaeLight = Color(0xFFEDE9FE); // 찬양대 연보라 배경
  static const Color simbang = Color(0xFFF97316);
  static const Color guyeok = Color(0xFF108981);
  static const Color gyojeok = Color(0xFF3B82F6);

  static const Color cardShadow = Color(0x14000000);

  // ----- 그라디언트 (HTML Primary/Secondary 기반) -----
  static final LinearGradient primaryGradient = LinearGradient(
    colors: [AppColors.primaryMain, AppColors.primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static final LinearGradient heroGradient = LinearGradient(
    colors: [AppColors.primaryMain, AppColors.primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static final LinearGradient gamsaGradient = LinearGradient(
    colors: [AppColors.secondaryMain, AppColors.secondaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ----- 카드 데코레이션 (기존 호환) -----
  static BoxDecoration get cardDecoration => BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 30, offset: Offset(0, 10)),
        ],
      );

  static BoxDecoration get cardDecorationSmall => BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Color(0x0F000000), blurRadius: 16, offset: Offset(0, 4)),
        ],
      );

  static BoxDecoration get highlightCardDecoration => BoxDecoration(
        color: AppColors.primaryLight.withOpacity(0.25),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.primaryMain.withOpacity(0.15)),
      );

  static BoxDecoration get primaryCardDecoration => BoxDecoration(
        gradient: primaryGradient,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryMain.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      );

  static BoxDecoration get gamsaCardDecoration => BoxDecoration(
        color: gamsaLight,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: gamsaBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondaryMain.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      );

  static BoxDecoration get gamsaGradientDecoration => BoxDecoration(
        gradient: gamsaGradient,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondaryMain.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      );

  // ----- 텍스트 스타일 (기존 호환) -----
  static TextStyle get sectionTitle => const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.3,
      );
  static TextStyle get cardTitle => const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.2,
      );
  static TextStyle get cardSubtitle => const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );
  static TextStyle get badgeText => const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: 0.2,
      );

  // ===== Light Theme (HTML 가이드 + Pretendard) =====
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        fontFamily: 'Pretendard',
        scaffoldBackgroundColor: AppColors.bgSecondary,
        colorScheme: ColorScheme.light(
          primary: AppColors.primaryMain,
          onPrimary: AppColors.primaryContrast,
          primaryContainer: AppColors.primaryLight,
          secondary: AppColors.secondaryMain,
          onSecondary: Colors.white,
          secondaryContainer: AppColors.secondaryLight,
          error: AppColors.error,
          onError: Colors.white,
          errorContainer: AppColors.errorBg,
          surface: AppColors.bgPrimary,
          onSurface: AppColors.textPrimary,
          outline: AppColors.borderMain,
          outlineVariant: AppColors.borderLight,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.bgPrimary,
          foregroundColor: AppColors.textPrimary,
          elevation: AppElevation.sm,
          centerTitle: true,
          titleTextStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
          iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 24),
        ),
        cardTheme: CardTheme(
          color: AppColors.bgPrimary,
          elevation: AppElevation.md,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          margin: const EdgeInsets.all(AppSpacing.sm),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryMain,
            foregroundColor: AppColors.primaryContrast,
            elevation: AppElevation.sm,
            minimumSize: const Size(0, 48),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryMain,
            minimumSize: const Size(0, 48),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            side: const BorderSide(color: AppColors.primaryMain, width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primaryMain,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            minimumSize: const Size(40, 40),
            iconSize: 24,
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: AppColors.primaryMain,
          foregroundColor: Colors.white,
          elevation: AppElevation.lg,
          shape: const CircleBorder(),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.bgPrimary,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.borderMain, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.borderMain, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.primaryMain, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.error, width: 2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.error, width: 2),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.borderLight, width: 1),
          ),
          labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          floatingLabelStyle: const TextStyle(color: AppColors.primaryMain, fontSize: 14),
          hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 16),
          helperStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          errorStyle: const TextStyle(color: AppColors.error, fontSize: 12),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.all(Colors.white),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return AppColors.primaryMain;
            return AppColors.borderDark;
          }),
          trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return AppColors.primaryMain;
            return Colors.transparent;
          }),
          checkColor: WidgetStateProperty.all(Colors.white),
          side: const BorderSide(color: AppColors.borderDark, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
        radioTheme: RadioThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return AppColors.primaryMain;
            return AppColors.borderDark;
          }),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.bgTertiary,
          selectedColor: AppColors.primaryMain,
          disabledColor: AppColors.bgSecondary,
          labelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.divider,
          thickness: 1,
          space: 1,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.bgPrimary,
          selectedItemColor: AppColors.primaryMain,
          unselectedItemColor: AppColors.textSecondary,
          type: BottomNavigationBarType.fixed,
          elevation: 1,
          selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          unselectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
        ),
        tabBarTheme: const TabBarTheme(
          labelColor: AppColors.primaryMain,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primaryMain,
          labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          unselectedLabelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        dialogTheme: DialogTheme(
          backgroundColor: AppColors.bgPrimary,
          elevation: AppElevation.xl,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          contentTextStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.normal,
            color: AppColors.textSecondary,
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: const Color(0xFF323232),
          contentTextStyle: const TextStyle(color: Colors.white, fontSize: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          behavior: SnackBarBehavior.floating,
          elevation: AppElevation.xl,
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppColors.primaryMain,
          linearTrackColor: AppColors.borderLight,
          circularTrackColor: AppColors.borderLight,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            height: 1.2,
          ),
          displayMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            height: 1.2,
          ),
          displaySmall: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            height: 1.3,
          ),
          bodyLarge: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w400,
            color: AppColors.textPrimary,
            height: 1.5,
          ),
          bodyMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: AppColors.textPrimary,
            height: 1.5,
          ),
          bodySmall: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
          labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
          labelMedium: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
          labelSmall: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      );

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        // TODO: 다크 테마 상세 설정
      );
}
