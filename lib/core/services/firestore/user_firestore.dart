import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/user_model.dart';
import '../../utils/app_logger.dart';
import '../geohash_service.dart';
import 'firestore_base.dart';

/// 사용자(User) 도메인 Firestore CRUD mixin
/// 
/// 사용자 생성, 조회, 수정, 삭제, 닉네임 중복 체크, 
/// 활동 통계, GeoHash 업데이트 등을 담당합니다.
mixin UserFirestore on FirestoreBase {
  
  Future<void> createUser(UserModel user) async {
    try {
      await firebase.usersCollection.doc(user.id).set(user.toFirestore());
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'createUser (userId: ${user.id})', e);
      rethrow;
    }
  }
  
  Future<UserModel?> getUser(String userId) async {
    try {
      final doc = await firebase.usersCollection.doc(userId).get();
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc.data()!, id: doc.id);
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'getUser (userId: $userId)', e);
      rethrow;
    }
  }
  
  Future<void> updateUser(UserModel user) async {
    try {
      await firebase.usersCollection.doc(user.id).update(user.toFirestore());
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'updateUser (userId: ${user.id})', e);
      rethrow;
    }
  }
  
  Future<void> deleteUser(String userId) async {
    try {
      await firebase.usersCollection.doc(userId).delete();
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'deleteUser (userId: $userId)', e);
      rethrow;
    }
  }
  
  /// 닉네임 중복 체크
  /// [nickname] 체크할 닉네임
  /// [excludeUserId] 본인 ID (수정 시 본인 제외)
  /// Returns: true = 사용 가능, false = 이미 사용 중
  Future<bool> isNicknameAvailable(String nickname, {String? excludeUserId}) async {
    try {
      final query = await firebase.usersCollection
          .where('nickname', isEqualTo: nickname)
          .limit(1)
          .get();
      
      if (query.docs.isEmpty) return true;
      
      // 본인인 경우 사용 가능
      if (excludeUserId != null && query.docs.first.id == excludeUserId) {
        return true;
      }
      
      return false;
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'isNicknameAvailable (nickname: $nickname)', e);
      rethrow;
    }
  }
  
  Stream<UserModel?> watchUser(String userId) {
    return firebase.usersCollection
        .doc(userId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return null;
          return UserModel.fromFirestore(doc.data()!, id: doc.id);
        });
  }

  // ===== 활동 기록 관련 =====

  /// 사용자의 전체 활동 기록 조회 (카운터 필드 활용 - 최적화)
  /// 
  /// UserModel에 저장된 카운터 필드를 직접 읽어 추가 쿼리 없이 통계 반환
  /// - 이벤트 발생 시 카운터가 자동 증가/감소되므로 항상 최신 상태 유지
  Future<Map<String, int>> getUserActivityStats(String userId) async {
    try {
      final userDoc = await firebase.usersCollection.doc(userId).get();
      if (!userDoc.exists) {
        return {
          'walks': 0,
          'matches': 0,
          'transactions': 0,
          'posts': 0,
          'groups': 0,
        };
      }
      
      final data = userDoc.data()!;
      return {
        'walks': data['walkCount'] ?? 0,
        'matches': data['matchCount'] ?? 0,
        'transactions': data['transactionCount'] ?? 0,
        'posts': data['postCount'] ?? 0,
        'groups': data['groupCount'] ?? 0,
      };
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'getUserActivityStats (userId: $userId)', e);
      rethrow;
    }
  }

  /// 사용자의 매칭 수 조회 (userIds 배열 활용 - 최적화)
  Future<int> getUserMatchCount(String userId) async {
    try {
      final snapshot = await firebase.matchesCollection
          .where('userIds', arrayContains: userId)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'getUserMatchCount (userId: $userId)', e);
      rethrow;
    }
  }

  /// 사용자의 산책 횟수 조회 (실제 기록 기반)
  Future<int> getUserWalkCount(String userId) async {
    try {
      final snapshot = await firebase.walksCollection
          .where('userId', isEqualTo: userId)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'getUserWalkCount (userId: $userId)', e);
      rethrow;
    }
  }

  /// 사용자의 거래 수 조회 (판매 완료 + 구매)
  Future<int> getUserTransactionCount(String userId) async {
    try {
      // 판매 완료
      final soldSnapshot = await firebase.productsCollection
          .where('sellerId', isEqualTo: userId)
          .where('status', isEqualTo: 'sold')
          .get();
      // 구매
      final boughtSnapshot = await firebase.productsCollection
          .where('buyerId', isEqualTo: userId)
          .get();
      return soldSnapshot.docs.length + boughtSnapshot.docs.length;
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'getUserTransactionCount (userId: $userId)', e);
      rethrow;
    }
  }

  /// 사용자가 참여한 모임 수 조회
  Future<int> getUserGroupCount(String userId) async {
    try {
      final snapshot = await firebase.groupsCollection
          .where('memberIds', arrayContains: userId)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'getUserGroupCount (userId: $userId)', e);
      rethrow;
    }
  }

  /// 사용자의 커뮤니티 게시글 수 조회
  Future<int> getUserPostCount(String userId) async {
    try {
      final snapshot = await firebase.feedPostsCollection
          .where('authorId', isEqualTo: userId)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'getUserPostCount (userId: $userId)', e);
      rethrow;
    }
  }

  /// 사용자 GeoHash 업데이트
  Future<void> updateUserGeohash(String userId, GeoPoint location) async {
    try {
      final geohash = GeoHashService.encodeGeoPoint(location);
      await firebase.usersCollection.doc(userId).update({
        'geohash': geohash,
        'homeLocation': location,
      });
    } catch (e) {
      rethrow;
    }
  }
}
