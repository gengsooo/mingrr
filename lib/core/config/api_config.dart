import 'package:firebase_remote_config/firebase_remote_config.dart';
import '../utils/app_logger.dart';

/// ============================================================
/// API 설정 관리 (Firebase Remote Config 방식)
/// 
/// Firebase Console에서 API 키를 관리하여 보안 강화
/// - 앱 재빌드 없이 키 변경 가능
/// - 관리 포인트 1곳 (Firebase Console)
/// 
/// Firebase Console 설정:
/// 1. Firebase Console > Remote Config 이동
/// 2. 다음 파라미터 추가:
///    - kakao_map_key: 카카오 지도 SDK 키
///    - kakao_rest_api_key: 카카오 REST API 키
///    - animal_registration_api_key: 동물등록 API 키
/// 3. 변경사항 게시
/// ============================================================

class ApiConfig {
  ApiConfig._();
  
  static final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;
  
  // ===== Fallback 값 (Remote Config 실패 시 사용) =====
  // 네이티브 설정(AndroidManifest, Info.plist)과 동일한 값
  // 클라이언트 SDK 키는 앱 번들에 이미 포함되므로 하드코딩해도 보안상 문제 없음
  static const String _fallbackKakaoMapKey = 'e80e09aa4db6c1f3d1eedb1be73ee8c6';
  
  // SDK 초기화 상태 추적
  static bool _isKakaoMapSdkInitialized = false;
  
  /// 카카오맵 SDK 초기화 여부
  static bool get isKakaoMapSdkInitialized => _isKakaoMapSdkInitialized;
  
  /// 카카오맵 SDK 초기화 상태 설정 (main.dart에서 호출)
  static void setKakaoMapSdkInitialized(bool value) {
    _isKakaoMapSdkInitialized = value;
    AppLogger.debug('ApiConfig', '카카오맵 SDK 초기화 상태: $value');
  }
  
  // ===== 초기화 =====
  
  /// Remote Config 초기화 (main.dart에서 호출)
  static Future<void> initialize() async {
    try {
      // 설정: 최소 fetch 간격 (개발: 0초, 운영: 1시간 권장)
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(hours: 1),
      ));
      
      // 기본값 설정 - Fallback 값 사용 (Remote Config 실패 시에도 작동)
      await _remoteConfig.setDefaults(const {
        'kakao_map_key': _fallbackKakaoMapKey,
        'kakao_rest_api_key': '',
        'animal_registration_api_key': '',
      });
      
      // 서버에서 값 가져오기 및 활성화
      await _remoteConfig.fetchAndActivate();
      
      AppLogger.info('ApiConfig', 'Remote Config 초기화 완료');
      AppLogger.debug('ApiConfig', '카카오맵 키 설정됨: ${hasKakaoMapKey}');
      AppLogger.debug('ApiConfig', '카카오맵 키 값: ${kakaoMapKey.substring(0, 8)}...');
      AppLogger.debug('ApiConfig', '카카오 REST API 키 설정됨: ${hasKakaoRestApiKey}');
      AppLogger.debug('ApiConfig', '동물등록 API 키 설정됨: ${hasAnimalRegistrationApiKey}');
    } catch (e) {
      AppLogger.error('ApiConfig', 'Remote Config 초기화 실패', e);
      // 실패해도 fallback 값이 기본값으로 설정되어 있으므로 작동함
    }
  }
  
  // ===== 카카오 API =====
  
  /// 카카오 지도 SDK 키 (네이티브 맵)
  static String get kakaoMapKey => _remoteConfig.getString('kakao_map_key');
  
  /// 카카오 REST API 키 (지오코딩, 장소 검색 등)
  static String get kakaoRestApiKey => _remoteConfig.getString('kakao_rest_api_key');
  
  // ===== 공공데이터포털 API =====
  
  /// 동물등록 정보조회 API 키
  static String get animalRegistrationApiKey => _remoteConfig.getString('animal_registration_api_key');
  
  // ===== API 키 유효성 검사 =====
  
  /// 카카오 지도 키가 설정되었는지 확인
  static bool get hasKakaoMapKey => kakaoMapKey.isNotEmpty;
  
  /// 카카오 REST API 키가 설정되었는지 확인
  static bool get hasKakaoRestApiKey => kakaoRestApiKey.isNotEmpty;
  
  /// 동물등록 API 키가 설정되었는지 확인
  static bool get hasAnimalRegistrationApiKey => animalRegistrationApiKey.isNotEmpty;
  
  /// 동물등록 API Base URL
  static const String animalRegistrationBaseUrl = 
      'https://apis.data.go.kr/1543061/animalInfoSrvc_v3';
  
  // ===== API 타임아웃 설정 =====
  
  /// 기본 API 타임아웃 (초)
  static const int defaultTimeoutSeconds = 10;
  
  /// 지오코딩 API 타임아웃 (초)
  static const int geocodingTimeoutSeconds = 5;
  
  /// 동물등록 API 타임아웃 (초)
  static const int animalRegistrationTimeoutSeconds = 15;
}
