import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/bottom_sheet_stack_manager.dart';
import '../services/rating_service.dart';
import '../theme/feature_colors.dart';
import '../constants/app_sizes.dart';
import '../../models/rating_model.dart';
import 'common_widgets.dart';
import 'mingrr_bottom_sheet.dart';

/// ============================================================
/// 꼬순내지수 평가 모달 (통합 평가 시스템)
/// 
/// 사용처:
/// - 보호자 프로필 모달 > 평가하기 버튼
/// - 채팅 옵션 모달 > 평가하기
/// - 거래/만남 완료 후 평가
/// 
/// 평가 플로우:
/// 1. 별점 선택 (1~5점)
/// 2. 태그 선택 (긍정/부정)
/// 3. Firebase 저장 + 꼬순내지수 업데이트
/// ============================================================

/// 평가 모달 표시 함수 (통합)
void showRatingModal(
  BuildContext context, {
  required String targetUserId,
  required String targetName,
  RatingType ratingType = RatingType.dating,
  String? relatedId,
  VoidCallback? onComplete,
}) {
  final stackManager = BottomSheetStackManager();
  final sheetId = BottomSheetStackManager.createSheetId(BottomSheetType.rating, targetName);
  
  // 순환 감지
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
      ratingType: ratingType,
      relatedId: relatedId,
      onComplete: onComplete,
    ),
  ).then((_) {
    stackManager.pop(sheetId);
  });
}

/// 꼬순내지수 평가 모달 위젯
class RatingModal extends StatefulWidget {
  final String targetUserId;
  final String targetName;
  final RatingType ratingType;
  final String? relatedId;
  final VoidCallback? onComplete;

  const RatingModal({
    super.key,
    required this.targetUserId,
    required this.targetName,
    this.ratingType = RatingType.dating,
    this.relatedId,
    this.onComplete,
  });

  @override
  State<RatingModal> createState() => _RatingModalState();
}

class _RatingModalState extends State<RatingModal> {
  int _selectedRating = 0; // 1~5 별점
  final List<String> _selectedTags = [];
  bool _isSubmitting = false;
  final _ratingService = RatingService();

  // 태그 목록 (평가 타입별)
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

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
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
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL, vertical: 12),
            child: Column(
              children: [
                Text(
                  '${widget.targetName}님에 대한 평가를 보내주세요! 🐾',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  '솔직한 평가는 더 좋은 커뮤니티를 만들어요',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          
          // 별점 선택
          _buildStarRating(),
          
          // 태그 선택 (별점 선택 후 표시)
          if (_selectedRating > 0)
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL),
                child: _buildTagSelection(),
              ),
            ),
          
          // 제출 버튼
          _buildSubmitButton(),
          
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }

  /// 별점 선택 UI
  Widget _buildStarRating() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (index) {
          final starIndex = index + 1;
          final isSelected = starIndex <= _selectedRating;
          
          return GestureDetector(
            onTap: () => setState(() => _selectedRating = starIndex),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: AnimatedScale(
                scale: isSelected ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 150),
                child: Icon(
                  isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 44,
                  color: isSelected 
                      ? Colors.orange 
                      : Theme.of(context).colorScheme.outline,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  /// 태그 선택 UI
  Widget _buildTagSelection() {
    final isPositive = _selectedRating >= 3;
    final tags = isPositive ? _positiveTags : _negativeTags;
    final tagColor = isPositive ? context.features.success : Colors.red;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          isPositive ? '어떤 점이 좋았나요?' : '어떤 점이 아쉬웠나요?',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 12),
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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? tagColor.withValues(alpha: 0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
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
        const SizedBox(height: 16),
      ],
    );
  }

  /// 제출 버튼
  Widget _buildSubmitButton() {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.paddingL),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: (_selectedRating > 0 && !_isSubmitting) ? _submitRating : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            disabledBackgroundColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  '평가 완료',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  /// 평가 제출
  Future<void> _submitRating() async {
    setState(() => _isSubmitting = true);
    
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('로그인이 필요합니다');
      }
      
      // RatingService를 통해 평가 저장 + 꼬순내지수 업데이트
      await _ratingService.createRating(
        raterId: currentUser.uid,
        targetId: widget.targetUserId,
        type: widget.ratingType,
        relatedId: widget.relatedId,
        result: ActivityResult.completed,
        score: _selectedRating,
        tags: _selectedTags,
      );
      
      if (mounted) {
        Navigator.pop(context);
        
        // 평가 완료 피드백
        _showCompletionFeedback();
        
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

  /// 평가 완료 피드백 표시
  void _showCompletionFeedback() {
    MingrrSnackBar.success(
      context, 
      '✨ 평가 완료! 더 좋은 커뮤니티를 만드는 데 도움이 돼요 🐾',
    );
  }
}
