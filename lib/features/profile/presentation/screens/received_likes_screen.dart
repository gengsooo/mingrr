import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../dating/presentation/providers/dating_provider.dart';

/// 받은 좋아요 화면
class ReceivedLikesScreen extends ConsumerWidget {
  const ReceivedLikesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
  
  Widget _buildLikeItem(BuildContext context, dynamic like) {
    return MingrrCard(
      margin: const EdgeInsets.only(bottom: AppSizes.gapM),
      child: Row(
        children: [
          // 프로필 이미지
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.datingLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.pets, color: AppColors.dating, size: 30),
          ),
          const SizedBox(width: 12),
          // 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '반려동물 ${like.fromPetId}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
          // 수락/거절 버튼
          if (like.status.name == 'pending')
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textHint),
                  onPressed: () {
                    // TODO: 좋아요 거절 처리 구현 예정
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.favorite, color: AppColors.dating),
                  onPressed: () {
                    // TODO: 좋아요 수락 처리 구현 예정
                  },
                ),
              ],
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: like.status.name == 'accepted' 
                    ? AppColors.success.withOpacity(0.1)
                    : AppColors.textHint.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                like.status.name == 'accepted' ? '수락됨' : '거절됨',
                style: TextStyle(
                  fontSize: 12,
                  color: like.status.name == 'accepted' 
                      ? AppColors.success 
                      : AppColors.textHint,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
