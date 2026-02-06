import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_icons.dart';
import '../../constants/app_sizes.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/feature_colors.dart';

/// ============================================================
/// 정보 배지 위젯 모음
/// 
/// 크기별 variant: small, medium, large
/// 
/// 포함 컴포넌트:
/// - DistanceBadge: 거리 표시 (예: 1.2km)
/// - MatchScoreBadge: 궁합 점수 표시 (예: 95%)
/// - GenderAgeBadge: 성별/나이 표시 (예: 남아 · 3살)
/// - InfoBadge: 범용 정보 배지
/// ============================================================

/// 배지 크기 enum
enum InfoBadgeSize {
  small,
  medium,
  large;
  
  /// 크기별 TextStyle 반환
  TextStyle getTextStyle(BuildContext context) {
    switch (this) {
      case InfoBadgeSize.small:
        return AppTextStyles.labelSmall(context);   // 10px
      case InfoBadgeSize.medium:
        return AppTextStyles.bodySmall(context);    // 12px
      case InfoBadgeSize.large:
        return AppTextStyles.bodyLarge(context);    // 14px
    }
  }
  
  /// 크기별 BorderRadius 반환
  double get borderRadius {
    switch (this) {
      case InfoBadgeSize.small:
        return AppSizes.radiusS;
      case InfoBadgeSize.medium:
        return AppSizes.radiusM;
      case InfoBadgeSize.large:
        return AppSizes.radiusL;
    }
  }
}

/// 범용 정보 배지
class InfoBadge extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? iconColor;
  final InfoBadgeSize size;

  const InfoBadge({
    super.key,
    required this.text,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.iconColor,
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
        return const EdgeInsets.symmetric(horizontal: 6, vertical: AppSizes.paddingXXS);
      case InfoBadgeSize.medium:
        return const EdgeInsets.symmetric(horizontal: AppSizes.paddingS, vertical: AppSizes.paddingXS);
      case InfoBadgeSize.large:
        return const EdgeInsets.symmetric(horizontal: AppSizes.paddingS, vertical: AppSizes.paddingXS);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? Theme.of(context).colorScheme.surface;
    final txtColor = textColor ?? Theme.of(context).colorScheme.onSurfaceVariant;
    final icnColor = iconColor ?? txtColor;

    return Container(
      padding: _padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(size.borderRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: _iconSize, color: icnColor),
            SizedBox(width: size == InfoBadgeSize.small ? 2 : 4),
          ],
          Text(
            text,
            style: size.getTextStyle(context).withWeight(FontWeight.w500).withColor(txtColor),
          ),
        ],
      ),
    );
  }
}

/// 궁합 배지 스타일
enum MatchBadgeStyle {
  /// 투명 배경 + 색상 텍스트 (홈 추천친구)
  transparent,
  /// 불투명 배경 + 흰색 텍스트 (데이팅 리스트 카드, 상세화면)
  filled,
  /// 이미지 오버레이용 (반투명 검정 배경)
  overlay,
}

/// 궁합 점수 배지
/// 
/// 사용처:
/// - 홈 추천친구 카드: style=transparent
/// - 데이팅 추천친구 리스트 카드: style=filled
/// - 데이팅 상세화면 이미지 헤더: style=filled, showInfoIcon=true
/// - 근처검색 카드: style=transparent
class MatchScoreBadge extends StatelessWidget {
  final int score;
  final InfoBadgeSize size;
  final MatchBadgeStyle style;
  final bool showIcon;
  final bool showLabel;
  final bool showInfoIcon; // 정보 아이콘 (상세화면용)
  final VoidCallback? onTap;

  const MatchScoreBadge({
    super.key,
    required this.score,
    this.size = InfoBadgeSize.medium,
    this.style = MatchBadgeStyle.transparent,
    this.showIcon = true,
    this.showLabel = true,
    this.showInfoIcon = false,
    this.onTap,
  });

  /// 점수에 따른 기본 색상 (공통 로직)
  static Color getScoreColor(BuildContext context, int score) {
    final features = context.features;
    if (score >= 90) return features.success;
    if (score >= 70) return features.dating;
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }

