import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/pet_constants.dart';
import '../../../../core/widgets/top_navigation.dart';
import '../../../../core/widgets/info_badge.dart';
import '../../../../core/widgets/trait_badge.dart';
import '../../../../core/widgets/verification_badge.dart';
import '../../../../core/widgets/request_sheet.dart';
import '../../../../core/widgets/profile_icon.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../models/pet_model.dart';
import '../providers/dating_provider.dart';
import '../../../pet/presentation/providers/pet_provider.dart';
import 'breeding_write_screen.dart';
import 'pet_detail_screen.dart';

/// ============================================================
/// 데이팅 화면 (V2 리팩토링 - 강아지 전용)
/// 
/// 변경사항:
/// - 3개 탭 (추천 / 근처 검색 / 교배찾기) - pill 형태
/// - 추천: 궁합 알고리즘 기반 추천 리스트
/// - 근처 검색: 거리 필터 + 그리드 뷰
/// - 교배찾기: 상세 필터 + 교배 가능한 강아지 목록
/// ============================================================

/// 선택된 탭 (0: 추천, 1: 근처 검색, 2: 교배찾기)
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

/// 인증 필터 (identity: 본인인증, pet: 동물인증, location: 위치인증)
final _breedingIdentityVerifiedFilterProvider = StateProvider<bool?>((ref) => null);
final _breedingPetVerifiedFilterProvider = StateProvider<bool?>((ref) => null);
final _breedingLocationVerifiedFilterProvider = StateProvider<bool?>((ref) => null);

/// 교배찾기 검색어 필터
final _breedingSearchQueryProvider = StateProvider<String>((ref) => '');

class DatingScreen extends ConsumerWidget {
  const DatingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTab = ref.watch(_selectedTabProvider);
    final distanceFilter = ref.watch(_distanceFilterProvider);
    // 내 반려동물 목록 미리 로드 (교배 신청 시 사용)
    ref.watch(userPetsProvider);

    // 탭 정의 (추천친구 / 근처 검색 / 교배찾기)
    final tabs = [
      TopNavTab(label: '추천친구', icon: Icons.auto_awesome, color: AppColors.dating),
      TopNavTab(label: '근처 검색', icon: Icons.location_on, color: AppColors.dating),
      TopNavTab(label: '교배찾기', icon: Icons.pets, color: AppColors.dating),
    ];

