import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../constants/app_colors.dart';

/// ============================================================
/// 이미지 유틸리티
/// 이미지 선택 및 크롭 기능 제공
/// ============================================================

class ImageUtils {
  static final ImagePicker _picker = ImagePicker();

  /// 이미지 선택 및 크롭 (단일 이미지)
  static Future<File?> pickAndCropImage({
    required BuildContext context,
    ImageSource source = ImageSource.gallery,
    CropAspectRatio? aspectRatio,
    int maxWidth = 1024,
    int maxHeight = 1024,
    int imageQuality = 80,
    Color toolbarColor = AppColors.primary,
    Color toolbarWidgetColor = Colors.white,
  }) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        imageQuality: imageQuality,
      );

      if (pickedFile == null) return null;

      // 크롭 실행
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: aspectRatio,
        compressQuality: imageQuality,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: '이미지 편집',
            toolbarColor: toolbarColor,
            toolbarWidgetColor: toolbarWidgetColor,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: aspectRatio != null,
            hideBottomControls: false,
          ),
          IOSUiSettings(
            title: '이미지 편집',
            cancelButtonTitle: '취소',
            doneButtonTitle: '완료',
            aspectRatioLockEnabled: aspectRatio != null,
          ),
        ],
      );

      if (croppedFile == null) return null;
      return File(croppedFile.path);
    } catch (e) {
      debugPrint('이미지 선택/크롭 오류: $e');
      return null;
    }
  }

  /// 이미지 소스 선택 다이얼로그
  static Future<ImageSource?> showImageSourceDialog(BuildContext context) async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '이미지 선택',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSourceOption(
                  context: ctx,
                  icon: Icons.camera_alt,
                  label: '카메라',
                  source: ImageSource.camera,
                ),
                _buildSourceOption(
                  context: ctx,
                  icon: Icons.photo_library,
                  label: '갤러리',
                  source: ImageSource.gallery,
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  static Widget _buildSourceOption({
    required BuildContext context,
    required IconData icon,
    required String label,
    required ImageSource source,
  }) {
    return GestureDetector(
      onTap: () => Navigator.pop(context, source),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 28, color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  /// 이미지 선택 + 소스 선택 다이얼로그 + 크롭 (통합)
  static Future<File?> pickImageWithDialog({
    required BuildContext context,
    CropAspectRatio? aspectRatio,
    Color toolbarColor = AppColors.primary,
  }) async {
    final source = await showImageSourceDialog(context);
    if (source == null) return null;

    return pickAndCropImage(
      context: context,
      source: source,
      aspectRatio: aspectRatio,
      toolbarColor: toolbarColor,
    );
  }

  /// 정사각형 크롭 (프로필 이미지용)
  static Future<File?> pickSquareImage({
    required BuildContext context,
    Color toolbarColor = AppColors.primary,
  }) async {
    return pickImageWithDialog(
      context: context,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      toolbarColor: toolbarColor,
    );
  }

  /// 16:9 크롭 (커버 이미지용)
  static Future<File?> pickCoverImage({
    required BuildContext context,
    Color toolbarColor = AppColors.primary,
  }) async {
    return pickImageWithDialog(
      context: context,
      aspectRatio: const CropAspectRatio(ratioX: 16, ratioY: 9),
      toolbarColor: toolbarColor,
    );
  }
}
