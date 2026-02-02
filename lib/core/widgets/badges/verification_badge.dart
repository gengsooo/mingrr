import 'package:flutter/material.dart';
import '../../constants/app_icons.dart';
import '../../constants/app_sizes.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/feature_colors.dart';

/// ============================================================
/// 인증 배지 위젯
/// 
/// 앱 전체에서 통일된 인증 배지 디자인을 제공합니다.
/// - 본인인증, 동물등록, 위치인증 등
/// ============================================================

/// 인증 배지 타입
enum VerificationBadgeType {
  identity('본인인증', '신분증'),
  pet('동물등록', '동물등록'),
  location('위치인증', '위치');

  final String label;
  final String shortLabel;

  const VerificationBadgeType(this.label, this.shortLabel);

  /// 배지 아이콘 반환
  IconData get icon {
    switch (this) {
      case VerificationBadgeType.identity:
        return AppIcons.badgeIdentity; // 신분증 아이콘
      case VerificationBadgeType.pet:
        return AppIcons.badgePet; // 태그 아이콘 (동물등록 태그)
      case VerificationBadgeType.location:
        return AppIcons.badgeLocation; // 위치 아이콘
    }
  }

  /// 인증 완료 시 아이콘
  IconData get verifiedIcon {
    switch (this) {
      case VerificationBadgeType.identity:
        return AppIcons.badgeIdentity; // 신분증 아이콘 (채워진)
      case VerificationBadgeType.pet:
        return AppIcons.badgePet; // 태그 아이콘 (채워진)
      case VerificationBadgeType.location:
        return AppIcons.badgeLocation; // 위치 아이콘 (채워진)
    }
  }
}

/// 인증 배지 - 작은 원형 (카드용)
class VerificationBadgeSmall extends StatelessWidget {
  final VerificationBadgeType type;
  final bool isVerified;

  const VerificationBadgeSmall({
    super.key,
    required this.type,
    this.isVerified = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: AppSizes.paddingXS),
      padding: const EdgeInsets.all(AppSizes.paddingXS),
      decoration: BoxDecoration(
        color: isVerified ? context.features.success : Theme.of(context).colorScheme.outlineVariant,
        shape: BoxShape.circle,
      ),
      child: Icon(
        isVerified ? type.verifiedIcon : type.icon,
        size: 10,
        color: Colors.white,
      ),
    );
  }
}

/// 인증 배지 - 중간 크기 (상세 화면용)
class VerificationBadgeMedium extends StatelessWidget {
  final VerificationBadgeType type;
  final bool isVerified;

  const VerificationBadgeMedium({
    super.key,
    required this.type,
    this.isVerified = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingM),
        decoration: BoxDecoration(
          color: isVerified 
              ? context.features.success.withValues(alpha: AppOpacity.o10) 
              : Theme.of(context).colorScheme.outline.withValues(alpha: AppOpacity.o50),
          borderRadius: BorderRadius.circular(AppSizes.radiusS),
        ),
        child: Column(
          children: [
            Icon(
              isVerified ? type.verifiedIcon : type.icon,
              size: 24,
              color: isVerified ? context.features.success : Theme.of(context).colorScheme.outlineVariant,
            ),
            const SizedBox(height: AppSizes.gapSM),
            Text(
              type.label,
              style: AppTextStyles.caption(context).withWeight(FontWeight.w500).withColor(
                isVerified ? context.features.success : Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            const SizedBox(height: AppSizes.gapXXS),
            Icon(
              isVerified ? AppIcons.checkCircle : AppIcons.circleOutlined,
              size: 14,
              color: isVerified ? context.features.success : Theme.of(context).colorScheme.outlineVariant,
            ),
          ],
        ),
      ),
    );
  }
}

/// 인증 배지 - 큰 크기 (프로필 화면용)
class VerificationBadgeLarge extends StatelessWidget {
  final VerificationBadgeType type;
  final bool isVerified;
  final VoidCallback? onTap;

  const VerificationBadgeLarge({
    super.key,
    required this.type,
    this.isVerified = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingL, horizontal: 12),
        decoration: BoxDecoration(
          color: isVerified 
              ? context.features.success.withValues(alpha: AppOpacity.o10) 
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusS),
          border: Border.all(
            color: isVerified ? context.features.success.withValues(alpha: AppOpacity.o30) : Theme.of(context).colorScheme.outline,
          ),
        ),
        child: Column(
          children: [
            Icon(
              isVerified ? type.verifiedIcon : type.icon,
              size: 32,
              color: isVerified ? context.features.success : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSizes.gapS),
            Text(
              type.label,
              style: AppTextStyles.bodySmall(context).withWeight(FontWeight.w500).withColor(
                isVerified ? context.features.success : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSizes.gapXS),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingS, vertical: AppSizes.paddingXXS),
              decoration: BoxDecoration(
                color: isVerified 
                    ? context.features.success 
                    : Theme.of(context).brightness == Brightness.dark
                        ? Theme.of(context).colorScheme.surfaceContainerHighest
                        : Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(AppSizes.radiusXS),
              ),
              child: Text(
                isVerified ? '완료' : '미인증',
                style: AppTextStyles.labelSmall(context).withWeight(FontWeight.w500).withColor(
                  isVerified 
                      ? Colors.white 
                      : Theme.of(context).brightness == Brightness.dark
                          ? Theme.of(context).colorScheme.onSurface
                          : Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 인증 배지 행 (3개 배지를 가로로 표시)
class VerificationBadgeRow extends StatelessWidget {
  final bool isIdentityVerified;
  final bool isPetVerified;
  final bool isLocationVerified;
  final bool useMediumSize;

  const VerificationBadgeRow({
    super.key,
    this.isIdentityVerified = false,
    this.isPetVerified = false,
    this.isLocationVerified = false,
    this.useMediumSize = true,
  });

  @override
  Widget build(BuildContext context) {
    if (useMediumSize) {
      return Row(
        children: [
          VerificationBadgeMedium(
            type: VerificationBadgeType.identity,
            isVerified: isIdentityVerified,
          ),
          const SizedBox(width: AppSizes.gapM),
          VerificationBadgeMedium(
            type: VerificationBadgeType.pet,
            isVerified: isPetVerified,
          ),
          const SizedBox(width: AppSizes.gapM),
          VerificationBadgeMedium(
            type: VerificationBadgeType.location,
            isVerified: isLocationVerified,
          ),
        ],
      );
    }

    // 작은 사이즈 (카드용)
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isIdentityVerified)
          const VerificationBadgeSmall(type: VerificationBadgeType.identity),
        if (isPetVerified)
          const VerificationBadgeSmall(type: VerificationBadgeType.pet),
        if (isLocationVerified)
          const VerificationBadgeSmall(type: VerificationBadgeType.location),
      ],
    );
  }
}
