import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_providers.dart' show firestoreServiceProvider;
import '../../features/auth/presentation/providers/auth_provider.dart';

/// ============================================================
/// 차단 관련 Provider
/// 
/// 차단된 사용자 목록을 관리하고, 필터링에 사용
/// ============================================================

/// 차단한 사용자 ID 목록 Provider (실시간 스트림)
final blockedUserIdsProvider = StreamProvider.autoDispose<List<String>>((ref) {
  final authState = ref.watch(authStateProvider);
  final userId = authState.valueOrNull?.uid;
  
  if (userId == null) {
    return Stream.value([]);
  }
  
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.watchBlockedUserIds(userId);
});

/// 차단한 사용자 ID 목록 (동기) - 필터링에 사용
final blockedUserIdsListProvider = Provider<List<String>>((ref) {
  final blockedAsync = ref.watch(blockedUserIdsProvider);
  return blockedAsync.valueOrNull ?? [];
});

/// 특정 사용자가 차단되었는지 확인
bool isUserBlocked(WidgetRef ref, String userId) {
  final blockedIds = ref.watch(blockedUserIdsListProvider);
  return blockedIds.contains(userId);
}

/// 리스트에서 차단된 사용자 필터링 헬퍼
/// 
/// 사용 예시:
/// ```dart
/// final filteredPets = filterBlockedUsers(
///   ref,
///   pets,
///   (pet) => pet.ownerId,
/// );
/// ```
List<T> filterBlockedUsers<T>(
  WidgetRef ref,
  List<T> items,
  String Function(T item) getOwnerId,
) {
  final blockedIds = ref.watch(blockedUserIdsListProvider);
  if (blockedIds.isEmpty) return items;
  
  return items.where((item) => !blockedIds.contains(getOwnerId(item))).toList();
}
