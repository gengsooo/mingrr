import 'package:flutter/material.dart';
import '../../constants/app_icons.dart';
import '../../constants/app_sizes.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/feature_colors.dart';

// ===== 배지 =====
/// 인증 배지, 상태 배지 등
class MingrrBadge extends StatelessWidget {
  final String text;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final bool isSmall;

  const MingrrBadge({
    super.key,
    required this.text,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.isSmall = false,
  });

  // 인증 배지 - 빌드 시점에 context에서 색상 가져옴
  static Widget verified(BuildContext context) {
    return MingrrBadge(
      text: '인증됨',
      backgroundColor: context.features.success,
      textColor: Colors.white,
      icon: AppIcons.verified,
    );
  }

  // 산책 중 배지 - 빌드 시점에 context에서 색상 가져옴
  static Widget walking(BuildContext context) {
    return MingrrBadge(
      text: '산책 중',
      backgroundColor: context.features.walk,
      textColor: Colors.white,
      icon: AppIcons.walk,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? AppSizes.paddingS : AppSizes.paddingM,
        vertical: isSmall ? AppSizes.paddingXS : AppSizes.paddingS,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: isSmall ? 12 : 14,
              color: textColor ?? Theme.of(context).colorScheme.onSurface,
            ),
            SizedBox(width: isSmall ? 2 : 4),
          ],
          Text(
            text,
            style: (isSmall ? AppTextStyles.labelSmall(context) : AppTextStyles.labelLarge(context))
                .withWeight(FontWeight.w600)
                .withColor(textColor ?? Theme.of(context).colorScheme.onSurface),
          ),
        ],
      ),
    );
  }
}
