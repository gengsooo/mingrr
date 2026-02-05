import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../constants/location_constants.dart';
import '../services/firebase_service.dart';
import '../services/location_service.dart';
import '../services/location_helper.dart';
import '../services/geocoding_service.dart';
import '../utils/app_logger.dart';
import '../widgets/common_widgets.dart';
import '../../models/user_model.dart';
import '../utils/error_handler.dart';

/// ============================================================
/// 위치 인증 시스템 Provider
/// 
/// 기능:
/// - 위치 불일치 감지 (저장된 위치 vs 현재 위치)
/// - 말풍선 알림 표시 여부 결정
/// - 위치 인증 가능 여부 확인
/// - 알림 무시 처리
/// - 앱 시작 시 위치 체크
/// - 위치 인증 만료 (90일)
/// ============================================================

final _firebase = FirebaseService();

/// 위치 불일치 상태
enum LocationMismatchStatus {
  /// 체크 중
  checking,
  /// 일치 (알림 불필요)
  matched,
  /// 불일치 (알림 필요)
  mismatched,
  /// 위치 정보 없음
  noLocation,
  /// 알림 무시됨 (24시간 쿨다운)
  dismissed,
  /// 인증 만료됨 (90일)
  expired,
  /// 오류
  error,
}

/// 위치 인증 가능 상태
enum VerificationEligibility {
  /// 인증 가능 (500m 이내)
  eligible,
  /// 조금 더 가까이 (500m~1km)
  tooFar,
  /// 범위 밖 (1km 이상)
  outOfRange,
  /// 첫 인증 (저장된 위치 없음)
  firstTime,
  /// 오류
  error,
}

/// 위치 불일치 결과
class LocationMismatchResult {
  final LocationMismatchStatus status;
  final double? distanceMeters;
  final String? savedAddress;
  final String? currentAddress;
  final String? message;

  const LocationMismatchResult({
    required this.status,
    this.distanceMeters,
    this.savedAddress,
    this.currentAddress,
    this.message,
  });

  /// 알림을 표시해야 하는지 여부
  bool get shouldShowBubble => 
      status == LocationMismatchStatus.mismatched ||
      status == LocationMismatchStatus.expired;
  
  /// 인증 만료 여부
  bool get isExpired => status == LocationMismatchStatus.expired;

  /// 거리 문자열
  String get distanceString {
    if (distanceMeters == null) return '';
    return LocationService.formatDistance(distanceMeters!);
  }
}

/// 위치 인증 가능 결과
class VerificationEligibilityResult {
  final VerificationEligibility status;
  final double? distanceMeters;
  final String? message;

  const VerificationEligibilityResult({
    required this.status,
    this.distanceMeters,
    this.message,
  });

  /// 인증 가능 여부
  bool get canVerify => 
      status == VerificationEligibility.eligible || 
      status == VerificationEligibility.firstTime;
}

/// 현재 사용자 정보 Provider (Stream)
final currentUserStreamProvider = StreamProvider.autoDispose<UserModel?>((ref) {
  final userId = _firebase.currentUserId;
  if (userId == null) return Stream.value(null);
  
  return _firebase.usersCollection.doc(userId).snapshots().map((doc) {
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc.data()!, id: doc.id);
  });
});

/// 현재 GPS 위치 Provider (캐시됨)
final _currentGpsPositionProvider = FutureProvider.autoDispose<Position?>((ref) async {
  final result = await LocationHelper.getCurrentLocation(
    purpose: LocationPurpose.map,
  );
  return result.isSuccess ? result.position : null;
});

