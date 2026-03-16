import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/theme/feature_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/location_constants.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../../../core/services/chat_service.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/sheets/mingrr_bottom_sheet.dart';
import '../../../../core/widgets/sheets/request_sheet.dart';
import '../../../../core/widgets/sheets/report_sheet.dart';
import '../../../../core/widgets/dialogs/dialogs.dart';
import '../../../../core/widgets/badges/info_badge.dart';
import '../../../../core/widgets/modals/guardian_profile_modal.dart';
import '../../../../core/widgets/navigation/top_navigation.dart';
import '../../../../models/group_model.dart';
import '../../../../models/chat_model.dart';
import '../../../../core/providers/refresh_notifier.dart';
import '../../../../core/services/share_service.dart';
import '../providers/group_provider.dart';
import '../../../../core/utils/error_handler.dart';
import 'group_write_screen.dart';
import '../../../../core/widgets/sheets/schedule_sheet.dart';
import '../../../../core/widgets/cards/request_card.dart';
import '../../../../core/widgets/badges/request_status_badge.dart';

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
  
  // 가입 신청 상태 (State 기반 - 깜빡임 방지)
  bool _hasPendingJoinRequest = false;
  bool _joinRequestStatusLoaded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadJoinRequestStatus();
  }
  
  /// 가입 신청 상태 로드 (State 기반 - 깜빡임 방지)
  Future<void> _loadJoinRequestStatus() async {
    try {
      final userId = FirebaseService().currentUserId;
      if (userId == null) {
        setState(() => _joinRequestStatusLoaded = true);
        return;
      }
      
      final hasPending = await ref.read(firestoreServiceProvider).hasUserRequestedJoin(widget.groupId, userId);
      
      if (mounted) {
        setState(() {
          _hasPendingJoinRequest = hasPending;
          _joinRequestStatusLoaded = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _joinRequestStatusLoaded = true);
      }
    }
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
    final accentColor = context.features.social;

    return Scaffold(
      backgroundColor: context.detailBackground,
      body: groupAsync.when(
        data: (group) {
          if (group == null) {
            return const MingrrEmptyState(
              icon: AppIcons.group,
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
                delegate: MingrrSubTabBarDelegate(
                  tabs: const ['정보', '멤버', '일정'],
                  controller: _tabController,
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
        loading: () => const MingrrLoadingState(
          type: MingrrLoadingType.community,
          message: '모임 정보를 불러오고 있어요',
        ),
        error: (_, _) => MingrrErrorState(
          onRetry: () => ref.invalidate(groupDetailProvider(widget.groupId)),
        ),
      ),
      bottomNavigationBar: groupAsync.whenData((group) {
        if (group == null) return const SizedBox.shrink();
        return _buildBottomButton(context, group);
      }).valueOrNull,
      floatingActionButton: groupAsync.whenData((group) {
        if (group == null) return null;
        final myUserId = FirebaseService().currentUserId;
        final isJoined = myUserId != null && group.isMember(myUserId);
        
        // 일정 탭이고 멤버인 경우에만 FAB 표시
        return AnimatedBuilder(
          animation: _tabController,
          builder: (context, child) {
            if (_tabController.index != 2 || !isJoined) {
              return const SizedBox.shrink();
            }
            return FloatingActionButton(
              onPressed: () => showScheduleWriteSheet(context, groupId: group.id),
              backgroundColor: context.features.social,
              child: const Icon(AppIcons.add, color: Colors.white),
            );
          },
        );
      }).valueOrNull,
    );
  }

  Widget _buildAppBar(BuildContext context, GroupModel group, bool isLiked) {
    final accentColor = context.features.social;

    return MingrrImageHeader(
      imageUrls: group.imageUrl != null ? [group.imageUrl!] : [],
      expandedHeight: 200,
      showIndicator: false,
      bottomRightOverlay: LikeOverlayBadge(
        count: group.likeCount,
        isLiked: isLiked,
        onTap: () async {
          await ref.read(groupNotifierProvider.notifier).toggleLike(group.id);
          ref.invalidate(groupDetailProvider(widget.groupId));
          ref.invalidate(isGroupLikedProvider(widget.groupId));
        },
      ),
      onMore: () => _showMoreOptions(context, group),
      placeholder: _buildDefaultCover(accentColor),
    );
  }

  Widget _buildDefaultCover(Color accentColor) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [accentColor.withValues(alpha: AppOpacity.o80), accentColor],
        ),
      ),
      child: const Center(
        child: Icon(AppIcons.group, size: 80, color: Colors.white),
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
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingS, vertical: AppSizes.paddingXS),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: AppOpacity.o10),
                  borderRadius: BorderRadius.circular(AppSizes.radiusS),
                ),
                child: Text(
                  group.typeString,
                  style: AppTextStyles.labelLarge(context).copyWith(color: accentColor),
                ),
              ),
              const SizedBox(width: AppSizes.gapS),
              if (group.isPetAccompanied)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingS, vertical: AppSizes.paddingXS),
                  decoration: BoxDecoration(
                    color: context.features.dating.withValues(alpha: AppOpacity.o10),
                    borderRadius: BorderRadius.circular(AppSizes.radiusS),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(AppIcons.pet, size: 12, color: context.features.dating),
                      const SizedBox(width: AppSizes.gapXS),
                      Text(
                        '반려동물 동반',
                        style: AppTextStyles.labelMedium(context).copyWith(color: context.features.dating),
                      ),
                    ],
                  ),
                ),
              if (isJoined) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingS, vertical: AppSizes.paddingXS),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(AppSizes.radiusS),
                  ),
                  child: Text(
                    '가입됨',
                    style: AppTextStyles.labelMedium(context).copyWith(color: Colors.white),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSizes.gapL),

          // 모임 이름
          Text(
            group.name,
            style: AppTextStyles.displayMedium(context),
          ),
          const SizedBox(height: AppSizes.gapM),

          // 정보 행
          Row(
            children: [
              Icon(LocationConstants.distanceIcon, size: 16, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: AppSizes.gapXS),
              Expanded(
                child: Text(
                  group.address ?? LocationConstants.noLocationText,
                  style: AppTextStyles.bodySmall(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.gapS),
          Row(
            children: [
              _buildInfoChip(AppIcons.people, '${group.memberCount}명', colorScheme),
              const SizedBox(width: 16),
              LikeCountText(count: group.likeCount, size: InfoBadgeSize.small),
              const SizedBox(width: 16),
              if (group.maxMembers > 0)
                _buildInfoChip(AppIcons.groupAdd, '정원 ${group.maxMembers}명', colorScheme),
            ],
          ),

          // 태그
          if (group.tags.isNotEmpty) ...[
            const SizedBox(height: AppSizes.gapL),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: group.tags.map((tag) => Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingS, vertical: AppSizes.paddingXS),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppSizes.radiusS),
                ),
                child: Text('#$tag', style: AppTextStyles.labelLarge(context).copyWith(color: accentColor)),
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
        const SizedBox(width: AppSizes.gapXS),
        Text(text, style: AppTextStyles.caption(context).copyWith(color: colorScheme.onSurfaceVariant)),
      ],
    );
  }

  Widget _buildInfoTab(BuildContext context, GroupModel group) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 모임 소개
          _buildSectionTitle('모임 소개'),
          const SizedBox(height: AppSizes.gapM),
          _buildSectionBox(
            child: Text(
              group.description,
              style: AppTextStyles.bodyMedium(context).copyWith(height: 1.6),
            ),
          ),
          const SizedBox(height: AppSizes.gapXL),

          // 모임 설정
          _buildSectionTitle('모임 설정'),
          const SizedBox(height: AppSizes.gapM),
          _buildSectionBox(
            child: Column(
              children: [
                _buildSettingRow('공개 모임', group.isPublic ? '예' : '아니오', AppIcons.eyeCleaning),
                const MingrrDivider.section(),
                _buildSettingRow('가입 승인', group.requireApproval ? '필요' : '자유 가입', AppIcons.verified),
                const MingrrDivider.section(),
                _buildSettingRow('반려동물 동반', group.isPetAccompanied ? '예' : '아니오', AppIcons.petOutlined),
              ],
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  /// 섹션 타이틀
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.titleMedium(context),
    );
  }

  /// 섹션 박스 (배경색 있는 컨테이너)
  Widget _buildSectionBox({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.paddingL),
      decoration: BoxDecoration(
        color: context.sectionBackground,
        borderRadius: BorderRadius.circular(AppSizes.radiusS),
      ),
      child: child,
    );
  }

  Widget _buildSettingRow(String label, String value, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: AppSizes.gapM),
        Text(label, style: AppTextStyles.bodyMedium(context)),
        const Spacer(),
        Text(value, style: AppTextStyles.bodySmall(context)),
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
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSizes.paddingXL),
              child: MingrrLoadingIndicator.medium(type: MingrrLoadingType.community),
            ),
          );
        }

        final members = snapshot.data ?? [];
        if (members.isEmpty) {
          // NestedScrollView 내부에서는 Center 대신 CustomScrollView 사용
          return CustomScrollView(
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: MingrrEmptyState(
                    icon: AppIcons.people,
                    title: '멤버가 없어요',
                    subtitle: '아직 가입한 멤버가 없습니다',
                  ),
                ),
              ),
            ],
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSizes.paddingL),
          itemCount: members.length,
          itemBuilder: (context, index) {
            final member = members[index];
            return GestureDetector(
              onTap: () => _showMemberProfile(context, member),
              child: Container(
                margin: const EdgeInsets.only(bottom: AppSizes.paddingS),
                padding: const EdgeInsets.all(AppSizes.paddingM),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppSizes.radiusS),
                ),
                child: Row(
                  children: [
                    MingrrImage.avatar(
                      size: 48,
                      imageUrl: member.profileUrl,
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
                              member.nickname,
                              style: AppTextStyles.titleMedium(context),
                            ),
                            const SizedBox(width: AppSizes.gapS),
                            if (member.isCreator)
                              _buildRoleBadge('모임장', accentColor)
                            else if (member.isAdmin)
                              _buildRoleBadge('운영진', colorScheme.outline),
                          ],
                        ),
                        if (member.petNames.isNotEmpty && group.isPetAccompanied) ...[
                          const SizedBox(height: AppSizes.gapXS),
                          Row(
                            children: [
                              Icon(AppIcons.pet, size: 12, color: context.features.dating),
                              const SizedBox(width: AppSizes.gapXS),
                              Text(
                                member.petNames.join(', '),
                                style: AppTextStyles.caption(context).copyWith(color: context.features.dating),
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
                      icon: Icon(AppIcons.moreVert, color: colorScheme.onSurfaceVariant),
                      onSelected: (value) => _handleMemberAction(value, member, group),
                      itemBuilder: (context) => [
                        if (isCreator)
                          PopupMenuItem(
                            value: member.isAdmin ? 'remove_admin' : 'make_admin',
                            child: Text(member.isAdmin ? '운영진 해제' : '운영진 지정'),
                          ),
                        PopupMenuItem(
                          value: 'kick',
                          child: Text('강퇴하기', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// 멤버 프로필 바텀시트 표시
  void _showMemberProfile(BuildContext context, _MemberInfo member) {
    showGuardianProfileFromFirestore(
      context,
      userId: member.id,
      fallbackName: member.nickname,
      fallbackImageUrl: member.profileUrl,
    );
  }

  Widget _buildRoleBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: AppSizes.paddingXXS),
      decoration: BoxDecoration(
        color: color.withValues(alpha: AppOpacity.o10),
        borderRadius: BorderRadius.circular(AppSizes.radiusS),
      ),
      child: Text(
        label,
        style: AppTextStyles.captionSmall(context).copyWith(color: color),
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
              icon: AppIcons.event,
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

            final myUserId = FirebaseService().currentUserId;
            final isAdmin = myUserId != null && group.isAdmin(myUserId);
            
            return GestureDetector(
              onTap: () => showScheduleDetailSheet(
                context,
                schedule: schedule,
                groupId: group.id,
                isGroupAdmin: isAdmin,
              ),
              child: Container(
                margin: const EdgeInsets.only(bottom: AppSizes.paddingM),
                padding: const EdgeInsets.all(AppSizes.paddingL),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppSizes.radiusS),
                  border: isPast ? null : Border.all(color: accentColor.withValues(alpha: AppOpacity.o30)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingS, vertical: AppSizes.paddingXS),
                          decoration: BoxDecoration(
                            color: isPast
                                ? colorScheme.surfaceContainerLow
                                : accentColor.withValues(alpha: AppOpacity.o10),
                            borderRadius: BorderRadius.circular(AppSizes.radiusS),
                          ),
                          child: Text(
                            isPast ? '종료' : '예정',
                            style: AppTextStyles.labelMedium(context).copyWith(
                              color: isPast ? colorScheme.onSurfaceVariant : accentColor,
                            ),
                          ),
                        ),
                        const Spacer(),
                        // 참여자 아바타 미리보기 (최대 3명)
                        if (schedule.participantIds.isNotEmpty)
                          _ScheduleParticipantAvatars(
                            participantIds: schedule.participantIds,
                            maxDisplay: 3,
                          ),
                        const SizedBox(width: AppSizes.gapS),
                        Text(
                          '${schedule.participantCount}명',
                          style: AppTextStyles.caption(context),
                        ),
                        const SizedBox(width: AppSizes.gapS),
                        Icon(AppIcons.chevronRight, size: 16, color: colorScheme.onSurfaceVariant),
                      ],
                    ),
                    const SizedBox(height: AppSizes.gapM),
                    Text(
                      schedule.title,
                      style: AppTextStyles.headlineSmall(context).copyWith(
                        color: isPast ? colorScheme.onSurfaceVariant : null,
                      ),
                    ),
                    const SizedBox(height: AppSizes.gapS),
                    Row(
                      children: [
                        Icon(AppIcons.calendar, size: 14, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: AppSizes.gapS),
                        Text(
                          _formatScheduleDate(schedule.startTime),
                          style: AppTextStyles.bodySmall(context),
                        ),
                      ],
                    ),
                    if (schedule.place != null) ...[
                      const SizedBox(height: AppSizes.gapS),
                      Row(
                        children: [
                          Icon(AppIcons.locationOutlined, size: 14, color: colorScheme.onSurfaceVariant),
                          const SizedBox(width: AppSizes.gapS),
                          Expanded(
                            child: Text(
                              schedule.place!,
                              style: AppTextStyles.bodySmall(context),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSizes.paddingXL),
          child: MingrrLoadingIndicator.medium(type: MingrrLoadingType.community),
        ),
      ),
      error: (error, stack) => Center(
        child: MingrrEmptyState(
          icon: AppIcons.event,
          title: '일정을 불러올 수 없어요',
          subtitle: '잠시 후 다시 시도해주세요',
        ),
      ),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusM)),
                  padding: EdgeInsets.zero,
                ),
                child: Icon(AppIcons.chatOutlined, color: accentColor),
              ),
            ),
            const SizedBox(width: AppSizes.gapM),
          ],
          // 메인 버튼 (State 기반 - 깜빡임 방지)
          Expanded(
            child: _buildJoinButton(context, group, isJoined, isCreator, accentColor),
          ),
        ],
      ),
    );
  }
  
  /// 가입 버튼 빌드 (State 기반 - 깜빡임 방지)
  Widget _buildJoinButton(BuildContext context, GroupModel group, bool isJoined, bool isCreator, Color accentColor) {
    // 이미 가입한 경우
    if (isJoined) {
      return MingrrButton(
        text: isCreator ? '모임 관리' : '모임 탈퇴',
        onPressed: _isJoining
            ? null
            : isCreator ? () => _showCreatorOptions(context, group) : () => _leaveGroup(group),
        isLoading: _isJoining,
        backgroundColor: isCreator ? accentColor : Theme.of(context).colorScheme.error,
        textColor: Colors.white,
        height: 56,
      );
    }
    
    // 로딩 중이면 비활성화된 버튼 표시 (텍스트는 기본값)
    if (!_joinRequestStatusLoaded) {
      return MingrrButton(
        text: group.requireApproval ? '가입 신청' : '모임 가입',
        onPressed: null,
        backgroundColor: accentColor,
        textColor: Colors.white,
        height: 56,
      );
    }
    
    // 이미 신청한 경우 비활성화
    if (_hasPendingJoinRequest) {
      return MingrrButton(
        text: '신청 대기 중',
        onPressed: null,
        backgroundColor: Theme.of(context).colorScheme.outlineVariant,
        textColor: Colors.white,
        height: 56,
      );
    }
    
    // 가입 가능
    return MingrrButton(
      text: group.requireApproval ? '가입 신청' : '모임 가입',
      onPressed: _isJoining ? null : () => _joinGroup(group),
      isLoading: _isJoining,
      backgroundColor: accentColor,
      textColor: Colors.white,
      height: 56,
    );
  }

  Future<void> _joinGroup(GroupModel group) async {
    // 승인 필요한 모임인 경우 공통 RequestSheet 사용
    if (group.requireApproval) {
      showGroupJoinSheet(
        context,
        groupName: group.name,
        onConfirm: (message) async {
          setState(() => _isJoining = true);
          try {
            final success = await ref.read(groupNotifierProvider.notifier).joinGroup(
              group.id,
              message: message,
            );
            if (mounted) {
              if (success) {
                MingrrSnackBar.success(context, '가입 신청을 보냈습니다');
                // State 기반 신청 상태 갱신
                setState(() => _hasPendingJoinRequest = true);
              }
              ref.invalidate(groupDetailProvider(widget.groupId));
            }
          } catch (e) {
            if (mounted) {
              ErrorHandler.showError(context, e, tag: 'GroupDetail', operation: '가입 신청');
            }
          } finally {
            if (mounted) setState(() => _isJoining = false);
          }
        },
      );
    } else {
      // 바로 가입
      setState(() => _isJoining = true);
      try {
        final success = await ref.read(groupNotifierProvider.notifier).joinGroup(group.id);
        if (mounted) {
          if (success) {
            MingrrSnackBar.success(context, '모임에 가입했습니다! 🎉');
          }
          ref.read(groupRefreshProvider.notifier).state++;
          ref.invalidate(groupDetailProvider(widget.groupId));
        }
      } catch (e) {
        if (mounted) {
          ErrorHandler.showError(context, e, tag: 'GroupDetail', operation: '모임 가입');
        }
      } finally {
        if (mounted) setState(() => _isJoining = false);
      }
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
        if (mounted) {
          if (success) {
            // 리스트 새로고침 트리거 (내 모임 목록 갱신)
            ref.read(groupRefreshProvider.notifier).state++;
            Navigator.pop(context); // 상세 화면 닫기
            MingrrSnackBar.success(context, '모임에서 탈퇴했습니다');
          } else {
            MingrrSnackBar.warning(context, '탈퇴에 실패했습니다. 다시 시도해주세요.');
          }
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
          icon: AppIcons.editOutlined,
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
          icon: AppIcons.groupAdd,
          label: '가입 신청 관리',
          onTap: () => _showJoinRequests(context, group),
        ),
        MingrrOptionItem(
          icon: AppIcons.deleteOutlined,
          label: '모임 삭제',
          isDestructive: true,
          onTap: () => _deleteGroup(group),
        ),
      ],
    );
  }

  void _showJoinRequests(BuildContext context, GroupModel group) {
    final firestoreService = ref.read(firestoreServiceProvider);
    final firebase = FirebaseService();
    final myUserId = firebase.currentUserId ?? '';

    showMingrrBottomSheet(
      context: context,
      title: '가입 신청 관리',
      height: MediaQuery.of(context).size.height * 0.7,
      child: StreamBuilder<List<GroupJoinRequestModel>>(
        stream: firestoreService.watchPendingJoinRequests(group.id),
        builder: (context, snapshot) {
          // 오류 처리 먼저
          if (snapshot.hasError) {
            return MingrrEmptyState(
              icon: AppIcons.error,
              title: '데이터를 불러올 수 없어요',
              subtitle: '오류: ${snapshot.error}',
            );
          }
          
          // 로딩 중 (데이터가 없고 연결 대기 중)
          if (!snapshot.hasData) {
            return const Center(child: MingrrLoadingIndicator());
          }

          final requests = snapshot.data!;

          if (requests.isEmpty) {
            return const MingrrEmptyState(
              icon: AppIcons.personRemove,
              title: '대기 중인 신청이 없어요',
              subtitle: '새로운 가입 신청이 들어오면 여기에 표시됩니다',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSizes.paddingM),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return AsyncRequestCard(
                type: RequestCardType.groupJoin,
                userId: request.userId,
                status: UnifiedRequestStatus.fromGroup(request.status),
                message: request.message,
                requestedAt: request.createdAt,
                loadUserInfo: (userId) async {
                  final user = await firestoreService.getUser(userId);
                  if (user == null) return null;
                  return {
                    'name': user.nickname,
                    'imageUrl': user.profileImageUrl,
                  };
                },
                onTap: () => showGuardianProfileFromFirestore(
                  context,
                  userId: request.userId,
                ),
                onAccept: () async {
                  try {
                    await firestoreService.approveJoinRequest(
                      requestId: request.id,
                      groupId: group.id,
                      userId: request.userId,
                      respondedBy: myUserId,
                    );
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                    if (context.mounted) {
                      MingrrSnackBar.success(context, '가입을 승인했습니다');
                    }
                    ref.invalidate(groupJoinRequestsProvider(group.id));
                    ref.invalidate(groupDetailProvider(widget.groupId));
                    ref.read(groupRefreshProvider.notifier).state++;
                  } catch (e) {
                    if (context.mounted) {
                      MingrrSnackBar.error(context, '승인에 실패했어요. 다시 시도해주세요');
                    }
                  }
                },
                onReject: () async {
                  try {
                    await firestoreService.rejectJoinRequest(
                      requestId: request.id,
                      respondedBy: myUserId,
                    );
                    if (context.mounted) {
                      MingrrSnackBar.info(context, '가입을 거절했습니다');
                      ref.invalidate(groupJoinRequestsProvider(group.id));
                    }
                  } catch (e) {
                    if (context.mounted) {
                      MingrrSnackBar.error(context, '거절에 실패했어요. 다시 시도해주세요');
                    }
                  }
                },
              );
            },
          );
        },
      ),
    );
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
          // 리스트 새로고침 트리거
          ref.read(groupRefreshProvider.notifier).state++;
          Navigator.pop(context);
          MingrrSnackBar.success(context, '모임이 삭제되었습니다');
        }
      } catch (e) {
        if (mounted) {
          ErrorHandler.showError(context, e, tag: 'GroupDetail', operation: '모임 삭제');
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

      if (!context.mounted) return;
      // go_router를 사용하여 채팅 탭으로 이동 (하단 메뉴 동기화)
      context.go('/chat/${chatRoom.id}');
    } catch (e) {
      if (!context.mounted) return;
      ErrorHandler.showError(context, e, tag: 'GroupDetail', operation: '채팅 시작');
    }
  }

  void _showMoreOptions(BuildContext context, GroupModel group) {
    final myUserId = FirebaseService().currentUserId;
    final isCreator = myUserId != null && group.isCreator(myUserId);

    showDetailOptionsSheet(
      context: context,
      isOwner: isCreator,
      onShare: () => ShareService.shareGroup(context, group),
      onReport: () {
        showReportSheet(
          context,
          targetId: group.id,
          targetName: group.name,
          targetType: ReportTargetType.group,
        );
      },
    );
  }
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

