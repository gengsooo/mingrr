import 'package:flutter/material.dart';
import '../../constants/app_icons.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/feature_colors.dart';
import '../../constants/app_sizes.dart';
import '../common_widgets.dart';
import '../kkosunnae_widgets.dart';
import '../badges/verification_badge.dart';
import '../badges/info_badge.dart' show PetGenderBadge, GenderBadgeStyle, InfoBadgeSize, LikeCountText;

/// ============================================================
/// 프로필 카드 공통 위젯
/// 
/// 보호자/반려동물 프로필을 간단히 표시하는 인라인 카드
/// 
/// 사용처:
/// - 마켓 상세 > 판매자 정보
/// - 알바 상세 > 등록자 정보
/// - 채팅 리스트 > 상대방 정보
/// - 소모임 상세 > 멤버 목록
/// - 데이팅 상세 > 보호자 정보
/// ============================================================

// ===== 보호자 프로필 카드 =====
/// 보호자(사용자) 프로필을 간단히 표시하는 카드
/// 
/// 사용법:
/// ```dart
/// GuardianProfileCard(
///   name: '홍길동',
///   kkosunnaeScore: 85.0,
///   onTap: () => showGuardianProfileModal(...),
/// )
/// ```
class GuardianProfileCard extends StatelessWidget {
  final String name;
  final double? kkosunnaeScore;
  final String? profileImageUrl;
  final String? subtitle;
  final String? gender;
  final bool isIdentityVerified;
  final bool isPetVerified;
  final bool isLocationVerified;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? accentColor;
  final bool showArrow;
  final bool compact;

  const GuardianProfileCard({
    super.key,
    required this.name,
    this.kkosunnaeScore,
    this.profileImageUrl,
    this.subtitle,
    this.gender,
    this.isIdentityVerified = false,
    this.isPetVerified = false,
    this.isLocationVerified = false,
    this.onTap,
    this.trailing,
    this.accentColor,
    this.showArrow = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? Theme.of(context).colorScheme.primary;
    final avatarSize = compact ? 40.0 : 48.0;
    final nameSize = compact ? 14.0 : 15.0;
    
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          // 아바타
          _buildAvatar(color, avatarSize),
          SizedBox(width: compact ? 10 : 12),
          
          // 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 이름 + 성별 + 인증 배지
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: (compact ? AppTextStyles.titleMedium(context) : AppTextStyles.titleLarge(context)).withWeight(FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (gender != null) ...[
                      const SizedBox(width: AppSizes.gapXS),
                      _buildGenderIcon(),
                    ],
                    if (_hasVerification) ...[
                      const SizedBox(width: AppSizes.gapSM),
                      _buildVerificationBadges(),
                    ],
                  ],
                ),
                
                // 부제목 또는 꼬순내지수
                if (subtitle != null || kkosunnaeScore != null) ...[
                  SizedBox(height: compact ? 2 : 4),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: (compact ? AppTextStyles.caption(context) : AppTextStyles.bodySmall(context)).withColor(Theme.of(context).colorScheme.onSurfaceVariant),
                    )
                  else if (kkosunnaeScore != null)
                    KkosunnaeScoreSmall(score: kkosunnaeScore!),
                ],
              ],
            ),
          ),
          
          // 트레일링 또는 화살표
          if (trailing != null)
            trailing!
          else if (showArrow && onTap != null)
            Icon(AppIcons.chevronRight, color: Theme.of(context).colorScheme.outlineVariant),
        ],
      ),
    );
  }

  Widget _buildAvatar(Color color, double size) {
    if (profileImageUrl != null && profileImageUrl!.isNotEmpty) {
      return MingrrImage.avatar(
        imageUrl: profileImageUrl,
        size: size,
        icon: AppIcons.profile,
      );
    }
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: AppOpacity.o10),
        shape: BoxShape.circle,
      ),
      child: Icon(AppIcons.profile, size: size * 0.5, color: color),
    );
  }

  bool get _hasVerification => isIdentityVerified || isPetVerified || isLocationVerified;

  Widget _buildGenderIcon() {
    final isMale = gender == 'male' || gender == '남성';
    return PetGenderBadge(
      isMale: isMale,
      showLabel: false,
      size: InfoBadgeSize.small,
      style: GenderBadgeStyle.tinted,
    );
  }

  Widget _buildVerificationBadges() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isIdentityVerified)
          const VerificationBadgeSmall(type: VerificationBadgeType.identity, isVerified: true),
        if (isPetVerified) ...[
          const SizedBox(width: 2),
          const VerificationBadgeSmall(type: VerificationBadgeType.pet, isVerified: true),
        ],
        if (isLocationVerified) ...[
          const SizedBox(width: 2),
          const VerificationBadgeSmall(type: VerificationBadgeType.location, isVerified: true),
        ],
      ],
    );
  }
}

