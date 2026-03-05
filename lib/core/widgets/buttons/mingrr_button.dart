import 'package:flutter/material.dart';
import '../../constants/app_icons.dart';
import '../../constants/app_sizes.dart';
import '../../theme/app_text_styles.dart';
import '../loading/loading_widgets.dart' show MingrrLoadingIndicator;

// ===== 동글동글한 버튼 =====
/// 앱의 메인 스타일 버튼 (노란색 배경)
class MingrrButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double height;

  const MingrrButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height = AppSizes.buttonHeightL,
  });

  @override
  Widget build(BuildContext context) {
    final buttonChild = isLoading
        ? MingrrLoadingIndicator.small(
            customColor: Theme.of(context).colorScheme.onSurface,
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: AppSizes.gapS),
              ],
              Text(text),
            ],
          );

    if (isOutlined) {
      return SizedBox(
        width: width ?? double.infinity,
        height: height,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: backgroundColor ?? Theme.of(context).colorScheme.primary,
              width: 1.5,
            ),
            foregroundColor: textColor ?? Theme.of(context).colorScheme.primary,
          ),
          child: buttonChild,
        ),
      );
    }

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.primary,
          foregroundColor: textColor ?? Theme.of(context).colorScheme.onSurface,
        ),
        child: buttonChild,
      ),
    );
  }
}

// ===== 소셜 로그인 버튼 =====
/// 카카오, 네이버, 구글 등 소셜 로그인용 버튼
class SocialLoginButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color textColor;
  final String? iconPath;
  final IconData? icon;

  const SocialLoginButton({
    super.key,
    required this.text,
    this.onPressed,
    required this.backgroundColor,
    required this.textColor,
    this.iconPath,
    this.icon,
  });

  // 카카오 로그인 버튼
  factory SocialLoginButton.kakao({
    required VoidCallback? onPressed,
  }) {
    return SocialLoginButton(
      text: '카카오로 시작하기',
      onPressed: onPressed,
      backgroundColor: const Color(0xFFFEE500),
      textColor: const Color(0xFF191919),
      icon: AppIcons.chatBubble,
    );
  }

  // 네이버 로그인 버튼
  factory SocialLoginButton.naver({
    required VoidCallback? onPressed,
  }) {
    return SocialLoginButton(
      text: '네이버로 시작하기',
      onPressed: onPressed,
      backgroundColor: const Color(0xFF03C75A),
      textColor: Colors.white,
      icon: AppIcons.arrowUp,
    );
  }

  // 구글 로그인 버튼
  factory SocialLoginButton.google({
    required VoidCallback? onPressed,
  }) {
    return SocialLoginButton(
      text: '구글로 시작하기',
      onPressed: onPressed,
      backgroundColor: Colors.white,
      textColor: const Color(0xFF757575),
      icon: AppIcons.profile,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppSizes.buttonHeightL,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: AppSizes.elevationS,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusL),
            side: backgroundColor == Colors.white
                ? BorderSide(color: Theme.of(context).colorScheme.outline)
                : BorderSide.none,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 24),
              const SizedBox(width: AppSizes.gapM),
            ],
            Text(
              text,
              style: AppTextStyles.titleLarge(context).withColor(textColor),
            ),
          ],
        ),
      ),
    );
  }
}
