import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/feature_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/dialogs/dialogs.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/mingrr_bottom_sheet.dart';
import '../../../../core/widgets/report_sheet.dart';
import '../../../../core/widgets/warmth_score.dart';
import '../../../../core/widgets/guardian_profile_modal.dart';

/// ============================================================
/// 소모임 상세 화면
/// 
/// 소모임 클릭 시 표시
/// - 모임 이미지/배너
/// - 모임 정보 (이름, 설명, 멤버 수)
/// - 모임장 정보
/// - 가입하기 버튼
/// - 신고 기능
/// ============================================================

class CommunityDetailScreen extends StatefulWidget {
  final String communityId;
  final bool isJoined;

  const CommunityDetailScreen({
    super.key,
    required this.communityId,
    this.isJoined = false,
  });

  @override
  State<CommunityDetailScreen> createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends State<CommunityDetailScreen> {
  late bool _isJoined;

  @override
  void initState() {
    super.initState();
    _isJoined = widget.isJoined;
  }

  @override
  Widget build(BuildContext context) {
    final communityData = _getDemoData();

    return Scaffold(
      backgroundColor: context.detailBackground,
      body: CustomScrollView(
        slivers: [
          // 이미지 헤더
          _buildImageHeader(context, communityData),
          
          // 본문 컨텐츠
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.paddingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 모임 정보
                  _buildCommunityInfo(communityData),
                  const SizedBox(height: AppSizes.gapXL),
                  
                  // 모임장 정보
                  _buildLeaderInfo(context, communityData),
                  const Divider(height: 32),
                  
                  // 모임 소개
                  _buildDescription(communityData),
                  const SizedBox(height: AppSizes.gapXL),
                  
                  // 활동 정보
                  _buildActivityInfo(communityData),
                  const SizedBox(height: AppSizes.gapXL),
                  
                  // 최근 멤버
                  _buildRecentMembers(context, communityData),
                  
                  // 하단 여백 (버튼 공간)
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      // 하단 고정 버튼
      bottomNavigationBar: _buildBottomButton(context, communityData),
    );
  }

  /// 데모 데이터
  Map<String, dynamic> _getDemoData() {
    return {
      'name': '한강 산책 모임',
      'description': '한강에서 함께 산책하는 모임입니다.\n매주 토요일 오전 10시에 만나요!',
      'category': '산책',
      'location': '서울 영등포구',
      'memberCount': 28,
      'maxMembers': 50,
      'createdAt': '2024년 1월',
      'meetingDay': '매주 토요일',
      'meetingTime': '오전 10시',
      'leader': {
        'nickname': '뽀삐맘',
        'warmthScore': 42.5,
      },
      'recentMembers': ['초코맘', '몽이아빠', '코코언니', '두부맘', '콩이아빠'],
      'isJoined': _isJoined,
    };
  }

  /// 이미지 헤더
  Widget _buildImageHeader(BuildContext context, Map<String, dynamic> data) {
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
            child: const Icon(Icons.share, color: Colors.white, size: 20),
          ),
          onPressed: () => _shareGroup(context, data),
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
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                context.features.community.withOpacity(0.8),
                context.features.community,
              ],
            ),
          ),
          child: const Center(
            child: Icon(Icons.groups, size: 80, color: Colors.white),
          ),
        ),
      ),
    );
  }

  /// 모임 정보
  Widget _buildCommunityInfo(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 카테고리
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: context.features.community.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            data['category'],
            style: TextStyle(fontSize: 12, color: context.features.community),
          ),
        ),
        const SizedBox(height: 12),
        // 모임 이름
        Text(
          data['name'],
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        // 위치, 멤버 수
        Row(
          children: [
            Icon(Icons.location_on_outlined, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              data['location'],
              style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(width: 16),
            Icon(Icons.people_outline, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              '${data['memberCount']}/${data['maxMembers']}명',
              style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ],
    );
  }

  /// 모임장 정보
  Widget _buildLeaderInfo(BuildContext context, Map<String, dynamic> data) {
    final leader = data['leader'] as Map<String, dynamic>;
    final kkosunnaeScore = (leader['kkosunnaeScore'] as num?)?.toDouble() ?? 50.0;
    
    return GestureDetector(
      onTap: () => _showLeaderProfile(context, leader),
      child: Row(
        children: [
          // 아이콘 (강아지 앱이므로 사진 대신)
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(Icons.person, size: 24, color: Theme.of(context).colorScheme.primary),
            ),
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
                      leader['nickname'],
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: context.features.community,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '모임장',
                        style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                KkosunnaeScoreSmall(score: kkosunnaeScore),
              ],
            ),
          ),
          // 화살표
          Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.outlineVariant),
        ],
      ),
    );
  }

  /// 모임장 프로필 모달 표시
  void _showLeaderProfile(BuildContext context, Map<String, dynamic> leader) {
    showGuardianProfileModal(
      context,
      guardianId: leader['id'] ?? 'leader_1',
      guardianName: leader['nickname'] ?? '모임장',
      kkosunnaeScore: (leader['kkosunnaeScore'] as num?)?.toDouble() ?? 50.0,
      isIdentityVerified: true,
      isPetVerified: true,
      isLocationVerified: true,
      pets: [
        GuardianPetInfo(
          id: 'pet_1',
          name: '뽀삐',
          breed: '골든 리트리버',
          ageString: '3살',
          likeCount: 42,
        ),
      ],
      activityInfo: const GuardianActivityInfo(
        walkCount: 156,
        datingCount: 22,
        marketCount: 15,
        communityCount: 48,
      ),
    );
  }

  /// 모임 소개
  Widget _buildDescription(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '모임 소개',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.sectionBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            data['description'],
            style: TextStyle(fontSize: 14, height: 1.6, color: Theme.of(context).colorScheme.onSurface),
          ),
        ),
      ],
    );
  }

  /// 활동 정보
  Widget _buildActivityInfo(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '정기 모임',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.sectionBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: context.features.community.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.calendar_today, color: context.features.community),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['meetingDay'],
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data['meetingTime'],
                    style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 최근 멤버
  Widget _buildRecentMembers(BuildContext context, Map<String, dynamic> data) {
    final members = data['recentMembers'] as List<String>;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '멤버',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Text(
              '${data['memberCount']}명',
              style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 70,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: members.length,
            itemBuilder: (context, index) {
              final memberName = members[index];
              return GestureDetector(
                onTap: () => _showMemberProfile(context, memberName, index),
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(Icons.person, size: 24, color: Theme.of(context).colorScheme.primary),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        memberName,
                        style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// 멤버 프로필 모달 표시
  void _showMemberProfile(BuildContext context, String memberName, int index) {
    showGuardianProfileModal(
      context,
      guardianId: 'member_$index',
      guardianName: memberName,
      kkosunnaeScore: 45.0 + (index * 5),
      isIdentityVerified: index % 2 == 0,
      isPetVerified: true,
      isLocationVerified: index % 3 == 0,
      pets: [
        GuardianPetInfo(
          id: 'pet_$index',
          name: index == 0 ? '초코' : '콩이',
          breed: index == 0 ? '말티즈' : '포메라니안',
          ageString: '${2 + index}살',
          likeCount: 15 + (index * 8),
        ),
      ],
      activityInfo: GuardianActivityInfo(
        walkCount: 50 + (index * 20),
        datingCount: 5 + index,
        marketCount: 3 + index,
        communityCount: 10 + (index * 5),
      ),
    );
  }

  /// 하단 고정 버튼
  Widget _buildBottomButton(BuildContext context, Map<String, dynamic> data) {
    final isJoined = data['isJoined'] as bool;
    
    return MingrrBottomButtonBar(
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: () {
            if (isJoined) {
              // 탈퇴 시 확인 바텀시트 표시
              showConfirmSheet(
                context,
                type: ConfirmSheetType.groupLeave,
                onConfirm: () {
                  Navigator.pop(context);
                  MingrrSnackBar.success(context, '모임에서 탈퇴했습니다.');
                },
              );
            } else {
              // 가입 시 바로 처리
              Navigator.pop(context);
              MingrrSnackBar.success(context, '모임에 가입했습니다! 🎉');
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isJoined ? Colors.red : context.features.community,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            isJoined ? '모임 탈퇴하기' : '모임 가입하기',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  /// 더보기 옵션 메뉴
  void _showMoreOptions(BuildContext context) {
    showMingrrOptionsSheet(
      context: context,
      options: [
        MingrrOptionItem(
          icon: Icons.notifications_off_outlined,
          label: '알림 끄기',
          onTap: () {},
        ),
        if (_isJoined)
          MingrrOptionItem(
            icon: Icons.exit_to_app,
            label: '모임 탈퇴하기',
            isDestructive: true,
            onTap: () => _showLeaveConfirmDialog(context),
          ),
        MingrrOptionItem(
          icon: Icons.report_outlined,
          label: '신고하기',
          isDestructive: true,
          onTap: () {
            showReportSheet(
              context,
              targetId: widget.communityId,
              targetName: '이 모임',
              targetType: ReportTargetType.group,
            );
          },
        ),
      ],
    );
  }

  /// 탈퇴 확인 바텀시트
  void _showLeaveConfirmDialog(BuildContext context) {
    showConfirmSheet(
      context,
      type: ConfirmSheetType.groupLeave,
      onConfirm: () {
        setState(() => _isJoined = false);
        Navigator.pop(context);
        MingrrSnackBar.success(context, '모임에서 탈퇴했습니다.');
      },
    );
  }
  
  /// 소모임 공유
  void _shareGroup(BuildContext context, Map<String, dynamic> data) {
    final text = '${data['name']}\n'
        '${data['description']}\n\n'
        '멤버 ${data['memberCount']}명이 함께하고 있어요!\n'
        'MINGRR에서 확인하기:\nhttps://mingrr.app/group/${widget.communityId}';
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.bottomSheetRadius)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BottomSheetHandle(),
            const Text(
              '공유하기',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildShareOption(
                  icon: Icons.copy,
                  label: '링크 복사',
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(text: text));
                    if (context.mounted) {
                      Navigator.pop(context);
                      MingrrSnackBar.success(context, '복사되었습니다');
                    }
                  },
                ),
                _buildShareOption(
                  icon: Icons.chat_bubble,
                  label: '카카오톡',
                  onTap: () {
                    Navigator.pop(context);
                    MingrrSnackBar.info(context, '카카오톡 공유는 SDK 설정 후 사용 가능합니다');
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                text,
                style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 10),
          ],
        ),
      ),
    );
  }
  
  Widget _buildShareOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 24, color: Theme.of(context).colorScheme.onSurface),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface),
          ),
        ],
      ),
    );
  }
}
