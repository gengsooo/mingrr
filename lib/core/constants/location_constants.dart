import 'package:flutter/material.dart';

/// ============================================================
/// 위치 관련 상수
/// 
/// 거리 필터, 위치 인증, 안전 구역 등 위치 관련 상수 정의
/// ============================================================
class LocationConstants {
  LocationConstants._();
  
  /// 집 반경 안전구역 (200m) - 산책 기능 비활성화
  static const double homeSafetyRadiusMeters = 200.0;
  
  /// 마켓 기본 거리 필터 (1.5km)
  static const double marketDefaultRadiusKm = 1.5;
  
  /// 마켓 최대 거리 필터 (10km)
  static const double marketMaxRadiusKm = 10.0;
  
  /// 소모임 기본 거리 필터 (5km)
  static const double communityDefaultRadiusKm = 5.0;
  
  /// 위치 인증 반경 (당근마켓 스타일)
  static const double locationVerificationRadiusKm = 6.0;
  
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
  static const IconData distanceIcon = Icons.location_on_outlined;
}
