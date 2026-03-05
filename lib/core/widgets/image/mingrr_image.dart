import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../constants/app_icons.dart';
import '../../constants/app_sizes.dart';

/// ============================================================
/// MINGRR 통합 이미지 컴포넌트
/// 
/// 앱 전체에서 사용하는 네트워크 이미지 위젯
/// - 캐싱: CachedNetworkImage 사용
/// - 메모리 최적화: memCacheWidth/memCacheHeight 자동 계산
/// - 통일된 로딩/에러 UI
/// - 테마 색상 지원 (accentColor)
/// 
/// 사용법:
/// ```dart
/// // 기본 사각형 이미지
/// MingrrImage(imageUrl: url, width: 100, height: 100)
/// 
/// // 원형 아바타
/// MingrrImage.avatar(imageUrl: url, size: 48)
/// 
/// // 썸네일
/// MingrrImage.thumbnail(imageUrl: url)
/// 
/// // 배경 이미지 + 오버레이
/// MingrrImage.background(imageUrl: url, child: overlay)
/// ```
/// ============================================================

/// 이미지 모양 enum
enum ImageShape {
  /// 사각형 (기본)
  rectangle,
  /// 원형
  circle,
  /// 둥근 모서리
  rounded,
}

/// 통합 네트워크 이미지 컴포넌트
class MingrrImage extends StatelessWidget {
  /// 이미지 URL (null이면 placeholder 표시)
  final String? imageUrl;
  
  /// 이미지 너비
  final double? width;
  
  /// 이미지 높이
  final double? height;
  
  /// 이미지 맞춤 방식
  final BoxFit fit;
  
  /// 이미지 모양
  final ImageShape shape;
  
  /// 테두리 반경 (shape가 rounded일 때 사용)
  final double borderRadius;
  
  /// 테두리 색상 (null이면 테두리 없음)
  final Color? borderColor;
  
  /// 테두리 두께
  final double borderWidth;
  
  /// 테마 강조 색상 (로딩/플레이스홀더에 사용)
  final Color? accentColor;
  
  /// 플레이스홀더 아이콘
  final IconData placeholderIcon;
  
  /// 배경색 (accentColor가 없을 때 사용)
  final Color? backgroundColor;
  
  /// 자식 위젯 (오버레이)
  final Widget? child;
  
  /// 그라데이션 오버레이 (하단 어둡게)
  final bool showGradient;
  
  /// 커스텀 placeholder 위젯
  final Widget? placeholder;
  
  /// 커스텀 에러 위젯
  final Widget? errorWidget;
  
  /// 메모리 캐시 배율 (기본 2.0 = 레티나 대응)
  final double cacheScale;

  /// 기본 생성자 (사각형 이미지)
  const MingrrImage({
    super.key,
    this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.shape = ImageShape.rectangle,
    this.borderRadius = 0,
    this.borderColor,
    this.borderWidth = 2,
    this.accentColor,
    this.placeholderIcon = AppIcons.image,
    this.backgroundColor,
    this.child,
    this.showGradient = false,
    this.placeholder,
    this.errorWidget,
    this.cacheScale = 2.0,
  });

  /// 원형 아바타 이미지
  /// 
  /// 사용 예시:
  /// ```dart
  /// MingrrImage.avatar(
  ///   imageUrl: user.profileImageUrl,
  ///   size: 48,
  /// )
  /// ```
  const MingrrImage.avatar({
    super.key,
    this.imageUrl,
    double size = 48,
    this.borderColor,
    this.borderWidth = 2,
    this.accentColor,
    IconData icon = AppIcons.profile,
    this.backgroundColor,
    this.placeholder,
    this.errorWidget,
    this.cacheScale = 2.0,
  }) : width = size,
       height = size,
       fit = BoxFit.cover,
       shape = ImageShape.circle,
       borderRadius = 0,
       placeholderIcon = icon,
       child = null,
       showGradient = false;

  /// 펫 아바타 이미지
  /// 
  /// 사용 예시:
  /// ```dart
  /// MingrrImage.petAvatar(
  ///   imageUrl: pet.profileImageUrl,
  ///   size: 56,
  /// )
  /// ```
  const MingrrImage.petAvatar({
    super.key,
    this.imageUrl,
    double size = 56,
    this.borderColor,
    this.borderWidth = 2,
    this.accentColor,
    this.backgroundColor,
    this.placeholder,
    this.errorWidget,
    this.cacheScale = 2.0,
  }) : width = size,
       height = size,
       fit = BoxFit.cover,
       shape = ImageShape.circle,
       borderRadius = 0,
       placeholderIcon = AppIcons.pet,
       child = null,
       showGradient = false;

  /// 사각형 썸네일 이미지
  /// 
  /// 사용 예시:
  /// ```dart
  /// MingrrImage.thumbnail(
  ///   imageUrl: product.imageUrl,
  ///   width: 80,
  ///   height: 80,
  /// )
  /// ```
  const MingrrImage.thumbnail({
    super.key,
    this.imageUrl,
    this.width = 80,
    this.height = 80,
    double radius = AppSizes.radiusS,
    this.accentColor,
    this.placeholder,
    this.errorWidget,
    this.cacheScale = 2.0,
  }) : fit = BoxFit.cover,
       shape = ImageShape.rounded,
       borderRadius = radius,
       borderColor = null,
       borderWidth = 0,
       placeholderIcon = AppIcons.image,
       backgroundColor = null,
       child = null,
       showGradient = false;

