import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/feature_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/pet_constants.dart';
import '../../../../core/widgets/mingrr_bottom_sheet.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/svg_icons.dart';
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

    final categories = [
      (label: '전체', icon: Icons.grid_view),
      ...GroupCategory.values.map((c) => (label: c.label.replaceAll(' 모임', ''), icon: c.icon)),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(bottom: BorderSide(color: colorScheme.outline.withOpacity(0.2))),
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
    List<({String label, IconData icon})> categories,
    int selectedIndex,
    Color accentColor,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(bottom: BorderSide(color: colorScheme.outline.withOpacity(0.2))),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = selectedIndex == index;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => ref.read(_selectedCategoryProvider.notifier).state = index,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? accentColor : colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? accentColor : colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(category.icon, size: 14, color: isSelected ? Colors.white : accentColor),
                    const SizedBox(width: 4),
                    Text(
                      category.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? Colors.white : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSortOptions(BuildContext context, WidgetRef ref) {
    final sortState = ref.watch(groupSortStateProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = context.features.social;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(bottom: BorderSide(color: colorScheme.outline.withOpacity(0.2))),
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
                  notifier.state = sortState.toggleDirection();
                } else {
                  notifier.state = GroupSortState(option: option, direction: SortDirection.descending);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? accentColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isSelected ? accentColor : colorScheme.outline),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getSortLabel(option),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? Colors.white : colorScheme.onSurfaceVariant,
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
          Row(
            children: [
              const Text('모임 목록', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('${filteredGroups.length}개', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 12),

          // 모임 카드들
          if (filteredGroups.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: MingrrEmptyState(
                  svgAsset: SvgAssets.emptyGroup,
                  title: '아직 데이터가 없어요',
                  subtitle: '새로운 모임을 만들어보세요',
                ),
              ),
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
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(AppSizes.radiusS),
          ),
          child: Column(
            children: [
              Icon(Icons.groups_outlined, size: 40, color: colorScheme.outlineVariant),
              const SizedBox(height: 8),
              Text('아직 데이터가 없어요', style: TextStyle(color: colorScheme.onSurfaceVariant)),
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
    // 지역 선택 바텀시트 (기존 로직 재사용)
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LocationSelectorSheet(ref: ref),
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
          color: colorScheme.surface,
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

/// 지역 선택 바텀시트 (3단계: 시/도 → 시/군 → 구)
class _LocationSelectorSheet extends ConsumerStatefulWidget {
  final WidgetRef ref;

  const _LocationSelectorSheet({required this.ref});

  @override
  ConsumerState<_LocationSelectorSheet> createState() => _LocationSelectorSheetState();
}

class _LocationSelectorSheetState extends ConsumerState<_LocationSelectorSheet> {
  String? _selectedProvince;
  String? _selectedCity;
  final List<String> _tempSelected = [];

  @override
  void initState() {
    super.initState();
    _tempSelected.addAll(widget.ref.read(_selectedLocationsProvider));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = context.features.social;
    final districts = _selectedCity != null 
        ? KoreaLocationData.getDistricts(_selectedProvince!, _selectedCity!)
        : <String>[];

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // 핸들
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outline.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // 헤더
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 8, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('취소', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                ),
                Column(
                  children: [
                    const Text('지역 선택', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                    if (_tempSelected.isNotEmpty)
                      Text(
                        '${_tempSelected.length}개 선택됨',
                        style: TextStyle(fontSize: 12, color: accentColor),
                      ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    widget.ref.read(_selectedLocationsProvider.notifier).state = List.from(_tempSelected);
                    Navigator.pop(context);
                  },
                  child: Text('완료', style: TextStyle(color: accentColor, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          // 선택된 지역 칩들
          if (_tempSelected.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 100),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _tempSelected.map((location) {
                    return Chip(
                      label: Text(location, style: const TextStyle(fontSize: 11)),
                      deleteIcon: const Icon(Icons.close, size: 14),
                      onDeleted: () => setState(() => _tempSelected.remove(location)),
                      backgroundColor: accentColor.withOpacity(0.1),
                      side: BorderSide.none,
                      labelStyle: TextStyle(color: accentColor),
                      deleteIconColor: accentColor,
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),
              ),
            ),
          const Divider(height: 1),
          // 3단 선택 영역
          Expanded(
            child: Row(
              children: [
                // 1단계: 시/도
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow,
                      border: Border(right: BorderSide(color: colorScheme.outline.withOpacity(0.2))),
                    ),
                    child: ListView(
                      children: KoreaLocationData.getProvinces().map((province) {
                        final isSelected = _selectedProvince == province;
                        return InkWell(
                          onTap: () => setState(() {
                            _selectedProvince = province;
                            _selectedCity = null;
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              color: isSelected ? accentColor.withOpacity(0.1) : null,
                              border: Border(
                                left: BorderSide(
                                  color: isSelected ? accentColor : Colors.transparent,
                                  width: 3,
                                ),
                              ),
                            ),
                            child: Text(
                              province,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                color: isSelected ? accentColor : colorScheme.onSurface,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                // 2단계: 시/군
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(right: BorderSide(color: colorScheme.outline.withOpacity(0.2))),
                    ),
                    child: _selectedProvince == null
                        ? Center(
                            child: Text(
                              '시/도 선택',
                              style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                            ),
                          )
                        : ListView(
                            children: KoreaLocationData.getCities(_selectedProvince!).map((city) {
                              final isSelected = _selectedCity == city;
                              final hasDistricts = KoreaLocationData.getDistricts(_selectedProvince!, city).isNotEmpty;
                              return InkWell(
                                onTap: () {
                                  if (hasDistricts) {
                                    setState(() => _selectedCity = city);
                                  } else {
                                    // 구가 없으면 바로 선택
                                    final locationKey = '$_selectedProvince $city';
                                    setState(() {
                                      if (_tempSelected.contains(locationKey)) {
                                        _tempSelected.remove(locationKey);
                                      } else {
                                        _tempSelected.add(locationKey);
                                      }
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: isSelected ? accentColor.withOpacity(0.1) : null,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          city,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                            color: isSelected ? accentColor : colorScheme.onSurface,
                                          ),
                                        ),
                                      ),
                                      if (hasDistricts)
                                        Icon(Icons.chevron_right, size: 18, color: colorScheme.onSurfaceVariant)
                                      else if (_tempSelected.contains('$_selectedProvince $city'))
                                        Icon(Icons.check, size: 18, color: accentColor),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                ),
                // 3단계: 구
                Expanded(
                  child: districts.isEmpty
                      ? Center(
                          child: Text(
                            _selectedCity == null ? '시/군 선택' : '전체 선택됨',
                            style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                          ),
                        )
                      : ListView(
                          children: districts.map((district) {
                            final locationKey = '$_selectedProvince $_selectedCity $district';
                            final isSelected = _tempSelected.contains(locationKey);
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    _tempSelected.remove(locationKey);
                                  } else {
                                    _tempSelected.add(locationKey);
                                  }
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        district,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                          color: isSelected ? accentColor : colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(Icons.check, size: 18, color: accentColor),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 한국 지역 데이터 (3단계: 시/도 → 시/군 → 구)
class KoreaLocationData {
  // 시/도 → 시/군 데이터
  static const Map<String, List<String>> data = {
    '서울특별시': ['강남구', '서초구', '송파구', '강동구', '마포구', '영등포구', '용산구', '종로구', '중구', '성동구', '광진구', '동대문구', '중랑구', '성북구', '강북구', '도봉구', '노원구', '은평구', '서대문구', '양천구', '강서구', '구로구', '금천구', '동작구', '관악구'],
    '경기도': ['수원시', '성남시', '용인시', '고양시', '부천시', '안산시', '안양시', '남양주시', '화성시', '평택시', '의정부시', '시흥시', '파주시', '김포시', '광명시', '광주시', '군포시', '하남시', '오산시', '이천시', '안성시', '의왕시', '양주시', '포천시', '구리시', '여주시', '동두천시', '과천시'],
    '인천광역시': ['중구', '동구', '미추홀구', '연수구', '남동구', '부평구', '계양구', '서구', '강화군', '옹진군'],
    '부산광역시': ['중구', '서구', '동구', '영도구', '부산진구', '동래구', '남구', '북구', '해운대구', '사하구', '금정구', '강서구', '연제구', '수영구', '사상구', '기장군'],
    '대구광역시': ['중구', '동구', '서구', '남구', '북구', '수성구', '달서구', '달성군'],
    '대전광역시': ['동구', '중구', '서구', '유성구', '대덕구'],
    '광주광역시': ['동구', '서구', '남구', '북구', '광산구'],
    '울산광역시': ['중구', '남구', '동구', '북구', '울주군'],
    '세종특별자치시': ['세종시'],
    '강원특별자치도': ['춘천시', '원주시', '강릉시', '동해시', '태백시', '속초시', '삼척시'],
    '충청북도': ['청주시', '충주시', '제천시'],
    '충청남도': ['천안시', '공주시', '보령시', '아산시', '서산시', '논산시', '계룡시', '당진시'],
    '전북특별자치도': ['전주시', '군산시', '익산시', '정읍시', '남원시', '김제시'],
    '전라남도': ['목포시', '여수시', '순천시', '나주시', '광양시'],
    '경상북도': ['포항시', '경주시', '김천시', '안동시', '구미시', '영주시', '영천시', '상주시', '문경시', '경산시'],
    '경상남도': ['창원시', '진주시', '통영시', '사천시', '김해시', '밀양시', '거제시', '양산시'],
    '제주특별자치도': ['제주시', '서귀포시'],
  };

  // 시/군 → 구 데이터 (구가 있는 시만)
  static const Map<String, Map<String, List<String>>> districtData = {
    '경기도': {
      '수원시': ['장안구', '권선구', '팔달구', '영통구'],
      '성남시': ['수정구', '중원구', '분당구'],
      '용인시': ['처인구', '기흥구', '수지구'],
      '고양시': ['덕양구', '일산동구', '일산서구'],
      '안산시': ['상록구', '단원구'],
      '안양시': ['만안구', '동안구'],
    },
    '충청북도': {
      '청주시': ['상당구', '서원구', '흥덕구', '청원구'],
    },
    '충청남도': {
      '천안시': ['동남구', '서북구'],
    },
    '전북특별자치도': {
      '전주시': ['완산구', '덕진구'],
    },
    '경상북도': {
      '포항시': ['남구', '북구'],
    },
    '경상남도': {
      '창원시': ['의창구', '성산구', '마산합포구', '마산회원구', '진해구'],
    },
  };

  static List<String> getProvinces() => data.keys.toList();
  static List<String> getCities(String province) => data[province] ?? [];
  static List<String> getDistricts(String province, String city) {
    return districtData[province]?[city] ?? [];
  }
}
