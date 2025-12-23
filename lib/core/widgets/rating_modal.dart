import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

/// ============================================================
/// 꼬순내지수 평가 모달 (공통 위젯)
/// 
/// 사용처:
/// - 보호자 프로필 모달 > 평가하기 버튼
/// - 기타 꼬순내지수 평가가 필요한 곳
/// ============================================================

enum RatingType {
  excellent('최고에요', Icons.sentiment_very_satisfied, AppColors.success),
  good('좋아요', Icons.sentiment_satisfied, AppColors.primary),
  normal('보통', Icons.sentiment_neutral, AppColors.warning),
  bad('나쁨', Icons.sentiment_dissatisfied, AppColors.error);

  final String label;
  final IconData icon;
  final Color color;

  const RatingType(this.label, this.icon, this.color);
}

/// 꼬순내지수 평가 모달 표시 함수
void showRatingModal(
  BuildContext context, {
  required String targetName,
  required Function(RatingType) onRatingSelected,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => RatingModal(
      targetName: targetName,
      onRatingSelected: onRatingSelected,
    ),
  );
}

/// 꼬순내지수 평가 모달 위젯
class RatingModal extends StatelessWidget {
  final String targetName;
  final Function(RatingType) onRatingSelected;

  const RatingModal({
    super.key,
    required this.targetName,
    required this.onRatingSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 핸들
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // 헤더
              Padding(
                padding: const EdgeInsets.all(AppSizes.paddingL),
                child: Column(
                  children: [
                    Text(
                      '$targetName님은 어떠셨나요?',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '솔직한 평가는 더 나은 커뮤니티를 만듭니다',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              
              const Divider(height: 1),
              
              // 평가 옵션
              Padding(
                padding: const EdgeInsets.all(AppSizes.paddingL),
                child: Column(
                  children: RatingType.values.map((rating) {
                    return _buildRatingOption(context, rating);
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 평가 옵션 아이템
  Widget _buildRatingOption(BuildContext context, RatingType rating) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pop(context);
            onRatingSelected(rating);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: rating.color.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: rating.color.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: rating.color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    rating.icon,
                    color: rating.color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    rating.label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: rating.color,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: rating.color.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
