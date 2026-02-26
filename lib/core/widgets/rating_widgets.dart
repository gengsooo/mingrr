import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/app_icons.dart';
import '../constants/rating_constants.dart';
import '../services/bottom_sheet_stack_manager.dart';
import '../services/rating_service.dart';
import '../theme/app_text_styles.dart';
import '../theme/feature_colors.dart';
import '../constants/app_sizes.dart';
import '../../models/rating_model.dart';
import 'common_widgets.dart';
import 'dialogs/dialog_buttons.dart';
import 'mingrr_image.dart';
import 'sheets/mingrr_bottom_sheet.dart';
import 'dialogs/action_prompt_dialog.dart';
import '../utils/responsive_utils.dart';
import '../utils/error_handler.dart';
import '../utils/format_utils.dart';

/// ============================================================
/// 꼬순내지수 평가 시스템 통합 위젯
/// 
/// 포함 컴포넌트:
/// 1. RatingModal - 평가 모달 (별점 + 태그)
/// 2. ActivityCompleteDialog - 활동 완료 팝업
/// 3. RatingCompleteDialog - 평가 완료 피드백
/// 4. RatingReminderBanner - 평가 리마인더 배너
/// 
/// 사용처:
/// - 채팅 상세 화면 (거래/데이팅/교배 완료 후)
/// - 보호자 프로필 모달
/// - 채팅 옵션 모달
/// ============================================================

// ============================================================
// 1. 평가 모달 (RatingModal)
// ============================================================

/// 평가 모달 표시 함수
/// 
/// [relatedId]는 필수입니다. 활동 기반 평가만 허용합니다.
/// relatedId가 없으면 평가 모달이 표시되지 않습니다.
void showRatingModal(
  BuildContext context, {
  required String targetUserId,
  required String targetName,
  required String relatedId,
  String? targetImageUrl,
  RatingType ratingType = RatingType.dating,
  VoidCallback? onComplete,
}) {
  // relatedId 검증 - 활동 기반 평가만 허용
  if (relatedId.isEmpty) {
    MingrrSnackBar.warning(context, '평가할 수 있는 활동이 없어요');
    return;
  }

  final stackManager = BottomSheetStackManager();
  final sheetId = BottomSheetStackManager.createSheetId(BottomSheetType.rating, targetName);
  
  if (stackManager.hasCycle(sheetId)) {
    final closeCount = stackManager.popUntilAndGetCount(sheetId);
    for (int i = 0; i < closeCount; i++) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
  }
  
  stackManager.push(sheetId);
  
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isDismissible: true,
    enableDrag: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => RatingModal(
      targetUserId: targetUserId,
      targetName: targetName,
      targetImageUrl: targetImageUrl,
      ratingType: ratingType,
      relatedId: relatedId,
      onComplete: onComplete,
    ),
  ).then((_) {
    stackManager.pop(sheetId);
  });
}

/// 평가 모달 위젯
class RatingModal extends StatefulWidget {
  final String targetUserId;
  final String targetName;
  final String? targetImageUrl;
  final RatingType ratingType;
  final String relatedId;
  final VoidCallback? onComplete;

  const RatingModal({
    super.key,
    required this.targetUserId,
    required this.targetName,
    this.targetImageUrl,
    this.ratingType = RatingType.dating,
    required this.relatedId,
    this.onComplete,
  });

  @override
  State<RatingModal> createState() => _RatingModalState();
}

class _RatingModalState extends State<RatingModal> {
  int _selectedRating = 0;
  final List<String> _selectedTags = [];
  ActivityResult _activityResult = ActivityResult.completed;
  bool _isSubmitting = false;
  final _ratingService = RatingService();

  List<String> get _positiveTags => widget.ratingType.positiveTags;

  List<String> get _negativeTags => widget.ratingType.negativeTags;

  String get _typeLabel => widget.ratingType.activityLabel;

