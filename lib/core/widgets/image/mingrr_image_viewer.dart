import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:gal/gal.dart';
import '../../constants/app_icons.dart';
import 'package:path_provider/path_provider.dart';
import '../../constants/app_sizes.dart';
import '../common_widgets.dart';
import 'mingrr_image.dart';
import '../../utils/error_handler.dart';

/// ============================================================
/// 통합 이미지 뷰어 (MingrrImageViewer)
/// 
/// 단일/다중 이미지를 전체화면으로 보여주는 통합 뷰어
/// - PageView로 좌우 스와이프 (다중 이미지)
/// - InteractiveViewer로 확대/축소
/// - 이미지 저장 기능
/// - 공유 버튼 (옵션)
/// - Hero 애니메이션 지원
/// 
/// 사용법:
/// ```dart
/// // 단일 이미지
/// showMingrrImageViewer(context, imageUrls: [imageUrl]);
/// 
/// // 다중 이미지
/// showMingrrImageViewer(context, imageUrls: imageUrls, initialIndex: 2);
/// 
/// // 저장 버튼 포함
/// showMingrrImageViewer(context, imageUrls: [url], showSaveButton: true);
/// ```
/// ============================================================

class MingrrImageViewer extends StatefulWidget {
  /// 이미지 URL 목록
  final List<String> imageUrls;
  
  /// 시작 인덱스
  final int initialIndex;
  
  /// 확대/축소 활성화 (기본 true)
  final bool enableZoom;
  
  /// 저장 버튼 표시 여부
  final bool showSaveButton;
  
  /// 공유 버튼 콜백 (null이면 버튼 숨김)
  final VoidCallback? onShare;

  const MingrrImageViewer({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
    this.enableZoom = true,
    this.showSaveButton = true,
    this.onShare,
  });

  @override
  State<MingrrImageViewer> createState() => _MingrrImageViewerState();
}

class _MingrrImageViewerState extends State<MingrrImageViewer> {
  late PageController _pageController;
  late int _currentIndex;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: MingrrAppBar.dark(
        title: widget.imageUrls.length > 1
            ? '${_currentIndex + 1} / ${widget.imageUrls.length}'
            : null,
        actions: [
          // 저장 버튼
          if (widget.showSaveButton)
            _isSaving
                ? const Padding(
                    padding: EdgeInsets.all(AppSizes.paddingM),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  )
                : IconButton(
                    icon: const Icon(AppIcons.download, color: Colors.white),
                    onPressed: _saveCurrentImage,
                  ),
          // 공유 버튼
          if (widget.onShare != null)
            IconButton(
              icon: const Icon(AppIcons.share, color: Colors.white),
              onPressed: widget.onShare,
            ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.imageUrls.length,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemBuilder: (context, index) {
          final imageWidget = MingrrImage(
            imageUrl: widget.imageUrls[index],
            fit: BoxFit.contain,
            errorWidget: const Icon(
              AppIcons.imageNotSupported,
              color: Colors.white54,
              size: 64,
            ),
          );

          if (widget.enableZoom) {
            return InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(child: imageWidget),
            );
          }

          return Center(child: imageWidget);
        },
      ),
    );
  }

  /// 현재 이미지 저장
  Future<void> _saveCurrentImage() async {
    setState(() => _isSaving = true);
    
    try {
      final imageUrl = widget.imageUrls[_currentIndex];
      final response = await http.get(Uri.parse(imageUrl));
      
      if (response.statusCode != 200) {
        throw Exception('이미지 다운로드 실패');
      }
      
      // 임시 파일로 저장 후 갤러리에 추가
      final tempDir = await getTemporaryDirectory();
      final fileName = 'mingrr_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(response.bodyBytes);
      
      await Gal.putImage(file.path, album: 'MINGRR');
      
      // 임시 파일 삭제
      await file.delete();
      
      if (mounted) {
        MingrrSnackBar.success(context, '이미지가 저장되었습니다');
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e, tag: 'ImageViewer', operation: '이미지 저장');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

/// MingrrImageViewer를 표시하는 헬퍼 함수
void showMingrrImageViewer(
  BuildContext context, {
  required List<String> imageUrls,
  int initialIndex = 0,
  bool enableZoom = true,
  bool showSaveButton = true,
  VoidCallback? onShare,
}) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => MingrrImageViewer(
        imageUrls: imageUrls,
        initialIndex: initialIndex,
        enableZoom: enableZoom,
        showSaveButton: showSaveButton,
        onShare: onShare,
      ),
    ),
  );
}

/// 단일 이미지 뷰어 (dialogs/image_viewer.dart 대체)
/// 채팅 등에서 단일 이미지를 빠르게 보여줄 때 사용
void showImageViewer(
  BuildContext context, {
  required String imageUrl,
  bool showSaveButton = true,
}) {
  showMingrrImageViewer(
    context,
    imageUrls: [imageUrl],
    showSaveButton: showSaveButton,
  );
}
