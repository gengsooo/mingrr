import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../models/location_model.dart';
import '../utils/app_logger.dart';

/// 진행 상태 콜백 타입
typedef LocationProgressCallback = void Function(LocationProgress progress);

/// ============================================================
/// 위치 서비스 헬퍼 (공통 유틸리티)
/// 
/// 기능:
/// - 현재 위치 가져오기 (3단계 전략: 캐시 → medium → low)
/// - 용도별 캐시 유효 시간 (지도: 5분, 산책: 1분)
/// - 백그라운드 high 정확도 업데이트
/// - 위치 권한 확인 및 요청
/// ============================================================
class LocationHelper {
  LocationHelper._();
  
  /// 위치 가져오기 타임아웃 (초)
  static const int _mediumTimeoutSeconds = 5;
  static const int _lowTimeoutSeconds = 2;
  
  /// 캐시 유효 시간 (지도 초기화용: 5분)
  static const int _mapCacheMinutes = 5;
  
  /// 캐시 유효 시간 (산책 시작용: 1분)
  static const int _walkCacheMinutes = 1;
  
  /// 위치 업데이트 최소 오차 (미터) - 이 이상 차이나면 지도 이동
  static const double updateThresholdMeters = 50.0;
  
  /// 호출 횟수 추적 (디버깅용)
  static int _callCount = 0;
  