  /// 배경 이미지 (오버레이 지원)
  /// 
  /// 사용 예시:
  /// ```dart
  /// MingrrImage.background(
  ///   imageUrl: pet.imageUrl,
  ///   borderRadius: 12,
  ///   accentColor: context.features.dating,
  ///   showGradient: true,
  ///   child: Positioned(
  ///     bottom: 8,
  ///     child: Text('이름'),
  ///   ),
  /// )
  /// ```
  const MingrrImage.background({
    super.key,
    this.imageUrl,
    this.width,
    this.height,
    double radius = 0,
    this.accentColor,
    this.child,
    this.showGradient = false,
    this.placeholder,
    this.errorWidget,
    this.cacheScale = 2.0,
  }) : fit = BoxFit.cover,
       shape = ImageShape.rounded,
       borderRadius = radius,
       borderColor = null,
       borderWidth = 0,
       placeholderIcon = AppIcons.image,
       backgroundColor = null;

  @override
  Widget build(BuildContext context) {
    return _buildContainer(
      context,
      child: _buildContent(context),
    );
  }

  /// 컨테이너 빌드 (모양, 테두리 적용)
  Widget _buildContainer(BuildContext context, {required Widget child}) {
    final colorScheme = Theme.of(context).colorScheme;
    final bgColor = backgroundColor ?? colorScheme.surfaceContainerLow;
    
    // 원형
    if (shape == ImageShape.circle) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bgColor,
          border: borderColor != null
              ? Border.all(color: borderColor!, width: borderWidth)
              : null,
        ),
        child: ClipOval(child: child),
      );
    }
    
    // 둥근 모서리 또는 사각형
    final radius = BorderRadius.circular(borderRadius);
    
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: radius,
        color: bgColor,
        border: borderColor != null
            ? Border.all(color: borderColor!, width: borderWidth)
            : null,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: child,
      ),
    );
  }

  /// 콘텐츠 빌드 (이미지 + 오버레이)
  Widget _buildContent(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 이미지
        _buildImage(context),
        
        // 그라데이션 오버레이
        if (showGradient) _buildGradientOverlay(),
        
        // 자식 위젯 (오버레이)
        if (child != null) child!,
      ],
    );
  }

  /// 이미지 빌드
  Widget _buildImage(BuildContext context) {
    // URL이 없거나 비어있으면 placeholder 표시
    if (imageUrl == null || imageUrl!.isEmpty) {
      return placeholder ?? _buildPlaceholder(context);
    }

    // 메모리 캐시 크기 계산 (레티나 대응)
    final memCacheWidth = width != null ? (width! * cacheScale).toInt() : null;
    final memCacheHeight = height != null ? (height! * cacheScale).toInt() : null;

    return CachedNetworkImage(
      imageUrl: imageUrl!,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      placeholder: (context, url) => _buildLoadingIndicator(context),
      errorWidget: (context, url, error) => errorWidget ?? _buildPlaceholder(context),
    );
  }

  /// 플레이스홀더 빌드
  Widget _buildPlaceholder(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // accentColor가 있으면 테마 그라데이션 배경 사용
    if (accentColor != null) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              accentColor!.withValues(alpha: AppOpacity.o15),
              accentColor!.withValues(alpha: AppOpacity.o05),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Icon(
            placeholderIcon,
            size: _getIconSize(),
            color: accentColor!.withValues(alpha: AppOpacity.o50),
          ),
        ),
      );
    }
    
    return Center(
      child: Icon(
        placeholderIcon,
        size: _getIconSize(),
        color: colorScheme.outlineVariant,
      ),
    );
  }

  /// 로딩 인디케이터 빌드
  Widget _buildLoadingIndicator(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // accentColor가 있으면 테마 그라데이션 배경 + 테마 색상 스피너 사용
    if (accentColor != null) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              accentColor!.withValues(alpha: AppOpacity.o15),
              accentColor!.withValues(alpha: AppOpacity.o05),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SizedBox(
            width: _getSpinnerSize(),
            height: _getSpinnerSize(),
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: accentColor,
            ),
          ),
        ),
      );
    }
    
    return Center(
      child: SizedBox(
        width: _getSpinnerSize(),
        height: _getSpinnerSize(),
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: colorScheme.outlineVariant,
        ),
      ),
    );
  }

  /// 그라데이션 오버레이 빌드
  Widget _buildGradientOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: AppOpacity.o70),
          ],
          stops: const [0.5, 1.0],
        ),
      ),
    );
  }

  /// 아이콘 크기 계산
  double _getIconSize() {
    if (width != null && height != null) {
      final minSize = width! < height! ? width! : height!;
      // 원형은 더 큰 아이콘
      if (shape == ImageShape.circle) {
        return minSize * 0.5;
      }
      return (minSize * 0.4).clamp(20.0, 48.0);
    }
    if (width != null) return (width! * 0.4).clamp(20.0, 48.0);
    if (height != null) return (height! * 0.4).clamp(20.0, 48.0);
    return 24;
  }

  /// 스피너 크기 계산
  double _getSpinnerSize() {
    if (width != null && height != null) {
      final minSize = width! < height! ? width! : height!;
      // 원형은 더 큰 스피너
      if (shape == ImageShape.circle) {
        return minSize * 0.4;
      }
      return (minSize * 0.25).clamp(16.0, 32.0);
    }
    if (width != null) return (width! * 0.25).clamp(16.0, 32.0);
    if (height != null) return (height! * 0.25).clamp(16.0, 32.0);
    return 24;
  }
}
