import 'package:flutter/material.dart';
import '../services/bottom_sheet_stack_manager.dart';
import '../theme/feature_colors.dart';
import '../constants/app_sizes.dart';
import 'common_widgets.dart';
import 'mingrr_bottom_sheet.dart';

/// ============================================================
/// 꼬순내지수 평가 모달 (공통 위젯)
/// 
/// 사용처:
/// - 보호자 프로필 모달 > 평가하기 버튼
/// - 기타 꼬순내지수 평가가 필요한 곳
/// ============================================================

enum RatingType {
  excellent('최고에요', Icons.sentiment_very_satisfied),
  good('좋아요', Icons.sentiment_satisfied),
  normal('보통', Icons.sentiment_neutral),
  bad('나쁨', Icons.sentiment_dissatisfied);

  final String label;
  final IconData icon;

  const RatingType(this.label, this.icon);

  Color getColor(BuildContext context) {
    switch (this) {
      case RatingType.excellent:
        return context.features.success;
      case RatingType.good:
        return Theme.of(context).colorScheme.primary;
      case RatingType.normal:
        return Colors.orange;
      case RatingType.bad:
        return Colors.red;
    }
  }
}

/// 꼬순내지수 평가 모달 표시 함수
void showRatingModal(
  BuildContext context, {
  required String targetName,
  required Function(RatingType) onRatingSelected,
}) {
  final stackManager = BottomSheetStackManager();
  final sheetId = BottomSheetStackManager.createSheetId(BottomSheetType.rating, targetName);
  
  // 순환 감지: 같은 평가 바텀시트가 이미 열려있으면 해당 바텀시트까지 닫기
  if (stackManager.hasCycle(sheetId)) {
    final closeCount = stackManager.popUntilAndGetCount(sheetId);
    for (int i = 0; i < closeCount; i++) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
  }
  
  // 스택에 등록
  stackManager.push(sheetId);
  
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isDismissible: true,
    enableDrag: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => RatingModal(
      targetName: targetName,
      onRatingSelected: (rating) {
        Navigator.pop(sheetContext);
        onRatingSelected(rating);
        // 평가 완료 알림 표시
        MingrrSnackBar.success(context, '$targetName님에게 "${rating.label}" 평가를 보냈어요! 🌟');
      },
    ),
  ).then((_) {
    // 바텀시트가 닫힐 때 스택에서 제거
    stackManager.pop(sheetId);
  });
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
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BottomSheetHandle(),
          // 헤더
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM, vertical: 8),
            child: Text(
              '$targetName님은 어떠셨나요?',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL),
            child: Text(
              '솔직한 평가는 더 나은 커뮤니티를 만듭니다',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          
          const SizedBox(height: AppSizes.gapM),
          
          // 평가 옵션 (스크롤 가능)
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              children: RatingType.values.map((rating) {
                return _buildRatingOption(context, rating);
              }).toList(),
            ),
          ),
          
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
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
              color: rating.getColor(context).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: rating.getColor(context).withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: rating.getColor(context).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    rating.icon,
                    color: rating.getColor(context),
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
                      color: rating.getColor(context),
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: rating.getColor(context).withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
