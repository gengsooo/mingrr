import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/dialogs/dialogs.dart';
import '../widgets/snackbar/mingrr_snackbar.dart';
import 'app_logger.dart';

/// ============================================================
/// ErrorHandler - 공통 오류 처리 유틸리티
/// 
/// 오류 타입 자동 감지 및 적절한 팝업 표시
/// 일관된 오류 처리 및 로깅 제공
/// 
/// 사용법:
/// 1. 다이얼로그 표시 (재시도 가능):
///    ErrorHandler.handle(context, error: e, tag: 'Screen');
/// 
/// 2. 스낵바만 표시 (간단한 알림):
///    ErrorHandler.showError(context, e, tag: 'Screen');
/// 
/// 3. 사용자 친화적 메시지만 얻기:
///    final message = ErrorHandler.getMessage(e);
/// ============================================================

class ErrorHandler {
  /// 오류 처리 및 팝업 표시
  /// 
  /// [context]: BuildContext
  /// [error]: 발생한 오류
  /// [tag]: 로깅용 태그 (화면/기능명)
  /// [operation]: 수행 중이던 작업 설명
  /// [onRetry]: 재시도 콜백 (null이면 재시도 버튼 없음)
  /// [themeColor]: 팝업 테마 색상
  static Future<ErrorResult?> handle(
    BuildContext context, {
    required Object error,
    required String tag,
    String? operation,
    VoidCallback? onRetry,
    Color? themeColor,
  }) async {
    final errorType = _detectErrorType(error);
    final message = operation ?? '작업 처리';
    
    // 로깅
    _logError(tag, message, error, errorType);
    
    // 팝업 표시
    if (!context.mounted) return null;
    
    final result = await showErrorDialog(
      context,
      type: errorType,
      themeColor: themeColor,
      showRetry: onRetry != null,
    );
    
    if (result == ErrorResult.retry && onRetry != null) {
      onRetry();
    }
    
    return result;
  }
  
  /// 오류 타입 자동 감지
  static ErrorType _detectErrorType(Object error) {
    final errorString = error.toString().toLowerCase();
    
    // 네트워크 오류
    if (error is SocketException || 
        errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('socket') ||
        errorString.contains('host lookup')) {
      return ErrorType.network;
    }
    
    // 타임아웃 오류
    if (error is TimeoutException ||
        errorString.contains('timeout') ||
        errorString.contains('timed out')) {
      return ErrorType.timeout;
    }
    
    // Firebase/DB 오류
    if (error is FirebaseException ||
        errorString.contains('firebase') ||
        errorString.contains('firestore') ||
        errorString.contains('database')) {
      return ErrorType.database;
    }
    
    // 권한 오류
    if (errorString.contains('permission') ||
        errorString.contains('denied') ||
        errorString.contains('unauthorized')) {
      return ErrorType.permission;
    }
    
    // 위치 오류
    if (errorString.contains('location') ||
        errorString.contains('gps') ||
        errorString.contains('geolocator')) {
      return ErrorType.location;
    }
    
    // 인증 오류
    if (errorString.contains('auth') ||
        errorString.contains('login') ||
        errorString.contains('credential') ||
        errorString.contains('token')) {
      return ErrorType.auth;
    }
    
    // 서버 오류
    if (errorString.contains('server') ||
        errorString.contains('500') ||
        errorString.contains('503') ||
        errorString.contains('api')) {
      return ErrorType.server;
    }
    
    // 일반 오류
    return ErrorType.general;
  }
  
  /// 오류 로깅
  static void _logError(String tag, String operation, Object error, ErrorType type) {
    switch (type) {
      case ErrorType.network:
        AppLogger.networkError(tag, operation, error);
        break;
      case ErrorType.database:
        AppLogger.dbError(tag, operation, error);
        break;
      case ErrorType.location:
        AppLogger.locationError(tag, operation, error);
        break;
      case ErrorType.permission:
        AppLogger.permissionError(tag, operation);
        break;
      default:
        AppLogger.error(tag, operation, error);
    }
  }
  