  Color get _themeColor {
    switch (widget.ratingType) {
      case RatingType.dating:
        return context.features.dating;
      case RatingType.marketplace:
        return context.features.market;
      case RatingType.breeding:
        return context.features.dating;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: ResponsiveUtils.maxSheetHeight(context),
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSizes.radiusL)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const BottomSheetHandle(),
              
              // 헤더
              _buildHeader(),
              
              // 활동 결과 선택
              _buildActivityResultSection(),
              
              // 별점 선택 (완료 시에만)
              if (_activityResult == ActivityResult.completed) ...[
                _buildStarRating(),
                
                // 태그 선택 (별점 선택 후)
                if (_selectedRating > 0)
                  _buildTagSelection(),
              ],
              
              // 제출 버튼
              _buildSubmitButton(),
              
              SizedBox(height: ResponsiveUtils.bottomPaddingWith(context, 8)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL, vertical: 16),
      child: Column(
        children: [
          // 프로필 이미지
          if (widget.targetImageUrl != null) ...[
            MingrrImage.avatar(
              imageUrl: widget.targetImageUrl,
              size: 64,
              icon: AppIcons.profile,
            ),
            const SizedBox(height: AppSizes.gapM),
          ],
          Text(
            '${widget.targetName}님에 대한 평가를 보내주세요!',
            style: AppTextStyles.headlineMedium(context),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.gapXS),
          Text(
            '솔직한 평가는 더 좋은 커뮤니티를 만들어요',
            style: AppTextStyles.bodyMedium(context).withColor(Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityResultSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$_typeLabel 결과',
            style: AppTextStyles.labelLarge(context).copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSizes.gapS),
          Row(
            children: [
              _buildResultChip(ActivityResult.completed, '완료'),
              const SizedBox(width: AppSizes.gapS),
              _buildResultChip(ActivityResult.noShow, '노쇼'),
              const SizedBox(width: AppSizes.gapS),
              _buildResultChip(ActivityResult.cancelled, '취소'),
            ],
          ),
          const SizedBox(height: AppSizes.gapL),
        ],
      ),
    );
  }

