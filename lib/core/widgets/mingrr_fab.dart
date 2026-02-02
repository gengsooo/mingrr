import 'package:flutter/material.dart';
import '../constants/app_icons.dart';
import '../constants/app_sizes.dart';

/// ============================================================
/// MINGRR 공통 FAB (Floating Action Button)
/// 
/// 앱 전체에서 통일된 FAB 스타일을 제공합니다.
/// 
/// 사용 예시:
/// ```dart
/// // 글쓰기 FAB
/// MingrrFAB.write(
///   onPressed: () => _navigateToWrite(context),
///   backgroundColor: context.features.social,
/// )
/// 
/// // 추가 FAB
/// MingrrFAB.add(
///   onPressed: () => _showAddSheet(context),
///   backgroundColor: context.features.health,
/// )
/// 
/// // 커스텀 FAB
/// MingrrFAB(
///   icon: Icons.camera_alt,
///   onPressed: () => _openCamera(),
///   backgroundColor: Colors.blue,
/// )
/// ```
/// ============================================================

/// FAB 타입 정의
enum MingrrFABType {
  /// 글쓰기/편집 (Icons.edit)
  write,
  /// 추가 (Icons.add)
  add,
  /// 현재 위치 (Icons.my_location)
  location,
  /// 커스텀 아이콘
  custom,
}

/// FAB 크기 정의
enum MingrrFABSize {
  /// 기본 크기 (56x56)
  regular,
  /// 작은 크기 (40x40)
  small,
  /// 확장형 (텍스트 포함)
  extended,
}

class MingrrFAB extends StatelessWidget {
  /// FAB 아이콘
  final IconData icon;
  
  /// 클릭 콜백
  final VoidCallback? onPressed;
  
  /// 배경색 (null이면 테마 primary 사용)
  final Color? backgroundColor;
  
  /// 아이콘 색상 (null이면 흰색 사용)
  final Color? iconColor;
  
  /// Hero 태그 (같은 화면에 여러 FAB가 있을 때 필수)
  final String? heroTag;
  
  /// FAB 크기
  final MingrrFABSize size;
  
  /// 확장형 FAB 라벨 (size가 extended일 때만 사용)
  final String? label;
  
  /// 그림자 높이
  final double elevation;
  
  /// 툴팁 텍스트
  final String? tooltip;
  
  /// 조건부 표시 여부 (false면 null 반환)
  final bool visible;

  const MingrrFAB({
    super.key,
    required this.icon,
    required this.onPressed,
    this.backgroundColor,
    this.iconColor,
    this.heroTag,
    this.size = MingrrFABSize.regular,
    this.label,
    this.elevation = 6.0,
    this.tooltip,
    this.visible = true,
  });

  /// 글쓰기/편집 FAB (Icons.edit)
  /// 
  /// 사용처: 데이팅(교배), 마켓(상품/알바), 커뮤니티(게시글)
  factory MingrrFAB.write({
    Key? key,
    required VoidCallback? onPressed,
    Color? backgroundColor,
    String? heroTag,
    String? tooltip,
    bool visible = true,
  }) {
    return MingrrFAB(
      key: key,
      icon: AppIcons.edit,
      onPressed: onPressed,
      backgroundColor: backgroundColor,
      heroTag: heroTag,
      tooltip: tooltip ?? '글쓰기',
      visible: visible,
    );
  }

  /// 추가 FAB (AppIcons.add)
  /// 
  /// 사용처: 소모임(모임 생성), 건강수첩(기록 추가)
  factory MingrrFAB.add({
    Key? key,
    required VoidCallback? onPressed,
    Color? backgroundColor,
    String? heroTag,
    String? tooltip,
    bool visible = true,
  }) {
    return MingrrFAB(
      key: key,
      icon: AppIcons.add,
      onPressed: onPressed,
      backgroundColor: backgroundColor,
      heroTag: heroTag,
      tooltip: tooltip ?? '추가',
      visible: visible,
    );
  }

  /// 현재 위치 FAB (AppIcons.myLocation)
  /// 
  /// 사용처: 산책 화면 (지도 위 현재 위치 버튼)
  /// 기본적으로 small 사이즈, surface 배경색 사용
  factory MingrrFAB.location({
    Key? key,
    required VoidCallback? onPressed,
    Color? backgroundColor,
    Color? iconColor,
    String? heroTag,
    String? tooltip,
    bool visible = true,
  }) {
    return MingrrFAB(
      key: key,
      icon: AppIcons.myLocation,
      onPressed: onPressed,
      backgroundColor: backgroundColor,
      iconColor: iconColor,
      heroTag: heroTag,
      size: MingrrFABSize.small,
      elevation: AppSizes.elevationM,
      tooltip: tooltip ?? '현재 위치',
      visible: visible,
    );
  }

