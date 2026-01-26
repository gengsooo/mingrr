import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/feature_colors.dart';
import '../../../../core/constants/pet_constants.dart';
import '../../../../core/widgets/navigation/top_navigation.dart';
import '../../../../core/widgets/search_screen.dart';
import '../../../../core/widgets/sheets/request_sheet.dart';
import '../../../../core/widgets/navigation/appbar_actions.dart';
import '../../../../core/widgets/filter_components.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/dialogs/dialogs.dart';
import '../../../../core/widgets/cards/dating_card.dart';
import '../../../../core/widgets/refresh_wrapper.dart';
import '../../../../core/providers/refresh_notifier.dart';
import '../../../../core/services/dating_service.dart';
import '../../../../core/services/firebase_service.dart';
import '../providers/dating_provider.dart';
import '../../../pet/presentation/providers/pet_provider.dart';
import 'breeding_write_screen.dart';
import 'pet_detail_screen.dart';

/// ============================================================
/// 데이팅 화면 (V2 리팩토링 - 반려동물 전용)
/// 
/// 변경사항:
/// - 3개 탭 (추천 / 근처 검색 / 교배찾기) - pill 형태
/// - 추천: 궁합 알고리즘 기반 추천 리스트
/// - 근처 검색: 거리 필터 + 그리드 뷰
/// - 교배찾기: 상세 필터 + 교배 가능한 반려동물 목록
/// ============================================================

/// 선택된 탭 (0: 추천, 1: 근처 검색, 2: 교배찾기)
final _selectedTabProvider = StateProvider<int>((ref) => 0);

/// 거리 필터 (근처 검색/교배찾기 공통)
final _distanceFilterProvider = StateProvider<double>((ref) => 3.0);

/// ============================================================
/// 교배찾기 필터 Provider
/// ============================================================

/// 성별 필터 (중복 선택 가능)
final _breedingGenderFilterProvider = StateProvider<List<String>>((ref) => []);

/// 같은 품종만 필터 (true: 같은 품종만, false/null: 무관)
final _breedingSameBreedFilterProvider = StateProvider<bool?>((ref) => null);

/// 무게/크기 필터 (중복 선택 가능)
final _breedingSizeFilterProvider = StateProvider<List<String>>((ref) => []);

/// 나이 필터 (null: 전체, 3, 5, 10, 15)
final _breedingAgeFilterProvider = StateProvider<int?>((ref) => null);

/// 혈통서 필터 (null: 전체, true: 혈통서 보유만)
final _breedingPedigreeFilterProvider = StateProvider<bool?>((ref) => null);

class DatingScreen extends ConsumerStatefulWidget {
  const DatingScreen({super.key});

  @override
  ConsumerState<DatingScreen> createState() => _DatingScreenState();
}

