import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/theme/feature_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/mingrr_image.dart';
import '../../../../core/widgets/loading/loading_widgets.dart';
import '../../../../core/widgets/sheets/mingrr_bottom_sheet.dart';
import '../../../../core/widgets/sheets/report_sheet.dart';
import '../../../../core/widgets/dialogs/dialogs.dart';
import '../../../../core/widgets/badges/info_badge.dart';
import '../../../../core/widgets/modals/guardian_profile_modal.dart';
import '../../../../core/widgets/refresh_wrapper.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/share_service.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../models/community_post_model.dart';
import '../../../../core/providers/refresh_notifier.dart';
import '../providers/community_provider.dart';
import '../../../../core/utils/responsive_utils.dart';
import 'community_write_screen.dart';

/// ============================================================
/// 커뮤니티(Community) 게시글 상세 화면
/// 
/// 소셜 > 커뮤니티 > 게시글 상세
/// 게시글 본문, 댓글, 좋아요 기능
/// ============================================================

class CommunityDetailScreen extends ConsumerStatefulWidget {
  final String postId;

  const CommunityDetailScreen({super.key, required this.postId});

  @override
  ConsumerState<CommunityDetailScreen> createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends ConsumerState<CommunityDetailScreen> {
  final _commentController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isAnonymousComment = false;
  String? _replyToCommentId;
  String? _replyToAuthorName;

  @override
  void initState() {
    super.initState();
    // 조회수 증가
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(communityNotifierProvider.notifier).incrementViewCount(widget.postId);
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final postAsync = ref.watch(communityPostDetailProvider(widget.postId));
    final commentsAsync = ref.watch(communityCommentsProvider(widget.postId));
    final isLikedAsync = ref.watch(isCommunityPostLikedProvider(widget.postId));
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = context.features.social;

    return Scaffold(
      backgroundColor: context.detailBackground,
      appBar: MingrrAppBar(
        title: '게시글',
        actions: [
          IconButton(
            icon: const Icon(AppIcons.moreVert),
            onPressed: () => _showMoreOptions(context, postAsync.valueOrNull),
          ),
        ],
      ),
      body: postAsync.when(
        data: (post) {
          if (post == null) {
            return const MingrrEmptyState(
              icon: AppIcons.communityOutlined,
              title: '아직 데이터가 없어요',
              subtitle: '게시글을 찾을 수 없습니다',
            );
          }

          return Column(
            children: [
              Expanded(
                child: MingrrRefreshWrapper(
                  color: accentColor,
                  onRefresh: () async {
                    ref.invalidate(communityPostDetailProvider(widget.postId));
                    ref.invalidate(communityCommentsProvider(widget.postId));
                  },
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 게시글 본문
                        _buildPostContent(context, post, isLikedAsync.valueOrNull ?? false),
                        
                        // 구분선
                        Container(
                          height: 8,
                          color: colorScheme.surfaceContainerLow,
                        ),
                        
                        // 댓글 섹션
                        _buildCommentsSection(context, commentsAsync, post),
                      ],
                    ),
                  ),
                ),
              ),
              
              // 댓글 입력
              _buildCommentInput(context, accentColor),
            ],
          );
        },
        loading: () => MingrrLoadingState(
          type: MingrrLoadingType.community,
          message: '게시글을 불러오고 있어요',
          timeout: AppSizes.loadingTimeout,
          onRetry: () => ref.invalidate(communityPostDetailProvider(widget.postId)),
        ),
        error: (_, __) => MingrrErrorState(
          onRetry: () => ref.invalidate(communityPostDetailProvider(widget.postId)),
        ),
      ),
    );
  }

  Widget _buildPostContent(BuildContext context, CommunityPostModel post, bool isLiked) {
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = context.features.social;

    return Container(
      color: colorScheme.surface,
      padding: const EdgeInsets.all(AppSizes.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 작성자 정보
          GestureDetector(
            onTap: post.isAnonymous ? null : () => _showAuthorProfile(context, post),
            child: Row(
              children: [
                MingrrImage.avatar(
                  size: 48,
                  imageUrl: post.isAnonymous ? null : post.authorProfileUrl,
                  icon: AppIcons.profile,
                ),
                const SizedBox(width: AppSizes.gapM),
                Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          post.displayAuthorName,
                          style: AppTextStyles.titleMedium(context),
                        ),
                        const SizedBox(width: AppSizes.gapS),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingS, vertical: 3),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: AppOpacity.o10),
                            borderRadius: BorderRadius.circular(AppSizes.radiusXXS),
                          ),
                          child: Text(
                            post.category.label,
                            style: AppTextStyles.labelMedium(context).copyWith(color: accentColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.gapXS),
                    Text(
                      formatDateTime(post.createdAt),
                      style: AppTextStyles.caption(context),
                    ),
                  ],
                ),
              ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.gapLL),

          // 제목
          if (post.title.isNotEmpty) ...[
            Text(
              post.title,
              style: AppTextStyles.headlineSmall(context).copyWith(height: 1.4),
            ),
            const SizedBox(height: AppSizes.gapM),
          ],

          // 본문
          Text(
            post.content,
            style: AppTextStyles.bodyLarge(context).copyWith(height: 1.6),
          ),

          // 동영상
          if (post.hasVideo) ...[
            const SizedBox(height: AppSizes.gapL),
            _buildVideoPlayer(context, post.videoUrl!, post.videoThumbnailUrl),
          ],

          // 이미지
          if (post.hasImages) ...[
            const SizedBox(height: AppSizes.gapL),
            MingrrImageGallery(
              imageUrls: post.imageUrls,
              height: 200,
              enableViewer: true,
            ),
          ],

          // 태그
          if (post.tags.isNotEmpty) ...[
            const SizedBox(height: AppSizes.gapL),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: post.tags.map((tag) => Text(
                '#$tag',
                style: AppTextStyles.bodyMedium(context).copyWith(color: accentColor),
              )).toList(),
            ),
          ],

          const SizedBox(height: AppSizes.gapLL),
          const MingrrDivider(),
          const SizedBox(height: AppSizes.gapM),

          // 액션 바
          Row(
            children: [
              // 좋아요 (공통 컴포넌트)
              LikeButton(
                count: post.likeCount,
                isLiked: isLiked,
                onTap: () async {
                  await ref.read(communityNotifierProvider.notifier).toggleLike(post.id);
                  ref.invalidate(communityPostDetailProvider(widget.postId));
                  ref.invalidate(isCommunityPostLikedProvider(widget.postId));
                },
                size: InfoBadgeSize.medium,
              ),
              const SizedBox(width: 24),
              // 댓글
              _buildActionButton(
                icon: AppIcons.chatOutlined,
                label: '댓글 ${post.commentCount}',
                color: colorScheme.onSurfaceVariant,
                onTap: () {
                  _scrollController.animateTo(
                    _scrollController.position.maxScrollExtent,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                },
              ),
              const Spacer(),
              // 공유
              IconButton(
                icon: Icon(AppIcons.share, color: colorScheme.onSurfaceVariant),
                onPressed: () => ShareService.sharePost(context, post),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer(BuildContext context, String videoUrl, String? thumbnailUrl) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return GestureDetector(
      onTap: () => _playVideo(context, videoUrl),
      child: Container(
        width: double.infinity,
        height: 220,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppSizes.radiusS),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 썸네일
            MingrrImage.background(
              imageUrl: thumbnailUrl,
              radius: AppSizes.radiusS,
              placeholder: _buildVideoPlaceholder(colorScheme),
            ),
            // 재생 버튼 오버레이
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: AppOpacity.o50),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  AppIcons.play,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
            // 동영상 표시
            Positioned(
              left: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingS, vertical: AppSizes.paddingXS),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: AppOpacity.o70),
                  borderRadius: BorderRadius.circular(AppSizes.radiusXXS),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(AppIcons.video, color: Colors.white, size: 16),
                    const SizedBox(width: AppSizes.gapXS),
                    Text(
                      '동영상',
                      style: AppTextStyles.caption(context).copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlaceholder(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSizes.radiusS),
      ),
      child: Center(
        child: Icon(
          AppIcons.video,
          size: 48,
          color: colorScheme.outlineVariant,
        ),
      ),
    );
  }

  void _playVideo(BuildContext context, String videoUrl) {
    // 외부 앱으로 동영상 재생 (추후 인앱 플레이어로 변경 가능)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _VideoPlayerScreen(videoUrl: videoUrl),
      ),
    );
  }


  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(width: AppSizes.gapSM),
          Text(label, style: AppTextStyles.bodyMedium(context).copyWith(color: color)),
        ],
      ),
    );
  }

  Widget _buildCommentsSection(
    BuildContext context,
    AsyncValue<List<CommunityCommentModel>> commentsAsync,
    CommunityPostModel post,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: colorScheme.surface,
      padding: const EdgeInsets.all(AppSizes.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '댓글 ${post.commentCount}',
            style: AppTextStyles.headlineSmall(context),
          ),
          const SizedBox(height: AppSizes.gapL),
          
          commentsAsync.when(
            data: (comments) {
              if (comments.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingXL),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(AppIcons.chatOutlined, size: 40, color: colorScheme.outlineVariant),
                        const SizedBox(height: AppSizes.gapS),
                        Text(
                          '첫 번째 댓글을 남겨보세요!',
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // 댓글과 대댓글 구조화
              final parentComments = comments.where((c) => c.parentId == null).toList();
              
              return Column(
                children: parentComments.map((comment) {
                  final replies = comments.where((c) => c.parentId == comment.id).toList();
                  return _buildCommentItem(context, comment, replies, post);
                }).toList(),
              );
            },
            loading: () => const Center(child: MingrrLoadingIndicator()),
            error: (_, __) => MingrrErrorState(
              onRetry: () => ref.invalidate(communityCommentsProvider(widget.postId)),
            ),
          ),
          
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildCommentItem(
    BuildContext context,
    CommunityCommentModel comment,
    List<CommunityCommentModel> replies,
    CommunityPostModel post,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = context.features.social;
    final isMyComment = FirebaseService().currentUserId == comment.authorId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 댓글
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingM),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: comment.isAnonymous ? null : () => _showCommentAuthorProfile(context, comment),
                child: MingrrImage.avatar(
                  size: 36,
                  imageUrl: comment.isAnonymous ? null : comment.authorProfileUrl,
                  icon: AppIcons.profile,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          comment.displayAuthorName,
                          style: AppTextStyles.titleSmall(context),
                        ),
                        if (comment.authorId == post.authorId) ...[
                          const SizedBox(width: AppSizes.gapSM),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: AppSizes.paddingXXS),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: AppOpacity.o10),
                              borderRadius: BorderRadius.circular(AppSizes.radiusXXS),
                            ),
                            child: Text(
                              '작성자',
                              style: AppTextStyles.captionSmall(context).copyWith(color: accentColor),
                            ),
                          ),
                        ],
                        const Spacer(),
                        Text(
                          formatRelativeTime(comment.createdAt),
                          style: AppTextStyles.captionSmall(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.gapSM),
                    Text(
                      comment.content,
                      style: AppTextStyles.bodyMedium(context).copyWith(height: 1.4),
                    ),
                    const SizedBox(height: AppSizes.gapS),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => _setReplyTo(comment),
                          child: Text(
                            '답글',
                            style: AppTextStyles.caption(context),
                          ),
                        ),
                        if (isMyComment) ...[
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: () => _deleteComment(comment, post.id),
                            child: Text(
                              '삭제',
                              style: AppTextStyles.caption(context).copyWith(color: colorScheme.error),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // 대댓글
        if (replies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: AppSizes.paddingXXL),
            child: Column(
              children: replies.map((reply) => _buildReplyItem(context, reply, post)).toList(),
            ),
          ),
        
        Divider(color: colorScheme.outline.withValues(alpha: AppOpacity.o20)),
      ],
    );
  }

  Widget _buildReplyItem(BuildContext context, CommunityCommentModel reply, CommunityPostModel post) {
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = context.features.social;
    final isMyComment = FirebaseService().currentUserId == reply.authorId;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: reply.isAnonymous ? null : () => _showCommentAuthorProfile(context, reply),
            child: MingrrImage.avatar(
              size: 28,
              imageUrl: reply.isAnonymous ? null : reply.authorProfileUrl,
              icon: AppIcons.profile,
            ),
          ),
          const SizedBox(width: AppSizes.gapS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      reply.displayAuthorName,
                      style: AppTextStyles.labelMedium(context),
                    ),
                    if (reply.authorId == post.authorId) ...[
                      const SizedBox(width: AppSizes.gapXS),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingXS, vertical: AppSizes.paddingXXS),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: AppOpacity.o10),
                          borderRadius: BorderRadius.circular(AppSizes.radiusXXS),
                        ),
                        child: Text(
                          '작성자',
                          style: AppTextStyles.captionSmall(context).copyWith(color: accentColor),
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      formatRelativeTime(reply.createdAt),
                      style: AppTextStyles.caption(context),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.gapXS),
                Text(
                  reply.content,
                  style: AppTextStyles.bodySmall(context).copyWith(height: 1.4),
                ),
                if (isMyComment) ...[
                  const SizedBox(height: AppSizes.gapSM),
                  GestureDetector(
                    onTap: () => _deleteComment(reply, post.id),
                    child: Text(
                      '삭제',
                      style: AppTextStyles.captionSmall(context).copyWith(color: colorScheme.error),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput(BuildContext context, Color accentColor) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.fromLTRB(AppSizes.paddingL, AppSizes.paddingM, AppSizes.paddingL, ResponsiveUtils.bottomPaddingWith(context, AppSizes.paddingM)),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outline.withValues(alpha: AppOpacity.o20))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 답글 대상 표시
          if (_replyToCommentId != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM, vertical: AppSizes.paddingS),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: AppOpacity.o10),
                borderRadius: BorderRadius.circular(AppSizes.radiusXS),
              ),
              child: Row(
                children: [
                  Text(
                    '$_replyToAuthorName님에게 답글',
                    style: AppTextStyles.caption(context).copyWith(color: accentColor),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _cancelReply,
                    child: Icon(AppIcons.close, size: 16, color: accentColor),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.gapS),
          ],
          
          Row(
            children: [
              // 익명 토글
              GestureDetector(
                onTap: () => setState(() => _isAnonymousComment = !_isAnonymousComment),
                child: Container(
                  padding: const EdgeInsets.all(AppSizes.paddingS),
                  decoration: BoxDecoration(
                    color: _isAnonymousComment ? accentColor.withValues(alpha: AppOpacity.o10) : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppSizes.radiusXS),
                    border: Border.all(
                      color: _isAnonymousComment ? accentColor : colorScheme.outline.withValues(alpha: AppOpacity.o30),
                    ),
                  ),
                  child: Icon(
                    AppIcons.profileOutlined,
                    size: 20,
                    color: _isAnonymousComment ? accentColor : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.gapM),
              
              // 입력 필드
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppSizes.radiusXL),
                  ),
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: _isAnonymousComment ? '익명으로 댓글 작성...' : '댓글을 입력하세요...',
                      hintStyle: AppTextStyles.bodyMedium(context).copyWith(color: colorScheme.onSurfaceVariant),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL, vertical: AppSizes.paddingS),
                    ),
                    maxLines: null,
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.gapM),
              
              // 전송 버튼
              GestureDetector(
                onTap: _submitComment,
                child: Container(
                  padding: const EdgeInsets.all(AppSizes.paddingS),
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(AppIcons.send, size: 20, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _setReplyTo(CommunityCommentModel comment) {
    setState(() {
      _replyToCommentId = comment.id;
      _replyToAuthorName = comment.displayAuthorName;
    });
  }

  void _cancelReply() {
    setState(() {
      _replyToCommentId = null;
      _replyToAuthorName = null;
    });
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    final commentId = await ref.read(communityNotifierProvider.notifier).createComment(
      postId: widget.postId,
      content: content,
      parentId: _replyToCommentId,
      isAnonymous: _isAnonymousComment,
    );

    if (commentId != null) {
      _commentController.clear();
      _cancelReply();
      ref.invalidate(communityCommentsProvider(widget.postId));
      ref.invalidate(communityPostDetailProvider(widget.postId));
    }
  }

  Future<void> _deleteComment(CommunityCommentModel comment, String postId) async {
    final confirmed = await showConfirmSheetWithResult(
      context,
      type: ConfirmSheetType.generalDelete,
      title: '댓글 삭제',
      message: '이 댓글을 삭제하시겠습니까?',
    );

    if (confirmed == true) {
      final success = await ref.read(communityNotifierProvider.notifier).deleteComment(comment.id, postId);
      if (success) {
        ref.invalidate(communityCommentsProvider(widget.postId));
        ref.invalidate(communityPostDetailProvider(widget.postId));
        if (mounted) {
          MingrrSnackBar.success(context, '댓글이 삭제되었습니다');
        }
      }
    }
  }

  void _showMoreOptions(BuildContext context, CommunityPostModel? post) {
    if (post == null) return;
    
    final isMyPost = FirebaseService().currentUserId == post.authorId;

    showDetailOptionsSheet(
      context: context,
      isOwner: isMyPost,
      onEdit: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CommunityWriteScreen(post: post)),
        ).then((result) {
          if (result == true) {
            ref.invalidate(communityPostDetailProvider(widget.postId));
          }
        });
      },
      onDelete: () => _deletePost(post),
      onReport: () {
        showReportSheet(
          context,
          targetId: post.id,
          targetName: '이 게시글',
          targetType: ReportTargetType.feed,
        );
      },
    );
  }

  Future<void> _deletePost(CommunityPostModel post) async {
    final confirmed = await showConfirmSheetWithResult(
      context,
      type: ConfirmSheetType.generalDelete,
      title: '게시글 삭제',
      message: '이 게시글을 삭제하시겠습니까?\n삭제된 게시글은 복구할 수 없습니다.',
    );

    if (confirmed == true) {
      final success = await ref.read(communityNotifierProvider.notifier).deletePost(post.id);
      if (success && mounted) {
        // 리스트 새로고침 트리거
        ref.read(communityRefreshProvider.notifier).state++;
        Navigator.pop(context);
        MingrrSnackBar.success(context, '게시글이 삭제되었습니다');
      }
    }
  }

  /// 게시글 작성자 프로필 바텀시트 표시
  Future<void> _showAuthorProfile(BuildContext context, CommunityPostModel post) async {
    await _showUserProfile(context, post.authorId, post.authorName, post.authorProfileUrl);
  }

  /// 댓글 작성자 프로필 바텀시트 표시
  Future<void> _showCommentAuthorProfile(BuildContext context, CommunityCommentModel comment) async {
    await _showUserProfile(context, comment.authorId, comment.authorName, comment.authorProfileUrl);
  }

  /// 사용자 프로필 바텀시트 표시 (공통)
  Future<void> _showUserProfile(BuildContext context, String userId, String userName, String? profileUrl) async {
    try {
      final userDoc = await FirebaseService().usersCollection.doc(userId).get();
      final userData = userDoc.data();
      
      final kkosunnaeScore = (userData?['kkosunnaeScore'] as num?)?.toDouble() ?? 50.0;
      final isIdentityVerified = userData?['isIdentityVerified'] as bool? ?? false;
      final isPetVerified = userData?['isPetVerified'] as bool? ?? false;
      final isLocationVerified = userData?['isLocationVerified'] as bool? ?? false;
      final genderStr = userData?['gender'] as String?;
      final age = userData?['age'] as int?;
      
      GuardianGender gender = GuardianGender.unknown;
      if (genderStr == 'male') gender = GuardianGender.male;
      if (genderStr == 'female') gender = GuardianGender.female;
      
      // 반려동물 정보 조회
      List<GuardianPetInfo> pets = [];
      final petsSnapshot = await FirebaseService().petsCollection
          .where('ownerId', isEqualTo: userId)
          .get();
      
      for (final petDoc in petsSnapshot.docs) {
        final petData = petDoc.data();
        pets.add(GuardianPetInfo(
          id: petDoc.id,
          name: petData['name'] ?? '반려동물',
          breed: petData['breed'],
          ageString: petData['age'] != null ? '${petData['age']}살' : null,
          introduction: petData['introduction'],
          traits: List<String>.from(petData['traits'] ?? []),
          photoUrls: List<String>.from(petData['photoUrls'] ?? []),
          profileImageUrl: petData['profileImageUrl'],
          likeCount: petData['likeCount'] ?? 0,
        ));
      }
      
      if (!mounted) return;
      
      showGuardianProfileModal(
        context,
        guardianId: userId,
        guardianName: userName,
        kkosunnaeScore: kkosunnaeScore,
        profileImageUrl: profileUrl ?? userData?['profileImageUrl'],
        gender: gender,
        age: age,
        isIdentityVerified: isIdentityVerified,
        isPetVerified: isPetVerified,
        isLocationVerified: isLocationVerified,
        pets: pets,
      );
    } catch (e) {
      if (!mounted) return;
      showGuardianProfileModal(
        context,
        guardianId: userId,
        guardianName: userName,
        kkosunnaeScore: 50.0,
        profileImageUrl: profileUrl,
        pets: [],
      );
    }
  }

}