  Widget _buildResultChip(ActivityResult result, String label) {
    final isSelected = _activityResult == result;
    final chipColor = result == ActivityResult.noShow 
        ? Colors.red 
        : result == ActivityResult.cancelled 
            ? Colors.grey 
            : _themeColor;
    
    return GestureDetector(
      onTap: () => setState(() {
        _activityResult = result;
        if (result != ActivityResult.completed) {
          _selectedRating = 1;
          _selectedTags.clear();
        } else {
          _selectedRating = 0;
        }
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL, vertical: AppSizes.paddingS),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
          border: Border.all(
            color: isSelected ? chipColor : Theme.of(context).colorScheme.outline,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.titleMedium(context).withColor(
            isSelected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildStarRating() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingL),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starIndex = index + 1;
              final isSelected = starIndex <= _selectedRating;
              
              return GestureDetector(
                onTap: () => setState(() {
                  // 별점 변경 시 태그 초기화 (긍정/부정 태그가 다르므로)
                  final wasPositive = _selectedRating >= 3;
                  final willBePositive = starIndex >= 3;
                  if (wasPositive != willBePositive) {
                    _selectedTags.clear();
                  }
                  _selectedRating = starIndex;
                }),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingXS),
                  child: AnimatedScale(
                    scale: isSelected ? 1.1 : 1.0,
                    duration: const Duration(milliseconds: 150),
                    child: Icon(
                      isSelected ? AppIcons.star : AppIcons.starOutlined,
                      size: 44,
                      color: isSelected ? Colors.amber : Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ),
              );
            }),
          ),
          if (_selectedRating > 0) ...[
            const SizedBox(height: AppSizes.gapS),
            Text(
              _getScoreLabel(_selectedRating),
              style: AppTextStyles.titleMedium(context).withColor(_themeColor),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTagSelection() {
    final isPositive = _selectedRating >= 3;
    final tags = isPositive ? _positiveTags : _negativeTags;
    final tagColor = isPositive ? context.features.success : Colors.red;
    
    // SizedBox.expand로 부모 너비에 맞춰 고정
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isPositive ? '어떤 점이 좋았나요?' : '어떤 점이 아쉬웠나요?',
              style: AppTextStyles.labelLarge(context),
            ),
            const SizedBox(height: AppSizes.gapM),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tags.map((tag) {
                final isSelected = _selectedTags.contains(tag);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedTags.remove(tag);
                      } else {
                        _selectedTags.add(tag);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppSizes.paddingS),
                    decoration: BoxDecoration(
                      color: isSelected ? tagColor.withValues(alpha: AppOpacity.o10) : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppSizes.radiusL),
                      border: Border.all(
                        color: isSelected ? tagColor : Theme.of(context).colorScheme.outline,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      tag,
                      style: AppTextStyles.titleSmall(context)
                          .withWeight(isSelected ? FontWeight.w500 : FontWeight.normal)
                          .withColor(isSelected ? tagColor : Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSizes.gapL),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    final canSubmit = _activityResult != ActivityResult.completed || _selectedRating > 0;
    
    return Padding(
      padding: const EdgeInsets.all(AppSizes.paddingL),
      child: MingrrButton(
        text: '평가 완료',
        onPressed: canSubmit ? _submitRating : null,
        isLoading: _isSubmitting,
        backgroundColor: _themeColor,
        textColor: Colors.white,
        height: 52,
      ),
    );
  }

  String _getScoreLabel(int score) {
    switch (score) {
      case 5:
        return '최고예요! 👍';
      case 4:
        return '좋았어요 😊';
      case 3:
        return '보통이에요 😐';
      case 2:
        return '아쉬웠어요 😕';
      case 1:
        return '별로였어요 😞';
      default:
        return '';
    }
  }

  Future<void> _submitRating() async {
    setState(() => _isSubmitting = true);
    
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('로그인이 필요합니다');
      }
      
      // RatingService.createRating에서 중복 체크 및 쿨다운 체크를 수행
      // RatingException이 발생하면 catch에서 처리
      await _ratingService.createRating(
        raterId: currentUser.uid,
        targetId: widget.targetUserId,
        type: widget.ratingType,
        relatedId: widget.relatedId,
        result: _activityResult,
        score: _activityResult == ActivityResult.completed ? _selectedRating : 1,
        tags: _selectedTags,
      );
      
      if (mounted) {
        Navigator.pop(context);
        showRatingCompleteDialog(context);
        widget.onComplete?.call();
      }
    } on RatingException catch (e) {
      // 평가 불가 사유 표시 (중복 평가, 쿨다운 등)
      if (mounted) {
        Navigator.pop(context);
        MingrrSnackBar.warning(context, e.message);
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e, tag: 'Rating', operation: '평가 제출');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}

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
      color: Colors.green,
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

// ============================================================
// 7. 평가 카드 (RatingCard)
// ============================================================

/// 평가 카드 위젯
/// 
/// 평가 대기 목록, 평가 이력 조회 화면에서 사용
class RatingCard extends StatelessWidget {
  final String targetName;
  final String? targetImageUrl;
  final RatingType ratingType;
  final DateTime createdAt;
  final int? score;
  final List<String>? tags;
  final bool isPending;
  final VoidCallback? onTap;
  final VoidCallback? onRate;

  const RatingCard({
    super.key,
    required this.targetName,
    this.targetImageUrl,
    required this.ratingType,
    required this.createdAt,
    this.score,
    this.tags,
    this.isPending = false,
    this.onTap,
    this.onRate,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = _getAccentColor(context);
    
    return GestureDetector(
      onTap: onTap ?? onRate,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSizes.gapM),
        padding: const EdgeInsets.all(AppSizes.paddingM),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
          border: isPending 
              ? Border.all(color: Colors.amber.withValues(alpha: 0.5), width: 1)
              : null,
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // 프로필 이미지
            MingrrImage.avatar(
              imageUrl: targetImageUrl,
              size: 56,
              icon: AppIcons.profile,
            ),
            const SizedBox(width: AppSizes.gapM),
            
            // 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 이름 + 타입 배지
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          targetName,
                          style: AppTextStyles.titleMedium(context).withWeight(FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.paddingS,
                          vertical: AppSizes.paddingXXS,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppSizes.radiusXS),
                        ),
                        child: Text(
                          ratingType.activityLabel,
                          style: AppTextStyles.captionSmall(context).copyWith(
                            color: accentColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.gapXXS),
                  
                  // 날짜
                  Text(
                    formatRelativeDate(createdAt),
                    style: AppTextStyles.caption(context).copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                  
                  // 별점 (평가 완료 시)
                  if (score != null && score! > 0) ...[
                    const SizedBox(height: AppSizes.gapS),
                    Row(
                      children: List.generate(5, (index) {
                        final isSelected = index < score!;
                        return Icon(
                          isSelected ? AppIcons.star : AppIcons.starOutlined,
                          size: 16,
                          color: isSelected ? Colors.amber : colorScheme.outline,
                        );
                      }),
                    ),
                  ],
                  
                  // 태그 (평가 완료 시)
                  if (tags != null && tags!.isNotEmpty) ...[
                    const SizedBox(height: AppSizes.gapS),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: tags!.take(RatingConstants.maxDisplayTags).map((tag) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.paddingS,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(AppSizes.radiusXXS),
                        ),
                        child: Text(
                          tag,
                          style: AppTextStyles.captionSmall(context).copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )).toList(),
                    ),
                  ],
                ],
              ),
            ),
            
            // 평가하기 버튼 (대기 중일 때)
            if (isPending && onRate != null) ...[
              const SizedBox(width: AppSizes.gapS),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingM,
                  vertical: AppSizes.paddingS,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusS),
                ),
                child: Text(
                  '평가하기',
                  style: AppTextStyles.labelMedium(context).copyWith(
                    color: Colors.amber.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Color _getAccentColor(BuildContext context) {
    switch (ratingType) {
      case RatingType.dating:
        return context.features.dating;
      case RatingType.marketplace:
        return context.features.market;
      case RatingType.breeding:
        return context.features.dating;
    }
  }
  
}

// ============================================================
// 8. 평가 카드 스켈레톤 (RatingCardSkeleton)
// ============================================================

/// 평가 카드 로딩 스켈레톤
/// 
/// 사용자 정보 비동기 로딩 중 표시되는 공통 스켈레톤 위젯
class RatingCardSkeleton extends StatelessWidget {
  const RatingCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.gapM),
      padding: const EdgeInsets.all(AppSizes.paddingM),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSizes.gapM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 100,
                  height: 16,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppSizes.radiusXXS),
                  ),
                ),
                const SizedBox(height: AppSizes.gapXS),
                Container(
                  width: 60,
                  height: 12,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppSizes.radiusXXS),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 9. 비동기 평가 카드 (AsyncRatingCard)
