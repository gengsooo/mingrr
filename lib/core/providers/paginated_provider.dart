import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/paginated_state.dart';

/// ============================================================
/// PaginatedNotifier - 페이지네이션 상태 관리자
///
/// 무한 스크롤 리스트의 상태를 관리하는 StateNotifier
/// - 초기 로딩 (loadInitial)
/// - 추가 로딩 (loadMore)
/// - 새로고침 (refresh)
/// - 캐싱 지원 (keepAlive)
///
/// 사용법:
/// ```dart
/// final postsProvider = StateNotifierProvider<
///   PaginatedNotifier<PostModel>,
///   PaginatedState<PostModel>
/// >((ref) {
///   // 캐싱 활성화 (화면 전환 시 상태 유지)
///   ref.keepAlive();
///   
///   return PaginatedNotifier(
///     fetchPage: (lastDoc, pageSize) async {
///       // Firestore 쿼리 실행
///       return PaginatedResult(...);
///     },
///   );
/// });
/// ```
/// ============================================================

/// 페이지네이션 Notifier
class PaginatedNotifier<T> extends StateNotifier<PaginatedState<T>> {
  /// 페이지 데이터를 가져오는 함수
  final Future<PaginatedResult<T>> Function(
    DocumentSnapshot? lastDocument,
    int pageSize,
  ) fetchPage;

  /// 페이지 크기 (기본값: 20)
  final int pageSize;

  /// 자동 초기 로딩 여부
  final bool autoLoad;

  PaginatedNotifier({
    required this.fetchPage,
    this.pageSize = 20,
    this.autoLoad = true,
  }) : super(PaginatedState.initial()) {
    if (autoLoad) {
      loadInitial();
    }
  }

  /// 초기 데이터 로딩
  Future<void> loadInitial() async {
    if (state.isLoading) return;

    state = state.copyWith(
      isLoading: true,
      isInitialLoading: true,
      clearError: true,
    );

    try {
      final result = await fetchPage(null, pageSize);

      state = PaginatedState(
        items: result.items,
        isLoading: false,
        isInitialLoading: false,
        hasMore: result.hasMore,
        lastDocument: result.lastDocument,
      );
    } catch (e) {
      state = PaginatedState.error(e);
    }
  }

  /// 추가 데이터 로딩 (무한 스크롤)
  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);

    try {
      final result = await fetchPage(state.lastDocument, pageSize);

      state = state.copyWith(
        items: [...state.items, ...result.items],
        isLoading: false,
        hasMore: result.hasMore,
        lastDocument: result.lastDocument,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e,
      );
    }
  }

  /// 새로고침 (Pull to Refresh)
  Future<void> refresh() async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      final result = await fetchPage(null, pageSize);

      state = PaginatedState(
        items: result.items,
        isLoading: false,
        isInitialLoading: false,
        hasMore: result.hasMore,
        lastDocument: result.lastDocument,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e,
      );
    }
  }

  /// 아이템 추가 (로컬)
  void addItem(T item, {bool prepend = true}) {
    if (prepend) {
      state = state.copyWith(items: [item, ...state.items]);
    } else {
      state = state.copyWith(items: [...state.items, item]);
    }
  }

  /// 아이템 제거 (로컬)
  void removeItem(bool Function(T) test) {
    state = state.copyWith(
      items: state.items.where((item) => !test(item)).toList(),
    );
  }

  /// 아이템 업데이트 (로컬)
  void updateItem(bool Function(T) test, T Function(T) update) {
    state = state.copyWith(
      items: state.items.map((item) => test(item) ? update(item) : item).toList(),
    );
  }

  /// 상태 초기화
  void reset() {
    state = PaginatedState.initial();
  }
}

/// 클라이언트 사이드 페이지네이션 Notifier
/// 전체 데이터를 로드한 후 클라이언트에서 페이지 분할
class ClientPaginatedNotifier<T> extends StateNotifier<PaginatedState<T>> {
  /// 전체 데이터를 가져오는 함수
  final Future<List<T>> Function() fetchAll;

  /// 페이지 크기
  final int pageSize;

  /// 전체 데이터 캐시
  List<T> _allItems = [];

  /// 현재 표시된 아이템 수
  int _displayedCount = 0;

  ClientPaginatedNotifier({
    required this.fetchAll,
    this.pageSize = 20,
  }) : super(PaginatedState.initial()) {
    loadInitial();
  }

  /// 초기 데이터 로딩
  Future<void> loadInitial() async {
    if (state.isLoading) return;

    state = state.copyWith(
      isLoading: true,
      isInitialLoading: true,
      clearError: true,
    );

    try {
      _allItems = await fetchAll();
      _displayedCount = _allItems.length > pageSize ? pageSize : _allItems.length;

      state = PaginatedState(
        items: _allItems.take(_displayedCount).toList(),
        isLoading: false,
        isInitialLoading: false,
        hasMore: _displayedCount < _allItems.length,
      );
    } catch (e) {
      state = PaginatedState.error(e);
    }
  }

  /// 추가 데이터 로딩 (클라이언트 사이드)
  void loadMore() {
    if (state.isLoading || !state.hasMore) return;

    final newCount = (_displayedCount + pageSize).clamp(0, _allItems.length);
    _displayedCount = newCount;

    state = state.copyWith(
      items: _allItems.take(_displayedCount).toList(),
      hasMore: _displayedCount < _allItems.length,
    );
  }

  /// 새로고침
  Future<void> refresh() async {
    _allItems = [];
    _displayedCount = 0;
    await loadInitial();
  }

  /// 전체 아이템 수
  int get totalCount => _allItems.length;

  /// 표시된 아이템 수
  int get displayedCount => _displayedCount;
}