/// 동영상 플레이어 화면
class _VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;

  const _VideoPlayerScreen({required this.videoUrl});

  @override
  State<_VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<_VideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    try {
      await _controller.initialize();
      _controller.addListener(_videoListener);
      if (mounted) {
        setState(() => _isInitialized = true);
        _controller.play();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _hasError = true);
      }
    }
  }

  void _videoListener() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_videoListener);
    _controller.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: const MingrrAppBar.dark(
        title: '동영상',
      ),
      body: _hasError
          ? _buildErrorState()
          : _isInitialized
              ? _buildVideoPlayer()
              : _buildLoadingState(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: MingrrLoadingIndicator(customColor: Colors.white),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(AppIcons.error, color: Colors.white54, size: 64),
          const SizedBox(height: AppSizes.gapL),
          Text(
            '동영상을 재생할 수 없습니다',
            style: AppTextStyles.titleLarge(context).copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppSizes.gapXL),
          MingrrButton(
            text: '다시 시도',
            onPressed: () {
              setState(() => _hasError = false);
              _initializeVideo();
            },
            backgroundColor: Theme.of(context).colorScheme.primary,
            textColor: Colors.white,
            height: 44,
            width: 120,
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return GestureDetector(
      onTap: () => setState(() => _showControls = !_showControls),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 동영상
          Center(
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            ),
          ),
          // 컨트롤 오버레이
          if (_showControls) ...[
            // 재생/일시정지 버튼
            GestureDetector(
              onTap: () {
                if (_controller.value.isPlaying) {
                  _controller.pause();
                } else {
                  _controller.play();
                }
              },
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: AppOpacity.o50),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _controller.value.isPlaying ? AppIcons.play : AppIcons.play,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
            // 하단 프로그레스 바
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(AppSizes.paddingL),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: AppOpacity.o70)],
                  ),
                ),
                child: Column(
                  children: [
                    // 프로그레스 바
                    VideoProgressIndicator(
                      _controller,
                      allowScrubbing: true,
                      colors: const VideoProgressColors(
                        playedColor: Colors.white,
                        bufferedColor: Colors.white38,
                        backgroundColor: Colors.white24,
                      ),
                    ),
                    const SizedBox(height: AppSizes.gapS),
                    // 시간 표시
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(_controller.value.position),
                          style: AppTextStyles.caption(context).copyWith(color: Colors.white),
                        ),
                        Text(
                          _formatDuration(_controller.value.duration),
                          style: AppTextStyles.caption(context).copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
