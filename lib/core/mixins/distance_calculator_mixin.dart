import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/location_constants.dart';
import '../providers/location_provider.dart';
import '../services/location_service.dart';

/// ============================================================
/// 거리 계산 Mixin
/// 
/// 상세화면에서 거리 계산 로직을 공통화하기 위한 Mixin
/// 
/// 사용처:
/// - ProductDetailScreen (상품 상세)
/// - JobDetailScreen (알바 상세)
/// - PetDetailScreen (펫 상세)
/// - GroupDetailScreen (소모임 상세)
/// ============================================================

/// ConsumerStatefulWidget용 거리 계산 Mixin
mixin DistanceCalculatorMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  /// 위치 정보로부터 거리 문자열 계산
  /// 
  /// [location]: 대상 위치 (GeoPoint)
  /// [fallbackAddress]: 위치 정보가 없을 때 표시할 주소
  /// 반환값: 거리 문자열 (예: "1.2km") 또는 fallback 주소
  String getDistanceFromLocation(GeoPoint? location, [String? fallbackAddress]) {
    if (location == null) {
      return fallbackAddress ?? LocationConstants.noLocationText;
    }
    
    final userLocation = ref.read(currentUserLocationProvider);
    if (userLocation == null) {
      return fallbackAddress ?? LocationConstants.noLocationText;
    }
    
    final distance = LocationService.calculateDistanceFromGeoPoints(
      userLocation,
      location,
    );
    return LocationService.formatDistance(distance);
  }
  
  /// 거리 미터 값 계산
  /// 
  /// [location]: 대상 위치 (GeoPoint)
  /// 반환값: 거리 (미터), 계산 불가 시 0
  double getDistanceMeters(GeoPoint? location) {
    if (location == null) return 0;
    
    final userLocation = ref.read(currentUserLocationProvider);
    if (userLocation == null) return 0;
    
    return LocationService.calculateDistanceFromGeoPoints(
      userLocation,
      location,
    );
  }
}

/// StatelessWidget에서 사용할 수 있는 거리 계산 유틸리티
class DistanceCalculator {
  DistanceCalculator._();
  
  /// 위치 정보로부터 거리 문자열 계산 (WidgetRef 필요)
  static String getDistanceString(
    WidgetRef ref,
    GeoPoint? location, [
    String? fallbackAddress,
  ]) {
    if (location == null) {
      return fallbackAddress ?? LocationConstants.noLocationText;
    }
    
    final userLocation = ref.read(currentUserLocationProvider);
    if (userLocation == null) {
      return fallbackAddress ?? LocationConstants.noLocationText;
    }
    
    final distance = LocationService.calculateDistanceFromGeoPoints(
      userLocation,
      location,
    );
    return LocationService.formatDistance(distance);
  }
  
  /// 거리 미터 값 계산 (WidgetRef 필요)
  static double getDistanceMeters(WidgetRef ref, GeoPoint? location) {
    if (location == null) return 0;
    
    final userLocation = ref.read(currentUserLocationProvider);
    if (userLocation == null) return 0;
    
    return LocationService.calculateDistanceFromGeoPoints(
      userLocation,
      location,
    );
  }
}
