import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// ============================================================
/// 로컬 이미지 미리보기 위젯
/// 
/// 카메라/갤러리에서 선택한 이미지(XFile)를 플랫폼에 맞게 표시합니다.
/// - Web: Image.network (XFile.path가 blob URL)
/// - Mobile: Image.file
/// 
/// 사용 예시:
/// ```dart
/// LocalImagePreview(
///   path: xFile.path,
///   width: 120,
///   height: 120,
///   fit: BoxFit.cover,
///   shape: ImagePreviewShape.circle,
/// )
/// ```
/// ============================================================

/// 미리보기 이미지 모양
enum ImagePreviewShape {
  /// 사각형 (기본)
  rectangle,
  /// 원형
  circle,
  /// 둥근 모서리
  rounded,
}

/// 로컬 파일 이미지 미리보기
class LocalImagePreview extends StatelessWidget {
  /// 이미지 파일 경로 (XFile.path)
  final String path;

  /// 이미지 너비
  final double? width;

  /// 이미지 높이
  final double? height;

  /// 이미지 맞춤 방식
  final BoxFit fit;

  /// 이미지 모양
  final ImagePreviewShape shape;

  /// 둥근 모서리 반경 (shape가 rounded일 때)
  final double borderRadius;

  const LocalImagePreview({
    super.key,
    required this.path,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.shape = ImagePreviewShape.rectangle,
    this.borderRadius = 8.0,
  });

  /// 원형 미리보기 편의 생성자
  const LocalImagePreview.circle({
    super.key,
    required this.path,
    double size = 120,
    this.fit = BoxFit.cover,
  }) : width = size,
       height = size,
       shape = ImagePreviewShape.circle,
       borderRadius = 0;

  @override
  Widget build(BuildContext context) {
    final image = kIsWeb
        ? Image.network(path, width: width, height: height, fit: fit)
        : Image.file(File(path), width: width, height: height, fit: fit);

    switch (shape) {
      case ImagePreviewShape.circle:
        return ClipOval(child: image);
      case ImagePreviewShape.rounded:
        return ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: image,
        );
      case ImagePreviewShape.rectangle:
        return image;
    }
  }
}
