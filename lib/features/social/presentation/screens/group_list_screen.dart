import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/theme/feature_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/pet_constants.dart';
import '../../../../core/widgets/sheets/mingrr_bottom_sheet.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/mingrr_image.dart';
import '../../../../core/widgets/badges/svg_icons.dart';
import '../../../../core/widgets/filter_components.dart';
import '../../../../core/widgets/forms/location_selector.dart';
import '../../../../core/widgets/badges/info_badge.dart';
import '../../../../core/widgets/refresh_wrapper.dart';
import '../../../../core/widgets/navigation/top_navigation.dart';
import '../../../../core/widgets/empty_states/location_required_empty_state.dart';
import '../../../../core/constants/location_constants.dart';
import '../../../../core/providers/refresh_notifier.dart';
import '../../../../core/providers/location_verification_provider.dart';
import '../providers/group_provider.dart';
import 'group_detail_screen.dart';
import 'group_write_screen.dart';

/// ============================================================
/// 소모임(Group) 목록 화면
/// 
/// 소셜 > 소모임 탭
/// 그룹 모임 목록, 지역/카테고리 필터, 정렬
/// ============================================================

/// 선택된 지역 목록
final _selectedLocationsProvider = StateProvider<List<String>>((ref) => []);

/// 선택된 카테고리 인덱스
final _selectedCategoryProvider = StateProvider<int>((ref) => 0);

class GroupListScreen extends ConsumerStatefulWidget {
  const GroupListScreen({super.key});

