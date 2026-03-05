import 'package:flutter/material.dart';
import '../../constants/app_sizes.dart';

// ===== 동글동글한 카드 =====
/// 앱 전체에서 사용되는 기본 카드 스타일
/// 
/// 접근성:
/// - `semanticLabel`로 스크린 리더 지원
/// - `onTap`이 있으면 버튼으로 인식
class MingrrCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final double? borderRadius;
  final String? semanticLabel;

  const MingrrCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.borderRadius,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    Widget card = Container(
      margin: margin ?? const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingM,
        vertical: AppSizes.paddingS,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? (isDark ? const Color(0xFF1E1E1E) : Colors.white),
        borderRadius: BorderRadius.circular(borderRadius ?? AppSizes.radiusL),
        boxShadow: AppShadows.shadowS(isDark),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius ?? AppSizes.radiusL),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(AppSizes.paddingM),
            child: child,
          ),
        ),
      ),
    );

    if (semanticLabel != null || onTap != null) {
      return Semantics(
        button: onTap != null,
        label: semanticLabel,
        child: card,
      );
    }
    return card;
  }
}
