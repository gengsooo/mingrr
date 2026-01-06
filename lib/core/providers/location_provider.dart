import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firebase_service.dart';
import '../services/location_service.dart';
import '../../models/user_model.dart';

/// ============================================================
/// 위치 관련 Provider
/// 
/// 기능:
/// - 현재 사용자 위치 (homeLocation 기반)
/// - 거리 필터링 적용된 데이터 조회
/// ============================================================

final _firebase = FirebaseService();

/// 현재 사용자 정보 Provider
final currentUserProvider = FutureProvider.autoDispose<UserModel?>((ref) async {
  final userId = _firebase.currentUserId;
  if (userId == null) return null;
  
  final doc = await _firebase.usersCollection.doc(userId).get();
  if (!doc.exists) return null;
  
  return UserModel.fromFirestore(doc.data()!, id: doc.id);
});

/// 현재 사용자 위치 (homeLocation) Provider
final currentUserLocationProvider = Provider.autoDispose<GeoPoint?>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  return user?.homeLocation;
});

/// 거리 필터링 유틸리티 클래스
class DistanceFilterHelper {
  /// 사용자 목록을 거리 기준으로 필터링
  /// 
  /// [users]: 필터링할 사용자 목록
  /// [userLocation]: 기준 위치 (현재 사용자 homeLocation)
  /// [radiusKm]: 필터 반경 (km)
  /// 반환값: 거리 내에 있는 사용자 목록 (거리 정보 포함)
  static List<UserWithDistance> filterUsersByDistance({
    required List<UserModel> users,
    required GeoPoint userLocation,
    required double radiusKm,
  }) {
    final result = <UserWithDistance>[];
    
    for (final user in users) {
      if (user.homeLocation == null) continue;
      
      final distance = LocationService.calculateDistanceFromGeoPoints(
        userLocation,
        user.homeLocation!,
      );
      
      // 반경 내에 있는 경우만 추가
      if (distance <= radiusKm * 1000) {
        result.add(UserWithDistance(user: user, distanceMeters: distance));
      }
    }
    
    // 거리순 정렬
    result.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
    
    return result;
  }
  
  /// 위치가 있는 아이템 목록을 거리 기준으로 필터링 (제네릭)
  /// 
  /// [items]: 필터링할 아이템 목록
  /// [userLocation]: 기준 위치
  /// [radiusKm]: 필터 반경 (km)
  /// [getLocation]: 아이템에서 위치를 추출하는 함수
  static List<ItemWithDistance<T>> filterItemsByDistance<T>({
    required List<T> items,
    required GeoPoint userLocation,
    required double radiusKm,
    required GeoPoint? Function(T item) getLocation,
  }) {
    final result = <ItemWithDistance<T>>[];
    
    for (final item in items) {
      final location = getLocation(item);
      if (location == null) continue;
      
      final distance = LocationService.calculateDistanceFromGeoPoints(
        userLocation,
        location,
      );
      
      if (distance <= radiusKm * 1000) {
        result.add(ItemWithDistance(item: item, distanceMeters: distance));
      }
    }
    
    result.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
    
    return result;
  }
}

/// 사용자 + 거리 정보
class UserWithDistance {
  final UserModel user;
  final double distanceMeters;
  
  UserWithDistance({required this.user, required this.distanceMeters});
  
  String get distanceString => LocationService.formatDistance(distanceMeters);
}

/// 아이템 + 거리 정보 (제네릭)
class ItemWithDistance<T> {
  final T item;
  final double distanceMeters;
  
  ItemWithDistance({required this.item, required this.distanceMeters});
  
  String get distanceString => LocationService.formatDistance(distanceMeters);
}