  /// 스타일에 따른 배경색
  Color _getBackgroundColor(BuildContext context) {
    final baseColor = getScoreColor(context, score);
    switch (style) {
      case MatchBadgeStyle.transparent:
        return baseColor.withValues(alpha: AppOpacity.o15);
      case MatchBadgeStyle.filled:
        return baseColor;
      case MatchBadgeStyle.overlay:
        return Colors.black.withValues(alpha: AppOpacity.o50);
    }
  }

  /// 스타일에 따른 텍스트색
  Color _getTextColor(BuildContext context) {
    switch (style) {
      case MatchBadgeStyle.transparent:
        return getScoreColor(context, score);
      case MatchBadgeStyle.filled:
      case MatchBadgeStyle.overlay:
        return Colors.white;
    }
  }

  String get _displayText {
    return showLabel ? '궁합 $score%' : '$score%';
  }

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
        return const EdgeInsets.symmetric(horizontal: 6, vertical: AppSizes.paddingXXS);
      case InfoBadgeSize.medium:
        return const EdgeInsets.symmetric(horizontal: AppSizes.paddingS, vertical: AppSizes.paddingXS);
      case InfoBadgeSize.large:
        return const EdgeInsets.symmetric(horizontal: AppSizes.paddingM, vertical: AppSizes.paddingXS);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _getBackgroundColor(context);
    final textColor = _getTextColor(context);
    
    final badge = Container(
      padding: _padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(size.borderRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(AppIcons.star, size: _iconSize, color: textColor),
            SizedBox(width: size == InfoBadgeSize.small ? 2 : 4),
          ],
          Text(
            _displayText,
            style: size.getTextStyle(context).withWeight(FontWeight.w600).withColor(textColor),
          ),
          if (showInfoIcon) ...[
            const SizedBox(width: AppSizes.gapXS),
            Icon(AppIcons.info, size: _iconSize - 2, color: textColor.withValues(alpha: AppOpacity.o70)),
          ],
        ],
      ),
    );
    
    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: badge);
    }
    return badge;
  }
}

/// 성별/나이 배지
class GenderAgeBadge extends StatelessWidget {
  final bool isMale;
  final int? age;
  final String? ageString; // "3살" 형태로 직접 전달 가능
  final InfoBadgeSize size;

  const GenderAgeBadge({
    super.key,
    required this.isMale,
    this.age,
    this.ageString,
    this.size = InfoBadgeSize.medium,
  });

  Color get _backgroundColor {
    return isMale 
        ? const Color(0xFF2196F3)  // 파란색 (투명도 없음)
        : const Color(0xFFE91E63); // 핑크색 (투명도 없음)
  }

  Color get _textColor {
    return Colors.white;  // 텍스트 흰색
  }

  String get _displayText {
    final genderText = isMale ? '남아' : '여아';
    if (ageString != null) return '$genderText · $ageString';
    if (age != null) return '$genderText · ${age}살';
    return genderText;
  }

  @override
  Widget build(BuildContext context) {
    return InfoBadge(
      text: _displayText,
      icon: isMale ? AppIcons.male : AppIcons.female,
      backgroundColor: _backgroundColor,
      textColor: _textColor,
      iconColor: _textColor,
      size: size,
    );
  }
}

// ===== 좋아요 관련 컴포넌트 =====

/// 좋아요 수 텍스트 (정보 표시용, 클릭 불가)
/// 
/// 사용처:
/// - 보호자 프로필 모달 > 반려동물 카드
/// - 소모임 상세 > 정보 칩
/// - 커뮤니티 게시글 카드
class LikeCountText extends StatelessWidget {
  final int count;
  final InfoBadgeSize size;

  const LikeCountText({
    super.key,
    required this.count,
    this.size = InfoBadgeSize.medium,
  });

  double get _iconSize {
    switch (size) {
      case InfoBadgeSize.small:
        return 12.0;
      case InfoBadgeSize.medium:
        return 14.0;
      case InfoBadgeSize.large:
        return 16.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          AppIcons.like,
          size: _iconSize,
          color: color,
        ),
        const SizedBox(width: 2),
        Text(
          '$count',
          style: size.getTextStyle(context).withWeight(FontWeight.w500).withColor(color),
        ),
      ],
    );
  }
}

