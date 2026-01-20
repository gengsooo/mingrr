import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/location_service.dart';
import 'location_provider.dart';

/// ============================================================
/// 거리 계산 캐싱 Provider
/// 
/// 동일한 좌표 쌍에 대한 거리 계산 결과를 캐싱하여 성능 최적화
/// 
/// 사용 시나리오:
/// - 리스트 스크롤 시 동일 아이템 재계산 방지
/// - 화면 전환 후 복귀 시 재계산 방지
/// - 위치 변경 시 캐시 자동 무효화
/// ============================================================

/// 캐시 키 생성 (좌표 쌍 → 문자열)
String _createCacheKey(GeoPoint from, GeoPoint to) {
  // 소수점 4자리까지만 사용 (약 11m 정밀도)
  final fromLat = from.latitude.toStringAsFixed(4);
  final fromLon = from.longitude.toStringAsFixed(4);
  final toLat = to.latitude.toStringAsFixed(4);
  final toLon = to.longitude.toStringAsFixed(4);
  return '${fromLat}_${fromLon}_${toLat}_$toLon';
}

/// 거리 캐시 상태
class DistanceCacheState {
  final Map<String, double> _cache;
  final DateTime _createdAt;
  
  DistanceCacheState({
    Map<String, double>? cache,
    DateTime? createdAt,
  }) : _cache = cache ?? {},
       _createdAt = createdAt ?? DateTime.now();
  
  /// 캐시에서 거리 조회
  double? get(String key) => _cache[key];
  
  /// 캐시에 거리 저장
  DistanceCacheState put(String key, double distance) {
    final newCache = Map<String, double>.from(_cache);
    newCache[key] = distance;
    return DistanceCacheState(cache: newCache, createdAt: _createdAt);
  }
  
  /// 캐시 크기
  int get size => _cache.length;
  
  /// 캐시 생성 시간
  DateTime get createdAt => _createdAt;
  
  /// 캐시 초기화
  DistanceCacheState clear() => DistanceCacheState();
}

/// 거리 캐시 Notifier
class DistanceCacheNotifier extends StateNotifier<DistanceCacheState> {
  DistanceCacheNotifier() : super(DistanceCacheState());
  
  /// 캐시된 거리 조회 또는 계산
  double getDistance(GeoPoint from, GeoPoint to) {
    final key = _createCacheKey(from, to);
    final cached = state.get(key);
    
    if (cached != null) {
      return cached;
    }
    
    // 캐시 미스: 계산 후 저장
    final distance = LocationService.calculateDistanceFromGeoPoints(from, to);
    state = state.put(key, distance);
    return distance;
  }
  
  /// 캐시 초기화 (위치 변경 시 호출)
  void invalidate() {
    state = DistanceCacheState();
  }
  
  /// 캐시 통계
  Map<String, dynamic> get stats => {
    'size': state.size,
    'createdAt': state.createdAt.toIso8601String(),
  };
}

/// 거리 캐시 Provider
final distanceCacheProvider = StateNotifierProvider<DistanceCacheNotifier, DistanceCacheState>((ref) {
  // 사용자 위치 변경 시 캐시 무효화
  ref.listen(currentUserLocationProvider, (previous, next) {
    if (previous != next) {
      ref.notifier.invalidate();
    }
  });
  
  return DistanceCacheNotifier();
});

/// 캐시된 거리 계산 유틸리티
/// 
/// Provider 외부에서 간편하게 사용할 수 있는 확장 함수
extension DistanceCacheExtension on WidgetRef {
  /// 캐시된 거리 계산
  double getCachedDistance(GeoPoint? targetLocation) {
    final userLocation = read(currentUserLocationProvider);
    if (userLocation == null || targetLocation == null) return 0;
    
    return read(distanceCacheProvider.notifier).getDistance(
      userLocation,
      targetLocation,
    );
  }
  
  /// 캐시된 거리 문자열
  String getCachedDistanceString(GeoPoint? targetLocation, [String? fallback]) {
    final distance = getCachedDistance(targetLocation);
    if (distance == 0) {
      return fallback ?? LocationService.formatDistance(0);
    }
    return LocationService.formatDistance(distance);
  }
}
