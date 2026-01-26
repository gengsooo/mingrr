import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants/app_sizes.dart';
import '../constants/location_constants.dart';
import '../theme/app_text_styles.dart';
import 'common_widgets.dart';
import 'badges/info_badge.dart';
import '../utils/responsive_utils.dart';

/// ============================================================
/// 상세 화면 이미지 헤더 (SliverAppBar 통합)
/// 
/// 상세 화면에서 이미지 슬라이더를 SliverAppBar로 표시
/// - PageView 슬라이더
/// - 페이지 인디케이터
/// - 4개 코너 오버레이 (옵션)
/// - AppBar 액션 버튼 (공유, 더보기 등)
/// ============================================================

class MingrrImageHeader extends StatefulWidget {
  /// 이미지 URL 목록
  final List<String> imageUrls;
  
  /// 확장 높이
  final double expandedHeight;
  
  /// 페이지 인디케이터 표시
  final bool showIndicator;
  
  /// 이미지 없을 때 표시할 위젯 (deprecated: emptyStateWidget 사용)
  final Widget? placeholder;
  
  /// 이미지 없을 때 표시할 빈 상태 위젯 (placeholder보다 우선)
  final Widget? emptyStateWidget;
  
  /// AppBar 고정 여부
  final bool pinned;
  
  /// 공유 버튼 콜백 (null이면 숨김)
  final VoidCallback? onShare;
  
  /// 더보기 버튼 콜백 (null이면 숨김)
  final VoidCallback? onMore;
  
  /// 커스텀 액션 위젯 (좋아요 버튼 등)
  final Widget? customAction;
  
  /// 좌상단 오버레이 (성별 배지 등)
  final Widget? topLeftOverlay;
  
  /// 우상단 오버레이 (거리 배지 등)
  final Widget? topRightOverlay;
  
  /// 좌하단 오버레이 (좋아요 버튼 등)
  final Widget? bottomLeftOverlay;
  
  /// 우하단 오버레이 (궁합점수 등)
  final Widget? bottomRightOverlay;
  
  /// 페이지 변경 콜백
  final ValueChanged<int>? onPageChanged;
  
  /// 인디케이터 하단 여백
  final double indicatorBottomPadding;

  const MingrrImageHeader({
    super.key,
    required this.imageUrls,
    this.expandedHeight = 300,
    this.showIndicator = true,
    this.placeholder,
    this.emptyStateWidget,
    this.pinned = true,
    this.onShare,
    this.onMore,
    this.customAction,
    this.topLeftOverlay,
    this.topRightOverlay,
    this.bottomLeftOverlay,
    this.bottomRightOverlay,
    this.onPageChanged,
    this.indicatorBottomPadding = 60,
  });

  @override
  State<MingrrImageHeader> createState() => _MingrrImageHeaderState();
}

class _MingrrImageHeaderState extends State<MingrrImageHeader> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: widget.expandedHeight,
      pinned: widget.pinned,
      backgroundColor: Theme.of(context).colorScheme.surface,
      leading: _buildBackButton(context),
      actions: _buildActions(),
      flexibleSpace: FlexibleSpaceBar(
        background: _buildSliderContent(context),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return IconButton(
      icon: Container(
        padding: const EdgeInsets.all(AppSizes.paddingS),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: AppOpacity.o30),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
      ),
      onPressed: () => Navigator.pop(context),
    );
  }

  List<Widget> _buildActions() {
    final actions = <Widget>[];

    // 커스텀 액션
    if (widget.customAction != null) {
      actions.add(widget.customAction!);
    }

    // 공유 버튼
    if (widget.onShare != null) {
      actions.add(
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(AppSizes.paddingS),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: AppOpacity.o30),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.share, color: Colors.white, size: 20),
          ),
          onPressed: widget.onShare,
        ),
      );
    }

    // 더보기 버튼
    if (widget.onMore != null) {
      actions.add(
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(AppSizes.paddingS),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: AppOpacity.o30),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.more_vert, color: Colors.white, size: 20),
          ),
          onPressed: widget.onMore,
        ),
      );
    }

    return actions;
  }

  Widget _buildSliderContent(BuildContext context) {
    // 이미지가 없으면 emptyStateWidget 또는 placeholder 표시
    if (widget.imageUrls.isEmpty) {
      return widget.emptyStateWidget ?? widget.placeholder ?? const DefaultPetImage(height: double.infinity);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // 이미지 슬라이더
        PageView.builder(
          itemCount: widget.imageUrls.length,
          onPageChanged: (index) {
            setState(() => _currentIndex = index);
            widget.onPageChanged?.call(index);
          },
          itemBuilder: (context, index) {
            return CachedNetworkImage(
              imageUrl: widget.imageUrls[index],
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              errorWidget: (context, url, error) => 
                  widget.placeholder ?? const DefaultPetImage(height: double.infinity),
            );
          },
        ),

        // 페이지 인디케이터
        if (widget.showIndicator && widget.imageUrls.length > 1)
          Positioned(
            bottom: widget.indicatorBottomPadding,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.imageUrls.length,
                (index) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: AppSizes.paddingXS),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentIndex == index
                        ? Colors.white
                        : Colors.white.withValues(alpha: AppOpacity.o50),
                  ),
                ),
              ),
            ),
          ),

        // 좌상단 오버레이
        if (widget.topLeftOverlay != null)
          Positioned(
            top: ResponsiveUtils.topSafeArea(context) + 60,
            left: 16,
            child: widget.topLeftOverlay!,
          ),

        // 우상단 오버레이
        if (widget.topRightOverlay != null)
          Positioned(
            top: ResponsiveUtils.topSafeArea(context) + 60,
            right: 16,
            child: widget.topRightOverlay!,
          ),

        // 좌하단 오버레이
        if (widget.bottomLeftOverlay != null)
          Positioned(
            bottom: 16,
            left: 16,
            child: widget.bottomLeftOverlay!,
          ),

        // 우하단 오버레이
        if (widget.bottomRightOverlay != null)
          Positioned(
            bottom: 16,
            right: 16,
            child: widget.bottomRightOverlay!,
          ),
      ],
    );
  }
}

