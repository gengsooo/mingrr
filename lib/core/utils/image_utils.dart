import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'app_logger.dart';
import '../constants/app_sizes.dart';
import '../widgets/mingrr_bottom_sheet.dart';

/// ============================================================
/// 이미지 유틸리티
/// 이미지 선택, 크롭, 최적화 기능 제공
/// ============================================================

/// 이미지 업로드 제한 상수
class ImageLimits {
  ImageLimits._();

  /// 최대 파일 크기 (10MB)
  static const int maxFileSizeBytes = 10 * 1024 * 1024;
  static const int maxFileSizeMB = 10;

  /// 권장 파일 크기 (1MB)
  static const int recommendedFileSizeBytes = 1 * 1024 * 1024;

  /// 최대 해상도 (1200px)
  static const int maxResolution = 1200;

  /// 이미지 품질 (80%)
  static const int imageQuality = 80;

  /// 최대 이미지 수
  static const int maxImageCount = 10;

  /// 허용 포맷
  static const List<String> allowedFormats = ['jpg', 'jpeg', 'png'];

  /// 권장 포맷
  static const String recommendedFormat = 'jpeg';
}

/// 이미지 유효성 검사 결과
class ImageValidationResult {
  final bool isValid;
  final String? errorMessage;
  final int? fileSizeBytes;

  const ImageValidationResult({
    required this.isValid,
    this.errorMessage,
    this.fileSizeBytes,
  });

  factory ImageValidationResult.valid({int? fileSizeBytes}) {
    return ImageValidationResult(
      isValid: true,
      fileSizeBytes: fileSizeBytes,
    );
  }

  factory ImageValidationResult.invalid(String message) {
    return ImageValidationResult(
      isValid: false,
      errorMessage: message,
    );
  }
}

class ImageUtils {
  static final ImagePicker _picker = ImagePicker();
  
  /// 최대 파일 크기 (10MB) - ImageLimits 사용 권장
  static const int maxFileSizeBytes = ImageLimits.maxFileSizeBytes;
  
  /// 권장 파일 크기 (1MB)
  static const int recommendedFileSizeBytes = ImageLimits.recommendedFileSizeBytes;

  /// 이미지 선택 및 크롭 (단일 이미지)
  static Future<File?> pickAndCropImage({
    required BuildContext context,
    ImageSource source = ImageSource.gallery,
    CropAspectRatio? aspectRatio,
    int maxWidth = 1024,
    int maxHeight = 1024,
    int imageQuality = 80,
    Color? toolbarColor,
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
            toolbarColor: toolbarColor ?? Theme.of(context).colorScheme.primary,
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
      AppLogger.error('ImageUtils', '이미지 선택/크롭 오류', e);
      return null;
    }
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
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '이미지 선택',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
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
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary),
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
    Color? toolbarColor,
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
    Color? toolbarColor,
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
    Color? toolbarColor,
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
    required BuildContext context,
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
              toolbarColor: Theme.of(context).colorScheme.primary,
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
    Color? toolbarColor,
    int maxBytes = recommendedFileSizeBytes,
  }) async {
    final file = await pickImageWithDialog(
      context: context,
      aspectRatio: aspectRatio,
      toolbarColor: toolbarColor,
    );
    
    if (file == null) return null;
    
    // 최적화 적용
    return optimizeImage(file, context: context, maxBytes: maxBytes);
  }
  
  /// 여러 이미지 선택 (갤러리에서)
  static Future<List<File>> pickMultipleImages({
    int maxImages = ImageLimits.maxImageCount,
    int imageQuality = ImageLimits.imageQuality,
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
  /// 
  /// [imagePath] 이미지 파일 경로
  /// 
  /// Returns: ImageValidationResult (유효성 검사 결과)
  static Future<ImageValidationResult> validateImage(String imagePath) async {
    try {
      final file = File(imagePath);
      
      // 파일 존재 확인
      if (!await file.exists()) {
        return ImageValidationResult.invalid('파일을 찾을 수 없습니다');
      }

      // 파일 크기 확인
      final fileSizeBytes = await file.length();
      if (fileSizeBytes > ImageLimits.maxFileSizeBytes) {
        final sizeMB = (fileSizeBytes / (1024 * 1024)).toStringAsFixed(1);
        return ImageValidationResult.invalid(
          '파일 크기가 너무 큽니다 (${sizeMB}MB). 최대 ${ImageLimits.maxFileSizeMB}MB까지 업로드 가능합니다',
        );
      }

      // 파일 포맷 확인
      final extension = imagePath.toLowerCase().split('.').last;
      if (!ImageLimits.allowedFormats.contains(extension)) {
        return ImageValidationResult.invalid(
          '지원하지 않는 파일 형식입니다. ${ImageLimits.allowedFormats.map((f) => f.toUpperCase()).join(', ')} 형식만 업로드 가능합니다',
        );
      }

      return ImageValidationResult.valid(fileSizeBytes: fileSizeBytes);
    } catch (e) {
      AppLogger.error('ImageUtils', '이미지 유효성 검사 오류', e);
      return ImageValidationResult.invalid('이미지 파일을 확인할 수 없습니다');
    }
  }

  /// 이미지 업로드 제한 안내 메시지
  static String get uploadLimitMessage {
    return '이미지는 최대 ${ImageLimits.maxImageCount}장, 각 ${ImageLimits.maxFileSizeMB}MB까지 업로드 가능합니다';
  }

  /// 이미지 업로드 제한 상세 안내
  static String get uploadLimitDetailMessage {
    return '''이미지 업로드 제한:
• 최대 개수: ${ImageLimits.maxImageCount}장
• 파일 크기: 각 ${ImageLimits.maxFileSizeMB}MB 이하
• 지원 형식: ${ImageLimits.allowedFormats.map((f) => f.toUpperCase()).join(', ')}''';
  }
}
