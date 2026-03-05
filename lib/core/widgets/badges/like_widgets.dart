import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_icons.dart';
import '../../constants/app_sizes.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/feature_colors.dart';
import 'info_badge.dart';

/// 좋아요 카운트 텍스트
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
