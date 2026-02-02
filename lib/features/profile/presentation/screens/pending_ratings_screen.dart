import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/feature_colors.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/rating_service.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/mingrr_image.dart';
import '../../../../core/widgets/rating_widgets.dart';
import '../../../../models/rating_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// ============================================================
/// 평가 대기 목록 화면
/// 
/// 내가 평가해야 할 거래/활동 목록을 표시
/// 홈 화면 배너에서 이동
/// ============================================================

/// 평가 대기 목록 Provider
final pendingRatingsProvider = StreamProvider.autoDispose<List<TransactionStatusModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  final userId = authState.valueOrNull?.uid;
  
  if (userId == null) return Stream.value([]);
  
  final ratingService = RatingService();
  return ratingService.watchPendingRatings(userId);
});

class PendingRatingsScreen extends ConsumerWidget {
  const PendingRatingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingRatingsAsync = ref.watch(pendingRatingsProvider);
    
    return Scaffold(
      appBar: const MingrrAppBar(title: '평가 대기'),
      body: pendingRatingsAsync.when(
        data: (transactions) {
          if (transactions.isEmpty) {
            return MingrrEmptyState(
              icon: AppIcons.starOutlined,
              title: '평가할 항목이 없어요',
              subtitle: '거래나 활동이 완료되면 여기에 표시됩니다',
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(AppSizes.paddingM),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              return _PendingRatingCard(transaction: transaction);
            },
          );
        },
        loading: () => const MingrrLoadingState(
          type: MingrrLoadingType.primary,
          message: '평가 대기 목록을 불러오고 있어요',
        ),
        error: (_, __) => MingrrErrorState(
          onRetry: () => ref.invalidate(pendingRatingsProvider),
        ),
      ),
    );
  }
}

/// 평가 대기 카드
class _PendingRatingCard extends ConsumerStatefulWidget {
  final TransactionStatusModel transaction;
  
  const _PendingRatingCard({required this.transaction});

  @override
  ConsumerState<_PendingRatingCard> createState() => _PendingRatingCardState();
}

class _PendingRatingCardState extends ConsumerState<_PendingRatingCard> {
  String? _targetName;
  String? _targetImageUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTargetInfo();
  }

  Future<void> _loadTargetInfo() async {
    final myUserId = FirebaseService().currentUserId;
    if (myUserId == null) return;
    
    // 내가 판매자면 구매자 정보, 내가 구매자면 판매자 정보
    final targetId = widget.transaction.sellerId == myUserId
        ? widget.transaction.buyerId
        : widget.transaction.sellerId;
    
    try {
      final userDoc = await FirebaseService().usersCollection.doc(targetId).get();
      if (userDoc.exists && mounted) {
        setState(() {
          _targetName = userDoc.data()?['nickname'] ?? '사용자';
          _targetImageUrl = userDoc.data()?['profileImageUrl'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final myUserId = FirebaseService().currentUserId;
    final isSeller = widget.transaction.sellerId == myUserId;
    
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingM),
      child: InkWell(
        onTap: () => _showRatingDialog(context, isSeller),
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingM),
          child: Row(
            children: [
              // 프로필 이미지
              _isLoading
                  ? Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : MingrrImage.avatar(
                      imageUrl: _targetImageUrl,
                      size: 56,
                      icon: AppIcons.profile,
                    ),
              const SizedBox(width: AppSizes.gapM),
              // 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _targetName ?? '로딩 중...',
                      style: AppTextStyles.titleMedium(context).withWeight(FontWeight.w600),
                    ),
                    const SizedBox(height: AppSizes.gapXXS),
                    Text(
                      _getTypeLabel(widget.transaction.type),
                      style: AppTextStyles.bodySmall(context).withColor(colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: AppSizes.gapXXS),
                    Text(
                      _formatDate(widget.transaction.createdAt),
                      style: AppTextStyles.caption(context).withColor(colorScheme.outline),
                    ),
                  ],
                ),
              ),
              // 평가하기 버튼
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingM,
                  vertical: AppSizes.paddingS,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppSizes.radiusS),
                ),
                child: Text(
                  '평가하기',
                  style: AppTextStyles.labelMedium(context).withColor(colorScheme.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'marketplace':
        return '마켓 거래';
      case 'dating':
        return '데이팅/산책';
      case 'breeding':
        return '교배';
      case 'community':
        return '소모임 활동';
      default:
        return '활동';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) {
      return '오늘';
    } else if (diff.inDays == 1) {
      return '어제';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}일 전';
    } else {
      return '${date.month}월 ${date.day}일';
    }
  }

  void _showRatingDialog(BuildContext context, bool isSeller) {
    final myUserId = FirebaseService().currentUserId;
    if (myUserId == null) return;
    
    final targetId = isSeller
        ? widget.transaction.buyerId
        : widget.transaction.sellerId;
    
    // 평가 타입 결정
    final ratingType = _getRatingType(widget.transaction.type);
    
    // 평가 모달 표시
    showRatingModal(
      context,
      targetUserId: targetId,
      targetName: _targetName ?? '상대방',
      ratingType: ratingType,
      relatedId: widget.transaction.id,
      onComplete: () {
        // 평가 완료 후 목록 갱신
        ref.invalidate(pendingRatingsProvider);
      },
    );
  }

  RatingType _getRatingType(String type) {
    switch (type) {
      case 'marketplace':
        return RatingType.marketplace;
      case 'dating':
        return RatingType.dating;
      case 'breeding':
        return RatingType.breeding;
      // 소모임(community/group)은 평가 기능 없음
      default:
        return RatingType.marketplace;
    }
  }
}