/// 위치 불일치 감지 Provider (인증 만료 포함)
final locationMismatchProvider = FutureProvider.autoDispose<LocationMismatchResult>((ref) async {
  final userAsync = ref.watch(currentUserStreamProvider);
  final user = userAsync.valueOrNull;
  
  // 사용자 정보 없음
  if (user == null) {
    return const LocationMismatchResult(
      status: LocationMismatchStatus.noLocation,
      message: '사용자 정보를 불러올 수 없습니다',
    );
  }
  
  // 위치 인증이 안 된 경우 → 불일치 체크 불필요
  if (!user.isLocationVerified || user.homeLocation == null) {
    return const LocationMismatchResult(
      status: LocationMismatchStatus.noLocation,
      message: '위치 인증이 필요합니다',
    );
  }
  
  // 위치 인증 만료 체크 (90일)
  if (user.locationVerifiedAt != null) {
    final elapsed = DateTime.now().difference(user.locationVerifiedAt!);
    if (elapsed.inDays >= LocationConstants.verificationExpirationDays) {
      return LocationMismatchResult(
        status: LocationMismatchStatus.expired,
        savedAddress: user.homeAddress ?? '저장된 위치',
        message: '위치 인증이 만료되었습니다. 다시 인증해주세요.',
      );
    }
  }
  
  // 알림 무시 후 24시간 이내인지 확인
  if (user.locationReminderDismissedAt != null) {
    final elapsed = DateTime.now().difference(user.locationReminderDismissedAt!);
    if (elapsed.inHours < LocationConstants.reminderCooldownHours) {
      return const LocationMismatchResult(
        status: LocationMismatchStatus.dismissed,
        message: '알림이 무시되었습니다',
      );
    }
  }
  
  // 현재 GPS 위치 가져오기
  final positionAsync = ref.watch(_currentGpsPositionProvider);
  final position = positionAsync.valueOrNull;
  
  if (position == null) {
    return const LocationMismatchResult(
      status: LocationMismatchStatus.error,
      message: '현재 위치를 가져올 수 없습니다',
    );
  }
  
  // 거리 계산
  final currentGeoPoint = GeoPoint(position.latitude, position.longitude);
  final distance = LocationService.calculateDistanceFromGeoPoints(
    user.homeLocation!,
    currentGeoPoint,
  );
  
  // 3km 이상 차이나면 불일치
  if (distance >= LocationConstants.mismatchThresholdMeters) {
    return LocationMismatchResult(
      status: LocationMismatchStatus.mismatched,
      distanceMeters: distance,
      savedAddress: user.homeAddress ?? '저장된 위치',
      message: '현재 위치가 저장된 동네와 ${LocationService.formatDistance(distance)} 떨어져 있어요',
    );
  }
  
  return LocationMismatchResult(
    status: LocationMismatchStatus.matched,
    distanceMeters: distance,
  );
});

/// 말풍선 표시 여부 Provider
final shouldShowLocationBubbleProvider = Provider.autoDispose<bool>((ref) {
  final mismatchAsync = ref.watch(locationMismatchProvider);
  return mismatchAsync.valueOrNull?.shouldShowBubble ?? false;
});

/// 위치 인증 가능 여부 확인 Provider
final verificationEligibilityProvider = FutureProvider.autoDispose<VerificationEligibilityResult>((ref) async {
  final userAsync = ref.watch(currentUserStreamProvider);
  final user = userAsync.valueOrNull;
  
  // 사용자 정보 없음
  if (user == null) {
    return const VerificationEligibilityResult(
      status: VerificationEligibility.error,
      message: '사용자 정보를 불러올 수 없습니다',
    );
  }
  
  // 저장된 위치가 없으면 → 첫 인증 (바로 가능)
  if (user.homeLocation == null) {
    return const VerificationEligibilityResult(
      status: VerificationEligibility.firstTime,
      message: '현재 위치를 동네로 등록합니다',
    );
  }
  
  // 현재 GPS 위치 가져오기
  final positionAsync = ref.watch(_currentGpsPositionProvider);
  final position = positionAsync.valueOrNull;
  
  if (position == null) {
    return const VerificationEligibilityResult(
      status: VerificationEligibility.error,
      message: '현재 위치를 가져올 수 없습니다',
    );
  }
  
  // 거리 계산
  final currentGeoPoint = GeoPoint(position.latitude, position.longitude);
  final distance = LocationService.calculateDistanceFromGeoPoints(
    user.homeLocation!,
    currentGeoPoint,
  );
  
  // 500m 이내 → 인증 가능
  if (distance <= LocationConstants.verificationRadiusMeters) {
    return VerificationEligibilityResult(
      status: VerificationEligibility.eligible,
      distanceMeters: distance,
      message: '위치 인증이 가능합니다',
    );
  }
  
  // 500m~1km → 조금 더 가까이
  if (distance <= LocationConstants.verificationNearbyMeters) {
    return VerificationEligibilityResult(
      status: VerificationEligibility.tooFar,
      distanceMeters: distance,
      message: '설정한 동네에서 ${distance.round()}m 떨어져 있어요.\n조금 더 가까이 이동해주세요.',
    );
  }
  
  // 1km 이상 → 범위 밖
  return VerificationEligibilityResult(
    status: VerificationEligibility.outOfRange,
    distanceMeters: distance,
    message: '설정한 동네 근처에서 인증해주세요.\n현재 ${LocationService.formatDistance(distance)} 떨어져 있어요.',
  );
});

/// 위치 인증 서비스 클래스
class LocationVerificationService {
  LocationVerificationService._();
  
