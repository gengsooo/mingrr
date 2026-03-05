import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants/app_icons.dart';
import '../../constants/app_sizes.dart';
import '../../services/bottom_sheet_stack_manager.dart';
import '../../services/rating_service.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/feature_colors.dart';
import '../../utils/responsive_utils.dart';
import '../../utils/error_handler.dart';
import '../../../models/rating_model.dart';
import '../common_widgets.dart';
import '../sheets/mingrr_bottom_sheet.dart';
import 'rating_dialogs.dart';

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
        ? Theme.of(context).colorScheme.error 
        : result == ActivityResult.cancelled 
            ? Theme.of(context).colorScheme.outlineVariant 
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
    final tagColor = isPositive ? context.features.success : Theme.of(context).colorScheme.error;
    
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