  /// 확장형 FAB (아이콘 + 텍스트)
  /// 
  /// 사용처: 강조가 필요한 주요 액션
  factory MingrrFAB.extended({
    Key? key,
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    Color? backgroundColor,
    String? heroTag,
    String? tooltip,
    bool visible = true,
  }) {
    return MingrrFAB(
      key: key,
      icon: icon,
      onPressed: onPressed,
      backgroundColor: backgroundColor,
      heroTag: heroTag,
      size: MingrrFABSize.extended,
      label: label,
      tooltip: tooltip,
      visible: visible,
    );
  }

  @override
  Widget build(BuildContext context) {
    // visible이 false면 null 반환 (FAB 숨김)
    if (!visible) return const SizedBox.shrink();
    
    final colorScheme = Theme.of(context).colorScheme;
    final bgColor = backgroundColor ?? colorScheme.primary;
    final fgColor = iconColor ?? Colors.white;
    
    // 확장형 FAB
    if (size == MingrrFABSize.extended && label != null) {
      return FloatingActionButton.extended(
        heroTag: heroTag,
        onPressed: onPressed,
        backgroundColor: bgColor,
        foregroundColor: fgColor,
        elevation: elevation,
        tooltip: tooltip,
        icon: Icon(icon),
        label: Text(
          label!,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    
    // 작은 FAB
    if (size == MingrrFABSize.small) {
      return FloatingActionButton.small(
        heroTag: heroTag,
        onPressed: onPressed,
        backgroundColor: bgColor,
        foregroundColor: fgColor,
        elevation: elevation,
        tooltip: tooltip,
        child: Icon(icon, size: 20),
      );
    }
    
    // 기본 FAB
    return FloatingActionButton(
      heroTag: heroTag,
      onPressed: onPressed,
      backgroundColor: bgColor,
      foregroundColor: fgColor,
      elevation: elevation,
      tooltip: tooltip,
      shape: const CircleBorder(),
      child: Icon(icon, color: fgColor),
    );
  }
}

/// FAB를 조건부로 표시하는 헬퍼 위젯
/// 
/// AsyncValue 등과 함께 사용할 때 유용합니다.
/// 
/// 사용 예시:
/// ```dart
/// floatingActionButton: MingrrFABBuilder(
///   condition: petsAsync.maybeWhen(
///     data: (pets) => pets.isNotEmpty,
///     orElse: () => false,
///   ),
///   builder: (context) => MingrrFAB.add(
///     onPressed: () => _showAddSheet(context),
///     backgroundColor: context.features.health,
///   ),
/// ),
/// ```
class MingrrFABBuilder extends StatelessWidget {
  /// FAB 표시 조건
  final bool condition;
  
  /// FAB 빌더
  final WidgetBuilder builder;

  const MingrrFABBuilder({
    super.key,
    required this.condition,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    if (!condition) return const SizedBox.shrink();
    return builder(context);
  }
}

/// 여러 FAB를 함께 배치하는 컨테이너
/// 
/// 지도 화면 등에서 여러 FAB를 세로로 배치할 때 사용합니다.
/// 
/// 사용 예시:
/// ```dart
/// MingrrFABColumn(
///   children: [
///     MingrrFAB.location(
///       onPressed: _goToMyLocation,
///       backgroundColor: colorScheme.surface,
///       iconColor: context.features.walk,
///       heroTag: 'walkMyLocation',
///     ),
///     MingrrFAB.add(
///       onPressed: _startWalk,
///       backgroundColor: context.features.walk,
///       heroTag: 'walkStart',
///     ),
///   ],
/// )
/// ```
class MingrrFABColumn extends StatelessWidget {
  /// FAB 목록
  final List<Widget> children;
  
  /// FAB 간 간격
  final double spacing;
  
  /// 정렬 방향 (기본: 아래에서 위로)
  final MainAxisAlignment mainAxisAlignment;

  const MingrrFABColumn({
    super.key,
    required this.children,
    this.spacing = AppSizes.gapM,
    this.mainAxisAlignment = MainAxisAlignment.end,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: mainAxisAlignment,
      children: [
        for (int i = 0; i < children.length; i++) ...[
          children[i],
          if (i < children.length - 1) SizedBox(height: spacing),
        ],
      ],
    );
  }
}
