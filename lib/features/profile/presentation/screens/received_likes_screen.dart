import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/feature_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/services/dating_service.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../models/dating_model.dart';
import '../../../../models/pet_model.dart';
import '../../../dating/presentation/providers/dating_provider.dart';
import '../../../pet/presentation/providers/pet_provider.dart';

/// 받은 좋아요 화면
class ReceivedLikesScreen extends ConsumerStatefulWidget {
  const ReceivedLikesScreen({super.key});

  @override
  ConsumerState<ReceivedLikesScreen> createState() => _ReceivedLikesScreenState();
}

class _ReceivedLikesScreenState extends ConsumerState<ReceivedLikesScreen> {
  final DatingService _datingService = DatingService();
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final likesAsync = ref.watch(receivedLikesProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('받은 좋아요'),
      ),
      body: likesAsync.when(
        data: (likes) {
          if (likes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: Theme.of(context).colorScheme.outlineVariant),
                  const SizedBox(height: 16),
                  Text(
                    '아직 받은 좋아요가 없어요',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '데이팅에서 활동해보세요!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                ],
              ),
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(AppSizes.paddingM),
            itemCount: likes.length,
            itemBuilder: (context, index) {
              final like = likes[index];
              return _buildLikeItem(context, like);
            },
          );
        },
        loading: () => const MingrrLoadingState(),
        error: (_, __) => const MingrrErrorState(title: '데이터를 불러올 수 없습니다'),
      ),
    );
  }
  
  Widget _buildLikeItem(BuildContext context, LikeModel like) {
    // 보낸 반려동물 정보 가져오기
    final petAsync = ref.watch(petByIdProvider(like.fromPetId));
    
    return MingrrCard(
      margin: const EdgeInsets.only(bottom: AppSizes.gapM),
      child: petAsync.when(
        data: (pet) => _buildLikeContent(context, like, pet),
        loading: () => _buildLoadingContent(),
        error: (_, __) => _buildLikeContent(context, like, null),
      ),
    );
  }
  
  Widget _buildLoadingContent() {
    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.outline,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 100, height: 16, color: Theme.of(context).colorScheme.outline),
              const SizedBox(height: 8),
              Container(width: 150, height: 12, color: Theme.of(context).colorScheme.outline),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildLikeContent(BuildContext context, LikeModel like, PetModel? pet) {
    return Row(
      children: [
        // 프로필 이미지
        GestureDetector(
          onTap: () => context.push('/dating/detail/${like.fromPetId}'),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: pet?.displayImageUrl != null
                ? Image.network(
                    pet!.displayImageUrl!,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildDefaultPetImage(),
                  )
                : _buildDefaultPetImage(),
          ),
        ),
        const SizedBox(width: 12),
        // 정보
        Expanded(
          child: GestureDetector(
            onTap: () => context.push('/dating/detail/${like.fromPetId}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pet?.name ?? '반려동물',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (pet != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${pet.breed ?? '믹스견'} · ${pet.ageString}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  like.message ?? '좋아요를 보냈어요!',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
        // 수락/거절 버튼
        if (like.status == LikeStatus.pending)
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.close, color: Theme.of(context).colorScheme.outlineVariant),
                onPressed: _isProcessing ? null : () => _rejectLike(like),
              ),
              IconButton(
                icon: Icon(Icons.favorite, color: context.features.dating),
                onPressed: _isProcessing ? null : () => _acceptLike(like),
              ),
            ],
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: like.status == LikeStatus.accepted 
                  ? context.features.success.withOpacity(0.1)
                  : Theme.of(context).colorScheme.outlineVariant.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              like.status == LikeStatus.accepted ? '수락됨' : '거절됨',
              style: TextStyle(
                fontSize: 12,
                color: like.status == LikeStatus.accepted 
                    ? context.features.success 
                    : Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ),
      ],
    );
  }
  
  Widget _buildDefaultPetImage() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: context.features.datingContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.pets, color: context.features.dating, size: 30),
    );
  }
  
  /// 좋아요 수락
  Future<void> _acceptLike(LikeModel like) async {
    setState(() => _isProcessing = true);
    
    try {
      final match = await _datingService.acceptLike(like.id);
      
      if (mounted) {
        if (match?.chatRoomId != null) {
          MingrrSnackBar.withAction(
            context,
            message: '매칭 성공! 채팅을 시작해보세요 🎉',
            actionLabel: '채팅하기',
            onAction: () => context.push('/chat/${match!.chatRoomId}'),
            backgroundColor: context.features.success,
          );
        } else {
          MingrrSnackBar.success(context, '매칭 성공! 채팅을 시작해보세요 🎉');
        }
      }
    } catch (e) {
      if (mounted) {
        MingrrSnackBar.error(context, '오류가 발생했습니다: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
  
  /// 좋아요 거절
  Future<void> _rejectLike(LikeModel like) async {
    // 확인 다이얼로그
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('좋아요 거절'),
        content: const Text('이 좋아요를 거절하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('거절'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    setState(() => _isProcessing = true);
    
    try {
      await _datingService.rejectLike(like.id);
      
      if (mounted) {
        MingrrSnackBar.info(context, '좋아요를 거절했습니다');
      }
    } catch (e) {
      if (mounted) {
        MingrrSnackBar.error(context, '오류가 발생했습니다: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}
