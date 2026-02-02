import 'package:flutter/material.dart';
import '../constants/app_icons.dart';
import '../constants/app_sizes.dart';
import '../theme/app_text_styles.dart';
import '../theme/feature_colors.dart';
import 'dialogs/dialogs.dart';

/// ============================================================
/// 궁합 점수 관련 위젯 모음
/// 
/// - showCompatibilityGuideModal: 궁합 안내 팝업
/// - CompatibilityScoreBadge: 궁합 점수 배지
/// ============================================================

/// 궁합 점수 등급 정보
class CompatibilityGrade {
  final int minScore;
  final String grade;
  final String description;
  final String emoji;
  final Color color;

  const CompatibilityGrade({
    required this.minScore,
    required this.grade,
    required this.description,
    required this.emoji,
    required this.color,
  });
}

/// 궁합 등급 목록 (기획서 기준)
const List<CompatibilityGrade> compatibilityGrades = [
  CompatibilityGrade(
    minScore: 85,
    grade: '최고',
    description: '환상의 궁합이에요!',
    emoji: '🎉',
    color: Color(0xFF4CAF50),
  ),
  CompatibilityGrade(
    minScore: 70,
    grade: '좋음',
    description: '잘 맞는 친구예요!',
    emoji: '😊',
    color: Color(0xFF8BC34A),
  ),
  CompatibilityGrade(
    minScore: 55,
    grade: '보통',
    description: '괜찮은 친구가 될 수 있어요',
    emoji: '🙂',
    color: Color(0xFFFFC107),
  ),
  CompatibilityGrade(
    minScore: 40,
    grade: '낮음',
    description: '조금 맞춰가야 할 수 있어요',
    emoji: '😐',
    color: Color(0xFFFF9800),
  ),
  CompatibilityGrade(
    minScore: 0,
    grade: '매우 낮음',
    description: '서로 다른 점이 많아요',
    emoji: '🤔',
    color: Color(0xFF9E9E9E),
  ),
];

/// 점수에 따른 등급 정보 반환
CompatibilityGrade getCompatibilityGrade(int score) {
  for (final grade in compatibilityGrades) {
    if (score >= grade.minScore) {
      return grade;
    }
  }
  return compatibilityGrades.last;
}

/// 궁합 점수 배분 정보
class CompatibilityFactor {
  final String name;
  final int percentage;
  final String description;
  final IconData icon;

  const CompatibilityFactor({
    required this.name,
    required this.percentage,
    required this.description,
    required this.icon,
  });
}

/// 궁합 점수 배분 목록 (기획서 기준 - 2024.01 업데이트)
const List<CompatibilityFactor> compatibilityFactors = [
  CompatibilityFactor(
    name: '체형 궁합',
    percentage: 20,
    description: '크기와 체중이 비슷할수록 높아요',
    icon: AppIcons.distance,
  ),
  CompatibilityFactor(
    name: '성격 궁합',
    percentage: 20,
    description: '성격이 잘 맞을수록 높아요',
    icon: AppIcons.psychology,
  ),
  CompatibilityFactor(
    name: '거리',
    percentage: 15,
    description: '가까울수록 만나기 쉬워요',
    icon: AppIcons.location,
  ),
  CompatibilityFactor(
    name: '보호자 신뢰도',
    percentage: 15,
    description: '인증과 꼬순내지수가 높을수록 좋아요',
    icon: AppIcons.verified,
  ),
  CompatibilityFactor(
    name: '인기도',
    percentage: 10,
    description: '활발하게 활동하는 친구예요',
    icon: AppIcons.like,
  ),
  CompatibilityFactor(
    name: '앱 활성도',
    percentage: 10,
    description: '최근 활동이 많을수록 높아요',
    icon: AppIcons.accessTime,
  ),
  CompatibilityFactor(
    name: '나이 궁합',
    percentage: 5,
    description: '비슷한 나이대면 더 잘 놀아요',
    icon: AppIcons.cake,
  ),
  CompatibilityFactor(
    name: '품종 궁합',
    percentage: 5,
    description: '같은 품종이면 더 잘 맞아요',
    icon: AppIcons.pet,
  ),
];

/// 궁합 안내 모달 표시
void showCompatibilityGuideModal(BuildContext context) {
  final features = Theme.of(context).extension<FeatureColors>()!;
  
  showInfoDialog(
    context,
    title: '궁합이란?',
    icon: AppIcons.autoAwesome,
    subtitle: '우리 아이와 얼마나 잘 맞는지 알려드려요',
    accentColor: features.dating,
    customContent: const _CompatibilityGuideContent(),
    footerText: '궁합 점수는 참고용이에요. 실제 만남이 더 중요해요!',
  );
}

/// 궁합 안내 커스텀 콘텐츠
class _CompatibilityGuideContent extends StatelessWidget {
  const _CompatibilityGuideContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 등급 안내
        _buildSectionTitle(context, '등급 안내'),
        const SizedBox(height: AppSizes.gapS),
        ...compatibilityGrades.map((grade) => _buildGradeRow(context, grade)),
        
        const SizedBox(height: AppSizes.gapL),
        