  /// 현재 위치 가져오기 (3단계 전략)
  /// 
  /// [purpose]: 용도 (map: 지도 초기화, walk: 산책 시작)
  /// [onProgress]: 진행 상태 콜백 (UI 업데이트용)
  /// 
  /// 1단계: 캐시된 위치 확인 (용도별 유효 시간)
  /// 2단계: medium 정확도로 GPS 요청 (5초)
  /// 3단계: low 정확도로 GPS 요청 (2초)
  static Future<LocationResult> getCurrentLocation({
    LocationPurpose purpose = LocationPurpose.map,
    LocationProgressCallback? onProgress,
  }) async {
    _callCount++;
    final callId = _callCount;
    final startTime = DateTime.now();
    final cacheMinutes = purpose == LocationPurpose.walk ? _walkCacheMinutes : _mapCacheMinutes;
    
    AppLogger.debug('Location', '========================================');
    AppLogger.debug('Location', 'getCurrentLocation 시작 (호출 #$callId)');
    AppLogger.debug('Location', '용도: $purpose, 캐시 유효시간: $cacheMinutes분');
    AppLogger.debug('Location', '시작 시간: $startTime');
    AppLogger.debug('Location', '========================================');
    
    // ============================================================
    // 🧪 [테스트용] 로딩 화면 테스트 - 주석 해제하여 사용
    // ============================================================
    // 
    // // 📌 테스트 1: 각 단계별 딜레이 추가 (로딩 애니메이션 확인용)
    // onProgress?.call(LocationProgress.checkingPermission);
    // await Future.delayed(const Duration(seconds: 2));
    // onProgress?.call(LocationProgress.checkingCache);
    // await Future.delayed(const Duration(seconds: 2));
    // onProgress?.call(LocationProgress.gettingGpsMedium);
    // await Future.delayed(const Duration(seconds: 3));
    // onProgress?.call(LocationProgress.gettingGpsLow);
    // await Future.delayed(const Duration(seconds: 2));
    // 
    // // 📌 테스트 2: 강제 실패 (오류 팝업 테스트용)
    // return LocationResult.failure(
    //   errorType: LocationErrorType.timeout,
    //   message: 'GPS 신호를 받을 수 없습니다 (테스트)',
    // );
    
    // ============================================================
    
    onProgress?.call(LocationProgress.checkingPermission);
    
    try {
      // 1. 위치 서비스 활성화 확인
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      AppLogger.debug('Location', ' [#$callId] 위치 서비스 활성화: $serviceEnabled');
      
      if (!serviceEnabled) {
        AppLogger.debug('Location', ' [#$callId] ❌ 위치 서비스 비활성화 - 종료');
        return LocationResult.failure(
          errorType: LocationErrorType.serviceDisabled,
          message: '위치 서비스가 비활성화되어 있습니다',
        );
      }
      
      // 2. 위치 권한 확인
      var permission = await Geolocator.checkPermission();
      AppLogger.debug('Location', ' [#$callId] 현재 권한 상태: $permission');
      
      if (permission == LocationPermission.denied) {
        AppLogger.debug('Location', ' [#$callId] 권한 요청 중...');
        permission = await Geolocator.requestPermission();
        AppLogger.debug('Location', ' [#$callId] 권한 요청 결과: $permission');
        
        if (permission == LocationPermission.denied) {
          AppLogger.debug('Location', ' [#$callId] ❌ 위치 권한 거부 - 종료');
          return LocationResult.failure(
            errorType: LocationErrorType.permissionDenied,
            message: '위치 권한이 거부되었습니다',
          );
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        AppLogger.debug('Location', ' [#$callId] ❌ 위치 권한 영구 거부 - 종료');
        return LocationResult.failure(
          errorType: LocationErrorType.permissionDeniedForever,
          message: '위치 권한이 영구적으로 거부되었습니다',
        );
      }
      
      // 3. [1단계] 캐시된 위치 확인
      onProgress?.call(LocationProgress.checkingCache);
      AppLogger.debug('Location', ' [#$callId] [1단계] 캐시된 위치 확인 중...');
      
      try {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          final age = DateTime.now().difference(lastKnown.timestamp);
          AppLogger.debug('Location', ' [#$callId] 캐시 위치: ${lastKnown.latitude}, ${lastKnown.longitude}');
          AppLogger.debug('Location', ' [#$callId] 캐시 시간: ${lastKnown.timestamp} (${age.inSeconds}초 전)');
          
          if (age.inMinutes <= cacheMinutes) {
            final totalElapsed = DateTime.now().difference(startTime);
            AppLogger.debug('Location', ' [#$callId] ✅ 캐시 위치 사용! (${age.inSeconds}초 전, 유효)');
            AppLogger.debug('Location', ' [#$callId] 전체 소요시간: ${totalElapsed.inMilliseconds}ms');
            AppLogger.debug('Location', ' ========================================');
            return LocationResult.success(
              position: lastKnown,
              source: LocationSource.cache,
            );
          } else {
            AppLogger.debug('Location', ' [#$callId] 캐시 만료 (${age.inMinutes}분 전) - GPS 요청 진행');
          }
        } else {
          AppLogger.debug('Location', ' [#$callId] 캐시된 위치 없음');
        }
      } catch (e) {
        AppLogger.debug('Location', ' [#$callId] 캐시 조회 실패: $e');
      }
      
      // 4. [2단계] medium 정확도로 GPS 요청
      onProgress?.call(LocationProgress.gettingGpsMedium);
      AppLogger.debug('Location', ' [#$callId] [2단계] medium 정확도 GPS 요청 (타임아웃: $_mediumTimeoutSeconds초)...');
      
      final mediumResult = await _requestPosition(
        callId: callId,
        accuracy: LocationAccuracy.medium,
        startTime: startTime,
      );
      
      if (mediumResult != null) {
        return LocationResult.success(
          position: mediumResult,
          source: LocationSource.gpsMedium,
        );
      }
      
      // 5. [3단계] low 정확도로 GPS 요청 (네트워크 기반)
      onProgress?.call(LocationProgress.gettingGpsLow);
      AppLogger.debug('Location', ' [#$callId] [3단계] low 정확도 GPS 요청 (타임아웃: $_lowTimeoutSeconds초)...');
      
      final lowResult = await _requestPosition(
        callId: callId,
        accuracy: LocationAccuracy.low,
        startTime: startTime,
      );
      
      if (lowResult != null) {
        return LocationResult.success(
          position: lowResult,
          source: LocationSource.gpsLow,
        );
      }
      
      // 6. 모든 단계 실패
      final totalElapsed = DateTime.now().difference(startTime);
      AppLogger.debug('Location', ' [#$callId] ❌ 모든 단계 실패!');
      AppLogger.debug('Location', ' [#$callId] 전체 소요시간: ${totalElapsed.inMilliseconds}ms');
      AppLogger.debug('Location', ' ========================================');
      
      return LocationResult.failure(
        errorType: LocationErrorType.timeout,
        message: 'GPS 신호를 받을 수 없습니다',
      );
    } catch (e) {
      AppLogger.debug('Location', ' [#$callId] ❌ 예외 발생: $e');
      AppLogger.debug('Location', ' ========================================');
      return LocationResult.failure(
        errorType: LocationErrorType.unknown,
        message: '위치 서비스 오류가 발생했습니다',
      );
    }
  }
  
