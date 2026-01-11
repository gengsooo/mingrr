import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/services/chat_service.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/svg_icons.dart';
import '../../../../core/widgets/dialogs/dialogs.dart';
import '../../../../models/chat_model.dart';
import '../../../../models/community_model.dart';
import '../../../chat/presentation/screens/chat_detail_screen.dart';
import '../providers/community_provider.dart';

/// ============================================================
/// 소모임 상세 화면
/// 
/// 소모임 정보, 멤버 목록, 일정, 게시글 등을 표시
/// ============================================================

class GroupDetailScreen extends ConsumerStatefulWidget {
  final String groupId;

  const GroupDetailScreen({
    super.key,
    required this.groupId,
  });

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupAsync = ref.watch(groupByIdProvider(widget.groupId));

    return groupAsync.when(
      data: (group) {
        if (group == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('소모임')),
            body: const Center(child: Text('소모임을 찾을 수 없습니다')),
          );
        }
        return _buildContent(context, group);
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Scaffold(
        appBar: AppBar(title: const Text('소모임')),
        body: const Center(child: Text('데이터를 불러올 수 없습니다')),
      ),
    );
  }

  Widget _buildContent(BuildContext context, GroupModel group) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildAppBar(context, group),
          _buildGroupInfo(group),
          _buildTabBar(),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildFeedTab(group),
            _buildScheduleTab(group),
            _buildMembersTab(group),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomButton(context, group),
    );
  }

  Widget _buildAppBar(BuildContext context, GroupModel group) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppColors.community,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
        ),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/community');
          }
        },
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.share, color: Colors.white, size: 20),
          ),
          onPressed: () {
            MingrrSnackBar.info(context, '공유 기능 준비 중입니다');
          },
        ),
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.more_vert, color: Colors.white, size: 20),
          ),
          onPressed: () => _showMoreOptions(context),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (group.imageUrl != null)
              Image.network(
                group.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildDefaultImage(),
              )
            else
              _buildDefaultImage(),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.5),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultImage() {
    return Container(
      color: AppColors.community.withOpacity(0.3),
      child: const Center(
        child: Icon(Icons.groups, size: 80, color: AppColors.community),
      ),
    );
  }

  Widget _buildGroupInfo(GroupModel group) {
    return SliverToBoxAdapter(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(AppSizes.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.community.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    group.category,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.community,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (!group.isPublic)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.textHint.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock, size: 12, color: AppColors.textHint),
                        SizedBox(width: 2),
                        Text(
                          '비공개',
                          style: TextStyle(fontSize: 11, color: AppColors.textHint),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              group.name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  group.address ?? '위치 미정',
                  style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.people, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  '멤버 ${group.memberCount}명',
                  style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
                if (group.maxMembers > 0) ...[
                  Text(
                    ' / ${group.maxMembers}명',
                    style: const TextStyle(fontSize: 14, color: AppColors.textHint),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            Text(
              group.description,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppColors.textPrimary,
              ),
            ),
            if (group.tags.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: group.tags.map((tag) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '#$tag',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverTabBarDelegate(
        TabBar(
          controller: _tabController,
          labelColor: AppColors.community,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.community,
          tabs: const [
            Tab(text: '피드'),
            Tab(text: '일정'),
            Tab(text: '멤버'),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedTab(GroupModel group) {
    return ListView(
      padding: const EdgeInsets.all(AppSizes.paddingM),
      children: [
        MingrrEmptyState(
          svgAsset: SvgAssets.emptyList,
          title: '아직 게시글이 없습니다',
          subtitle: '첫 번째 게시글을 작성해보세요!',
        ),
      ],
    );
  }

  Widget _buildScheduleTab(GroupModel group) {
    return ListView(
      padding: const EdgeInsets.all(AppSizes.paddingM),
      children: [
        MingrrEmptyState(
          svgAsset: SvgAssets.emptySchedule,
          title: '예정된 일정이 없습니다',
          subtitle: '새로운 모임 일정을 만들어보세요!',
        ),
      ],
    );
  }

  Widget _buildMembersTab(GroupModel group) {
    return ListView(
      padding: const EdgeInsets.all(AppSizes.paddingM),
      children: [
        MingrrCard(
          margin: const EdgeInsets.only(bottom: AppSizes.gapM),
          child: ListTile(
            leading: const MingrrAvatar(size: 48, placeholderIcon: Icons.person),
            title: const Text('모임장', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('멤버 ${group.memberCount}명 관리 중'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.community.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '모임장',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.community,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        MingrrEmptyState(
          svgAsset: SvgAssets.emptyGroup,
          title: '다른 멤버가 없습니다',
          subtitle: '친구를 초대해보세요!',
        ),
      ],
    );
  }


  Widget _buildBottomButton(BuildContext context, GroupModel group) {
    // TODO: 실제 가입 여부 확인 로직 필요
    final isJoined = false; // 임시

    return Container(
      padding: EdgeInsets.only(
        left: AppSizes.paddingL,
        right: AppSizes.paddingL,
        top: AppSizes.paddingM,
        bottom: MediaQuery.of(context).padding.bottom + AppSizes.paddingM,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 채팅 버튼 (가입한 경우에만)
          if (isJoined) ...[
            SizedBox(
              height: 56,
              width: 56,
              child: OutlinedButton(
                onPressed: () => _openGroupChat(context, group),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.community),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: EdgeInsets.zero,
                ),
                child: const Icon(Icons.chat_bubble_outline, color: AppColors.community),
              ),
            ),
            const SizedBox(width: 12),
          ],
          // 가입/채팅 버튼
          Expanded(
            child: SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: isJoined
                    ? () => _openGroupChat(context, group)
                    : () => _showJoinConfirmation(context, group),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.community,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  isJoined ? '채팅하기' : '모임 가입하기',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 소모임 채팅 열기
  Future<void> _openGroupChat(BuildContext context, GroupModel group) async {
    final firebaseService = FirebaseService();
    final chatService = ChatService();
    final myUserId = firebaseService.currentUserId;
    
    if (myUserId == null) {
      MingrrSnackBar.warning(context, '로그인이 필요합니다');
      return;
    }

    try {
      // 내 정보 가져오기
      final myUserDoc = await firebaseService.usersCollection.doc(myUserId).get();
      final myUserData = myUserDoc.data();

      final myInfo = ChatParticipant(
        id: myUserId,
        nickname: myUserData?['nickname'] ?? '사용자',
        profileImageUrl: myUserData?['profileImageUrl'],
      );

      // 소모임 채팅방은 그룹 ID를 relatedId로 사용
      // 소모임 대표와의 1:1 채팅으로 구현 (그룹 채팅은 별도 구현 필요)
      final creatorDoc = await firebaseService.usersCollection.doc(group.creatorId).get();
      final creatorData = creatorDoc.data();
      
      final leaderInfo = ChatParticipant(
        id: group.creatorId,
        nickname: creatorData?['nickname'] ?? '모임장',
        profileImageUrl: creatorData?['profileImageUrl'],
      );

      final chatRoom = await chatService.getOrCreateChatRoom(
        myUserId: myUserId,
        otherUserId: group.creatorId,
        type: 'community',
        myInfo: myInfo,
        otherInfo: leaderInfo,
        relatedId: group.id,
      );

      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatDetailScreen(
              chatRoomId: chatRoom.id,
              otherUserName: group.name,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        MingrrSnackBar.error(context, '채팅 시작 실패: $e');
      }
    }
  }

  void _showJoinConfirmation(BuildContext context, GroupModel group) {
    showConfirmSheet(
      context,
      type: ConfirmSheetType.groupJoin,
      title: group.name,
      message: group.requireApproval
          ? '이 모임은 가입 승인이 필요합니다.\n가입 신청을 보내시겠습니까?'
          : '이 모임에 가입하시겠습니까?',
      confirmText: group.requireApproval ? '신청하기' : '가입하기',
      onConfirm: () {
        MingrrSnackBar.success(
          context,
          group.requireApproval
              ? '가입 신청을 보냈습니다! 승인을 기다려주세요.'
              : '모임에 가입했습니다! 🎉',
        );
      },
    );
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('알림 설정'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.report_outlined, color: AppColors.error),
              title: const Text('신고하기', style: TextStyle(color: AppColors.error)),
              onTap: () => Navigator.pop(context),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
