import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants/app_sizes.dart';

/// ============================================================
/// MINGRR 통합 이미지 컴포넌트
/// 
/// 앱 전체에서 사용하는 네트워크 이미지 위젯
/// - 캐싱: CachedNetworkImage 사용
/// - 메모리 최적화: memCacheWidth/memCacheHeight 자동 계산
/// - 통일된 로딩/에러 UI
/// 
/// 컴포넌트 목록:
/// - MingrrNetworkImage: 기본 네트워크 이미지
/// - MingrrAvatar: 원형 프로필/아바타 이미지
/// - MingrrThumbnail: 사각형 썸네일 이미지
/// - MingrrBackgroundImage: 배경 이미지 (Container 래핑)
/// ============================================================

// ============================================================
// 1. 기본 네트워크 이미지
// ============================================================

/// 캐싱 및 메모리 최적화가 적용된 네트워크 이미지
/// 
/// 사용 예시:
/// ```dart
/// MingrrNetworkImage(
///   imageUrl: 'https://example.com/image.jpg',
///   width: 100,
///   height: 100,
/// )
/// ```
class MingrrNetworkImage extends StatelessWidget {
  /// 이미지 URL (null이면 placeholder 표시)
  final String? imageUrl;
  
  /// 이미지 너비
  final double? width;
  
  /// 이미지 높이
  final double? height;
  
  /// 이미지 맞춤 방식
  final BoxFit fit;
  
  /// 테두리 반경
  final BorderRadius? borderRadius;
  
  /// 커스텀 placeholder 위젯
  final Widget? placeholder;
  
  /// 커스텀 에러 위젯
  final Widget? errorWidget;
  
  /// 메모리 캐시 배율 (기본 2.0 = 레티나 대응)
  final double cacheScale;

  const MingrrNetworkImage({
    super.key,
    this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.cacheScale = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    // URL이 없거나 비어있으면 placeholder 표시
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildPlaceholder(context);
    }

    // 메모리 캐시 크기 계산 (레티나 대응)
    final memCacheWidth = width != null ? (width! * cacheScale).toInt() : null;
    final memCacheHeight = height != null ? (height! * cacheScale).toInt() : null;

    Widget image = CachedNetworkImage(
      imageUrl: imageUrl!,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      placeholder: (context, url) => _buildLoadingIndicator(context),
      errorWidget: (context, url, error) => _buildErrorWidget(context),
    );

    // borderRadius가 있으면 ClipRRect 적용
    if (borderRadius != null) {
      image = ClipRRect(
        borderRadius: borderRadius!,
        child: image,
      );
    }

    return image;
  }

  Widget _buildPlaceholder(BuildContext context) {
    if (placeholder != null) return placeholder!;
    
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: borderRadius,
      ),
      child: Icon(
        Icons.image_outlined,
        size: _getIconSize(),
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
    );
  }

  Widget _buildLoadingIndicator(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: borderRadius,
      ),
      child: Center(
        child: SizedBox(
          width: _getIconSize() * 0.6,
          height: _getIconSize() * 0.6,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    if (errorWidget != null) return errorWidget!;
    
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: borderRadius,
      ),
      child: Icon(
        Icons.broken_image_outlined,
        size: _getIconSize(),
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
    );
  }

  double _getIconSize() {
    if (width != null && height != null) {
      return (width! < height! ? width! : height!) * 0.4;
    }
    if (width != null) return width! * 0.4;
    if (height != null) return height! * 0.4;
    return 24;
  }
}

// ============================================================
// 2. 원형 아바타 이미지
// ============================================================

/// 원형 프로필/아바타 이미지
/// 
/// 사용 예시:
/// ```dart
/// MingrrAvatar(
///   imageUrl: user.profileImageUrl,
///   size: 48,
/// )
/// ```
class MingrrAvatar extends StatelessWidget {
  /// 이미지 URL
  final String? imageUrl;
  
  /// 아바타 크기 (너비 = 높이)
  final double size;
  
  /// 테두리 색상 (null이면 테두리 없음)
  final Color? borderColor;
  
  /// 테두리 두께
  final double borderWidth;
  
  /// 커스텀 placeholder 아이콘
  final IconData placeholderIcon;
  
  /// placeholder 아이콘 색상
  final Color? placeholderIconColor;
  
  /// 배경색
  final Color? backgroundColor;

