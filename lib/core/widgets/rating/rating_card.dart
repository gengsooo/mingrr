import 'package:flutter/material.dart';
import '../../constants/app_icons.dart';
import '../../constants/rating_constants.dart';
import '../../constants/app_sizes.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/feature_colors.dart';
import '../../utils/format_utils.dart';
import '../../../models/rating_model.dart';
import '../mingrr_image.dart';

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
                          borderRadius: BorderRadius.circular(AppSizes.radiusS),
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
                          borderRadius: BorderRadius.circular(AppSizes.radiusS),
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
                    borderRadius: BorderRadius.circular(AppSizes.radiusS),
                  ),
                ),
                const SizedBox(height: AppSizes.gapXS),
                Container(
                  width: 60,
                  height: 12,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppSizes.radiusS),
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