// ===== 반려동물 프로필 카드 =====
/// 반려동물 프로필을 간단히 표시하는 카드
/// 
/// 사용법:
/// ```dart
/// PetProfileCard(
///   name: '뽀삐',
///   breed: '말티즈',
///   age: 3,
///   gender: 'female',
///   onTap: () => showPetProfileModal(...),
/// )
/// ```
class PetProfileCard extends StatelessWidget {
  final String name;
  final String? breed;
  final int? age;
  final String? gender;
  final double? weight;
  final String? profileImageUrl;
  final List<String> traits;
  final int? likeCount;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? accentColor;
  final bool showArrow;
  final bool compact;
  final bool showTraits;

  const PetProfileCard({
    super.key,
    required this.name,
    this.breed,
    this.age,
    this.gender,
    this.weight,
    this.profileImageUrl,
    this.traits = const [],
    this.likeCount,
    this.onTap,
    this.trailing,
    this.accentColor,
    this.showArrow = true,
    this.compact = false,
    this.showTraits = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? context.features.dating;
    final avatarSize = compact ? 40.0 : 48.0;
    final nameSize = compact ? 14.0 : 15.0;
    
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          // 아바타
          _buildAvatar(color, avatarSize),
          SizedBox(width: compact ? 10 : 12),
          
          // 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 이름 + 성별 아이콘
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: (compact ? AppTextStyles.titleMedium(context) : AppTextStyles.titleLarge(context)).withWeight(FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (gender != null) ...[
                      const SizedBox(width: AppSizes.gapXS),
                      _buildGenderIcon(),
                    ],
                    if (likeCount != null && likeCount! > 0) ...[
                      const SizedBox(width: AppSizes.gapS),
                      _buildLikeCount(context),
                    ],
                  ],
                ),
                
                // 품종, 나이, 체중
                SizedBox(height: compact ? 2 : 4),
                Text(
                  _buildSubtitle(),
                  style: (compact ? AppTextStyles.caption(context) : AppTextStyles.bodySmall(context)).withColor(Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                
                // 성격 태그
                if (showTraits && traits.isNotEmpty) ...[
                  const SizedBox(height: AppSizes.gapSM),
                  _buildTraits(context, color),
                ],
              ],
            ),
          ),
          
          // 트레일링 또는 화살표
          if (trailing != null)
            trailing!
          else if (showArrow && onTap != null)
            Icon(AppIcons.chevronRight, color: Theme.of(context).colorScheme.outlineVariant),
        ],
      ),
    );
  }

  Widget _buildAvatar(Color color, double size) {
    if (profileImageUrl != null && profileImageUrl!.isNotEmpty) {
      return MingrrImage.avatar(
        imageUrl: profileImageUrl,
        size: size,
        icon: AppIcons.pet,
      );
    }
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: AppOpacity.o10),
        shape: BoxShape.circle,
      ),
      child: Icon(AppIcons.pet, size: size * 0.5, color: color),
    );
  }

  Widget _buildGenderIcon() {
    final isMale = gender == 'male';
    return PetGenderBadge(
      isMale: isMale,
      showLabel: false,
      size: InfoBadgeSize.small,
      style: GenderBadgeStyle.tinted,
    );
  }

  Widget _buildLikeCount(BuildContext context) {
    return LikeCountText(count: likeCount ?? 0, size: InfoBadgeSize.small);
  }

  String _buildSubtitle() {
    final parts = <String>[];
    if (breed != null) parts.add(breed!);
    if (age != null) parts.add('$age세');
    if (weight != null) parts.add('${weight}kg');
    return parts.isEmpty ? '정보 없음' : parts.join(' · ');
  }

  Widget _buildTraits(BuildContext context, Color color) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: traits.take(3).map((trait) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: AppSizes.paddingXXS),
          decoration: BoxDecoration(
            color: color.withValues(alpha: AppOpacity.o10),
            borderRadius: BorderRadius.circular(AppSizes.radiusXS),
          ),
          child: Text(
            trait,
            style: AppTextStyles.captionSmall(context).copyWith(color: color),
          ),
        );
      }).toList(),
    );
  }
}

// ===== 프로필 카드 래퍼 (카드 스타일) =====
/// 프로필 카드를 카드 형태로 감싸는 래퍼
/// 
/// 사용법:
/// ```dart
/// ProfileCardWrapper(
///   child: GuardianProfileCard(...),
///   onTap: () => ...,
/// )
/// ```
class ProfileCardWrapper extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;

  const ProfileCardWrapper({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        boxShadow: AppShadows.shadowS(Theme.of(context).brightness == Brightness.dark),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(AppSizes.paddingM),
            child: child,
          ),
        ),
      ),
    );
  }
}