/// 일정 카드용 참여자 아바타 미리보기
class _ScheduleParticipantAvatars extends StatefulWidget {
  final List<String> participantIds;
  final int maxDisplay;

  const _ScheduleParticipantAvatars({
    required this.participantIds,
    this.maxDisplay = 3,
  });

  @override
  State<_ScheduleParticipantAvatars> createState() => _ScheduleParticipantAvatarsState();
}

class _ScheduleParticipantAvatarsState extends State<_ScheduleParticipantAvatars> {
  final List<String?> _profileUrls = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadParticipantProfiles();
  }

  Future<void> _loadParticipantProfiles() async {
    final displayIds = widget.participantIds.take(widget.maxDisplay).toList();
    
    for (final userId in displayIds) {
      try {
        final user = await FirestoreService().getUser(userId);
        if (mounted) {
          setState(() {
            _profileUrls.add(user?.profileImageUrl);
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _profileUrls.add(null);
          });
        }
      }
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final displayCount = widget.participantIds.take(widget.maxDisplay).length;
    
    if (_isLoading && _profileUrls.isEmpty) {
      return const SizedBox(width: 60);
    }
    
    return SizedBox(
      width: 20.0 + (displayCount - 1) * 14.0,
      height: 20,
      child: Stack(
        children: List.generate(
          _profileUrls.length,
          (index) => Positioned(
            left: index * 14.0,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.surface, width: 1.5),
                color: colorScheme.surfaceContainerLow,
              ),
              child: ClipOval(
                child: _profileUrls[index] != null
                    ? MingrrImage(
                        imageUrl: _profileUrls[index],
                        fit: BoxFit.cover,
                      )
                    : Icon(AppIcons.profile, size: 12, color: colorScheme.onSurfaceVariant),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