  /// 위치 인증 처리 (개선된 버전)
  /// 
  /// [userId]: 사용자 ID
  /// [currentPosition]: 현재 GPS 위치
  /// [address]: 주소 문자열
  /// [isFirstTime]: 첫 인증 여부 (저장된 위치 없음)
  static Future<void> verifyLocation({
    required String userId,
    required Position currentPosition,
    required String address,
    bool isFirstTime = false,
  }) async {
    final geoPoint = GeoPoint(currentPosition.latitude, currentPosition.longitude);
    
    await _firebase.usersCollection.doc(userId).update({
      // 인증 배지 연동 (verifications.location)
      'verifications.location': true,
      'verifications.locationAt': FieldValue.serverTimestamp(),
      'verifications.locationAddress': address,
      'verifications.locationGeoPoint': geoPoint,
      // 위치 인증 상태 (UserModel 필드)
      'isLocationVerified': true,
      'locationVerifiedAt': FieldValue.serverTimestamp(),
      'homeLocation': geoPoint,
      'homeAddress': address,
      'locationMismatchCount': 0, // 인증 시 불일치 횟수 초기화
      'lastLocationCheckAt': FieldValue.serverTimestamp(),
      'locationReminderDismissedAt': null, // 알림 무시 초기화
    });
  }
  
  /// 위치 변경 (불일치 시 현재 위치로 업데이트)
  static Future<void> updateLocation({
    required String userId,
    required Position currentPosition,
    required String address,
  }) async {
    final geoPoint = GeoPoint(currentPosition.latitude, currentPosition.longitude);
    
    await _firebase.usersCollection.doc(userId).update({
      // 인증 배지 연동 (verifications.location) - 위치 변경 시에도 업데이트
      'verifications.locationAddress': address,
      'verifications.locationGeoPoint': geoPoint,
      // 위치 정보 업데이트
      'homeLocation': geoPoint,
      'homeAddress': address,
      'locationMismatchCount': 0,
      'lastLocationCheckAt': FieldValue.serverTimestamp(),
      'locationReminderDismissedAt': null, // 알림 무시 초기화
    });
  }
  
  /// 알림 무시 처리
  static Future<void> dismissReminder(String userId) async {
    await _firebase.usersCollection.doc(userId).update({
      'locationReminderDismissedAt': FieldValue.serverTimestamp(),
    });
  }
  
  /// 위치 체크 시간 업데이트
  static Future<void> updateLastCheckTime(String userId) async {
    await _firebase.usersCollection.doc(userId).update({
      'lastLocationCheckAt': FieldValue.serverTimestamp(),
    });
  }
  
  /// 불일치 횟수 증가
  static Future<void> incrementMismatchCount(String userId) async {
    await _firebase.usersCollection.doc(userId).update({
      'locationMismatchCount': FieldValue.increment(1),
    });
  }
  
  /// 위치 인증 만료 여부 확인
  static bool isVerificationExpired(DateTime? verifiedAt) {
    if (verifiedAt == null) return true;
    final elapsed = DateTime.now().difference(verifiedAt);
    return elapsed.inDays >= LocationConstants.verificationExpirationDays;
  }
  
  /// 위치 인증 남은 일수
  static int getRemainingDays(DateTime? verifiedAt) {
    if (verifiedAt == null) return 0;
    final elapsed = DateTime.now().difference(verifiedAt);
    final remaining = LocationConstants.verificationExpirationDays - elapsed.inDays;
    return remaining > 0 ? remaining : 0;
  }
  
  /// 위치 인증 만료 처리 (인증 상태 초기화)
  static Future<void> expireVerification(String userId) async {
    await _firebase.usersCollection.doc(userId).update({
      'verifications.location': false,
      'isLocationVerified': false,
    });
  }
  
  // ===== 공통 UI 함수 =====
  
