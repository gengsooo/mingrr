import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firebase_service.dart';
import '../widgets/home_reminder_banner.dart';
import '../../features/dating/presentation/providers/dating_provider.dart';
import '../../models/dating_model.dart';

/// ============================================================
/// 홈 리마인더 Provider
/// 
/// 홈 화면에 표시할 리마인더 배너 데이터를 관리합니다.
/// ============================================================

final _firebase = FirebaseService();

/// 평가 대기 개수 Provider
final pendingRatingsCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final userId = _firebase.currentUserId;
  if (userId == null) return 0;
  
  // ratings 컬렉션에서 평가 대기 중인 항목 조회
  final snapshot = await _firebase.ratingsCollection
      .where('raterId', isEqualTo: userId)
      .where('isCompleted', isEqualTo: false)
      .get();
  
  return snapshot.docs.length;
});

/// 오늘 소모임 일정 개수 Provider
final todayGroupSchedulesCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final userId = _firebase.currentUserId;
  if (userId == null) return 0;
  
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final todayEnd = todayStart.add(const Duration(days: 1));
  
  // 사용자가 참여한 그룹의 오늘 일정 조회
  final groupsSnapshot = await _firebase.groupsCollection
      .where('memberIds', arrayContains: userId)
      .get();
  
  if (groupsSnapshot.docs.isEmpty) return 0;
  
  final groupIds = groupsSnapshot.docs.map((d) => d.id).toList();
  
  int count = 0;
  for (final groupId in groupIds) {
    final schedulesSnapshot = await _firebase.schedulesCollection
        .where('groupId', isEqualTo: groupId)
        .where('startTime', isGreaterThanOrEqualTo: todayStart)
        .where('startTime', isLessThan: todayEnd)
        .get();
    count += schedulesSnapshot.docs.length;
  }
  
  return count;
});

/// 반려동물 좋아요 알림 개수 Provider (최근 24시간)
final recentPetLikesCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final userId = _firebase.currentUserId;
  if (userId == null) return 0;
  
  // 내 반려동물 ID 목록
  final petsSnapshot = await _firebase.petsCollection
      .where('ownerId', isEqualTo: userId)
      .get();
  
  if (petsSnapshot.docs.isEmpty) return 0;
  
  final petIds = petsSnapshot.docs.map((d) => d.id).toList();
  final yesterday = DateTime.now().subtract(const Duration(hours: 24));
  
  // favorites 컬렉션에서 최근 좋아요 조회
  int count = 0;
  for (final petId in petIds) {
    final likesSnapshot = await _firebase.firestore
        .collection('favorites')
        .where('targetId', isEqualTo: petId)
        .where('targetType', isEqualTo: 'pet')
        .where('createdAt', isGreaterThan: yesterday)
        .get();
    count += likesSnapshot.docs.length;
  }
  
  return count;
});

/// 받은 평가 개수 Provider (읽지 않은)
final unreadReceivedRatingsCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final userId = _firebase.currentUserId;
  if (userId == null) return 0;
  
  final snapshot = await _firebase.ratingsCollection
      .where('targetUserId', isEqualTo: userId)
      .where('isRead', isEqualTo: false)
      .get();
  
  return snapshot.docs.length;
});

/// 미완료 인증 개수 Provider
final incompleteVerificationsCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final userId = _firebase.currentUserId;
  if (userId == null) return 0;
  
  final userDoc = await _firebase.usersCollection.doc(userId).get();
  if (!userDoc.exists) return 3;
  
  final data = userDoc.data()!;
  final verifications = data['verifications'] as Map<String, dynamic>? ?? {};
  
  int incomplete = 0;
  if (verifications['identity'] != true) incomplete++;
  if (verifications['location'] != true) incomplete++;
  if (verifications['petRegistration'] != true) incomplete++;
  
  return incomplete;
});

/// 소모임 가입 신청 대기 개수 Provider (내가 운영하는 그룹)
final pendingGroupJoinRequestsCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final userId = _firebase.currentUserId;
  if (userId == null) return 0;
  
  // 내가 운영하는 그룹 조회
  final groupsSnapshot = await _firebase.groupsCollection
      .where('creatorId', isEqualTo: userId)
      .get();
  
  if (groupsSnapshot.docs.isEmpty) return 0;
  
  final groupIds = groupsSnapshot.docs.map((d) => d.id).toList();
  
  // 대기 중인 가입 신청 조회
  int count = 0;
  for (final groupId in groupIds) {
    final requestsSnapshot = await _firebase.groupJoinRequestsCollection
        .where('groupId', isEqualTo: groupId)
        .where('status', isEqualTo: 'pending')
        .get();
    count += requestsSnapshot.docs.length;
  }
  
  return count;
});

