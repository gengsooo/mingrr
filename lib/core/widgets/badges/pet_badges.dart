import 'package:flutter/material.dart';
import '../../constants/app_icons.dart';
import '../../constants/app_sizes.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/feature_colors.dart';
import 'info_badge.dart';

/// 성별 배지 스타일
enum GenderBadgeStyle {
  /// 불투명 배경 + 흰색 텍스트 (이미지 위에 표시용)
  filled,
  /// 투명 배경 + 컬러 텍스트 (일반 UI용)
  tinted,
}

/// 반려동물 성별 배지 (통합 컴포넌트)
/// 
/// 사용 예시:
/// - 이미지 위: PetGenderBadge(isMale: true, style: GenderBadgeStyle.filled)
/// - 일반 UI: PetGenderBadge(isMale: true, style: GenderBadgeStyle.tinted)
class PetGenderBadge extends StatelessWidget {
  final bool isMale;
  final bool showLabel;
  final InfoBadgeSize size;
  final GenderBadgeStyle style;

  const PetGenderBadge({
    super.key,
    required this.isMale,
    this.showLabel = true,
    this.size = InfoBadgeSize.medium,
    this.style = GenderBadgeStyle.tinted,
  });

  double get _symbolSize {
    switch (size) {
      case InfoBadgeSize.small:
        return 11;
      case InfoBadgeSize.medium:
        return 14;
      case InfoBadgeSize.large:
        return 16;
    }
  }

  EdgeInsets get _padding {
    switch (size) {
      case InfoBadgeSize.small:
        return const EdgeInsets.symmetric(horizontal: 6, vertical: AppSizes.paddingXXS);
      case InfoBadgeSize.medium:
        return const EdgeInsets.symmetric(horizontal: AppSizes.paddingS, vertical: 3);
      case InfoBadgeSize.large:
        return const EdgeInsets.symmetric(horizontal: AppSizes.paddingS, vertical: AppSizes.paddingXS);
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = isMale ? Colors.blue : Colors.pink;
    
    // 스타일에 따른 색상 설정
    final Color bgColor;
    final Color textColor;
    
    switch (style) {
      case GenderBadgeStyle.filled:
        // 불투명 배경 + 흰색 텍스트 (이미지 위에 표시용)
        bgColor = isMale ? const Color(0xFF2196F3) : const Color(0xFFE91E63);
        textColor = Colors.white;
        break;
      case GenderBadgeStyle.tinted:
        // 투명 배경 + 컬러 텍스트 (일반 UI용)
        bgColor = baseColor.withValues(alpha: AppOpacity.o15);
        textColor = baseColor;
        break;
    }
    
    return Container(
      padding: _padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusS),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isMale ? AppIcons.male : AppIcons.female,
            size: _symbolSize,
            color: textColor,
          ),
          if (showLabel) ...[
            const SizedBox(width: 3),
            Text(
              isMale ? '남아' : '여아',
              style: size.getTextStyle(context).withWeight(FontWeight.w500).withColor(textColor),
            ),
          ],
        ],
      ),
    );
  }
}

/// 인증 상태 배지 (간단 버전)
class VerifiedBadge extends StatelessWidget {
  final String label;
  final bool isVerified;
  final InfoBadgeSize size;

  const VerifiedBadge({
    super.key,
    required this.label,
    required this.isVerified,
    this.size = InfoBadgeSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    return InfoBadge(
      text: label,
      icon: isVerified ? AppIcons.success : AppIcons.cancel,
      backgroundColor: isVerified 
          ? context.features.success.withValues(alpha: AppOpacity.o10) 
          : Theme.of(context).colorScheme.surface,
      textColor: isVerified ? context.features.success : Theme.of(context).colorScheme.outlineVariant,
      size: size,
    );
  }
}

/// 빈 상태 안내 배지 (이미지 오버레이용)
/// 
/// 사용처:
/// - 데이팅 상세 이미지 헤더: 위치 정보 없음, 궁합 정보 없음
/// - 이미지 없을 때 안내
class EmptyInfoBadge extends StatelessWidget {
  final IconData icon;
  final String text;
  final InfoBadgeSize size;

  const EmptyInfoBadge({
    super.key,
    required this.icon,
    required this.text,
    this.size = InfoBadgeSize.medium,
  });

  double get _iconSize {
    switch (size) {
      case InfoBadgeSize.small:
        return 12;
      case InfoBadgeSize.medium:
        return 14;
      case InfoBadgeSize.large:
        return 16;
    }
  }

  EdgeInsets get _padding {
    switch (size) {
      case InfoBadgeSize.small:
        return const EdgeInsets.symmetric(horizontal: AppSizes.paddingS, vertical: AppSizes.paddingXS);
      case InfoBadgeSize.medium:
        return const EdgeInsets.symmetric(horizontal: AppSizes.paddingS, vertical: AppSizes.paddingXS);
      case InfoBadgeSize.large:
        return const EdgeInsets.symmetric(horizontal: AppSizes.paddingM, vertical: AppSizes.paddingXS);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: _padding,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: AppOpacity.o50),
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: _iconSize, color: Colors.white70),
          const SizedBox(width: AppSizes.gapXS),
          Text(
            text,
            style: size.getTextStyle(context).withWeight(FontWeight.w500).withColor(Colors.white70),
          ),
        ],
      ),
    );
  }
}

/// ============================================================
/// 혈통서 유무 배지
/// 
/// 사용처:
/// - 교배찾기 리스트 카드
/// - 교배 상세 화면
/// - 반려동물 선택 바텀시트/카드
/// ============================================================
class PedigreeBadge extends StatelessWidget {
  final bool hasPedigree;
  final InfoBadgeSize size;
  final Color? accentColor;

  const PedigreeBadge({
    super.key,
    required this.hasPedigree,
    this.size = InfoBadgeSize.medium,
    this.accentColor,
  });

  double get _iconSize {
    switch (size) {
      case InfoBadgeSize.small:
        return 10;
      case InfoBadgeSize.medium:
        return 12;
      case InfoBadgeSize.large:
        return 14;
    }
  }

  EdgeInsets get _padding {
    switch (size) {
      case InfoBadgeSize.small:
        return const EdgeInsets.symmetric(horizontal: 6, vertical: AppSizes.paddingXXS);
      case InfoBadgeSize.medium:
        return const EdgeInsets.symmetric(horizontal: AppSizes.paddingS, vertical: 3);
      case InfoBadgeSize.large:
        return const EdgeInsets.symmetric(horizontal: AppSizes.paddingS, vertical: AppSizes.paddingXS);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = accentColor ?? Theme.of(context).extension<FeatureColors>()!.dating;
    
    return Container(
      padding: _padding,
      decoration: BoxDecoration(
        color: hasPedigree 
            ? color.withValues(alpha: AppOpacity.o10)
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(size.borderRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasPedigree ? AppIcons.verified : AppIcons.block,
            size: _iconSize,
            color: hasPedigree ? color : colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSizes.gapXS),
          Text(
            hasPedigree ? '혈통서' : '혈통서 없음',
            style: size.getTextStyle(context)
                .withWeight(hasPedigree ? FontWeight.w600 : FontWeight.w500)
                .withColor(hasPedigree ? color : colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
