import 'package:flutter/material.dart';

/// ============================================================
/// 전체화면 이미지 뷰어
/// 
/// 이미지 목록을 전체화면으로 보여주는 뷰어
/// - PageView로 좌우 스와이프
/// - InteractiveViewer로 확대/축소
/// - 공유 버튼 (옵션)
/// ============================================================

class MingrrImageViewer extends StatefulWidget {
  /// 이미지 URL 목록
  final List<String> imageUrls;
  
  /// 시작 인덱스
  final int initialIndex;
  
  /// 확대/축소 활성화 (기본 true)
  final bool enableZoom;
  
  /// 공유 버튼 콜백 (null이면 버튼 숨김)
  final VoidCallback? onShare;

  const MingrrImageViewer({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
    this.enableZoom = true,
    this.onShare,
  });

  @override
  State<MingrrImageViewer> createState() => _MingrrImageViewerState();
}

class _MingrrImageViewerState extends State<MingrrImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

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
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${_currentIndex + 1} / ${widget.imageUrls.length}',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          if (widget.onShare != null)
            IconButton(
              icon: const Icon(Icons.share, color: Colors.white),
              onPressed: widget.onShare,
            ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.imageUrls.length,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemBuilder: (context, index) {
          final imageWidget = Image.network(
            widget.imageUrls[index],
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.image_not_supported,
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
}

/// MingrrImageViewer를 표시하는 헬퍼 함수
void showMingrrImageViewer(
  BuildContext context, {
  required List<String> imageUrls,
  int initialIndex = 0,
  bool enableZoom = true,
  VoidCallback? onShare,
}) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => MingrrImageViewer(
        imageUrls: imageUrls,
        initialIndex: initialIndex,
        enableZoom: enableZoom,
        onShare: onShare,
      ),
    ),
  );
}
