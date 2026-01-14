import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/feature_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/svg_icons.dart';
import '../../../../models/feed_model.dart';
import '../providers/feed_provider.dart';
import 'feed_write_screen.dart';
import 'feed_detail_screen.dart';

/// ============================================================
/// 커뮤니티 피드 화면
/// SNS형 게시판 - 글/이미지 공유, 좋아요, 댓글
/// ============================================================

/// 선택된 카테고리
final _selectedCategoryProvider = StateProvider<FeedCategory?>((ref) => null);

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(_selectedCategoryProvider);
    final feedsAsync = ref.watch(feedPostsProvider(selectedCategory));
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = context.features.community;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // 카테고리 필터
          _buildCategoryFilter(context, ref, selectedCategory),
          
          // 피드 목록
          Expanded(
            child: feedsAsync.when(
              data: (posts) {
                if (posts.isEmpty) {
                  return Center(
                    child: MingrrEmptyState(
                      svgAsset: SvgAssets.emptyList,
                      title: '아직 게시글이 없어요',
                      subtitle: '첫 번째 글을 작성해보세요!',
                      buttonText: '글 작성하기',
                      onButtonPressed: () => _navigateToWrite(context),
                    ),
                  );
                }
                
                return RefreshIndicator(
                  color: accentColor,
                  onRefresh: () async {
                    ref.invalidate(feedPostsProvider(selectedCategory));
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSizes.paddingM),
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      return _FeedPostCard(
                        post: posts[index],
                        onTap: () => _navigateToDetail(context, posts[index]),
                        onLike: () => ref.read(feedProviderNotifier.notifier)
                            .toggleLike(posts[index].id),
                      );
                    },
                  ),
                );
              },
              loading: () => const MingrrLoadingState(),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                    const SizedBox(height: 16),
                    Text('데이터를 불러올 수 없습니다', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => ref.invalidate(feedPostsProvider(selectedCategory)),
                      child: const Text('다시 시도'),
                    ),
                  ],
                ),
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

  Widget _buildCategoryFilter(BuildContext context, WidgetRef ref, FeedCategory? selected) {
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = context.features.community;
    
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
        ),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM),
        children: [
          // 전체 버튼
          _CategoryChip(
            label: '전체',
            isSelected: selected == null,
            accentColor: accentColor,
            onTap: () => ref.read(_selectedCategoryProvider.notifier).state = null,
          ),
          const SizedBox(width: 8),
          // 카테고리 버튼들
          ...FeedCategory.values.map((category) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _CategoryChip(
              label: '${category.emoji} ${category.label}',
              isSelected: selected == category,
              accentColor: accentColor,
              onTap: () => ref.read(_selectedCategoryProvider.notifier).state = category,
            ),
          )),
        ],
      ),
    );
  }

  void _navigateToWrite(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FeedWriteScreen()),
    );
  }

  void _navigateToDetail(BuildContext context, FeedPostModel post) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FeedDetailScreen(postId: post.id)),
    );
  }
}

/// 카테고리 칩
class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? accentColor : colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? accentColor : colorScheme.outline.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? Colors.white : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// 피드 게시글 카드
class _FeedPostCard extends StatelessWidget {
  final FeedPostModel post;
  final VoidCallback onTap;
  final VoidCallback onLike;

  const _FeedPostCard({
    required this.post,
    required this.onTap,
    required this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = context.features.community;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더 (작성자 정보)
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // 프로필 아바타
                  MingrrAvatar(
                    size: 40,
                    imageUrl: post.isAnonymous ? null : post.authorProfileUrl,
                    placeholderIcon: Icons.person,
                  ),
                  const SizedBox(width: 10),
                  // 작성자 정보
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              post.displayAuthorName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: accentColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                post.category.label,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: accentColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatTimeAgo(post.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 더보기 버튼
                  IconButton(
                    icon: Icon(Icons.more_horiz, color: colorScheme.onSurfaceVariant),
                    onPressed: () {},
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            
            // 본문
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                post.content,
                style: const TextStyle(fontSize: 14, height: 1.5),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            // 이미지 (있는 경우)
            if (post.hasImages) ...[
              const SizedBox(height: 12),
              _buildImages(context, post.imageUrls),
            ],
            
            // 태그
            if (post.tags.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: post.tags.map((tag) => Text(
                    '#$tag',
                    style: TextStyle(
                      fontSize: 12,
                      color: accentColor,
                    ),
                  )).toList(),
                ),
              ),
            ],
            
            // 하단 액션 바
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // 좋아요
                  _ActionButton(
                    icon: Icons.favorite_border,
                    activeIcon: Icons.favorite,
                    label: '${post.likeCount}',
                    isActive: false,
                    activeColor: Colors.red,
                    onTap: onLike,
                  ),
                  const SizedBox(width: 20),
                  // 댓글
                  _ActionButton(
                    icon: Icons.chat_bubble_outline,
                    label: '${post.commentCount}',
                    onTap: onTap,
                  ),
                  const SizedBox(width: 20),
                  // 조회수
                  Row(
                    children: [
                      Icon(Icons.visibility_outlined, size: 18, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        '${post.viewCount}',
                        style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // 공유
                  IconButton(
                    icon: Icon(Icons.share_outlined, size: 20, color: colorScheme.onSurfaceVariant),
                    onPressed: () {},
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImages(BuildContext context, List<String> imageUrls) {
    if (imageUrls.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.zero,
        child: Image.network(
          imageUrls.first,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            height: 200,
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            child: const Center(child: Icon(Icons.image_not_supported)),
          ),
        ),
      );
    }
    
    return SizedBox(
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(right: index < imageUrls.length - 1 ? 8 : 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrls[index],
                width: 150,
                height: 150,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 150,
                  height: 150,
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  child: const Center(child: Icon(Icons.image_not_supported)),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    
    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    return '${dateTime.month}/${dateTime.day}';
  }
}

/// 액션 버튼
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final bool isActive;
  final Color? activeColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    this.activeIcon,
    required this.label,
    this.isActive = false,
    this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = isActive ? (activeColor ?? colorScheme.primary) : colorScheme.onSurfaceVariant;
    
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            isActive ? (activeIcon ?? icon) : icon,
            size: 20,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: color),
          ),
        ],
      ),
    );
  }
}
