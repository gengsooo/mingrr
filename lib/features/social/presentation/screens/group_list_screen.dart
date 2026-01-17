import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/feature_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/pet_constants.dart';
import '../../../../core/widgets/mingrr_bottom_sheet.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/svg_icons.dart';
import '../../../../core/widgets/filter_components.dart';
import '../../../../core/widgets/location_selector.dart';
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

class GroupListScreen extends ConsumerWidget {
  const GroupListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedLocations = ref.watch(_selectedLocationsProvider);
    final selectedCategory = ref.watch(_selectedCategoryProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = context.features.social;

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
            child: _buildGroupList(context, ref, selectedLocations),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'group_fab',
        onPressed: () => _showCreateGroupSheet(context),
        backgroundColor: accentColor,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildLocationFilterBar(BuildContext context, WidgetRef ref, List<String> selectedLocations) {
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = context.features.social;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(bottom: BorderSide(color: colorScheme.outline.withOpacity(0.3))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, size: 18, color: accentColor),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => _showLocationSelector(context, ref),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        selectedLocations.isEmpty ? '전체 지역' : '지역 선택',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: accentColor),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.keyboard_arrow_down, size: 18, color: accentColor),
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
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(AppSizes.radiusS),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.refresh, size: 14, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 2),
                        Text('초기화', style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          if (selectedLocations.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: selectedLocations.map((location) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: accentColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(location, style: TextStyle(fontSize: 12, color: accentColor, fontWeight: FontWeight.w500)),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () {
                          final current = ref.read(_selectedLocationsProvider);
                          ref.read(_selectedLocationsProvider.notifier).state =
                              current.where((l) => l != location).toList();
                        },
                        child: Icon(Icons.close, size: 14, color: accentColor),
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

  Widget _buildGroupList(BuildContext context, WidgetRef ref, List<String> locationFilter) {
    final sortedGroups = ref.watch(sortedGroupsProvider);
    final myGroupsAsync = ref.watch(userGroupsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = context.features.social;

    final filteredGroups = locationFilter.isEmpty
        ? sortedGroups
        : sortedGroups.where((g) {
            final address = g.group.address ?? '';
            return locationFilter.any((loc) => address.contains(loc));
          }).toList();

    return RefreshIndicator(
      color: accentColor,
      onRefresh: () async {
        ref.invalidate(sortedGroupsProvider);
        ref.invalidate(userGroupsProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
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
          const SizedBox(height: 24),

          // 모임 목록 헤더
          const Text('모임 목록', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),

          // 모임 카드들
          if (filteredGroups.isEmpty)
            MingrrEmptyState(
              icon: Icons.groups_outlined,
              title: '아직 데이터가 없어요',
              subtitle: '새로운 모임을 만들어보세요',
              buttonText: '모임 만들기',
              onButtonPressed: () => _showCreateGroupSheet(context),
              accentColor: accentColor,
            )
          else
            ...filteredGroups.map((groupWithDistance) => _GroupCard(
                  groupWithDistance: groupWithDistance,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GroupDetailScreen(groupId: groupWithDistance.group.id),
                    ),
                  ),
                )),

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
        const Text('내 모임', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppSizes.radiusM),
          ),
          child: Column(
            children: [
              Icon(Icons.groups_outlined, size: 48, color: colorScheme.outlineVariant),
              const SizedBox(height: 16),
              Text(
                '가입한 모임이 없어요',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '관심 있는 모임에 가입해보세요',
                style: TextStyle(fontSize: 12, color: colorScheme.outlineVariant),
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
            const Text('내 모임', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            TextButton(
              onPressed: () {},
              child: const Text('전체보기', style: TextStyle(fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: myGroups.length,
            itemBuilder: (context, index) {
              final group = myGroups[index];
              return _MyGroupCard(
                name: group.name,
                memberCount: group.memberCount,
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
  final VoidCallback onTap;

  const _MyGroupCard({
    required this.name,
    required this.memberCount,
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
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppSizes.radiusS),
          border: Border.all(color: accentColor.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.groups, size: 20, color: accentColor),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              '멤버 $memberCount명',
              style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
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
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 이미지
            if (group.imageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  group.imageUrl!,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 120,
                    color: accentColor.withOpacity(0.1),
                    child: Center(child: Icon(Icons.groups, size: 40, color: accentColor)),
                  ),
                ),
              )
            else
              Container(
                height: 80,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Center(child: Icon(Icons.groups, size: 40, color: accentColor)),
              ),

            // 정보
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          group.typeString,
                          style: TextStyle(fontSize: 11, color: accentColor, fontWeight: FontWeight.w500),
                        ),
                      ),
                      const Spacer(),
                      if (groupWithDistance.distanceMeters.isFinite)
                        Text(
                          groupWithDistance.distanceString,
                          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    group.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    group.description,
                    style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 14, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          group.address ?? '지역 미설정',
                          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.people_outline, size: 14, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        '${group.memberCount}명',
                        style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.favorite_outline, size: 14, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        '${group.likeCount}',
                        style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                      ),
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
