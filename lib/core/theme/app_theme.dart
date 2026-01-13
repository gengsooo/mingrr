import 'package:flutter/material.dart';
import '../constants/app_sizes.dart';
import 'feature_colors.dart';

/// ============================================================
/// MINGRR 앱 테마 설정
/// Material 3 기반의 통합 테마 시스템
/// 
/// 색상 사용법:
/// - 기본 색상: Theme.of(context).colorScheme.xxx
/// - 기능별 색상: Theme.of(context).extension<FeatureColors>()!.xxx
/// - 또는 확장 메서드: context.colors.xxx, context.features.xxx
/// 
/// 화면 배경색 사용법:
/// - 상세/등록 화면: context.detailBackground (라이트: 흰색, 다크: surface)
/// - 섹션/카드 배경: context.sectionBackground (라이트: tint, 다크: surfaceContainer)
/// ============================================================
class AppTheme {
  AppTheme._();

  // ===== 색상 상수 (내부용) =====
  static const _primary = Color(0xFFFFD54F);
  static const _primaryDark = Color(0xFFFFC107);
  static const _primaryLight = Color(0xFFFFF8E1);
  static const _accent = Color(0xFFFF8A65);
  static const _accentLight = Color(0xFFFFCCBC);
  static const _error = Color(0xFFE57373);
  
  // 라이트 모드 색상
  static const _textPrimary = Color(0xFF3E2723);
  static const _textSecondary = Color(0xFF795548);
  static const _textHint = Color(0xFFBCAAA4);
  static const _divider = Color(0xFFEEE0D5);
  static const _background = Color(0xFFFFFBF5);
  
  // 다크 모드 색상
  static const _darkBackground = Color(0xFF121212);
  static const _darkSurface = Color(0xFF1E1E1E);
  static const _darkSurfaceLight = Color(0xFF2C2C2C);
  static const _darkDivider = Color(0xFF3C3C3C);
  static const _darkTextPrimary = Color(0xFFFFFFFF);
  static const _darkTextSecondary = Color(0xFFB3B3B3);
  static const _darkTextHint = Color(0xFF757575);

  /// 라이트 테마 (기본)
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      // ===== ThemeExtension 등록 =====
      extensions: const [FeatureColors.light],
      
      // ===== 색상 스킴 =====
      colorScheme: const ColorScheme.light(
        primary: _primary,
        primaryContainer: _primaryLight,
        secondary: _accent,
        secondaryContainer: _accentLight,
        tertiary: _primaryDark,
        surface: Colors.white,
        surfaceContainerHighest: _primaryLight,
        error: _error,
        onPrimary: _textPrimary,
        onSecondary: Colors.white,
        onSurface: _textPrimary,
        onSurfaceVariant: _textSecondary,
        onError: Colors.white,
        outline: _divider,
        outlineVariant: _textHint,
      ),
      
      // ===== 배경 색상 =====
      scaffoldBackgroundColor: _background,
      
