import 'package:flutter/material.dart';
import '../../constants/app_sizes.dart';

/// ============================================================
/// 스켈레톤 로딩 위젯
/// 
/// 콘텐츠 로딩 중 레이아웃을 유지하며 Shimmer 애니메이션 제공
/// 
/// 사용 예시:
/// - MingrrSkeletonBox(width: 100, height: 20)
/// - MingrrSkeletonAvatar(size: 48)
/// - MingrrSkeletonCard.chatItem()
/// - MingrrSkeletonList(itemCount: 5, itemBuilder: (_) => MingrrSkeletonCard.chatItem())
/// ============================================================

/// Shimmer 애니메이션 래퍼
class MingrrShimmer extends StatefulWidget {
  final Widget child;
  final Duration duration;
  
  const MingrrShimmer({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<MingrrShimmer> createState() => _MingrrShimmerState();
}

class _MingrrShimmerState extends State<MingrrShimmer> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
    
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final baseColor = isDark 
        ? colorScheme.surfaceContainerHighest 
        : colorScheme.surfaceContainerHigh;
    final highlightColor = isDark 
        ? colorScheme.surfaceContainerHigh 
        : colorScheme.surface;
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: [
                0.0,
                0.5 + _animation.value * 0.25,
                1.0,
              ],
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// 기본 스켈레톤 박스
class MingrrSkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final BorderRadius? borderRadius;
  final bool isCircle;
  
  const MingrrSkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius,
    this.isCircle = false,
  });
  
  /// 원형 스켈레톤
  const MingrrSkeletonBox.circle({
    super.key,
    required double size,
  }) : width = size, height = size, isCircle = true, borderRadius = null;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final color = isDark 
        ? colorScheme.surfaceContainerHighest 
        : colorScheme.surfaceContainerHigh;
    
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircle ? null : (borderRadius ?? BorderRadius.circular(AppSizes.radiusS)),
      ),
    );
  }
}

/// 스켈레톤 아바타 (원형)
class MingrrSkeletonAvatar extends StatelessWidget {
  final double size;
  
  const MingrrSkeletonAvatar({
    super.key,
    this.size = 48,
  });
  
  /// 작은 사이즈
  const MingrrSkeletonAvatar.small({super.key}) : size = 32;
  
  /// 중간 사이즈
  const MingrrSkeletonAvatar.medium({super.key}) : size = 48;
  
  /// 큰 사이즈
  const MingrrSkeletonAvatar.large({super.key}) : size = 64;

  @override
  Widget build(BuildContext context) {
    return MingrrSkeletonBox.circle(size: size);
  }
}

/// 스켈레톤 텍스트 라인
class MingrrSkeletonText extends StatelessWidget {
  final double? width;
  final double height;
  final int lines;
  final double spacing;
  
  const MingrrSkeletonText({
    super.key,
    this.width,
    this.height = 14,
    this.lines = 1,
    this.spacing = 8,
  });
  
  /// 제목용 (굵은 텍스트)
  const MingrrSkeletonText.title({
    super.key,
    this.width,
  }) : height = 18, lines = 1, spacing = 8;
  
  /// 본문용 (여러 줄)
  const MingrrSkeletonText.body({
    super.key,
    this.width,
    this.lines = 2,
  }) : height = 14, spacing = 6;
  
  /// 캡션용 (작은 텍스트)
  const MingrrSkeletonText.caption({
    super.key,
    this.width,
  }) : height = 12, lines = 1, spacing = 8;

  @override
  Widget build(BuildContext context) {
    if (lines == 1) {
      return MingrrSkeletonBox(width: width, height: height);
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(lines, (index) {
        // 마지막 줄은 짧게
        final lineWidth = index == lines - 1 
            ? (width != null ? width! * 0.7 : null)
            : width;
        
        return Padding(
          padding: EdgeInsets.only(bottom: index < lines - 1 ? spacing : 0),
          child: MingrrSkeletonBox(
            width: lineWidth,
            height: height,
          ),
        );
      }),
    );
  }
}

