import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/dialogs/dialogs.dart';
import 'app_logger.dart';

/// ============================================================
/// ErrorHandler - 공통 오류 처리 유틸리티
/// 
/// 오류 타입 자동 감지 및 적절한 팝업 표시
/// 일관된 오류 처리 및 로깅 제공
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
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
  
  /// 성공 메시지 표시
  static void showSuccess(BuildContext context, String message) {
    showSnackBar(context, message: message, isError: false);
  }
}
