import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/feature_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/pet_constants.dart';
import '../../../../core/constants/location_constants.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/chat_service.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/mingrr_image.dart';
import '../../../../core/widgets/loading/loading_widgets.dart';
import '../../../../core/widgets/sheets/mingrr_bottom_sheet.dart';
import '../../../../core/widgets/sheets/report_sheet.dart';
import '../../../../core/widgets/badges/svg_icons.dart';
import '../../../../core/widgets/dialogs/dialogs.dart';
import '../../../../core/widgets/badges/info_badge.dart';
import '../../../../core/widgets/mingrr_image_header.dart';
import '../../../../core/widgets/modals/guardian_profile_modal.dart';
import '../../../../core/widgets/navigation/top_navigation.dart';
import '../../../../models/group_model.dart';
import '../../../../models/chat_model.dart';
import '../../../../models/user_model.dart';
import '../../../chat/presentation/screens/chat_detail_screen.dart';
import '../../../../core/providers/refresh_notifier.dart';
import '../../../../core/services/share_service.dart';
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
        error: (_, __) => MingrrErrorState(
          onRetry: () => ref.invalidate(groupDetailProvider(widget.groupId)),
        ),
      ),
      bottomNavigationBar: groupAsync.whenData((group) {
        if (group == null) return const SizedBox.shrink();
        return _buildBottomButton(context, group);
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
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingS, vertical: AppSizes.paddingXS),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: AppOpacity.o10),
                  borderRadius: BorderRadius.circular(AppSizes.radiusXS),
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
                    borderRadius: BorderRadius.circular(AppSizes.radiusXS),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.pets, size: 12, color: context.features.dating),
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
                    borderRadius: BorderRadius.circular(AppSizes.radiusXS),
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
              _buildInfoChip(Icons.people_outline, '${group.memberCount}명', colorScheme),
              const SizedBox(width: 16),
              LikeCountText(count: group.likeCount, size: InfoBadgeSize.small),
              const SizedBox(width: 16),
              if (group.maxMembers > 0)
                _buildInfoChip(Icons.group_add_outlined, '정원 ${group.maxMembers}명', colorScheme),
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
                _buildSettingRow('공개 모임', group.isPublic ? '예' : '아니오', Icons.visibility_outlined),
                const MingrrDivider.section(),
                _buildSettingRow('가입 승인', group.requireApproval ? '필요' : '자유 가입', Icons.how_to_reg_outlined),
                const MingrrDivider.section(),
                _buildSettingRow('반려동물 동반', group.isPetAccompanied ? '예' : '아니오', Icons.pets_outlined),
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
                    icon: Icons.people_outline,
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
                    MingrrAvatar(
                      size: 48,
                      imageUrl: member.profileUrl,
                      placeholderIcon: Icons.person,
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
                              Icon(Icons.pets, size: 12, color: context.features.dating),
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
              ),
            );
          },
        );
      },
    );
  }

  /// 멤버 프로필 바텀시트 표시
  Future<void> _showMemberProfile(BuildContext context, _MemberInfo member) async {
    try {
      final userDoc = await FirebaseService().usersCollection.doc(member.id).get();
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
          .where('ownerId', isEqualTo: member.id)
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
        guardianId: member.id,
        guardianName: member.nickname,
        kkosunnaeScore: kkosunnaeScore,
        profileImageUrl: member.profileUrl,
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
        guardianId: member.id,
        guardianName: member.nickname,
        kkosunnaeScore: 50.0,
        profileImageUrl: member.profileUrl,
        pets: [],
      );
    }
  }

  Widget _buildRoleBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: AppSizes.paddingXXS),
      decoration: BoxDecoration(
        color: color.withValues(alpha: AppOpacity.o10),
        borderRadius: BorderRadius.circular(AppSizes.radiusXXS),
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
          // NestedScrollView 내부에서는 Center 대신 CustomScrollView 사용
          return CustomScrollView(
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: MingrrEmptyState(
                    icon: Icons.event_outlined,
                    title: '일정이 없어요',
                    subtitle: isJoined ? '새로운 일정을 만들어보세요' : '예정된 일정이 없습니다',
                  ),
                ),
              ),
            ],
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSizes.paddingL),
          itemCount: schedules.length,
          itemBuilder: (context, index) {
            final schedule = schedules[index];
            final isPast = schedule.isPast;

            return Container(
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
                          borderRadius: BorderRadius.circular(AppSizes.radiusXXS),
                        ),
                        child: Text(
                          isPast ? '종료' : '예정',
                          style: AppTextStyles.labelMedium(context).copyWith(
                            color: isPast ? colorScheme.onSurfaceVariant : accentColor,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${schedule.participantCount}명 참여',
                        style: AppTextStyles.caption(context),
                      ),
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
                      Icon(Icons.calendar_today, size: 14, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: AppSizes.gapSM),
                      Text(
                        _formatScheduleDate(schedule.startTime),
                        style: AppTextStyles.bodySmall(context),
                      ),
                    ],
                  ),
                  if (schedule.place != null) ...[
                    const SizedBox(height: AppSizes.gapSM),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 14, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: AppSizes.gapSM),
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
      error: (_, __) => MingrrErrorState(
        onRetry: () => ref.invalidate(groupSchedulesProvider(group.id)),
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
                child: Icon(Icons.chat_bubble_outline, color: accentColor),
              ),
            ),
            const SizedBox(width: AppSizes.gapM),
          ],
          // 메인 버튼
          Expanded(
            child: MingrrButton(
              text: isJoined
                  ? (isCreator ? '모임 관리' : '모임 탈퇴')
                  : (group.requireApproval ? '가입 신청' : '모임 가입'),
              onPressed: _isJoining
                  ? null
                  : isJoined
                      ? (isCreator ? () => _showCreatorOptions(context, group) : () => _leaveGroup(group))
                      : () => _joinGroup(group),
              isLoading: _isJoining,
              backgroundColor: isJoined && !isCreator ? Colors.red : accentColor,
              textColor: Colors.white,
              height: 56,
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
    final firestoreService = FirestoreService();
    final firebase = FirebaseService();
    final myUserId = firebase.currentUserId ?? '';

    showMingrrBottomSheet(
      context: context,
      title: '가입 신청 관리',
      height: 0.7,
      child: StreamBuilder<List<GroupJoinRequestModel>>(
        stream: firestoreService.watchPendingJoinRequests(group.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: MingrrLoadingIndicator());
          }

          final requests = snapshot.data ?? [];

          if (requests.isEmpty) {
            return const MingrrEmptyState(
              icon: Icons.person_add_disabled,
              title: '대기 중인 신청이 없어요',
              subtitle: '새로운 가입 신청이 들어오면 여기에 표시됩니다',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingS),
            itemCount: requests.length,
            separatorBuilder: (_, __) => const MingrrDivider(),
            itemBuilder: (context, index) {
              final request = requests[index];
              return _JoinRequestTile(
                request: request,
                groupId: group.id,
                myUserId: myUserId,
                firestoreService: firestoreService,
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

/// 가입 신청 타일 위젯
class _JoinRequestTile extends StatefulWidget {
  final GroupJoinRequestModel request;
  final String groupId;
  final String myUserId;
  final FirestoreService firestoreService;

  const _JoinRequestTile({
    required this.request,
    required this.groupId,
    required this.myUserId,
    required this.firestoreService,
  });

  @override
  State<_JoinRequestTile> createState() => _JoinRequestTileState();
}

class _JoinRequestTileState extends State<_JoinRequestTile> {
  UserModel? _user;
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final user = await widget.firestoreService.getUser(widget.request.userId);
      if (mounted) {
        setState(() {
          _user = user;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _approve() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      await widget.firestoreService.approveJoinRequest(
        requestId: widget.request.id,
        groupId: widget.groupId,
        userId: widget.request.userId,
        respondedBy: widget.myUserId,
      );
      if (mounted) {
        MingrrSnackBar.success(context, '${_user?.nickname ?? '사용자'}님의 가입을 승인했습니다');
      }
    } catch (e) {
      if (mounted) {
        MingrrSnackBar.error(context, '승인 실패: $e');
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _reject() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      await widget.firestoreService.rejectJoinRequest(
        requestId: widget.request.id,
        respondedBy: widget.myUserId,
      );
      if (mounted) {
        MingrrSnackBar.info(context, '${_user?.nickname ?? '사용자'}님의 가입을 거절했습니다');
      }
    } catch (e) {
      if (mounted) {
        MingrrSnackBar.error(context, '거절 실패: $e');
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const ListTile(
        leading: CircleAvatar(child: Icon(Icons.person)),
        title: Text('로딩 중...'),
      );
    }

    final theme = Theme.of(context);
    final timeAgo = _formatTimeAgo(widget.request.createdAt);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingM,
        vertical: AppSizes.paddingS,
      ),
      leading: MingrrAvatar(
        imageUrl: _user?.profileImageUrl,
        size: 48,
        placeholderIcon: Icons.person,
      ),
      title: Row(
        children: [
          Text(
            _user?.nickname ?? '알 수 없음',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(width: AppSizes.gapS),
          Text(
            timeAgo,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
      subtitle: widget.request.message != null && widget.request.message!.isNotEmpty
          ? Padding(
              padding: const EdgeInsets.only(top: AppSizes.paddingXS),
              child: Text(
                widget.request.message!,
                style: theme.textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            )
          : null,
      trailing: _isProcessing
          ? const MingrrLoadingIndicator(
              size: 24,
              strokeWidth: 2,
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.close, color: theme.colorScheme.error),
                  onPressed: _reject,
                  tooltip: '거절',
                ),
                const SizedBox(width: AppSizes.gapXS),
                IconButton(
                  icon: Icon(Icons.check, color: theme.colorScheme.primary),
                  onPressed: _approve,
                  tooltip: '승인',
                ),
              ],
            ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 0) return '${diff.inDays}일 전';
    if (diff.inHours > 0) return '${diff.inHours}시간 전';
    if (diff.inMinutes > 0) return '${diff.inMinutes}분 전';
    return '방금 전';
  }
}
