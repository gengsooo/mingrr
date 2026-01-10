import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/pet_constants.dart';
import '../../../../core/widgets/search_screen.dart';
import '../../../../core/widgets/top_navigation.dart';
import '../../../../core/widgets/request_sheet.dart';
import '../../../../core/widgets/profile_icon.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../providers/community_provider.dart';
import 'group_detail_screen.dart';
import 'group_write_screen.dart';

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

// 정렬 옵션은 community_provider.dart에서 import

/// 한국 지역 데이터 (특별시/광역시/특례시 정식 명칭 사용)
class KoreaLocationData {
  static const Map<String, Map<String, List<String>>> data = {
    '서울특별시': {
      '서울특별시': ['강남구', '서초구', '송파구', '강동구', '마포구', '영등포구', '용산구', '종로구', '중구', '성동구', '광진구', '동대문구', '중랑구', '성북구', '강북구', '도봉구', '노원구', '은평구', '서대문구', '양천구', '강서구', '구로구', '금천구', '동작구', '관악구'],
    },
    '경기도': {
      '수원특례시': ['장안구', '권선구', '팔달구', '영통구'],
      '성남시': ['수정구', '중원구', '분당구'],
      '용인특례시': ['처인구', '기흥구', '수지구'],
      '고양특례시': ['덕양구', '일산동구', '일산서구'],
      '부천시': [],
      '안산시': ['상록구', '단원구'],
      '안양시': ['만안구', '동안구'],
      '남양주시': [],
      '화성시': [],
      '평택시': [],
      '의정부시': [],
      '시흥시': [],
      '파주시': [],
      '김포시': [],
      '광명시': [],
      '광주시': [],
      '군포시': [],
      '하남시': [],
      '오산시': [],
      '이천시': [],
      '안성시': [],
      '의왕시': [],
      '양주시': [],
      '포천시': [],
      '구리시': [],
      '여주시': [],
      '동두천시': [],
      '과천시': [],
      '가평군': [],
      '양평군': [],
      '연천군': [],
    },
    '인천광역시': {
      '인천광역시': ['중구', '동구', '미추홀구', '연수구', '남동구', '부평구', '계양구', '서구', '강화군', '옹진군'],
    },
    '부산광역시': {
      '부산광역시': ['중구', '서구', '동구', '영도구', '부산진구', '동래구', '남구', '북구', '해운대구', '사하구', '금정구', '강서구', '연제구', '수영구', '사상구', '기장군'],
    },
    '대구광역시': {
      '대구광역시': ['중구', '동구', '서구', '남구', '북구', '수성구', '달서구', '달성군', '군위군'],
    },
    '대전광역시': {
      '대전광역시': ['동구', '중구', '서구', '유성구', '대덕구'],
    },
    '광주광역시': {
      '광주광역시': ['동구', '서구', '남구', '북구', '광산구'],
    },
    '울산광역시': {
      '울산광역시': ['중구', '남구', '동구', '북구', '울주군'],
    },
    '세종특별자치시': {
      '세종특별자치시': [],
    },
    '강원특별자치도': {
      '춘천시': [],
      '원주시': [],
      '강릉시': [],
      '동해시': [],
      '태백시': [],
      '속초시': [],
      '삼척시': [],
      '홍천군': [],
      '횡성군': [],
      '영월군': [],
      '평창군': [],
      '정선군': [],
      '철원군': [],
      '화천군': [],
      '양구군': [],
      '인제군': [],
      '고성군': [],
      '양양군': [],
    },
    '충청북도': {
      '청주시': ['상당구', '서원구', '흥덕구', '청원구'],
      '충주시': [],
      '제천시': [],
      '보은군': [],
      '옥천군': [],
      '영동군': [],
      '증평군': [],
      '진천군': [],
      '괴산군': [],
      '음성군': [],
      '단양군': [],
    },
    '충청남도': {
      '천안시': ['동남구', '서북구'],
      '공주시': [],
      '보령시': [],
      '아산시': [],
      '서산시': [],
      '논산시': [],
      '계룡시': [],
      '당진시': [],
      '금산군': [],
      '부여군': [],
      '서천군': [],
      '청양군': [],
      '홍성군': [],
      '예산군': [],
      '태안군': [],
    },
    '전북특별자치도': {
      '전주시': ['완산구', '덕진구'],
      '군산시': [],
      '익산시': [],
      '정읍시': [],
      '남원시': [],
      '김제시': [],
      '완주군': [],
      '진안군': [],
      '무주군': [],
      '장수군': [],
      '임실군': [],
      '순창군': [],
      '고창군': [],
      '부안군': [],
    },
    '전라남도': {
      '목포시': [],
      '여수시': [],
      '순천시': [],
      '나주시': [],
      '광양시': [],
      '담양군': [],
      '곡성군': [],
      '구례군': [],
      '고흥군': [],
      '보성군': [],
      '화순군': [],
      '장흥군': [],
      '강진군': [],
      '해남군': [],
      '영암군': [],
      '무안군': [],
      '함평군': [],
      '영광군': [],
      '장성군': [],
      '완도군': [],
      '진도군': [],
      '신안군': [],
    },
    '경상북도': {
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
      '의성군': [],
      '청송군': [],
      '영양군': [],
      '영덕군': [],
      '청도군': [],
      '고령군': [],
      '성주군': [],
      '칠곡군': [],
      '예천군': [],
      '봉화군': [],
      '울진군': [],
      '울릉군': [],
    },
    '경상남도': {
      '창원특례시': ['의창구', '성산구', '마산합포구', '마산회원구', '진해구'],
      '진주시': [],
      '통영시': [],
      '사천시': [],
      '김해시': [],
      '밀양시': [],
      '거제시': [],
      '양산시': [],
      '의령군': [],
      '함안군': [],
      '창녕군': [],
      '고성군': [],
      '남해군': [],
      '하동군': [],
      '산청군': [],
      '함양군': [],
      '거창군': [],
      '합천군': [],
    },
    '제주특별자치도': {
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SearchScreen(
                    searchType: SearchType.community,
                    accentColor: AppColors.community,
                  ),
                ),
              );
            },
          ),
          const NotificationIconButton(),
          buildProfileAction(),
        ],
      ),
      body: Column(
        children: [
          // 지역 필터 바
          _buildLocationFilterBar(context, ref, selectedLocations),
          
          // 카테고리 필터 + 정렬
          Container(
            color: Colors.white,
            child: Column(
              children: [
                CategoryFilterChips(
                  categories: categories.map((c) => (label: c.label, emoji: c.emoji, icon: c.icon)).toList(),
                  selectedIndex: selectedCategory,
                  onSelected: (index) {
                    ref.read(_selectedCategoryProvider.notifier).state = index;
                  },
                  accentColor: AppColors.community,
                  showDropdownIcon: false,
                ),
                // 정렬 옵션
                _buildSortOptions(context, ref),
              ],
            ),
          ),
          
          // 모임 목록
          Expanded(
            child: _buildGroupList(context, ref, selectedLocations),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateGroupSheet(context),
        backgroundColor: AppColors.community,
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }

  /// 정렬 옵션 라벨
  String _getSortLabel(GroupSortOption option) {
    switch (option) {
      case GroupSortOption.recommended:
        return '추천순';
      case GroupSortOption.members:
        return '멤버순';
      case GroupSortOption.latest:
        return '최신순';
      case GroupSortOption.likes:
        return '좋아요순';
    }
  }

  /// 정렬 옵션 바 (오름차순/내림차순 토글 아이콘 포함)
  Widget _buildSortOptions(BuildContext context, WidgetRef ref) {
    final sortState = ref.watch(groupSortStateProvider);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider.withOpacity(0.3))),
      ),
      child: Row(
        children: GroupSortOption.values.map((option) {
          final isSelected = sortState.option == option;
          final isAsc = sortState.direction == SortDirection.ascending;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                final notifier = ref.read(groupSortStateProvider.notifier);
                if (isSelected) {
                  // 같은 옵션 클릭 시 방향 토글
                  notifier.state = sortState.toggleDirection();
                } else {
                  // 다른 옵션 클릭 시 해당 옵션으로 변경 (기본 내림차순)
                  notifier.state = GroupSortState(
                    option: option,
                    direction: SortDirection.descending,
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.community : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? AppColors.community : AppColors.divider,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getSortLabel(option),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 2),
                      Icon(
                        isAsc ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 12,
                        color: Colors.white,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
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

  /// 모임 목록 (Firebase 연동 + 정렬 적용)
  Widget _buildGroupList(BuildContext context, WidgetRef ref, List<String> locationFilter) {
    final sortedGroups = ref.watch(sortedGroupsProvider);
    final sortState = ref.watch(groupSortStateProvider);
    
    // 지역 필터 적용
    final filteredGroups = locationFilter.isEmpty 
        ? sortedGroups 
        : sortedGroups.where((g) {
            final address = g.group.address ?? '';
            return locationFilter.any((loc) => address.contains(loc));
          }).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 내 모임 섹션
        _buildMyGroupsSection(context),
        const SizedBox(height: 24),
        
        // 추천 모임 헤더
        Row(
          children: [
            Text(
              '${_getSortLabel(sortState.option)} 모임',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 4),
            Icon(
              sortState.direction == SortDirection.ascending 
                  ? Icons.arrow_upward 
                  : Icons.arrow_downward,
              size: 14,
              color: AppColors.textSecondary,
            ),
            if (locationFilter.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                '${locationFilter.length}개 지역',
                style: const TextStyle(fontSize: 12, color: AppColors.community, fontWeight: FontWeight.w500),
              ),
            ],
            const Spacer(),
            Text(
              '${filteredGroups.length}개',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // 모임 카드들
        if (filteredGroups.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            child: const Column(
              children: [
                Icon(Icons.groups_outlined, size: 48, color: AppColors.textHint),
                SizedBox(height: 12),
                Text('등록된 모임이 없습니다', style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          )
        else
          ...filteredGroups.map((groupWithDistance) => _buildGroupCardFromModel(
            context: context,
            groupWithDistance: groupWithDistance,
          )),
        
        const SizedBox(height: 80),
      ],
    );
  }
  
  /// GroupWithDistance를 사용한 모임 카드
  Widget _buildGroupCardFromModel({
    required BuildContext context,
    required GroupWithDistance groupWithDistance,
  }) {
    final group = groupWithDistance.group;
    return _buildGroupCard(
      context: context,
      id: group.id,
      name: group.name,
      category: group.typeString,
      members: group.memberCount,
      district: group.address ?? '지역 미설정',
      likeCount: group.likeCount,
      distance: groupWithDistance.distanceString,
      recommendScore: groupWithDistance.recommendScore,
    );
  }

  /// 내 모임 섹션
  Widget _buildMyGroupsSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final myGroupsAsync = ref.watch(userGroupsProvider);
        
        return myGroupsAsync.when(
          data: (myGroups) {
            if (myGroups.isEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('내 모임', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.groups_outlined, size: 40, color: AppColors.textHint),
                        SizedBox(height: 8),
                        Text('가입한 모임이 없습니다', style: TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              );
            }
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('내 모임', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    TextButton(
                      onPressed: () => _showMyGroupsFullScreenFromProvider(context, ref),
                      child: const Text('전체보기', style: TextStyle(fontSize: 13)),
                    ),
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
                        context: context,
                        id: group.id,
                        name: group.name,
                        district: group.address ?? '지역 미설정',
                        members: group.memberCount,
                      );
                    },
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('오류: $e')),
        );
      },
    );
  }
  
  /// 내 모임 전체보기 화면 (Provider 사용)
  void _showMyGroupsFullScreenFromProvider(BuildContext context, WidgetRef ref) {
    final myGroups = ref.read(userGroupsProvider).valueOrNull ?? [];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: AppColors.communityLight,
          appBar: AppBar(
            title: const Text('내 모임'),
            backgroundColor: Colors.white,
            elevation: 0,
          ),
          body: myGroups.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.groups_outlined, size: 64, color: AppColors.textHint),
                      SizedBox(height: 16),
                      Text('가입한 모임이 없습니다', style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: myGroups.length,
                  itemBuilder: (context, index) {
                    final group = myGroups[index];
                    return _buildGroupCard(
                      context: context,
                      name: group.name,
                      category: group.typeString,
                      members: group.memberCount,
                      district: group.address ?? '지역 미설정',
                      isJoined: true,
                    );
                  },
                ),
        ),
      ),
    );
  }

  /// 내 모임 카드
  Widget _buildMyGroupCard({
    required BuildContext context,
    required String id,
    required String name,
    required String district,
    required int members,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GroupDetailScreen(groupId: id),
          ),
        );
      },
      child: Container(
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
      ),
    );
  }

  /// 모임 카드
  Widget _buildGroupCard({
    required BuildContext context,
    String? id,
    required String name,
    required String category,
    required int members,
    required String district,
    int likeCount = 0,
    String? distance,
    double recommendScore = 0,
    bool isJoined = false,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GroupDetailScreen(
              groupId: id ?? name.hashCode.toString(),
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
                    if (distance != null && distance != '거리 정보 없음') ...[
                      const SizedBox(width: 4),
                      Text('· $distance', style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.people, size: 12, color: AppColors.textHint),
                    const SizedBox(width: 2),
                    Text('$members명', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    const SizedBox(width: 8),
                    const Icon(Icons.favorite, size: 12, color: AppColors.textHint),
                    const SizedBox(width: 2),
                    Text('$likeCount', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
          if (isJoined)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.community.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('가입중', style: TextStyle(fontSize: 12, color: AppColors.community, fontWeight: FontWeight.w600)),
            )
          else
            TextButton(
              onPressed: () => _showGroupJoinSheet(context, name),
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

  /// 소모임 가입 알림창
  void _showGroupJoinSheet(BuildContext context, String groupName) {
    showGroupJoinSheet(
      context,
      groupName: groupName,
      onConfirm: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$groupName에 가입 신청을 보냈어요!'),
            backgroundColor: AppColors.community,
          ),
        );
      },
    );
  }

  /// 모임 만들기 화면 이동
  void _showCreateGroupSheet(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GroupWriteScreen()),
    );
    
    // 등록 성공 시 목록 새로고침
    if (result == true && context.mounted) {
      // 상태 관리가 자동 해제 모드이므로 자동으로 새로고침됨
    }
  }
}

