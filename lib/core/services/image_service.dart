import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

/// ============================================================
/// 통합 이미지 서비스
/// 
/// 이미지 선택, 크롭, 유효성 검사를 단일 서비스로 통합
/// 
/// 기능:
/// - 갤러리/카메라에서 이미지 선택
/// - 스타일별 크롭 (원형, 정사각형, 카드, 와이드, 자유)
/// - 파일 크기/포맷 유효성 검사
/// - 네이티브 크롭 UI 테마 적용 (iOS/Android 공통 항목)
/// 
/// 사용법:
/// ```dart
/// // 단일 이미지 선택 + 크롭
/// final result = await ImageService.instance.pickAndCrop(
///   context: context,
///   source: ImageSource.gallery,
///   style: ImageCropStyle.circle,
/// );
/// 
/// // 여러 이미지 선택 + 각각 크롭
/// final results = await ImageService.instance.pickAndCropMultiple(
///   context: context,
///   style: ImageCropStyle.square,
///   maxCount: 5,
/// );
/// 
/// // 유효성 검사
/// final validation = ImageService.instance.validate(imagePath);
/// if (!validation.isValid) {
///   showError(validation.errorMessage);
/// }
/// ```
/// ============================================================

// ============================================================
// 크롭 스타일 정의
// ============================================================

/// 이미지 크롭 스타일
enum ImageCropStyle {
  /// 원형 (프로필용) - 1:1
  circle,
  /// 정사각형 - 1:1
  square,
  /// 카드형 - 4:3
  card,
  /// 와이드 - 16:9
  wide,
  /// 자유 비율
  free,
}

// ============================================================
// 이미지 제한 상수
// ============================================================

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
  
  /// 업로드 제한 안내 메시지
  static String get uploadLimitMessage =>
      '이미지는 최대 $maxImageCount장, 각 ${maxFileSizeMB}MB까지 업로드 가능합니다';

  /// 업로드 제한 상세 안내
  static String get uploadLimitDetailMessage => '''이미지 업로드 제한:
• 최대 개수: $maxImageCount장
• 파일 크기: 각 ${maxFileSizeMB}MB 이하
• 지원 형식: ${allowedFormats.map((f) => f.toUpperCase()).join(', ')}''';
}

// ============================================================
// 결과 클래스
// ============================================================

/// 이미지 처리 결과
class ImageResult {
  final File file;
  final String path;
  final int sizeBytes;

  const ImageResult({
    required this.file,
    required this.path,
    required this.sizeBytes,
  });

  /// 파일 크기 (MB)
  double get sizeMB => sizeBytes / (1024 * 1024);

  /// 파일 크기 포맷팅
  String get sizeFormatted {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${sizeMB.toStringAsFixed(1)} MB';
  }
  
  /// XFile로 변환
  XFile toXFile() => XFile(path);
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

// ============================================================
// 통합 이미지 서비스
// ============================================================

/// 통합 이미지 서비스 (싱글톤)
class ImageService {
  // 싱글톤 인스턴스
  static final ImageService _instance = ImageService._internal();
  static ImageService get instance => _instance;
  factory ImageService() => _instance;
  ImageService._internal();

  final ImagePicker _picker = ImagePicker();
  final ImageCropper _cropper = ImageCropper();

  // ============================================================
  // 메인 API - 이미지 선택 + 크롭
  // ============================================================

  /// 이미지 선택 + 크롭 (단일 이미지)
  /// 
  /// [context] BuildContext (테마 색상 적용용)
  /// [source] 이미지 소스 (갤러리/카메라)
  /// [style] 크롭 스타일
  /// [enableCrop] 크롭 활성화 여부 (기본 true)
  /// 
  /// Returns: ImageResult? (성공 시 결과, 취소/실패 시 null)
  Future<ImageResult?> pickAndCrop({
    required BuildContext context,
    required ImageSource source,
    required ImageCropStyle style,
    bool enableCrop = true,
  }) async {
    // 1. 이미지 선택
    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      maxWidth: 2000,
      maxHeight: 2000,
      imageQuality: 90,
    );

    if (pickedFile == null) return null;

    // 2. 웹이거나 크롭 비활성화 시 원본 반환
    if (kIsWeb || !enableCrop) {
      return _createResult(pickedFile.path);
    }

    // 3. 크롭 실행
    return await crop(
      context: context,
      imagePath: pickedFile.path,
      style: style,
    );
  }

  /// 이미지 크롭만 실행 (이미 선택된 이미지)
  /// 
  /// [context] BuildContext (테마 색상 적용용)
  /// [imagePath] 이미지 파일 경로
  /// [style] 크롭 스타일
  Future<ImageResult?> crop({
    required BuildContext context,
    required String imagePath,
    required ImageCropStyle style,
  }) async {
    // 웹에서는 크롭 미지원
    if (kIsWeb) {
      return _createResult(imagePath);
    }

    final croppedFile = await _cropper.cropImage(
      sourcePath: imagePath,
      maxWidth: ImageLimits.maxResolution,
      maxHeight: ImageLimits.maxResolution,
      compressQuality: ImageLimits.imageQuality,
      aspectRatio: _getAspectRatio(style),
      uiSettings: _buildUiSettings(context, style),
    );

    if (croppedFile == null) return null;

    return _createResult(croppedFile.path);
  }

