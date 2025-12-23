import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/top_navigation.dart';
import 'dog_detail_screen.dart';

/// ============================================================
/// 데이팅 화면 (V2 리팩토링 - 강아지 전용)
/// 
/// 변경사항:
/// - 3개 탭 (AI추천 / 근처 검색 / 교배찾기) - pill 형태
/// - AI추천: 틴더 스타일 스와이프 카드
/// - 근처 검색: 거리 필터 + 그리드 뷰
/// - 교배찾기: 상세 필터 + 교배 가능한 강아지 목록
/// ============================================================

/// 선택된 탭 (0: AI추천, 1: 근처 검색, 2: 교배찾기)
final _selectedTabProvider = StateProvider<int>((ref) => 0);

/// 거리 필터 (근처 검색/교배찾기 공통)
final _distanceFilterProvider = StateProvider<double>((ref) => 3.0);

/// ============================================================
/// 교배찾기 필터 Provider
/// ============================================================

/// 성별 필터 (null: 전체, 'male', 'female')
final _breedingGenderFilterProvider = StateProvider<String?>((ref) => null);

/// 같은 품종만 필터 (true: 같은 품종만, false/null: 무관)
final _breedingSameBreedFilterProvider = StateProvider<bool?>((ref) => null);

/// 무게/크기 필터 (중복 선택 가능)
final _breedingSizeFilterProvider = StateProvider<List<String>>((ref) => []);

/// 나이 필터 (null: 전체, 3, 5, 10, 15)
final _breedingAgeFilterProvider = StateProvider<int?>((ref) => null);

/// 혈통서 필터
final _breedingHasPedigreeFilterProvider = StateProvider<bool?>((ref) => null);

/// 인증 필터 (identity: 본인인증, pet: 동물인증, location: 위치인증)
final _breedingIdentityVerifiedFilterProvider = StateProvider<bool?>((ref) => null);
final _breedingPetVerifiedFilterProvider = StateProvider<bool?>((ref) => null);
final _breedingLocationVerifiedFilterProvider = StateProvider<bool?>((ref) => null);

class DatingScreen extends ConsumerWidget {
  const DatingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTab = ref.watch(_selectedTabProvider);
    final distanceFilter = ref.watch(_distanceFilterProvider);

    // 탭 정의 (AI추천 / 근처 검색 / 교배찾기)
    final tabs = [
      TopNavTab(label: 'AI추천', icon: Icons.auto_awesome, color: AppColors.dating),
      TopNavTab(label: '근처 검색', icon: Icons.location_on, color: AppColors.dating),
      TopNavTab(label: '교배찾기', icon: Icons.pets, color: AppColors.dating),
    ];

    return Scaffold(
      backgroundColor: AppColors.datingLight,
      appBar: AppBar(
        title: const Text('데이팅'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 3개 탭 (AI추천 / 근처 검색 / 교배찾기)
          Container(
            color: Colors.white,
            child: PillTabBar(
              tabs: tabs,
              selectedIndex: selectedTab,
              onTabSelected: (index) {
                ref.read(_selectedTabProvider.notifier).state = index;
              },
            ),
          ),
          
          // 위치/거리 필터 바 (근처 검색/교배찾기 탭에서 표시)
          if (selectedTab == 1 || selectedTab == 2)
            LocationDistanceBar(
              accentColor: AppColors.dating,
              currentDistance: distanceFilter,
              onDistanceChanged: (distance) {
                ref.read(_distanceFilterProvider.notifier).state = distance;
              },
            ),
          
          // 교배찾기 필터 (교배찾기 탭에서만)
          if (selectedTab == 2) _buildBreedingFilters(context, ref),
          
          // 탭별 컨텐츠
          Expanded(
            child: _buildTabContent(context, ref, selectedTab, distanceFilter),
          ),
          
          const SizedBox(height: AppSizes.gapL),
        ],
      ),
      // 교배찾기 탭에서 글쓰기 FAB 표시
      floatingActionButton: selectedTab == 2
          ? FloatingActionButton.extended(
              onPressed: () => _showBreedingWriteSheet(context),
              backgroundColor: AppColors.dating,
              icon: const Icon(Icons.edit, color: Colors.white),
              label: const Text('교배 글쓰기', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            )
          : null,
    );
  }

  /// 탭별 컨텐츠
  Widget _buildTabContent(BuildContext context, WidgetRef ref, int selectedTab, double distanceFilter) {
    switch (selectedTab) {
      case 0:
        return _buildAiRecommendList(context);  // AI추천: 스크롤 리스트
      case 1:
        return _buildNearbyGrid(context, distanceFilter);  // 근처 검색: 그리드
      case 2:
        return _buildBreedingList(context, ref, distanceFilter);  // 교배찾기: 리스트
      default:
        return const SizedBox();
    }
  }