  /// 위치 획득 헬퍼 함수 (타임아웃 포함)
  static Future<Position?> _getPositionWithTimeout() async {
    try {
      // 마지막 알려진 위치 먼저 시도 (즉시 반환)
      final lastPosition = await Geolocator.getLastKnownPosition();
      if (lastPosition != null) {
        AppLogger.debug('LocationVerification', '마지막 위치 사용: ${lastPosition.latitude}, ${lastPosition.longitude}');
        return lastPosition;
      }
    } catch (e) {
      AppLogger.warning('LocationVerification', '마지막 위치 획득 실패: $e');
    }
    
    // 현재 위치 획득 시도
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
      ),
    );
  }

  /// 위치 업데이트 처리 (공통 함수)
  /// 
  /// 프로필 화면, 홈 화면 등에서 공통으로 사용
  /// 타임아웃, 권한 체크, 개선된 로딩 UI 포함
  static Future<void> handleLocationUpdateWithUI({
    required BuildContext context,
    required String userId,
    VoidCallback? onSuccess,
  }) async {
    // 공통 로딩 다이얼로그 사용
    showMingrrLoading(
      context,
      title: '현재 위치 확인 중',
      subtitle: 'GPS 신호를 찾고 있습니다...',
    );
    
    try {
      // 1. 위치 서비스 활성화 확인 (2초 타임아웃)
      final serviceEnabled = await Geolocator.isLocationServiceEnabled()
          .timeout(const Duration(seconds: 2), onTimeout: () => false);
      if (!serviceEnabled) {
        if (context.mounted) Navigator.pop(context);
        if (context.mounted) {
          MingrrSnackBar.warning(context, '위치 서비스를 켜주세요');
        }
        return;
      }
      
      // 2. 위치 권한 확인 (2초 타임아웃)
      LocationPermission permission = await Geolocator.checkPermission()
          .timeout(const Duration(seconds: 2), onTimeout: () => LocationPermission.denied);
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission()
            .timeout(const Duration(seconds: 10), onTimeout: () => LocationPermission.denied);
        if (permission == LocationPermission.denied) {
          if (context.mounted) Navigator.pop(context);
          if (context.mounted) {
            MingrrSnackBar.warning(context, '위치 권한이 필요합니다');
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (context.mounted) Navigator.pop(context);
        if (context.mounted) {
          MingrrSnackBar.warning(context, '설정에서 위치 권한을 허용해주세요');
        }
        return;
      }
      
      // 3. 현재 위치 가져오기 (전체 8초 타임아웃)
      Position? position;
      try {
        position = await _getPositionWithTimeout()
            .timeout(const Duration(seconds: 8));
        AppLogger.info('LocationVerification', '위치 획득 성공: ${position?.latitude}, ${position?.longitude}');
      } catch (e) {
        AppLogger.warning('LocationVerification', '위치 획득 실패: $e');
        if (context.mounted) Navigator.pop(context);
        if (context.mounted) {
          MingrrSnackBar.warning(context, 'GPS 신호를 찾을 수 없습니다.');
        }
        return;
      }
      
      // 위치 획득 실패 체크
      if (position == null) {
        if (context.mounted) Navigator.pop(context);
        if (context.mounted) {
          MingrrSnackBar.warning(context, '위치를 확인할 수 없습니다');
        }
        return;
      }
      
      // 4. 주소 변환 (타임아웃 3초)
      String address = '위도: ${position.latitude.toStringAsFixed(4)}, 경도: ${position.longitude.toStringAsFixed(4)}';
      try {
        final addressResult = await GeocodingService.reverseGeocode(
          position.latitude,
          position.longitude,
        ).timeout(const Duration(seconds: 3));
        if (addressResult != null) {
          address = addressResult.shortAddress;
        }
      } catch (_) {}
      
      if (context.mounted) Navigator.pop(context); // 로딩 다이얼로그 닫기
      
      // 5. 위치 업데이트
      await updateLocation(
        userId: userId,
        currentPosition: position,
        address: address,
      );
      
      if (context.mounted) {
        MingrrSnackBar.success(context, '위치가 업데이트되었습니다! 📍');
        onSuccess?.call();
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) {
        ErrorHandler.showError(context, e, tag: 'Location', operation: '위치 업데이트');
      }
    }
  }
}

/// ============================================================
/// 앱 시작 시 위치 체크 서비스
/// 
/// 앱이 시작될 때 백그라운드에서 위치를 체크하고
/// 불일치 또는 만료 시 알림을 표시합니다.
/// ============================================================
class AppStartLocationChecker {
  AppStartLocationChecker._();
  
  static bool _hasCheckedOnAppStart = false;
  static ProviderContainer? _container;
  
  /// 앱 시작 시 위치 체크 (한 번만 실행)
  /// 
  /// WidgetRef 대신 ProviderContainer를 사용하여 위젯 생명주기와 분리
  static Future<void> checkOnAppStart(WidgetRef ref) async {
    if (_hasCheckedOnAppStart) return;
    _hasCheckedOnAppStart = true;
    
    // ProviderContainer 저장 (나중에 사용)
    // 주의: WidgetRef는 위젯이 dispose되면 사용 불가
    // 따라서 비동기 작업 전에 필요한 데이터를 미리 읽어옴
    
    try {
      // 약간의 딜레이 후 체크 (앱 초기화 완료 대기)
      await Future.delayed(const Duration(seconds: 3));
      
      // ref가 아직 유효한지 확인 후 invalidate
      // 위젯이 dispose된 경우 예외 발생하므로 try-catch로 처리
      try {
        ref.invalidate(locationMismatchProvider);
      } catch (e) {
        // ref가 dispose된 경우 무시 (정상적인 상황)
        AppLogger.debug('LocationVerification', '위치 체크 Provider invalidate 스킵 (위젯 dispose됨)');
      }
    } catch (e) {
      AppLogger.warning('LocationVerification', '앱 시작 시 위치 체크 실패: $e');
    }
  }
  
  /// 앱 재시작 시 체크 상태 초기화
  static void reset() {
    _hasCheckedOnAppStart = false;
    _container = null;
  }
}
