import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

/// ============================================================
/// 이미지 크롭 서비스
/// 
/// 기능:
/// - 원형 크롭 (프로필 이미지용)
/// - 사각형 크롭 (카드/배너 이미지용)
/// - 자유 비율 크롭
/// ============================================================

enum ImageCropStyle {
  circle,   // 원형 (프로필용)
  square,   // 정사각형 (1:1)
  card,     // 카드형 (4:3)
  wide,     // 와이드 (16:9)
  free,     // 자유 비율
}

class ImageCropService {
  static final ImageCropService _instance = ImageCropService._internal();
  factory ImageCropService() => _instance;
  ImageCropService._internal();

  final ImagePicker _picker = ImagePicker();

  /// 갤러리에서 이미지 선택 후 크롭
  Future<String?> pickAndCropImage({
    required ImageCropStyle style,
    int maxWidth = 1080,
    int maxHeight = 1080,
    int compressQuality = 85,
  }) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2000,
      maxHeight: 2000,
    );

    if (pickedFile == null) return null;

    return await cropImage(
      imagePath: pickedFile.path,
      style: style,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      compressQuality: compressQuality,
    );
  }

  /// 카메라로 촬영 후 크롭
  Future<String?> captureAndCropImage({
    required ImageCropStyle style,
    int maxWidth = 1080,
    int maxHeight = 1080,
    int compressQuality = 85,
  }) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 2000,
      maxHeight: 2000,
    );

    if (pickedFile == null) return null;

    return await cropImage(
      imagePath: pickedFile.path,
      style: style,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      compressQuality: compressQuality,
    );
  }

  /// 이미지 크롭
  Future<String?> cropImage({
    required String imagePath,
    required ImageCropStyle style,
    BuildContext? context,
    int maxWidth = 1080,
    int maxHeight = 1080,
    int compressQuality = 85,
  }) async {
    final cropStyle = style == ImageCropStyle.circle 
        ? CropStyle.circle 
        : CropStyle.rectangle;
    
    final aspectRatio = _getAspectRatio(style);
    final aspectRatioPresets = _getAspectRatioPresets(style);

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: imagePath,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      compressQuality: compressQuality,
      aspectRatio: aspectRatio,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: _getToolbarTitle(style),
          toolbarColor: context != null ? Theme.of(context).colorScheme.primary : const Color(0xFF6750A4),
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: context != null ? Theme.of(context).colorScheme.primary : const Color(0xFF6750A4),
          initAspectRatio: _getInitAspectRatio(style),
          lockAspectRatio: style != ImageCropStyle.free,
          aspectRatioPresets: aspectRatioPresets,
          cropStyle: cropStyle,
        ),
        IOSUiSettings(
          title: _getToolbarTitle(style),
          aspectRatioLockEnabled: style != ImageCropStyle.free,
          resetAspectRatioEnabled: style == ImageCropStyle.free,
          aspectRatioPickerButtonHidden: style != ImageCropStyle.free,
          aspectRatioPresets: aspectRatioPresets,
          cropStyle: cropStyle,
        ),
        if (context != null)
          WebUiSettings(
            context: context,
            presentStyle: WebPresentStyle.dialog,
            size: const CropperSize(width: 520, height: 520),
          ),
      ],
    );

    return croppedFile?.path;
  }

  /// 스타일별 비율 반환
  CropAspectRatio? _getAspectRatio(ImageCropStyle style) {
    switch (style) {
      case ImageCropStyle.circle:
      case ImageCropStyle.square:
        return const CropAspectRatio(ratioX: 1, ratioY: 1);
      case ImageCropStyle.card:
        return const CropAspectRatio(ratioX: 4, ratioY: 3);
      case ImageCropStyle.wide:
        return const CropAspectRatio(ratioX: 16, ratioY: 9);
      case ImageCropStyle.free:
        return null;
    }
  }

  /// 스타일별 초기 비율
  CropAspectRatioPreset _getInitAspectRatio(ImageCropStyle style) {
    switch (style) {
      case ImageCropStyle.circle:
      case ImageCropStyle.square:
        return CropAspectRatioPreset.square;
      case ImageCropStyle.card:
        return CropAspectRatioPreset.ratio4x3;
      case ImageCropStyle.wide:
        return CropAspectRatioPreset.ratio16x9;
      case ImageCropStyle.free:
        return CropAspectRatioPreset.original;
    }
  }

  /// 스타일별 비율 프리셋
  List<CropAspectRatioPreset> _getAspectRatioPresets(ImageCropStyle style) {
    switch (style) {
      case ImageCropStyle.circle:
      case ImageCropStyle.square:
        return [CropAspectRatioPreset.square];
      case ImageCropStyle.card:
        return [CropAspectRatioPreset.ratio4x3];
      case ImageCropStyle.wide:
        return [CropAspectRatioPreset.ratio16x9];
      case ImageCropStyle.free:
        return [
          CropAspectRatioPreset.original,
          CropAspectRatioPreset.square,
          CropAspectRatioPreset.ratio3x2,
          CropAspectRatioPreset.ratio4x3,
          CropAspectRatioPreset.ratio16x9,
        ];
    }
  }

  /// 스타일별 타이틀
  String _getToolbarTitle(ImageCropStyle style) {
    switch (style) {
      case ImageCropStyle.circle:
        return '프로필 사진 편집';
      case ImageCropStyle.square:
        return '사진 편집 (1:1)';
      case ImageCropStyle.card:
        return '사진 편집 (4:3)';
      case ImageCropStyle.wide:
        return '사진 편집 (16:9)';
      case ImageCropStyle.free:
        return '사진 편집';
    }
  }
}
