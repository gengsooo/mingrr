import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

/// ============================================================
/// 지오코딩 서비스
/// 
/// 기능:
/// - 역지오코딩: 좌표 → 주소 변환 (카카오 로컬 API)
/// - 지오코딩: 주소 → 좌표 변환
/// - 주소 검색
/// ============================================================
class GeocodingService {
  GeocodingService._();
  
  /// 카카오 REST API 키 (JavaScript 키가 아닌 REST API 키 사용)
  static const String _kakaoRestApiKey = '185d8f5a9d617aa3506964ffd352c8b4';
  
  /// 역지오코딩: 좌표 → 주소 변환
  /// 
  /// [latitude]: 위도
  /// [longitude]: 경도
  /// 반환값: AddressResult (주소 정보)
  static Future<AddressResult?> reverseGeocode(double latitude, double longitude) async {
    try {
      final url = Uri.parse(
        'https://dapi.kakao.com/v2/local/geo/coord2address.json?x=$longitude&y=$latitude'
      );
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'KakaoAK $_kakaoRestApiKey',
        },
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final documents = data['documents'] as List?;
        
        if (documents != null && documents.isNotEmpty) {
          final doc = documents.first;
          final roadAddress = doc['road_address'];
          final address = doc['address'];
          
          return AddressResult(
            fullAddress: roadAddress?['address_name'] ?? address?['address_name'] ?? '',
            roadAddress: roadAddress?['address_name'],
            jibunAddress: address?['address_name'],
            sido: address?['region_1depth_name'] ?? '',
            sigungu: address?['region_2depth_name'] ?? '',
            dong: address?['region_3depth_name'] ?? '',
            latitude: latitude,
            longitude: longitude,
          );
        }
      }
      
      return null;
    } catch (e) {
      print('역지오코딩 오류: $e');
      return null;
    }
  }
  
  /// 지오코딩: 주소 → 좌표 변환
  /// 
  /// [address]: 검색할 주소
  /// 반환값: AddressResult (좌표 포함)
  static Future<AddressResult?> geocode(String address) async {
    try {
      final encodedAddress = Uri.encodeComponent(address);
      final url = Uri.parse(
        'https://dapi.kakao.com/v2/local/search/address.json?query=$encodedAddress'
      );
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'KakaoAK $_kakaoRestApiKey',
        },
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final documents = data['documents'] as List?;
        
        if (documents != null && documents.isNotEmpty) {
          final doc = documents.first;
          final roadAddress = doc['road_address'];
          final jibunAddress = doc['address'];
          
          final lat = double.tryParse(doc['y']?.toString() ?? '') ?? 0;
          final lng = double.tryParse(doc['x']?.toString() ?? '') ?? 0;
          
          return AddressResult(
            fullAddress: roadAddress?['address_name'] ?? jibunAddress?['address_name'] ?? address,
            roadAddress: roadAddress?['address_name'],
            jibunAddress: jibunAddress?['address_name'],
            sido: jibunAddress?['region_1depth_name'] ?? '',
            sigungu: jibunAddress?['region_2depth_name'] ?? '',
            dong: jibunAddress?['region_3depth_name'] ?? '',
            latitude: lat,
            longitude: lng,
          );
        }
      }
      
      return null;
    } catch (e) {
      print('지오코딩 오류: $e');
      return null;
    }
  }
  
  /// 키워드로 장소 검색
  /// 
  /// [keyword]: 검색 키워드
  /// [latitude], [longitude]: 중심 좌표 (선택)
  /// 반환값: 장소 목록
  static Future<List<PlaceResult>> searchPlaces(
    String keyword, {
    double? latitude,
    double? longitude,
  }) async {
    try {
      final encodedKeyword = Uri.encodeComponent(keyword);
      String urlString = 'https://dapi.kakao.com/v2/local/search/keyword.json?query=$encodedKeyword';
      
      if (latitude != null && longitude != null) {
        urlString += '&y=$latitude&x=$longitude&sort=distance';
      }
      
      final url = Uri.parse(urlString);
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'KakaoAK $_kakaoRestApiKey',
        },
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final documents = data['documents'] as List?;
        
        if (documents != null) {
          return documents.map((doc) => PlaceResult(
            placeName: doc['place_name'] ?? '',
            address: doc['address_name'] ?? '',
            roadAddress: doc['road_address_name'] ?? '',
            category: doc['category_name'] ?? '',
            latitude: double.tryParse(doc['y']?.toString() ?? '') ?? 0,
            longitude: double.tryParse(doc['x']?.toString() ?? '') ?? 0,
            distance: int.tryParse(doc['distance']?.toString() ?? '') ?? 0,
          )).toList();
        }
      }
      
      return [];
    } catch (e) {
      print('장소 검색 오류: $e');
      return [];
    }
  }
  
  /// GeoPoint에서 주소 가져오기
  static Future<AddressResult?> getAddressFromGeoPoint(GeoPoint geoPoint) async {
    return reverseGeocode(geoPoint.latitude, geoPoint.longitude);
  }
  
  /// 간단한 주소 문자열 반환 (구 동)
  static Future<String> getSimpleAddress(double latitude, double longitude) async {
    final result = await reverseGeocode(latitude, longitude);
    if (result != null) {
      return result.shortAddress;
    }
    return '위치 정보 없음';
  }
}

