import 'package:flutter/material.dart';
import '../../constants/app_sizes.dart';

/// ============================================================
/// 페이지네이션 로딩 인디케이터
/// 
/// 무한 스크롤 목록 하단에 표시되는 공통 로딩 위젯입니다.
/// 
/// 사용처:
/// - marketplace_screen.dart (상품/알바 목록)
/// - community_screen.dart (게시글 목록)
/// - group_list_screen.dart (소모임 목록)
/// 
/// 사용 예시:
/// ```dart
/// if (index >= items.length) {
///   return const MingrrPaginationLoader();
/// }
/// ```
/// ============================================================
class MingrrPaginationLoader extends StatelessWidget {
  final double size;
  final double strokeWidth;
  final Color? color;

  const MingrrPaginationLoader({
    super.key,
    this.size = 24,
    this.strokeWidth = 2,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.paddingL),
      child: Center(
        child: SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: strokeWidth,
            color: color,
          ),
        ),
      ),
    );
  }
}
