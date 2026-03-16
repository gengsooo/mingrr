import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/feature_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/filter_components.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/refresh_wrapper.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../models/community_post_model.dart';
import '../../../../core/providers/refresh_notifier.dart';
import '../../../../core/models/sort_state.dart';
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

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final selectedCategory = ref.read(_selectedCommunityCategory);
      ref.read(paginatedCommunityPostsProvider(selectedCategory).notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedCategory = ref.watch(_selectedCommunityCategory);
    final paginatedState = ref.watch(paginatedCommunityPostsProvider(selectedCategory));
    final accentColor = context.features.social;

    // 새로고침 트리거 감지 (등록/수정/삭제 후 자동 새로고침)
    ref.listen(communityRefreshProvider, (prev, next) {
      if (prev != next) {
        ref.read(paginatedCommunityPostsProvider(selectedCategory).notifier).refresh();
      }
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // 카테고리 필터
          _buildCategoryFilter(context, ref, selectedCategory),
          
          // 정렬 옵션
          _buildSortOptions(context, ref),
          
          // 피드 목록 (Provider 레벨 페이지네이션)
          Expanded(
            child: _buildPostList(paginatedState, accentColor),
          ),
        ],
      ),
      floatingActionButton: MingrrFAB.write(
        onPressed: () => _navigateToWrite(context),
        backgroundColor: accentColor,
        tooltip: '게시글 작성',
      ),
    );
  }

  Widget _buildPostList(dynamic paginatedState, Color accentColor) {
    // 초기 로딩 상태
    if (paginatedState.isInitialLoading) {
      return MingrrLoadingState(
        type: MingrrLoadingType.community,
        message: '게시글을 불러오고 있어요',
        timeout: AppSizes.loadingTimeout,
        onRetry: () {
          final selectedCategory = ref.read(_selectedCommunityCategory);
          ref.read(paginatedCommunityPostsProvider(selectedCategory).notifier).loadInitial();
        },
      );
    }

    // 에러 상태
    if (paginatedState.hasError && paginatedState.items.isEmpty) {
      return MingrrErrorState(
        title: '일시적인 오류가 발생했어요',
        subtitle: '잠시 후 다시 시도해주세요',
        buttonText: '다시 시도',
        onRetry: () {
          final selectedCategory = ref.read(_selectedCommunityCategory);
          ref.read(paginatedCommunityPostsProvider(selectedCategory).notifier).loadInitial();
        },
      );
    }

    // 빈 상태
    if (paginatedState.isEmpty) {
      return MingrrEmptyState(
        icon: AppIcons.communityOutlined,
        title: '아직 데이터가 없어요',
        subtitle: '첫 번째 글을 작성해보세요',
        buttonText: '글 작성하기',
        onButtonPressed: () => _navigateToWrite(context),
        accentColor: accentColor,
        onRefresh: () async {
          final selectedCategory = ref.read(_selectedCommunityCategory);
          await ref.read(paginatedCommunityPostsProvider(selectedCategory).notifier).refresh();
        },
      );
    }

    // 데이터 있음
    return MingrrRefreshWrapper(
      color: accentColor,
      onRefresh: () async {
        final selectedCategory = ref.read(_selectedCommunityCategory);
        ref.invalidate(paginatedCommunityPostsProvider(selectedCategory));
        // invalidate 후 새 데이터 로딩 대기
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSizes.paddingM),
        itemCount: paginatedState.items.length + (paginatedState.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          // 로딩 인디케이터
          if (index >= paginatedState.items.length) {
            return const MingrrPaginationLoader();
          }

          final post = paginatedState.items[index];
          return MingrrAnimatedListItem(
            index: index,
            child: _CommunityPostCard(
              post: post,
              onTap: () => _navigateToDetail(context, post),
              onLike: () => ref.read(communityNotifierProvider.notifier).toggleLike(post.id),
            ),
          );
        },
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

  Widget _buildSortOptions(BuildContext context, WidgetRef ref) {
    final sortState = ref.watch(communitySortStateProvider);
    final accentColor = context.features.social;
    
    final sortOptions = ['최신순', '인기순'];
    final selectedIndex = CommunitySortOption.values.indexOf(sortState.option);
    final isAscending = sortState.direction == SortDirection.ascending;

    return MingrrSortChips(
      title: '정렬',
      options: sortOptions,
      selectedIndex: selectedIndex,
      isAscending: isAscending,
      onSelected: (index) {
        final notifier = ref.read(communitySortStateProvider.notifier);
        final option = CommunitySortOption.values[index];
        if (sortState.option == option) {
          notifier.state = sortState.toggleDirection();
        } else {
          notifier.state = CommunitySortState(option: option, direction: SortDirection.descending);
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

  static const double _thumbnailSize = 70.0;

  const _CommunityPostCard({
    required this.post,
    required this.onTap,
    required this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = context.features.social;
    final hasMedia = post.hasMedia;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSizes.paddingS),
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM, vertical: AppSizes.paddingS),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusS),
          boxShadow: AppShadows.shadowS(Theme.of(context).brightness == Brightness.dark),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 왼쪽: 게시글 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 상단 콘텐츠
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 카테고리 + 익명
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: AppSizes.paddingXXS),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: AppOpacity.o10),
                                borderRadius: BorderRadius.circular(AppSizes.radiusS),
                              ),
                              child: Text(
                                post.category.label,
                                style: AppTextStyles.labelSmall(context).withWeight(FontWeight.w600).withColor(accentColor),
                              ),
                            ),
                            if (post.isAnonymous) ...[
                              const SizedBox(width: AppSizes.gapXS),
                              Icon(AppIcons.visibilityOff, size: 10, color: colorScheme.outlineVariant),
                            ],
                          ],
                        ),
                        const SizedBox(height: AppSizes.gapXS),
                        
                        // 제목
                        if (post.title.isNotEmpty)
                          Text(
                            post.title,
                            style: AppTextStyles.titleMedium(context).withWeight(FontWeight.w600).withHeight(1.2),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (post.title.isNotEmpty) const SizedBox(height: AppSizes.gapXXS),
                        
                        // 본문 내용
                        Text(
                          post.content,
                          style: AppTextStyles.bodySmall(context).withColor(colorScheme.onSurfaceVariant).withHeight(1.3),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: AppSizes.gapS),
                    
                    // 작성자 · 시간
                    Text(
                      '${post.displayAuthorName} · ${formatRelativeTime(post.createdAt)}',
                      style: AppTextStyles.captionSmall(context).copyWith(color: colorScheme.outlineVariant),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              // 오른쪽: 이미지 + 액션 버튼
              const SizedBox(width: 10),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // 썸네일 이미지 (미디어가 있을 때만)
                  if (hasMedia)
                    Stack(
                      children: [
                        MingrrImage.thumbnail(
                          imageUrl: post.hasVideo ? post.videoThumbnailUrl : post.firstImage,
                          width: _thumbnailSize,
                          height: _thumbnailSize,
                          radius: AppSizes.radiusS,
                          accentColor: accentColor,
                        ),
                        if (post.hasVideo)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black26,
                                borderRadius: BorderRadius.circular(AppSizes.radiusS),
                              ),
                              child: const Icon(AppIcons.play, color: Colors.white, size: 24),
                            ),
                          ),
                      ],
                    )
                  else
                    const SizedBox.shrink(),
                  
                  // 💬 · ❤️ · 👁 (항상 하단)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(AppIcons.chatOutlined, size: 10, color: colorScheme.outlineVariant),
                      const SizedBox(width: 2),
                      Text('${post.commentCount}', style: AppTextStyles.captionSmall(context).copyWith(color: colorScheme.outlineVariant)),
                      _dot(context, colorScheme),
                      Icon(AppIcons.likeOutlined, size: 10, color: colorScheme.outlineVariant),
                      const SizedBox(width: 2),
                      Text('${post.likeCount}', style: AppTextStyles.captionSmall(context).copyWith(color: colorScheme.outlineVariant)),
                      _dot(context, colorScheme),
                      Icon(AppIcons.visibility, size: 10, color: colorScheme.outlineVariant),
                      const SizedBox(width: 2),
                      Text('${post.viewCount}', style: AppTextStyles.captionSmall(context).copyWith(color: colorScheme.outlineVariant)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dot(BuildContext context, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingXXS),
      child: Text('·', style: AppTextStyles.captionSmall(context).copyWith(color: colorScheme.outlineVariant)),
    );
  }

}
