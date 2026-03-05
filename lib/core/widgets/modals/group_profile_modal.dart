import 'package:flutter/material.dart';
import '../../constants/app_icons.dart';
import '../../services/bottom_sheet_stack_manager.dart';
import '../../theme/feature_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../constants/app_sizes.dart';
import '../dividers/app_dividers.dart';
import 'guardian_profile_modal.dart';
import 'profile_modal_components.dart';

/// ============================================================
/// 소모임(Group) 프로필 모달
/// 
/// 소모임 채팅에서 소모임 정보를 표시할 때 사용
/// ============================================================

/// 소모임 멤버 정보
class GroupMember {
  final String id;
  final String nickname;
  final double kkosunnaeScore;
  final bool isOnline;
  final bool isCreator; // 모임장 여부

  const GroupMember({
    required this.id,
    required this.nickname,
    this.kkosunnaeScore = 50.0,
    this.isOnline = false,
    this.isCreator = false,
  });
}

/// 소모임 프로필 모달 표시 함수
void showGroupProfileModal(
  BuildContext context, {
  required String groupId,
  required String groupName,
  String? description,
  int memberCount = 0,
  String? category,
  String? location,
  String? createdAt,
  List<String> tags = const [],
  bool isJoined = true,
  List<GroupMember> members = const [],
}) {
  showStackedProfileModal(
    context: context,
    type: BottomSheetType.group,
    id: groupId,
    builder: (sheetContext) => GroupProfileModal(
      groupId: groupId,
      groupName: groupName,
      description: description,
      memberCount: memberCount,
      category: category,
      location: location,
      createdAt: createdAt,
      tags: tags,
      isJoined: isJoined,
      members: members,
    ),
  );
}

/// 소모임 프로필 모달 위젯
class GroupProfileModal extends StatelessWidget {
  final String groupId;
  final String groupName;
  final String? description;
  final int memberCount;
  final String? category;
  final String? location;
  final String? createdAt;
  final List<String> tags;
  final bool isJoined;
  final List<GroupMember> members;

  const GroupProfileModal({
    super.key,
    required this.groupId,
    required this.groupName,
    this.description,
    this.memberCount = 0,
    this.category,
    this.location,
    this.createdAt,
    this.tags = const [],
    this.isJoined = true,
    this.members = const [],
  });

  @override
  Widget build(BuildContext context) {
    return ProfileModalContainer(
      title: '소모임 정보',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 소모임 기본 정보
          _buildGroupInfo(context),
          const SizedBox(height: AppSizes.gapL),
          
          // 태그
          if (tags.isNotEmpty) ...[
            _buildTags(context),
            const SizedBox(height: AppSizes.gapL),
          ],
          
          // 소개
          if (description != null && description!.isNotEmpty) ...[
            _buildDescription(context),
            const SizedBox(height: AppSizes.gapL),
          ],
          
          // 멤버 리스트
          if (members.isNotEmpty) ...[
            _buildMembersSection(context),
            const SizedBox(height: AppSizes.gapL),
          ],
          
          // 상세 정보
          _buildDetails(context),
        ],
      ),
    );
  }

  /// 멤버 리스트 섹션
  Widget _buildMembersSection(BuildContext context) {
    return ProfileModalSection(
      title: '참여 멤버',
      count: '${members.length}명',
      content: ProfileModalHorizontalList<GroupMember>(
        items: members,
        height: 120,
        itemSpacing: 12,
        itemBuilder: (context, member, index) => _buildMemberItem(context, member),
      ),
    );
  }

  /// 멤버 아이템
  Widget _buildMemberItem(BuildContext context, GroupMember member) {
    return ProfileModalItemCard(
      width: 100,
      avatar: Stack(
        children: [
          ProfileModalAvatar(
            size: 50,
            fallbackIcon: AppIcons.profile,
          ),
          if (member.isOnline)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: context.features.success,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: member.nickname,
      subtitleWidget: null,
      badge: member.isCreator ? _buildCreatorBadge(context) : null,
      onTap: () => _openMemberProfile(context, member),
    );
  }

  /// 모임장 배지
  Widget _buildCreatorBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingXS, vertical: AppSizes.paddingXXS),
      decoration: BoxDecoration(
        color: context.features.social,
        borderRadius: BorderRadius.circular(AppSizes.radiusS),
      ),
      child: Text(
        '모임장',
        style: AppTextStyles.captionSmall(context).withColor(Colors.white),
      ),
    );
  }

  /// 멤버 프로필 모달 열기
  void _openMemberProfile(BuildContext context, GroupMember member) {
    showGuardianProfileFromFirestore(
      context,
      userId: member.id,
      fallbackName: member.nickname,
      fallbackScore: member.kkosunnaeScore,
    );
  }

  /// 소모임 기본 정보
  Widget _buildGroupInfo(BuildContext context) {
    return ProfileModalHeader(
      avatar: ProfileModalAvatar(
        fallbackIcon: AppIcons.group,
        backgroundColor: context.features.social.withValues(alpha: AppOpacity.o10),
        iconColor: context.features.social,
      ),
      name: groupName,
      subtitle: category != null ? _buildCategoryBadge(context) : null,
    );
  }

  /// 카테고리 배지
  Widget _buildCategoryBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingS, vertical: AppSizes.paddingXXS),
      decoration: BoxDecoration(
        color: context.features.social.withValues(alpha: AppOpacity.o10),
        borderRadius: BorderRadius.circular(AppSizes.radiusS),
      ),
      child: Text(
        category!,
        style: AppTextStyles.labelMedium(context).copyWith(color: context.features.social),
      ),
    );
  }

  /// 태그
  Widget _buildTags(BuildContext context) {
    return ProfileModalSection(
      title: '관심사',
      content: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: tags.map((tag) => Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM, vertical: AppSizes.paddingXS),
          decoration: BoxDecoration(
            color: context.features.social.withValues(alpha: AppOpacity.o10),
            borderRadius: BorderRadius.circular(AppSizes.radiusM),
          ),
          child: Text(
            '#$tag',
            style: AppTextStyles.bodySmall(context).copyWith(color: context.features.social),
          ),
        )).toList(),
      ),
    );
  }

  /// 소개
  Widget _buildDescription(BuildContext context) {
    return ProfileModalSection(
      title: '소개',
      content: ProfileModalDescriptionBox(text: description!),
    );
  }

  /// 상세 정보
  Widget _buildDetails(BuildContext context) {
    return ProfileModalSection(
      title: '상세 정보',
      content: ProfileModalDetailsBox(
        children: [
          if (location != null)
            ProfileModalDetailRow(icon: AppIcons.location, label: '활동 지역', value: location!),
          if (createdAt != null) ...[
            if (location != null) const MingrrDivider.section(),
            ProfileModalDetailRow(icon: AppIcons.calendar, label: '개설일', value: createdAt!),
          ],
          const MingrrDivider.section(),
          ProfileModalDetailRow(
            icon: AppIcons.checkCircle,
            label: '가입 상태',
            value: isJoined ? '가입됨' : '미가입',
          ),
        ],
      ),
    );
  }
}
