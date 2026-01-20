import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/bottom_sheet_stack_manager.dart';
import '../services/rating_service.dart';
import '../theme/app_text_styles.dart';
import '../theme/feature_colors.dart';
import '../constants/app_sizes.dart';
import '../../models/rating_model.dart';
import 'common_widgets.dart';
import 'mingrr_bottom_sheet.dart';
import 'dialogs/action_prompt_dialog.dart';

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
void showRatingModal(
  BuildContext context, {
  required String targetUserId,
  required String targetName,
  String? targetImageUrl,
  RatingType ratingType = RatingType.dating,
  String? relatedId,
  VoidCallback? onComplete,
}) {
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
  final String? relatedId;
  final VoidCallback? onComplete;

  const RatingModal({
    super.key,
    required this.targetUserId,
    required this.targetName,
    this.targetImageUrl,
    this.ratingType = RatingType.dating,
    this.relatedId,
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

  List<String> get _positiveTags {
    switch (widget.ratingType) {
      case RatingType.marketplace:
        return PositiveRatingTags.marketplace;
      case RatingType.breeding:
        return PositiveRatingTags.breeding;
      default:
        return PositiveRatingTags.dating;
    }
  }

  List<String> get _negativeTags {
    switch (widget.ratingType) {
      case RatingType.marketplace:
        return NegativeRatingTags.marketplace;
      case RatingType.breeding:
        return NegativeRatingTags.breeding;
      default:
        return NegativeRatingTags.dating;
    }
  }

  String get _typeLabel {
    switch (widget.ratingType) {
      case RatingType.dating:
        return '만남';
      case RatingType.marketplace:
        return '거래';
      case RatingType.breeding:
        return '교배';
      case RatingType.community:
        return '소모임';
    }
  }

  Color get _themeColor {
    switch (widget.ratingType) {
      case RatingType.dating:
        return context.features.dating;
      case RatingType.marketplace:
        return context.features.market;
      case RatingType.breeding:
        return context.features.dating;
      case RatingType.community:
        return context.features.social;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL),
                    child: _buildTagSelection(),
                  ),
              ],
              
              // 제출 버튼
              _buildSubmitButton(),
              
              SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
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
            CircleAvatar(
              radius: 32,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
              backgroundImage: NetworkImage(widget.targetImageUrl!),
            ),
            const SizedBox(height: AppSizes.gapM),
          ],
          Text(
            '${widget.targetName}님에 대한 평가를 보내주세요! 🐾',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.gapXS),
          Text(
            '솔직한 평가는 더 좋은 커뮤니티를 만들어요',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
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
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
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
                onTap: () => setState(() => _selectedRating = starIndex),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingXS),
                  child: AnimatedScale(
                    scale: isSelected ? 1.1 : 1.0,
                    duration: const Duration(milliseconds: 150),
                    child: Icon(
                      isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
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
              style: TextStyle(
                fontSize: 14,
                color: _themeColor,
                fontWeight: FontWeight.w500,
              ),
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
    
    return Column(
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
                  color: isSelected ? tagColor.withValues(alpha: 0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSizes.radiusL),
                  border: Border.all(
                    color: isSelected ? tagColor : Theme.of(context).colorScheme.outline,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                    color: isSelected ? tagColor : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSizes.gapL),
      ],
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
    } catch (e) {
      if (mounted) {
        MingrrSnackBar.error(context, '평가 실패: $e');
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
void showActivityCompleteDialog(
  BuildContext context, {
  required String activityType,
  required String partnerName,
  required String partnerUserId,
  String? partnerImageUrl,
  String? relatedId,
  VoidCallback? onRateLater,
}) {
  final typeLabel = _getActivityTypeLabel(activityType);
  final ratingType = _getRatingType(activityType);
  
  showActionPromptDialog(
    context,
    icon: MingrrActionPromptDialog.buildCircleIcon(
      icon: Icons.check_circle_outline,
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
        targetImageUrl: partnerImageUrl,
        ratingType: ratingType,
        relatedId: relatedId,
      );
    },
    secondaryButtonText: '나중에 하기',
    onSecondaryPressed: onRateLater,
  );
}

String _getActivityTypeLabel(String type) {
  switch (type) {
    case 'dating':
      return '만남';
    case 'marketplace':
    case 'market':
      return '거래';
    case 'breeding':
      return '교배';
    case 'community':
      return '소모임';
    default:
      return '활동';
  }
}

RatingType _getRatingType(String type) {
  switch (type) {
    case 'dating':
      return RatingType.dating;
    case 'marketplace':
    case 'market':
      return RatingType.marketplace;
    case 'breeding':
      return RatingType.breeding;
    case 'community':
      return RatingType.community;
    default:
      return RatingType.dating;
  }
}

// ============================================================
// 3. 평가 완료 피드백 다이얼로그 (RatingCompleteDialog)
// ============================================================

/// 평가 완료 후 피드백 다이얼로그 표시
void showRatingCompleteDialog(BuildContext context) {
  showActionPromptDialog(
    context,
    icon: MingrrActionPromptDialog.buildGradientIcon(
      icon: Icons.pets,
      colors: [Colors.amber.shade300, Colors.orange.shade400],
    ),
    title: '✨ 평가 완료!',
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
                Icons.rate_review_outlined,
                size: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: AppSizes.gapM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📝 아직 평가하지 않은 활동이 있어요',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    '$pendingCount건의 평가가 기다리고 있어요',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
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
              const Icon(Icons.pets, size: 20),
              const SizedBox(width: AppSizes.gapS),
              Expanded(
                child: Text(
                  '🐾 $raterName님이 평가를 남겼어요!',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onDismiss,
                child: Icon(
                  Icons.close,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.gapS),
          Text(
            '나도 평가해볼까요?',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
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
              Icons.check_circle_outline,
              size: 48,
              color: context.features.success,
            ),
            const SizedBox(height: AppSizes.gapL),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSizes.gapS),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
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
            MingrrButton(
              text: '상대방이 안 나왔어요',
              onPressed: () {
                Navigator.pop(context);
                onNoShow();
              },
              isOutlined: true,
              backgroundColor: Colors.red,
              textColor: Colors.red,
              height: 48,
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
