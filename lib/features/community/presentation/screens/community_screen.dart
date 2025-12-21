import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/common_widgets.dart';

/// ============================================================
/// 커뮤니티 화면
/// 소모임, 클래스, 오프라인 활동 기능
/// 유저 리텐션을 위한 커뮤니티 기능
/// ============================================================
class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('커뮤니티'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: 검색
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '소모임'),
            Tab(text: '클래스'),
          ],
          indicatorColor: AppColors.community,
          labelColor: AppColors.community,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGroupsTab(),
          _buildClassesTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showCreateGroupSheet();
        },
        backgroundColor: AppColors.community,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          '모임 만들기',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  /// 소모임 탭
  Widget _buildGroupsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 카테고리 필터
          _buildCategoryFilter(),
          
          const SizedBox(height: AppSizes.gapL),
          
          // 내 모임
          const MingrrSectionHeader(
            title: '내 모임',
            actionText: '전체보기',
          ),
          const SizedBox(height: AppSizes.gapM),
          _buildMyGroups(),
          
          const SizedBox(height: AppSizes.gapXL),
          
          // 추천 모임
          const MingrrSectionHeader(
            title: '추천 모임',
            actionText: '전체보기',
          ),
          const SizedBox(height: AppSizes.gapM),
          
          ...List.generate(5, (index) => _buildGroupCard(index)),
        ],
      ),
    );
  }

  /// 카테고리 필터
  Widget _buildCategoryFilter() {
    final categories = [
      {'icon': Icons.all_inclusive, 'label': '전체'},
      {'icon': Icons.directions_walk, 'label': '산책'},
      {'icon': Icons.school, 'label': '훈련'},
      {'icon': Icons.celebration, 'label': '친목'},
      {'icon': Icons.cookie, 'label': '수제간식'},
      {'icon': Icons.health_and_safety, 'label': '건강'},
    ];

    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = index == 0;
          
          return Container(
            width: 70,
            margin: const EdgeInsets.only(right: AppSizes.gapS),
            child: Column(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.community
                        : AppColors.community.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    cat['icon'] as IconData,
                    color: isSelected ? Colors.white : AppColors.community,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  cat['label'] as String,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? AppColors.community
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 내 모임 가로 스크롤
  Widget _buildMyGroups() {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (context, index) {
          return Container(
            width: 200,
            margin: const EdgeInsets.only(right: AppSizes.gapM),
            child: MingrrCard(
              margin: EdgeInsets.zero,
              onTap: () {
                // TODO: 모임 상세
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.community.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.groups,
                          color: AppColors.community,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppSizes.gapS),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ['한강 산책 모임', '수제 간식 클럽', '강남 댕댕이'][index],
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '멤버 ${(index + 1) * 12}명',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '다음 일정: ${['토요일 오후 2시', '일요일 오전 10시', '금요일 저녁 7시'][index]}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// 모임 카드
  Widget _buildGroupCard(int index) {
    final groups = [
      {
        'name': '주말 한강 산책 모임',
        'type': '산책 모임',
        'members': 28,
        'location': '서울 영등포구',
        'description': '매주 주말 한강에서 함께 산책해요! 🐕',
      },
      {
        'name': '강아지 수제 간식 만들기',
        'type': '수제 간식',
        'members': 15,
        'location': '서울 강남구',
        'description': '건강한 수제 간식을 함께 만들어봐요 🍪',
      },
      {
        'name': '소형견 친목 모임',
        'type': '친목 모임',
        'members': 42,
        'location': '서울 마포구',
        'description': '소형견 친구들 모여라! 🐩',
      },
      {
        'name': '반려견 훈련 스터디',
        'type': '훈련/교육',
        'members': 18,
        'location': '서울 송파구',
        'description': '함께 훈련 팁을 공유해요 📚',
      },
      {
        'name': '시니어 반려견 케어 모임',
        'type': '건강/케어',
        'members': 23,
        'location': '서울 서초구',
        'description': '노령견 케어 정보를 나눠요 💝',
      },
    ];

    final group = groups[index];

    return MingrrCard(
      margin: const EdgeInsets.only(bottom: AppSizes.gapM),
      onTap: () {
        // TODO: 모임 상세 페이지
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 모임 이미지
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.community.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppSizes.radiusM),
                ),
                child: const Icon(
                  Icons.groups,
                  color: AppColors.community,
                  size: 30,
                ),
              ),
              const SizedBox(width: AppSizes.gapM),
              
              // 모임 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.community.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            group['type'] as String,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.community,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      group['name'] as String,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 12,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          group['location'] as String,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.people,
                          size: 12,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${group['members']}명',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.gapM),
          Text(
            group['description'] as String,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSizes.gapM),
          
          // 멤버 아바타
          Row(
            children: [
              SizedBox(
                width: 80,
                height: 28,
                child: Stack(
                  children: List.generate(3, (i) {
                    return Positioned(
                      left: i * 18.0,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.pets,
                          size: 14,
                          color: AppColors.primary,
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: () {
                  // TODO: 가입 신청
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.community,
                  side: const BorderSide(color: AppColors.community),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                child: const Text('가입하기'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 클래스 탭
  Widget _buildClassesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 진행 중인 클래스
          const MingrrSectionHeader(
            title: '진행 중인 클래스',
            actionText: '전체보기',
          ),
          const SizedBox(height: AppSizes.gapM),
          
          ...List.generate(4, (index) => _buildClassCard(index)),
        ],
      ),
    );
  }

  /// 클래스 카드
  Widget _buildClassCard(int index) {
    final classes = [
      {
        'title': '강아지 수제 간식 만들기 클래스',
        'instructor': '김쿠키',
        'date': '2024.01.27 (토) 14:00',
        'location': '서울 강남구',
        'price': '35,000원',
        'spots': '3자리 남음',
      },
      {
        'title': '반려견 기초 훈련 클래스',
        'instructor': '박트레이너',
        'date': '2024.01.28 (일) 10:00',
        'location': '서울 송파구',
        'price': '50,000원',
        'spots': '5자리 남음',
      },
      {
        'title': '펫 마사지 배우기',
        'instructor': '이힐링',
        'date': '2024.02.03 (토) 15:00',
        'location': '서울 마포구',
        'price': '40,000원',
        'spots': '2자리 남음',
      },
      {
        'title': '반려견 사진 잘 찍는 법',
        'instructor': '최포토',
        'date': '2024.02.04 (일) 13:00',
        'location': '서울 성동구',
        'price': '30,000원',
        'spots': '8자리 남음',
      },
    ];

    final classInfo = classes[index];

    return MingrrCard(
      margin: const EdgeInsets.only(bottom: AppSizes.gapM),
      onTap: () {
        // TODO: 클래스 상세
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 이미지 영역
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.community.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusM),
            ),
            child: Stack(
              children: [
                const Center(
                  child: Icon(
                    Icons.class_,
                    size: 50,
                    color: AppColors.community,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      classInfo['spots'] as String,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.gapM),
          
          // 클래스 정보
          Text(
            classInfo['title'] as String,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.person, size: 14, color: AppColors.textHint),
              const SizedBox(width: 4),
              Text(
                classInfo['instructor'] as String,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 14, color: AppColors.textHint),
              const SizedBox(width: 4),
              Text(
                classInfo['date'] as String,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on, size: 14, color: AppColors.textHint),
              const SizedBox(width: 4),
              Text(
                classInfo['location'] as String,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.gapM),
          
          // 가격 및 신청 버튼
          Row(
            children: [
              Text(
                classInfo['price'] as String,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.community,
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  // TODO: 클래스 신청
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.community,
                  foregroundColor: Colors.white,
                ),
                child: const Text('신청하기'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 모임 만들기 바텀시트
  void _showCreateGroupSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSizes.radiusXL),
          ),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSizes.paddingM),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      '모임 만들기',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('모임이 생성되었습니다!'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    },
                    child: const Text('완료'),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSizes.paddingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 모임 이미지
                    Center(
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(AppSizes.radiusL),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt, color: AppColors.textHint),
                            SizedBox(height: 4),
                            Text(
                              '대표 이미지',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textHint,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: AppSizes.gapXL),
                    
                    const MingrrTextField(
                      labelText: '모임 이름',
                      hintText: '모임 이름을 입력해주세요',
                    ),
                    
                    const SizedBox(height: AppSizes.gapL),
                    
                    const Text(
                      '카테고리',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSizes.gapS),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildGroupTypeChip('산책 모임'),
                        _buildGroupTypeChip('훈련/교육'),
                        _buildGroupTypeChip('친목 모임'),
                        _buildGroupTypeChip('수제 간식'),
                        _buildGroupTypeChip('건강/케어'),
                        _buildGroupTypeChip('기타'),
                      ],
                    ),
                    
                    const SizedBox(height: AppSizes.gapL),
                    
                    const MingrrTextField(
                      labelText: '모임 소개',
                      hintText: '모임에 대해 소개해주세요',
                      maxLines: 4,
                    ),
                    
                    const SizedBox(height: AppSizes.gapL),
                    
                    const MingrrTextField(
                      labelText: '활동 지역',
                      hintText: '예: 서울 강남구',
                      prefixIcon: Icons.location_on,
                    ),
                    
                    const SizedBox(height: AppSizes.gapL),
                    
                    const MingrrTextField(
                      labelText: '최대 인원',
                      hintText: '0 = 무제한',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.people,
                    ),
                    
                    const SizedBox(height: AppSizes.gapXXL),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 모임 타입 칩
  Widget _buildGroupTypeChip(String label) {
    return ChoiceChip(
      label: Text(label),
      selected: false,
      onSelected: (value) {},
    );
  }
}