  @override
  ConsumerState<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends ConsumerState<GroupListScreen> {
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
      ref.read(paginatedGroupsProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedLocations = ref.watch(_selectedLocationsProvider);
    final selectedCategory = ref.watch(_selectedCategoryProvider);
    final accentColor = context.features.social;

    // 새로고침 트리거 감지 (등록/수정/삭제 후 자동 새로고침)
    ref.listen(groupRefreshProvider, (prev, next) {
      if (prev != next) {
        ref.read(paginatedGroupsProvider.notifier).refresh();
        ref.invalidate(userGroupsProvider);
      }
    });

    // 카테고리 목록 (아이콘 제거)
    final categories = [
      '전체',
      ...GroupCategory.values.map((c) => c.label.replaceAll(' 모임', '')),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // 지역 필터
          _buildLocationFilterBar(context, ref, selectedLocations),

          // 카테고리 필터
          _buildCategoryFilter(context, ref, categories, selectedCategory, accentColor),

          // 정렬 옵션
          _buildSortOptions(context, ref),

          // 모임 목록
          Expanded(
            child: _buildContent(context, ref, selectedLocations),
          ),
        ],
      ),
      floatingActionButton: MingrrFAB.add(
        onPressed: () => _showCreateGroupSheet(context),
        backgroundColor: accentColor,
        heroTag: 'group_fab',
        tooltip: '모임 만들기',
      ),
    );
  }

  Widget _buildLocationFilterBar(BuildContext context, WidgetRef ref, List<String> selectedLocations) {
    return LocationRegionBar(
      accentColor: context.features.social,
      selectedLocations: selectedLocations,
      onTap: () => _showLocationSelector(context, ref),
      onReset: () => ref.read(_selectedLocationsProvider.notifier).state = [],
      onRemoveLocation: (location) {
        final current = ref.read(_selectedLocationsProvider);
        ref.read(_selectedLocationsProvider.notifier).state =
            current.where((l) => l != location).toList();
      },
    );
  }

  Widget _buildCategoryFilter(
    BuildContext context,
    WidgetRef ref,
    List<String> categories,
    int selectedIndex,
    Color accentColor,
  ) {
    return MingrrCategoryChips(
      title: '카테고리',
      categories: categories,
      selectedIndex: selectedIndex,
      onSelected: (index) {
        ref.read(_selectedCategoryProvider.notifier).state = index;
      },
      accentColor: accentColor,
    );
  }

  Widget _buildSortOptions(BuildContext context, WidgetRef ref) {
    final sortState = ref.watch(groupSortStateProvider);
    final accentColor = context.features.social;
    
    final sortOptions = ['추천순', '멤버순', '최신순', '좋아요순'];
    final selectedIndex = GroupSortOption.values.indexOf(sortState.option);
    final isAscending = sortState.direction == SortDirection.ascending;

    return MingrrSortChips(
      title: '정렬',
      options: sortOptions,
      selectedIndex: selectedIndex,
      isAscending: isAscending,
      onSelected: (index) {
        final notifier = ref.read(groupSortStateProvider.notifier);
        final option = GroupSortOption.values[index];
        if (sortState.option == option) {
          notifier.state = sortState.toggleDirection();
        } else {
          notifier.state = GroupSortState(option: option, direction: SortDirection.descending);
        }
      },
      accentColor: accentColor,
    );
  }

  /// 컨텐츠 (위치 인증 상태 확인)
  Widget _buildContent(BuildContext context, WidgetRef ref, List<String> locationFilter) {
    // 위치 인증 상태 확인
    final userAsync = ref.watch(currentUserStreamProvider);
    final user = userAsync.valueOrNull;
    final isLocationVerified = user?.isLocationVerified ?? false;
    
    // 위치 미인증 시 빈 화면 표시
    if (!isLocationVerified) {
      return LocationRequiredEmptyState(
        type: LocationRequiredType.group,
        accentColor: context.features.social,
      );
    }
    
    return _buildGroupList(context, ref, locationFilter);
  }

  Widget _buildGroupList(BuildContext context, WidgetRef ref, List<String> locationFilter) {
    final paginatedState = ref.watch(paginatedGroupsProvider);
    final myGroupsAsync = ref.watch(userGroupsProvider);
    final accentColor = context.features.social;

    // 지역 필터 적용
    final allGroups = paginatedState.items;
    final filteredGroups = locationFilter.isEmpty
        ? allGroups
        : allGroups.where((g) {
            final address = g.group.address ?? '';
            return locationFilter.any((loc) => address.contains(loc));
          }).toList();

    // 초기 로딩 상태
    if (paginatedState.isInitialLoading) {
      return MingrrLoadingState(
        type: MingrrLoadingType.community,
        message: '모임 목록을 불러오고 있어요',
      );
    }

    return MingrrRefreshWrapper(
      color: accentColor,
      onRefresh: () async {
        await ref.read(paginatedGroupsProvider.notifier).refresh();
        ref.invalidate(userGroupsProvider);
      },
      child: ListView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSizes.paddingL),
        children: [
          // 내 모임 섹션
          myGroupsAsync.when(
            data: (myGroups) {
              if (myGroups.isEmpty) {
                return _buildEmptyMyGroups(context);
              }
              return _buildMyGroupsSection(context, ref, myGroups);
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: AppSizes.gapXL),

          // 모임 목록 헤더
          Text('모임 목록', style: AppTextStyles.headlineSmall(context)),
          const SizedBox(height: AppSizes.gapM),

          // 모임 카드들
          if (filteredGroups.isEmpty)
            MingrrEmptyState(
              icon: AppIcons.group,
              title: '아직 데이터가 없어요',
              subtitle: '새로운 모임을 만들어보세요',
              buttonText: '모임 만들기',
              onButtonPressed: () => _showCreateGroupSheet(context),
              accentColor: accentColor,
            )
          else
            ...filteredGroups.asMap().entries.map((entry) => MingrrAnimatedListItem(
                  index: entry.key,
                  child: _GroupCard(
                    groupWithDistance: entry.value,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GroupDetailScreen(groupId: entry.value.group.id),
                      ),
                    ),
                  ),
                )),

          // 로딩 인디케이터
          if (paginatedState.hasMore)
            const Padding(
              padding: EdgeInsets.all(AppSizes.paddingL),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildEmptyMyGroups(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('내 모임', style: AppTextStyles.headlineSmall(context)),
        const SizedBox(height: AppSizes.gapL),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSizes.paddingXL),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppSizes.radiusM),
          ),
          child: Column(
            children: [
              Icon(AppIcons.group, size: 48, color: colorScheme.outlineVariant),
              const SizedBox(height: AppSizes.gapL),
              Text(
                '가입한 모임이 없어요',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppSizes.gapS),
              Text(
                '관심 있는 모임에 가입해보세요',
                style: AppTextStyles.caption(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMyGroupsSection(BuildContext context, WidgetRef ref, List<dynamic> myGroups) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('내 모임', style: AppTextStyles.headlineSmall(context)),
            TextButton(
              onPressed: () {},
              child: Text('전체보기', style: AppTextStyles.bodySmall(context)),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.gapS),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: myGroups.length,
            itemBuilder: (context, index) {
              final group = myGroups[index];
              return _MyGroupCard(
                name: group.name,
                memberCount: group.memberCount,
                imageUrl: group.imageUrl,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => GroupDetailScreen(groupId: group.id)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showLocationSelector(BuildContext context, WidgetRef ref) {
    final selectedLocations = ref.read(_selectedLocationsProvider);
    final accentColor = context.features.social;
    
    showMultiLocationSelector(
      context: context,
      initialLocations: selectedLocations,
      accentColor: accentColor,
      onLocationsSelected: (locations) {
        ref.read(_selectedLocationsProvider.notifier).state = locations;
      },
    );
  }

  void _showCreateGroupSheet(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GroupWriteScreen()),
    );
  }
}

/// 내 모임 카드
class _MyGroupCard extends StatelessWidget {
  final String name;
  final int memberCount;
  final String? imageUrl;
  final VoidCallback onTap;

  const _MyGroupCard({
    required this.name,
    required this.memberCount,
    this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = context.features.social;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: AppSizes.paddingM),
        padding: const EdgeInsets.all(AppSizes.paddingM),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusS),
          border: Border.all(color: accentColor.withValues(alpha: AppOpacity.o30)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radiusXS),
              child: SizedBox(
                width: 36,
                height: 36,
                child: imageUrl != null && imageUrl!.isNotEmpty
                    ? MingrrImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        accentColor: accentColor,
                        placeholderIcon: AppIcons.group,
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: AppOpacity.o10),
                        ),
                        child: Icon(AppIcons.group, size: 20, color: accentColor),
                      ),
              ),
            ),
            const SizedBox(height: AppSizes.gapS),
            Text(
              name,
              style: AppTextStyles.titleSmall(context),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSizes.gapXXS),
            Text(
              '멤버 $memberCount명',
              style: AppTextStyles.captionSmall(context),
            ),
          ],
        ),
      ),
    );
  }
}

