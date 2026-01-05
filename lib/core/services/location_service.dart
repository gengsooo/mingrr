import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/pet_constants.dart';

/// ============================================================
/// 위치 서비스
/// 
/// 기능:
/// - 집주소 기반 거리 계산
/// - 200m 안전구역 체크 (산책 기능 비활성화)
/// - 마켓 거리 필터 (1.5km 기본)
/// - 소모임 거리 필터
/// - 주소에서 동 단위 추출
/// ============================================================
class LocationService {
  LocationService._();
  
  /// 두 좌표 간 거리 계산 (Haversine 공식, 미터 단위)
  /// 
  /// [lat1], [lon1]: 첫 번째 좌표 (위도, 경도)
  /// [lat2], [lon2]: 두 번째 좌표 (위도, 경도)
  /// 반환값: 거리 (미터)
  static double calculateDistance(
    double lat1, double lon1,
    double lat2, double lon2,
  ) {
    const double earthRadius = 6371000; // 지구 반지름 (미터)
    
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);
    
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }
  
  /// GeoPoint 간 거리 계산
  static double calculateDistanceFromGeoPoints(GeoPoint point1, GeoPoint point2) {
    return calculateDistance(
      point1.latitude, point1.longitude,
      point2.latitude, point2.longitude,
    );
  }
  
  /// 도(degree)를 라디안(radian)으로 변환
  static double _toRadians(double degree) {
    return degree * math.pi / 180;
  }
  
  /// 집 반경 안전구역 내에 있는지 확인 (200m)
  /// 
  /// [currentLocation]: 현재 위치
  /// [homeLocation]: 집 위치
  /// 반환값: 안전구역 내에 있으면 true
  static bool isInHomeSafetyZone(GeoPoint currentLocation, GeoPoint homeLocation) {
    final distance = calculateDistanceFromGeoPoints(currentLocation, homeLocation);
    return distance <= LocationConstants.homeSafetyRadiusMeters;
  }
  
  /// 산책 기능 활성화 가능 여부 확인
  /// 
  /// 집 반경 200m 밖에서만 산책 기능 활성화 (안전구역 기능이 켜져 있는 경우)
  /// 
  /// [currentLocation]: 현재 위치
  /// [homeLocation]: 집 위치
  /// [homeSafetyEnabled]: 안전구역 기능 활성화 여부 (기본값: true)
  ///   - true: 집 반경 200m 내에서 산책 불가
  ///   - false: 안전구역 기능 사용 안 함 (어디서든 산책 가능)
  /// 반환값: 산책 가능하면 true
  static bool canStartWalk(
    GeoPoint? currentLocation,
    GeoPoint? homeLocation, {
    bool homeSafetyEnabled = true,
  }) {
    // 위치 정보가 없으면 산책 불가
    if (currentLocation == null || homeLocation == null) {
      return false;
    }
    
    // 안전구역 기능이 꺼져 있으면 항상 산책 가능
    if (!homeSafetyEnabled) {
      return true;
    }
    
    // 안전구역 밖에서만 산책 가능
    return !isInHomeSafetyZone(currentLocation, homeLocation);
  }
  
  /// 마켓 거리 필터 범위 내에 있는지 확인
  /// 
  /// [itemLocation]: 상품 위치
  /// [userHomeLocation]: 사용자 집 위치
  /// [radiusKm]: 필터 반경 (km), 기본값 1.5km
  /// 반환값: 범위 내에 있으면 true
  static bool isWithinMarketRadius(
    GeoPoint itemLocation,
    GeoPoint userHomeLocation, {
    double radiusKm = LocationConstants.marketDefaultRadiusKm,
  }) {
    final distance = calculateDistanceFromGeoPoints(itemLocation, userHomeLocation);
    return distance <= radiusKm * 1000; // km를 m로 변환
  }
  
  /// 소모임 거리 필터 범위 내에 있는지 확인
  /// 
  /// [communityLocation]: 소모임 위치
  /// [userHomeLocation]: 사용자 집 위치
  /// [radiusKm]: 필터 반경 (km), 기본값 5km
  /// 반환값: 범위 내에 있으면 true
  static bool isWithinCommunityRadius(
    GeoPoint communityLocation,
    GeoPoint userHomeLocation, {
    double radiusKm = LocationConstants.communityDefaultRadiusKm,
  }) {
    final distance = calculateDistanceFromGeoPoints(communityLocation, userHomeLocation);
    return distance <= radiusKm * 1000;
  }
  
  /// 거리를 사람이 읽기 쉬운 형태로 변환
  /// 
  /// [distanceMeters]: 거리 (미터)
  /// 반환값: "300m" 또는 "1.5km" 형태의 문자열
  static String formatDistance(double distanceMeters) {
    // 거리 정보가 없거나 무한대인 경우
    if (distanceMeters == 0 || distanceMeters.isInfinite || distanceMeters.isNaN) {
      return '거리 정보 없음';
    }
    if (distanceMeters < 1000) {
      return '${distanceMeters.round()}m';
    } else {
      return '${(distanceMeters / 1000).toStringAsFixed(1)}km';
    }
  }
  
  /// 주소에서 동(洞) 단위 추출
  /// 
  /// 예: "서울특별시 강남구 역삼동 123-45" → "강남구 역삼동"
  /// 예: "경기도 용인시 처인구 역북동 67-89" → "처인구 역북동"
  /// 
  /// [fullAddress]: 전체 주소
  /// 반환값: "OO구 OO동" 형태의 문자열
  static String extractDistrict(String fullAddress) {
    // 주소를 공백으로 분리
    final parts = fullAddress.split(' ');
    
    String? gu; // 구
    String? dong; // 동
    
    for (final part in parts) {
      // 구 찾기 (강남구, 처인구 등)
      if (part.endsWith('구')) {
        gu = part;
      }
      // 동 찾기 (역삼동, 역북동 등)
      else if (part.endsWith('동') && !part.contains('아파트')) {
        dong = part;
      }
    }
    
    // 구와 동이 모두 있으면 조합
    if (gu != null && dong != null) {
      return '$gu $dong';
    }
    // 동만 있으면 동만 반환
    else if (dong != null) {
      return dong;
    }
    // 구만 있으면 구만 반환
    else if (gu != null) {
      return gu;
    }
    
    // 찾지 못하면 원본 주소의 일부 반환
    if (parts.length >= 3) {
      return '${parts[1]} ${parts[2]}';
    }
    
    return fullAddress;
  }
  
  /// 두 위치 간 거리를 포맷팅된 문자열로 반환
  /// 
  /// [from]: 시작 위치
  /// [to]: 도착 위치
  /// 반환값: "1.5km" 형태의 문자열
  static String getFormattedDistanceBetween(GeoPoint from, GeoPoint to) {
    final distance = calculateDistanceFromGeoPoints(from, to);
    return formatDistance(distance);
  }
}

