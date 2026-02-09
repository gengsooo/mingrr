import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/paginated_state.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../../../core/providers/location_provider.dart';
import '../../../../core/providers/paginated_provider.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/transaction_service.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../models/group_model.dart';

/// ============================================================
/// 소모임(Group) Provider
/// 
/// 소셜 > 소모임 기능의 상태 관리
/// - 모임 목록 조회 (+ 거리/추천 점수)
/// - 모임 가입/탈퇴/강퇴
/// - 관리자 지정
/// - 좋아요 토글
/// - 일정 관리
/// ============================================================

/// 소모임 + 거리 정보 + 추천 점수 (ItemWithDistance<GroupModel> 확장)
class GroupWithDistance extends ItemWithDistance<GroupModel> {
  final double recommendScore;

  GroupWithDistance({
    required GroupModel group,
    required double distanceMeters,
    this.recommendScore = 0,
  }) : super(item: group, distanceMeters: distanceMeters);

  /// 기존 코드 호환성을 위한 접근자
  GroupModel get group => item;
}

/// 소모임 추천 알고리즘
class GroupRecommendationService {
  static double calculateRecommendScore({
    required GroupModel group,
    required double distanceMeters,
  }) {
    double score = 0;

    // 1. 거리 점수 (30%) - 10km 이내가 만점
    if (distanceMeters.isFinite && distanceMeters > 0) {
      final distanceScore = (1 - (distanceMeters / 10000).clamp(0, 1)) * 30;
      score += distanceScore;
    } else if (distanceMeters == 0) {
      score += 15;
    }

    // 2. 멤버 수 점수 (25%) - 최대 50명 기준
    final memberScore = (group.memberCount / 50).clamp(0, 1) * 25;
    score += memberScore;

    // 3. 좋아요 점수 (20%) - 최대 100개 기준
    final likeScore = (group.likeCount / 100).clamp(0, 1) * 20;
    score += likeScore;

    // 4. 최신 점수 (15%) - 30일 이내 생성이면 만점
    final daysSinceCreated = DateTime.now().difference(group.createdAt).inDays;
    final freshnessScore = (1 - (daysSinceCreated / 30).clamp(0, 1)) * 15;
    score += freshnessScore;

    // 5. 활동 점수 (10%) - 7일 이내 업데이트면 만점
    final daysSinceUpdated = DateTime.now().difference(group.updatedAt).inDays;
    final activityScore = (1 - (daysSinceUpdated / 7).clamp(0, 1)) * 10;
    score += activityScore;

    return score;
  }
}

/// 정렬 옵션
enum GroupSortOption {
  recommended,
  members,
  latest,
  likes,
}

/// 정렬 방향
enum SortDirection {
  descending,
  ascending,
}

/// 정렬 상태
class GroupSortState {
  final GroupSortOption option;
  final SortDirection direction;

  const GroupSortState({
    this.option = GroupSortOption.recommended,
    this.direction = SortDirection.descending,
  });

  GroupSortState copyWith({GroupSortOption? option, SortDirection? direction}) {
    return GroupSortState(
      option: option ?? this.option,
      direction: direction ?? this.direction,
    );
  }

  GroupSortState toggleDirection() {
    return copyWith(
      direction: direction == SortDirection.descending
          ? SortDirection.ascending
          : SortDirection.descending,
    );
  }
}

/// 정렬 상태 Provider
final groupSortStateProvider = StateProvider<GroupSortState>((ref) => const GroupSortState());

/// 모든 공개 소모임 (거리 정보 + 추천 점수 포함)
final _allGroupsWithDistanceProvider = FutureProvider.autoDispose<List<GroupWithDistance>>((ref) async {
  // 캐시 유지 - 소모임 목록은 자주 사용되는 데이터
  ref.keepAlive();
  
  final firestoreService = ref.watch(firestoreServiceProvider);
  final userLocation = ref.watch(currentUserLocationProvider);

  final groups = await firestoreService.getPublicGroups(limit: 50);

  final result = <GroupWithDistance>[];
  for (final group in groups) {
    double distance = 0;
    if (userLocation != null && group.location != null) {
      distance = LocationService.calculateDistanceFromGeoPoints(userLocation, group.location!);
    } else if (group.location == null) {
      distance = double.infinity;
    }

    final recommendScore = GroupRecommendationService.calculateRecommendScore(
      group: group,
      distanceMeters: distance,
    );

    result.add(GroupWithDistance(
      group: group,
      distanceMeters: distance,
      recommendScore: recommendScore,
    ));
  }

  return result;
});

