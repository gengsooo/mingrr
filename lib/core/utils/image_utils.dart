import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'app_logger.dart';
import '../constants/app_sizes.dart';
import '../theme/app_text_styles.dart';
import '../widgets/sheets/mingrr_bottom_sheet.dart';
import '../services/image_service.dart';

/// ============================================================
/// 이미지 유틸리티 (레거시 호환용)
/// 
/// 주의: 새로운 코드에서는 ImageService를 직접 사용하세요.
/// 이 파일은 기존 코드와의 호환성을 위해 유지됩니다.
/// 
/// 권장 사용법:
/// ```dart
/// // ImageService 직접 사용 (권장)
/// final result = await ImageService.instance.pickAndCrop(
///   context: context,
///   source: ImageSource.gallery,
///   style: ImageCropStyle.circle,
/// );
/// ```
/// ============================================================

// ImageLimits, ImageValidationResult, ImageCropStyle은 ImageService에서 export
// 기존 코드 호환을 위해 re-export
export '../services/image_service.dart' 
    show ImageLimits, ImageValidationResult, ImageCropStyle, ImageResult;

/// 레거시 이미지 유틸리티 클래스
/// 
/// @deprecated ImageService를 직접 사용하세요.
class ImageUtils {
  static final ImagePicker _picker = ImagePicker();

  /// @deprecated ImageService.instance.pickAndCrop() 사용 권장
  static Future<File?> pickAndCropImage({
    required BuildContext context,
    ImageSource source = ImageSource.gallery,
    bool enableCrop = true,
  }) async {
    final result = await ImageService.instance.pickAndCrop(
      context: context,
      source: source,
      style: ImageCropStyle.square,
      enableCrop: enableCrop,
    );
    return result?.file;
  }

  /// 이미지 소스 선택 다이얼로그
  static Future<ImageSource?> showImageSourceDialog(BuildContext context) async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.only(
          left: AppSizes.paddingL,
          right: AppSizes.paddingL,
          bottom: AppSizes.paddingL,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.bottomSheetRadius)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BottomSheetHandle(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingS),
              child: Text(
                '이미지 선택',
                style: AppTextStyles.headlineSmall(ctx),
                textAlign: TextAlign.center,
              ),
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
              color: Theme.of(context).colorScheme.primary.withValues(alpha: AppOpacity.o10),
              borderRadius: BorderRadius.circular(AppSizes.radiusM),
            ),
            child: Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(height: 8),
          Text(label, style: AppTextStyles.bodyMedium(context)),
        ],
      ),
    );
  }

  /// 파일 크기 확인
  static Future<int> getFileSize(File file) async {
    return await file.length();
  }

  /// 파일 크기가 제한을 초과하는지 확인
  static Future<bool> isFileTooLarge(File file, {int? maxBytes}) async {
    final size = await getFileSize(file);
    return size > (maxBytes ?? ImageLimits.maxFileSizeBytes);
  }

  /// 파일 크기를 읽기 쉬운 형식으로 변환
  static String formatFileSize(int bytes) {
    return ImageService.instance.formatFileSize(bytes);
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

  /// 이미지 파일 유효성 검사
  static Future<ImageValidationResult> validateImage(String imagePath) async {
    return ImageService.instance.validate(imagePath);
  }

  /// 이미지 업로드 제한 안내 메시지
  static String get uploadLimitMessage => ImageLimits.uploadLimitMessage;

  /// 이미지 업로드 제한 상세 안내
  static String get uploadLimitDetailMessage => ImageLimits.uploadLimitDetailMessage;
}
