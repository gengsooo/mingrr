import 'package:flutter/material.dart';
import '../../constants/app_icons.dart';
import '../../constants/app_sizes.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/feature_colors.dart';
import '../../../models/rating_model.dart';
import '../common_widgets.dart';
import '../dialogs/dialog_buttons.dart';
import '../dialogs/action_prompt_dialog.dart';
import 'rating_modal.dart';

// ============================================================
// 2. 활동 완료 팝업 (ActivityCompleteDialog)
// ============================================================

/// 활동 완료 후 평가 유도 팝업 표시
/// 
/// [relatedId]는 필수입니다. 활동 기반 평가만 허용합니다.
void showActivityCompleteDialog(
  BuildContext context, {
  required String activityType,
  required String partnerName,
  required String partnerUserId,
  required String relatedId,
  String? partnerImageUrl,
  VoidCallback? onRateLater,
}) {
  // relatedId 검증
  if (relatedId.isEmpty) {
    return;
  }

  final ratingType = RatingType.fromActivityType(activityType);
  final typeLabel = ratingType.activityLabel;
  
  showActionPromptDialog(
    context,
    icon: MingrrActionPromptDialog.buildCircleIcon(
      icon: AppIcons.successOutlined,
      color: Theme.of(context).colorScheme.primary,
    ),
    title: '🎉 $typeLabel이 완료되었어요!',
    message: '$partnerName님과의 $typeLabel은 어떠셨나요?',
    primaryButtonText: '지금 평가하기',
    onPrimaryPressed: () {
      showRatingModal(
        context,
        targetUserId: partnerUserId,
        targetName: partnerName,
        relatedId: relatedId,
        targetImageUrl: partnerImageUrl,
        ratingType: ratingType,
      );
    },
    secondaryButtonText: '나중에 하기',
    onSecondaryPressed: onRateLater,
  );
}


// ============================================================
// 3. 평가 완료 피드백 다이얼로그 (RatingCompleteDialog)
// ============================================================

/// 평가 완료 후 피드백 다이얼로그 표시
void showRatingCompleteDialog(BuildContext context) {
  showActionPromptDialog(
    context,
    icon: MingrrActionPromptDialog.buildGradientIcon(
      icon: AppIcons.pet,
      colors: [Colors.amber.shade300, Colors.orange.shade400],
    ),
    title: '평가 완료!',
    message: '당신의 평가가 더 좋은 커뮤니티를\n만드는 데 도움이 돼요 🐾',
    primaryButtonText: '확인',
    onPrimaryPressed: () {},
  );
}

// ============================================================
// 4. 평가 리마인더 배너 (RatingReminderBanner)
// ============================================================

/// 평가하지 않은 활동이 있을 때 표시하는 배너
class RatingReminderBanner extends StatelessWidget {
  final int pendingCount;
  final VoidCallback onTap;

  const RatingReminderBanner({
    super.key,
    required this.pendingCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (pendingCount <= 0) return const SizedBox.shrink();
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL, vertical: AppSizes.paddingS),
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL, vertical: AppSizes.paddingM),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.amber.shade100,
              Colors.orange.shade100,
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(AppSizes.radiusS),
          border: Border.all(
            color: Colors.amber.shade300,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.amber.shade400,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                AppIcons.edit,
                size: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: AppSizes.gapM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📝 아직 평가하지 않은 활동이 있어요',
                    style: AppTextStyles.titleSmall(context).withWeight(FontWeight.w600).withColor(Colors.black87),
                  ),
                  Text(
                    '$pendingCount건의 평가가 기다리고 있어요',
                    style: AppTextStyles.caption(context).withColor(Colors.grey.shade700),
                  ),
                ],
              ),
            ),
            Icon(
              AppIcons.chevronRight,
              size: 14,
              color: Colors.grey.shade600,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 5. 상대방 평가 알림 배너 (RatingReceivedBanner)
// ============================================================

/// 상대방이 평가를 남겼을 때 표시하는 배너
class RatingReceivedBanner extends StatelessWidget {
  final String raterName;
  final VoidCallback onRateBack;
  final VoidCallback onDismiss;

  const RatingReceivedBanner({
    super.key,
    required this.raterName,
    required this.onRateBack,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL, vertical: AppSizes.paddingS),
      padding: const EdgeInsets.all(AppSizes.paddingL),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppSizes.radiusS),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(AppIcons.pet, size: 20),
              const SizedBox(width: AppSizes.gapS),
              Expanded(
                child: Text(
                  '🐾 $raterName님이 평가를 남겼어요!',
                  style: AppTextStyles.titleMedium(context).withWeight(FontWeight.w600),
                ),
              ),
              GestureDetector(
                onTap: onDismiss,
                child: Icon(
                  AppIcons.close,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.gapS),
          Text(
            '나도 평가해볼까요?',
            style: AppTextStyles.bodySmall(context).withColor(Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSizes.gapM),
          MingrrButton(
            text: '평가하러 가기',
            onPressed: onRateBack,
            backgroundColor: Theme.of(context).colorScheme.primary,
            textColor: Colors.white,
            height: 40,
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 6. 거래 완료 확인 다이얼로그 (TransactionCompleteDialog)
// ============================================================

/// 거래/만남 완료 확인 다이얼로그
class TransactionCompleteDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onComplete;
  final VoidCallback onNoShow;
  final VoidCallback onCancel;

  const TransactionCompleteDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onComplete,
    required this.onNoShow,
    required this.onCancel,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onComplete,
    required VoidCallback onNoShow,
    required VoidCallback onCancel,
  }) {
    return showDialog(
      context: context,
      builder: (context) => TransactionCompleteDialog(
        title: title,
        message: message,
        onComplete: onComplete,
        onNoShow: onNoShow,
        onCancel: onCancel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingXXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              AppIcons.successOutlined,
              size: 48,
              color: context.features.success,
            ),
            const SizedBox(height: AppSizes.gapL),
            Text(
              title,
              style: AppTextStyles.headlineMedium(context).withWeight(FontWeight.bold),
            ),
            const SizedBox(height: AppSizes.gapS),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge(context).withColor(Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSizes.gapXL),
            
            // 완료 버튼
            MingrrButton(
              text: '완료했어요',
              onPressed: () {
                Navigator.pop(context);
                onComplete();
              },
              backgroundColor: context.features.success,
              textColor: Colors.white,
              height: 48,
            ),
            const SizedBox(height: AppSizes.gapS),
            
            // 노쇼 버튼
            MingrrDialogButton.destructiveOutlined(
              text: '상대방이 안 나왔어요',
              onPressed: () {
                Navigator.pop(context);
                onNoShow();
              },
            ),
            const SizedBox(height: AppSizes.gapS),
            
            // 취소 버튼
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onCancel();
              },
              child: Text(
                '취소됐어요',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
