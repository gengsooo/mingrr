import 'package:flutter/material.dart';
import 'app_icons.dart';

/// ============================================================
/// 위치 관련 상수
/// 
/// 거리 필터, 위치 인증, 안전 구역 등 위치 관련 상수 정의
/// ============================================================
class LocationConstants {
  LocationConstants._();
  
  /// 집 반경 안전구역 (200m) - 산책 기능 비활성화
  static const double homeSafetyRadiusMeters = 200.0;
  
  /// 기본 거리 필터 (5km)
  static const double defaultRadiusKm = 5.0;
  
  /// 위치 인증 반경 (당근마켓 스타일)
  static const double locationVerificationRadiusKm = 6.0;
  
  // ===== 거리 필터 옵션 =====
  
  /// 데이팅 거리 필터 옵션 (2, 5, 10, 20, 30km)
  static const List<double> datingDistanceOptions = [2, 5, 10, 20, 30];
  
  /// 마켓 거리 필터 옵션 (2, 5, 10, 20km, 전체)
  /// 0 = 전체 (거리 제한 없음)
  static const List<double> marketDistanceOptions = [2, 5, 10, 20, 0];
  
  /// 소모임 거리 필터 옵션 (2, 5, 10, 20, 30km)
  static const List<double> groupDistanceOptions = [2, 5, 10, 20, 30];
  
  // ===== 위치 인증 시스템 상수 =====
  
  /// 위치 불일치 알림 기준 (3km)
  /// - 저장된 위치와 현재 위치가 이 거리 이상 차이나면 알림 표시
  static const double mismatchThresholdMeters = 3000.0;
  
  /// 위치 인증 허용 거리 (500m)
  /// - 저장된 위치에서 이 거리 이내에서만 재인증 가능
  static const double verificationRadiusMeters = 500.0;
  
  /// 위치 인증 "조금 더 가까이" 안내 거리 (1km)
  /// - 500m~1km 사이면 "조금 더 가까이 이동해주세요" 안내
  static const double verificationNearbyMeters = 1000.0;
  
  /// 재알림 방지 시간 (24시간)
  /// - "무시" 클릭 후 이 시간 동안 알림 표시 안 함
  static const int reminderCooldownHours = 24;
  
  /// 위치 체크 캐시 유효 시간 (5분)
  /// - 앱 시작 시 위치 체크 결과 캐싱
  static const int locationCheckCacheMinutes = 5;
  
  /// 위치 인증 만료 기간 (90일)
  /// - 인증 후 이 기간이 지나면 재인증 필요
  static const int verificationExpirationDays = 90;
  
  // ===== 거리 표시 관련 상수 =====
  
  /// 위치 정보 없음 기본 텍스트
  static const String noLocationText = '위치 정보 없음';
  
  /// 거리 표시 아이콘
  static const IconData distanceIcon = AppIcons.locationOutlined;
}

/// ============================================================
/// 위치 인증 필요 화면 타입
/// 
/// 위치 인증이 필요한 기능에서 빈 화면 메시지 정의
/// 사용처: LocationRequiredEmptyState 컴포넌트
/// ============================================================
enum LocationRequiredType {
  dating(
    title: '주변 친구를 찾으려면\n위치 인증이 필요해요',
    description: '위치 인증 후 내 주변의\n반려동물 친구를 만나보세요!',
    hint: '위치 정보는 주변 검색에만 사용됩니다',
  ),
  market(
    title: '주변 상품을 보려면\n위치 인증이 필요해요',
    description: '위치 인증 후 내 주변의\n상품을 거래해보세요!',
    hint: '위치 정보는 주변 검색에만 사용됩니다',
  ),
  group(
    title: '주변 모임을 찾으려면\n위치 인증이 필요해요',
    description: '위치 인증 후 내 주변의\n소모임에 참여해보세요!',
    hint: '위치 정보는 주변 검색에만 사용됩니다',
  );

  final String title;
  final String description;
  final String hint;

  const LocationRequiredType({
    required this.title,
    required this.description,
    required this.hint,
  });
}
