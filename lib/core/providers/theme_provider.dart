import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 테마 모드 열거형
enum AppThemeMode {
  system, // 시스템 설정 따름
  light,  // 라이트 모드
  dark,   // 다크 모드
}

/// 테마 모드 Provider
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, AppThemeMode>((ref) {
  return ThemeModeNotifier();
});

/// 테마 모드 Notifier
class ThemeModeNotifier extends StateNotifier<AppThemeMode> {
  static const String _key = 'theme_mode';
  
  ThemeModeNotifier() : super(AppThemeMode.system) {
    _loadThemeMode();
  }
  
  /// 저장된 테마 모드 로드
  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    if (value != null) {
      state = AppThemeMode.values.firstWhere(
        (e) => e.name == value,
        orElse: () => AppThemeMode.system,
      );
    }
  }
  
  /// 테마 모드 변경
  Future<void> setThemeMode(AppThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }
  
  /// ThemeMode로 변환 (MaterialApp에서 사용)
  ThemeMode get themeMode {
    switch (state) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }
}

/// 테마 모드 표시 문자열
extension AppThemeModeExtension on AppThemeMode {
  String get displayName {
    switch (this) {
      case AppThemeMode.system:
        return '시스템 설정';
      case AppThemeMode.light:
        return '라이트 모드';
      case AppThemeMode.dark:
        return '다크 모드';
    }
  }
  
  IconData get icon {
    switch (this) {
      case AppThemeMode.system:
        return Icons.settings_brightness;
      case AppThemeMode.light:
        return Icons.light_mode;
      case AppThemeMode.dark:
        return Icons.dark_mode;
    }
  }
}
