import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/location_constants.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/feature_colors.dart';
import '../../../../core/constants/pet_constants.dart';
import '../../../../core/widgets/navigation/top_navigation.dart';
import '../../../../core/widgets/search_screen.dart';
import '../../../../core/widgets/navigation/appbar_actions.dart';
import '../../../../core/widgets/filter_chip_bar.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/cards/dating_card.dart';
import '../../../../core/widgets/refresh_wrapper.dart';
import '../../../../core/widgets/empty_states/location_required_empty_state.dart';
import '../../../../core/providers/refresh_notifier.dart';
import '../../../../core/providers/location_verification_provider.dart';
import '../providers/dating_provider.dart';
import '../../../pet/presentation/providers/pet_provider.dart';
import 'pet_detail_screen.dart';

/// ============================================================
/// 데이팅 화면 (V3 리팩토링 - 탭 제거, 교배 제거, 필터 통합)
/// 
/// 변경사항:
/// - 상단 탭 제거 → 단일 리스트 + 정렬 필터 칩
/// - 교배 기능 완전 제거
/// - 정렬: 추천순 | 거리순
/// - 검색: 앱바 검색 아이콘
/// ============================================================

/// 정렬 옵션 (0: 추천순, 1: 거리순)
final _selectedSortProvider = StateProvider<int>((ref) => 0);

/// 거리 필터 - 기본값 5km (거리순 정렬 시 사용)
final _distanceFilterProvider = StateProvider<double>((ref) => LocationConstants.defaultRadiusKm);

class DatingScreen extends ConsumerStatefulWidget {
  final int initialTab;
  
  const DatingScreen({super.key, this.initialTab = 0});

  @override
  ConsumerState<DatingScreen> createState() => _DatingScreenState();
}

class _DatingScreenState extends ConsumerState<DatingScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final selectedSort = ref.read(_selectedSortProvider);
      if (selectedSort == 1) {
        final distanceFilter = ref.read(_distanceFilterProvider);
        ref.read(paginatedNearbyPetsProvider(distanceFilter).notifier).loadMore();
      } else {
        ref.read(paginatedRecommendedPetsProvider.notifier).loadMore();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedSort = ref.watch(_selectedSortProvider);
    final distanceFilter = ref.watch(_distanceFilterProvider);
    ref.watch(userPetsProvider);

    ref.listen(datingRefreshProvider, (prev, next) {
      if (prev != next) {
        ref.read(paginatedNearbyPetsProvider(distanceFilter).notifier).refresh();
        ref.read(paginatedRecommendedPetsProvider.notifier).refresh();
      }
    });

    final accent = context.features.dating;
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: MingrrAppBar.mainTab(
        title: '데이팅',
        actions: [
          AppBarActionButton.search(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => SearchScreen(
                    searchType: SearchType.breeding,
                    accentColor: accent,
                  ),
                ),
              );
            },
          ),
          AppBarActionButton.notification(),
        ],
      ),
      body: Column(
        children: [
          // 정렬 필터 칩 바
          _buildSortFilterBar(context, ref, selectedSort, accent, colorScheme),
          
          // 거리순 선택 시 거리 필터 표시
          if (selectedSort == 1)
            LocationDistanceBar(
              accentColor: accent,
              currentDistance: distanceFilter,
              distanceOptions: LocationConstants.datingDistanceOptions,
              onDistanceChanged: (distance) {
                ref.read(_distanceFilterProvider.notifier).state = distance;
              },
            ),
          
          // 컨텐츠
          Expanded(
            child: _buildContent(context, ref, selectedSort, distanceFilter),
          ),
        ],
      ),
    );
  }

  /// 정렬 필터 칩 바
  Widget _buildSortFilterBar(BuildContext context, WidgetRef ref, int selectedSort, Color accent, ColorScheme colorScheme) {
    return MingrrFilterChipBar<int>(
      items: const [
        (key: 0, label: '추천순'),
        (key: 1, label: '거리순'),
      ],
      selected: selectedSort,
      onSelected: (key) => ref.read(_selectedSortProvider.notifier).state = key,
      accentColor: accent,
    );
  }

  /// 정렬별 컨텐츠
  Widget _buildContent(BuildContext context, WidgetRef ref, int selectedSort, double distanceFilter) {
    final userAsync = ref.watch(currentUserStreamProvider);
    final user = userAsync.valueOrNull;
    final isLocationVerified = user?.isLocationVerified ?? false;
    
    if (!isLocationVerified) {
      return LocationRequiredEmptyState(
        type: LocationRequiredType.dating,
        accentColor: context.features.dating,
      );
    }
    
    switch (selectedSort) {
      case 0:
        return _buildRecommendList(context);
      case 1:
        return _buildNearbyGrid(context, distanceFilter);
      default:
        return _buildRecommendList(context);
    }
  }

  /// 상세화면으로 이동
  void _navigateToDetail(
    BuildContext context, 
    String petId, {
    bool isBreeding = false,
    double? distanceMeters,
    int? matchScore,
    String? breedingPostId,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PetDetailScreen(
          petId: petId,
          isBreeding: isBreeding,
          cachedDistanceMeters: distanceMeters,
          cachedMatchScore: matchScore,
          breedingPostId: breedingPostId,
        ),
      ),
    );
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
              Icon(AppIcons.pet, size: 48, color: Theme.of(context).colorScheme.outlineVariant),
              const SizedBox(height: AppSizes.gapL),
              Text(
                '반려동물을 먼저 등록해주세요',
                style: AppTextStyles.bodyMedium(context).withWeight(FontWeight.w500).withColor(Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSizes.gapS),
              Text(
                '내 반려동물을 등록하면\n추천 친구를 찾아드릴게요!',
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
        icon: AppIcons.radar,
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
        controller: _scrollController,
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
      isMale: pet.gender == PetGender.male,
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
              Icon(AppIcons.pet, size: 48, color: Theme.of(context).colorScheme.outlineVariant),
              const SizedBox(height: AppSizes.gapL),
              Text(
                '반려동물을 먼저 등록해주세요',
                style: AppTextStyles.bodyMedium(context).withWeight(FontWeight.w500).withColor(Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSizes.gapS),
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
        icon: AppIcons.autoAwesome,
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
        controller: _scrollController,
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
