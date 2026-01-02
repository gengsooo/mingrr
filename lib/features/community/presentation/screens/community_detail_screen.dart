import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
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
      backgroundColor: Colors.white,
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
      backgroundColor: AppColors.community,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
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
          onPressed: () {
            // TODO: 소모임 공유 기능 구현 예정
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
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.community.withOpacity(0.8),
                AppColors.community,
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
            color: AppColors.community.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            data['category'],
            style: const TextStyle(fontSize: 12, color: AppColors.community),
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
            const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              data['location'],
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(width: 16),
            const Icon(Icons.people_outline, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              '${data['memberCount']}/${data['maxMembers']}명',
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
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
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.person, size: 24, color: AppColors.primary),
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
                        color: AppColors.community,
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
          const Icon(Icons.chevron_right, color: AppColors.textHint),
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
      dogs: [
        GuardianDogInfo(
          id: 'dog_1',
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
        Text(
          data['description'],
          style: const TextStyle(fontSize: 14, height: 1.6, color: AppColors.textPrimary),
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
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.community.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.calendar_today, color: AppColors.community),
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
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
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
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
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
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(Icons.person, size: 24, color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        memberName,
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
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
      dogs: [
        GuardianDogInfo(
          id: 'dog_$index',
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
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(isJoined ? '모임에서 탈퇴했습니다.' : '모임에 가입했습니다! 🎉'),
                backgroundColor: AppColors.community,
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isJoined ? AppColors.divider : AppColors.community,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            isJoined ? '모임 탈퇴하기' : '모임 가입하기',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isJoined ? AppColors.textSecondary : Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  /// 더보기 옵션 메뉴
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
              leading: const Icon(Icons.notifications_off_outlined),
              title: const Text('알림 끄기'),
              onTap: () => Navigator.pop(context),
            ),
            if (_isJoined)
              ListTile(
                leading: const Icon(Icons.exit_to_app, color: AppColors.error),
                title: const Text('모임 탈퇴하기', style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(context);
                  _showLeaveConfirmDialog(context);
                },
              ),
            ListTile(
              leading: const Icon(Icons.report_outlined, color: AppColors.error),
              title: const Text('신고하기', style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.pop(context);
                showReportSheet(
                  context,
                  targetId: widget.communityId,
                  targetName: '이 모임',
                  targetType: ReportTargetType.community,
                );
              },
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  /// 탈퇴 확인 다이얼로그
  void _showLeaveConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('모임 탈퇴'),
        content: const Text('정말 이 모임에서 탈퇴하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _isJoined = false);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('모임에서 탈퇴했습니다.'),
                  backgroundColor: AppColors.community,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('탈퇴하기', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
