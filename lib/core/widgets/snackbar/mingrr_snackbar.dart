import 'package:flutter/material.dart';
import '../../constants/app_sizes.dart';
import '../../theme/feature_colors.dart';

// ===== 공통 SnackBar 헬퍼 =====
/// SnackBar를 쉽게 표시하기 위한 헬퍼 클래스
class MingrrSnackBar {
  MingrrSnackBar._();

  /// 성공 메시지 표시 (녹색)
  static void success(BuildContext context, String message) {
    _show(context, message, context.features.success);
  }

  /// 에러 메시지 표시 (빨간색)
  static void error(BuildContext context, String message) {
    _show(context, message, Theme.of(context).colorScheme.error);
  }

  /// 정보 메시지 표시 (기본 색상)
  static void info(BuildContext context, String message) {
    _show(context, message, Theme.of(context).colorScheme.onSurfaceVariant);
  }

  /// 경고 메시지 표시 (주황색)
  static void warning(BuildContext context, String message) {
    _show(context, message, Theme.of(context).colorScheme.tertiary);
  }

  /// 커스텀 SnackBar 표시
  static void _show(BuildContext context, String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusS)),
        margin: const EdgeInsets.all(AppSizes.paddingL),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 액션이 있는 SnackBar 표시
  static void withAction(
    BuildContext context, {
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
    Color? backgroundColor,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.onSurfaceVariant,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusS)),
        margin: const EdgeInsets.all(AppSizes.paddingL),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: actionLabel,
          textColor: Colors.white,
          onPressed: onAction,
        ),
      ),
    );
  }
}