class _DatingScreenState extends ConsumerState<DatingScreen> {
  final ScrollController _breedingScrollController = ScrollController();
  final ScrollController _nearbyScrollController = ScrollController();
  final ScrollController _recommendScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _breedingScrollController.addListener(_onBreedingScroll);
    _nearbyScrollController.addListener(_onNearbyScroll);
    _recommendScrollController.addListener(_onRecommendScroll);
  }

  @override
  void dispose() {
    _breedingScrollController.removeListener(_onBreedingScroll);
    _nearbyScrollController.removeListener(_onNearbyScroll);
    _recommendScrollController.removeListener(_onRecommendScroll);
    _breedingScrollController.dispose();
    _nearbyScrollController.dispose();
    _recommendScrollController.dispose();
    super.dispose();
  }

  void _onBreedingScroll() {
    if (_breedingScrollController.position.pixels >=
        _breedingScrollController.position.maxScrollExtent - 200) {
      final distanceFilter = ref.read(_distanceFilterProvider);
      ref.read(paginatedBreedingPetsProvider(distanceFilter).notifier).loadMore();
    }
  }

  void _onNearbyScroll() {
    if (_nearbyScrollController.position.pixels >=
        _nearbyScrollController.position.maxScrollExtent - 200) {
      final distanceFilter = ref.read(_distanceFilterProvider);
      ref.read(paginatedNearbyPetsProvider(distanceFilter).notifier).loadMore();
    }
  }

  void _onRecommendScroll() {
    if (_recommendScrollController.position.pixels >=
        _recommendScrollController.position.maxScrollExtent - 200) {
      ref.read(paginatedRecommendedPetsProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedTab = ref.watch(_selectedTabProvider);
    final distanceFilter = ref.watch(_distanceFilterProvider);
    // 내 반려동물 목록 미리 로드 (교배 신청 시 사용)
    ref.watch(userPetsProvider);

    // 새로고침 트리거 감지 (등록/수정/삭제 후 자동 새로고침)
    ref.listen(datingRefreshProvider, (prev, next) {
      if (prev != next) {
        ref.read(paginatedBreedingPetsProvider(distanceFilter).notifier).refresh();
        ref.read(paginatedNearbyPetsProvider(distanceFilter).notifier).refresh();
        ref.read(paginatedRecommendedPetsProvider.notifier).refresh();
      }
    });

    final theme = Theme.of(context);
    final features = theme.extension<FeatureColors>()!;
    
    // 탭 정의 (추천친구 / 근처 검색 / 교배찾기)
    final tabs = [
      MingrrTabItem(label: '추천친구', icon: Icons.auto_awesome, color: features.dating),
      MingrrTabItem(label: '근처 검색', icon: Icons.radar, color: features.dating),
      MingrrTabItem(label: '교배찾기', icon: Icons.family_restroom, color: features.dating),
    ];
    
    return Scaffold(
      backgroundColor: features.datingContainer,
      appBar: AppBar(
        title: const Text('데이팅'),
        actions: [
          // 교배찾기 탭에서만 검색 아이콘 표시
          if (selectedTab == 2)
            AppBarActionButton.search(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (ctx) => SearchScreen(
                      searchType: SearchType.breeding,
                      accentColor: features.dating,
                    ),
                  ),
                );
              },
            ),
          AppBarActionButton.notification(),
          AppBarActionButton.profile(backgroundColor: Theme.of(context).scaffoldBackgroundColor),
        ],
      ),
      body: Column(
        children: [
          // 3개 탭 (추천 / 근처 검색 / 교배찾기)
          MingrrMainTabBar(
            tabs: tabs,
            selectedIndex: selectedTab,
            onTabSelected: (index) {
              ref.read(_selectedTabProvider.notifier).state = index;
            },
          ),
          
          // 위치/거리 필터 바 (근처 검색/교배찾기 탭에서 표시)
          if (selectedTab == 1 || selectedTab == 2)
            LocationDistanceBar(
              accentColor: features.dating,
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
      floatingActionButton: MingrrFAB.write(
        onPressed: () => _showBreedingWriteSheet(context),
        backgroundColor: features.dating,
        visible: selectedTab == 2,
        tooltip: '교배 등록',
      ),
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
  void _navigateToDetail(
    BuildContext context, 
    String petId, {
    bool isBreeding = false,
    double? distanceMeters,
    int? matchScore,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PetDetailScreen(
          petId: petId,
          isBreeding: isBreeding,
          cachedDistanceMeters: distanceMeters,
          cachedMatchScore: matchScore,
        ),
      ),
    );
  }

  /// 교배찾기 필터 섹션
  Widget _buildBreedingFilters(BuildContext context, WidgetRef ref) {
    final accentColor = context.features.dating;
    return MingrrFilterSection(
      rows: [
        // 1행: 성별 + 품종
        MingrrFilterRow(
          title: '성별/품종',
          children: [
            _buildGenderFilters(ref, accentColor),
            const MingrrFilterDivider(),
            _buildBreedFilters(ref, accentColor),
          ],
        ),
        // 2행: 크기 + 나이
        MingrrFilterRow(
          title: '크기/나이',
          children: [
            _buildSizeFilters(context, ref, accentColor),
            const MingrrFilterDivider(),
            _buildAgeFilters(ref, accentColor),
          ],
        ),
        // 3행: 혈통서
        MingrrFilterRow(
          title: '혈통서',
          children: [
            _buildPedigreeFilters(ref, accentColor),
          ],
        ),
      ],
    );
  }

  /// 성별 필터 (중복 선택 가능)
  Widget _buildGenderFilters(WidgetRef ref, Color accentColor) {
    final selectedGenders = ref.watch(_breedingGenderFilterProvider);
    return Row(
      children: [
        MingrrFilterChip(
          label: '남아',
          icon: Icons.male,
          iconSize: 14,
          isSelected: selectedGenders.contains('male'),
          onTap: () {
            final current = List<String>.from(selectedGenders);
            if (current.contains('male')) {
              current.remove('male');
            } else {
              current.add('male');
            }
            ref.read(_breedingGenderFilterProvider.notifier).state = current;
          },
          accentColor: accentColor,
        ),
        const SizedBox(width: AppSizes.gapSM),
        MingrrFilterChip(
          label: '여아',
          icon: Icons.female,
          iconSize: 14,
          isSelected: selectedGenders.contains('female'),
          onTap: () {
            final current = List<String>.from(selectedGenders);
            if (current.contains('female')) {
              current.remove('female');
            } else {
              current.add('female');
            }
            ref.read(_breedingGenderFilterProvider.notifier).state = current;
          },
          accentColor: accentColor,
        ),
      ],
    );
  }

  /// 품종 필터 (같은 품종/무관)
  Widget _buildBreedFilters(WidgetRef ref, Color accentColor) {
    final sameBreedFilter = ref.watch(_breedingSameBreedFilterProvider);
    return Row(
      children: [
        MingrrFilterChip(
          label: '품종 무관',
          isSelected: sameBreedFilter == null || sameBreedFilter == false,
          onTap: () => ref.read(_breedingSameBreedFilterProvider.notifier).state = null,
          accentColor: accentColor,
        ),
        const SizedBox(width: AppSizes.gapSM),
        MingrrFilterChip(
          label: '같은 품종만',
          isSelected: sameBreedFilter == true,
          onTap: () => ref.read(_breedingSameBreedFilterProvider.notifier).state = true,
          accentColor: accentColor,
        ),
      ],
    );
  }

  /// 크기 필터 (중복 선택 가능)
  Widget _buildSizeFilters(BuildContext context, WidgetRef ref, Color accentColor) {
    final selectedSizes = ref.watch(_breedingSizeFilterProvider);
    final sizes = [
      {'key': 'xs', 'label': '초소형'},
      {'key': 's', 'label': '소형'},
      {'key': 'm', 'label': '중형'},
      {'key': 'l', 'label': '대형'},
      {'key': 'xl', 'label': '초대형'},
    ];
    return Row(
      children: [
        // 안내 버튼
        GestureDetector(
          onTap: () => _showSizeGuideModal(context),
          child: Container(
            padding: const EdgeInsets.all(AppSizes.paddingXS),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: AppOpacity.o10),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.help_outline, size: 14, color: accentColor),
          ),
        ),
        const SizedBox(width: AppSizes.gapS),
        // 크기 필터 칩들
        ...sizes.map((size) {
          final key = size['key'] as String;
          final isSelected = selectedSizes.contains(key);
          return Padding(
            padding: const EdgeInsets.only(right: AppSizes.paddingXS),
            child: MingrrFilterChip(
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
              accentColor: accentColor,
            ),
          );
        }),
      ],
    );
  }

  /// 크기 안내 모달
  void _showSizeGuideModal(BuildContext context) {
    final features = Theme.of(context).extension<FeatureColors>()!;
    showInfoDialog(
      context,
      title: '반려동물 크기 안내',
      icon: Icons.pets,
      subtitle: '체중 기준으로 분류해요',
      accentColor: features.dating,
      items: const [
        InfoItem(label: '초소형', value: '0~4kg', description: '치와와, 요크셔테리어 등'),
        InfoItem(label: '소형', value: '4~10kg', description: '말티즈, 푸들, 시츄 등'),
        InfoItem(label: '중형', value: '10~25kg', description: '코카스파니엘, 비글 등'),
        InfoItem(label: '대형', value: '25~45kg', description: '골든리트리버, 래브라도 등'),
        InfoItem(label: '초대형', value: '45kg~', description: '그레이트데인, 세인트버나드 등'),
      ],
      footerText: '반려동물마다 개체차가 있을 수 있어요',
    );
  }

  /// 나이 필터
  Widget _buildAgeFilters(WidgetRef ref, Color accentColor) {
    final ageFilter = ref.watch(_breedingAgeFilterProvider);
    final ages = [
      {'key': null, 'label': '전체'},
      {'key': 3, 'label': '3세 이하'},
      {'key': 5, 'label': '5세 이하'},
      {'key': 10, 'label': '10세 이하'},
    ];
    return Row(
      children: ages.map((age) {
        return Padding(
          padding: const EdgeInsets.only(right: AppSizes.paddingXS),
          child: MingrrFilterChip(
            label: age['label'] as String,
            isSelected: ageFilter == age['key'],
            onTap: () => ref.read(_breedingAgeFilterProvider.notifier).state = age['key'] as int?,
            accentColor: accentColor,
          ),
        );
      }).toList(),
    );
  }

  /// 혈통서 필터
  Widget _buildPedigreeFilters(WidgetRef ref, Color accentColor) {
    final pedigreeFilter = ref.watch(_breedingPedigreeFilterProvider);
    return Row(
      children: [
        MingrrFilterChip(
          label: '전체',
          isSelected: pedigreeFilter == null,
          onTap: () => ref.read(_breedingPedigreeFilterProvider.notifier).state = null,
          accentColor: accentColor,
        ),
        const SizedBox(width: AppSizes.gapSM),
        MingrrFilterChip(
          label: '혈통서 보유',
          icon: Icons.verified,
          iconSize: 12,
          isSelected: pedigreeFilter == true,
          onTap: () => ref.read(_breedingPedigreeFilterProvider.notifier).state = 
              pedigreeFilter == true ? null : true,
          accentColor: accentColor,
        ),
      ],
    );
  }

  /// 교배찾기 리스트 (Firebase 연동 + 거리 필터링 + 페이지네이션)
  Widget _buildBreedingList(BuildContext context, WidgetRef ref, double distanceFilter) {
    final paginatedState = ref.watch(paginatedBreedingPetsProvider(distanceFilter));
    final genderFilter = ref.watch(_breedingGenderFilterProvider);
    final pedigreeFilter = ref.watch(_breedingPedigreeFilterProvider);
    
    // 초기 로딩 상태
    if (paginatedState.isInitialLoading) {
      return MingrrLoadingState(
        type: MingrrLoadingType.dating,
        message: '교배 가능한 반려동물을 찾고 있어요',
        timeout: AppSizes.loadingTimeout,
        onRetry: () => ref.read(paginatedBreedingPetsProvider(distanceFilter).notifier).loadInitial(),
      );
    }
    
    // 에러 상태
    if (paginatedState.hasError && paginatedState.items.isEmpty) {
      return MingrrErrorState(
        title: '데이터를 불러올 수 없어요',
        subtitle: '잠시 후 다시 시도해주세요',
        onRetry: () => ref.read(paginatedBreedingPetsProvider(distanceFilter).notifier).loadInitial(),
      );
    }
    
    // 성별/혈통서 필터 적용
    var filteredPets = paginatedState.items.toList();
    if (genderFilter.isNotEmpty) {
      filteredPets = filteredPets.where((p) {
        if (genderFilter.contains('male') && p.pet.gender == PetGender.male) return true;
        if (genderFilter.contains('female') && p.pet.gender == PetGender.female) return true;
        return false;
      }).toList();
    }
    if (pedigreeFilter == true) {
      filteredPets = filteredPets.where((p) => p.pet.hasPedigree).toList();
    }
    
    // 빈 상태
    if (filteredPets.isEmpty) {
      return MingrrEmptyState(
        icon: Icons.family_restroom,
        title: '아직 데이터가 없어요',
        subtitle: '거리를 늘리거나 필터를 조정해보세요',
        accentColor: context.features.dating,
        onRefresh: () async {
          await ref.read(paginatedBreedingPetsProvider(distanceFilter).notifier).refresh();
        },
      );
    }
    
    // 데이터 있음
    return MingrrRefreshWrapper(
      color: context.features.dating,
      onRefresh: () async {
        await ref.read(paginatedBreedingPetsProvider(distanceFilter).notifier).refresh();
      },
      child: ListView.builder(
        controller: _breedingScrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSizes.paddingM),
        itemCount: filteredPets.length + (paginatedState.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= filteredPets.length) {
            return const Padding(
              padding: EdgeInsets.all(AppSizes.paddingL),
              child: Center(
                child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            );
          }
          return MingrrAnimatedListItem(
            index: index,
            child: _buildBreedingPetCard(context, ref, filteredPets[index]),
          );
        },
      ),
    );
  }
  
  /// Firebase PetWithDistance를 사용한 교배찾기 카드 - 공통 컴포넌트 사용
  Widget _buildBreedingPetCard(BuildContext context, WidgetRef ref, PetWithDistance petWithDistance) {
    final pet = petWithDistance.pet;
    
    return DatingBreedingCard(
      name: pet.name,
      breed: pet.breed,
      ageString: pet.ageString,
      isMale: pet.gender == PetGender.male,
      distanceString: petWithDistance.distanceString,
      description: petWithDistance.breedingDescription,
      hasPedigree: pet.hasPedigree,
      imageUrl: pet.displayImageUrl,
      onTap: () => _navigateToDetail(
        context, 
        pet.id, 
        isBreeding: true,
        distanceMeters: petWithDistance.distanceMeters,
      ),
      onBreedingRequest: () => _showBreedingRequestSheet(context, ref, pet.id),
    );
  }

  /// 교배 신청 바톰시트
  void _showBreedingRequestSheet(BuildContext context, WidgetRef ref, String targetPetId) async {
    final myPets = ref.read(userPetsProvider).valueOrNull ?? [];
    final myUserId = FirebaseService().currentUserId;
    
    if (myUserId == null) {
      MingrrSnackBar.error(context, '로그인이 필요합니다');
      return;
    }
    
    if (myPets.isEmpty) {
      MingrrSnackBar.warning(context, '먼저 반려동물을 등록해주세요');
      return;
    }
    
    showBreedingRequestSheet(
      context,
      myPets: myPets,
      onConfirm: (message, {selectedPet}) async {
        try {
          // 대상 반려동물 정보 가져오기
          final targetPetDoc = await FirebaseService().petsCollection.doc(targetPetId).get();
          if (!targetPetDoc.exists) {
            if (context.mounted) {
              MingrrSnackBar.error(context, '반려동물 정보를 찾을 수 없습니다');
            }
            return;
          }
          
          final targetPetData = targetPetDoc.data()!;
          final targetOwnerId = targetPetData['ownerId'] as String;
          
          // 내 대표 반려동물 또는 선택한 반려동물
          final myPet = selectedPet ?? myPets.firstWhere(
            (p) => p.isPrimary,
            orElse: () => myPets.first,
          );
          
          // 교배 신청 보내기
          final datingService = DatingService();
          await datingService.sendBreedingRequest(
            fromUserId: myUserId,
            fromPetId: myPet.id,
            toUserId: targetOwnerId,
            toPetId: targetPetId,
            message: message,
          );
          
          if (context.mounted) {
            MingrrSnackBar.success(context, '${myPet.name}(으)로 교배 신청을 보냈어요! 🐶');
          }
        } catch (e) {
          if (context.mounted) {
            MingrrSnackBar.error(context, e.toString().replaceAll('Exception: ', ''));
          }
        }
      },
    );
  }

  /// 교배 등록 화면 이동
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

  /// 근처 검색 그리드 뷰 (Firebase 연동 + 거리 필터링 + 페이지네이션)
  Widget _buildNearbyGrid(BuildContext context, double distanceFilter) {
    final paginatedState = ref.watch(paginatedNearbyPetsProvider(distanceFilter));
    final myPetsAsync = ref.watch(userPetsProvider);
    final hasMyPet = myPetsAsync.valueOrNull?.isNotEmpty ?? false;
    
    // 초기 로딩 상태
    if (paginatedState.isInitialLoading) {
      return MingrrLoadingState(
        type: MingrrLoadingType.dating,
        message: '근처 반려동물을 찾고 있어요',
        timeout: AppSizes.loadingTimeout,
        onRetry: () => ref.read(paginatedNearbyPetsProvider(distanceFilter).notifier).loadInitial(),
      );
    }
    
    // 에러 상태
    if (paginatedState.hasError && paginatedState.items.isEmpty) {
      return MingrrErrorState(
        title: '데이터를 불러올 수 없어요',
        subtitle: '잠시 후 다시 시도해주세요',
        onRetry: () => ref.read(paginatedNearbyPetsProvider(distanceFilter).notifier).loadInitial(),
      );
    }
    
    // 빈 상태
    if (paginatedState.isEmpty) {
      if (!hasMyPet) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.pets, size: 48, color: Theme.of(context).colorScheme.outlineVariant),
              const SizedBox(height: AppSizes.gapL),
              Text(
                '반려동물을 먼저 등록해주세요',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Text(
                '반려동물을 등록하면 근처의\n친구들을 찾아드려요',
                style: AppTextStyles.caption(context),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.gapL),
              MingrrButton(
                text: '반려동물 추가하기',
                onPressed: () => context.push('/profile'),
                backgroundColor: context.features.dating,
                textColor: Colors.white,
                width: 180,
              ),
            ],
          ),
        );
      }
      return MingrrEmptyState(
        icon: Icons.radar,
        title: '아직 데이터가 없어요',
        subtitle: '거리를 늘려보세요',
        accentColor: context.features.dating,
        onRefresh: () async {
          await ref.read(paginatedNearbyPetsProvider(distanceFilter).notifier).refresh();
        },
      );
    }
    
    // 데이터 있음
    return MingrrRefreshWrapper(
      color: context.features.dating,
      onRefresh: () async {
        await ref.read(paginatedNearbyPetsProvider(distanceFilter).notifier).refresh();
      },
      child: CustomScrollView(
        controller: _nearbyScrollController,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(AppSizes.paddingM),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSizes.gapM,
                mainAxisSpacing: AppSizes.gapM,
                childAspectRatio: 0.75,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildNearbyPetCard(context, paginatedState.items[index]),
                childCount: paginatedState.items.length,
              ),
            ),
          ),
          if (paginatedState.hasMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(AppSizes.paddingL),
                child: Center(
                  child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  /// Firebase PetWithDistance를 사용한 근처 검색 카드 - 공통 컴포넌트 사용
  Widget _buildNearbyPetCard(BuildContext context, PetWithDistance petWithDistance) {
    final pet = petWithDistance.pet;
    
    return DatingNearbyCard(
      name: pet.name,
      breed: pet.breed,
      ageString: pet.ageString,
      matchScore: petWithDistance.matchScore,
      distanceString: petWithDistance.distanceString,
      traits: pet.traits.map((t) => t.label).toList(),
      imageUrl: pet.displayImageUrl,
      onTap: () => _navigateToDetail(
        context, 
        pet.id,
        distanceMeters: petWithDistance.distanceMeters,
        matchScore: petWithDistance.matchScore,
      ),
    );
  }

  /// 추천 리스트 (궁합 알고리즘 적용 + 페이지네이션)
  Widget _buildRecommendList(BuildContext context) {
    final paginatedState = ref.watch(paginatedRecommendedPetsProvider);
    final myPetsAsync = ref.watch(userPetsProvider);
    final hasMyPet = myPetsAsync.valueOrNull?.isNotEmpty ?? false;
    
    // 초기 로딩 상태
    if (paginatedState.isInitialLoading) {
      return MingrrLoadingState(
        type: MingrrLoadingType.dating,
        message: '추천 반려동물을 불러오고 있어요',
        timeout: AppSizes.loadingTimeout,
        onRetry: () => ref.read(paginatedRecommendedPetsProvider.notifier).loadInitial(),
      );
    }
    
    // 에러 상태
    if (paginatedState.hasError && paginatedState.items.isEmpty) {
      return MingrrErrorState(
        title: '일시적인 오류가 발생했어요',
        subtitle: '잠시 후 다시 시도해주세요',
        onRetry: () => ref.read(paginatedRecommendedPetsProvider.notifier).loadInitial(),
      );
    }
    
    // 빈 상태
    if (paginatedState.isEmpty) {
      if (!hasMyPet) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.pets, size: 48, color: Theme.of(context).colorScheme.outlineVariant),
              const SizedBox(height: AppSizes.gapL),
              Text(
                '반려동물을 먼저 등록해주세요',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Text(
                '반려동물을 등록하면 궁합이 맞는\n친구들을 추천해드려요',
                style: AppTextStyles.caption(context),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.gapL),
              MingrrButton(
                text: '반려동물 추가하기',
                onPressed: () => context.push('/profile'),
                backgroundColor: context.features.dating,
                textColor: Colors.white,
                width: 180,
              ),
            ],
          ),
        );
      }
      return MingrrEmptyState(
        icon: Icons.auto_awesome,
        title: '추천할 반려동물이 없어요',
        subtitle: '근처에 등록된 반려동물이 없어요',
        accentColor: context.features.dating,
        onRefresh: () async {
          await ref.read(paginatedRecommendedPetsProvider.notifier).refresh();
        },
      );
    }
    
    // 데이터 있음
    return MingrrRefreshWrapper(
      color: context.features.dating,
      onRefresh: () async {
        await ref.read(paginatedRecommendedPetsProvider.notifier).refresh();
      },
      child: ListView.builder(
        controller: _recommendScrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSizes.paddingM),
        itemCount: paginatedState.items.length + (paginatedState.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= paginatedState.items.length) {
            return const Padding(
              padding: EdgeInsets.all(AppSizes.paddingL),
              child: Center(
                child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            );
          }
          return MingrrAnimatedListItem(
            index: index,
            child: _buildRecommendPetCard(context, paginatedState.items[index]),
          );
        },
      ),
    );
  }

  /// 추천 카드 (궁합 점수 표시) - 공통 컴포넌트 사용
  Widget _buildRecommendPetCard(BuildContext context, RecommendedPet recommended) {
    final pet = recommended.pet;
    
    return DatingRecommendCard(
      name: pet.name,
      breed: pet.breed,
      ageString: pet.ageString,
      isMale: pet.gender == PetGender.male,
      matchScore: recommended.matchScore,
      distanceString: recommended.distanceString,
      traits: pet.traits.map((t) => t.label).toList(),
      imageUrl: pet.displayImageUrl,
      onTap: () => _navigateToDetail(
        context, 
        pet.id,
        distanceMeters: recommended.distanceMeters,
        matchScore: recommended.matchScore,
      ),
    );
  }

}
