/// ============================================================
/// API 설정 관리
/// 
/// 외부 API 키들을 중앙에서 관리
/// 프로덕션 환경에서는 --dart-define 또는 Firebase Remote Config 사용 권장
/// ============================================================

class ApiConfig {
  ApiConfig._();
  
  // ===== 카카오 API =====
  
  /// 카카오 REST API 키 (지오코딩, 장소 검색 등)
  static const String kakaoRestApiKey = String.fromEnvironment(
    'KAKAO_REST_API_KEY',
    defaultValue: '185d8f5a9d617aa3506964ffd352c8b4',
  );
  
  // ===== 공공데이터포털 API =====
  
  /// 동물등록 정보조회 API 키
  static const String animalRegistrationApiKey = String.fromEnvironment(
    'ANIMAL_REGISTRATION_API_KEY',
    defaultValue: 'a93698e1158aff136c971c3e54a7b5a657eb9f302ae5bc7501ea24c55bdd5575',
  );
  
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