  /// 상세화면으로 이동
  void _navigateToDetail(BuildContext context, String dogId, {bool isBreeding = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DogDetailScreen(
          dogId: dogId,
          isBreeding: isBreeding,
        ),
      ),
    );
  }

  /// 교배찾기 필터 섹션
  Widget _buildBreedingFilters(BuildContext context, WidgetRef ref) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1행: 성별 + 품종
          _buildFilterRow(
            context, ref,
            title: '성별/품종',
            children: [
              _buildGenderFilters(ref),
              _buildDivider(),
              _buildBreedFilters(ref),
            ],
          ),
          const Divider(height: 1),
          // 2행: 크기 + 나이
          _buildFilterRow(
            context, ref,
            title: '크기/나이',
            children: [
              _buildSizeFilters(context, ref),
              _buildDivider(),
              _buildAgeFilters(ref),
            ],
          ),
          const Divider(height: 1),
          // 3행: 인증 여부
          _buildFilterRow(
            context, ref,
            title: '인증',
            children: [
              _buildVerificationFilters(ref),
            ],
          ),
        ],
      ),
    );
  }

  /// 필터 행 위젯
  Widget _buildFilterRow(BuildContext context, WidgetRef ref, {
    required String title,
    required List<Widget> children,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM, vertical: AppSizes.paddingS),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // 필터 제목
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  /// 구분선
  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(width: 1, height: 20, color: AppColors.divider),
    );
  }

  /// 성별 필터
  Widget _buildGenderFilters(WidgetRef ref) {
    final genderFilter = ref.watch(_breedingGenderFilterProvider);
    return Row(
      children: [
        _buildFilterChip(
          label: '전체',
          isSelected: genderFilter == null,
          onTap: () => ref.read(_breedingGenderFilterProvider.notifier).state = null,
        ),
        const SizedBox(width: 6),
        _buildFilterChip(
          label: '수컷 ♂',
          isSelected: genderFilter == 'male',
          onTap: () => ref.read(_breedingGenderFilterProvider.notifier).state = 'male',
        ),
        const SizedBox(width: 6),
        _buildFilterChip(
          label: '암컷 ♀',
          isSelected: genderFilter == 'female',
          onTap: () => ref.read(_breedingGenderFilterProvider.notifier).state = 'female',
        ),
      ],
    );
  }

  /// 품종 필터 (같은 품종/무관)
  Widget _buildBreedFilters(WidgetRef ref) {
    final sameBreedFilter = ref.watch(_breedingSameBreedFilterProvider);
    return Row(
      children: [
        _buildFilterChip(
          label: '품종 무관',
          isSelected: sameBreedFilter == null || sameBreedFilter == false,
          onTap: () => ref.read(_breedingSameBreedFilterProvider.notifier).state = null,
        ),
        const SizedBox(width: 6),
        _buildFilterChip(
          label: '같은 품종만',
          isSelected: sameBreedFilter == true,
          onTap: () => ref.read(_breedingSameBreedFilterProvider.notifier).state = true,
        ),
      ],
    );
  }

  /// 크기 필터 (중복 선택 가능)
  Widget _buildSizeFilters(BuildContext context, WidgetRef ref) {
    final selectedSizes = ref.watch(_breedingSizeFilterProvider);
    final sizes = [
      {'key': 'xs', 'label': '초소형', 'weight': '0~4kg'},
      {'key': 's', 'label': '소형', 'weight': '4~10kg'},
      {'key': 'm', 'label': '중형', 'weight': '10~25kg'},
      {'key': 'l', 'label': '대형', 'weight': '25~45kg'},
      {'key': 'xl', 'label': '초대형', 'weight': '45kg~'},
    ];
    return Row(
      children: [
        // 안내 버튼
        GestureDetector(
          onTap: () => _showSizeGuideModal(context),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.dating.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.help_outline, size: 14, color: AppColors.dating),
          ),
        ),
        const SizedBox(width: 8),
        // 크기 필터 칩들
        ...sizes.map((size) {
          final key = size['key'] as String;
          final isSelected = selectedSizes.contains(key);
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: _buildFilterChip(
              label: size['label'] as String,
              isSelected: isSelected,
              onTap: () {
                final current = List<String>.from(selectedSizes);
                if (isSelected) {
                  current.remove(key);
                } else {
                  current.add(key);
                }
                ref.read(_breedingSizeFilterProvider.notifier).state = current;
              },
            ),
          );
        }),
      ],
    );
  }

  /// 크기 안내 모달
  void _showSizeGuideModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.pets, color: AppColors.dating, size: 24),
            const SizedBox(width: 8),
            const Text('강아지 크기 안내', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSizeGuideItem('초소형', '0~4kg', '치와와, 요크셔테리어 등'),
            _buildSizeGuideItem('소형', '4~10kg', '말티즈, 푸들, 시촄 등'),
            _buildSizeGuideItem('중형', '10~25kg', '코카스파니엘, 비글 등'),
            _buildSizeGuideItem('대형', '25~45kg', '골든리트리버, 래브라도 등'),
            _buildSizeGuideItem('초대형', '45kg~', '그레이트데인, 세인트버나드 등'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  /// 크기 안내 아이템
  Widget _buildSizeGuideItem(String label, String weight, String examples) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 60,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.dating.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.dating),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(weight, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                Text(examples, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 나이 필터
  Widget _buildAgeFilters(WidgetRef ref) {
    final ageFilter = ref.watch(_breedingAgeFilterProvider);
    final ages = [
      {'key': null, 'label': '전체'},
      {'key': 3, 'label': '3세 이하'},
      {'key': 5, 'label': '5세 이하'},
      {'key': 10, 'label': '10세 이하'},
      {'key': 15, 'label': '15세 이하'},
    ];
    return Row(
      children: ages.map((age) {
        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: _buildFilterChip(
            label: age['label'] as String,
            isSelected: ageFilter == age['key'],
            onTap: () => ref.read(_breedingAgeFilterProvider.notifier).state = age['key'] as int?,
          ),
        );
      }).toList(),
    );
  }

  /// 인증 필터
  Widget _buildVerificationFilters(WidgetRef ref) {
    final identityVerified = ref.watch(_breedingIdentityVerifiedFilterProvider);
    final petVerified = ref.watch(_breedingPetVerifiedFilterProvider);
    final locationVerified = ref.watch(_breedingLocationVerifiedFilterProvider);
    final hasPedigree = ref.watch(_breedingHasPedigreeFilterProvider);
    
    return Row(
      children: [
        _buildFilterChip(
          label: '본인인증',
          isSelected: identityVerified == true,
          onTap: () => ref.read(_breedingIdentityVerifiedFilterProvider.notifier).state = 
              identityVerified == true ? null : true,
          icon: Icons.person_outline,
        ),
        const SizedBox(width: 6),
        _buildFilterChip(
          label: '동물인증',
          isSelected: petVerified == true,
          onTap: () => ref.read(_breedingPetVerifiedFilterProvider.notifier).state = 
              petVerified == true ? null : true,
          icon: Icons.pets,
        ),
        const SizedBox(width: 6),
        _buildFilterChip(
          label: '위치인증',
          isSelected: locationVerified == true,
          onTap: () => ref.read(_breedingLocationVerifiedFilterProvider.notifier).state = 
              locationVerified == true ? null : true,
          icon: Icons.location_on_outlined,
        ),
        const SizedBox(width: 6),
        _buildFilterChip(
          label: '혈통서',
          isSelected: hasPedigree == true,
          onTap: () => ref.read(_breedingHasPedigreeFilterProvider.notifier).state = 
              hasPedigree == true ? null : true,
          icon: Icons.verified_outlined,
        ),
      ],
    );
  }

  /// 필터 칩
  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color? color,
    IconData? icon,
  }) {
    final chipColor = color ?? AppColors.dating;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? chipColor : AppColors.divider,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 12,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 교배찾기 리스트
  Widget _buildBreedingList(BuildContext context, WidgetRef ref, double distanceFilter) {
    // TODO: 필터 적용 로직 구현
    // final genderFilter = ref.watch(_breedingGenderFilterProvider);
    // final hasPedigreeFilter = ref.watch(_breedingHasPedigreeFilterProvider);
    
    return ListView.builder(
      padding: const EdgeInsets.all(AppSizes.paddingM),
      itemCount: 5,
      itemBuilder: (context, index) {
        return _buildBreedingCard(context, index);
      },
    );
  }

  /// 교배찾기 카드
  Widget _buildBreedingCard(BuildContext context, int index) {
    final distance = (index + 1) * 1.5;
    final isMale = index % 2 == 1;
    // 데모용 인증/조건 데이터
    final isIdentityVerified = index % 3 != 0;
    final isPetVerified = index % 2 == 0;
    final isLocationVerified = index % 4 != 0;
    final requiresPedigree = index % 2 == 0;
    final requiresHealthCheck = index % 3 == 0;
    final requiresSameBreed = index % 4 == 0;
    
    return GestureDetector(
      onTap: () => _navigateToDetail(context, 'breeding_$index', isBreeding: true),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSizes.gapM),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          children: [
            // 이미지 영역
            Container(
              width: 120,
              height: 130,
              decoration: BoxDecoration(
                color: AppColors.datingLight,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(AppSizes.radiusL),
                ),
              ),
              child: Stack(
                children: [
                  const Center(
                    child: Icon(Icons.pets, size: 50, color: AppColors.dating),
                  ),
                  // 성별 배지
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isMale ? Colors.blue : Colors.pink,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isMale ? '♂' : '♀',
                        style: const TextStyle(fontSize: 12, color: Colors.white),
                      ),
                    ),
                  ),
                  // 인증 배지들 (하단)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    right: 8,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        if (isIdentityVerified)
                          _buildVerificationBadge(Icons.person, AppColors.success),
                        if (isPetVerified)
                          _buildVerificationBadge(Icons.pets, AppColors.success),
                        if (isLocationVerified)
                          _buildVerificationBadge(Icons.location_on, AppColors.success),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // 정보 영역
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.paddingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '교배견 ${index + 1}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        Text(
                          '${distance.toStringAsFixed(1)}km',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '푸들 · ${isMale ? "수컷" : "암컷"} · 3살',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    // 원하는 조건 태그
                    const Text(
                      '원하는 조건',
                      style: TextStyle(fontSize: 10, color: AppColors.textHint),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (requiresPedigree)
                          _buildBreedingConditionTag('혈통서', Icons.verified_outlined),
                        if (requiresHealthCheck)
                          _buildBreedingConditionTag('건강검진', Icons.health_and_safety_outlined),
                        if (requiresSameBreed)
                          _buildBreedingConditionTag('같은 품종', Icons.pets),
                        if (!requiresPedigree && !requiresHealthCheck && !requiresSameBreed)
                          _buildBreedingConditionTag('조건 없음', Icons.check_circle_outline),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 인증 배지 (교배찾기 카드용)
  Widget _buildVerificationBadge(IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 10, color: Colors.white),
    );
  }

  /// 교배 조건 태그
  Widget _buildBreedingConditionTag(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.dating.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: AppColors.dating),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.dating),
          ),
        ],
      ),
    );
  }

  /// 교배찾기 태그
  Widget _buildBreedingTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: color),
      ),
    );
  }

  /// 교배 신청 바톰시트
  void _showBreedingRequestSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSizes.paddingL),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXL)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSizes.gapXL),
            const Icon(Icons.pets, size: 48, color: AppColors.dating),
            const SizedBox(height: AppSizes.gapM),
            const Text(
              '교배 신청',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSizes.gapS),
            const Text(
              '상대방에게 교배 신청을 보낼까요?\n수락되면 채팅이 시작됩니다.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSizes.gapXL),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.divider),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('취소'),
                  ),
                ),
                const SizedBox(width: AppSizes.gapM),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('교배 신청을 보냈어요! 🐶'),
                          backgroundColor: AppColors.dating,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.dating,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '신청하기',
                      style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  /// 교배 글쓰기 바텀시트
  void _showBreedingWriteSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXL)),
        ),
        child: Column(
          children: [
            // 헤더
            Container(
              padding: const EdgeInsets.all(AppSizes.paddingM),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.divider)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      '교배 글쓰기',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('교배 글이 등록되었어요! 🐶'),
                          backgroundColor: AppColors.dating,
                        ),
                      );
                    },
                    child: const Text('등록', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            // 본문
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSizes.paddingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 강아지 선택
                    const Text('교배할 강아지', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.datingLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.dating.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppColors.dating.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(child: Text('🐶', style: TextStyle(fontSize: 24))),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('뽀삐', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                                Text('골든 리트리버 · 수컷 · 3살', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // 제목
                    const Text('제목', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: InputDecoration(
                        hintText: '예) 건강한 골든 리트리버 교배 원해요',
                        hintStyle: const TextStyle(color: AppColors.textHint),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.divider),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.divider),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.dating),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // 내용
                    const Text('상세 내용', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextField(
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: '교배 조건, 원하는 상대 조건 등을 자세히 적어주세요',
                        hintStyle: const TextStyle(color: AppColors.textHint),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.divider),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.divider),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.dating),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // 원하는 상대 크기
                    const Text('원하는 상대 크기 (중복 선택 가능)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildWriteSizeChip('초소형 (0~4kg)'),
                        _buildWriteSizeChip('소형 (4~10kg)'),
                        _buildWriteSizeChip('중형 (10~25kg)'),
                        _buildWriteSizeChip('대형 (25~45kg)'),
                        _buildWriteSizeChip('초대형 (45kg~)'),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // 추가 조건
                    const Text('추가 조건', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildWriteConditionChip('혈통서 필수', Icons.verified_outlined),
                        _buildWriteConditionChip('건강검진 완료', Icons.health_and_safety_outlined),
                        _buildWriteConditionChip('같은 품종만', Icons.pets),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 글쓰기 크기 칩
  Widget _buildWriteSizeChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
      ),
    );
  }

  /// 글쓰기 조건 칩
  Widget _buildWriteConditionChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  /// 근처 검색 그리드 뷰
  Widget _buildNearbyGrid(BuildContext context, double distanceFilter) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSizes.paddingM),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSizes.gapM,
        mainAxisSpacing: AppSizes.gapM,
        childAspectRatio: 0.75,
      ),
      itemCount: 10,
      itemBuilder: (context, index) {
        return _buildNearbyCard(context, index);
      },
    );
  }

  /// 근처 검색 카드
  Widget _buildNearbyCard(BuildContext context, int index) {
    final distance = (index + 1) * 0.5;
    final matchScore = 80 + index * 2;
    final isHighMatch = matchScore >= 90;
    final matchColor = isHighMatch ? AppColors.success : AppColors.dating;
    
    return GestureDetector(
      onTap: () => _navigateToDetail(context, 'nearby_$index'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 이미지 영역
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.datingLight,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppSizes.radiusL),
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const Center(
                      child: Icon(Icons.pets, size: 50, color: AppColors.dating),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${distance}km',
                          style: const TextStyle(fontSize: 10, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // 정보 영역
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.paddingS),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '멍멍이 ${index + 1}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      '푸들 · 3살',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    // 특성 태그
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        _buildSmallTag('활발함'),
                        _buildSmallTag('친화적'),
                      ],
                    ),
                    const Spacer(),
                    // 궁합 점수 (90% 이상 초록색)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: matchColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '궁합 $matchScore%',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: matchColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 작은 태그 (근처검색용)
  Widget _buildSmallTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.dating.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 9, color: AppColors.dating),
      ),
    );
  }

  /// AI 추천 리스트 (스크롤 가능)
  Widget _buildAiRecommendList(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSizes.paddingM),
      itemCount: 10,
      itemBuilder: (context, index) {
        return _buildAiRecommendCard(context, index);
      },
    );
  }

  /// AI 추천 카드
  Widget _buildAiRecommendCard(BuildContext context, int index) {
    final matchScore = 95 - (index * 3);
    final distance = (index + 1) * 0.8;
    final isMale = index % 2 == 0;
    
    return GestureDetector(
      onTap: () => _navigateToDetail(context, 'ai_$index'),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSizes.gapM),
        height: 280,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusXL),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSizes.radiusXL),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 배경 이미지 (플레이스홀더)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.datingLight,
                      AppColors.dating.withOpacity(0.2),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: const Center(
                  child: Text('🐶', style: TextStyle(fontSize: 80)),
                ),
              ),
              
              // 그라데이션 오버레이
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 150,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              
              // 성별 배지
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isMale ? Colors.blue : Colors.pink,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isMale ? '♂' : '♀',
                        style: const TextStyle(fontSize: 14, color: Colors.white),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isMale ? '수컷' : '암컷',
                        style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
              
              // AI 궁합 점수 (90% 이상 초록색)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: matchScore >= 90 ? AppColors.success : AppColors.dating,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome, size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        '궁합 $matchScore%',
                        style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
              
              // 정보 영역
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.paddingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 이름과 나이
                      Row(
                        children: [
                          Text(
                            '뽀삐 ${index + 1}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '2살',
                            style: TextStyle(fontSize: 16, color: Colors.white70),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      
                      // 품종과 거리
                      Row(
                        children: [
                          const Text(
                            '골든 리트리버',
                            style: TextStyle(fontSize: 13, color: Colors.white70),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.location_on, size: 12, color: Colors.white70),
                          const SizedBox(width: 2),
                          Text(
                            '${distance.toStringAsFixed(1)}km',
                            style: const TextStyle(fontSize: 12, color: Colors.white70),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // 성격 태그
                      Wrap(
                        spacing: 6,
                        children: [
                          _buildPersonalityTag('활발한'),
                          _buildPersonalityTag('친화적인'),
                          _buildPersonalityTag('장난스러운'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 성격 태그
  Widget _buildPersonalityTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, color: Colors.white),
      ),
    );
  }
}
