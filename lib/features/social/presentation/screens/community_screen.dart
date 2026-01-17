import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/feature_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/filter_components.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/svg_icons.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../models/community_post_model.dart';
import '../providers/community_provider.dart';
import 'community_write_screen.dart';
import 'community_detail_screen.dart';

/// ============================================================
/// 커뮤니티(Community) 게시판 화면
/// 
/// 소셜 > 커뮤니티 탭
/// 게시판 형태의 게시글 목록, 카테고리 필터링
/// ============================================================

/// 선택된 카테고리
final _selectedCommunityCategory = StateProvider<CommunityCategory?>((ref) => null);

class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(_selectedCommunityCategory);
    final postsAsync = ref.watch(communityPostsProvider(selectedCategory));
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = context.features.social;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // 카테고리 필터
          _buildCategoryFilter(context, ref, selectedCategory),
          
          // 피드 목록
          Expanded(
            child: postsAsync.when(
              data: (posts) {
                if (posts.isEmpty) {
                  return MingrrEmptyState(
                    icon: Icons.article_outlined,
                    title: '아직 데이터가 없어요',
                    subtitle: '첫 번째 글을 작성해보세요',
                    buttonText: '글 작성하기',
                    onButtonPressed: () => _navigateToWrite(context),
                    accentColor: accentColor,
                  );
                }
                
                return RefreshIndicator(
                  color: accentColor,
                  onRefresh: () async {
                    ref.invalidate(communityPostsProvider(selectedCategory));
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSizes.paddingM),
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      return _CommunityPostCard(
                        post: posts[index],
                        onTap: () => _navigateToDetail(context, posts[index]),
                        onLike: () => ref.read(communityNotifierProvider.notifier)
                            .toggleLike(posts[index].id),
                      );
                    },
                  ),
                );
              },
              loading: () => const MingrrLoadingState(),
              error: (_, __) => MingrrErrorState(
                title: '일시적인 오류가 발생했어요',
                subtitle: '잠시 후 다시 시도해주세요',
                buttonText: '다시 시도',
                onRetry: () => ref.invalidate(communityPostsProvider(selectedCategory)),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToWrite(context),
        backgroundColor: accentColor,
        shape: const CircleBorder(),
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }

  Widget _buildCategoryFilter(BuildContext context, WidgetRef ref, CommunityCategory? selected) {
    final accentColor = context.features.social;
    
    // 카테고리 목록 생성 (이모지 제거)
    final categories = [
      '전체',
      ...CommunityCategory.values.map((c) => c.label),
    ];
    
    // 선택된 인덱스 계산
    final selectedIndex = selected == null 
        ? 0 
        : CommunityCategory.values.indexOf(selected) + 1;
    
    return MingrrCategoryChips(
      title: '카테고리',
      categories: categories,
      selectedIndex: selectedIndex,
      onSelected: (index) {
        if (index == 0) {
          ref.read(_selectedCommunityCategory.notifier).state = null;
        } else {
          ref.read(_selectedCommunityCategory.notifier).state = CommunityCategory.values[index - 1];
        }
      },
      accentColor: accentColor,
    );
  }

  void _navigateToWrite(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CommunityWriteScreen()),
    );
  }

  void _navigateToDetail(BuildContext context, CommunityPostModel post) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CommunityDetailScreen(postId: post.id)),
    );
  }
}

/// 커뮤니티 게시글 아이템 (게시판 리스트 형태)
class _CommunityPostCard extends StatelessWidget {
  final CommunityPostModel post;
  final VoidCallback onTap;
  final VoidCallback onLike;

  const _CommunityPostCard({
    required this.post,
    required this.onTap,
    required this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = context.features.social;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 1),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border(
            bottom: BorderSide(color: colorScheme.outline.withOpacity(0.1)),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 왼쪽: 게시글 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 카테고리 + 제목/내용
                  Row(
                    children: [
                      // 카테고리 태그
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          post.category.label,
                          style: TextStyle(
                            fontSize: 11,
                            color: accentColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 익명 표시
                      if (post.isAnonymous)
                        Icon(Icons.visibility_off, size: 14, color: colorScheme.onSurfaceVariant),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // 본문 내용 (제목처럼 표시)
                  Text(
                    post.content,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 10),
                  
                  // 하단 정보 (작성자, 시간, 댓글/좋아요/조회수)
                  Row(
                    children: [
                      // 작성자
                      Text(
                        post.displayAuthorName,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      _buildDot(colorScheme),
                      // 시간
                      Text(
                        formatRelativeTime(post.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const Spacer(),
                      // 댓글
                      Icon(Icons.chat_bubble_outline, size: 14, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 3),
                      Text(
                        '${post.commentCount}',
                        style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(width: 12),
                      // 좋아요
                      Icon(Icons.favorite_border, size: 14, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 3),
                      Text(
                        '${post.likeCount}',
                        style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(width: 12),
                      // 조회수
                      Icon(Icons.visibility_outlined, size: 14, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 3),
                      Text(
                        '${post.viewCount}',
                        style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // 오른쪽: 썸네일 이미지 (있는 경우)
            if (post.hasImages) ...[
              const SizedBox(width: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  post.firstImage!,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 70,
                    height: 70,
                    color: colorScheme.surfaceContainerLow,
                    child: Icon(Icons.image, color: colorScheme.onSurfaceVariant),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDot(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        '·',
        style: TextStyle(color: colorScheme.onSurfaceVariant),
      ),
    );
  }

}