      // ===== 앱바 테마 =====
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        foregroundColor: _textPrimary,
        titleTextStyle: TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: _textPrimary,
        ),
        iconTheme: IconThemeData(
          color: _textPrimary,
          size: AppSizes.iconM,
        ),
      ),
      
      // ===== 카드 테마 =====
      cardTheme: CardThemeData(
        elevation: AppSizes.cardElevation,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingM,
          vertical: AppSizes.paddingS,
        ),
      ),
      
      // ===== 버튼 테마 =====
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: _textPrimary,
          elevation: 0,
          minimumSize: const Size(double.infinity, AppSizes.buttonHeightL),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusL),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _primary,
          side: const BorderSide(color: _primary, width: 1.5),
          minimumSize: const Size(double.infinity, AppSizes.buttonHeightL),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusL),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _textSecondary,
          textStyle: const TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      
      // ===== 입력 필드 테마 =====
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingM,
          vertical: AppSizes.paddingM,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          borderSide: const BorderSide(color: _divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          borderSide: const BorderSide(color: _divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          borderSide: const BorderSide(color: _primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          borderSide: const BorderSide(color: _error),
        ),
        hintStyle: const TextStyle(
          fontFamily: 'Pretendard',
          color: _textHint,
          fontSize: 13,
        ),
        labelStyle: const TextStyle(
          fontFamily: 'Pretendard',
          color: _textSecondary,
          fontSize: 14,
        ),
      ),
      
      // ===== 바텀 네비게이션 테마 =====
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: _primary,
        unselectedItemColor: _textHint,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),
      
      // ===== 플로팅 액션 버튼 테마 =====
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _primary,
        foregroundColor: _textPrimary,
        elevation: 4,
        shape: CircleBorder(),
      ),
      
      // ===== 칩 테마 =====
      chipTheme: ChipThemeData(
        backgroundColor: _primaryLight,
        selectedColor: _primary,
        labelStyle: const TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 13,
          color: _textPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        ),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingM,
          vertical: AppSizes.paddingS,
        ),
      ),
      
      // ===== 다이얼로그 테마 =====
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusXL),
        ),
        titleTextStyle: const TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: _textPrimary,
        ),
        contentTextStyle: const TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 14,
          color: _textSecondary,
        ),
      ),
      
      // ===== 바텀시트 테마 =====
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSizes.radiusXL),
          ),
        ),
      ),
      
      // ===== 스낵바 테마 =====
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _textPrimary,
        contentTextStyle: const TextStyle(
          fontFamily: 'Pretendard',
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      
      // ===== 탭바 테마 =====
      tabBarTheme: const TabBarThemeData(
        labelColor: _primary,
        unselectedLabelColor: _textHint,
        indicatorColor: _primary,
        labelStyle: TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),
      
      // ===== 디바이더 테마 =====
      dividerTheme: const DividerThemeData(
        color: _divider,
        thickness: 1,
        space: 1,
      ),
      
      // ===== 텍스트 테마 =====
      textTheme: const TextTheme(
        // 대형 제목
        displayLarge: TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: _textPrimary,
        ),
        displayMedium: TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: _textPrimary,
        ),
        displaySmall: TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: _textPrimary,
        ),
        // 헤드라인
        headlineLarge: TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: _textPrimary,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: _textPrimary,
        ),
        headlineSmall: TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: _textPrimary,
        ),
        // 타이틀
        titleLarge: TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: _textPrimary,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: _textPrimary,
        ),
        titleSmall: TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: _textPrimary,
        ),
        // 본문
        bodyLarge: TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: _textPrimary,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: _textPrimary,
        ),
        bodySmall: TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: _textSecondary,
        ),
        // 라벨
        labelLarge: TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: _textPrimary,
        ),
        labelMedium: TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: _textSecondary,
        ),
        labelSmall: TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color: _textHint,
        ),
      ),
      
      // ===== 폰트 패밀리 =====
      fontFamily: 'Pretendard',
    );
  }

  /// 다크 테마
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      // ===== ThemeExtension 등록 =====
      extensions: const [FeatureColors.dark],
      
      // ===== 색상 스킴 =====
      colorScheme: const ColorScheme.dark(
        primary: _primary,
        primaryContainer: Color(0xFF3D3D00),
        secondary: _accent,
        secondaryContainer: Color(0xFF5D2A1F),
        surface: _darkSurface,
        surfaceContainerHighest: _darkSurfaceLight,
        error: _error,
        onPrimary: _textPrimary,
        onSecondary: Colors.white,
        onSurface: _darkTextPrimary,
        onSurfaceVariant: _darkTextSecondary,
        onError: Colors.white,
        outline: _darkDivider,
      ),
      
      // ===== 배경 색상 =====
      scaffoldBackgroundColor: _darkBackground,
      
      // ===== 앱바 테마 =====
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        backgroundColor: _darkSurface,
        foregroundColor: _darkTextPrimary,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: _darkTextPrimary,
        ),
        iconTheme: IconThemeData(
          color: _darkTextPrimary,
          size: AppSizes.iconM,
        ),
      ),
      
      // ===== 카드 테마 =====
      cardTheme: CardThemeData(
        elevation: 2,
        color: _darkSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingM,
          vertical: AppSizes.paddingS,
        ),
      ),
      
      // ===== 버튼 테마 =====
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: _textPrimary,
          elevation: 0,
          minimumSize: const Size(double.infinity, AppSizes.buttonHeightL),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusL),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _primary,
          side: const BorderSide(color: _primary, width: 1.5),
          minimumSize: const Size(double.infinity, AppSizes.buttonHeightL),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusL),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _primary,
          textStyle: const TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      
      // ===== 입력 필드 테마 =====
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkSurfaceLight,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingM,
          vertical: AppSizes.paddingM,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          borderSide: const BorderSide(color: _darkDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          borderSide: const BorderSide(color: _darkDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          borderSide: const BorderSide(color: _primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          borderSide: const BorderSide(color: _error),
        ),
        hintStyle: const TextStyle(
          fontFamily: 'Pretendard',
          color: _darkTextHint,
          fontSize: 14,
        ),
        labelStyle: const TextStyle(
          fontFamily: 'Pretendard',
          color: _darkTextSecondary,
        ),
      ),
      
      // ===== 바텀 네비게이션 테마 =====
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _darkSurface,
        selectedItemColor: _primary,
        unselectedItemColor: _darkTextHint,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      
      // ===== 바텀시트 테마 =====
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: _darkSurface,
        modalBackgroundColor: _darkSurface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSizes.radiusXL),
          ),
        ),
      ),
      
      // ===== 다이얼로그 테마 =====
      dialogTheme: DialogThemeData(
        backgroundColor: _darkSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusXL),
        ),
        titleTextStyle: const TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: _darkTextPrimary,
        ),
        contentTextStyle: const TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 14,
          color: _darkTextSecondary,
        ),
      ),
      
      // ===== 스낵바 테마 =====
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _darkSurfaceLight,
        contentTextStyle: const TextStyle(
          fontFamily: 'Pretendard',
          color: _darkTextPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      
      // ===== 칩 테마 =====
      chipTheme: ChipThemeData(
        backgroundColor: _darkSurfaceLight,
        selectedColor: _primary.withValues(alpha: 0.3),
        disabledColor: _darkDivider,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
        ),
        side: const BorderSide(color: _darkDivider),
      ),
      
      // ===== 탭바 테마 =====
      tabBarTheme: const TabBarThemeData(
        labelColor: _primary,
        unselectedLabelColor: _darkTextSecondary,
        indicatorColor: _primary,
      ),
      
      // ===== 리스트타일 테마 =====
      listTileTheme: const ListTileThemeData(
        textColor: _darkTextPrimary,
        iconColor: _darkTextPrimary,
      ),
      
      // ===== 아이콘 테마 =====
      iconTheme: const IconThemeData(
        color: _darkTextPrimary,
      ),
      
      // ===== 디바이더 테마 =====
      dividerTheme: const DividerThemeData(
        color: _darkDivider,
        thickness: 1,
        space: 1,
      ),
      
      // ===== 폰트 패밀리 =====
      fontFamily: 'Pretendard',
    );
  }
}

