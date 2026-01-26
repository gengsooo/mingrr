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
          OverflowBadge(count: overflowCount, size: size),
      ],
    );
  }
}

/// +N 오버플로우 배지
class OverflowBadge extends StatelessWidget {
  final int count;
  final TraitBadgeSize size;

  const OverflowBadge({super.key, required this.count, required this.size});

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

/// ------------------------------------------------------------
/// 카드용 특성 배지 목록 (하단 정렬, 최대 2줄)
/// 
/// 카드 내에서 사용하는 특성 배지 목록
/// - 하단에서부터 채워짐 (Column + MainAxisAlignment.end)
/// - 최대 2줄까지 표시
/// - 2줄 초과 시 +N 표시
/// 
/// 사용처: DatingNearbyCard, DatingRecommendCard 등
/// ------------------------------------------------------------
class TraitBadgeListCompact extends StatelessWidget {
  final List<String> traits;
  final TraitBadgeSize size;
  final double maxWidth;

  const TraitBadgeListCompact({
    super.key,
    required this.traits,
    this.size = TraitBadgeSize.small,
    this.maxWidth = double.infinity,
  });

  /// 크기별 간격
  double get _spacing {
    switch (size) {
      case TraitBadgeSize.small:
        return 4;
      case TraitBadgeSize.medium:
        return 6;
      case TraitBadgeSize.large:
        return 8;
    }
  }

  /// 크기별 배지 높이 (패딩 포함)
  double get _badgeHeight {
    switch (size) {
      case TraitBadgeSize.small:
        return 22; // 10px font + 6px vertical padding
      case TraitBadgeSize.medium:
        return 28;
      case TraitBadgeSize.large:
        return 34;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (traits.isEmpty) return const SizedBox.shrink();

    // 최대 2줄 높이 계산
    final maxHeight = (_badgeHeight * 2) + _spacing;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: maxHeight,
        maxWidth: maxWidth,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return _TraitBadgeFlow(
            traits: traits,
            size: size,
            spacing: _spacing,
            badgeHeight: _badgeHeight,
            maxWidth: constraints.maxWidth,
          );
        },
      ),
    );
  }
}

/// 배지 Flow 레이아웃 (내부 위젯)
class _TraitBadgeFlow extends StatelessWidget {
  final List<String> traits;
  final TraitBadgeSize size;
  final double spacing;
  final double badgeHeight;
  final double maxWidth;

  const _TraitBadgeFlow({
    required this.traits,
    required this.size,
    required this.spacing,
    required this.badgeHeight,
    required this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    // 배지들을 2줄에 맞게 계산
    final result = _calculateVisibleBadges(context);
    final visibleTraits = result.visibleTraits;
    final overflowCount = result.overflowCount;

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            ...visibleTraits.map((trait) => TraitBadge(
              trait: trait,
              size: size,
            )),
            if (overflowCount > 0)
              OverflowBadge(count: overflowCount, size: size),
          ],
        ),
      ],
    );
  }

  /// 2줄에 들어갈 수 있는 배지 수 계산
  _BadgeCalculationResult _calculateVisibleBadges(BuildContext context) {
    if (traits.isEmpty) {
      return _BadgeCalculationResult(visibleTraits: [], overflowCount: 0);
    }

    // 배지 너비 추정 (텍스트 길이 기반)
    final textStyle = size.getTextStyle(context);
    final horizontalPadding = size == TraitBadgeSize.small ? 16.0 : 24.0;
    
    // +N 배지 너비 (대략적인 값)
    const overflowBadgeWidth = 32.0;

    List<String> visibleTraits = [];
    double currentLineWidth = 0;
    int currentLine = 1;
    const maxLines = 2;

    for (int i = 0; i < traits.length; i++) {
      final trait = traits[i];
      
      // 텍스트 너비 측정
      final textPainter = TextPainter(
        text: TextSpan(text: trait, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      
      final badgeWidth = textPainter.width + horizontalPadding;
      
      // 현재 줄에 들어갈 수 있는지 확인
      if (currentLineWidth + badgeWidth + spacing <= maxWidth) {
        visibleTraits.add(trait);
        currentLineWidth += badgeWidth + spacing;
      } else if (currentLine < maxLines) {
        // 다음 줄로
        currentLine++;
        currentLineWidth = badgeWidth + spacing;
        visibleTraits.add(trait);
      } else {
        // 2줄 초과 - 마지막 배지를 제거하고 +N 배지 공간 확보
        // +N 배지가 들어갈 공간이 있는지 확인
        while (visibleTraits.isNotEmpty && 
               currentLineWidth + overflowBadgeWidth > maxWidth) {
          final removedTrait = visibleTraits.removeLast();
          final removedPainter = TextPainter(
            text: TextSpan(text: removedTrait, style: textStyle),
            textDirection: TextDirection.ltr,
          )..layout();
          currentLineWidth -= (removedPainter.width + horizontalPadding + spacing);
        }
        break;
      }
    }

    final overflowCount = traits.length - visibleTraits.length;
    return _BadgeCalculationResult(
      visibleTraits: visibleTraits,
      overflowCount: overflowCount,
    );
  }
}

/// 배지 계산 결과
class _BadgeCalculationResult {
  final List<String> visibleTraits;
  final int overflowCount;

  _BadgeCalculationResult({
    required this.visibleTraits,
    required this.overflowCount,
  });
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
