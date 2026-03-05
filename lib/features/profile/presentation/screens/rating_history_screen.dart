import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/rating_service.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/navigation/top_navigation.dart';
import '../../../../core/widgets/rating_widgets.dart';
import '../../../../models/rating_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// ============================================================
/// 평가 이력 조회 화면
/// 
/// 프로필 > 평가 이력
/// 탭 구성: 받은 평가 / 보낸 평가
/// RatingCard 공통 컴포넌트 사용
/// ============================================================

/// 받은 평가 목록 Provider
final receivedRatingsProvider = StreamProvider.autoDispose<List<RatingModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  final userId = authState.valueOrNull?.uid;
  
  if (userId == null) return Stream.value([]);
  
  final ratingService = RatingService();
  return ratingService.getReceivedRatings(userId).handleError((error, stackTrace) {
    AppLogger.error('RatingHistoryScreen', '받은 평가 로드 실패 (userId: $userId)', error, stackTrace);
    return <RatingModel>[];
  });
});

/// 보낸 평가 목록 Provider
final givenRatingsProvider = StreamProvider.autoDispose<List<RatingModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  final userId = authState.valueOrNull?.uid;
  
  if (userId == null) return Stream.value([]);
  
  final ratingService = RatingService();
  return ratingService.getGivenRatings(userId).handleError((error, stackTrace) {
    AppLogger.error('RatingHistoryScreen', '보낸 평가 로드 실패 (userId: $userId)', error, stackTrace);
    return <RatingModel>[];
  });
});

class RatingHistoryScreen extends ConsumerWidget {
  const RatingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: const MingrrAppBar(title: '평가 이력'),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const MingrrSubTabBar(
              tabs: ['받은 평가', '보낸 평가'],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _ReceivedRatingsTab(),
                  _GivenRatingsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 받은 평가 탭
class _ReceivedRatingsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ratingsAsync = ref.watch(receivedRatingsProvider);
    
    return ratingsAsync.when(
      data: (ratings) {
        if (ratings.isEmpty) {
          return MingrrEmptyState(
            icon: AppIcons.starOutlined,
            title: '받은 평가가 없어요',
            subtitle: '활동을 완료하면 상대방이 평가를 남길 수 있어요',
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(AppSizes.paddingM),
          itemCount: ratings.length,
          itemBuilder: (context, index) {
            final rating = ratings[index];
            return _RatingHistoryCard(
              rating: rating,
              isReceived: true,
            );
          },
        );
      },
      loading: () => const MingrrLoadingState(
        type: MingrrLoadingType.primary,
        message: '받은 평가를 불러오고 있어요',
      ),
      error: (_, _) => MingrrErrorState(
        onRetry: () => ref.invalidate(receivedRatingsProvider),
      ),
    );
  }
}

/// 보낸 평가 탭
class _GivenRatingsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ratingsAsync = ref.watch(givenRatingsProvider);
    
    return ratingsAsync.when(
      data: (ratings) {
        if (ratings.isEmpty) {
          return MingrrEmptyState(
            icon: AppIcons.starOutlined,
            title: '보낸 평가가 없어요',
            subtitle: '활동을 완료하고 상대방을 평가해보세요',
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(AppSizes.paddingM),
          itemCount: ratings.length,
          itemBuilder: (context, index) {
            final rating = ratings[index];
            return _RatingHistoryCard(
              rating: rating,
              isReceived: false,
            );
          },
        );
      },
      loading: () => const MingrrLoadingState(
        type: MingrrLoadingType.primary,
        message: '보낸 평가를 불러오고 있어요',
      ),
      error: (_, _) => MingrrErrorState(
        onRetry: () => ref.invalidate(givenRatingsProvider),
      ),
    );
  }
}

/// 평가 이력 카드 (비동기 사용자 정보 로딩)
class _RatingHistoryCard extends StatefulWidget {
  final RatingModel rating;
  final bool isReceived;
  
  const _RatingHistoryCard({
    required this.rating,
    required this.isReceived,
  });

  @override
  State<_RatingHistoryCard> createState() => _RatingHistoryCardState();
}

class _RatingHistoryCardState extends State<_RatingHistoryCard> {
  String? _userName;
  String? _userImageUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final targetId = widget.isReceived 
        ? widget.rating.raterId 
        : widget.rating.targetId;
    
    try {
      final userDoc = await FirebaseService().usersCollection.doc(targetId).get();
      if (userDoc.exists && mounted) {
        setState(() {
          _userName = userDoc.data()?['nickname'] ?? '사용자';
          _userImageUrl = userDoc.data()?['profileImageUrl'];
          _isLoading = false;
        });
      } else {
        if (mounted) setState(() => _isLoading = false);
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
      targetName: _userName ?? '알 수 없음',
      targetImageUrl: _userImageUrl,
      ratingType: widget.rating.type,
      createdAt: widget.rating.createdAt,
      score: widget.rating.result == ActivityResult.completed ? widget.rating.score : null,
      tags: widget.rating.tags.isNotEmpty ? widget.rating.tags : null,
      isPending: false,
    );
  }
}
