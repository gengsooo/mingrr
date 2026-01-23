import 'package:flutter/material.dart';
import '../../constants/app_sizes.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../common_widgets.dart';

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
enum TraitBadgeSize {
  small,
  medium,
  large;
  
  /// 크기별 TextStyle 반환
  TextStyle getTextStyle(BuildContext context) {
    switch (this) {
      case TraitBadgeSize.small:
        return AppTextStyles.labelSmall(context);   // 10px
      case TraitBadgeSize.medium:
        return AppTextStyles.bodyMedium(context);   // 13px
      case TraitBadgeSize.large:
        return AppTextStyles.titleLarge(context);   // 15px
    }
  }
  
  /// 크기별 BorderRadius 반환
  double get borderRadius {
    switch (this) {
      case TraitBadgeSize.small:
        return AppSizes.radiusS;
      case TraitBadgeSize.medium:
        return AppSizes.radiusM;
      case TraitBadgeSize.large:
        return AppSizes.radiusL;
    }
  }
}

/// 단일 특성 배지
class TraitBadge extends StatelessWidget {
  final String trait;
  final TraitBadgeSize size;

  const TraitBadge({
    super.key,
    required this.trait,
    this.size = TraitBadgeSize.medium,
  });

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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: _padding,
      decoration: BoxDecoration(
        color: context.sectionBackground,
        borderRadius: BorderRadius.circular(size.borderRadius),
      ),
      child: Text(
        trait,
        style: size.getTextStyle(context),
      ),
    );
  }
}

/// 특성 배지 목록 (Wrap)
/// 
/// [maxCount]가 설정되고 traits 개수가 초과하면 "+N" 배지 표시
class TraitBadgeList extends StatelessWidget {
  final List<String> traits;
  final TraitBadgeSize size;
  final int? maxCount; // 최대 표시 개수 (null이면 전체 표시)
  final bool showOverflowCount; // +N 표시 여부 (기본: true)

  const TraitBadgeList({
    super.key,
    required this.traits,
    this.size = TraitBadgeSize.medium,
    this.maxCount,
    this.showOverflowCount = true,
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
    final hasOverflow = maxCount != null && traits.length > maxCount!;
    final displayTraits = maxCount != null 
        ? traits.take(maxCount!).toList() 
        : traits;
    final overflowCount = hasOverflow ? traits.length - maxCount! : 0;
    
    return Wrap(
      spacing: _spacing,
      runSpacing: _spacing,
      children: [
        ...displayTraits.map((trait) => TraitBadge(
          trait: trait,
          size: size,
        )),
        // +N 배지 표시
        if (hasOverflow && showOverflowCount)
          _OverflowBadge(count: overflowCount, size: size),
      ],
    );
  }
}

/// +N 오버플로우 배지
class _OverflowBadge extends StatelessWidget {
  final int count;
  final TraitBadgeSize size;

  const _OverflowBadge({required this.count, required this.size});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: size == TraitBadgeSize.small ? 6 : 8,
        vertical: size == TraitBadgeSize.small ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSizes.radiusS),
      ),
      child: Text(
        '+$count',
        style: (size == TraitBadgeSize.small 
            ? AppTextStyles.captionSmall(context) 
            : AppTextStyles.caption(context))
            .withColor(colorScheme.onSurfaceVariant),
      ),
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
            style: AppTextStyles.headlineSmall(context),
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
          style: AppTextStyles.headlineSmall(context),
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
