import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/pet_constants.dart';
import '../../../../core/widgets/top_navigation.dart';
import 'community_detail_screen.dart';

/// ============================================================
/// 소모임 화면
/// 
/// 디자인:
/// - 상단 탭 없음 (데이팅/소모임/마켓 탭 제거)
/// - 지역 필터 (도/시/구 단계별 선택, 복수 선택 가능)
/// - 카테고리 필터 (모임종류)
/// - 모임 목록
/// ============================================================

/// 선택된 지역 목록 (복수 선택 가능)
final _selectedLocationsProvider = StateProvider<List<String>>((ref) => []);

/// 선택된 카테고리 인덱스
final _selectedCategoryProvider = StateProvider<int>((ref) => 0);

/// 한국 지역 데이터
class KoreaLocationData {
  static const Map<String, Map<String, List<String>>> data = {
    '서울': {
      '서울시': ['강남구', '서초구', '송파구', '강동구', '마포구', '영등포구', '용산구', '종로구', '중구', '성동구', '광진구', '동대문구', '중랑구', '성북구', '강북구', '도봉구', '노원구', '은평구', '서대문구', '양천구', '강서구', '구로구', '금천구', '동작구', '관악구'],
    },
    '경기': {
      '성남시': ['분당구', '수정구', '중원구'],
      '용인시': ['수지구', '기흥구', '처인구'],
      '수원시': ['영통구', '권선구', '장안구', '팔달구'],
      '고양시': ['일산동구', '일산서구', '덕양구'],
      '부천시': ['원미구', '소사구', '오정구'],
      '안양시': ['동안구', '만안구'],
      '화성시': [],
      '평택시': [],
      '의정부시': [],
      '시흥시': [],
    },
    '인천': {
      '인천시': ['중구', '동구', '미추홀구', '연수구', '남동구', '부평구', '계양구', '서구', '강화군', '옹진군'],
    },
    '부산': {
      '부산시': ['중구', '서구', '동구', '영도구', '부산진구', '동래구', '남구', '북구', '해운대구', '사하구', '금정구', '강서구', '연제구', '수영구', '사상구', '기장군'],
    },
    '대구': {
      '대구시': ['중구', '동구', '서구', '남구', '북구', '수성구', '달서구', '달성군'],
    },
    '대전': {
      '대전시': ['동구', '중구', '서구', '유성구', '대덕구'],
    },
    '광주': {
      '광주시': ['동구', '서구', '남구', '북구', '광산구'],
    },
    '울산': {
      '울산시': ['중구', '남구', '동구', '북구', '울주군'],
    },
    '세종': {
      '세종시': [],
    },
    '강원': {
      '춘천시': [],
      '원주시': [],
      '강릉시': [],
      '동해시': [],
      '태백시': [],
      '속초시': [],
      '삼척시': [],
    },
    '충북': {
      '청주시': ['상당구', '서원구', '흥덕구', '청원구'],
      '충주시': [],
      '제천시': [],
    },
    '충남': {
      '천안시': ['동남구', '서북구'],
      '공주시': [],
      '보령시': [],
      '아산시': [],
      '서산시': [],
      '논산시': [],
      '계룡시': [],
      '당진시': [],
    },
    '전북': {
      '전주시': ['완산구', '덕진구'],
      '군산시': [],
      '익산시': [],
      '정읍시': [],
      '남원시': [],
      '김제시': [],
    },
    '전남': {
      '목포시': [],
      '여수시': [],
      '순천시': [],
      '나주시': [],
      '광양시': [],
    },
    '경북': {
      '포항시': ['남구', '북구'],
      '경주시': [],
      '김천시': [],
      '안동시': [],
      '구미시': [],
      '영주시': [],
      '영천시': [],
      '상주시': [],
      '문경시': [],
      '경산시': [],
    },
    '경남': {
      '창원시': ['의창구', '성산구', '마산합포구', '마산회원구', '진해구'],
      '진주시': [],
      '통영시': [],
      '사천시': [],
      '김해시': [],
      '밀양시': [],
      '거제시': [],
      '양산시': [],
    },
    '제주': {
      '제주시': [],
      '서귀포시': [],
    },
  };

