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
  
  // ===== 초기화 =====
  
  /// Remote Config 초기화 (main.dart에서 호출)
  static Future<void> initialize() async {
    try {
      // 설정: 최소 fetch 간격 (개발: 0초, 운영: 1시간 권장)
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(hours: 1),
      ));
      
      // 기본값 설정 (Remote Config에서 가져오기 전 사용)
      await _remoteConfig.setDefaults(const {
        'kakao_map_key': '',
        'kakao_rest_api_key': '',
        'animal_registration_api_key': '',
      });
      
      // 서버에서 값 가져오기 및 활성화
      await _remoteConfig.fetchAndActivate();
      
      AppLogger.info('ApiConfig', 'Remote Config 초기화 완료');
      AppLogger.debug('ApiConfig', '카카오맵 키 설정됨: ${hasKakaoMapKey}');
      AppLogger.debug('ApiConfig', '카카오 REST API 키 설정됨: ${hasKakaoRestApiKey}');
      AppLogger.debug('ApiConfig', '동물등록 API 키 설정됨: ${hasAnimalRegistrationApiKey}');
    } catch (e) {
      AppLogger.error('ApiConfig', 'Remote Config 초기화 실패', e);
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