  // ============================================================
  // 다중 이미지 선택
  // ============================================================

  /// 여러 이미지 선택 (크롭 없이)
  Future<List<ImageResult>> pickMultiple({
    int maxCount = ImageLimits.maxImageCount,
  }) async {
    final pickedFiles = await _picker.pickMultiImage(
      imageQuality: ImageLimits.imageQuality,
      maxWidth: ImageLimits.maxResolution.toDouble(),
      maxHeight: ImageLimits.maxResolution.toDouble(),
      limit: maxCount,
    );

    final results = <ImageResult>[];
    for (final file in pickedFiles) {
      final result = await _createResult(file.path);
      if (result != null) {
        results.add(result);
      }
    }
    return results;
  }

  /// 여러 이미지 선택 + 각각 크롭
  Future<List<ImageResult>> pickAndCropMultiple({
    required BuildContext context,
    required ImageCropStyle style,
    int maxCount = ImageLimits.maxImageCount,
  }) async {
    final pickedFiles = await _picker.pickMultiImage(
      imageQuality: 90,
      maxWidth: 2000,
      maxHeight: 2000,
      limit: maxCount,
    );

    if (pickedFiles.isEmpty) return [];

    // 웹에서는 크롭 미지원
    if (kIsWeb) {
      final results = <ImageResult>[];
      for (final file in pickedFiles) {
        final result = await _createResult(file.path);
        if (result != null) {
          results.add(result);
        }
      }
      return results;
    }

    // 각 이미지 크롭
    final results = <ImageResult>[];
    for (final file in pickedFiles) {
      final result = await crop(
        context: context,
        imagePath: file.path,
        style: style,
      );
      if (result != null) {
        results.add(result);
      }
    }
    return results;
  }

  // ============================================================
  // 유효성 검사
  // ============================================================

  /// 이미지 파일 유효성 검사
  ImageValidationResult validate(String imagePath) {
    final file = File(imagePath);

    // 파일 존재 확인
    if (!file.existsSync()) {
      return ImageValidationResult.invalid('파일을 찾을 수 없습니다');
    }

    // 파일 크기 확인
    final fileSizeBytes = file.lengthSync();
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
  }

  /// 파일 크기가 제한을 초과하는지 확인
  bool isFileTooLarge(String imagePath) {
    final file = File(imagePath);
    if (!file.existsSync()) return false;
    return file.lengthSync() > ImageLimits.maxFileSizeBytes;
  }

  // ============================================================
  // 유틸리티
  // ============================================================

  /// 파일 크기 포맷팅
  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// ImageResult 생성
  Future<ImageResult?> _createResult(String path) async {
    final file = File(path);
    if (!file.existsSync()) return null;
    
    final size = await file.length();
    return ImageResult(
      file: file,
      path: path,
      sizeBytes: size,
    );
  }

  // ============================================================
  // 네이티브 크롭 UI 설정 (iOS/Android 공통 항목만)
  // ============================================================

  List<PlatformUiSettings> _buildUiSettings(
    BuildContext context,
    ImageCropStyle style,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // 앱 테마 색상
    final primaryColor = colorScheme.primary;
    final onPrimaryColor = colorScheme.onPrimary;

    final cropStyle =
        style == ImageCropStyle.circle ? CropStyle.circle : CropStyle.rectangle;
    final aspectRatioPresets = _getAspectRatioPresets(style);
    final lockAspectRatio = style != ImageCropStyle.free;
    final title = _getToolbarTitle(style);

    return [
      // Android 설정 (공통 항목 + Android 전용 최적화)
      AndroidUiSettings(
        toolbarTitle: title,
        toolbarColor: primaryColor,
        toolbarWidgetColor: onPrimaryColor,
        activeControlsWidgetColor: primaryColor,
        lockAspectRatio: lockAspectRatio,
        hideBottomControls: false,
        initAspectRatio: _getInitAspectRatio(style),
        aspectRatioPresets: aspectRatioPresets,
        cropStyle: cropStyle,
      ),
      // iOS 설정 (공통 항목만)
      IOSUiSettings(
        title: title,
        cancelButtonTitle: '취소',
        doneButtonTitle: '완료',
        aspectRatioLockEnabled: lockAspectRatio,
        resetAspectRatioEnabled: !lockAspectRatio,
        aspectRatioPickerButtonHidden: lockAspectRatio,
        aspectRatioPresets: aspectRatioPresets,
        cropStyle: cropStyle,
      ),
      // Web 설정
      WebUiSettings(
        context: context,
        presentStyle: WebPresentStyle.dialog,
        size: const CropperSize(width: 520, height: 520),
      ),
    ];
  }

  // ============================================================
  // 스타일별 설정
  // ============================================================

  /// 스타일별 비율
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
        return '사진 편집';
      case ImageCropStyle.card:
        return '사진 편집';
      case ImageCropStyle.wide:
        return '사진 편집';
      case ImageCropStyle.free:
        return '사진 편집';
    }
  }
}