  const MingrrAvatar({
    super.key,
    this.imageUrl,
    this.size = 48,
    this.borderColor,
    this.borderWidth = 2,
    this.placeholderIcon = Icons.person,
    this.placeholderIconColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor ?? colorScheme.surfaceContainerLow,
        border: borderColor != null
            ? Border.all(color: borderColor!, width: borderWidth)
            : null,
      ),
      child: ClipOval(
        child: _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildPlaceholder(context);
    }

    // 메모리 캐시 크기 (레티나 대응)
    final cacheSize = (size * 2).toInt();

    return CachedNetworkImage(
      imageUrl: imageUrl!,
      width: size,
      height: size,
      fit: BoxFit.cover,
      memCacheWidth: cacheSize,
      memCacheHeight: cacheSize,
      placeholder: (context, url) => _buildLoadingIndicator(context),
      errorWidget: (context, url, error) => _buildPlaceholder(context),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Center(
      child: Icon(
        placeholderIcon,
        size: size * 0.5,
        color: placeholderIconColor ?? Theme.of(context).colorScheme.outlineVariant,
      ),
    );
  }

  Widget _buildLoadingIndicator(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size * 0.4,
        height: size * 0.4,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
    );
  }
}

// ============================================================
// 3. 사각형 썸네일 이미지
// ============================================================

/// 사각형 썸네일 이미지 (리스트 아이템용)
/// 
/// 사용 예시:
/// ```dart
/// MingrrThumbnail(
///   imageUrl: product.imageUrl,
///   width: 80,
///   height: 80,
/// )
/// ```
class MingrrThumbnail extends StatelessWidget {
  /// 이미지 URL
  final String? imageUrl;
  
  /// 썸네일 너비
  final double width;
  
  /// 썸네일 높이
  final double height;
  
  /// 테두리 반경
  final double borderRadius;
  
  /// 커스텀 placeholder 위젯
  final Widget? placeholder;
  
  /// 커스텀 에러 위젯
  final Widget? errorWidget;

  const MingrrThumbnail({
    super.key,
    this.imageUrl,
    this.width = 80,
    this.height = 80,
    this.borderRadius = AppSizes.radiusS,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    return MingrrNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.circular(borderRadius),
      placeholder: placeholder,
      errorWidget: errorWidget,
    );
  }
}

// ============================================================
// 4. 배경 이미지 컨테이너
// ============================================================

/// 배경 이미지가 있는 컨테이너 (카드 배경 등)
/// 
/// 사용 예시:
/// ```dart
/// MingrrBackgroundImage(
///   imageUrl: pet.imageUrl,
///   borderRadius: 12,
///   child: Positioned(
///     bottom: 8,
///     child: Text('이름'),
///   ),
/// )
/// ```
class MingrrBackgroundImage extends StatelessWidget {
  /// 이미지 URL
  final String? imageUrl;
  
  /// 컨테이너 너비
  final double? width;
  
  /// 컨테이너 높이
  final double? height;
  
  /// 테두리 반경
  final double borderRadius;
  
  /// 자식 위젯 (오버레이)
  final Widget? child;
  
  /// 그라데이션 오버레이 (하단 어둡게)
  final bool showGradient;
  
  /// 커스텀 placeholder 위젯
  final Widget? placeholder;

  const MingrrBackgroundImage({
    super.key,
    this.imageUrl,
    this.width,
    this.height,
    this.borderRadius = 0,
    this.child,
    this.showGradient = false,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: Theme.of(context).colorScheme.surfaceContainerLow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 배경 이미지
            _buildImage(context),
            
            // 그라데이션 오버레이
            if (showGradient)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.6),
                    ],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),
            
            // 자식 위젯
            if (child != null) child!,
          ],
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return placeholder ?? _buildPlaceholder(context);
    }

    // 메모리 캐시 크기 계산
    final memCacheWidth = width != null ? (width! * 2).toInt() : null;
    final memCacheHeight = height != null ? (height! * 2).toInt() : null;

    return CachedNetworkImage(
      imageUrl: imageUrl!,
      width: width,
      height: height,
      fit: BoxFit.cover,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      placeholder: (context, url) => _buildLoadingIndicator(context),
      errorWidget: (context, url, error) => placeholder ?? _buildPlaceholder(context),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 48,
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// 5. 펫 전용 아바타 (기본 이미지 지원)
// ============================================================

/// 펫 프로필 아바타 (기본 펫 이미지 지원)
/// 
/// 사용 예시:
/// ```dart
/// MingrrPetAvatar(
///   imageUrl: pet.profileImageUrl,
///   size: 56,
/// )
/// ```
class MingrrPetAvatar extends StatelessWidget {
  /// 이미지 URL
  final String? imageUrl;
  
  /// 아바타 크기
  final double size;
  
  /// 테두리 색상
  final Color? borderColor;
  
  /// 테두리 두께
  final double borderWidth;

  const MingrrPetAvatar({
    super.key,
    this.imageUrl,
    this.size = 56,
    this.borderColor,
    this.borderWidth = 2,
  });

  @override
  Widget build(BuildContext context) {
    return MingrrAvatar(
      imageUrl: imageUrl,
      size: size,
      borderColor: borderColor,
      borderWidth: borderWidth,
      placeholderIcon: Icons.pets,
    );
  }
}
