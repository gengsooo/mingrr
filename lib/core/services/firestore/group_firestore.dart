import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/group_model.dart';
import '../../utils/app_logger.dart';
import '../geohash_service.dart';
import '../transaction_service.dart';
import 'firestore_base.dart';

/// 소모임(Group) 도메인 Firestore CRUD mixin
mixin GroupFirestore on FirestoreBase {

  Future<void> createGroup(GroupModel group) async {
    try {
      await firebase.groupsCollection.doc(group.id).set(group.toFirestore());
      
      // 생성자의 소모임 카운터 증가 (생성자도 멤버에 포함됨)
      if (group.creatorId.isNotEmpty) {
        await firebase.usersCollection.doc(group.creatorId).update({
          'groupCount': FieldValue.increment(1),
        });
      }
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'createGroup (groupId: ${group.id})', e);
      rethrow;
    }
  }
  
  Future<GroupModel?> getGroup(String groupId) async {
    try {
      final doc = await firebase.groupsCollection.doc(groupId).get();
      if (!doc.exists) return null;
      return GroupModel.fromFirestore(doc.data()!, id: doc.id);
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'getGroup (groupId: $groupId)', e);
      rethrow;
    }
  }
  
  Future<void> updateGroup(GroupModel group) async {
    try {
      await firebase.groupsCollection.doc(group.id).update(group.toFirestore());
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'updateGroup (groupId: ${group.id})', e);
      rethrow;
    }
  }
  
  Future<List<GroupModel>> getPublicGroups({int limit = 20}) async {
    try {
      final snapshot = await firebase.groupsCollection
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => GroupModel.fromFirestore(doc.data(), id: doc.id))
          .toList();
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'getPublicGroups', e);
      rethrow;
    }
  }

  /// 소모임 삭제
  Future<void> deleteGroup(String groupId) async {
    try {
      await firebase.groupsCollection.doc(groupId).delete();
      // 관련 좋아요도 삭제
      final likes = await firebase.groupLikesCollection
          .where('groupId', isEqualTo: groupId)
          .get();
      for (final doc in likes.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'deleteGroup (groupId: $groupId)', e);
      rethrow;
    }
  }

  // ===== 일정 관련 =====

  Future<void> createSchedule(GroupScheduleModel schedule) async {
    try {
      await firebase.schedulesCollection.doc(schedule.id).set(schedule.toFirestore());
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'createSchedule (scheduleId: ${schedule.id})', e);
      rethrow;
    }
  }
  
  Future<List<GroupScheduleModel>> getGroupSchedules(String groupId) async {
    try {
      final snapshot = await firebase.schedulesCollection
          .where('groupId', isEqualTo: groupId)
          .orderBy('startTime', descending: false)
          .get();
      
      return snapshot.docs
          .map((doc) => GroupScheduleModel.fromFirestore(doc.data(), id: doc.id))
          .toList();
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'getGroupSchedules (groupId: $groupId)', e);
      rethrow;
    }
  }

  /// 일정 수정
  Future<void> updateSchedule(GroupScheduleModel schedule) async {
    try {
      await firebase.schedulesCollection.doc(schedule.id).update(schedule.toFirestore());
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'updateSchedule (scheduleId: ${schedule.id})', e);
      rethrow;
    }
  }

  /// 일정 삭제
  Future<void> deleteSchedule(String scheduleId) async {
    try {
      await firebase.schedulesCollection.doc(scheduleId).delete();
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'deleteSchedule (scheduleId: $scheduleId)', e);
      rethrow;
    }
  }

  /// 일정 참여
  Future<void> joinSchedule(String scheduleId, String userId) async {
    try {
      await firebase.schedulesCollection.doc(scheduleId).update({
        'participantIds': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'joinSchedule (scheduleId: $scheduleId, userId: $userId)', e);
      rethrow;
    }
  }

  /// 일정 참여 취소
  Future<void> leaveSchedule(String scheduleId, String userId) async {
    try {
      await firebase.schedulesCollection.doc(scheduleId).update({
        'participantIds': FieldValue.arrayRemove([userId]),
      });
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'leaveSchedule (scheduleId: $scheduleId, userId: $userId)', e);
      rethrow;
    }
  }

  // ===== 소모임 좋아요 관련 =====

  /// 소모임 좋아요 토글 (TransactionService 위임)
  Future<bool> toggleGroupLike(String groupId, String userId) async {
    try {
      return await TransactionService.toggleGroupLike(
        groupId: groupId,
        userId: userId,
      );
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'toggleGroupLike (groupId: $groupId)', e);
      rethrow;
    }
  }

  /// 소모임 좋아요 여부 확인
  Future<bool> isGroupLiked(String groupId, String userId) async {
    try {
      final likeId = '${userId}_$groupId';
      final doc = await firebase.groupLikesCollection.doc(likeId).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// 사용자가 좋아요한 소모임 목록
  Future<List<String>> getUserLikedGroupIds(String userId) async {
    try {
      final snapshot = await firebase.groupLikesCollection
          .where('userId', isEqualTo: userId)
          .get();
      return snapshot.docs.map((doc) => doc.data()['groupId'] as String).toList();
    } catch (e) {
      return [];
    }
  }

  // ===== 소모임 가입 신청 관련 =====

  /// 가입 신청 생성
  Future<void> createJoinRequest({
    required String groupId,
    required String userId,
    String? message,
  }) async {
    try {
      await firebase.groupJoinRequestsCollection.add({
        'groupId': groupId,
        'userId': userId,
        'message': message,
        'status': JoinRequestStatus.pending.name,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// 특정 모임의 가입 신청 목록 조회 (대기중만)
  Future<List<GroupJoinRequestModel>> getPendingJoinRequests(String groupId) async {
    try {
      final snapshot = await firebase.groupJoinRequestsCollection
          .where('groupId', isEqualTo: groupId)
          .where('status', isEqualTo: JoinRequestStatus.pending.name)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map((doc) => GroupJoinRequestModel.fromFirestore(doc)).toList();
    } catch (e) {
      return [];
    }
  }

  /// 특정 모임의 가입 신청 목록 스트림 (대기중만)
  Stream<List<GroupJoinRequestModel>> watchPendingJoinRequests(String groupId) {
    return firebase.groupJoinRequestsCollection
        .where('groupId', isEqualTo: groupId)
        .where('status', isEqualTo: JoinRequestStatus.pending.name)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GroupJoinRequestModel.fromFirestore(doc))
            .toList());
  }

  /// 가입 신청 승인
  Future<void> approveJoinRequest({
    required String requestId,
    required String groupId,
    required String userId,
    required String respondedBy,
  }) async {
    try {
      final batch = firestore.batch();
      
      // 1. 신청 상태 업데이트
      batch.update(firebase.groupJoinRequestsCollection.doc(requestId), {
        'status': JoinRequestStatus.approved.name,
        'respondedAt': FieldValue.serverTimestamp(),
        'respondedBy': respondedBy,
      });
      
      // 2. 모임 멤버 목록에 추가
      batch.update(firebase.groupsCollection.doc(groupId), {
        'memberIds': FieldValue.arrayUnion([userId]),
        'memberCount': FieldValue.increment(1),
      });
      
      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }

  /// 가입 신청 거절
  Future<void> rejectJoinRequest({
    required String requestId,
    required String respondedBy,
  }) async {
    try {
      await firebase.groupJoinRequestsCollection.doc(requestId).update({
        'status': JoinRequestStatus.rejected.name,
        'respondedAt': FieldValue.serverTimestamp(),
        'respondedBy': respondedBy,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// 사용자가 해당 모임에 가입 신청했는지 확인
  Future<bool> hasUserRequestedJoin(String groupId, String userId) async {
    try {
      final snapshot = await firebase.groupJoinRequestsCollection
          .where('groupId', isEqualTo: groupId)
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: JoinRequestStatus.pending.name)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// 대기중인 가입 신청 수 조회
  Future<int> getPendingJoinRequestCount(String groupId) async {
    try {
      final snapshot = await firebase.groupJoinRequestsCollection
          .where('groupId', isEqualTo: groupId)
          .where('status', isEqualTo: JoinRequestStatus.pending.name)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  // ===== 서버 사이드 필터링 + 페이지네이션 =====

  /// 소모임 목록 조회 (서버 사이드 필터링 + 페이지네이션)
  Future<({List<GroupModel> items, DocumentSnapshot? lastDoc, bool hasMore})> 
      getGroupsPaginated({
    bool? isPublic,
    String? category,
    DocumentSnapshot? lastDocument,
    int limit = 20,
  }) async {
    try {
      Query<Map<String, dynamic>> query = firebase.groupsCollection;
      
      if (isPublic != null) {
        query = query.where('isPublic', isEqualTo: isPublic);
      }
      if (category != null) {
        query = query.where('category', isEqualTo: category);
      }
      
      query = query.orderBy('createdAt', descending: true);
      
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }
      
      final snapshot = await query.limit(limit + 1).get();
      final hasMore = snapshot.docs.length > limit;
      final docs = hasMore ? snapshot.docs.take(limit).toList() : snapshot.docs;
      
      return (
        items: docs.map((doc) => GroupModel.fromFirestore(doc.data(), id: doc.id)).toList(),
        lastDoc: docs.isNotEmpty ? docs.last : null,
        hasMore: hasMore,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// GeoHash 기반 소모임 검색 (반경 내)
  Future<List<GroupModel>> getGroupsByGeohash({
    required String centerGeohash,
    required double radiusKm,
    bool? isPublic,
  }) async {
    try {
      final precision = radiusKm <= 1 ? 6 : (radiusKm <= 5 ? 5 : 4);
      final prefix = centerGeohash.substring(0, precision.clamp(1, centerGeohash.length));
      
      Query<Map<String, dynamic>> query = firebase.groupsCollection
          .where('geohash', isGreaterThanOrEqualTo: prefix)
          .where('geohash', isLessThan: '$prefix~');
      
      if (isPublic != null) {
        query = query.where('isPublic', isEqualTo: isPublic);
      }
      
      final snapshot = await query.get();
      
      return snapshot.docs
          .map((doc) => GroupModel.fromFirestore(doc.data(), id: doc.id))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// 소모임 GeoHash 업데이트
  Future<void> updateGroupGeohash(String groupId, GeoPoint location) async {
    try {
      final geohash = GeoHashService.encodeGeoPoint(location);
      await firebase.groupsCollection.doc(groupId).update({
        'geohash': geohash,
        'location': location,
      });
    } catch (e) {
      rethrow;
    }
  }
}