/// 정렬된 소모임 목록
final sortedGroupsProvider = Provider.autoDispose<List<GroupWithDistance>>((ref) {
  final groupsAsync = ref.watch(_allGroupsWithDistanceProvider);
  final groups = groupsAsync.valueOrNull ?? [];
  final sortState = ref.watch(groupSortStateProvider);

  if (groups.isEmpty) return [];

  final sortedGroups = List<GroupWithDistance>.from(groups);
  final isAsc = sortState.direction == SortDirection.ascending;

  switch (sortState.option) {
    case GroupSortOption.recommended:
      sortedGroups.sort((a, b) => isAsc
          ? a.recommendScore.compareTo(b.recommendScore)
          : b.recommendScore.compareTo(a.recommendScore));
      break;
    case GroupSortOption.members:
      sortedGroups.sort((a, b) => isAsc
          ? a.group.memberCount.compareTo(b.group.memberCount)
          : b.group.memberCount.compareTo(a.group.memberCount));
      break;
    case GroupSortOption.latest:
      sortedGroups.sort((a, b) => isAsc
          ? a.group.createdAt.compareTo(b.group.createdAt)
          : b.group.createdAt.compareTo(a.group.createdAt));
      break;
    case GroupSortOption.likes:
      sortedGroups.sort((a, b) => isAsc
          ? a.group.likeCount.compareTo(b.group.likeCount)
          : b.group.likeCount.compareTo(a.group.likeCount));
      break;
  }

  return sortedGroups;
});

/// 사용자가 가입한 소모임 목록
final userGroupsProvider = FutureProvider.autoDispose<List<GroupModel>>((ref) async {
  final firebase = FirebaseService();
  final userId = firebase.currentUserId;
  if (userId == null) return [];

  final snapshot = await firebase.groupsCollection
      .where('memberIds', arrayContains: userId)
      .orderBy('updatedAt', descending: true)
      .get();

  return snapshot.docs
      .map((doc) => GroupModel.fromFirestore(doc.data(), id: doc.id))
      .toList();
});

/// 특정 소모임 상세
final groupDetailProvider = FutureProvider.autoDispose.family<GroupModel?, String>((ref, groupId) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getGroup(groupId);
});

/// 소모임 상세 (alias)
final groupByIdProvider = groupDetailProvider;

/// 인기 소모임 (홈 화면용)
final popularGroupsProvider = FutureProvider.autoDispose<List<GroupModel>>((ref) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final groups = await firestoreService.getPublicGroups(limit: 5);
  groups.sort((a, b) => b.memberCount.compareTo(a.memberCount));
  return groups;
});

/// 소모임 관리 Notifier
class GroupNotifier extends StateNotifier<AsyncValue<void>> {
  final FirebaseService _firebase = FirebaseService();

  GroupNotifier(Ref ref) : super(const AsyncValue.data(null));

