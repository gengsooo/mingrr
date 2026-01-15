import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/feature_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/chat_service.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/mingrr_bottom_sheet.dart';
import '../../../../core/widgets/report_sheet.dart';
import '../../../../core/widgets/svg_icons.dart';
import '../../../../core/widgets/dialogs/dialogs.dart';
import '../../../../models/group_model.dart';
import '../../../../models/chat_model.dart';
import '../../../chat/presentation/screens/chat_detail_screen.dart';
import '../providers/group_provider.dart';
import 'group_write_screen.dart';

/// ============================================================
/// 소모임(Group) 상세 화면
/// 
/// 소셜 > 소모임 > 모임 상세
/// 모임 정보, 멤버 목록, 일정, 가입/탈퇴/강퇴 기능
/// ============================================================

class GroupDetailScreen extends ConsumerStatefulWidget {
  final String groupId;

  const GroupDetailScreen({super.key, required this.groupId});

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
    final groupAsync = ref.watch(groupDetailProvider(widget.groupId));
    final isLikedAsync = ref.watch(isGroupLikedProvider(widget.groupId));
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = context.features.social;

    return Scaffold(
      backgroundColor: context.detailBackground,
      body: groupAsync.when(
        data: (group) {
          if (group == null) {
            return const MingrrEmptyState(
              icon: Icons.groups_outlined,
              title: '모임을 찾을 수 없어요',
              subtitle: '삭제되었거나 존재하지 않는 모임입니다',
            );
          }

          final myUserId = FirebaseService().currentUserId;
          final isJoined = myUserId != null && group.isMember(myUserId);
          final isCreator = myUserId != null && group.isCreator(myUserId);
          final isAdmin = myUserId != null && group.isAdmin(myUserId);

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              _buildAppBar(context, group, isLikedAsync.valueOrNull ?? false),
              SliverToBoxAdapter(
                child: _buildGroupInfo(context, group, isJoined),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _TabBarDelegate(
                  tabController: _tabController,
                  accentColor: accentColor,
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildInfoTab(context, group),
                _buildMembersTab(context, group, isCreator, isAdmin),
                _buildScheduleTab(context, group, isJoined),
              ],
            ),
          );
        },
        loading: () => const MingrrLoadingState(),
        error: (_, __) => const MingrrErrorState(title: '일시적인 오류가 발생했어요', subtitle: '잠시 후 다시 시도해주세요'),
      ),
      bottomNavigationBar: groupAsync.whenData((group) {
        if (group == null) return const SizedBox.shrink();
        return _buildBottomButton(context, group);
      }).valueOrNull,
    );
  }

  Widget _buildAppBar(BuildContext context, GroupModel group, bool isLiked) {
    final accentColor = context.features.social;

    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: accentColor,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isLiked ? Icons.favorite : Icons.favorite_border,
              color: isLiked ? Colors.red : Colors.white,
              size: 20,
            ),
          ),
          onPressed: () async {
            await ref.read(groupNotifierProvider.notifier).toggleLike(group.id);
            ref.invalidate(groupDetailProvider(widget.groupId));
            ref.invalidate(isGroupLikedProvider(widget.groupId));
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
          onPressed: () => _showMoreOptions(context, group),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: group.imageUrl != null
            ? Image.network(
                group.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildDefaultCover(accentColor),
              )
            : _buildDefaultCover(accentColor),
      ),
    );
  }

  Widget _buildDefaultCover(Color accentColor) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [accentColor.withOpacity(0.8), accentColor],
        ),
      ),
      child: const Center(
        child: Icon(Icons.groups, size: 80, color: Colors.white),
      ),
    );
  }

  Widget _buildGroupInfo(BuildContext context, GroupModel group, bool isJoined) {
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = context.features.social;

    return Container(
      color: colorScheme.surface,
      padding: const EdgeInsets.all(AppSizes.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 카테고리 + 상태
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  group.typeString,
                  style: TextStyle(fontSize: 12, color: accentColor, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(width: 8),
              if (group.isPetAccompanied)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: context.features.dating.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.pets, size: 12, color: context.features.dating),
                      const SizedBox(width: 4),
                      Text(
                        '반려동물 동반',
                        style: TextStyle(fontSize: 11, color: context.features.dating),
                      ),
                    ],
                  ),
                ),
              if (isJoined) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '가입됨',
                    style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // 모임 이름
          Text(
            group.name,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),

          // 정보 행
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 16, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  group.address ?? '지역 미설정',
                  style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildInfoChip(Icons.people_outline, '${group.memberCount}명', colorScheme),
              const SizedBox(width: 16),
              _buildInfoChip(Icons.favorite_outline, '${group.likeCount}', colorScheme),
              const SizedBox(width: 16),
              if (group.maxMembers > 0)
                _buildInfoChip(Icons.group_add_outlined, '정원 ${group.maxMembers}명', colorScheme),
            ],
          ),

          // 태그
          if (group.tags.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: group.tags.map((tag) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppSizes.radiusS),
                ),
                child: Text('#$tag', style: TextStyle(fontSize: 12, color: accentColor)),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, ColorScheme colorScheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
      ],
    );
  }

  Widget _buildInfoTab(BuildContext context, GroupModel group) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 모임 소개
          const Text('모임 소개', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(AppSizes.radiusS),
            ),
            child: Text(
              group.description,
              style: TextStyle(fontSize: 14, height: 1.6, color: colorScheme.onSurface),
            ),
          ),
          const SizedBox(height: 24),

          // 모임 설정
          const Text('모임 설정', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(AppSizes.radiusS),
            ),
            child: Column(
              children: [
                _buildSettingRow('공개 모임', group.isPublic ? '예' : '아니오', Icons.visibility_outlined),
                const Divider(height: 24),
                _buildSettingRow('가입 승인', group.requireApproval ? '필요' : '자유 가입', Icons.how_to_reg_outlined),
                const Divider(height: 24),
                _buildSettingRow('반려동물 동반', group.isPetAccompanied ? '예' : '아니오', Icons.pets_outlined),
              ],
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSettingRow(String label, String value, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontSize: 14)),
        const Spacer(),
        Text(value, style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant)),
      ],
    );
  }

  Widget _buildMembersTab(BuildContext context, GroupModel group, bool isCreator, bool isAdmin) {
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = context.features.social;

    return FutureBuilder<List<_MemberInfo>>(
      future: _loadMembers(group),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MingrrLoadingState();
        }

        final members = snapshot.data ?? [];
        if (members.isEmpty) {
          return Center(
            child: MingrrEmptyState(
              icon: Icons.people_outline,
              title: '멤버가 없어요',
              subtitle: '아직 가입한 멤버가 없습니다',
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSizes.paddingL),
          itemCount: members.length,
          itemBuilder: (context, index) {
            final member = members[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(AppSizes.radiusS),
              ),
              child: Row(
                children: [
                  MingrrAvatar(
                    size: 48,
                    imageUrl: member.profileUrl,
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
                              member.nickname,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 8),
                            if (member.isCreator)
                              _buildRoleBadge('모임장', accentColor)
                            else if (member.isAdmin)
                              _buildRoleBadge('운영진', colorScheme.outline),
                          ],
                        ),
                        if (member.petNames.isNotEmpty && group.isPetAccompanied) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.pets, size: 12, color: context.features.dating),
                              const SizedBox(width: 4),
                              Text(
                                member.petNames.join(', '),
                                style: TextStyle(fontSize: 12, color: context.features.dating),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  // 관리 버튼 (모임장/운영진만)
                  if ((isCreator || isAdmin) && !member.isCreator && member.id != FirebaseService().currentUserId)
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: colorScheme.onSurfaceVariant),
                      onSelected: (value) => _handleMemberAction(value, member, group),
                      itemBuilder: (context) => [
                        if (isCreator)
                          PopupMenuItem(
                            value: member.isAdmin ? 'remove_admin' : 'make_admin',
                            child: Text(member.isAdmin ? '운영진 해제' : '운영진 지정'),
                          ),
                        const PopupMenuItem(
                          value: 'kick',
                          child: Text('강퇴하기', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRoleBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  Future<List<_MemberInfo>> _loadMembers(GroupModel group) async {
    final firebase = FirebaseService();
    final List<_MemberInfo> result = [];

    for (final memberId in group.memberIds.take(50)) {
      try {
        final userDoc = await firebase.usersCollection.doc(memberId).get();
        if (!userDoc.exists) continue;

        final userData = userDoc.data()!;
        List<String> petNames = [];

        if (group.isPetAccompanied) {
          final petsSnapshot = await firebase.petsCollection
              .where('ownerId', isEqualTo: memberId)
              .limit(3)
              .get();
          petNames = petsSnapshot.docs
              .map((doc) => doc.data()['name'] as String? ?? '반려동물')
              .toList();
        }

        result.add(_MemberInfo(
          id: memberId,
          nickname: userData['nickname'] ?? '사용자',
          profileUrl: userData['profileImageUrl'],
          isCreator: memberId == group.creatorId,
          isAdmin: group.adminIds.contains(memberId),
          petNames: petNames,
        ));
      } catch (_) {}
    }

    // 모임장 -> 운영진 -> 일반 멤버 순 정렬
    result.sort((a, b) {
      if (a.isCreator) return -1;
      if (b.isCreator) return 1;
      if (a.isAdmin && !b.isAdmin) return -1;
      if (b.isAdmin && !a.isAdmin) return 1;
      return 0;
    });

    return result;
  }

  void _handleMemberAction(String action, _MemberInfo member, GroupModel group) async {
    final notifier = ref.read(groupNotifierProvider.notifier);

    switch (action) {
      case 'make_admin':
      case 'remove_admin':
        await notifier.toggleAdmin(group.id, member.id);
        ref.invalidate(groupDetailProvider(widget.groupId));
        break;
      case 'kick':
        final confirmed = await showConfirmSheetWithResult(
          context,
          type: ConfirmSheetType.generalDelete,
          title: '멤버 강퇴',
          message: '${member.nickname}님을 모임에서 강퇴하시겠습니까?',
          confirmText: '강퇴',
        );
        if (confirmed == true) {
          final success = await notifier.kickMember(group.id, member.id);
          if (success && mounted) {
            MingrrSnackBar.success(context, '멤버를 강퇴했습니다');
            ref.invalidate(groupDetailProvider(widget.groupId));
          }
        }
        break;
    }
  }

  Widget _buildScheduleTab(BuildContext context, GroupModel group, bool isJoined) {
    final schedulesAsync = ref.watch(groupSchedulesProvider(group.id));
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = context.features.social;

    return schedulesAsync.when(
      data: (schedules) {
        if (schedules.isEmpty) {
          return Center(
            child: MingrrEmptyState(
              icon: Icons.event_outlined,
              title: '일정이 없어요',
              subtitle: isJoined ? '새로운 일정을 만들어보세요' : '예정된 일정이 없습니다',
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSizes.paddingL),
          itemCount: schedules.length,
          itemBuilder: (context, index) {
            final schedule = schedules[index];
            final isPast = schedule.isPast;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(AppSizes.radiusS),
                border: isPast ? null : Border.all(color: accentColor.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isPast
                              ? colorScheme.surfaceContainerLow
                              : accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isPast ? '종료' : '예정',
                          style: TextStyle(
                            fontSize: 11,
                            color: isPast ? colorScheme.onSurfaceVariant : accentColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${schedule.participantCount}명 참여',
                        style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    schedule.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isPast ? colorScheme.onSurfaceVariant : colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Text(
                        _formatScheduleDate(schedule.startTime),
                        style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                  if (schedule.place != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 14, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            schedule.place!,
                            style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
      loading: () => const MingrrLoadingState(),
      error: (_, __) => const MingrrErrorState(title: '일시적인 오류가 발생했어요', subtitle: '잠시 후 다시 시도해주세요'),
    );
  }

  String _formatScheduleDate(DateTime dateTime) {
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    return '${dateTime.month}/${dateTime.day}(${weekdays[dateTime.weekday - 1]}) '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildBottomButton(BuildContext context, GroupModel group) {
    final myUserId = FirebaseService().currentUserId;
    final isJoined = myUserId != null && group.isMember(myUserId);
    final isCreator = myUserId != null && group.isCreator(myUserId);
    final accentColor = context.features.social;

    return MingrrBottomButtonBar(
      child: Row(
        children: [
          // 채팅 버튼 (가입한 경우)
          if (isJoined) ...[
            SizedBox(
              height: 56,
              width: 56,
              child: OutlinedButton(
                onPressed: () => _openGroupChat(context, group),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: accentColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: EdgeInsets.zero,
                ),
                child: Icon(Icons.chat_bubble_outline, color: accentColor),
              ),
            ),
            const SizedBox(width: 12),
          ],
          // 메인 버튼
          Expanded(
            child: SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isJoining
                    ? null
                    : isJoined
                        ? (isCreator ? () => _showCreatorOptions(context, group) : () => _leaveGroup(group))
                        : () => _joinGroup(group),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isJoined && !isCreator ? Colors.red : accentColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isJoining
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        isJoined
                            ? (isCreator ? '모임 관리' : '모임 탈퇴')
                            : (group.requireApproval ? '가입 신청' : '모임 가입'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _joinGroup(GroupModel group) async {
    setState(() => _isJoining = true);

    try {
      final success = await ref.read(groupNotifierProvider.notifier).joinGroup(group.id);
      if (success && mounted) {
        if (group.requireApproval) {
          MingrrSnackBar.success(context, '가입 신청을 보냈습니다');
        } else {
          MingrrSnackBar.success(context, '모임에 가입했습니다! 🎉');
        }
        ref.invalidate(groupDetailProvider(widget.groupId));
      }
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }

  Future<void> _leaveGroup(GroupModel group) async {
    final confirmed = await showConfirmSheetWithResult(
      context,
      type: ConfirmSheetType.groupLeave,
      title: group.name,
      message: '이 모임에서 탈퇴하시겠습니까?',
    );

    if (confirmed == true) {
      setState(() => _isJoining = true);
      try {
        final success = await ref.read(groupNotifierProvider.notifier).leaveGroup(group.id);
        if (success && mounted) {
          MingrrSnackBar.success(context, '모임에서 탈퇴했습니다');
          ref.invalidate(groupDetailProvider(widget.groupId));
        }
      } finally {
        if (mounted) setState(() => _isJoining = false);
      }
    }
  }

  void _showCreatorOptions(BuildContext context, GroupModel group) {
    showMingrrOptionsSheet(
      context: context,
      options: [
        MingrrOptionItem(
          icon: Icons.edit_outlined,
          label: '모임 수정',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => GroupWriteScreen(group: group)),
            ).then((result) {
              if (result == true) {
                ref.invalidate(groupDetailProvider(widget.groupId));
              }
            });
          },
        ),
        MingrrOptionItem(
          icon: Icons.person_add_outlined,
          label: '가입 신청 관리',
          onTap: () => _showJoinRequests(context, group),
        ),
        MingrrOptionItem(
          icon: Icons.delete_outline,
          label: '모임 삭제',
          isDestructive: true,
          onTap: () => _deleteGroup(group),
        ),
      ],
    );
  }

  void _showJoinRequests(BuildContext context, GroupModel group) {
    // TODO: 가입 신청 관리 화면
    MingrrSnackBar.info(context, '가입 신청 관리 기능 준비 중');
  }

  Future<void> _deleteGroup(GroupModel group) async {
    final confirmed = await showConfirmSheetWithResult(
      context,
      type: ConfirmSheetType.groupDelete,
      title: '모임 삭제',
      message: '이 모임을 삭제하시겠습니까?\n삭제된 모임은 복구할 수 없습니다.',
    );

    if (confirmed == true) {
      try {
        await FirebaseService().groupsCollection.doc(group.id).delete();
        if (mounted) {
          Navigator.pop(context);
          MingrrSnackBar.success(context, '모임이 삭제되었습니다');
        }
      } catch (e) {
        if (mounted) {
          MingrrSnackBar.error(context, '삭제 실패: $e');
        }
      }
    }
  }

  Future<void> _openGroupChat(BuildContext context, GroupModel group) async {
    final firebase = FirebaseService();
    final chatService = ChatService();
    final myUserId = firebase.currentUserId;

    if (myUserId == null) {
      MingrrSnackBar.warning(context, '로그인이 필요합니다');
      return;
    }

    try {
      final myUserDoc = await firebase.usersCollection.doc(myUserId).get();
      final myUserData = myUserDoc.data();

      final myInfo = ChatParticipant(
        id: myUserId,
        nickname: myUserData?['nickname'] ?? '사용자',
        profileImageUrl: myUserData?['profileImageUrl'],
      );

      final creatorDoc = await firebase.usersCollection.doc(group.creatorId).get();
      final creatorData = creatorDoc.data();

      final leaderInfo = ChatParticipant(
        id: group.creatorId,
        nickname: creatorData?['nickname'] ?? '모임장',
        profileImageUrl: creatorData?['profileImageUrl'],
      );

      final chatRoom = await chatService.getOrCreateChatRoom(
        myUserId: myUserId,
        otherUserId: group.creatorId,
        type: 'group',
        myInfo: myInfo,
        otherInfo: leaderInfo,
        relatedId: group.id,
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatDetailScreen(
              chatRoomId: chatRoom.id,
              otherUserName: group.name,
              chatType: 'group',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        MingrrSnackBar.error(context, '채팅 시작 실패: $e');
      }
    }
  }

  void _showMoreOptions(BuildContext context, GroupModel group) {
    final myUserId = FirebaseService().currentUserId;
    final isCreator = myUserId != null && group.isCreator(myUserId);

    showMingrrOptionsSheet(
      context: context,
      options: [
        MingrrOptionItem(
          icon: Icons.share_outlined,
          label: '공유하기',
          onTap: () {},
        ),
        if (!isCreator)
          MingrrOptionItem(
            icon: Icons.report_outlined,
            label: '신고하기',
            isDestructive: true,
            onTap: () {
              showReportSheet(
                context,
                targetId: group.id,
                targetName: group.name,
                targetType: ReportTargetType.group,
              );
            },
          ),
      ],
    );
  }
}

/// 탭바 델리게이트
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;
  final Color accentColor;

  _TabBarDelegate({required this.tabController, required this.accentColor});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: TabBar(
        controller: tabController,
        indicatorColor: accentColor,
        indicatorWeight: 3,
        labelColor: accentColor,
        unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
        tabs: const [
          Tab(text: '정보'),
          Tab(text: '멤버'),
          Tab(text: '일정'),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 48;

  @override
  double get minExtent => 48;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}

/// 멤버 정보
class _MemberInfo {
  final String id;
  final String nickname;
  final String? profileUrl;
  final bool isCreator;
  final bool isAdmin;
  final List<String> petNames;

  _MemberInfo({
    required this.id,
    required this.nickname,
    this.profileUrl,
    required this.isCreator,
    required this.isAdmin,
    this.petNames = const [],
  });
}