/// 좋아요 버튼 (애니메이션 포함)
/// 
/// 기능:
/// - 탭 시 바운스 애니메이션
/// - 좋아요 시 스케일 + 컬러 애니메이션
/// - 햅틱 피드백
/// 
/// 사용처:
/// - 반려동물 프로필 모달 헤더
/// - 데이팅 상세 하단 버튼
/// - 커뮤니티 상세 액션 바
class LikeButton extends StatefulWidget {
  final int count;
  final bool isLiked;
  final VoidCallback? onTap;
  final InfoBadgeSize size;
  final bool showCount;
  final bool enableHaptic;

  const LikeButton({
    super.key,
    required this.count,
    required this.isLiked,
    this.onTap,
    this.size = InfoBadgeSize.medium,
    this.showCount = true,
    this.enableHaptic = true,
  });

  @override
  State<LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _wasLiked = false;

  @override
  void initState() {
    super.initState();
    _wasLiked = widget.isLiked;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 0.9), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 25),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(LikeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLiked && !_wasLiked) {
      _controller.forward(from: 0);
      if (widget.enableHaptic) {
        HapticFeedback.lightImpact();
      }
    }
    _wasLiked = widget.isLiked;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _iconSize {
    switch (widget.size) {
      case InfoBadgeSize.small:
        return 16.0;
      case InfoBadgeSize.medium:
        return 20.0;
      case InfoBadgeSize.large:
        return 24.0;
    }
  }

  EdgeInsets get _padding {
    switch (widget.size) {
      case InfoBadgeSize.small:
        return const EdgeInsets.symmetric(horizontal: AppSizes.paddingXS, vertical: AppSizes.paddingXS);
      case InfoBadgeSize.medium:
        return const EdgeInsets.symmetric(horizontal: AppSizes.paddingS, vertical: AppSizes.paddingXS);
      case InfoBadgeSize.large:
        return const EdgeInsets.symmetric(horizontal: AppSizes.paddingS, vertical: AppSizes.paddingS);
    }
  }

  void _handleTap() {
    if (widget.onTap != null) {
      if (widget.enableHaptic) {
        HapticFeedback.selectionClick();
      }
      widget.onTap!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = context.features.dating;
    
    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: Semantics(
        button: true,
        label: widget.isLiked ? '좋아요 취소, ${widget.count}개' : '좋아요, ${widget.count}개',
        child: Padding(
          padding: _padding,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 150),
                      transitionBuilder: (child, animation) {
                        return ScaleTransition(scale: animation, child: child);
                      },
                      child: Icon(
                        widget.isLiked ? AppIcons.like : AppIcons.likeOutlined,
                        key: ValueKey(widget.isLiked),
                        size: _iconSize,
                        color: color,
                      ),
                    ),
                  );
                },
              ),
              if (widget.showCount) ...[
                const SizedBox(width: AppSizes.gapXS),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.5),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: Text(
                    '${widget.count}',
                    key: ValueKey(widget.count),
                    style: widget.size.getTextStyle(context).withWeight(FontWeight.w600).withColor(color),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 이미지 오버레이용 좋아요 배지 (반투명 배경)
/// 
/// 사용처:
/// - 데이팅 상세 이미지 헤더
/// - 소모임 상세 이미지 헤더
class LikeOverlayBadge extends StatelessWidget {
  final int count;
  final bool isLiked;
  final VoidCallback? onTap;

  const LikeOverlayBadge({
    super.key,
    required this.count,
    required this.isLiked,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final likedColor = context.features.dating;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM, vertical: AppSizes.paddingXS),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: AppOpacity.o50),
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isLiked ? AppIcons.like : AppIcons.likeOutlined,
              size: 16.0,
              color: isLiked ? likedColor : Colors.white,
            ),
            const SizedBox(width: AppSizes.gapXS),
            Text(
              '$count',
              style: AppTextStyles.bodyMedium(context).withWeight(FontWeight.w600).withColor(isLiked ? likedColor : Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

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
