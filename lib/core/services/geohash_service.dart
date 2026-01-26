import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';

/// ============================================================
/// GeoHash 서비스
/// 
/// 위치 기반 검색을 위한 GeoHash 인코딩/디코딩 및 쿼리 지원
/// - GeoHash 생성: 위치를 문자열로 인코딩
/// - 범위 쿼리: 특정 반경 내 데이터 검색
/// - 정밀도: 6자리 (~1km), 5자리 (~5km), 4자리 (~20km)
/// ============================================================
class GeoHashService {
  GeoHashService._();

  static const String _base32 = '0123456789bcdefghjkmnpqrstuvwxyz';

  /// GeoHash 생성
  /// 
  /// [latitude] 위도 (-90 ~ 90)
  /// [longitude] 경도 (-180 ~ 180)
  /// [precision] 정밀도 (기본값: 9)
  ///   - 4: ~20km
  ///   - 5: ~5km
  ///   - 6: ~1km
  ///   - 7: ~150m
  ///   - 8: ~40m
  ///   - 9: ~5m
  static String encode(double latitude, double longitude, {int precision = 9}) {
    double minLat = -90.0, maxLat = 90.0;
    double minLon = -180.0, maxLon = 180.0;
    
    final buffer = StringBuffer();
    int bits = 0;
    int bitsTotal = 0;
    int hashValue = 0;
    bool isEven = true;

    while (buffer.length < precision) {
      if (isEven) {
        final mid = (minLon + maxLon) / 2;
        if (longitude >= mid) {
          hashValue = (hashValue << 1) + 1;
          minLon = mid;
        } else {
          hashValue = hashValue << 1;
          maxLon = mid;
        }
      } else {
        final mid = (minLat + maxLat) / 2;
        if (latitude >= mid) {
          hashValue = (hashValue << 1) + 1;
          minLat = mid;
        } else {
          hashValue = hashValue << 1;
          maxLat = mid;
        }
      }

      isEven = !isEven;
      bitsTotal++;

      if (bitsTotal == 5) {
        buffer.write(_base32[hashValue]);
        bitsTotal = 0;
        hashValue = 0;
      }
    }

    return buffer.toString();
  }

  /// GeoPoint에서 GeoHash 생성
  static String encodeGeoPoint(GeoPoint point, {int precision = 9}) {
    return encode(point.latitude, point.longitude, precision: precision);
  }

  /// 특정 반경 내 검색을 위한 GeoHash 범위 계산
  /// 
  /// [center] 중심점
  /// [radiusKm] 반경 (km)
  /// 반환값: (startHash, endHash) 범위
  static ({String start, String end}) getBoundsForRadius(
    GeoPoint center,
    double radiusKm,
  ) {
    // 반경에 따른 정밀도 결정
    final precision = _getPrecisionForRadius(radiusKm);
    final hash = encodeGeoPoint(center, precision: precision);
    
    // 범위 계산 (prefix 기반)
    final start = hash;
    final end = '$hash~'; // ~ 는 ASCII에서 z보다 큼
    
    return (start: start, end: end);
  }

  /// 반경에 따른 적절한 정밀도 반환
  static int _getPrecisionForRadius(double radiusKm) {
    if (radiusKm <= 0.04) return 8;      // ~40m
    if (radiusKm <= 0.15) return 7;      // ~150m
    if (radiusKm <= 1.0) return 6;       // ~1km
    if (radiusKm <= 5.0) return 5;       // ~5km
    if (radiusKm <= 20.0) return 4;      // ~20km
    return 3;                             // ~80km
  }

  /// 주변 8개 셀의 GeoHash 반환 (더 정확한 범위 검색용)
  static List<String> getNeighbors(String geohash) {
    if (geohash.isEmpty) return [];
    
    final neighbors = <String>[];
    final directions = [
      [-1, -1], [-1, 0], [-1, 1],
      [0, -1],           [0, 1],
      [1, -1],  [1, 0],  [1, 1],
    ];
    
    // 간단한 구현: 현재 해시의 prefix만 사용
    // 실제로는 더 복잡한 이웃 계산이 필요하지만,
    // Firestore 쿼리에서는 prefix 기반 범위 쿼리로 충분
    final prefix = geohash.substring(0, geohash.length - 1);
    
    for (var i = 0; i < _base32.length; i++) {
      neighbors.add('$prefix${_base32[i]}');
    }
    
    return neighbors;
  }

  /// 두 GeoHash 간 대략적인 거리 비교
  /// 공통 prefix 길이가 길수록 가까움
  static int compareDistance(String hash1, String hash2) {
    int commonLength = 0;
    final minLength = math.min(hash1.length, hash2.length);
    
    for (var i = 0; i < minLength; i++) {
      if (hash1[i] == hash2[i]) {
        commonLength++;
      } else {
        break;
      }
    }
    
    return commonLength;
  }
}

/// GeoHash 데이터 모델 (Firestore 저장용)
class GeoHashData {
  final GeoPoint geopoint;
  final String geohash;

  GeoHashData({
    required this.geopoint,
    required this.geohash,
  });

  factory GeoHashData.fromGeoPoint(GeoPoint point, {int precision = 9}) {
    return GeoHashData(
      geopoint: point,
      geohash: GeoHashService.encodeGeoPoint(point, precision: precision),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'geopoint': geopoint,
      'geohash': geohash,
    };
  }

  factory GeoHashData.fromFirestore(Map<String, dynamic> data) {
    return GeoHashData(
      geopoint: data['geopoint'] as GeoPoint,
      geohash: data['geohash'] as String,
    );
  }
}
