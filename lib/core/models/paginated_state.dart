import 'package:cloud_firestore/cloud_firestore.dart';

/// ============================================================
/// PaginatedState - 페이지네이션 상태 모델
///
/// 무한 스크롤 리스트의 상태를 관리하는 불변 모델
/// - items: 현재까지 로드된 아이템 목록
/// - isLoading: 로딩 중 여부
/// - hasMore: 추가 데이터 존재 여부
/// - lastDocument: 마지막 문서 (커서)
/// - error: 에러 정보
///
/// 사용법:
/// ```dart
/// final state = PaginatedState<PostModel>.initial();
/// final newState = state.copyWith(items: posts, hasMore: true);
/// ```
/// ============================================================

class PaginatedState<T> {
  /// 현재까지 로드된 아이템 목록
  final List<T> items;
  
  /// 로딩 중 여부 (초기 로딩 또는 추가 로딩)
  final bool isLoading;
  
  /// 초기 로딩 중 여부 (스켈레톤 표시용)
  final bool isInitialLoading;
  
  /// 추가 데이터 존재 여부
  final bool hasMore;
  
  /// 마지막 문서 스냅샷 (커서 기반 페이지네이션용)
  final DocumentSnapshot? lastDocument;
  
  /// 에러 정보
  final Object? error;

  const PaginatedState({
    required this.items,
    this.isLoading = false,
    this.isInitialLoading = false,
    this.hasMore = true,
    this.lastDocument,
    this.error,
  });

  /// 초기 상태 생성
  factory PaginatedState.initial() => PaginatedState<T>(
    items: [],
    isLoading: false,
    isInitialLoading: true,
    hasMore: true,
  );

  /// 로딩 중 상태
  factory PaginatedState.loading({List<T>? items}) => PaginatedState<T>(
    items: items ?? [],
    isLoading: true,
    isInitialLoading: items?.isEmpty ?? true,
    hasMore: true,
  );

  /// 에러 상태
  factory PaginatedState.error(Object error, {List<T>? items}) => PaginatedState<T>(
    items: items ?? [],
    isLoading: false,
    isInitialLoading: false,
    hasMore: false,
    error: error,
  );

  /// 상태 복사
  PaginatedState<T> copyWith({
    List<T>? items,
    bool? isLoading,
    bool? isInitialLoading,
    bool? hasMore,
    DocumentSnapshot? lastDocument,
    Object? error,
    bool clearError = false,
  }) {
    return PaginatedState<T>(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      hasMore: hasMore ?? this.hasMore,
      lastDocument: lastDocument ?? this.lastDocument,
      error: clearError ? null : (error ?? this.error),
    );
  }

  /// 데이터가 비어있는지 확인
  bool get isEmpty => items.isEmpty && !isLoading && !isInitialLoading;

  /// 데이터가 있는지 확인
  bool get hasData => items.isNotEmpty;

  /// 에러가 있는지 확인
  bool get hasError => error != null;

  @override
  String toString() {
    return 'PaginatedState(items: ${items.length}, isLoading: $isLoading, hasMore: $hasMore, error: $error)';
  }
}

/// 페이지네이션 결과 모델
class PaginatedResult<T> {
  /// 로드된 아이템 목록
  final List<T> items;
  
  /// 마지막 문서 스냅샷
  final DocumentSnapshot? lastDocument;
  
  /// 추가 데이터 존재 여부
  final bool hasMore;

  const PaginatedResult({
    required this.items,
    this.lastDocument,
    required this.hasMore,
  });

  /// 빈 결과
  factory PaginatedResult.empty() => PaginatedResult<T>(
    items: [],
    hasMore: false,
  );
}
