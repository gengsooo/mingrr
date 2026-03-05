import 'package:flutter/material.dart';
import '../../constants/app_sizes.dart';
import 'mingrr_image.dart';
import 'mingrr_image_viewer.dart';

/// ============================================================
/// 가로 스크롤 이미지 갤러리
/// 
/// 본문 내에서 이미지 목록을 가로 스크롤로 표시
/// - 단일 이미지: 전체 너비 (fullWidthSingle=true) 또는 고정 크기
/// - 다중 이미지: 가로 스크롤 리스트 (기본 4:3 비율)
/// - 탭 시 전체화면 뷰어 열기 (옵션)
/// ============================================================

class MingrrImageGallery extends StatelessWidget {
  /// 이미지 URL 목록
  final List<String> imageUrls;
  
  /// 갤러리 높이
  final double height;
  
  /// 아이템 너비 (null이면 다중: height*4/3, 단일: 전체 너비)
  final double? itemWidth;
  
  /// 단일 이미지일 때 전체 너비로 표시 (기본 true)
  /// false이면 itemWidth ?? height 크기로 표시
  final bool fullWidthSingle;
  
  /// 탭 시 전체화면 뷰어 열기
  final bool enableViewer;
  
  /// 공유 버튼 콜백 (뷰어에서 사용)
  final VoidCallback? onShare;
  
  /// 테두리 반경
  final double borderRadius;
  
  /// 테마 강조 색상 (로딩/플레이스홀더에 사용)
  final Color? accentColor;

  const MingrrImageGallery({
    super.key,
    required this.imageUrls,
    this.height = 200,
    this.itemWidth,
    this.fullWidthSingle = true,
    this.enableViewer = true,
    this.onShare,
    this.borderRadius = AppSizes.radiusS,
    this.accentColor,
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
    // 전체 너비 모드: 부모 너비에 맞추고 높이만 제한
    if (fullWidthSingle) {
      return GestureDetector(
        onTap: enableViewer ? () => _openViewer(context, 0) : null,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: height,
              minWidth: double.infinity,
            ),
            child: MingrrImage(
              imageUrl: imageUrls.first,
              fit: BoxFit.cover,
              shape: ImageShape.rounded,
              borderRadius: borderRadius,
              accentColor: accentColor,
            ),
          ),
        ),
      );
    }

    // 고정 크기 모드 (모달 등 소형 갤러리용)
    final width = itemWidth ?? height;
    return GestureDetector(
      onTap: enableViewer ? () => _openViewer(context, 0) : null,
      child: MingrrImage.thumbnail(
        imageUrl: imageUrls.first,
        width: width,
        height: height,
        radius: borderRadius,
        accentColor: accentColor,
      ),
    );
  }

  Widget _buildMultipleImages(BuildContext context) {
    // 기본 4:3 비율 (가로형)
    final width = itemWidth ?? (height * 4 / 3).roundToDouble();
    
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
              child: MingrrImage.thumbnail(
                imageUrl: imageUrls[index],
                width: width,
                height: height,
                radius: borderRadius,
                accentColor: accentColor,
              ),
            ),
          );
        },
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
