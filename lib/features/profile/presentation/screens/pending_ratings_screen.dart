import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/rating_service.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/rating_widgets.dart';
import '../../../../models/rating_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// ============================================================
/// 평가 대기 목록 화면
/// 
/// 내가 평가해야 할 거래/활동 목록을 표시
/// 홈 화면 배너에서 이동
/// AsyncRatingCard 공통 컴포넌트 사용
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
    final myUserId = FirebaseService().currentUserId;
    
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
              final isSeller = transaction.sellerId == myUserId;
              final targetId = isSeller ? transaction.buyerId : transaction.sellerId;
              final ratingType = RatingType.fromActivityType(transaction.type);
              
              return _PendingRatingCard(
                transaction: transaction,
                targetId: targetId,
                ratingType: ratingType,
                isSeller: isSeller,
                onRated: () => ref.invalidate(pendingRatingsProvider),
              );
            },
          );
        },
        loading: () => const MingrrLoadingState(
          type: MingrrLoadingType.primary,
          message: '평가 대기 목록을 불러오고 있어요',
        ),
        error: (_, _) => MingrrErrorState(
          onRetry: () => ref.invalidate(pendingRatingsProvider),
        ),
      ),
    );
  }
  
}

/// 평가 대기 카드 (사용자 정보 비동기 로딩 + 평가 모달 연동)
class _PendingRatingCard extends StatefulWidget {
  final TransactionStatusModel transaction;
  final String targetId;
  final RatingType ratingType;
  final bool isSeller;
  final VoidCallback onRated;

  const _PendingRatingCard({
    required this.transaction,
    required this.targetId,
    required this.ratingType,
    required this.isSeller,
    required this.onRated,
  });

  @override
  State<_PendingRatingCard> createState() => _PendingRatingCardState();
}

class _PendingRatingCardState extends State<_PendingRatingCard> {
  String _targetName = '사용자';
  String? _targetImageUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final userDoc = await FirebaseService().usersCollection.doc(widget.targetId).get();
      if (userDoc.exists && mounted) {
        setState(() {
          _targetName = userDoc.data()?['nickname'] ?? '사용자';
          _targetImageUrl = userDoc.data()?['profileImageUrl'];
          _isLoading = false;
        });
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showRatingDialog() {
    showRatingModal(
      context,
      targetUserId: widget.targetId,
      targetName: _targetName,
      targetImageUrl: _targetImageUrl,
      ratingType: widget.ratingType,
      relatedId: widget.transaction.id,
      onComplete: () async {
        await RatingService().markAsRated(widget.transaction.id, widget.isSeller);
        widget.onRated();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const RatingCardSkeleton();
    }

    return RatingCard(
      targetName: _targetName,
      targetImageUrl: _targetImageUrl,
      ratingType: widget.ratingType,
      createdAt: widget.transaction.createdAt,
      isPending: true,
      onRate: _showRatingDialog,
    );
  }
}