        // 점수 구성 요소
        _buildSectionTitle(context, '점수 구성 요소'),
        const SizedBox(height: AppSizes.gapS),
        ...compatibilityFactors.map((factor) => _buildFactorRow(context, factor)),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: AppTextStyles.labelLarge(context).withWeight(FontWeight.w600),
    );
  }

  Widget _buildGradeRow(BuildContext context, CompatibilityGrade grade) {
    final isTop = grade.minScore >= 85;
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingXS),
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingS, vertical: AppSizes.paddingS),
      decoration: BoxDecoration(
        color: isTop ? Colors.white : grade.color.withValues(alpha: AppOpacity.o10),
        borderRadius: BorderRadius.circular(AppSizes.radiusS),
        border: Border.all(color: grade.color.withValues(alpha: isTop ? AppOpacity.o50 : AppOpacity.o20)),
        boxShadow: isTop ? AppShadows.shadowS(Theme.of(context).brightness == Brightness.dark) : null,
      ),
      child: Row(
        children: [
          Text(grade.emoji, style: AppTextStyles.labelLarge(context)),
          const SizedBox(width: AppSizes.gapS),
          SizedBox(
            width: 55,
            child: Text(
              '${grade.minScore}%~',
              style: AppTextStyles.labelSmall(context).copyWith(
                fontWeight: FontWeight.w600,
                color: grade.color,
              ),
            ),
          ),
          Text(
            grade.grade,
            style: AppTextStyles.labelSmall(context).copyWith(
              fontWeight: FontWeight.w600,
              color: grade.color,
            ),
          ),
          const SizedBox(width: AppSizes.gapS),
          Expanded(
            child: Text(
              grade.description,
              style: AppTextStyles.captionSmall(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFactorRow(BuildContext context, CompatibilityFactor factor) {
    final features = Theme.of(context).extension<FeatureColors>()!;
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingXS),
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingS, vertical: AppSizes.paddingS),
      decoration: BoxDecoration(
        color: features.dating.withValues(alpha: AppOpacity.o05),
        borderRadius: BorderRadius.circular(AppSizes.radiusXS),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(factor.icon, size: 16, color: features.dating),
          const SizedBox(width: AppSizes.gapS),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: AppSizes.paddingXXS),
            decoration: BoxDecoration(
              color: features.dating.withValues(alpha: AppOpacity.o15),
              borderRadius: BorderRadius.circular(AppSizes.radiusXXS),
            ),
            child: Text(
              '${factor.percentage}%',
              style: AppTextStyles.labelMedium(context).withWeight(FontWeight.w700).withColor(features.dating),
            ),
          ),
          const SizedBox(width: AppSizes.gapMS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  factor.name,
                  style: AppTextStyles.labelLarge(context).withWeight(FontWeight.w600),
                ),
                const SizedBox(height: AppSizes.gapXXS),
                Text(
                  factor.description,
                  style: AppTextStyles.captionSmall(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 궁합 점수 배지 (소형)
class CompatibilityScoreBadge extends StatelessWidget {
  final int score;
  final bool showLabel;
  final double? size;

  const CompatibilityScoreBadge({
    super.key,
    required this.score,
    this.showLabel = true,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final features = Theme.of(context).extension<FeatureColors>()!;
    final badgeSize = size ?? 14.0;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: showLabel ? 8 : 6,
        vertical: AppSizes.paddingXS,
      ),
      decoration: BoxDecoration(
        color: score >= 85 ? features.success : features.dating,
        borderRadius: BorderRadius.circular(AppSizes.radiusS),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppIcons.autoAwesome, size: badgeSize, color: Colors.white),
          if (showLabel) ...[
            const SizedBox(width: AppSizes.gapXS),
            Text(
              '궁합 $score%',
              style: AppTextStyles.bodyMedium(context).withWeight(FontWeight.w600).withColor(Colors.white),
            ),
          ],
        ],
      ),
    );
  }
}

/// 궁합 점수 상세 카드
class CompatibilityScoreCard extends StatelessWidget {
  final int score;
  final VoidCallback? onInfoTap;

  const CompatibilityScoreCard({
    super.key,
    required this.score,
    this.onInfoTap,
  });

  @override
  Widget build(BuildContext context) {
    final grade = getCompatibilityGrade(score);
    final features = Theme.of(context).extension<FeatureColors>()!;
    
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingM),
      decoration: BoxDecoration(
        color: grade.color.withValues(alpha: AppOpacity.o10),
        borderRadius: BorderRadius.circular(AppSizes.radiusS),
        border: Border.all(color: grade.color.withValues(alpha: AppOpacity.o30)),
      ),
      child: Row(
        children: [
          // 점수 원형
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: grade.color,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$score%',
                style: AppTextStyles.titleMedium(context).withWeight(FontWeight.w700).withColor(Colors.white),
              ),
            ),
          ),
          const SizedBox(width: AppSizes.gapM),
          // 등급 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      grade.emoji,
                      style: AppTextStyles.titleLarge(context),
                    ),
                    const SizedBox(width: AppSizes.gapXS),
                    Text(
                      grade.grade,
                      style: AppTextStyles.titleMedium(context).withWeight(FontWeight.w600).withColor(grade.color),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.gapXXS),
                Text(
                  grade.description,
                  style: AppTextStyles.bodySmall(context).withColor(Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          // 안내 버튼
          if (onInfoTap != null)
            GestureDetector(
              onTap: onInfoTap,
              child: Container(
                padding: const EdgeInsets.all(AppSizes.paddingXS),
                decoration: BoxDecoration(
                  color: features.dating.withValues(alpha: AppOpacity.o10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  AppIcons.help,
                  size: 18,
                  color: features.dating,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
