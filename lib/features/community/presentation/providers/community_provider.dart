import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../models/community_model.dart';

/// ============================================================
/// 커뮤니티(소모임) 관련 Provider
/// Firebase Firestore와 연동하여 소모임 데이터 관리
/// ============================================================

final _firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

// 공개 소모임 목록
final publicGroupsProvider = FutureProvider.autoDispose<List<GroupModel>>((ref) async {
  final firestoreService = ref.watch(_firestoreServiceProvider);
  return firestoreService.getPublicGroups(limit: 10);
});

// 인기 소모임 목록 (홈 화면용)
final popularGroupsProvider = FutureProvider.autoDispose<List<GroupModel>>((ref) async {
  final firestoreService = ref.watch(_firestoreServiceProvider);
  final groups = await firestoreService.getPublicGroups(limit: 3);
  // 멤버 수 기준 정렬
  groups.sort((a, b) => b.memberCount.compareTo(a.memberCount));
  return groups;
});

// 특정 소모임 상세
final groupDetailProvider = FutureProvider.autoDispose.family<GroupModel?, String>((ref, groupId) async {
  final firestoreService = ref.watch(_firestoreServiceProvider);
  return firestoreService.getGroup(groupId);
});
