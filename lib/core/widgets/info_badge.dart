import 'package:flutter/material.dart';
import '../theme/feature_colors.dart';

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
    final bgColor = backgroundColor ?? Theme.of(context).colorScheme.surface;
    final txtColor = textColor ?? Theme.of(context).colorScheme.onSurfaceVariant;
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

  /// 점수에 따른 배경색
  Color _getBackgroundColor(BuildContext context) {
    final features = context.features;
    if (score >= 90) return features.success.withOpacity(0.15);
    if (score >= 70) return features.dating.withOpacity(0.15);
    return Theme.of(context).colorScheme.surface;
  }

  /// 점수에 따른 텍스트색
  Color _getTextColor(BuildContext context) {
    final features = context.features;
    if (score >= 90) return features.success;
    if (score >= 70) return features.dating;
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }

  String get _displayText {
    return showLabel ? '궁합 $score%' : '$score%';
  }

  @override
  Widget build(BuildContext context) {
    return InfoBadge(
      text: _displayText,
      icon: showIcon ? Icons.favorite : null,
      backgroundColor: _getBackgroundColor(context),
      textColor: _getTextColor(context),
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
        ? const Color(0xFF2196F3)  // 파란색 (투명도 없음)
        : const Color(0xFFE91E63); // 핑크색 (투명도 없음)
  }

  Color get _textColor {
    return Colors.white;  // 텍스트 흰색
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
      backgroundColor: context.features.dating.withOpacity(0.1),
      textColor: context.features.dating,
      size: size,
    );
  }
}

/// 반려동물 성별 배지 (데이팅/교배찾기용)
class PetGenderBadge extends StatelessWidget {
  final bool isMale;
  final bool showLabel;
  final InfoBadgeSize size;

  const PetGenderBadge({
    super.key,
    required this.isMale,
    this.showLabel = true,
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

  double get _symbolSize {
    switch (size) {
      case InfoBadgeSize.small:
        return 11;
      case InfoBadgeSize.medium:
        return 13;
      case InfoBadgeSize.large:
        return 15;
    }
  }

  EdgeInsets get _padding {
    switch (size) {
      case InfoBadgeSize.small:
        return const EdgeInsets.symmetric(horizontal: 6, vertical: 2);
      case InfoBadgeSize.medium:
        return const EdgeInsets.symmetric(horizontal: 8, vertical: 3);
      case InfoBadgeSize.large:
        return const EdgeInsets.symmetric(horizontal: 10, vertical: 4);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 투명도 없는 배경색, 흰색 텍스트
    final bgColor = isMale 
        ? const Color(0xFF2196F3)  // 파란색 (투명도 없음)
        : const Color(0xFFE91E63); // 핑크색 (투명도 없음)
    const textColor = Colors.white;
    
    return Container(
      padding: _padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isMale ? Icons.male : Icons.female,
            size: _symbolSize,
            color: textColor,
          ),
          if (showLabel) ...[
            const SizedBox(width: 3),
            Text(
              isMale ? '남아' : '여아',
              style: TextStyle(
                fontSize: _fontSize,
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
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
          ? context.features.success.withOpacity(0.1) 
          : Theme.of(context).colorScheme.surface,
      textColor: isVerified ? context.features.success : Theme.of(context).colorScheme.outlineVariant,
      size: size,
    );
  }
}
