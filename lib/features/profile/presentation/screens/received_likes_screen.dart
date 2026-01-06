import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('받은 좋아요'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: likesAsync.when(
        data: (likes) {
          if (likes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: AppColors.textHint),
                  const SizedBox(height: 16),
                  const Text(
                    '아직 받은 좋아요가 없어요',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '데이팅에서 활동해보세요!',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textHint,
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('데이터를 불러올 수 없습니다')),
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
            color: AppColors.divider,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 100, height: 16, color: AppColors.divider),
              const SizedBox(height: 8),
              Container(width: 150, height: 12, color: AppColors.divider),
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
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  like.message ?? '좋아요를 보냈어요!',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
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
                icon: const Icon(Icons.close, color: AppColors.textHint),
                onPressed: _isProcessing ? null : () => _rejectLike(like),
              ),
              IconButton(
                icon: const Icon(Icons.favorite, color: AppColors.dating),
                onPressed: _isProcessing ? null : () => _acceptLike(like),
              ),
            ],
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: like.status == LikeStatus.accepted 
                  ? AppColors.success.withOpacity(0.1)
                  : AppColors.textHint.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              like.status == LikeStatus.accepted ? '수락됨' : '거절됨',
              style: TextStyle(
                fontSize: 12,
                color: like.status == LikeStatus.accepted 
                    ? AppColors.success 
                    : AppColors.textHint,
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
        color: AppColors.datingLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.pets, color: AppColors.dating, size: 30),
    );
  }
  
  /// 좋아요 수락
  Future<void> _acceptLike(LikeModel like) async {
    setState(() => _isProcessing = true);
    
    try {
      final match = await _datingService.acceptLike(like.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('매칭 성공! 채팅을 시작해보세요 🎉'),
            backgroundColor: AppColors.success,
            action: match?.chatRoomId != null
                ? SnackBarAction(
                    label: '채팅하기',
                    textColor: Colors.white,
                    onPressed: () => context.push('/chat/${match!.chatRoomId}'),
                  )
                : null,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류가 발생했습니다: $e'),
            backgroundColor: AppColors.error,
          ),
        );
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
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('좋아요를 거절했습니다'),
            backgroundColor: AppColors.textSecondary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류가 발생했습니다: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}