  /// 소모임 가입
  Future<bool> joinGroup(String groupId, {String? message}) async {
    state = const AsyncValue.loading();

    try {
      final userId = _firebase.currentUserId;
      if (userId == null) throw Exception('로그인이 필요합니다');

      final groupDoc = await _firebase.groupsCollection.doc(groupId).get();
      if (!groupDoc.exists) throw Exception('모임을 찾을 수 없습니다');

      final group = GroupModel.fromFirestore(groupDoc.data()!, id: groupDoc.id);

      if (group.requireApproval) {
        // 가입 승인 필요 - 신청서 저장
        await _firebase.groupJoinRequestsCollection.add({
          'groupId': groupId,
          'userId': userId,
          'message': message,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        // 바로 가입 (트랜잭션으로 Race Condition 방지)
        await TransactionService.joinGroup(
          groupId: groupId,
          userId: userId,
        );
      }

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      AppLogger.error('GroupProvider', '소모임 가입 오류', e);
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// 소모임 탈퇴 (트랜잭션으로 Race Condition 방지)
  Future<bool> leaveGroup(String groupId) async {
    state = const AsyncValue.loading();

    try {
      final userId = _firebase.currentUserId;
      if (userId == null) throw Exception('로그인이 필요합니다');

      await TransactionService.leaveGroup(
        groupId: groupId,
        userId: userId,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      AppLogger.error('GroupProvider', '소모임 탈퇴 오류', e);
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// 멤버 강퇴
  Future<bool> kickMember(String groupId, String memberId) async {
    state = const AsyncValue.loading();

    try {
      final userId = _firebase.currentUserId;
      if (userId == null) throw Exception('로그인이 필요합니다');

      // 권한 확인
      final groupDoc = await _firebase.groupsCollection.doc(groupId).get();
      final group = GroupModel.fromFirestore(groupDoc.data()!, id: groupDoc.id);

      if (!group.isAdmin(userId) && !group.isCreator(userId)) {
        throw Exception('권한이 없습니다');
      }

      await _firebase.groupsCollection.doc(groupId).update({
        'memberIds': FieldValue.arrayRemove([memberId]),
        'adminIds': FieldValue.arrayRemove([memberId]),
        'memberCount': FieldValue.increment(-1),
      });
      
      // 강퇴된 사용자의 소모임 카운터 감소
      await _firebase.usersCollection.doc(memberId).update({
        'groupCount': FieldValue.increment(-1),
      });

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      AppLogger.error('GroupProvider', '멤버 강퇴 오류', e);
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// 관리자 지정/해제
  Future<bool> toggleAdmin(String groupId, String memberId) async {
    try {
      final userId = _firebase.currentUserId;
      if (userId == null) return false;

      final groupDoc = await _firebase.groupsCollection.doc(groupId).get();
      final group = GroupModel.fromFirestore(groupDoc.data()!, id: groupDoc.id);

      if (!group.isCreator(userId)) return false;

      if (group.isAdmin(memberId)) {
        await _firebase.groupsCollection.doc(groupId).update({
          'adminIds': FieldValue.arrayRemove([memberId]),
        });
      } else {
        await _firebase.groupsCollection.doc(groupId).update({
          'adminIds': FieldValue.arrayUnion([memberId]),
        });
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// 좋아요 토글 (트랜잭션으로 Race Condition 방지)
  Future<bool> toggleLike(String groupId) async {
    try {
      final userId = _firebase.currentUserId;
      if (userId == null) return false;

      return await TransactionService.toggleGroupLike(
        groupId: groupId,
        userId: userId,
      );
    } catch (e) {
      AppLogger.error('GroupProvider', '좋아요 토글 오류', e);
      return false;
    }
  }

  /// 가입 신청 승인
  Future<bool> approveJoinRequest(String requestId, String groupId, String userId) async {
    try {
      await _firebase.groupJoinRequestsCollection.doc(requestId).update({
        'status': 'approved',
        'respondedAt': FieldValue.serverTimestamp(),
        'respondedBy': _firebase.currentUserId,
      });

      await _firebase.groupsCollection.doc(groupId).update({
        'memberIds': FieldValue.arrayUnion([userId]),
        'memberCount': FieldValue.increment(1),
      });
      
      // 사용자 소모임 카운터 증가
      await _firebase.usersCollection.doc(userId).update({
        'groupCount': FieldValue.increment(1),
      });

      return true;
    } catch (e) {
      AppLogger.error('GroupProvider', '가입 신청 승인 오류', e);
      return false;
    }
  }

  /// 가입 신청 거절
  Future<bool> rejectJoinRequest(String requestId) async {
    try {
      await _firebase.groupJoinRequestsCollection.doc(requestId).update({
        'status': 'rejected',
        'respondedAt': FieldValue.serverTimestamp(),
        'respondedBy': _firebase.currentUserId,
      });
      return true;
    } catch (e) {
      AppLogger.error('GroupProvider', '가입 신청 거절 오류', e);
      return false;
    }
  }
}

/// Group Notifier Provider
final groupNotifierProvider = StateNotifierProvider<GroupNotifier, AsyncValue<void>>((ref) {
  return GroupNotifier(ref);
});

/// 소모임 좋아요 여부
final isGroupLikedProvider = FutureProvider.autoDispose.family<bool, String>((ref, groupId) async {
  final firebase = FirebaseService();
  final userId = firebase.currentUserId;
  if (userId == null) return false;

  final likeId = '${userId}_$groupId';
  final doc = await firebase.groupLikesCollection.doc(likeId).get();
  return doc.exists;
});

/// 소모임 가입 신청 목록 (관리자용)
final groupJoinRequestsProvider = FutureProvider.autoDispose.family<List<GroupJoinRequestModel>, String>((ref, groupId) async {
  final firebase = FirebaseService();
  final snapshot = await firebase.groupJoinRequestsCollection
      .where('groupId', isEqualTo: groupId)
      .where('status', isEqualTo: 'pending')
      .orderBy('createdAt', descending: true)
      .get();

  return snapshot.docs.map((doc) => GroupJoinRequestModel.fromFirestore(doc)).toList();
});

/// 소모임 일정 목록
final groupSchedulesProvider = FutureProvider.autoDispose.family<List<GroupScheduleModel>, String>((ref, groupId) async {
  final firebase = FirebaseService();
  final snapshot = await firebase.schedulesCollection
      .where('groupId', isEqualTo: groupId)
      .orderBy('startTime', descending: false)
      .get();

  return snapshot.docs
      .map((doc) => GroupScheduleModel.fromFirestore(doc.data(), id: doc.id))
      .toList();
});

/// ============================================================
/// 페이지네이션 소모임 목록 Provider
/// 
/// 서버 사이드 필터링 + 클라이언트 거리/추천점수 계산 + 캐싱
/// - 정렬 옵션 지원
/// - 20개씩 로드
/// - keepAlive로 화면 전환 시 상태 유지
/// ============================================================

/// 페이지네이션 소모임 목록 Provider
final paginatedGroupsProvider = StateNotifierProvider<
    ClientPaginatedNotifier<GroupWithDistance>,
    PaginatedState<GroupWithDistance>>((ref) {
  // 캐싱: 화면 전환 시 상태 유지 (5분 후 자동 해제)
  final link = ref.keepAlive();
  Future.delayed(const Duration(minutes: 5), () => link.close());
  
  final sortState = ref.watch(groupSortStateProvider);
  final userLocation = ref.watch(currentUserLocationProvider);
  
  return ClientPaginatedNotifier<GroupWithDistance>(
    pageSize: 20,
    fetchAll: () async {
      final firestoreService = ref.read(firestoreServiceProvider);
      final groups = await firestoreService.getPublicGroups(limit: 100);
      
      final result = <GroupWithDistance>[];
      for (final group in groups) {
        double distance = 0;
        if (userLocation != null && group.location != null) {
          distance = LocationService.calculateDistanceFromGeoPoints(
            userLocation,
            group.location!,
          );
        } else if (group.location == null) {
          distance = double.infinity;
        }
        
        final recommendScore = GroupRecommendationService.calculateRecommendScore(
          group: group,
          distanceMeters: distance,
        );
        
        result.add(GroupWithDistance(
          group: group,
          distanceMeters: distance,
          recommendScore: recommendScore,
        ));
      }
      
      // 정렬 적용
      final isAsc = sortState.direction == SortDirection.ascending;
      switch (sortState.option) {
        case GroupSortOption.recommended:
          result.sort((a, b) => isAsc
              ? a.recommendScore.compareTo(b.recommendScore)
              : b.recommendScore.compareTo(a.recommendScore));
          break;
        case GroupSortOption.members:
          result.sort((a, b) => isAsc
              ? a.group.memberCount.compareTo(b.group.memberCount)
              : b.group.memberCount.compareTo(a.group.memberCount));
          break;
        case GroupSortOption.latest:
          result.sort((a, b) => isAsc
              ? a.group.createdAt.compareTo(b.group.createdAt)
              : b.group.createdAt.compareTo(a.group.createdAt));
          break;
        case GroupSortOption.likes:
          result.sort((a, b) => isAsc
              ? a.group.likeCount.compareTo(b.group.likeCount)
              : b.group.likeCount.compareTo(a.group.likeCount));
          break;
      }
      
      return result;
    },
  );
});