/// ============================================================
/// 이미지 헤더용 오버레이 배지 위젯들
/// ============================================================

/// 성별 배지
class GenderBadge extends StatelessWidget {
  final bool isMale;

  const GenderBadge({super.key, required this.isMale});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingS, vertical: AppSizes.paddingXS),
      decoration: BoxDecoration(
        color: isMale 
            ? const Color(0xFF2196F3)  // 파란색
            : const Color(0xFFE91E63), // 핑크색
        borderRadius: BorderRadius.circular(AppSizes.radiusS),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isMale ? Icons.male : Icons.female,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 2),
          Text(
            isMale ? '남아' : '여아',
            style: AppTextStyles.bodySmall(context).withWeight(FontWeight.w500).withColor(Colors.white),
          ),
        ],
      ),
    );
  }
}

/// 이미지 헤더용 거리 배지 (오버레이 스타일)
class ImageHeaderDistanceBadge extends StatelessWidget {
  final double distanceKm;

  const ImageHeaderDistanceBadge({super.key, required this.distanceKm});

  @override
  Widget build(BuildContext context) {
    final distanceText = distanceKm > 0 && distanceKm.isFinite 
        ? '${distanceKm.toStringAsFixed(1)}km'
        : LocationConstants.noLocationText;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingS, vertical: AppSizes.paddingXS),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: AppOpacity.o50),
        borderRadius: BorderRadius.circular(AppSizes.radiusS),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LocationConstants.distanceIcon, size: 14, color: Colors.white),
          const SizedBox(width: 2),
          Text(
            distanceText,
            style: AppTextStyles.bodyMedium(context).withWeight(FontWeight.w500).withColor(Colors.white),
          ),
        ],
      ),
    );
  }
}

/// 좋아요 버튼 배지 (deprecated - LikeOverlayBadge 사용 권장)
/// info_badge.dart의 LikeOverlayBadge로 통합됨
/// 하위 호환성을 위해 유지
typedef LikeBadge = LikeOverlayBadge;

/// 이미지 헤더용 궁합점수 배지
/// 
/// @deprecated info_badge.dart의 MatchScoreBadge 사용 권장
/// MatchScoreBadge(score: score, style: MatchBadgeStyle.filled, showInfoIcon: true, onTap: onTap)
@Deprecated('Use MatchScoreBadge from info_badge.dart instead')
class ImageHeaderMatchBadge extends StatelessWidget {
  final int score;
  final VoidCallback? onTap;

  const ImageHeaderMatchBadge({
    super.key,
    required this.score,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM, vertical: AppSizes.paddingXS),
        decoration: BoxDecoration(
          color: score >= 90 
              ? const Color(0xFF4CAF50)  // 성공 색상 (90% 이상)
              : const Color(0xFFFF8A80), // 데이팅 색상 (핑크/코랄)
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome, size: 14, color: Colors.white),
            const SizedBox(width: AppSizes.gapXS),
            Text(
              '궁합 $score%',
              style: AppTextStyles.bodyMedium(context).withWeight(FontWeight.w600).withColor(Colors.white),
            ),
            const SizedBox(width: AppSizes.gapXS),
            const Icon(Icons.info_outline, size: 12, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}