    return Scaffold(
      backgroundColor: AppColors.datingLight,
      appBar: AppBar(
        title: const Text('데이팅'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          const NotificationIconButton(),
          buildProfileAction(),
        ],
      ),
      body: Column(
        children: [
          // 3개 탭 (추천 / 근처 검색 / 교배찾기)
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
              icon: const Icon(Icons.edit, color: Colors.white, size: 20),
              label: const Text('글쓰기', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
            )
          : null,
    );
  }

  /// 탭별 컨텐츠
  Widget _buildTabContent(BuildContext context, WidgetRef ref, int selectedTab, double distanceFilter) {
    switch (selectedTab) {
      case 0:
        return _buildRecommendList(context);  // 추천: 스크롤 리스트
      case 1:
        return _buildNearbyGrid(context, distanceFilter);  // 근처 검색: 그리드
      case 2:
        return _buildBreedingList(context, ref, distanceFilter);  // 교배찾기: 리스트
      default:
        return const SizedBox();
    }
  }

  /// 상세화면으로 이동
  void _navigateToDetail(BuildContext context, String petId, {bool isBreeding = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PetDetailScreen(
          petId: petId,
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
          // 검색 바
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSizes.paddingM, AppSizes.paddingS, AppSizes.paddingM, 0),
            child: TextField(
              onChanged: (value) => ref.read(_breedingSearchQueryProvider.notifier).state = value,
              decoration: InputDecoration(
                hintText: '제목으로 검색',
                hintStyle: const TextStyle(fontSize: 14, color: AppColors.textHint),
                prefixIcon: const Icon(Icons.search, color: AppColors.textHint, size: 20),
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
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

  /// 교배찾기 리스트 (Firebase 연동 + 거리 필터링)
  Widget _buildBreedingList(BuildContext context, WidgetRef ref, double distanceFilter) {
    // 거리 필터가 적용된 교배 펫 목록 사용
    final filteredByDistance = ref.watch(filteredBreedingPetsProvider(distanceFilter));
    final genderFilter = ref.watch(_breedingGenderFilterProvider);
    
    // 성별 필터 적용
    var filteredPets = filteredByDistance;
    if (genderFilter != null) {
      filteredPets = filteredByDistance.where((p) {
        if (genderFilter == 'male') return p.pet.gender == PetGender.male;
        if (genderFilter == 'female') return p.pet.gender == PetGender.female;
        return true;
      }).toList();
    }
    
    if (filteredPets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.pets, size: 48, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text(
              '${distanceFilter.toInt()}km 내에 교배 가능한 반려동물이 없습니다',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            const Text(
              '거리를 늘려보세요',
              style: TextStyle(fontSize: 12, color: AppColors.textHint),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(AppSizes.paddingM),
      itemCount: filteredPets.length,
      itemBuilder: (context, index) {
        return _buildBreedingPetCard(context, ref, filteredPets[index]);
      },
    );
  }
  
  /// Firebase PetWithDistance를 사용한 교배찾기 카드
  Widget _buildBreedingPetCard(BuildContext context, WidgetRef ref, PetWithDistance petWithDistance) {
    final pet = petWithDistance.pet;
    final isMale = pet.gender == PetGender.male;
    
    return GestureDetector(
      onTap: () => _navigateToDetail(context, pet.id, isBreeding: true),
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
            // 이미지 영역 (대표사진 우선)
            Container(
              width: 120,
              height: 130,
              decoration: BoxDecoration(
                color: AppColors.datingLight,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(AppSizes.radiusL),
                ),
                image: _getPetPrimaryPhotoUrl(pet) != null
                    ? DecorationImage(
                        image: NetworkImage(_getPetPrimaryPhotoUrl(pet)!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: Stack(
                children: [
                  if (_getPetPrimaryPhotoUrl(pet) == null)
                    const Center(
                      child: Text('🐶', style: TextStyle(fontSize: 50)),
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
                          pet.name,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        Text(
                          petWithDistance.distanceString,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${pet.breed ?? '품종 미상'} · ${pet.ageString}',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    // 교배 조건 태그
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        if (pet.hasPedigree)
                          _buildBreedingConditionTag('혈통서 보유', Icons.verified),
                        if (pet.isVaccinationVerified)
                          _buildBreedingConditionTag('예방접종 완료', Icons.health_and_safety),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // 교배 신청 버튼
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _showBreedingRequestSheet(context, ref, pet.id),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.dating,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          '교배 신청',
                          style: TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
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

  /// 교배찾기 카드 (더미 데이터용 - 사용하지 않음)
  Widget _buildBreedingCard(BuildContext context, int index) {
    final distance = (index + 1) * 1.5;
    final isMale = index % 2 == 1;
    // 데모용 인증/조건 데이터
    final isIdentityVerified = index % 3 != 0;
    final isPetVerified = index % 2 == 0;
    final isLocationVerified = index % 4 != 0;
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
                    child: Text('🐶', style: TextStyle(fontSize: 50)),
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
                    child: VerificationBadgeRow(
                      isIdentityVerified: isIdentityVerified,
                      isPetVerified: isPetVerified,
                      isLocationVerified: isLocationVerified,
                      useMediumSize: false,
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
                        if (requiresHealthCheck)
                          _buildBreedingConditionTag('건강검진', Icons.health_and_safety_outlined),
                        if (requiresSameBreed)
                          _buildBreedingConditionTag('같은 품종', Icons.pets),
                        if (!requiresHealthCheck && !requiresSameBreed)
                          _buildBreedingConditionTag('조건 없음', Icons.check_circle_outline, isNoCondition: true),
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

  /// 교배 조건 태그
  Widget _buildBreedingConditionTag(String text, IconData icon, {bool isNoCondition = false}) {
    final color = isNoCondition ? Colors.grey : AppColors.dating;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: color),
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
  void _showBreedingRequestSheet(BuildContext context, WidgetRef ref, String petId) {
    final myPets = ref.read(userPetsProvider).valueOrNull ?? [];
    showBreedingRequestSheet(
      context,
      myPets: myPets,
      onConfirm: (message, {selectedPet}) {
        // TODO: message, selectedPet을 DB에 저장
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(selectedPet != null 
                ? '${selectedPet.name}(으)로 교배 신청을 보냈어요! 🐶' 
                : '교배 신청을 보냈어요! 🐶'),
            backgroundColor: AppColors.dating,
          ),
        );
      },
    );
  }

  /// 교배 글쓰기 화면 이동
  void _showBreedingWriteSheet(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BreedingWriteScreen()),
    );
    
    // 등록 성공 시 목록 새로고침
    if (result == true && context.mounted) {
      // 상태 관리가 자동 해제 모드이므로 자동으로 새로고침됨
    }
  }

  /// 근처 검색 그리드 뷰 (Firebase 연동 + 거리 필터링)
  Widget _buildNearbyGrid(BuildContext context, double distanceFilter) {
    return Consumer(
      builder: (context, ref, child) {
        // 거리 필터가 적용된 펫 목록 사용
        final filteredPets = ref.watch(filteredDatingPetsProvider(distanceFilter));
        final myPetsAsync = ref.watch(userPetsProvider);
        final hasMyPet = myPetsAsync.valueOrNull?.isNotEmpty ?? false;
        
        if (filteredPets.isEmpty) {
          // 내 반려동물이 없는 경우
          if (!hasMyPet) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.pets, size: 48, color: AppColors.textHint),
                  const SizedBox(height: 16),
                  const Text(
                    '반려동물을 먼저 등록해주세요',
                    style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '반려동물을 등록하면 근처의\n친구들을 찾아드려요',
                    style: TextStyle(fontSize: 12, color: AppColors.textHint),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.push('/profile'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.dating,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('반려동물 추가하기'),
                  ),
                ],
              ),
            );
          }
          // 내 반려동물은 있지만 근처에 다른 반려동물이 없는 경우
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_off, size: 48, color: AppColors.textHint),
                const SizedBox(height: 16),
                Text(
                  '${distanceFilter.toInt()}km 내에 반려동물이 없습니다',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                const Text(
                  '거리를 늘려보세요',
                  style: TextStyle(fontSize: 12, color: AppColors.textHint),
                ),
              ],
            ),
          );
        }
        
        return GridView.builder(
          padding: const EdgeInsets.all(AppSizes.paddingM),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: AppSizes.gapM,
            mainAxisSpacing: AppSizes.gapM,
            childAspectRatio: 0.75,
          ),
          itemCount: filteredPets.length,
          itemBuilder: (context, index) {
            return _buildNearbyPetCard(context, filteredPets[index]);
          },
        );
      },
    );
  }
  
  /// Firebase PetWithDistance를 사용한 근처 검색 카드
  Widget _buildNearbyPetCard(BuildContext context, PetWithDistance petWithDistance) {
    final pet = petWithDistance.pet;
    final matchScore = petWithDistance.matchScore;
    final isHighMatch = matchScore >= 90;
    final matchColor = isHighMatch ? AppColors.success : AppColors.dating;
    
    return GestureDetector(
      onTap: () => _navigateToDetail(context, pet.id),
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
            // 이미지 영역 (대표사진 우선)
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.datingLight,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppSizes.radiusL),
                  ),
                  image: _getPetPrimaryPhotoUrl(pet) != null
                      ? DecorationImage(
                          image: NetworkImage(_getPetPrimaryPhotoUrl(pet)!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_getPetPrimaryPhotoUrl(pet) == null)
                      const Center(
                        child: Text('🐶', style: TextStyle(fontSize: 50)),
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
                          petWithDistance.distanceString,
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
                    // 궁합 점수
                    MatchScoreBadge(
                      score: matchScore,
                      size: InfoBadgeSize.small,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pet.name,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${pet.breed ?? '품종 미상'} · ${pet.ageString}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    // 성격 태그
                    if (pet.traits.isNotEmpty)
                      TraitBadgeList(
                        traits: pet.traits.map((t) => t.label).toList(),
                        size: TraitBadgeSize.small,
                        maxCount: 2,
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

  /// 반려동물 대표사진 URL 가져오기 (추가사진 > null)
  String? _getPetPrimaryPhotoUrl(PetModel pet) {
    return pet.displayImageUrl;
  }

  /// 근처 검색 카드 (더미 데이터용 - 사용하지 않음)
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
                      child: Text('🐶', style: TextStyle(fontSize: 50)),
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

  /// 작은 태그 (근처검색용 - 회색)
  Widget _buildSmallTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
      ),
    );
  }

  /// 추천 리스트 (궁합 알고리즘 적용)
  Widget _buildRecommendList(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final petsAsync = ref.watch(recommendedPetsProvider);
        final myPetsAsync = ref.watch(userPetsProvider);
        final hasMyPet = myPetsAsync.valueOrNull?.isNotEmpty ?? false;
        
        return petsAsync.when(
          data: (pets) {
            if (pets.isEmpty) {
              // 내 반려동물이 없는 경우
              if (!hasMyPet) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.pets, size: 48, color: AppColors.textHint),
                      const SizedBox(height: 16),
                      const Text(
                        '반려동물을 먼저 등록해주세요',
                        style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '반려동물을 등록하면 궁합이 맞는\n친구들을 추천해드려요',
                        style: TextStyle(fontSize: 12, color: AppColors.textHint),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => context.push('/profile'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.dating,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('반려동물 추가하기'),
                      ),
                    ],
                  ),
                );
              }
              // 내 반려동물은 있지만 추천할 다른 반려동물이 없는 경우
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.auto_awesome, size: 48, color: AppColors.textHint),
                    const SizedBox(height: 16),
                    const Text(
                      '추천할 반려동물이 없습니다',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '근처에 등록된 반려동물이 없어요',
                      style: TextStyle(fontSize: 12, color: AppColors.textHint),
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(AppSizes.paddingM),
              itemCount: pets.length,
              itemBuilder: (context, index) {
                return _buildRecommendPetCard(context, pets[index]);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(child: Text('데이터를 불러올 수 없습니다')),
        );
      },
    );
  }

  /// 추천 카드 (궁합 점수 표시)
  Widget _buildRecommendPetCard(BuildContext context, RecommendedPet recommended) {
    final pet = recommended.pet;
    final matchScore = recommended.matchScore;
    final isMale = pet.gender == PetGender.male;
    
    return GestureDetector(
      onTap: () => _navigateToDetail(context, pet.id),
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
              // 배경 이미지
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
                  image: _getPetPrimaryPhotoUrl(pet) != null
                      ? DecorationImage(
                          image: NetworkImage(_getPetPrimaryPhotoUrl(pet)!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _getPetPrimaryPhotoUrl(pet) == null
                    ? const Center(
                        child: Text('🐶', style: TextStyle(fontSize: 80)),
                      )
                    : null,
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
                            pet.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            pet.ageString,
                            style: const TextStyle(fontSize: 16, color: Colors.white70),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      
                      // 품종과 거리
                      Row(
                        children: [
                          Text(
                            pet.breed ?? '품종 미상',
                            style: const TextStyle(fontSize: 13, color: Colors.white70),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.location_on, size: 12, color: Colors.white70),
                          const SizedBox(width: 2),
                          Text(
                            recommended.distanceString,
                            style: const TextStyle(fontSize: 12, color: Colors.white70),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // 성격 태그
                      if (pet.traits.isNotEmpty)
                        TraitBadgeList(
                          traits: pet.traits.map((t) => t.label).toList(),
                          size: TraitBadgeSize.small,
                          maxCount: 3,
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

}
