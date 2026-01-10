import 'package:flutter/foundation.dart';

/// ============================================================
/// AppLogger - 공통 로깅 유틸리티
/// 
/// 앱 전체에서 일관된 로깅 형식 제공
/// 개발 모드에서만 로그 출력 (릴리즈 모드에서는 비활성화)
/// ============================================================

enum LogLevel { debug, info, warning, error }

class AppLogger {
  static const String _appName = 'MINGRR';
  
  /// 디버그 로그
  static void debug(String tag, String message) {
    _log(LogLevel.debug, tag, message);
  }
  
  /// 정보 로그
  static void info(String tag, String message) {
    _log(LogLevel.info, tag, message);
  }
  
  /// 경고 로그
  static void warning(String tag, String message) {
    _log(LogLevel.warning, tag, message);
  }
  
  /// 오류 로그
  static void error(String tag, String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.error, tag, message);
    if (error != null) {
      debugPrint('❌ [$_appName] Error: $error');
    }
    if (stackTrace != null && kDebugMode) {
      debugPrint('❌ [$_appName] StackTrace: $stackTrace');
    }
  }
  
  /// API/네트워크 오류 로그
  static void networkError(String tag, String endpoint, Object error) {
    _log(LogLevel.error, tag, '네트워크 오류 - $endpoint');
    debugPrint('🌐 [$_appName] Endpoint: $endpoint');
    debugPrint('🌐 [$_appName] Error: $error');
  }
  
  /// Firebase/DB 오류 로그
  static void dbError(String tag, String operation, Object error) {
    _log(LogLevel.error, tag, 'DB 오류 - $operation');
    debugPrint('🗄️ [$_appName] Operation: $operation');
    debugPrint('🗄️ [$_appName] Error: $error');
  }
  
  /// 위치 오류 로그
  static void locationError(String tag, String message, Object error) {
    _log(LogLevel.error, tag, '위치 오류 - $message');
    debugPrint('📍 [$_appName] Error: $error');
  }
  
  /// 권한 오류 로그
  static void permissionError(String tag, String permission) {
    _log(LogLevel.warning, tag, '권한 거부 - $permission');
  }
  
  /// 내부 로그 출력
  static void _log(LogLevel level, String tag, String message) {
    if (!kDebugMode) return;
    
    final emoji = switch (level) {
      LogLevel.debug => '🔍',
      LogLevel.info => 'ℹ️',
      LogLevel.warning => '⚠️',
      LogLevel.error => '❌',
    };
    
    final timestamp = DateTime.now().toString().substring(11, 19);
    debugPrint('$emoji [$timestamp] [$tag] $message');
  }
}
