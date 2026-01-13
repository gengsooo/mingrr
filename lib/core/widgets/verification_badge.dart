import 'package:flutter/material.dart';
import '../theme/feature_colors.dart';

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
        return Icons.badge_outlined; // 신분증 아이콘
      case VerificationBadgeType.pet:
        return Icons.sell_outlined; // 태그 아이콘 (동물등록 태그)
      case VerificationBadgeType.location:
        return Icons.location_on_outlined; // 위치 아이콘
    }
  }

  /// 인증 완료 시 아이콘
  IconData get verifiedIcon {
    switch (this) {
      case VerificationBadgeType.identity:
        return Icons.badge; // 신분증 아이콘 (채워진)
      case VerificationBadgeType.pet:
        return Icons.sell; // 태그 아이콘 (채워진)
      case VerificationBadgeType.location:
        return Icons.location_on; // 위치 아이콘 (채워진)
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
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.all(4),
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
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isVerified 
              ? context.features.success.withOpacity(0.1) 
              : Theme.of(context).colorScheme.outline.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              isVerified ? type.verifiedIcon : type.icon,
              size: 24,
              color: isVerified ? context.features.success : Theme.of(context).colorScheme.outlineVariant,
            ),
            const SizedBox(height: 6),
            Text(
              type.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isVerified ? context.features.success : Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            const SizedBox(height: 2),
            Icon(
              isVerified ? Icons.check_circle : Icons.cancel_outlined,
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
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isVerified 
              ? context.features.success.withOpacity(0.1) 
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isVerified ? context.features.success.withOpacity(0.3) : Theme.of(context).colorScheme.outline,
          ),
        ),
        child: Column(
          children: [
            Icon(
              isVerified ? type.verifiedIcon : type.icon,
              size: 32,
              color: isVerified ? context.features.success : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              type.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isVerified ? context.features.success : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isVerified 
                    ? context.features.success 
                    : Theme.of(context).brightness == Brightness.dark
                        ? Theme.of(context).colorScheme.surfaceContainerHighest
                        : Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isVerified ? '완료' : '미인증',
                style: TextStyle(
                  fontSize: 10,
                  color: isVerified 
                      ? Colors.white 
                      : Theme.of(context).brightness == Brightness.dark
                          ? Theme.of(context).colorScheme.onSurface
                          : Colors.white,
                  fontWeight: FontWeight.w500,
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
          const SizedBox(width: 12),
          VerificationBadgeMedium(
            type: VerificationBadgeType.pet,
            isVerified: isPetVerified,
          ),
          const SizedBox(width: 12),
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
