import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants/app_sizes.dart';
import 'mingrr_image_viewer.dart';

/// ============================================================
/// 가로 스크롤 이미지 갤러리
/// 
/// 본문 내에서 이미지 목록을 가로 스크롤로 표시
/// - 단일 이미지: 전체 너비
/// - 다중 이미지: 가로 스크롤 리스트
/// - 탭 시 전체화면 뷰어 열기 (옵션)
/// ============================================================

class MingrrImageGallery extends StatelessWidget {
  /// 이미지 URL 목록
  final List<String> imageUrls;
  
  /// 갤러리 높이
  final double height;
  
  /// 아이템 너비 (null이면 height와 동일)
  final double? itemWidth;
  
  /// 탭 시 전체화면 뷰어 열기
  final bool enableViewer;
  
  /// 공유 버튼 콜백 (뷰어에서 사용)
  final VoidCallback? onShare;
  
  /// 테두리 반경
  final double borderRadius;

  const MingrrImageGallery({
    super.key,
    required this.imageUrls,
    this.height = 200,
    this.itemWidth,
    this.enableViewer = true,
    this.onShare,
    this.borderRadius = AppSizes.radiusS,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) {
      return const SizedBox.shrink();
    }

    // 단일 이미지
    if (imageUrls.length == 1) {
      return _buildSingleImage(context);
    }

    // 다중 이미지 (가로 스크롤)
    return _buildMultipleImages(context);
  }

  Widget _buildSingleImage(BuildContext context) {
    return GestureDetector(
      onTap: enableViewer ? () => _openViewer(context, 0) : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: CachedNetworkImage(
          imageUrl: imageUrls.first,
          width: double.infinity,
          height: height,
          fit: BoxFit.cover,
          memCacheHeight: (height * 2).toInt(),
          placeholder: (context, url) => _buildLoadingPlaceholder(context),
          errorWidget: (context, url, error) => _buildErrorPlaceholder(context),
        ),
      ),
    );
  }

  Widget _buildMultipleImages(BuildContext context) {
    final width = itemWidth ?? height;
    
    return SizedBox(
      height: height,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: enableViewer ? () => _openViewer(context, index) : null,
            child: Padding(
              padding: EdgeInsets.only(
                right: index < imageUrls.length - 1 ? 8 : 0,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(borderRadius),
                child: CachedNetworkImage(
                  imageUrl: imageUrls[index],
                  width: width,
                  height: height,
                  fit: BoxFit.cover,
                  memCacheWidth: (width * 2).toInt(),
                  memCacheHeight: (height * 2).toInt(),
                  placeholder: (context, url) => _buildLoadingPlaceholder(
                    context,
                    width: width,
                  ),
                  errorWidget: (context, url, error) => _buildErrorPlaceholder(
                    context,
                    width: width,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingPlaceholder(BuildContext context, {double? width}) {
    return Container(
      width: width ?? double.infinity,
      height: height,
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

  Widget _buildErrorPlaceholder(BuildContext context, {double? width}) {
    return Container(
      width: width ?? double.infinity,
      height: height,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: const Center(
        child: Icon(Icons.image_not_supported),
      ),
    );
  }

  void _openViewer(BuildContext context, int index) {
    showMingrrImageViewer(
      context,
      imageUrls: imageUrls,
      initialIndex: index,
      onShare: onShare,
    );
  }
}