/// 주소 결과 모델
class AddressResult {
  /// 전체 주소
  final String fullAddress;
  
  /// 도로명 주소
  final String? roadAddress;
  
  /// 지번 주소
  final String? jibunAddress;
  
  /// 시/도
  final String sido;
  
  /// 시/군/구
  final String sigungu;
  
  /// 동/읍/면
  final String dong;
  
  /// 위도
  final double latitude;
  
  /// 경도
  final double longitude;
  
  const AddressResult({
    required this.fullAddress,
    this.roadAddress,
    this.jibunAddress,
    required this.sido,
    required this.sigungu,
    required this.dong,
    required this.latitude,
    required this.longitude,
  });
  
  /// 짧은 주소 (구 동)
  String get shortAddress {
    if (sigungu.isNotEmpty && dong.isNotEmpty) {
      return '$sigungu $dong';
    } else if (dong.isNotEmpty) {
      return dong;
    } else if (sigungu.isNotEmpty) {
      return sigungu;
    }
    return fullAddress;
  }
  
  /// 중간 길이 주소 (시 구 동)
  String get mediumAddress {
    if (sido.isNotEmpty && sigungu.isNotEmpty && dong.isNotEmpty) {
      // 서울특별시 → 서울, 경기도 → 경기 등 축약
      String shortSido = sido;
      if (sido.endsWith('특별시') || sido.endsWith('광역시')) {
        shortSido = sido.substring(0, 2);
      } else if (sido.endsWith('도')) {
        shortSido = sido.substring(0, sido.length - 1);
      }
      return '$shortSido $sigungu $dong';
    }
    return shortAddress;
  }
  
  /// GeoPoint로 변환
  GeoPoint toGeoPoint() => GeoPoint(latitude, longitude);
  
  /// Map으로 변환 (Firestore 저장용)
  Map<String, dynamic> toMap() {
    return {
      'fullAddress': fullAddress,
      'roadAddress': roadAddress,
      'jibunAddress': jibunAddress,
      'sido': sido,
      'sigungu': sigungu,
      'dong': dong,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
  
  /// Map에서 생성
  factory AddressResult.fromMap(Map<String, dynamic> map) {
    return AddressResult(
      fullAddress: map['fullAddress'] ?? '',
      roadAddress: map['roadAddress'],
      jibunAddress: map['jibunAddress'],
      sido: map['sido'] ?? '',
      sigungu: map['sigungu'] ?? '',
      dong: map['dong'] ?? '',
      latitude: (map['latitude'] ?? 0).toDouble(),
      longitude: (map['longitude'] ?? 0).toDouble(),
    );
  }
}

/// 장소 검색 결과 모델
class PlaceResult {
  /// 장소명
  final String placeName;
  
  /// 지번 주소
  final String address;
  
  /// 도로명 주소
  final String roadAddress;
  
  /// 카테고리
  final String category;
  
  /// 위도
  final double latitude;
  
  /// 경도
  final double longitude;
  
  /// 거리 (미터)
  final int distance;
  
  const PlaceResult({
    required this.placeName,
    required this.address,
    required this.roadAddress,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.distance,
  });
  
  /// 표시용 주소 (도로명 우선)
  String get displayAddress => roadAddress.isNotEmpty ? roadAddress : address;
  
  /// GeoPoint로 변환
  GeoPoint toGeoPoint() => GeoPoint(latitude, longitude);
}
