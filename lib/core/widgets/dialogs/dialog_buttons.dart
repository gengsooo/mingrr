import 'package:flutter/material.dart';
import '../../constants/app_sizes.dart';
import '../../theme/app_text_styles.dart';

/// ============================================================
/// MingrrDialogButtons - 다이얼로그/바텀시트 전용 버튼 컴포넌트
/// 
/// 다이얼로그, 바텀시트에서 사용하는 취소/확인 버튼 쌍
/// 메인 화면의 MingrrButton과 분리하여 관심사 분리 원칙 준수
/// 
/// 사용법:
/// ```dart
/// // 버튼 쌍 (취소 + 확인)
/// MingrrDialogButtons(
///   onCancel: () => Navigator.pop(context),
///   onConfirm: () => doSomething(),
///   confirmColor: Colors.red,
/// )
/// 
/// // 단일 버튼
/// MingrrDialogButton.cancel(onPressed: () => Navigator.pop(context))
/// MingrrDialogButton.confirm(text: '저장', onPressed: () => save())
/// ```
/// ============================================================

/// 다이얼로그 버튼 쌍 (취소 + 확인)
class MingrrDialogButtons extends StatelessWidget {
  final String cancelText;
  final String confirmText;
  final VoidCallback? onCancel;
  final VoidCallback? onConfirm;
  final Color? confirmColor;
  final double height;
  final bool isLoading;

  const MingrrDialogButtons({
    super.key,
    this.cancelText = '취소',
    this.confirmText = '확인',
    this.onCancel,
    this.onConfirm,
    this.confirmColor,
    this.height = 48,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: MingrrDialogButton.cancel(
            text: cancelText,
            onPressed: onCancel,
            height: height,
          ),
        ),
        const SizedBox(width: AppSizes.gapM),
        Expanded(
          child: MingrrDialogButton.confirm(
            text: confirmText,
            onPressed: onConfirm,
            color: confirmColor,
            height: height,
            isLoading: isLoading,
          ),
        ),
      ],
    );
  }
}

/// 다이얼로그 단일 버튼
class MingrrDialogButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? textColor;
  final bool isOutlined;
  final double height;
  final bool isLoading;
  final IconData? icon;

  const MingrrDialogButton({
    super.key,
    required this.text,
    this.onPressed,
    this.color,
    this.textColor,
    this.isOutlined = false,
    this.height = 48,
    this.isLoading = false,
    this.icon,
  });

  /// 취소 버튼 (Outlined 스타일)
  factory MingrrDialogButton.cancel({
    Key? key,
    String text = '취소',
    VoidCallback? onPressed,
    double height = 48,
  }) {
    return MingrrDialogButton(
      key: key,
      text: text,
      onPressed: onPressed,
      isOutlined: true,
      height: height,
    );
  }

  /// 확인 버튼 (Filled 스타일)
  factory MingrrDialogButton.confirm({
    Key? key,
    String text = '확인',
    VoidCallback? onPressed,
    Color? color,
    double height = 48,
    bool isLoading = false,
    IconData? icon,
  }) {
    return MingrrDialogButton(
      key: key,
      text: text,
      onPressed: onPressed,
      color: color,
      isOutlined: false,
      height: height,
      isLoading: isLoading,
      icon: icon,
    );
  }

  /// 위험 동작 버튼 (삭제 등)
  factory MingrrDialogButton.destructive({
    Key? key,
    String text = '삭제',
    VoidCallback? onPressed,
    double height = 48,
    bool isLoading = false,
  }) {
    return MingrrDialogButton(
      key: key,
      text: text,
      onPressed: onPressed,
      color: Colors.red,
      textColor: Colors.white,
      isOutlined: false,
      height: height,
      isLoading: isLoading,
    );
  }

  /// 위험 동작 취소 버튼 (Outlined 빨간색)
  factory MingrrDialogButton.destructiveOutlined({
    Key? key,
    String text = '삭제',
    VoidCallback? onPressed,
    double height = 48,
  }) {
    return MingrrDialogButton(
      key: key,
      text: text,
      onPressed: onPressed,
      color: Colors.red,
      textColor: Colors.red,
      isOutlined: true,
      height: height,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    if (isOutlined) {
      return _buildOutlinedButton(context, colorScheme);
    }
    return _buildFilledButton(context, colorScheme);
  }

  Widget _buildOutlinedButton(BuildContext context, ColorScheme colorScheme) {
    final borderColor = color ?? colorScheme.outline;
    final foregroundColor = textColor ?? colorScheme.onSurfaceVariant;
    
    return SizedBox(
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: foregroundColor,
          side: BorderSide(color: borderColor, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusS),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          text,
          style: AppTextStyles.titleMedium(context).copyWith(
            color: foregroundColor,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildFilledButton(BuildContext context, ColorScheme colorScheme) {
    final bgColor = color ?? colorScheme.primary;
    final fgColor = textColor ?? Colors.white;
    
    return SizedBox(
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          disabledBackgroundColor: bgColor.withValues(alpha: 0.6),
          disabledForegroundColor: fgColor.withValues(alpha: 0.6),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusS),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(fgColor),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18),
                    const SizedBox(width: AppSizes.gapXS),
                  ],
                  Flexible(
                    child: Text(
                      text,
                      style: AppTextStyles.titleMedium(context).copyWith(
                        color: fgColor,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
