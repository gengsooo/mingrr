import 'package:flutter/material.dart';
import '../constants/app_sizes.dart';
import '../theme/app_theme.dart';
import 'common_widgets.dart';

/// ============================================================
/// 성격&특성 배지 위젯
/// 
/// 크기별 variant: small, medium, large
/// - small: 카드 내 작은 태그 (데이팅 리스트 카드)
/// - medium: 일반적인 태그 (상세화면, 모달)
/// - large: 강조 태그 (프로필 편집 등)
/// 
/// 사용처:
/// - 데이팅 리스트 (small)
/// - 데이팅 상세화면 (medium)
/// - 반려동물 프로필 모달 (medium)
/// - 보호자 정보 모달 (medium)
/// - AI 추천 카드 (small)
/// ============================================================

/// 배지 크기 enum
enum TraitBadgeSize { small, medium, large }

/// 단일 특성 배지
class TraitBadge extends StatelessWidget {
  final String trait;
  final TraitBadgeSize size;

  const TraitBadge({
    super.key,
    required this.trait,
    this.size = TraitBadgeSize.medium,
  });

  /// 크기별 설정값
  double get _fontSize {
    switch (size) {
      case TraitBadgeSize.small:
        return 10;
      case TraitBadgeSize.medium:
        return 13;
      case TraitBadgeSize.large:
        return 15;
    }
  }

  EdgeInsets get _padding {
    switch (size) {
      case TraitBadgeSize.small:
        return const EdgeInsets.symmetric(horizontal: AppSizes.paddingS, vertical: 3);
      case TraitBadgeSize.medium:
        return const EdgeInsets.symmetric(horizontal: AppSizes.paddingM, vertical: AppSizes.paddingXS);
      case TraitBadgeSize.large:
        return const EdgeInsets.symmetric(horizontal: AppSizes.paddingL, vertical: AppSizes.paddingS);
    }
  }

  double get _borderRadius {
    switch (size) {
      case TraitBadgeSize.small:
        return 8;
      case TraitBadgeSize.medium:
        return 12;
      case TraitBadgeSize.large:
        return 16;
    }
  }

  FontWeight get _fontWeight {
    switch (size) {
      case TraitBadgeSize.small:
        return FontWeight.w400;
      case TraitBadgeSize.medium:
        return FontWeight.w500;
      case TraitBadgeSize.large:
        return FontWeight.w600;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: _padding,
      decoration: BoxDecoration(
        color: context.sectionBackground,
        borderRadius: BorderRadius.circular(_borderRadius),
      ),
      child: Text(
        trait,
        style: TextStyle(
          fontSize: _fontSize,
          fontWeight: _fontWeight,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}

/// 특성 배지 목록 (Wrap)
class TraitBadgeList extends StatelessWidget {
  final List<String> traits;
  final TraitBadgeSize size;
  final int? maxCount; // 최대 표시 개수 (null이면 전체 표시)

  const TraitBadgeList({
    super.key,
    required this.traits,
    this.size = TraitBadgeSize.medium,
    this.maxCount,
  });

  /// 크기별 간격
  double get _spacing {
    switch (size) {
      case TraitBadgeSize.small:
        return 4;
      case TraitBadgeSize.medium:
        return 8;
      case TraitBadgeSize.large:
        return 10;
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayTraits = maxCount != null 
        ? traits.take(maxCount!).toList() 
        : traits;
    
    return Wrap(
      spacing: _spacing,
      runSpacing: _spacing,
      children: displayTraits.map((trait) => TraitBadge(
        trait: trait,
        size: size,
      )).toList(),
    );
  }
}

/// 성격&특성 섹션 (제목 포함)
class TraitSection extends StatelessWidget {
  final String title;
  final List<String> traits;
  final TraitBadgeSize size;
  final int? maxCount;
  final bool showEmptyState;

  const TraitSection({
    super.key,
    this.title = '성격 & 특성',
    required this.traits,
    this.size = TraitBadgeSize.medium,
    this.maxCount,
    this.showEmptyState = false,
  });

  @override
  Widget build(BuildContext context) {
    // 빈 상태 처리
    if (traits.isEmpty) {
      if (!showEmptyState) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSizes.gapM),
          const MingrrEmptySection(
            icon: Icons.pets_outlined,
            message: '등록된 특성이 없어요',
            height: 60,
          ),
        ],
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSizes.gapM),
        TraitBadgeList(
          traits: traits,
          size: size,
          maxCount: maxCount,
        ),
      ],
    );
  }
}
