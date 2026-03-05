import 'package:flutter/material.dart';
import '../../constants/app_icons.dart';
import '../../constants/app_sizes.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/feature_colors.dart';

// 하위 호환성 유지를 위한 re-export
export 'like_widgets.dart';
export 'pet_badges.dart';

/// ============================================================
/// 정보 배지 위젯 모음
/// 
/// 크기별 variant: small, medium, large
/// 
/// 포함 컴포넌트:
/// - DistanceBadge: 거리 표시 (예: 1.2km)
/// - MatchScoreBadge: 궁합 점수 표시 (예: 95%)
/// - GenderAgeBadge: 성별/나이 표시 (예: 남아 · 3살)
/// - InfoBadge: 범용 정보 배지
/// ============================================================

/// 배지 크기 enum
enum InfoBadgeSize {
  small,
  medium,
  large;
  
  /// 크기별 TextStyle 반환
  TextStyle getTextStyle(BuildContext context) {
    switch (this) {
      case InfoBadgeSize.small:
        return AppTextStyles.labelSmall(context);   // 10px
      case InfoBadgeSize.medium:
        return AppTextStyles.bodySmall(context);    // 12px
      case InfoBadgeSize.large:
        return AppTextStyles.bodyLarge(context);    // 14px
    }
  }
  
  /// 크기별 BorderRadius 반환
  double get borderRadius {
    switch (this) {
      case InfoBadgeSize.small:
        return AppSizes.radiusS;
      case InfoBadgeSize.medium:
        return AppSizes.radiusM;
      case InfoBadgeSize.large:
        return AppSizes.radiusL;
    }
  }
}

/// 범용 정보 배지
class InfoBadge extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? iconColor;
  final InfoBadgeSize size;

  const InfoBadge({
    super.key,
    required this.text,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.iconColor,
    this.size = InfoBadgeSize.medium,
  });

  double get _iconSize {
    switch (size) {
      case InfoBadgeSize.small:
        return 12;
      case InfoBadgeSize.medium:
        return 14;
      case InfoBadgeSize.large:
        return 16;
    }
  }

  EdgeInsets get _padding {
    switch (size) {
      case InfoBadgeSize.small:
        return const EdgeInsets.symmetric(horizontal: 6, vertical: AppSizes.paddingXXS);
      case InfoBadgeSize.medium:
        return const EdgeInsets.symmetric(horizontal: AppSizes.paddingS, vertical: AppSizes.paddingXS);
      case InfoBadgeSize.large:
        return const EdgeInsets.symmetric(horizontal: AppSizes.paddingS, vertical: AppSizes.paddingXS);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? Theme.of(context).colorScheme.surface;
    final txtColor = textColor ?? Theme.of(context).colorScheme.onSurfaceVariant;
    final icnColor = iconColor ?? txtColor;

    return Container(
      padding: _padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(size.borderRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: _iconSize, color: icnColor),
            SizedBox(width: size == InfoBadgeSize.small ? 2 : 4),
          ],
          Text(
            text,
            style: size.getTextStyle(context).withWeight(FontWeight.w500).withColor(txtColor),
          ),
        ],
      ),
    );
  }
}

/// 궁합 배지 스타일
enum MatchBadgeStyle {
  /// 투명 배경 + 색상 텍스트 (홈 추천친구)
  transparent,
  /// 불투명 배경 + 흰색 텍스트 (데이팅 리스트 카드, 상세화면)
  filled,
  /// 이미지 오버레이용 (반투명 검정 배경)
  overlay,
}

/// 궁합 점수 배지
/// 
/// 사용처:
/// - 홈 추천친구 카드: style=transparent
/// - 데이팅 추천친구 리스트 카드: style=filled
/// - 데이팅 상세화면 이미지 헤더: style=filled, showInfoIcon=true
/// - 근처검색 카드: style=transparent
class MatchScoreBadge extends StatelessWidget {
  final int score;
  final InfoBadgeSize size;
  final MatchBadgeStyle style;
  final bool showIcon;
  final bool showLabel;
  final bool showInfoIcon; // 정보 아이콘 (상세화면용)
  final VoidCallback? onTap;

