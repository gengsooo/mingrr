import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

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
enum InfoBadgeSize { small, medium, large }

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

  double get _fontSize {
    switch (size) {
      case InfoBadgeSize.small:
        return 10;
      case InfoBadgeSize.medium:
        return 12;
      case InfoBadgeSize.large:
        return 14;
    }
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
        return const EdgeInsets.symmetric(horizontal: 6, vertical: 2);
      case InfoBadgeSize.medium:
        return const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
      case InfoBadgeSize.large:
        return const EdgeInsets.symmetric(horizontal: 10, vertical: 6);
    }
  }

  double get _borderRadius {
    switch (size) {
      case InfoBadgeSize.small:
        return 6;
      case InfoBadgeSize.medium:
        return 8;
      case InfoBadgeSize.large:
        return 10;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? AppColors.background;
    final txtColor = textColor ?? AppColors.textSecondary;
    final icnColor = iconColor ?? txtColor;

    return Container(
      padding: _padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(_borderRadius),
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
            style: TextStyle(
              fontSize: _fontSize,
              fontWeight: FontWeight.w500,
              color: txtColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// 거리 배지
class DistanceBadge extends StatelessWidget {
  final double distanceKm;
  final InfoBadgeSize size;
  final bool showIcon;

  const DistanceBadge({
    super.key,
    required this.distanceKm,
    this.size = InfoBadgeSize.medium,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return InfoBadge(
      text: '${distanceKm.toStringAsFixed(1)}km',
      icon: showIcon ? Icons.location_on_outlined : null,
      size: size,
    );
  }
}

/// 궁합 점수 배지
class MatchScoreBadge extends StatelessWidget {
  final int score;
  final InfoBadgeSize size;
  final bool showIcon;
  final bool showLabel; // "궁합" 텍스트 표시 여부

  const MatchScoreBadge({
    super.key,
    required this.score,
    this.size = InfoBadgeSize.medium,
    this.showIcon = true,
    this.showLabel = true,
  });

  /// 점수에 따른 색상
  Color get _backgroundColor {
    if (score >= 90) return AppColors.success.withOpacity(0.15);
    if (score >= 70) return AppColors.dating.withOpacity(0.15);
    return AppColors.background;
  }

  Color get _textColor {
    if (score >= 90) return AppColors.success;
    if (score >= 70) return AppColors.dating;
    return AppColors.textSecondary;
  }

  String get _displayText {
    return showLabel ? '궁합 $score%' : '$score%';
  }

  @override
  Widget build(BuildContext context) {
    return InfoBadge(
      text: _displayText,
      icon: showIcon ? Icons.favorite : null,
      backgroundColor: _backgroundColor,
      textColor: _textColor,
      size: size,
    );
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
        ? Colors.blue.withOpacity(0.1) 
        : Colors.pink.withOpacity(0.1);
  }

  Color get _textColor {
    return isMale ? Colors.blue : Colors.pink;
  }

  String get _displayText {
    final genderText = isMale ? '남아' : '여아';
    if (ageString != null) return '$genderText · $ageString';
    if (age != null) return '$genderText · ${age}살';
    return genderText;
  }

  @override
  Widget build(BuildContext context) {
    return InfoBadge(
      text: _displayText,
      icon: isMale ? Icons.male : Icons.female,
      backgroundColor: _backgroundColor,
      textColor: _textColor,
      iconColor: _textColor,
      size: size,
    );
  }
}

/// 좋아요 수 배지
class LikeCountBadge extends StatelessWidget {
  final int count;
  final InfoBadgeSize size;
  final bool showIcon;

  const LikeCountBadge({
    super.key,
    required this.count,
    this.size = InfoBadgeSize.medium,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return InfoBadge(
      text: '$count',
      icon: showIcon ? Icons.favorite : null,
      backgroundColor: AppColors.dating.withOpacity(0.1),
      textColor: AppColors.dating,
      size: size,
    );
  }
}

/// 인증 상태 배지 (간단 버전)
class VerifiedBadge extends StatelessWidget {
  final String label;
  final bool isVerified;
  final InfoBadgeSize size;

  const VerifiedBadge({
    super.key,
    required this.label,
    required this.isVerified,
    this.size = InfoBadgeSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    return InfoBadge(
      text: label,
      icon: isVerified ? Icons.check_circle : Icons.cancel_outlined,
      backgroundColor: isVerified 
          ? AppColors.success.withOpacity(0.1) 
          : AppColors.background,
      textColor: isVerified ? AppColors.success : AppColors.textHint,
      size: size,
    );
  }
}
