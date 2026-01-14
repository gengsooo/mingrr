import 'package:flutter/material.dart';
import '../../models/rating_model.dart';
import '../constants/app_sizes.dart';
import '../theme/feature_colors.dart';
import 'common_widgets.dart';
import 'mingrr_bottom_sheet.dart';

/// ============================================================
/// 평가하기 바텀시트
/// 거래/데이팅/교배 완료 후 상대방 평가
/// ============================================================

class RatingSheet extends StatefulWidget {
  final String targetUserId;
  final String targetUserName;
  final String? targetUserImageUrl;
  final RatingType ratingType;
  final String? relatedId;
  final Function(int score, List<String> tags, String? comment, ActivityResult result) onSubmit;

  const RatingSheet({
    super.key,
    required this.targetUserId,
    required this.targetUserName,
    this.targetUserImageUrl,
    required this.ratingType,
    this.relatedId,
    required this.onSubmit,
  });

  static Future<void> show(
    BuildContext context, {
    required String targetUserId,
    required String targetUserName,
    String? targetUserImageUrl,
    required RatingType ratingType,
    String? relatedId,
    required Function(int score, List<String> tags, String? comment, ActivityResult result) onSubmit,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RatingSheet(
        targetUserId: targetUserId,
        targetUserName: targetUserName,
        targetUserImageUrl: targetUserImageUrl,
        ratingType: ratingType,
        relatedId: relatedId,
        onSubmit: onSubmit,
      ),
    );
  }

  @override
  State<RatingSheet> createState() => _RatingSheetState();
}

class _RatingSheetState extends State<RatingSheet> {
  int _selectedScore = 5;
  final Set<String> _selectedTags = {};
  final _commentController = TextEditingController();
  ActivityResult _result = ActivityResult.completed;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  List<String> get _positiveTags {
    switch (widget.ratingType) {
      case RatingType.dating:
        return PositiveRatingTags.dating;
      case RatingType.marketplace:
        return PositiveRatingTags.marketplace;
      case RatingType.breeding:
        return PositiveRatingTags.breeding;
      case RatingType.community:
        return PositiveRatingTags.dating;
    }
  }

  List<String> get _negativeTags {
    switch (widget.ratingType) {
      case RatingType.dating:
        return NegativeRatingTags.dating;
      case RatingType.marketplace:
        return NegativeRatingTags.marketplace;
      case RatingType.breeding:
        return NegativeRatingTags.breeding;
      case RatingType.community:
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
        return context.features.community;
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
          child: Padding(
            padding: EdgeInsets.only(
              left: AppSizes.paddingL,
              right: AppSizes.paddingL,
              bottom: AppSizes.paddingL,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(child: BottomSheetHandle()),

                // 헤더
                Center(
                  child: Column(
                    children: [
                      // 프로필 이미지
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                        backgroundImage: widget.targetUserImageUrl != null
                            ? NetworkImage(widget.targetUserImageUrl!)
                            : null,
                        child: widget.targetUserImageUrl == null
                            ? Icon(Icons.person, size: 36, color: Theme.of(context).colorScheme.outline)
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.targetUserName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$_typeLabel은 어떠셨나요?',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 활동 결과 선택
                const Text(
                  '활동 결과',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildResultChip(ActivityResult.completed, '완료'),
                    const SizedBox(width: 8),
                    _buildResultChip(ActivityResult.noShow, '노쇼'),
                    const SizedBox(width: 8),
                    _buildResultChip(ActivityResult.cancelled, '취소'),
                  ],
                ),
                const SizedBox(height: 24),

                // 별점
                if (_result == ActivityResult.completed) ...[
                  const Text(
                    '별점',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(5, (index) {
                        final starIndex = index + 1;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedScore = starIndex),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              starIndex <= _selectedScore
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              size: 40,
                              color: starIndex <= _selectedScore
                                  ? Colors.amber
                                  : Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      _getScoreLabel(_selectedScore),
                      style: TextStyle(
                        fontSize: 14,
                        color: _themeColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 평가 태그
                  Text(
                    _selectedScore >= 4 ? '좋았던 점' : '아쉬웠던 점',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (_selectedScore >= 4 ? _positiveTags : _negativeTags)
                        .map((tag) => _buildTagChip(tag))
                        .toList(),
                  ),
                  const SizedBox(height: 24),
                ],

                // 코멘트 (선택)
                const Text(
                  '한 줄 평가 (선택)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _commentController,
                  maxLength: 100,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: '상대방에게 전달하고 싶은 말을 적어주세요',
                    hintStyle: TextStyle(color: Theme.of(context).colorScheme.outlineVariant, fontSize: 13),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(16),
                    counterStyle: TextStyle(color: Theme.of(context).colorScheme.outlineVariant),
                  ),
                ),
                const SizedBox(height: 24),

                // 제출 버튼
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _themeColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Text(
                            '평가 완료',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultChip(ActivityResult result, String label) {
    final isSelected = _result == result;
    return GestureDetector(
      onTap: () => setState(() => _result = result),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _themeColor : Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? _themeColor : Theme.of(context).colorScheme.outline,
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

  Widget _buildTagChip(String tag) {
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _themeColor.withOpacity(0.1) : Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? _themeColor : Theme.of(context).colorScheme.outline,
          ),
        ),
        child: Text(
          tag,
          style: TextStyle(
            fontSize: 13,
            color: isSelected ? _themeColor : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
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

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);

    try {
      await widget.onSubmit(
        _result == ActivityResult.completed ? _selectedScore : 1,
        _selectedTags.toList(),
        _commentController.text.isNotEmpty ? _commentController.text : null,
        _result,
      );

      if (mounted) {
        Navigator.pop(context);
        MingrrSnackBar.success(context, '평가가 완료되었습니다');
      }
    } catch (e) {
      if (mounted) {
        MingrrSnackBar.error(context, '평가 중 오류가 발생했습니다: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}

/// 거래 완료 확인 다이얼로그
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
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 48,
              color: context.features.success,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            
            // 완료 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  onComplete();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.features.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('완료했어요'),
              ),
            ),
            const SizedBox(height: 8),
            
            // 노쇼 버튼
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                  onNoShow();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('상대방이 안 나왔어요'),
              ),
            ),
            const SizedBox(height: 8),
            
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
