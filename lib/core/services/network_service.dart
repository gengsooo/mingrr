import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/app_logger.dart';

/// ============================================================
/// 네트워크 연결 상태 관리 서비스
/// 
/// 앱 전체에서 네트워크 상태를 모니터링하고 관리
/// - 실시간 연결 상태 감지
/// - 오프라인 모드 지원
/// - 네트워크 오류 처리 유틸리티
/// ============================================================

/// 네트워크 연결 상태
enum NetworkStatus {
  /// 온라인 (WiFi 또는 모바일 데이터)
  online,
  /// 오프라인
  offline,
  /// 확인 중
  checking,
}

class NetworkService {
  // 싱글톤 패턴
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal();

  final Connectivity _connectivity = Connectivity();
  
  // 현재 네트워크 상태
  NetworkStatus _currentStatus = NetworkStatus.checking;
  NetworkStatus get currentStatus => _currentStatus;
  
  // 상태 변경 스트림 컨트롤러
  final _statusController = StreamController<NetworkStatus>.broadcast();
  Stream<NetworkStatus> get statusStream => _statusController.stream;
  
  // 구독 관리
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  
  /// 서비스 초기화
  Future<void> initialize() async {
    try {
      // 현재 상태 확인
      final results = await _connectivity.checkConnectivity();
      _updateStatus(results);
      
      // 상태 변경 구독
      _subscription = _connectivity.onConnectivityChanged.listen(
        _updateStatus,
        onError: (error) {
          AppLogger.error('NetworkService', '연결 상태 감지 오류', error);
          _currentStatus = NetworkStatus.offline;
          _statusController.add(_currentStatus);
        },
      );
      
      AppLogger.info('NetworkService', '네트워크 서비스 초기화 완료 (상태: $_currentStatus)');
    } catch (e) {
      AppLogger.error('NetworkService', '네트워크 서비스 초기화 실패', e);
      _currentStatus = NetworkStatus.offline;
    }
  }
  
  /// 연결 상태 업데이트
  void _updateStatus(List<ConnectivityResult> results) {
    final previousStatus = _currentStatus;
    
    if (results.contains(ConnectivityResult.wifi) ||
        results.contains(ConnectivityResult.mobile) ||
        results.contains(ConnectivityResult.ethernet)) {
      _currentStatus = NetworkStatus.online;
    } else if (results.contains(ConnectivityResult.none)) {
      _currentStatus = NetworkStatus.offline;
    } else {
      _currentStatus = NetworkStatus.offline;
    }
    
    // 상태가 변경된 경우에만 로깅 및 알림
    if (previousStatus != _currentStatus) {
      AppLogger.info('NetworkService', '네트워크 상태 변경: $previousStatus → $_currentStatus');
      _statusController.add(_currentStatus);
    }
  }
  
  /// 현재 온라인 상태인지 확인
  bool get isOnline => _currentStatus == NetworkStatus.online;
  
  /// 현재 오프라인 상태인지 확인
  bool get isOffline => _currentStatus == NetworkStatus.offline;
  
  /// 네트워크 상태 수동 확인
  Future<bool> checkConnection() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateStatus(results);
      return isOnline;
    } catch (e) {
      AppLogger.error('NetworkService', '네트워크 상태 확인 실패', e);
      return false;
    }
  }
  
  /// 서비스 정리
  void dispose() {
    _subscription?.cancel();
    _statusController.close();
  }
}

/// ============================================================
/// 네트워크 오류 처리 유틸리티
/// ============================================================

/// 네트워크 관련 예외
class NetworkException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  
  const NetworkException({
    required this.message,
    this.code,
    this.originalError,
  });
  
  @override
  String toString() => 'NetworkException: $message (code: $code)';
  
  /// 사용자에게 표시할 메시지
  String get userMessage {
    switch (code) {
      case 'no_connection':
        return '인터넷 연결을 확인해주세요.';
      case 'timeout':
        return '요청 시간이 초과되었습니다. 다시 시도해주세요.';
      case 'server_error':
        return '서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
      case 'permission_denied':
        return '접근 권한이 없습니다.';
      case 'not_found':
        return '요청한 데이터를 찾을 수 없습니다.';
      default:
        return message;
    }
  }
}

/// 네트워크 요청 래퍼
/// 네트워크 상태 확인 및 오류 처리를 자동으로 수행
class NetworkRequestHelper {
  static final NetworkService _networkService = NetworkService();
  
  /// 네트워크 요청 실행
  /// 
  /// [request] 실행할 비동기 요청
  /// [onOffline] 오프라인 시 실행할 콜백 (선택)
  /// [retryCount] 재시도 횟수 (기본: 0)
  /// [retryDelay] 재시도 간격 (기본: 1초)
  static Future<T> execute<T>({
    required Future<T> Function() request,
    T Function()? onOffline,
    int retryCount = 0,
    Duration retryDelay = const Duration(seconds: 1),
  }) async {
    // 네트워크 상태 확인
    if (_networkService.isOffline) {
      if (onOffline != null) {
        return onOffline();
      }
      throw const NetworkException(
        message: '인터넷 연결이 없습니다.',
        code: 'no_connection',
      );
    }
    
    // 요청 실행 (재시도 포함)
    int attempts = 0;
    while (true) {
      try {
        return await request();
      } catch (e) {
        attempts++;
        
        // 재시도 횟수 초과
        if (attempts > retryCount) {
          AppLogger.error('NetworkRequestHelper', '요청 실패 (시도: $attempts회)', e);
          rethrow;
        }
        
        AppLogger.warning('NetworkRequestHelper', '요청 실패, 재시도 중... ($attempts/$retryCount)');
        await Future.delayed(retryDelay);
      }
    }
  }
  
  /// 네트워크 상태 확인 후 요청 실행 (간단 버전)
  static Future<T> safeExecute<T>(Future<T> Function() request) async {
    if (_networkService.isOffline) {
      throw const NetworkException(
        message: '인터넷 연결이 없습니다.',
        code: 'no_connection',
      );
    }
    return request();
  }
}

/// ============================================================
/// Riverpod Providers
/// ============================================================

/// 네트워크 서비스 Provider
final networkServiceProvider = Provider<NetworkService>((ref) {
  final service = NetworkService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// 네트워크 상태 StreamProvider
final networkStatusProvider = StreamProvider<NetworkStatus>((ref) {
  final service = ref.watch(networkServiceProvider);
  return service.statusStream;
});

/// 현재 온라인 상태 Provider
final isOnlineProvider = Provider<bool>((ref) {
  final statusAsync = ref.watch(networkStatusProvider);
  return statusAsync.whenOrNull(data: (status) => status == NetworkStatus.online) ?? 
         NetworkService().isOnline;
});
