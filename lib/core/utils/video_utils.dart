import 'dart:io';
import 'dart:typed_data';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'app_logger.dart';

/// ============================================================
/// 비디오 유틸리티
/// 비디오 썸네일 생성 및 관련 유틸리티 함수
/// ============================================================

/// 동영상 업로드 제한 상수
class VideoLimits {
  VideoLimits._();

  /// 최대 파일 크기 (50MB)
  static const int maxFileSizeBytes = 50 * 1024 * 1024;
  static const int maxFileSizeMB = 50;

  /// 최대 영상 길이 (60초)
  static const int maxDurationSeconds = 60;

  /// 최대 해상도 (720p)
  static const int maxResolutionHeight = 720;
  static const int maxResolutionWidth = 1280;

  /// 허용 포맷
  static const List<String> allowedFormats = ['mp4', 'mov', 'm4v'];

  /// 권장 포맷
  static const String recommendedFormat = 'mp4';
}

/// 동영상 유효성 검사 결과
class VideoValidationResult {
  final bool isValid;
  final String? errorMessage;
  final int? fileSizeBytes;
  final int? durationSeconds;

  const VideoValidationResult({
    required this.isValid,
    this.errorMessage,
    this.fileSizeBytes,
    this.durationSeconds,
  });

  factory VideoValidationResult.valid({int? fileSizeBytes, int? durationSeconds}) {
    return VideoValidationResult(
      isValid: true,
      fileSizeBytes: fileSizeBytes,
      durationSeconds: durationSeconds,
    );
  }

  factory VideoValidationResult.invalid(String message) {
    return VideoValidationResult(
      isValid: false,
      errorMessage: message,
    );
  }
}

class VideoUtils {
  VideoUtils._();

  /// 비디오 파일에서 썸네일 생성
  /// 
  /// [videoPath] 비디오 파일 경로
  /// [maxWidth] 썸네일 최대 너비 (기본값: 512)
  /// [quality] 썸네일 품질 0-100 (기본값: 75)
  /// 
  /// Returns: 썸네일 파일 또는 null (실패 시)
  static Future<File?> generateThumbnail(
    String videoPath, {
    int maxWidth = 512,
    int quality = 75,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: tempDir.path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: maxWidth,
        quality: quality,
      );
      
      if (thumbnailPath != null) {
        return File(thumbnailPath);
      }
      return null;
    } catch (e) {
      AppLogger.error('VideoUtils', '썸네일 생성 오류', e);
      return null;
    }
  }

  /// 비디오 파일에서 썸네일 바이트 데이터 생성
  /// 
  /// [videoPath] 비디오 파일 경로
  /// [maxWidth] 썸네일 최대 너비 (기본값: 512)
  /// [quality] 썸네일 품질 0-100 (기본값: 75)
  /// 
  /// Returns: 썸네일 바이트 데이터 또는 null (실패 시)
  static Future<Uint8List?> generateThumbnailData(
    String videoPath, {
    int maxWidth = 512,
    int quality = 75,
  }) async {
    try {
      final thumbnailData = await VideoThumbnail.thumbnailData(
        video: videoPath,
        imageFormat: ImageFormat.JPEG,
        maxWidth: maxWidth,
        quality: quality,
      );
      return thumbnailData;
    } catch (e) {
      AppLogger.error('VideoUtils', '썸네일 데이터 생성 오류', e);
      return null;
    }
  }

  /// 비디오 파일 확장자 확인
  static bool isVideoFile(String path) {
    final extension = path.toLowerCase().split('.').last;
    return ['mp4', 'mov', 'avi', 'mkv', 'webm', 'm4v'].contains(extension);
  }

  /// 비디오 파일 크기 포맷팅
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// 동영상 파일 유효성 검사
  /// 
  /// [videoPath] 비디오 파일 경로
  /// 
  /// Returns: VideoValidationResult (유효성 검사 결과)
  static Future<VideoValidationResult> validateVideo(String videoPath) async {
    try {
      final file = File(videoPath);
      
      // 파일 존재 확인
      if (!await file.exists()) {
        return VideoValidationResult.invalid('파일을 찾을 수 없습니다');
      }

      // 파일 크기 확인
      final fileSizeBytes = await file.length();
      if (fileSizeBytes > VideoLimits.maxFileSizeBytes) {
        final sizeMB = (fileSizeBytes / (1024 * 1024)).toStringAsFixed(1);
        return VideoValidationResult.invalid(
          '파일 크기가 너무 큽니다 (${sizeMB}MB). 최대 ${VideoLimits.maxFileSizeMB}MB까지 업로드 가능합니다',
        );
      }

      // 파일 포맷 확인
      final extension = videoPath.toLowerCase().split('.').last;
      if (!VideoLimits.allowedFormats.contains(extension)) {
        return VideoValidationResult.invalid(
          '지원하지 않는 파일 형식입니다. ${VideoLimits.allowedFormats.join(', ')} 형식만 업로드 가능합니다',
        );
      }

      return VideoValidationResult.valid(fileSizeBytes: fileSizeBytes);
    } catch (e) {
      AppLogger.error('VideoUtils', '동영상 유효성 검사 오류', e);
      return VideoValidationResult.invalid('동영상 파일을 확인할 수 없습니다');
    }
  }

  /// 동영상 업로드 제한 안내 메시지
  static String get uploadLimitMessage {
    return '동영상은 최대 ${VideoLimits.maxFileSizeMB}MB, ${VideoLimits.maxDurationSeconds}초까지 업로드 가능합니다';
  }

  /// 동영상 업로드 제한 상세 안내
  static String get uploadLimitDetailMessage {
    return '''동영상 업로드 제한:
• 파일 크기: 최대 ${VideoLimits.maxFileSizeMB}MB
• 영상 길이: 최대 ${VideoLimits.maxDurationSeconds}초
• 지원 형식: ${VideoLimits.allowedFormats.map((f) => f.toUpperCase()).join(', ')}''';
  }
}