/// 모임 카드
class _GroupCard extends StatelessWidget {
  final GroupWithDistance groupWithDistance;
  final VoidCallback onTap;

  const _GroupCard({
    required this.groupWithDistance,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final group = groupWithDistance.group;
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = context.features.social;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSizes.paddingM),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          boxShadow: AppShadows.shadowS(Theme.of(context).brightness == Brightness.dark),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 이미지
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSizes.radiusL)),
              child: MingrrImage.background(
                imageUrl: group.imageUrl,
                height: group.imageUrl != null ? 120 : 80,
                accentColor: accentColor,
              ),
            ),

            // 정보
            Padding(
              padding: const EdgeInsets.all(AppSizes.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingS, vertical: 3),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: AppOpacity.o10),
                          borderRadius: BorderRadius.circular(AppSizes.radiusXXS),
                        ),
                        child: Text(
                          group.typeString,
                          style: AppTextStyles.labelMedium(context).copyWith(color: accentColor),
                        ),
                      ),
                      const Spacer(),
                      if (groupWithDistance.distanceMeters.isFinite)
                        Text(
                          groupWithDistance.distanceString,
                          style: AppTextStyles.caption(context),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.gapS),
                  Text(
                    group.name,
                    style: AppTextStyles.headlineSmall(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSizes.gapXS),
                  Text(
                    group.description,
                    style: AppTextStyles.bodySmall(context),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSizes.gapM),
                  Row(
                    children: [
                      Icon(LocationConstants.distanceIcon, size: 14, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: AppSizes.gapXS),
                      Expanded(
                        child: Text(
                          group.address ?? LocationConstants.noLocationText,
                          style: AppTextStyles.caption(context),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSizes.gapM),
                      Icon(AppIcons.people, size: 14, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: AppSizes.gapXS),
                      Text(
                        '${group.memberCount}명',
                        style: AppTextStyles.caption(context),
                      ),
                      const SizedBox(width: AppSizes.gapM),
                      LikeCountText(count: group.likeCount, size: InfoBadgeSize.small),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
