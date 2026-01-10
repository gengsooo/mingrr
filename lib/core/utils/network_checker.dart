import 'dart:io';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../widgets/dialogs/dialogs.dart';

/// ============================================================
/// NetworkChecker - 네트워크 연결 상태 체크 유틸리티
/// 
/// 네트워크 연결 상태를 확인하고 오프라인 시 안내 제공
/// ============================================================

class NetworkChecker {
  static final Connectivity _connectivity = Connectivity();
  
  /// 현재 네트워크 연결 상태 확인
  static Future<bool> get isConnected async {
    try {
      final result = await _connectivity.checkConnectivity();
      if (result.contains(ConnectivityResult.none)) {
        return false;
      }
      // 실제 인터넷 연결 확인 (DNS lookup)
      final lookup = await InternetAddress.lookup('google.com');
      return lookup.isNotEmpty && lookup[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
  
  /// 네트워크 연결 타입 확인
  static Future<String> get connectionType async {
    final result = await _connectivity.checkConnectivity();
    if (result.contains(ConnectivityResult.wifi)) return 'WiFi';
    if (result.contains(ConnectivityResult.mobile)) return 'Mobile';
    if (result.contains(ConnectivityResult.ethernet)) return 'Ethernet';
    return 'None';
  }
  
  /// 네트워크 연결 체크 후 오류 팝업 표시
  /// 연결되어 있으면 true, 아니면 false 반환
  static Future<bool> checkAndShowError(BuildContext context) async {
    if (await isConnected) return true;
    
    if (context.mounted) {
      await showErrorDialog(
        context,
        type: ErrorType.network,
        showRetry: false,
      );
    }
    return false;
  }
  
  /// 네트워크 상태 변경 스트림
  static Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.asyncMap((result) async {
      if (result.contains(ConnectivityResult.none)) return false;
      try {
        final lookup = await InternetAddress.lookup('google.com');
        return lookup.isNotEmpty && lookup[0].rawAddress.isNotEmpty;
      } catch (e) {
        return false;
      }
    });
  }
}