/// ============================================================
/// 화면 배경색 확장 메서드
/// 상세/등록 화면에서 라이트/다크 모드 통합 배경색 제공
/// ============================================================
extension ScreenBackgroundExtension on BuildContext {
  /// 상세/등록 화면 배경색
  /// - 라이트: 흰색 (깔끔한 폼 배경)
  /// - 다크: surface (기존 다크 테마 유지)
  Color get detailBackground {
    final isDark = Theme.of(this).brightness == Brightness.dark;
    return isDark 
        ? Theme.of(this).colorScheme.surface 
        : Colors.white;
  }
  
  /// 섹션/카드 배경색 (상세/등록 화면 내부 컨테이너용)
  /// - 라이트: 홈 배경색 (0xFFFFFBF5) - 서비스 대표 색상
  /// - 다크: surfaceContainerHighest (기존 다크 테마 유지)
  Color get sectionBackground {
    final isDark = Theme.of(this).brightness == Brightness.dark;
    return isDark 
        ? Theme.of(this).colorScheme.surfaceContainerHighest 
        : const Color(0xFFFFFBF5);
  }
  
  /// 입력 필드 배경색
  /// - 라이트: 홈 배경색 (0xFFFFFBF5) - 서비스 대표 색상
  /// - 다크: surfaceContainerHighest
  Color get inputBackground {
    final isDark = Theme.of(this).brightness == Brightness.dark;
    return isDark 
        ? Theme.of(this).colorScheme.surfaceContainerHighest 
        : const Color(0xFFFFFBF5);
  }
}