// ============================================================

/// 비동기 로딩을 지원하는 평가 카드
/// 
/// 사용자 정보를 비동기로 로드해야 하는 경우 사용
class AsyncRatingCard extends StatefulWidget {
  final String targetUserId;
  final RatingType ratingType;
  final DateTime createdAt;
  final int? score;
  final List<String>? tags;
  final bool isPending;
  final Future<Map<String, dynamic>?> Function(String userId) loadUserInfo;
  final VoidCallback? onTap;
  final VoidCallback? onRate;

  const AsyncRatingCard({
    super.key,
    required this.targetUserId,
    required this.ratingType,
    required this.createdAt,
    this.score,
    this.tags,
    this.isPending = false,
    required this.loadUserInfo,
    this.onTap,
    this.onRate,
  });

  @override
  State<AsyncRatingCard> createState() => _AsyncRatingCardState();
}

class _AsyncRatingCardState extends State<AsyncRatingCard> {
  Map<String, dynamic>? _userInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final info = await widget.loadUserInfo(widget.targetUserId);
      if (mounted) {
        setState(() {
          _userInfo = info;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const RatingCardSkeleton();
    }
    
    return RatingCard(
      targetName: _userInfo?['name'] as String? ?? '알 수 없음',
      targetImageUrl: _userInfo?['imageUrl'] as String?,
      ratingType: widget.ratingType,
      createdAt: widget.createdAt,
      score: widget.score,
      tags: widget.tags,
      isPending: widget.isPending,
      onTap: widget.onTap,
      onRate: widget.onRate,
    );
  }
}
