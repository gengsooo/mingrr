import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/feature_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/services/chat_service.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/mingrr_bottom_sheet.dart';
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
  bool _isJoining = false;

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
      backgroundColor: context.detailBackground,
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
      backgroundColor: context.features.community,
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
      color: context.features.community.withOpacity(0.3),
      child: Center(
        child: Icon(Icons.groups, size: 80, color: context.features.community),
      ),
    );
  }

  Widget _buildGroupInfo(GroupModel group) {
    return SliverToBoxAdapter(
      child: Container(
        color: Theme.of(context).colorScheme.surface,
        padding: const EdgeInsets.all(AppSizes.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: context.features.community.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    group.category,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.features.community,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // 반려동물 동반 배지
                if (group.isPetAccompanied)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: context.features.dating.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.pets, size: 12, color: context.features.dating),
                        const SizedBox(width: 2),
                        Text(
                          '반려동물 동반',
                          style: TextStyle(fontSize: 11, color: context.features.dating, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                if (!group.isPublic) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock, size: 12, color: Theme.of(context).colorScheme.outlineVariant),
                        const SizedBox(width: 2),
                        Text(
                          '비공개',
                          style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.outlineVariant),
                        ),
                      ],
                    ),
                  ),
                ],
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
                Icon(Icons.location_on, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  group.address ?? '위치 미정',
                  style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.people, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  '멤버 ${group.memberCount}명',
                  style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                if (group.maxMembers > 0) ...[
                  Text(
                    ' / ${group.maxMembers}명',
                    style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.outlineVariant),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.sectionBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                group.description,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
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
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '#$tag',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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
          labelColor: context.features.community,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
          indicatorColor: context.features.community,
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
    return FutureBuilder<List<_MemberWithPets>>(
      future: _loadMembersWithPets(group),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final members = snapshot.data ?? [];
        
        return ListView(
          padding: const EdgeInsets.all(AppSizes.paddingM),
          children: [
            // 멤버 목록
            if (members.isEmpty)
              MingrrEmptyState(
                svgAsset: SvgAssets.emptyGroup,
                title: '멤버가 없습니다',
                subtitle: '친구를 초대해보세요!',
              )
            else
              ...members.map((member) => _buildMemberItem(context, member, group)),
          ],
        );
      },
    );
  }

  /// 멤버 + 반려동물 정보 로드
  Future<List<_MemberWithPets>> _loadMembersWithPets(GroupModel group) async {
    final firebaseService = FirebaseService();
    final List<_MemberWithPets> result = [];
    
    for (final memberId in group.memberIds.take(20)) {
      try {
        // 사용자 정보
        final userDoc = await firebaseService.firestore
            .collection('users')
            .doc(memberId)
            .get();
        
        if (!userDoc.exists) continue;
        final userData = userDoc.data()!;
        
        // 반려동물 정보
        List<String> petNames = [];
        if (group.isPetAccompanied) {
          final petsSnapshot = await firebaseService.firestore
              .collection('pets')
              .where('ownerId', isEqualTo: memberId)
              .limit(3)
              .get();
          
          petNames = petsSnapshot.docs
              .map((doc) => doc.data()['name'] as String? ?? '반려동물')
              .toList();
        }
        
        result.add(_MemberWithPets(
          id: memberId,
          nickname: userData['nickname'] ?? '사용자',
          profileImageUrl: userData['profileImageUrl'],
          isCreator: memberId == group.creatorId,
          isAdmin: group.adminIds.contains(memberId),
          petNames: petNames,
        ));
      } catch (e) {
        // 에러 무시
      }
    }
    
    // 모임장을 맨 위로
    result.sort((a, b) {
      if (a.isCreator) return -1;
      if (b.isCreator) return 1;
      if (a.isAdmin) return -1;
      if (b.isAdmin) return 1;
      return 0;
    });
    
    return result;
  }

  /// 멤버 아이템 위젯
  Widget _buildMemberItem(BuildContext context, _MemberWithPets member, GroupModel group) {
    return MingrrCard(
      margin: const EdgeInsets.only(bottom: AppSizes.gapS),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // 프로필 이미지
            MingrrAvatar(
              size: 48,
              imageUrl: member.profileImageUrl,
              placeholderIcon: Icons.person,
            ),
            const SizedBox(width: 12),
            // 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        member.nickname,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (member.isCreator) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: context.features.community.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '모임장',
                            style: TextStyle(
                              fontSize: 10,
                              color: context.features.community,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ] else if (member.isAdmin) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '운영진',
                            style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(context).colorScheme.outlineVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  // 반려동물 정보 (동반 모임인 경우)
                  if (group.isPetAccompanied) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.pets, size: 14, color: context.features.dating),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            member.petNames.isEmpty
                                ? '(반려동물 미등록)'
                                : member.petNames.join(', '),
                            style: TextStyle(
                              fontSize: 12,
                              color: member.petNames.isEmpty
                                  ? Theme.of(context).colorScheme.outlineVariant
                                  : context.features.dating,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildBottomButton(BuildContext context, GroupModel group) {
    final firebaseService = FirebaseService();
    final myUserId = firebaseService.currentUserId;
    // 현재 사용자가 memberIds에 포함되어 있는지 확인
    final isJoined = myUserId != null && group.memberIds.contains(myUserId);
    final isCreator = myUserId == group.creatorId;

    return MingrrBottomButtonBar(
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
                  side: BorderSide(color: context.features.community),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: EdgeInsets.zero,
                ),
                child: Icon(Icons.chat_bubble_outline, color: context.features.community),
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
                  backgroundColor: context.features.community,
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
      onConfirm: () => _joinGroup(context, group),
    );
  }
  
  /// 소모임 가입 처리
  Future<void> _joinGroup(BuildContext context, GroupModel group) async {
    if (_isJoining) return;
    
    final firebaseService = FirebaseService();
    final myUserId = firebaseService.currentUserId;
    
    if (myUserId == null) {
      MingrrSnackBar.warning(context, '로그인이 필요합니다');
      return;
    }
    
    setState(() => _isJoining = true);
    
    try {
      if (group.requireApproval) {
        // 승인 필요: 가입 신청 저장
        await firebaseService.joinRequestsCollection.add({
          'groupId': group.id,
          'userId': myUserId,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        if (context.mounted) {
          MingrrSnackBar.success(context, '가입 신청을 보냈습니다! 승인을 기다려주세요.');
        }
      } else {
        // 승인 불필요: 바로 가입
        await firebaseService.groupsCollection.doc(group.id).update({
          'memberIds': FieldValue.arrayUnion([myUserId]),
        });
        
        // 가입 후 채팅방 생성 및 이동
        if (context.mounted) {
          MingrrSnackBar.success(context, '모임에 가입했습니다! 🎉');
          // 채팅방으로 이동
          await _openGroupChat(context, group);
        }
      }
    } catch (e) {
      if (context.mounted) {
        MingrrSnackBar.error(context, '가입 실패: $e');
      }
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }

  void _showMoreOptions(BuildContext context) {
    showMingrrOptionsSheet(
      context: context,
      options: [
        MingrrOptionItem(
          icon: Icons.notifications_outlined,
          label: '알림 설정',
          onTap: () {},
        ),
        MingrrOptionItem(
          icon: Icons.report_outlined,
          label: '신고하기',
          isDestructive: true,
          onTap: () {},
        ),
      ],
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
      color: Theme.of(context).colorScheme.surface,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}

/// 멤버 + 반려동물 정보 모델
class _MemberWithPets {
  final String id;
  final String nickname;
  final String? profileImageUrl;
  final bool isCreator;
  final bool isAdmin;
  final List<String> petNames;

  const _MemberWithPets({
    required this.id,
    required this.nickname,
    this.profileImageUrl,
    this.isCreator = false,
    this.isAdmin = false,
    this.petNames = const [],
  });
}
