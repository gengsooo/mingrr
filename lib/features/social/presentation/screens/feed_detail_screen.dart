import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/feature_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/mingrr_bottom_sheet.dart';
import '../../../../core/widgets/report_sheet.dart';
import '../../../../core/widgets/dialogs/dialogs.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../models/feed_model.dart';
import '../providers/feed_provider.dart';
import 'feed_write_screen.dart';

/// ============================================================
/// 커뮤니티 피드 상세 화면
/// 게시글 상세, 댓글, 좋아요
/// ============================================================

class FeedDetailScreen extends ConsumerStatefulWidget {
  final String postId;

  const FeedDetailScreen({super.key, required this.postId});

  @override
  ConsumerState<FeedDetailScreen> createState() => _FeedDetailScreenState();
}

class _FeedDetailScreenState extends ConsumerState<FeedDetailScreen> {
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
      ref.read(feedProviderNotifier.notifier).incrementViewCount(widget.postId);
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
    final postAsync = ref.watch(feedPostDetailProvider(widget.postId));
    final commentsAsync = ref.watch(feedCommentsProvider(widget.postId));
    final isLikedAsync = ref.watch(isPostLikedProvider(widget.postId));
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = context.features.community;

    return Scaffold(
      backgroundColor: context.detailBackground,
      appBar: AppBar(
        title: const Text('게시글'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showMoreOptions(context, postAsync.valueOrNull),
          ),
        ],
      ),
      body: postAsync.when(
        data: (post) {
          if (post == null) {
            return const Center(child: Text('게시글을 찾을 수 없습니다'));
          }

          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  color: accentColor,
                  onRefresh: () async {
                    ref.invalidate(feedPostDetailProvider(widget.postId));
                    ref.invalidate(feedCommentsProvider(widget.postId));
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
        loading: () => const MingrrLoadingState(),
        error: (e, _) => Center(child: Text('오류: $e')),
      ),
    );
  }

