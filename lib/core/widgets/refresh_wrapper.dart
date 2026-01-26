import 'package:flutter/material.dart';

/// ============================================================
/// MingrrRefreshWrapper - Pull to Refresh 래퍼
/// 
/// 모든 리스트 화면에서 일관된 Pull to Refresh 경험 제공
/// - 통일된 색상/스타일
/// - 커스터마이징 가능한 옵션
/// 
/// 사용법:
/// ```dart
/// MingrrRefreshWrapper(
///   color: context.features.chat,
///   onRefresh: () async {
///     ref.invalidate(userChatRoomsProvider);
///   },
///   child: ListView.builder(...),
/// )
/// ```
/// ============================================================

class MingrrRefreshWrapper extends StatelessWidget {
  /// 래핑할 스크롤 가능한 위젯 (ListView, GridView 등)
  final Widget child;
  
  /// 새로고침 콜백
  final Future<void> Function() onRefresh;
  
  /// 인디케이터 색상 (null이면 primary 색상 사용)
  final Color? color;
  
  /// 인디케이터 배경색 (null이면 surface 색상 사용)
  final Color? backgroundColor;
  
  /// 인디케이터 위치 오프셋
  final double displacement;
  
  /// 상단 엣지 오프셋 (AppBar 아래 시작 위치 조정)
  final double edgeOffset;
  
  /// 스트로크 너비
  final double strokeWidth;

  const MingrrRefreshWrapper({
    super.key,
    required this.child,
    required this.onRefresh,
    this.color,
    this.backgroundColor,
    this.displacement = 40.0,
    this.edgeOffset = 0.0,
    this.strokeWidth = 2.5,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return RefreshIndicator(
      color: color ?? colorScheme.primary,
      backgroundColor: backgroundColor ?? colorScheme.surface,
      displacement: displacement,
      edgeOffset: edgeOffset,
      strokeWidth: strokeWidth,
      onRefresh: onRefresh,
      child: child,
    );
  }
}