/// ============================================================
/// 지역 선택 바텀시트 (도/시/구 단계별 선택)
/// 
/// 로직:
/// - 임시 선택 상태(tempSelectedLocations)와 적용된 상태(_selectedLocationsProvider) 분리
/// - + 버튼 클릭 시 임시 상태에 추가
/// - 적용 버튼 클릭 시에만 Provider에 반영
/// - 초기화는 임시 상태만 초기화
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
  late List<String> tempSelectedLocations;

  @override
  void initState() {
    super.initState();
    // 현재 적용된 지역을 임시 상태로 복사
    tempSelectedLocations = List.from(widget.ref.read(_selectedLocationsProvider));
  }

  @override
  Widget build(BuildContext context) {
    final provinces = KoreaLocationData.getProvinces();
    final cities = selectedProvince != null ? KoreaLocationData.getCities(selectedProvince!) : <String>[];
    final districts = (selectedProvince != null && selectedCity != null) 
        ? KoreaLocationData.getDistricts(selectedProvince!, selectedCity!) 
        : <String>[];

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // 드래그 핸들
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // 헤더 (초기화 + 타이틀 + X버튼)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM, vertical: AppSizes.paddingS),
            child: Row(
              children: [
                // 초기화 버튼 (왼쪽)
                TextButton(
                  onPressed: () {
                    setState(() {
                      tempSelectedLocations = [];
                      selectedProvince = null;
                      selectedCity = null;
                    });
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(40, 40),
                  ),
                  child: const Text('초기화', style: TextStyle(fontSize: 14)),
                ),
                const Expanded(
                  child: Text(
                    '지역 선택',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          
          // 선택된 지역 표시 (임시 상태 기준)
          if (tempSelectedLocations.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: AppColors.communityLight,
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: tempSelectedLocations.map((location) {
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
                            setState(() {
                              tempSelectedLocations = tempSelectedLocations.where((l) => l != location).toList();
                            });
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
                                    final cityLocation = '$selectedProvince $city';
                                    final isAdded = cityDistricts.isEmpty && tempSelectedLocations.contains(cityLocation);
                                    final hasHighlight = isSelected || isAdded;
                                    
                                    return GestureDetector(
                                      onTap: () {
                                        if (cityDistricts.isEmpty) {
                                          // 구가 없는 시/군은 로우 전체 클릭 시 추가/제거
                                          setState(() {
                                            if (isAdded) {
                                              tempSelectedLocations = tempSelectedLocations.where((l) => l != cityLocation).toList();
                                            } else {
                                              tempSelectedLocations = [...tempSelectedLocations, cityLocation];
                                            }
                                          });
                                        } else {
                                          setState(() {
                                            selectedCity = city;
                                          });
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                        color: hasHighlight ? AppColors.community.withOpacity(0.1) : Colors.transparent,
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                city,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: hasHighlight ? FontWeight.w600 : FontWeight.w400,
                                                  color: hasHighlight ? AppColors.community : AppColors.textPrimary,
                                                ),
                                              ),
                                            ),
                                            if (cityDistricts.isEmpty)
                                              Icon(
                                                isAdded ? Icons.check : Icons.add,
                                                size: 16,
                                                color: AppColors.community,
                                              ),
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
                                  final isAdded = tempSelectedLocations.contains(fullLocation);
                                  
                                  return GestureDetector(
                                    onTap: () {
                                      // 로우 전체 클릭 시 추가/제거
                                      setState(() {
                                        if (isAdded) {
                                          tempSelectedLocations = tempSelectedLocations.where((l) => l != fullLocation).toList();
                                        } else {
                                          tempSelectedLocations = [...tempSelectedLocations, fullLocation];
                                        }
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      color: isAdded ? AppColors.community.withOpacity(0.1) : Colors.transparent,
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              district,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: isAdded ? FontWeight.w600 : FontWeight.w400,
                                                color: isAdded ? AppColors.community : AppColors.textPrimary,
                                              ),
                                            ),
                                          ),
                                          Icon(
                                            isAdded ? Icons.check : Icons.add,
                                            size: 16,
                                            color: AppColors.community,
                                          ),
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
                onPressed: () {
                  // 적용 버튼 클릭 시에만 Provider에 반영
                  widget.ref.read(_selectedLocationsProvider.notifier).state = tempSelectedLocations;
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.community,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  tempSelectedLocations.isEmpty ? '적용' : '${tempSelectedLocations.length}개 지역 적용',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
