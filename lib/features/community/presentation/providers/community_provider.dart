import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../../../core/providers/location_provider.dart';
import '../../../../core/services/location_service.dart';
import '../../../../models/group_model.dart';

/// ============================================================
/// 커뮤니티(소모임) 관련 Provider
/// Firebase Firestore와 연동하여 소모임 데이터 관리
/// ============================================================

/// 소모임 + 거리 정보 + 추천 점수
class GroupWithDistance {
  final GroupModel group;
  final double distanceMeters;
  final double recommendScore; // 추천 점수 (높을수록 추천)
  
  GroupWithDistance({
    required this.group,
    required this.distanceMeters,
    this.recommendScore = 0,
  });
  
  String get distanceString => LocationService.formatDistance(distanceMeters);
}

/// 소모임 추천 알고리즘
/// 
/// 가중치:
/// - 거리 (30%): 가까울수록 높은 점수
/// - 멤버 수 (25%): 멤버가 많을수록 높은 점수 (활성화된 모임)
/// - 좋아요 수 (20%): 좋아요가 많을수록 높은 점수
/// - 최신 (15%): 최근 생성된 모임일수록 높은 점수
/// - 활동 내역 (10%): 최근 업데이트된 모임일수록 높은 점수
class GroupRecommendationService {
  static double calculateRecommendScore({
    required GroupModel group,
    required double distanceMeters,
  }) {
    double score = 0;
    
    // 1. 거리 점수 (30%) - 10km 이내가 만점, 멀수록 감소
    if (distanceMeters.isFinite && distanceMeters > 0) {
      final distanceScore = (1 - (distanceMeters / 10000).clamp(0, 1)) * 30;
      score += distanceScore;
    } else if (distanceMeters == 0) {
      // 거리 정보 없음 - 중간 점수
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

// 모든 공개 소모임 (거리 정보 + 추천 점수 포함)
final _allGroupsWithDistanceProvider = FutureProvider.autoDispose<List<GroupWithDistance>>((ref) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final userLocation = ref.watch(currentUserLocationProvider);
  
  final groups = await firestoreService.getPublicGroups(limit: 50);
  
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
  
  return result;
});

// 공개 소모임 목록 (거리 필터 적용)
final publicGroupsProvider = Provider.autoDispose.family<List<GroupWithDistance>, double>((ref, radiusKm) {
  final groupsAsync = ref.watch(_allGroupsWithDistanceProvider);
  final groups = groupsAsync.valueOrNull ?? [];
  
  return groups.where((g) => g.distanceMeters <= radiusKm * 1000).toList();
});

/// 정렬 옵션 enum
enum GroupSortOption {
  recommended, // 추천순
  members,     // 멤버순
  latest,      // 최신순
  likes,       // 좋아요순
}

/// 정렬 방향
enum SortDirection {
  descending, // 내림차순 (기본)
  ascending,  // 오름차순
}

/// 정렬 상태
class GroupSortState {
  final GroupSortOption option;
  final SortDirection direction;
  
  const GroupSortState({
    this.option = GroupSortOption.recommended,
    this.direction = SortDirection.descending,
  });
  
  GroupSortState copyWith({
    GroupSortOption? option,
    SortDirection? direction,
  }) {
    return GroupSortState(
      option: option ?? this.option,
      direction: direction ?? this.direction,
    );
  }
  
  /// 같은 옵션 클릭 시 방향 토글
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

/// 정렬된 소모임 목록 Provider
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

// 인기 소모임 목록 (홈 화면용 - 거리 무관)
final popularGroupsProvider = FutureProvider.autoDispose<List<GroupModel>>((ref) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final groups = await firestoreService.getPublicGroups(limit: 3);
  // 멤버 수 기준 정렬
  groups.sort((a, b) => b.memberCount.compareTo(a.memberCount));
  return groups;
});

// 특정 소모임 상세
final groupDetailProvider = FutureProvider.autoDispose.family<GroupModel?, String>((ref, groupId) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getGroup(groupId);
});

// 소모임 상세 (alias)
final groupByIdProvider = groupDetailProvider;