  /// GPS 위치 요청 (내부 헬퍼)
  static Future<Position?> _requestPosition({
    required int callId,
    required LocationAccuracy accuracy,
    required DateTime startTime,
  }) async {
    final positionStartTime = DateTime.now();
    final timeoutSeconds = accuracy == LocationAccuracy.low 
        ? _lowTimeoutSeconds 
        : _mediumTimeoutSeconds;
    
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: accuracy,
          timeLimit: Duration(seconds: timeoutSeconds),
        ),
      );
      
      final positionElapsed = DateTime.now().difference(positionStartTime);
      final totalElapsed = DateTime.now().difference(startTime);
      
      AppLogger.debug('Location', ' [#$callId] ✅ $accuracy 위치 획득 성공!');
      AppLogger.debug('Location', ' [#$callId] 위치: ${position.latitude}, ${position.longitude}');
      AppLogger.debug('Location', ' [#$callId] 정확도: ${position.accuracy}m');
      AppLogger.debug('Location', ' [#$callId] 소요시간: ${positionElapsed.inMilliseconds}ms');
      AppLogger.debug('Location', ' [#$callId] 전체 소요시간: ${totalElapsed.inMilliseconds}ms');
      AppLogger.debug('Location', ' ========================================');
      
      return position;
    } catch (e) {
      final positionElapsed = DateTime.now().difference(positionStartTime);
      AppLogger.debug('Location', ' [#$callId] ❌ $accuracy 실패: $e (${positionElapsed.inMilliseconds}ms)');
      return null;
    }
  }
  
  /// 백그라운드에서 high 정확도 위치 가져오기
  /// 지도 표시 후 더 정확한 위치로 업데이트할 때 사용
  static Future<Position?> getHighAccuracyPosition() async {
    AppLogger.debug('Location', ' [LocationHelper] 백그라운드 high 정확도 위치 요청...');
    
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      
      AppLogger.debug('Location', ' [LocationHelper] ✅ high 정확도 위치: ${position.latitude}, ${position.longitude} (정확도: ${position.accuracy}m)');
      return position;
    } catch (e) {
      AppLogger.debug('Location', ' [LocationHelper] ❌ high 정확도 실패: $e');
      return null;
    }
  }
  
  /// 두 위치 간 거리 계산 (미터)
  static double calculateDistance(
    double lat1, double lon1,
    double lat2, double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }
  
  /// 위치 업데이트가 필요한지 확인 (오차 50m 이상)
  static bool shouldUpdatePosition(Position oldPos, Position newPos) {
    final distance = calculateDistance(
      oldPos.latitude, oldPos.longitude,
      newPos.latitude, newPos.longitude,
    );
    return distance >= updateThresholdMeters;
  }
  
  /// 위치 권한 상태 확인
  static Future<LocationPermissionStatus> checkPermissionStatus() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationPermissionStatus.serviceDisabled;
    }
    
    final permission = await Geolocator.checkPermission();
    switch (permission) {
      case LocationPermission.denied:
        return LocationPermissionStatus.denied;
      case LocationPermission.deniedForever:
        return LocationPermissionStatus.deniedForever;
      case LocationPermission.whileInUse:
      case LocationPermission.always:
        return LocationPermissionStatus.granted;
      default:
        return LocationPermissionStatus.denied;
    }
  }
  
  /// 위치 권한 요청
  static Future<bool> requestPermission() async {
    final permission = await Geolocator.requestPermission();
    return permission == LocationPermission.whileInUse || 
           permission == LocationPermission.always;
  }
  
  /// Position을 LocationData로 변환
  static LocationData positionToLocationData(Position position) {
    return LocationData.fromCoordinates(position.latitude, position.longitude);
  }
}

/// 위치 결과 클래스
class LocationResult {
  final Position? position;
  final bool isSuccess;
  final LocationErrorType? errorType;
  final String? message;
  final LocationSource? source;
  
  const LocationResult._({
    this.position,
    required this.isSuccess,
    this.errorType,
    this.message,
    this.source,
  });
  
  /// 성공 결과 생성
  factory LocationResult.success({
    required Position position,
    LocationSource source = LocationSource.gpsMedium,
  }) {
    return LocationResult._(
      position: position,
      isSuccess: true,
      source: source,
    );
  }
  
  /// 실패 결과 생성
  factory LocationResult.failure({
    required LocationErrorType errorType,
    required String message,
  }) {
    return LocationResult._(
      isSuccess: false,
      errorType: errorType,
      message: message,
    );
  }
  
  double get latitude => position?.latitude ?? 0;
  double get longitude => position?.longitude ?? 0;
}

/// 위치 획득 소스
enum LocationSource {
  cache,      // 캐시된 위치
  gpsMedium,  // GPS medium 정확도
  gpsLow,     // GPS low 정확도 (네트워크 기반)
  gpsHigh,    // GPS high 정확도
}

/// 위치 용도
enum LocationPurpose {
  map,   // 지도 초기화 (캐시 5분)
  walk,  // 산책 시작 (캐시 1분)
}

/// 위치 획득 진행 상태
enum LocationProgress {
  checkingPermission,  // 권한 확인 중
  checkingCache,       // 캐시 확인 중
  gettingGpsMedium,    // GPS 신호 찾는 중 (medium)
  gettingGpsLow,       // GPS 신호 찾는 중 (low)
}

/// 위치 오류 타입
enum LocationErrorType {
  serviceDisabled,       // 위치 서비스 비활성화
  permissionDenied,      // 위치 권한 거부
  permissionDeniedForever, // 위치 권한 영구 거부
  timeout,               // 타임아웃 (GPS 신호 없음)
  unknown,               // 알 수 없는 오류
}

/// 위치 권한 상태 enum
enum LocationPermissionStatus {
  granted,
  denied,
  deniedForever,
  serviceDisabled,
}