/// ============================================================
/// 산책 추적 서비스
/// 
/// 기능:
/// - 산책 경로 기록
/// - 거리 계산
/// - 다중 반려동물 산책 지원
/// ============================================================
class WalkTrackingService {
  WalkTrackingService._();
  
  /// 경로 포인트들로부터 총 거리 계산
  /// 
  /// [routePoints]: 경로 좌표 목록
  /// 반환값: 총 거리 (미터)
  static double calculateTotalDistance(List<GeoPoint> routePoints) {
    if (routePoints.length < 2) return 0;
    
    double totalDistance = 0;
    
    for (int i = 0; i < routePoints.length - 1; i++) {
      totalDistance += LocationService.calculateDistanceFromGeoPoints(
        routePoints[i],
        routePoints[i + 1],
      );
    }
    
    return totalDistance;
  }
  
  /// 예상 칼로리 계산 (간단한 공식)
  /// 
  /// [distanceMeters]: 거리 (미터)
  /// [durationMinutes]: 시간 (분)
  /// [petWeightKg]: 반려동물 체중 (kg)
  /// 반환값: 예상 소모 칼로리
  static double estimateCalories(
    double distanceMeters,
    int durationMinutes,
    double petWeightKg,
  ) {
    // 간단한 칼로리 계산 공식
    // 기본: 체중(kg) * 거리(km) * 0.8
    final distanceKm = distanceMeters / 1000;
    return petWeightKg * distanceKm * 0.8;
  }
  
  /// 산책 속도 계산 (km/h)
  /// 
  /// [distanceMeters]: 거리 (미터)
  /// [durationMinutes]: 시간 (분)
  /// 반환값: 속도 (km/h)
  static double calculateSpeed(double distanceMeters, int durationMinutes) {
    if (durationMinutes <= 0) return 0;
    
    final distanceKm = distanceMeters / 1000;
    final durationHours = durationMinutes / 60;
    
    return distanceKm / durationHours;
  }
}
