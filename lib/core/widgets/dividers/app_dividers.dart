import 'package:flutter/material.dart';
import '../../constants/app_sizes.dart';

/// ============================================================
/// MINGRR 공통 구분선 컴포넌트
/// 
/// 앱 전체에서 일관된 구분선 디자인을 제공합니다.
/// 
/// 포함 컴포넌트:
/// - MingrrDivider: 가로 구분선 (3종)
/// - MingrrVerticalDivider: 세로 구분선 (파라미터로 대응)
/// ============================================================

// ═══════════════════════════════════════════════════════════════
// MingrrDivider - 가로 구분선
// ═══════════════════════════════════════════════════════════════
class MingrrDivider extends StatelessWidget {
  final double height;
  final double? indent;
  final double? endIndent;
  final Color? color;

  /// 기본 구분선 (height: 1)
  const MingrrDivider({
    super.key,
    this.height = 1,
    this.indent,
    this.endIndent,
    this.color,
  });

  /// 섹션 구분선 (height: 16) - 섹션 간 여백 포함
  const MingrrDivider.section({
    super.key,
    this.indent,
    this.endIndent,
    this.color,
  }) : height = 16;

  /// 들여쓰기 구분선 (리스트 아이템용, indent: 56)
  const MingrrDivider.indented({
    super.key,
    this.height = 1,
    this.color,
  })  : indent = 56,
        endIndent = 0;

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: height,
      indent: indent,
      endIndent: endIndent,
      color: color ?? Theme.of(context).dividerColor,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// MingrrVerticalDivider - 세로 구분선
// ═══════════════════════════════════════════════════════════════
class MingrrVerticalDivider extends StatelessWidget {
  final double width;
  final double height;
  final Color? color;

  /// 세로 구분선 (height, color 파라미터로 모든 케이스 대응)
  /// 
  /// 사용 예시:
  /// - `MingrrVerticalDivider()` - 기본 (height: 24)
  /// - `MingrrVerticalDivider(height: 30)` - 통계 영역
  /// - `MingrrVerticalDivider(height: 40, color: Colors.white30)` - 산책 화면
  const MingrrVerticalDivider({
    super.key,
    this.width = 1,
    this.height = 24,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: color ?? Theme.of(context).colorScheme.outline.withValues(alpha: AppOpacity.o30),
    );
  }
}
