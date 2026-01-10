import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// ============================================================
/// 위치 정보 통합 모델
/// 
/// 앱 전체에서 사용하는 위치 데이터 구조
/// - 좌표 (위도, 경도)
/// - 주소 정보 (전체 주소, 짧은 주소)
/// ============================================================
class LocationData extends Equatable {
  /// 위도
  final double latitude;
  
  /// 경도
  final double longitude;
  
  /// 전체 주소 (도로명 또는 지번)
  final String? fullAddress;
  
  /// 짧은 주소 (구 동)
  final String? shortAddress;
  
  /// 시/도
  final String? sido;
  
  /// 시/군/구
  final String? sigungu;
  
  /// 동/읍/면
  final String? dong;

  const LocationData({
    required this.latitude,
    required this.longitude,
    this.fullAddress,
    this.shortAddress,
    this.sido,
    this.sigungu,
    this.dong,
  });
  
  /// 기본 위치 (서울 시청)
  static const LocationData defaultLocation = LocationData(
    latitude: 37.5665,
    longitude: 126.9780,
    fullAddress: '서울특별시 중구 세종대로 110',
    shortAddress: '중구 태평로1가',
    sido: '서울특별시',
    sigungu: '중구',
    dong: '태평로1가',
  );
  
  /// 좌표만 있는 경우 생성
  factory LocationData.fromCoordinates(double latitude, double longitude) {
    return LocationData(
      latitude: latitude,
      longitude: longitude,
    );
  }
  
  /// GeoPoint에서 생성
  factory LocationData.fromGeoPoint(GeoPoint geoPoint) {
    return LocationData(
      latitude: geoPoint.latitude,
      longitude: geoPoint.longitude,
    );
  }
  
  /// Firestore 데이터에서 생성
  factory LocationData.fromMap(Map<String, dynamic> map) {
    // GeoPoint 형태인 경우
    if (map['location'] is GeoPoint) {
      final geoPoint = map['location'] as GeoPoint;
      return LocationData(
        latitude: geoPoint.latitude,
        longitude: geoPoint.longitude,
        fullAddress: map['address'] ?? map['fullAddress'],
        shortAddress: map['shortAddress'],
        sido: map['sido'],
        sigungu: map['sigungu'],
        dong: map['dong'],
      );
    }
    
    // 개별 필드 형태인 경우
    return LocationData(
      latitude: (map['latitude'] ?? 0).toDouble(),
      longitude: (map['longitude'] ?? 0).toDouble(),
      fullAddress: map['address'] ?? map['fullAddress'],
      shortAddress: map['shortAddress'],
      sido: map['sido'],
      sigungu: map['sigungu'],
      dong: map['dong'],
    );
  }
  
  /// GeoPoint로 변환
  GeoPoint toGeoPoint() => GeoPoint(latitude, longitude);
  
  /// Firestore 저장용 Map
  Map<String, dynamic> toMap() {
    return {
      'location': toGeoPoint(),
      'latitude': latitude,
      'longitude': longitude,
      'fullAddress': fullAddress,
      'shortAddress': shortAddress,
      'sido': sido,
      'sigungu': sigungu,
      'dong': dong,
    };
  }
  
  /// 표시용 주소 (짧은 주소 우선, 없으면 전체 주소)
  String get displayAddress {
    if (shortAddress != null && shortAddress!.isNotEmpty) {
      return shortAddress!;
    }
    if (fullAddress != null && fullAddress!.isNotEmpty) {
      return fullAddress!;
    }
    return '위치 정보 없음';
  }
  
  /// 주소 정보가 있는지 확인
  bool get hasAddress => fullAddress != null && fullAddress!.isNotEmpty;
  
  /// 유효한 좌표인지 확인
  bool get isValid => latitude != 0 && longitude != 0;
  
  /// 주소 정보 업데이트된 새 인스턴스 반환
  LocationData copyWithAddress({
    String? fullAddress,
    String? shortAddress,
    String? sido,
    String? sigungu,
    String? dong,
  }) {
    return LocationData(
      latitude: latitude,
      longitude: longitude,
      fullAddress: fullAddress ?? this.fullAddress,
      shortAddress: shortAddress ?? this.shortAddress,
      sido: sido ?? this.sido,
      sigungu: sigungu ?? this.sigungu,
      dong: dong ?? this.dong,
    );
  }
  
  @override
  List<Object?> get props => [
    latitude,
    longitude,
    fullAddress,
    shortAddress,
    sido,
    sigungu,
    dong,
  ];
  
  @override
  String toString() {
    return 'LocationData(lat: $latitude, lng: $longitude, address: $displayAddress)';
  }
}