  Widget _buildPostContent(BuildContext context, FeedPostModel post, bool isLiked) {
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = context.features.community;

    return Container(
      color: colorScheme.surface,
      padding: const EdgeInsets.all(AppSizes.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 작성자 정보
          Row(
            children: [
              MingrrAvatar(
                size: 48,
                imageUrl: post.isAnonymous ? null : post.authorProfileUrl,
                placeholderIcon: Icons.person,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          post.displayAuthorName,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            post.category.label,
                            style: TextStyle(fontSize: 11, color: accentColor, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDateTime(post.createdAt),
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 본문
          Text(
            post.content,
            style: const TextStyle(fontSize: 15, height: 1.6),
          ),

          // 이미지
          if (post.hasImages) ...[
            const SizedBox(height: 16),
            _buildImages(context, post.imageUrls),
          ],

          // 태그
          if (post.tags.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: post.tags.map((tag) => Text(
                '#$tag',
                style: TextStyle(fontSize: 14, color: accentColor),
              )).toList(),
            ),
          ],

          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),

          // 액션 바
          Row(
            children: [
              // 좋아요
              _buildActionButton(
                icon: isLiked ? Icons.favorite : Icons.favorite_border,
                label: '좋아요 ${post.likeCount}',
                color: isLiked ? Colors.red : colorScheme.onSurfaceVariant,
                onTap: () async {
                  await ref.read(feedProviderNotifier.notifier).toggleLike(post.id);
                  ref.invalidate(feedPostDetailProvider(widget.postId));
                  ref.invalidate(isPostLikedProvider(widget.postId));
                },
              ),
              const SizedBox(width: 24),
              // 댓글
              _buildActionButton(
                icon: Icons.chat_bubble_outline,
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
                icon: Icon(Icons.share_outlined, color: colorScheme.onSurfaceVariant),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImages(BuildContext context, List<String> imageUrls) {
    if (imageUrls.length == 1) {
      return GestureDetector(
        onTap: () => _showImageViewer(context, imageUrls, 0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            imageUrls.first,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              height: 200,
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              child: const Center(child: Icon(Icons.image_not_supported)),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _showImageViewer(context, imageUrls, index),
            child: Padding(
              padding: EdgeInsets.only(right: index < imageUrls.length - 1 ? 8 : 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrls[index],
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 200,
                    height: 200,
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    child: const Center(child: Icon(Icons.image_not_supported)),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showImageViewer(BuildContext context, List<String> imageUrls, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _ImageViewerScreen(
          imageUrls: imageUrls,
          initialIndex: initialIndex,
        ),
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
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 14, color: color)),
        ],
      ),
    );
  }

  Widget _buildCommentsSection(
    BuildContext context,
    AsyncValue<List<FeedCommentModel>> commentsAsync,
    FeedPostModel post,
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
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          
          commentsAsync.when(
            data: (comments) {
              if (comments.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 40, color: colorScheme.outlineVariant),
                        const SizedBox(height: 8),
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
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('댓글을 불러올 수 없습니다')),
          ),
          
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildCommentItem(
    BuildContext context,
    FeedCommentModel comment,
    List<FeedCommentModel> replies,
    FeedPostModel post,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = context.features.community;
    final isMyComment = FirebaseService().currentUserId == comment.authorId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 댓글
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MingrrAvatar(
                size: 36,
                imageUrl: comment.isAnonymous ? null : comment.authorProfileUrl,
                placeholderIcon: Icons.person,
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
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        if (comment.authorId == post.authorId) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '작성자',
                              style: TextStyle(fontSize: 10, color: accentColor),
                            ),
                          ),
                        ],
                        const Spacer(),
                        Text(
                          _formatTimeAgo(comment.createdAt),
                          style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      comment.content,
                      style: const TextStyle(fontSize: 14, height: 1.4),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => _setReplyTo(comment),
                          child: Text(
                            '답글',
                            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                          ),
                        ),
                        if (isMyComment) ...[
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: () => _deleteComment(comment, post.id),
                            child: Text(
                              '삭제',
                              style: TextStyle(fontSize: 12, color: colorScheme.error),
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
            padding: const EdgeInsets.only(left: 46),
            child: Column(
              children: replies.map((reply) => _buildReplyItem(context, reply, post)).toList(),
            ),
          ),
        
        Divider(color: colorScheme.outline.withOpacity(0.2)),
      ],
    );
  }

  Widget _buildReplyItem(BuildContext context, FeedCommentModel reply, FeedPostModel post) {
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = context.features.community;
    final isMyComment = FirebaseService().currentUserId == reply.authorId;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MingrrAvatar(
            size: 28,
            imageUrl: reply.isAnonymous ? null : reply.authorProfileUrl,
            placeholderIcon: Icons.person,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      reply.displayAuthorName,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    if (reply.authorId == post.authorId) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          '작성자',
                          style: TextStyle(fontSize: 9, color: accentColor),
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      _formatTimeAgo(reply.createdAt),
                      style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  reply.content,
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
                if (isMyComment) ...[
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () => _deleteComment(reply, post.id),
                    child: Text(
                      '삭제',
                      style: TextStyle(fontSize: 11, color: colorScheme.error),
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
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outline.withOpacity(0.2))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 답글 대상 표시
          if (_replyToCommentId != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(
                    '$_replyToAuthorName님에게 답글',
                    style: TextStyle(fontSize: 12, color: accentColor),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _cancelReply,
                    child: Icon(Icons.close, size: 16, color: accentColor),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          
          Row(
            children: [
              // 익명 토글
              GestureDetector(
                onTap: () => setState(() => _isAnonymousComment = !_isAnonymousComment),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _isAnonymousComment ? accentColor.withOpacity(0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _isAnonymousComment ? accentColor : colorScheme.outline.withOpacity(0.3),
                    ),
                  ),
                  child: Icon(
                    Icons.person_off_outlined,
                    size: 20,
                    color: _isAnonymousComment ? accentColor : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // 입력 필드
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: _isAnonymousComment ? '익명으로 댓글 작성...' : '댓글을 입력하세요...',
                      hintStyle: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    maxLines: null,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // 전송 버튼
              GestureDetector(
                onTap: _submitComment,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.send, size: 20, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _setReplyTo(FeedCommentModel comment) {
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

    final commentId = await ref.read(feedProviderNotifier.notifier).createComment(
      postId: widget.postId,
      content: content,
      parentId: _replyToCommentId,
      isAnonymous: _isAnonymousComment,
    );

    if (commentId != null) {
      _commentController.clear();
      _cancelReply();
      ref.invalidate(feedCommentsProvider(widget.postId));
      ref.invalidate(feedPostDetailProvider(widget.postId));
    }
  }

  Future<void> _deleteComment(FeedCommentModel comment, String postId) async {
    final confirmed = await showConfirmSheetWithResult(
      context,
      type: ConfirmSheetType.generalDelete,
      title: '댓글 삭제',
      message: '이 댓글을 삭제하시겠습니까?',
    );

    if (confirmed == true) {
      final success = await ref.read(feedProviderNotifier.notifier).deleteComment(comment.id, postId);
      if (success) {
        ref.invalidate(feedCommentsProvider(widget.postId));
        ref.invalidate(feedPostDetailProvider(widget.postId));
        if (mounted) {
          MingrrSnackBar.success(context, '댓글이 삭제되었습니다');
        }
      }
    }
  }

  void _showMoreOptions(BuildContext context, FeedPostModel? post) {
    if (post == null) return;
    
    final isMyPost = FirebaseService().currentUserId == post.authorId;

    showMingrrOptionsSheet(
      context: context,
      options: [
        if (isMyPost) ...[
          MingrrOptionItem(
            icon: Icons.edit_outlined,
            label: '수정하기',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => FeedWriteScreen(post: post)),
              ).then((result) {
                if (result == true) {
                  ref.invalidate(feedPostDetailProvider(widget.postId));
                }
              });
            },
          ),
          MingrrOptionItem(
            icon: Icons.delete_outline,
            label: '삭제하기',
            isDestructive: true,
            onTap: () => _deletePost(post),
          ),
        ] else ...[
          MingrrOptionItem(
            icon: Icons.report_outlined,
            label: '신고하기',
            isDestructive: true,
            onTap: () {
              showReportSheet(
                context,
                targetId: post.id,
                targetName: '이 게시글',
                targetType: ReportTargetType.feed,
              );
            },
          ),
        ],
      ],
    );
  }

  Future<void> _deletePost(FeedPostModel post) async {
    final confirmed = await showConfirmSheetWithResult(
      context,
      type: ConfirmSheetType.generalDelete,
      title: '게시글 삭제',
      message: '이 게시글을 삭제하시겠습니까?\n삭제된 게시글은 복구할 수 없습니다.',
    );

    if (confirmed == true) {
      final success = await ref.read(feedProviderNotifier.notifier).deletePost(post.id);
      if (success && mounted) {
        Navigator.pop(context);
        MingrrSnackBar.success(context, '게시글이 삭제되었습니다');
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}.${dateTime.month}.${dateTime.day} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
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

/// 이미지 뷰어 화면
class _ImageViewerScreen extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const _ImageViewerScreen({
    required this.imageUrls,
    required this.initialIndex,
  });

  @override
  State<_ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<_ImageViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${_currentIndex + 1} / ${widget.imageUrls.length}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.imageUrls.length,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemBuilder: (context, index) {
          return InteractiveViewer(
            child: Center(
              child: Image.network(
                widget.imageUrls[index],
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.image_not_supported,
                  color: Colors.white54,
                  size: 64,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