  /// 간단한 오류 스낵바 표시 (팝업 없이)
  static void showSnackBar(
    BuildContext context, {
    required String message,
    bool isError = true,
  }) {
    if (!context.mounted) return;
    
    if (isError) {
      MingrrSnackBar.error(context, message);
    } else {
      MingrrSnackBar.success(context, message);
    }
  }
  
  /// 성공 메시지 표시
  static void showSuccess(BuildContext context, String message) {
    if (!context.mounted) return;
    MingrrSnackBar.success(context, message);
  }
  
  // ===== 사용자 친화적 메시지 변환 =====
  
  /// 오류 객체를 사용자 친화적 메시지로 변환
  /// 
  /// 기술적인 오류 메시지를 사용자가 이해하기 쉬운 메시지로 변환합니다.
  /// 내부 시스템 정보는 노출하지 않습니다.
  /// 
  /// 사용 예:
  /// ```dart
  /// catch (e) {
  ///   MingrrSnackBar.error(context, ErrorHandler.getMessage(e));
  /// }
  /// ```
  static String getMessage(Object error) {
    final errorString = error.toString().toLowerCase();
    
    // Firestore 서버 연결 불가
    if (errorString.contains('unavailable')) {
      return '서버 연결이 불안정해요. 잠시 후 다시 시도해주세요.';
    }
    
    // 네트워크 오류
    if (error is SocketException ||
        errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('socket') ||
        errorString.contains('host lookup') ||
        errorString.contains('failed host lookup')) {
      return '인터넷 연결을 확인해주세요.';
    }
    
    // 타임아웃
    if (error is TimeoutException ||
        errorString.contains('timeout') ||
        errorString.contains('timed out')) {
      return '요청 시간이 초과되었어요. 다시 시도해주세요.';
    }
    
    // Firestore 권한 오류
    if (errorString.contains('permission-denied') ||
        errorString.contains('permission denied')) {
      return '권한이 없어요. 다시 로그인해주세요.';
    }
    
    // 문서 없음
    if (errorString.contains('not-found') ||
        errorString.contains('not found')) {
      return '요청한 데이터를 찾을 수 없어요.';
    }
    
    // 이미 존재
    if (errorString.contains('already-exists') ||
        errorString.contains('already exists')) {
      return '이미 존재하는 데이터예요.';
    }
    
    // 인증 오류
    if (error is FirebaseAuthException) {
      return _getAuthErrorMessage(error);
    }
    
    // Firebase 일반 오류
    if (error is FirebaseException) {
      return _getFirebaseErrorMessage(error);
    }
    
    // 위치 오류
    if (errorString.contains('location') ||
        errorString.contains('gps') ||
        errorString.contains('geolocator')) {
      return '위치 정보를 가져올 수 없어요.';
    }
    
    // 이미지 업로드 오류
    if (errorString.contains('upload') ||
        errorString.contains('storage')) {
      return '파일 업로드에 실패했어요.';
    }
    
    // 취소됨
    if (errorString.contains('cancelled') ||
        errorString.contains('canceled')) {
      return '작업이 취소되었어요.';
    }
    
    // Exception: 접두사 제거
    final cleanMessage = error.toString()
        .replaceAll('Exception: ', '')
        .replaceAll('exception: ', '');
    
    // 한글 메시지인 경우 그대로 반환 (이미 사용자 친화적)
    if (_isKoreanMessage(cleanMessage)) {
      return cleanMessage;
    }
    
    // 기본 메시지
    return '문제가 발생했어요. 다시 시도해주세요.';
  }
  