  const MatchScoreBadge({
    super.key,
    required this.score,
    this.size = InfoBadgeSize.medium,
    this.style = MatchBadgeStyle.transparent,
    this.showIcon = true,
    this.showLabel = true,
    this.showInfoIcon = false,
    this.onTap,
  });

  /// 점수에 따른 기본 색상 (공통 로직)
  static Color getScoreColor(BuildContext context, int score) {
    final features = context.features;
    if (score >= 90) return features.success;
    if (score >= 70) return features.dating;
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }

  /// 스타일에 따른 배경색
  Color _getBackgroundColor(BuildContext context) {
    final baseColor = getScoreColor(context, score);
    switch (style) {
      case MatchBadgeStyle.transparent:
        return baseColor.withValues(alpha: AppOpacity.o15);
      case MatchBadgeStyle.filled:
        return baseColor;
      case MatchBadgeStyle.overlay:
        return Colors.black.withValues(alpha: AppOpacity.o50);
    }
  }

  /// 스타일에 따른 텍스트색
  Color _getTextColor(BuildContext context) {
    switch (style) {
      case MatchBadgeStyle.transparent:
        return getScoreColor(context, score);
      case MatchBadgeStyle.filled:
      case MatchBadgeStyle.overlay:
        return Colors.white;
    }
  }

  String get _displayText {
    return showLabel ? '궁합 $score%' : '$score%';
  }

  double get _iconSize {
    switch (size) {
      case InfoBadgeSize.small:
        return 12;
      case InfoBadgeSize.medium:
        return 14;
      case InfoBadgeSize.large:
        return 16;
    }
  }

  EdgeInsets get _padding {
    switch (size) {
      case InfoBadgeSize.small:
        return const EdgeInsets.symmetric(horizontal: 6, vertical: AppSizes.paddingXXS);
      case InfoBadgeSize.medium:
        return const EdgeInsets.symmetric(horizontal: AppSizes.paddingS, vertical: AppSizes.paddingXS);
      case InfoBadgeSize.large:
        return const EdgeInsets.symmetric(horizontal: AppSizes.paddingM, vertical: AppSizes.paddingXS);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _getBackgroundColor(context);
    final textColor = _getTextColor(context);
    
    final badge = Container(
      padding: _padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(size.borderRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(AppIcons.star, size: _iconSize, color: textColor),
            SizedBox(width: size == InfoBadgeSize.small ? 2 : 4),
          ],
          Text(
            _displayText,
            style: size.getTextStyle(context).withWeight(FontWeight.w600).withColor(textColor),
          ),
          if (showInfoIcon) ...[
            const SizedBox(width: AppSizes.gapXS),
            Icon(AppIcons.info, size: _iconSize - 2, color: textColor.withValues(alpha: AppOpacity.o70)),
          ],
        ],
      ),
    );
    
    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: badge);
    }
    return badge;
  }
}

/// 성별/나이 배지
class GenderAgeBadge extends StatelessWidget {
  final bool isMale;
  final int? age;
  final String? ageString; // "3살" 형태로 직접 전달 가능
  final InfoBadgeSize size;

  const GenderAgeBadge({
    super.key,
    required this.isMale,
    this.age,
    this.ageString,
    this.size = InfoBadgeSize.medium,
  });

  Color get _backgroundColor {
    return isMale 
        ? const Color(0xFF2196F3)  // 파란색 (투명도 없음)
        : const Color(0xFFE91E63); // 핑크색 (투명도 없음)
  }

  Color get _textColor {
    return Colors.white;  // 텍스트 흰색
  }

  String get _displayText {
    final genderText = isMale ? '남아' : '여아';
    if (ageString != null) return '$genderText · $ageString';
    if (age != null) return '$genderText · $age살';
    return genderText;
  }

  @override
  Widget build(BuildContext context) {
    return InfoBadge(
      text: _displayText,
      icon: isMale ? AppIcons.male : AppIcons.female,
      backgroundColor: _backgroundColor,
      textColor: _textColor,
      iconColor: _textColor,
      size: size,
    );
  }
}
