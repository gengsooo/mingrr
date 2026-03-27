import 'package:flutter/material.dart';
import '../constants/app_sizes.dart';
import 'feature_colors.dart';

/// ============================================================
/// MINGRR 앱 테마 설정
/// Material 3 기반의 통합 테마 시스템
/// 
/// 색상 사용법:
/// - 기본 색상: Theme.of(context).colorScheme.xxx
/// - 기능별 색상: `Theme.of(context).extension<FeatureColors>()!.xxx`
/// - 또는 확장 메서드: context.colors.xxx, context.features.xxx
/// 
/// 화면 배경색 사용법:
/// - 상세/등록 화면: context.detailBackground (라이트: 흰색, 다크: surface)
/// - 섹션/카드 배경: context.sectionBackground (라이트: tint, 다크: surfaceContainer)
/// ============================================================
class AppTheme {
  AppTheme._();

  // ===== 색상 상수 (내부용) - 뉴트럴 모던 팔레트 =====
  static const _primary = Color(0xFFFF8A65);      // 코럴 (브랜드)
  static const _primaryDark = Color(0xFFFF7043);
  static const _primaryLight = Color(0xFFFFF3E0);
  static const _accent = Color(0xFFFF8A65);
  static const _accentLight = Color(0xFFFFCCBC);
  static const _error = Color(0xFFFF4B4B);
  
  // 라이트 모드 색상 (뉴트럴 그레이 톤)
  static const _textPrimary = Color(0xFF191F28);     // 거의 블랙
  static const _textSecondary = Color(0xFF8B95A1);   // 뉴트럴 그레이
  static const _textHint = Color(0xFFB0B8C1);        // 연한 그레이
  static const _divider = Color(0xFFF2F4F6);         // 배경색과 동일 (시각적 구분)
  static const _background = Color(0xFFFFFFFF);      // 순백
  static const _surfaceVariant = Color(0xFFF2F4F6);  // 카드/섹션 배경
  static const _outline = Color(0xFFE5E8EB);         // 입력 필드 테두리
  
  // 다크 모드 색상 (뉴트럴 다크)
  static const _darkBackground = Color(0xFF17171C);
  static const _darkSurface = Color(0xFF1B1D24);
  static const _darkSurfaceLight = Color(0xFF252830);
  static const _darkDivider = Color(0xFF252830);
  static const _darkTextPrimary = Color(0xFFFFFFFF);
  static const _darkTextSecondary = Color(0xFF8B95A1);
  static const _darkTextHint = Color(0xFF6B7684);

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
        surfaceContainerHighest: _surfaceVariant,
        error: _error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: _textPrimary,
        onSurfaceVariant: _textSecondary,
        onError: Colors.white,
        outline: _outline,
        outlineVariant: _textHint,
      ),
      
      // ===== 배경 색상 =====
      scaffoldBackgroundColor: _background,
      
      // ===== 앱바 테마 =====
      appBarTheme: const AppBarTheme(
        elevation: AppSizes.elevationNone,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: _background,
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
        elevation: AppSizes.elevationNone,
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
        ),
        margin: EdgeInsets.zero,
      ),
      
      // ===== 버튼 테마 =====
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          elevation: AppSizes.elevationNone,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
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
          foregroundColor: _textPrimary,
          side: const BorderSide(color: _outline, width: 1),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
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
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      
      // ===== 입력 필드 테마 (filled 스타일) =====
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingL,
          vertical: AppSizes.paddingL,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
          borderSide: const BorderSide(color: _primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
          borderSide: const BorderSide(color: _error),
        ),
        hintStyle: const TextStyle(
          fontFamily: 'Pretendard',
          color: _textHint,
          fontSize: 15,
        ),
        labelStyle: const TextStyle(
          fontFamily: 'Pretendard',
          color: _textSecondary,
          fontSize: 15,
        ),
      ),
      
      // ===== 바텀 네비게이션 테마 =====
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: _primary,
        unselectedItemColor: _textHint,
        type: BottomNavigationBarType.fixed,
        elevation: AppSizes.elevationM,
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
        elevation: AppSizes.elevationM,
        shape: CircleBorder(),
      ),
      
      // ===== 칩 테마 (pill 형태, border 없음) =====
      chipTheme: ChipThemeData(
        backgroundColor: _surfaceVariant,
        selectedColor: _primary,
        labelStyle: const TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: _textPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        ),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingL,
          vertical: AppSizes.paddingS,
        ),
      ),
      
      // ===== 다이얼로그 테마 =====
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        elevation: AppSizes.elevationM,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
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
        elevation: AppSizes.elevationM,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSizes.radiusL),
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
        primaryContainer: Color(0xFF5D2A1F),
        secondary: _accent,
        secondaryContainer: Color(0xFF5D2A1F),
        surface: _darkSurface,
        surfaceContainerHighest: _darkSurfaceLight,
        error: _error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: _darkTextPrimary,
        onSurfaceVariant: _darkTextSecondary,
        onError: Colors.white,
        outline: _darkDivider,
        outlineVariant: _darkTextHint,
      ),
      
      // ===== 배경 색상 =====
      scaffoldBackgroundColor: _darkBackground,
      
      // ===== 앱바 테마 =====
      appBarTheme: const AppBarTheme(
        elevation: AppSizes.elevationNone,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: _darkBackground,
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
        elevation: AppSizes.elevationNone,
        color: _darkSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
        ),
        margin: EdgeInsets.zero,
      ),
      
      // ===== 버튼 테마 =====
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          elevation: AppSizes.elevationNone,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
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
        elevation: AppSizes.elevationM,
      ),
      
      // ===== 바텀시트 테마 =====
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: _darkSurface,
        modalBackgroundColor: _darkSurface,
        elevation: AppSizes.elevationM,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSizes.radiusL),
          ),
        ),
      ),
      
      // ===== 다이얼로그 테마 =====
      dialogTheme: DialogThemeData(
        backgroundColor: _darkSurface,
        surfaceTintColor: Colors.transparent,
        elevation: AppSizes.elevationM,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
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
      
      // ===== 칩 테마 (pill 형태, border 없음) =====
      chipTheme: ChipThemeData(
        backgroundColor: _darkSurfaceLight,
        selectedColor: _primary,
        disabledColor: _darkDivider,
        labelStyle: const TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: _darkTextPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        ),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingL,
          vertical: AppSizes.paddingS,
        ),
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