/// 스켈레톤 카드 (리스트 아이템용)
class MingrrSkeletonCard extends StatelessWidget {
  final bool hasAvatar;
  final bool hasImage;
  final int textLines;
  final double? imageHeight;
  final EdgeInsets padding;
  
  const MingrrSkeletonCard({
    super.key,
    this.hasAvatar = true,
    this.hasImage = false,
    this.textLines = 2,
    this.imageHeight,
    this.padding = const EdgeInsets.all(AppSizes.paddingM),
  });

  @override
  Widget build(BuildContext context) {
    return MingrrShimmer(
      child: Container(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 이미지 영역
            if (hasImage) ...[
              MingrrSkeletonBox(
                width: double.infinity,
                height: imageHeight ?? 150,
                borderRadius: BorderRadius.circular(AppSizes.radiusM),
              ),
              const SizedBox(height: AppSizes.gapM),
            ],
            
            // 아바타 + 텍스트 영역
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasAvatar) ...[
                  const MingrrSkeletonAvatar(),
                  const SizedBox(width: AppSizes.gapM),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const MingrrSkeletonText.title(width: 120),
                      const SizedBox(height: AppSizes.gapS),
                      MingrrSkeletonText.body(lines: textLines),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  /// 채팅 아이템 스켈레톤
  static Widget chatItem() {
    return const MingrrSkeletonCard(
      hasAvatar: true,
      hasImage: false,
      textLines: 1,
    );
  }
  
  /// 상품 카드 스켈레톤
  static Widget productCard() {
    return const MingrrSkeletonCard(
      hasAvatar: false,
      hasImage: true,
      imageHeight: 120,
      textLines: 2,
    );
  }
  
  /// 데이팅 카드 스켈레톤
  static Widget datingCard() {
    return Builder(
      builder: (context) {
        return MingrrShimmer(
          child: Container(
            padding: const EdgeInsets.all(AppSizes.paddingM),
            child: Column(
              children: [
                // 큰 원형 아바타
                const MingrrSkeletonBox.circle(size: 80),
                const SizedBox(height: AppSizes.gapM),
                // 이름
                const MingrrSkeletonText.title(width: 100),
                const SizedBox(height: AppSizes.gapS),
                // 정보
                const MingrrSkeletonText.caption(width: 150),
                const SizedBox(height: AppSizes.gapS),
                // 태그들
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: AppSizes.gapXS,
                  runSpacing: AppSizes.gapXS,
                  children: [
                    MingrrSkeletonBox(width: 45, height: 20, borderRadius: BorderRadius.circular(AppSizes.radiusS)),
                    MingrrSkeletonBox(width: 55, height: 20, borderRadius: BorderRadius.circular(AppSizes.radiusS)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  /// 알림 아이템 스켈레톤
  static Widget notificationItem() {
    return const MingrrSkeletonCard(
      hasAvatar: true,
      hasImage: false,
      textLines: 2,
      padding: EdgeInsets.symmetric(
        horizontal: AppSizes.paddingM,
        vertical: AppSizes.paddingS,
      ),
    );
  }
  
  /// 게시글 카드 스켈레톤
  static Widget postCard() {
    return const MingrrSkeletonCard(
      hasAvatar: true,
      hasImage: true,
      imageHeight: 200,
      textLines: 2,
    );
  }
  
  /// 소모임 카드 스켈레톤
  static Widget groupCard() {
    return Builder(
      builder: (context) {
        return MingrrShimmer(
          child: Container(
            padding: const EdgeInsets.all(AppSizes.paddingM),
            child: Row(
              children: [
                // 소모임 이미지
                MingrrSkeletonBox(
                  width: 80,
                  height: 80,
                  borderRadius: BorderRadius.circular(AppSizes.radiusM),
                ),
                const SizedBox(width: AppSizes.gapM),
                // 소모임 정보
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const MingrrSkeletonText.title(width: 120),
                      const SizedBox(height: AppSizes.gapS),
                      const MingrrSkeletonText.caption(width: 80),
                      const SizedBox(height: AppSizes.gapS),
                      const MingrrSkeletonText.body(lines: 1),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  /// 건강 카드 스켈레톤
  static Widget healthCard() {
    return Builder(
      builder: (context) {
        return MingrrShimmer(
          child: Container(
            padding: const EdgeInsets.all(AppSizes.paddingM),
            child: Row(
              children: [
                // 아이콘 영역
                MingrrSkeletonBox(
                  width: 48,
                  height: 48,
                  borderRadius: BorderRadius.circular(AppSizes.radiusM),
                ),
                const SizedBox(width: AppSizes.gapM),
                // 정보 영역
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MingrrSkeletonText.title(width: 100),
                      SizedBox(height: AppSizes.gapS),
                      MingrrSkeletonText.caption(width: 150),
                    ],
                  ),
                ),
                // 값 영역
                const MingrrSkeletonBox(width: 60, height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 스켈레톤 리스트 (여러 아이템)
class MingrrSkeletonList extends StatelessWidget {
  final int itemCount;
  final Widget Function(int index) itemBuilder;
  final bool isGrid;
  final int crossAxisCount;
  final double? itemSpacing;
  final EdgeInsets? padding;
  
  const MingrrSkeletonList({
    super.key,
    this.itemCount = 5,
    required this.itemBuilder,
    this.isGrid = false,
    this.crossAxisCount = 2,
    this.itemSpacing,
    this.padding,
  });
  
  /// 채팅 리스트 스켈레톤
  factory MingrrSkeletonList.chat({int itemCount = 5}) {
    return MingrrSkeletonList(
      itemCount: itemCount,
      itemBuilder: (_) => MingrrSkeletonCard.chatItem(),
    );
  }
  
  /// 상품 그리드 스켈레톤
  factory MingrrSkeletonList.products({int itemCount = 6}) {
    return MingrrSkeletonList(
      itemCount: itemCount,
      isGrid: true,
      crossAxisCount: 2,
      itemBuilder: (_) => MingrrSkeletonCard.productCard(),
    );
  }
  
  /// 데이팅 그리드 스켈레톤
  factory MingrrSkeletonList.dating({int itemCount = 6}) {
    return MingrrSkeletonList(
      itemCount: itemCount,
      isGrid: true,
      crossAxisCount: 2,
      itemBuilder: (_) => MingrrSkeletonCard.datingCard(),
    );
  }
  
  /// 알림 리스트 스켈레톤
  factory MingrrSkeletonList.notifications({int itemCount = 5}) {
    return MingrrSkeletonList(
      itemCount: itemCount,
      itemBuilder: (_) => MingrrSkeletonCard.notificationItem(),
    );
  }
  
  /// 소모임 리스트 스켈레톤
  factory MingrrSkeletonList.groups({int itemCount = 5}) {
    return MingrrSkeletonList(
      itemCount: itemCount,
      itemBuilder: (_) => MingrrSkeletonCard.groupCard(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectivePadding = padding ?? const EdgeInsets.all(AppSizes.paddingM);
    final effectiveSpacing = itemSpacing ?? AppSizes.gapM;
    
    if (isGrid) {
      return Padding(
        padding: effectivePadding,
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: effectiveSpacing,
            mainAxisSpacing: effectiveSpacing,
            childAspectRatio: 0.8,
          ),
          itemCount: itemCount,
          itemBuilder: (context, index) => itemBuilder(index),
        ),
      );
    }
    
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: effectivePadding,
      itemCount: itemCount,
      separatorBuilder: (_, _) => SizedBox(height: effectiveSpacing),
      itemBuilder: (context, index) => itemBuilder(index),
    );
  }
}

/// MingrrLoadingState에 스켈레톤 옵션 추가를 위한 확장
extension SkeletonLoadingExtension on BuildContext {
  /// 스켈레톤 로딩 표시
  Widget skeletonLoading({
    required Widget skeleton,
    bool isLoading = true,
    required Widget child,
  }) {
    return isLoading ? skeleton : child;
  }
}
