import 'package:flutter/material.dart';
import '../constants/location_constants.dart';

/// ============================================================
/// 거리 표시 배지 공통 위젯
/// 
/// 앱 전체에서 거리 정보를 일관되게 표시하기 위한 공통 컴포넌트
/// 
/// 사용처:
/// - ProductCard (상품 카드)
/// - JobCard (알바 카드)
/// - DatingCard (데이팅 카드)
/// - GroupListScreen (소모임 목록)
/// - 상세화면 헤더
/// ============================================================

/// 거리 배지 크기
enum DistanceBadgeSize {
  small(12, 11),
  medium(14, 12),
  large(16, 14);

  final double iconSize;
  final double fontSize;

  const DistanceBadgeSize(this.iconSize, this.fontSize);
}

/// 거리 표시 배지
/// 
/// [distanceString]: 표시할 거리 문자열 (예: "1.2km", "300m")
/// [size]: 배지 크기 (small, medium, large)
/// [color]: 아이콘 및 텍스트 색상 (기본: Theme.colorScheme.outline)
/// [showIcon]: 아이콘 표시 여부 (기본: true)
class DistanceBadge extends StatelessWidget {
  final String distanceString;
  final DistanceBadgeSize size;
  final Color? color;
  final bool showIcon;

  const DistanceBadge({
    super.key,
    required this.distanceString,
    this.size = DistanceBadgeSize.small,
    this.color,
    this.showIcon = true,
  });

  /// 작은 크기 배지 (리스트 아이템용)
  const DistanceBadge.small({
    super.key,
    required this.distanceString,
    this.color,
    this.showIcon = true,
  }) : size = DistanceBadgeSize.small;

  /// 중간 크기 배지 (카드용)
  const DistanceBadge.medium({
    super.key,
    required this.distanceString,
    this.color,
    this.showIcon = true,
  }) : size = DistanceBadgeSize.medium;

  /// 큰 크기 배지 (상세화면용)
  const DistanceBadge.large({
    super.key,
    required this.distanceString,
    this.color,
    this.showIcon = true,
  }) : size = DistanceBadgeSize.large;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.outline;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showIcon) ...[
          Icon(
            LocationConstants.distanceIcon,
            size: size.iconSize,
            color: effectiveColor,
          ),
          const SizedBox(width: 2),
        ],
        Text(
          distanceString,
          style: TextStyle(
            fontSize: size.fontSize,
            color: effectiveColor,
          ),
        ),
      ],
    );
  }
}

/// 거리 + 구분자 + 시간 표시 위젯
/// 
/// 리스트 아이템에서 "1.2km · 3분 전" 형태로 표시할 때 사용
class DistanceTimeText extends StatelessWidget {
  final String distanceString;
  final String timeString;
  final DistanceBadgeSize size;
  final Color? color;
  final String separator;

  const DistanceTimeText({
    super.key,
    required this.distanceString,
    required this.timeString,
    this.size = DistanceBadgeSize.small,
    this.color,
    this.separator = ' · ',
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.outline;

    return Text(
      '$distanceString$separator$timeString',
      style: TextStyle(
        fontSize: size.fontSize,
        color: effectiveColor,
      ),
    );
  }
}