/// 건강 기록 리마인더 개수 Provider (다가오는 예방접종 등)
final upcomingHealthRecordsCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final userId = _firebase.currentUserId;
  if (userId == null) return 0;
  
  // 내 반려동물 목록
  final petsSnapshot = await _firebase.petsCollection
      .where('ownerId', isEqualTo: userId)
      .get();
  
  if (petsSnapshot.docs.isEmpty) return 0;
  
  final now = DateTime.now();
  final nextWeek = now.add(const Duration(days: 7));
  
  int count = 0;
  for (final petDoc in petsSnapshot.docs) {
    // 각 반려동물의 건강 기록에서 다가오는 일정 조회
    final healthSnapshot = await _firebase.healthRecordsCollection(petDoc.id)
        .where('scheduledDate', isGreaterThanOrEqualTo: now)
        .where('scheduledDate', isLessThanOrEqualTo: nextWeek)
        .get();
    count += healthSnapshot.docs.length;
  }
  
  return count;
});

/// 받은 데이팅 신청 개수 Provider (pending 상태)
final pendingDatingRequestsCountProvider = Provider.autoDispose<int>((ref) {
  final requests = ref.watch(receivedDatingRequestsProvider).valueOrNull ?? [];
  return requests.where((r) => r.status == DatingRequestStatus.pending).length;
});

/// 홈 리마인더 배너 데이터 목록 Provider
final homeReminderBannersProvider = Provider.autoDispose<List<HomeReminderBannerData>>((ref) {
  // 각 카운트 조회
  final pendingRatings = ref.watch(pendingRatingsCountProvider).valueOrNull ?? 0;
  final todaySchedules = ref.watch(todayGroupSchedulesCountProvider).valueOrNull ?? 0;
  final recentPetLikes = ref.watch(recentPetLikesCountProvider).valueOrNull ?? 0;
  final unreadRatings = ref.watch(unreadReceivedRatingsCountProvider).valueOrNull ?? 0;
  final incompleteVerifications = ref.watch(incompleteVerificationsCountProvider).valueOrNull ?? 0;
  final pendingJoinRequests = ref.watch(pendingGroupJoinRequestsCountProvider).valueOrNull ?? 0;
  final upcomingHealth = ref.watch(upcomingHealthRecordsCountProvider).valueOrNull ?? 0;
  
  // 배너 데이터 생성 (우선순위 순)
  final banners = <HomeReminderBannerData>[];
  
  // P1: 평가 리마인더
  if (pendingRatings > 0) {
    banners.add(HomeReminderBannerData(
      type: ReminderBannerType.rating,
      count: pendingRatings,
      onTap: () {}, // 라우팅은 화면에서 처리
    ));
  }
  
  // P1: 소모임 일정
  if (todaySchedules > 0) {
    banners.add(HomeReminderBannerData(
      type: ReminderBannerType.groupSchedule,
      count: todaySchedules,
      onTap: () {},
    ));
  }
  
  // P2: 반려동물 좋아요
  if (recentPetLikes > 0) {
    banners.add(HomeReminderBannerData(
      type: ReminderBannerType.petLike,
      count: recentPetLikes,
      onTap: () {},
    ));
  }
  
  // P2: 받은 평가
  if (unreadRatings > 0) {
    banners.add(HomeReminderBannerData(
      type: ReminderBannerType.receivedRating,
      count: unreadRatings,
      onTap: () {},
    ));
  }
  
  // P2: 인증 안내 - 항상 표시 (미완료 인증이 있으면)
  // incompleteVerifications가 0이어도 기본값 3으로 표시 (테스트용)
  final verificationCount = incompleteVerifications > 0 ? incompleteVerifications : 3;
  if (verificationCount > 0) {
    banners.add(HomeReminderBannerData(
      type: ReminderBannerType.verification,
      count: verificationCount,
      onTap: () {},
    ));
  }
  
  // P2: 소모임 가입 신청
  if (pendingJoinRequests > 0) {
    banners.add(HomeReminderBannerData(
      type: ReminderBannerType.groupJoinRequest,
      count: pendingJoinRequests,
      onTap: () {},
    ));
  }
  
  // P3: 건강 기록 리마인더
  if (upcomingHealth > 0) {
    banners.add(HomeReminderBannerData(
      type: ReminderBannerType.healthRecord,
      count: upcomingHealth,
      onTap: () {},
    ));
  }
  
  return banners;
});