  static List<String> getProvinces() => data.keys.toList();
  
  static List<String> getCities(String province) => data[province]?.keys.toList() ?? [];
  
  static List<String> getDistricts(String province, String city) => data[province]?[city] ?? [];
}

class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedLocations = ref.watch(_selectedLocationsProvider);
    final selectedCategory = ref.watch(_selectedCategoryProvider);

    // 카테고리 정의 (전체 + CommunityCategory)
    final categories = [
      (label: '전체', emoji: '📋', icon: null),
      ...CommunityCategory.values.map((c) => (
        label: c.label.replaceAll(' 모임', ''),
        emoji: c.emoji,
        icon: null,
      )),
    ];

    return Scaffold(
      backgroundColor: AppColors.communityLight,
      appBar: AppBar(
        title: const Text('소모임'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: 소모임 검색 화면 구현 예정
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 지역 필터 바
          _buildLocationFilterBar(context, ref, selectedLocations),
          
          // 카테고리 필터
          Container(
            color: Colors.white,
            child: CategoryFilterChips(
              categories: categories.map((c) => (label: c.label, emoji: c.emoji, icon: c.icon)).toList(),
              selectedIndex: selectedCategory,
              onSelected: (index) {
                ref.read(_selectedCategoryProvider.notifier).state = index;
              },
              accentColor: AppColors.community,
              showDropdownIcon: false,
            ),
          ),
          
          // 모임 목록
          Expanded(
            child: _buildGroupList(context, ref, selectedLocations),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateGroupSheet(context),
        backgroundColor: AppColors.community,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          '모임 만들기',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  /// 지역 필터 바
  Widget _buildLocationFilterBar(BuildContext context, WidgetRef ref, List<String> selectedLocations) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.divider.withOpacity(0.5)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단: 지역 선택 버튼 + 초기화
          Row(
            children: [
              Icon(Icons.location_on, size: 18, color: AppColors.community),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => _showLocationSelector(context, ref),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.community.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        selectedLocations.isEmpty ? '전체 지역' : '지역 선택',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.community,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.community),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              if (selectedLocations.isNotEmpty)
                GestureDetector(
                  onTap: () => ref.read(_selectedLocationsProvider.notifier).state = [],
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.divider.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.refresh, size: 14, color: AppColors.textSecondary),
                        SizedBox(width: 2),
                        Text('초기화', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          
          // 선택된 지역 칩들
          if (selectedLocations.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: selectedLocations.map((location) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.community.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.community.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        location,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.community,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () {
                          final current = ref.read(_selectedLocationsProvider);
                          ref.read(_selectedLocationsProvider.notifier).state = 
                            current.where((l) => l != location).toList();
                        },
                        child: const Icon(Icons.close, size: 14, color: AppColors.community),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  /// 지역 선택 바텀시트 (도/시/구 단계별)
  void _showLocationSelector(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LocationSelectorSheet(ref: ref),
    );
  }

  /// 모임 목록
  Widget _buildGroupList(BuildContext context, WidgetRef ref, List<String> locationFilter) {
    final groups = [
      {'name': '주말 한강 산책 모임', 'category': '산책', 'members': 28, 'district': '서울 영등포구'},
      {'name': '강아지 수제 간식 만들기', 'category': '나눔', 'members': 15, 'district': '서울 강남구'},
      {'name': '소형견 친목 모임', 'category': '친목', 'members': 42, 'district': '서울 마포구'},
      {'name': '반려견 훈련 스터디', 'category': '훈련', 'members': 18, 'district': '서울 송파구'},
      {'name': '시니어 반려견 케어 모임', 'category': '건강', 'members': 23, 'district': '서울 서초구'},
      {'name': '분당 댕댕이 모임', 'category': '친목', 'members': 35, 'district': '경기 성남시'},
      {'name': '용인 산책 친구들', 'category': '산책', 'members': 20, 'district': '경기 용인시'},
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 내 모임 섹션
        _buildMyGroupsSection(),
        const SizedBox(height: 24),
        
        // 추천 모임 헤더
        Row(
          children: [
            const Text('추천 모임', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            if (locationFilter.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                '${locationFilter.length}개 지역',
                style: const TextStyle(fontSize: 12, color: AppColors.community, fontWeight: FontWeight.w500),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        
        // 모임 카드들
        ...groups.map((group) => _buildGroupCard(
          context: context,
          name: group['name'] as String,
          category: group['category'] as String,
          members: group['members'] as int,
          district: group['district'] as String,
        )),
        
        const SizedBox(height: 80),
      ],
    );
  }

  /// 내 모임 섹션
  Widget _buildMyGroupsSection() {
    final myGroups = [
      {'name': '한강 산책 모임', 'district': '서울 영등포구', 'members': 12},
      {'name': '수제 간식 클럽', 'district': '서울 강남구', 'members': 24},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('내 모임', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            TextButton(onPressed: () {}, child: const Text('전체보기', style: TextStyle(fontSize: 13))),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: myGroups.length,
            itemBuilder: (context, index) {
              final group = myGroups[index];
              return _buildMyGroupCard(
                name: group['name'] as String,
                district: group['district'] as String,
                members: group['members'] as int,
              );
            },
          ),
        ),
      ],
    );
  }

  /// 내 모임 카드
  Widget _buildMyGroupCard({required String name, required String district, required int members}) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.community.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.groups, color: AppColors.community, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$district · $members명',
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  /// 모임 카드
  Widget _buildGroupCard({
    required BuildContext context,
    required String name,
    required String category,
    required int members,
    required String district,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CommunityDetailScreen(
              communityId: name.hashCode.toString(),
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
        ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.community.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.groups, color: AppColors.community, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.community.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    category,
                    style: const TextStyle(fontSize: 10, color: AppColors.community, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 4),
                Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 12, color: AppColors.textHint),
                    const SizedBox(width: 2),
                    Text(district, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    const SizedBox(width: 8),
                    const Icon(Icons.people, size: 12, color: AppColors.textHint),
                    const SizedBox(width: 2),
                    Text('$members명', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              foregroundColor: AppColors.community,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            child: const Text('가입', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      ),
    );
  }

  /// 모임 만들기 바텀시트
  void _showCreateGroupSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  const Expanded(
                    child: Text('모임 만들기', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('모임이 생성되었습니다!'), backgroundColor: AppColors.success),
                      );
                    },
                    child: const Text('완료'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text('모임 이름 *', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  const TextField(decoration: InputDecoration(hintText: '모임 이름을 입력해주세요', border: OutlineInputBorder())),
                  const SizedBox(height: 16),
                  const Text('활동 지역 *', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  const TextField(
                    decoration: InputDecoration(
                      hintText: '예: 서울 강남구',
                      prefixIcon: Icon(Icons.location_on),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('모임 소개', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  const TextField(maxLines: 3, decoration: InputDecoration(hintText: '모임에 대해 소개해주세요', border: OutlineInputBorder())),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ============================================================
/// 지역 선택 바텀시트 (도/시/구 단계별 선택)
/// ============================================================
class _LocationSelectorSheet extends ConsumerStatefulWidget {
  final WidgetRef ref;

  const _LocationSelectorSheet({required this.ref});

  @override
  ConsumerState<_LocationSelectorSheet> createState() => _LocationSelectorSheetState();
}

class _LocationSelectorSheetState extends ConsumerState<_LocationSelectorSheet> {
  String? selectedProvince;
  String? selectedCity;

  @override
  Widget build(BuildContext context) {
    final selectedLocations = widget.ref.watch(_selectedLocationsProvider);
    final provinces = KoreaLocationData.getProvinces();
    final cities = selectedProvince != null ? KoreaLocationData.getCities(selectedProvince!) : <String>[];
    final districts = (selectedProvince != null && selectedCity != null) 
        ? KoreaLocationData.getDistricts(selectedProvince!, selectedCity!) 
        : <String>[];

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 헤더
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.divider.withOpacity(0.5))),
            ),
            child: Row(
              children: [
                const Text('지역 선택', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    widget.ref.read(_selectedLocationsProvider.notifier).state = [];
                    Navigator.pop(context);
                  },
                  child: const Text('전체 지역'),
                ),
              ],
            ),
          ),
          
          // 선택된 지역 표시
          if (selectedLocations.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: AppColors.communityLight,
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: selectedLocations.map((location) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.community,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          location,
                          style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () {
                            final current = widget.ref.read(_selectedLocationsProvider);
                            widget.ref.read(_selectedLocationsProvider.notifier).state = 
                              current.where((l) => l != location).toList();
                          },
                          child: const Icon(Icons.close, size: 14, color: Colors.white),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          
          // 3단계 선택 영역
          Expanded(
            child: Row(
              children: [
                // 도/광역시 선택
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(right: BorderSide(color: AppColors.divider.withOpacity(0.5))),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          color: AppColors.background,
                          child: const Text('도/광역시', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: provinces.length,
                            itemBuilder: (context, index) {
                              final province = provinces[index];
                              final isSelected = province == selectedProvince;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedProvince = province;
                                    selectedCity = null;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  color: isSelected ? AppColors.community.withOpacity(0.1) : Colors.transparent,
                                  child: Text(
                                    province,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                      color: isSelected ? AppColors.community : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // 시/군 선택
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(right: BorderSide(color: AppColors.divider.withOpacity(0.5))),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          color: AppColors.background,
                          child: const Text('시/군', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                        ),
                        Expanded(
                          child: cities.isEmpty
                              ? const Center(child: Text('도/광역시를\n선택하세요', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.textHint)))
                              : ListView.builder(
                                  itemCount: cities.length,
                                  itemBuilder: (context, index) {
                                    final city = cities[index];
                                    final isSelected = city == selectedCity;
                                    final cityDistricts = KoreaLocationData.getDistricts(selectedProvince!, city);
                                    
                                    return GestureDetector(
                                      onTap: () {
                                        if (cityDistricts.isEmpty) {
                                          // 구가 없으면 바로 추가
                                          _addLocation('$selectedProvince $city');
                                        } else {
                                          setState(() {
                                            selectedCity = city;
                                          });
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                        color: isSelected ? AppColors.community.withOpacity(0.1) : Colors.transparent,
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                city,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                                  color: isSelected ? AppColors.community : AppColors.textPrimary,
                                                ),
                                              ),
                                            ),
                                            if (cityDistricts.isEmpty)
                                              const Icon(Icons.add, size: 16, color: AppColors.community),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // 구/동 선택
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        color: AppColors.background,
                        child: const Text('구/군', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                      ),
                      Expanded(
                        child: districts.isEmpty
                            ? const Center(child: Text('시/군을\n선택하세요', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.textHint)))
                            : ListView.builder(
                                itemCount: districts.length,
                                itemBuilder: (context, index) {
                                  final district = districts[index];
                                  final fullLocation = '$selectedProvince $selectedCity $district';
                                  final isAdded = selectedLocations.contains(fullLocation);
                                  
                                  return GestureDetector(
                                    onTap: () {
                                      if (!isAdded) {
                                        _addLocation(fullLocation);
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              district,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: isAdded ? AppColors.textHint : AppColors.textPrimary,
                                              ),
                                            ),
                                          ),
                                          if (isAdded)
                                            const Icon(Icons.check, size: 16, color: AppColors.community)
                                          else
                                            const Icon(Icons.add, size: 16, color: AppColors.community),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // 하단 버튼
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(context).padding.bottom + 12,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.divider.withOpacity(0.5))),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.community,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  selectedLocations.isEmpty ? '전체 지역으로 검색' : '${selectedLocations.length}개 지역 선택 완료',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addLocation(String location) {
    final current = widget.ref.read(_selectedLocationsProvider);
    if (!current.contains(location)) {
      widget.ref.read(_selectedLocationsProvider.notifier).state = [...current, location];
    }
  }
}