  /// Firebase Auth 오류 메시지 변환
  static String _getAuthErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'user-not-found':
        return '등록되지 않은 사용자예요.';
      case 'wrong-password':
        return '비밀번호가 올바르지 않아요.';
      case 'email-already-in-use':
        return '이미 사용 중인 이메일이에요.';
      case 'weak-password':
        return '비밀번호가 너무 약해요.';
      case 'invalid-email':
        return '올바른 이메일 형식이 아니에요.';
      case 'user-disabled':
        return '비활성화된 계정이에요.';
      case 'too-many-requests':
        return '요청이 너무 많아요. 잠시 후 다시 시도해주세요.';
      case 'operation-not-allowed':
        return '허용되지 않은 작업이에요.';
      case 'invalid-verification-code':
        return '인증 코드가 올바르지 않아요.';
      case 'invalid-verification-id':
        return '인증 세션이 만료되었어요. 다시 시도해주세요.';
      case 'session-expired':
        return '세션이 만료되었어요. 다시 로그인해주세요.';
      case 'requires-recent-login':
        return '보안을 위해 다시 로그인이 필요해요.';
      default:
        return '인증에 실패했어요. 다시 시도해주세요.';
    }
  }
  
  /// Firebase 일반 오류 메시지 변환
  static String _getFirebaseErrorMessage(FirebaseException error) {
    switch (error.code) {
      case 'unavailable':
        return '서버 연결이 불안정해요. 잠시 후 다시 시도해주세요.';
      case 'permission-denied':
        return '권한이 없어요. 다시 로그인해주세요.';
      case 'not-found':
        return '요청한 데이터를 찾을 수 없어요.';
      case 'already-exists':
        return '이미 존재하는 데이터예요.';
      case 'cancelled':
        return '작업이 취소되었어요.';
      case 'deadline-exceeded':
        return '요청 시간이 초과되었어요.';
      case 'resource-exhausted':
        return '요청 한도를 초과했어요. 잠시 후 다시 시도해주세요.';
      case 'unauthenticated':
        return '로그인이 필요해요.';
      case 'internal':
        return '서버 오류가 발생했어요. 잠시 후 다시 시도해주세요.';
      case 'data-loss':
        return '데이터 처리 중 오류가 발생했어요.';
      case 'invalid-argument':
        return '잘못된 요청이에요.';
      case 'failed-precondition':
        return '요청을 처리할 수 없는 상태예요.';
      case 'aborted':
        return '작업이 중단되었어요. 다시 시도해주세요.';
      case 'out-of-range':
        return '요청 범위를 벗어났어요.';
      case 'unimplemented':
        return '지원하지 않는 기능이에요.';
      default:
        return '문제가 발생했어요. 다시 시도해주세요.';
    }
  }
  
  /// 한글 메시지인지 확인
  static bool _isKoreanMessage(String message) {
    // 한글이 포함되어 있고, 영문 기술 용어가 없으면 한글 메시지로 판단
    final hasKorean = RegExp(r'[가-힣]').hasMatch(message);
    final hasTechnicalTerms = RegExp(
      r'(firebase|firestore|exception|error|null|undefined|socket|network|timeout)',
      caseSensitive: false,
    ).hasMatch(message);
    
    return hasKorean && !hasTechnicalTerms;
  }
  
  // ===== 스낵바 기반 에러 표시 (간단한 오류용) =====
  
  /// 오류를 스낵바로 표시 (다이얼로그 없이)
  /// 
  /// 간단한 오류 알림에 사용합니다.
  /// 자동으로 사용자 친화적 메시지로 변환됩니다.
  /// 
  /// 사용 예:
  /// ```dart
  /// catch (e) {
  ///   ErrorHandler.showError(context, e, tag: 'ProfileEdit');
  /// }
  /// ```
  static void showError(
    BuildContext context,
    Object error, {
    required String tag,
    String? operation,
  }) {
    // 로깅
    final errorType = _detectErrorType(error);
    _logError(tag, operation ?? '작업 처리', error, errorType);
    
    // 스낵바 표시
    if (!context.mounted) return;
    showSnackBar(context, message: getMessage(error), isError: true);
  }
}
