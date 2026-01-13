import 'package:flutter/material.dart';
import '../services/bottom_sheet_stack_manager.dart';
import '../theme/feature_colors.dart';
import '../constants/app_sizes.dart';
import 'guardian_profile_modal.dart';
import 'mingrr_bottom_sheet.dart';
import 'warmth_score.dart';

/// ============================================================
/// 소모임 프로필 모달
/// 
/// 소모임 채팅에서 소모임 정보를 표시할 때 사용
/// ============================================================

/// 소모임 멤버 정보
class CommunityMember {
  final String id;
  final String nickname;
  final double kkosunnaeScore;
  final bool isOnline;

  const CommunityMember({
    required this.id,
    required this.nickname,
    this.kkosunnaeScore = 50.0,
    this.isOnline = false,
  });
}

/// 소모임 프로필 모달 표시 함수
void showCommunityProfileModal(
  BuildContext context, {
  required String communityId,
  required String communityName,
  String? description,
  int memberCount = 0,
  String? category,
  String? location,
  String? createdAt,
  List<String> tags = const [],
  bool isJoined = true,
  List<CommunityMember> members = const [],
}) {
  final stackManager = BottomSheetStackManager();
  final sheetId = BottomSheetStackManager.createSheetId(BottomSheetType.community, communityId);
  
  // 순환 감지: 같은 소모임 바텀시트가 이미 열려있으면 해당 바텀시트까지 닫기
  if (stackManager.hasCycle(sheetId)) {
    final closeCount = stackManager.popUntilAndGetCount(sheetId);
    for (int i = 0; i < closeCount; i++) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
  }
  
  // 스택에 등록
  stackManager.push(sheetId);
  
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => CommunityProfileModal(
      communityId: communityId,
      communityName: communityName,
      description: description,
      memberCount: memberCount,
      category: category,
      location: location,
      createdAt: createdAt,
      tags: tags,
      isJoined: isJoined,
      members: members,
    ),
  ).then((_) {
    // 바텀시트가 닫힐 때 스택에서 제거
    stackManager.pop(sheetId);
  });
}

/// 소모임 프로필 모달 위젯
class CommunityProfileModal extends StatelessWidget {
  final String communityId;
  final String communityName;
  final String? description;
  final int memberCount;
  final String? category;
  final String? location;
  final String? createdAt;
  final List<String> tags;
  final bool isJoined;
  final List<CommunityMember> members;

  const CommunityProfileModal({
    super.key,
    required this.communityId,
    required this.communityName,
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
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BottomSheetHandle(),
          // 헤더
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL, vertical: 8),
            child: const Text(
              '소모임 정보',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ),
          
          // 본문
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 소모임 기본 정보
                  _buildCommunityInfo(context),
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
            ),
          ),
        ],
      ),
    );
  }

  /// 멤버 리스트 섹션
  Widget _buildMembersSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '참여 멤버 (${members.length})',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSizes.gapS),
        ...members.take(5).map((member) => _buildMemberItem(context, member)),
        if (members.length > 5)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Center(
              child: Text(
                '외 ${members.length - 5}명',
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outlineVariant),
              ),
            ),
          ),
      ],
    );
  }

  /// 멤버 아이템 (클릭 시 보호자 프로필)
  Widget _buildMemberItem(BuildContext context, CommunityMember member) {
    return GestureDetector(
      onTap: () {
        // 스택 방식: 현재 바텀시트 위에 보호자 정보 바텀시트를 열음
        // 보호자 정보 바텀시트를 닫으면 현재 소모임 정보 바텀시트가 보임
        showGuardianProfileModal(
          context,
          guardianId: member.id,
          guardianName: member.nickname,
          kkosunnaeScore: member.kkosunnaeScore,
          gender: GuardianGender.unknown,
          isIdentityVerified: true,
          isPetVerified: true,
          isLocationVerified: false,
          pets: [
            GuardianPetInfo(
              id: 'pet_${member.id}',
              name: '멍멍이',
              breed: '골든 리트리버',
              ageString: '3살',
              likeCount: 42,
            ),
          ],
          activityInfo: const GuardianActivityInfo(
            walkCount: 85,
            datingCount: 12,
            marketCount: 5,
            communityCount: 18,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person, size: 20, color: Theme.of(context).colorScheme.primary),
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
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.nickname,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  KkosunnaeScoreSmall(score: member.kkosunnaeScore),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: Theme.of(context).colorScheme.outlineVariant),
          ],
        ),
      ),
    );
  }

  /// 소모임 기본 정보
  Widget _buildCommunityInfo(BuildContext context) {
    return Row(
      children: [
        // 프로필 이미지
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: context.features.community.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.groups,
            size: 35,
            color: context.features.community,
          ),
        ),
        const SizedBox(width: AppSizes.gapM),
        
        // 정보
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                communityName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.people, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    '멤버 $memberCount명',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (category != null) ...[
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: context.features.community.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        category!,
                        style: TextStyle(
                          fontSize: 11,
                          color: context.features.community,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 태그
  Widget _buildTags(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '관심사',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSizes.gapS),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tags.map((tag) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: context.features.community.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '#$tag',
              style: TextStyle(
                fontSize: 13,
                color: context.features.community,
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }

  /// 소개
  Widget _buildDescription(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '소개',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSizes.gapS),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            description!,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  /// 상세 정보
  Widget _buildDetails(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '상세 정보',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSizes.gapS),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              if (location != null)
                _buildDetailRow(context, Icons.location_on, '활동 지역', location!),
              if (createdAt != null) ...[
                if (location != null) const Divider(height: 16),
                _buildDetailRow(context, Icons.calendar_today, '개설일', createdAt!),
              ],
              const Divider(height: 16),
              _buildDetailRow(
                context,
                Icons.check_circle,
                '가입 상태',
                isJoined ? '가입됨' : '미가입',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
