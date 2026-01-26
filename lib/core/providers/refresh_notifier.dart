import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ============================================================
/// RefreshNotifier - 리스트 새로고침 트리거 Provider
///
/// 등록/수정/삭제 후 리스트 화면을 자동으로 새로고침하기 위한 공통 패턴
/// 
/// 사용법:
/// ```dart
/// // 등록/수정/삭제 성공 시 (Write/Detail 화면)
/// ref.read(communityRefreshProvider.notifier).state++;
/// 
/// // 리스트 화면에서 listen
/// ref.listen(communityRefreshProvider, (prev, next) {
///   if (prev != next) {
///     ref.read(paginatedCommunityPostsProvider(category).notifier).refresh();
///   }
/// });
/// ```
/// ============================================================

/// 커뮤니티 새로고침 트리거
final communityRefreshProvider = StateProvider<int>((ref) => 0);

/// 마켓플레이스 (상품/알바) 새로고침 트리거
final marketRefreshProvider = StateProvider<int>((ref) => 0);

/// 데이팅 (교배) 새로고침 트리거
final datingRefreshProvider = StateProvider<int>((ref) => 0);

/// 소모임 새로고침 트리거
final groupRefreshProvider = StateProvider<int>((ref) => 0);

/// 반려동물 새로고침 트리거
final petRefreshProvider = StateProvider<int>((ref) => 0);

/// ============================================================
/// RefreshNotifier 헬퍼 함수
/// ============================================================

/// 새로고침 트리거 발동
/// [provider]: 새로고침할 Provider
void triggerRefresh(WidgetRef ref, StateProvider<int> provider) {
  ref.read(provider.notifier).state++;
}

/// 새로고침 트리거 발동 (Reader 버전 - Provider 내부에서 사용)
void triggerRefreshWithReader(Ref ref, StateProvider<int> provider) {
  ref.read(provider.notifier).state++;
}
