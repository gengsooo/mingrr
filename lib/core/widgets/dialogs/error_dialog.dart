import 'package:flutter/material.dart';
import '../../constants/app_sizes.dart';
import '../svg_icons.dart';

/// ============================================================
/// ErrorDialog - 오류 다이얼로그
/// 
/// 오류 발생 시 사용자에게 안내하고 재시도/취소 선택을 제공
/// 화면 중앙에 표시되는 다이얼로그 형태
/// 
/// 사용법:
/// ```dart
/// final result = await showErrorDialog(
///   context,
///   type: ErrorType.location,
/// );
/// if (result == ErrorResult.retry) {
///   // 재시도 로직
/// }
/// ```
/// ============================================================

/// 오류 타입
enum ErrorType {
  /// 위치/GPS 오류
  location(
    icon: Icons.location_off_outlined,
    svgAsset: SvgAssets.errorLocation,
    color: Colors.red,
    title: '위치를 가져올 수 없습니다',
    message: 'GPS 신호가 약하거나 위치 서비스가 비활성화되어 있습니다.\n설정에서 위치 서비스를 확인해주세요.',
  ),
  
  /// 네트워크 오류
  network(
    icon: Icons.wifi_off_outlined,
    svgAsset: SvgAssets.errorNetwork,
    color: Colors.red,
    title: '네트워크 연결 오류',
    message: '인터넷 연결이 불안정합니다.\nWi-Fi 또는 모바일 데이터 연결을 확인해주세요.',
  ),
  
  /// 서버/API 오류
  server(
    icon: Icons.cloud_off_outlined,
    svgAsset: SvgAssets.errorServer,
    color: Colors.red,
    title: '서버 연결 오류',
    message: '서버와 연결할 수 없습니다.\n잠시 후 다시 시도해주세요.',
  ),
  
  /// 데이터베이스 오류
  database(
    icon: Icons.storage_outlined,
    svgAsset: SvgAssets.errorDatabase,
    color: Colors.red,
    title: '데이터 처리 오류',
    message: '데이터를 처리하는 중 문제가 발생했습니다.\n다시 시도해주세요.',
  ),
  
  /// 권한 오류
  permission(
    icon: Icons.lock_outline,
    svgAsset: SvgAssets.errorPermission,
    color: Colors.orange,
    title: '권한이 필요합니다',
    message: '이 기능을 사용하려면 권한이 필요합니다.\n설정에서 권한을 허용해주세요.',
  ),
  
  /// 데이터 로드 오류
  dataLoad(
    icon: Icons.error_outline,
    svgAsset: SvgAssets.errorServer,
    color: Colors.red,
    title: '데이터를 불러올 수 없습니다',
    message: '데이터를 가져오는 중 문제가 발생했습니다.\n다시 시도해주세요.',
  ),
  
  /// 이미지 업로드 오류
  imageUpload(
    icon: Icons.image_not_supported_outlined,
    svgAsset: SvgAssets.errorServer,
    color: Colors.red,
    title: '이미지 업로드 실패',
    message: '이미지를 업로드하는 중 문제가 발생했습니다.\n다시 시도해주세요.',
  ),
  
  /// 인증 오류
  auth(
    icon: Icons.person_off_outlined,
    svgAsset: SvgAssets.errorPermission,
    color: Colors.red,
    title: '인증 오류',
    message: '로그인 정보가 만료되었습니다.\n다시 로그인해주세요.',
  ),
  
  /// 타임아웃 오류
  timeout(
    icon: Icons.timer_off_outlined,
    svgAsset: SvgAssets.errorNetwork,
    color: Colors.orange,
    title: '요청 시간 초과',
    message: '요청 처리 시간이 초과되었습니다.\n다시 시도해주세요.',
  ),
  
  /// 일반 오류
  general(
    icon: Icons.warning_amber_outlined,
    svgAsset: SvgAssets.errorServer,
    color: Colors.red,
    title: '오류가 발생했습니다',
    message: '예기치 않은 오류가 발생했습니다.\n다시 시도해주세요.',
  );

  final IconData icon;
  final String svgAsset;
  final Color color;
  final String title;
  final String message;

  const ErrorType({
    required this.icon,
    required this.svgAsset,
    required this.color,
    required this.title,
    required this.message,
  });
}

/// 오류 다이얼로그 결과
enum ErrorResult {
  retry,
  cancel,
}

/// 오류 다이얼로그 표시 함수
Future<ErrorResult?> showErrorDialog(
  BuildContext context, {
  required ErrorType type,
  String? title,
  String? message,
  String? retryText,
  String? cancelText,
  Color? themeColor,
  bool showRetry = true,
}) {
  return showDialog<ErrorResult>(
    context: context,
    barrierDismissible: false,
    builder: (context) => ErrorDialog(
      type: type,
      title: title,
      message: message,
      retryText: retryText,
      cancelText: cancelText,
      themeColor: themeColor,
      showRetry: showRetry,
    ),
  );
}

/// ErrorDialog 위젯
class ErrorDialog extends StatelessWidget {
  final ErrorType type;
  final String? title;
  final String? message;
  final String? retryText;
  final String? cancelText;
  final Color? themeColor;
  final bool showRetry;

  const ErrorDialog({
    super.key,
    required this.type,
    this.title,
    this.message,
    this.retryText,
    this.cancelText,
    this.themeColor,
    this.showRetry = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = themeColor ?? type.color;
    
    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // SVG 일러스트
            MingrrSvgIcon(
              assetPath: type.svgAsset,
              width: 100,
              height: 100,
            ),
            const SizedBox(height: AppSizes.gapM),
            
            // 제목
            Text(
              title ?? type.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(height: AppSizes.gapS),
            
            // 메시지
            Text(
              message ?? type.message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSizes.gapXL),
            
            // 버튼
            if (showRetry)
              _buildTwoButtons(context, color)
            else
              _buildSingleButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => Navigator.pop(context, ErrorResult.cancel),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: BorderSide(color: Theme.of(context).colorScheme.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          cancelText ?? '닫기',
          style: TextStyle(
            fontSize: 15,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildTwoButtons(BuildContext context, Color color) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context, ErrorResult.cancel),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: Theme.of(context).colorScheme.outline),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              cancelText ?? '취소',
              style: TextStyle(
                fontSize: 15,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSizes.gapM),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, ErrorResult.retry),
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(
              retryText ?? '재시도',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
