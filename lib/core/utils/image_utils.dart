import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../constants/app_colors.dart';
import 'app_logger.dart';

/// ============================================================
/// 이미지 유틸리티
/// 이미지 선택, 크롭, 최적화 기능 제공
/// ============================================================

class ImageUtils {
  static final ImagePicker _picker = ImagePicker();
  
  /// 최대 파일 크기 (5MB)
  static const int maxFileSizeBytes = 5 * 1024 * 1024;
  
  /// 권장 파일 크기 (1MB)
  static const int recommendedFileSizeBytes = 1 * 1024 * 1024;

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
  
  /// 파일 크기 확인
  static Future<int> getFileSize(File file) async {
    return await file.length();
  }
  
  /// 파일 크기가 제한을 초과하는지 확인
  static Future<bool> isFileTooLarge(File file, {int? maxBytes}) async {
    final size = await getFileSize(file);
    return size > (maxBytes ?? maxFileSizeBytes);
  }
  
  /// 파일 크기를 읽기 쉬운 형식으로 변환
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  
  /// 이미지 최적화 (크기 제한 적용)
  /// 파일이 maxBytes를 초과하면 품질을 낮춰서 재압축
  static Future<File?> optimizeImage(
    File file, {
    int maxBytes = recommendedFileSizeBytes,
    int minQuality = 50,
  }) async {
    try {
      var currentFile = file;
      var currentSize = await getFileSize(currentFile);
      var quality = 80;
      
      AppLogger.debug('ImageUtils', '원본 크기: ${formatFileSize(currentSize)}');
      
      // 이미 충분히 작으면 그대로 반환
      if (currentSize <= maxBytes) {
        return currentFile;
      }
      
      // 품질을 낮춰가며 압축
      while (currentSize > maxBytes && quality >= minQuality) {
        quality -= 10;
        
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: file.path,
          compressQuality: quality,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: '이미지 최적화',
              toolbarColor: AppColors.primary,
              toolbarWidgetColor: Colors.white,
              hideBottomControls: true,
              lockAspectRatio: false,
            ),
            IOSUiSettings(
              title: '이미지 최적화',
              hidesNavigationBar: true,
            ),
          ],
        );
        
        if (croppedFile != null) {
          currentFile = File(croppedFile.path);
          currentSize = await getFileSize(currentFile);
          AppLogger.debug('ImageUtils', '압축 후 크기 (품질 $quality%): ${formatFileSize(currentSize)}');
        }
      }
      
      if (currentSize > maxFileSizeBytes) {
        AppLogger.warning('ImageUtils', '이미지가 여전히 너무 큽니다: ${formatFileSize(currentSize)}');
      }
      
      return currentFile;
    } catch (e) {
      AppLogger.error('ImageUtils', '이미지 최적화 실패', e);
      return file; // 실패 시 원본 반환
    }
  }
  
  /// 이미지 선택 + 크롭 + 최적화 (통합)
  static Future<File?> pickOptimizedImage({
    required BuildContext context,
    CropAspectRatio? aspectRatio,
    Color toolbarColor = AppColors.primary,
    int maxBytes = recommendedFileSizeBytes,
  }) async {
    final file = await pickImageWithDialog(
      context: context,
      aspectRatio: aspectRatio,
      toolbarColor: toolbarColor,
    );
    
    if (file == null) return null;
    
    // 최적화 적용
    return optimizeImage(file, maxBytes: maxBytes);
  }
  
  /// 여러 이미지 선택 (갤러리에서)
  static Future<List<File>> pickMultipleImages({
    int maxImages = 10,
    int imageQuality = 80,
  }) async {
    try {
      final pickedFiles = await _picker.pickMultiImage(
        imageQuality: imageQuality,
        limit: maxImages,
      );
      
      return pickedFiles.map((xFile) => File(xFile.path)).toList();
    } catch (e) {
      AppLogger.error('ImageUtils', '다중 이미지 선택 실패', e);
      return [];
    }
  }
}
