import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_sizes.dart';
import '../constants/location_constants.dart';
import '../theme/app_text_styles.dart';
import 'mingrr_bottom_sheet.dart';
import '../providers/location_verification_provider.dart';

/// ============================================================
/// 공통 탭 네비게이션 컴포넌트
/// 
/// 컴포넌트 목록:
/// - MingrrTabItem: 탭 아이템 정의 클래스
/// - MingrrMainTabBar: 메인 화면용 탭 바 (Pill 형태, 아이콘+라벨)
/// - MingrrSubTabBar: 서브 화면용 탭 바 (밑줄 인디케이터, 텍스트만)
/// - LocationDistanceBar: 위치/거리 필터 바
/// 
/// 사용 화면:
/// - MingrrMainTabBar: 데이팅, 마켓, 채팅, 소셜
/// - MingrrSubTabBar: 활동 내역, 거래 내역, 찜한 목록
/// ============================================================

/// ------------------------------------------------------------
/// 탭 아이템 정의
/// 
/// [label]: 탭 라벨 (필수)
/// [emoji]: 이모지 (선택)
/// [icon]: 아이콘 (선택)
/// [color]: 탭 색상 (필수)
/// ------------------------------------------------------------
class MingrrTabItem {
  final String label;
  final String? emoji;
  final IconData? icon;
  final Color color;

  const MingrrTabItem({
    required this.label,
    this.emoji,
    this.icon,
    required this.color,
  });
}

/// ------------------------------------------------------------
/// 메인 화면용 탭 바 (Pill 형태)
/// 
/// 특징:
/// - 둥근 pill 형태 디자인
/// - 아이콘 + 라벨 조합
/// - 선택 시 피처 컬러 배경
/// 
/// 사용처: 데이팅, 마켓, 채팅, 소셜 화면
/// 
/// [tabs]: 탭 목록
/// [selectedIndex]: 선택된 탭 인덱스
/// [onTabSelected]: 탭 선택 콜백
/// [backgroundColor]: 배경색 (기본: surface)
/// ------------------------------------------------------------
class MingrrMainTabBar extends StatelessWidget {
  final List<MingrrTabItem> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final Color? backgroundColor;

  const MingrrMainTabBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL, vertical: AppSizes.paddingS),
      color: backgroundColor ?? colorScheme.surface,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.paddingXS),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppSizes.radiusXXL),
        ),
        child: Row(
          children: List.generate(tabs.length, (index) {
            final tab = tabs[index];
            final isSelected = index == selectedIndex;
            
            return Expanded(
              child: GestureDetector(
                onTap: () => onTabSelected(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingS),
                  decoration: BoxDecoration(
                    color: isSelected ? tab.color : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppSizes.radiusXL),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: tab.color.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 이모지 또는 아이콘
                      if (tab.emoji != null)
                        Text(
                          tab.emoji!,
                          style: AppTextStyles.titleLarge(context),
                        )
                      else if (tab.icon != null)
                        Icon(
                          tab.icon,
                          size: 18,
                          color: isSelected ? Colors.white : colorScheme.onSurfaceVariant,
                        ),
                      const SizedBox(width: AppSizes.gapSM),
                      // 라벨
                      Text(
                        tab.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected ? Colors.white : colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

/// ------------------------------------------------------------
/// 서브 화면용 탭 바 (밑줄 인디케이터)
/// 
/// 특징:
/// - 심플한 밑줄 인디케이터
/// - 텍스트만 표시
/// - DefaultTabController 또는 외부 TabController와 함께 사용
/// 
/// 사용처:
/// - DefaultTabController 내부: 활동 내역, 거래 내역, 찜한 목록
/// - AppBar.bottom: 알림 화면
/// - SliverPersistentHeader: 소모임 상세 (MingrrSubTabBarDelegate 사용)
/// 
/// [tabs]: 탭 라벨 목록
/// [accentColor]: 테마 색상 (기본: primary)
/// [controller]: 외부 TabController (AppBar.bottom, Sliver용)
/// [isScrollable]: 스크롤 가능 여부 (기본: false)
/// ------------------------------------------------------------
class MingrrSubTabBar extends StatelessWidget implements PreferredSizeWidget {
  final List<String> tabs;
  final Color? accentColor;
  final TabController? controller;
  final bool isScrollable;

  const MingrrSubTabBar({
    super.key,
    required this.tabs,
    this.accentColor,
    this.controller,
    this.isScrollable = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(48);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveColor = accentColor ?? colorScheme.primary;
    
    return Container(
      color: colorScheme.surface,
      child: TabBar(
        controller: controller,
        labelColor: effectiveColor,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        indicatorColor: effectiveColor,
        isScrollable: isScrollable,
        tabs: tabs.map((label) => Tab(text: label)).toList(),
      ),
    );
  }
}

/// ------------------------------------------------------------
/// Sliver용 탭 바 델리게이트
/// 
/// NestedScrollView 내 SliverPersistentHeader에서 사용
/// 스크롤 시 탭바가 상단에 고정됨
/// 
/// 사용처: 소모임 상세 화면
/// 
/// [tabs]: 탭 라벨 목록
/// [controller]: TabController
/// [accentColor]: 테마 색상 (기본: primary)
/// ------------------------------------------------------------
class MingrrSubTabBarDelegate extends SliverPersistentHeaderDelegate {
  final List<String> tabs;
  final TabController controller;
  final Color? accentColor;

  MingrrSubTabBarDelegate({
    required this.tabs,
    required this.controller,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return MingrrSubTabBar(
      tabs: tabs,
      controller: controller,
      accentColor: accentColor,
    );
  }

  @override
  double get maxExtent => 48;

  @override
  double get minExtent => 48;

  @override
  bool shouldRebuild(covariant MingrrSubTabBarDelegate oldDelegate) => false;
}

/// ------------------------------------------------------------
/// 위치/거리 필터 바
/// 
/// 내 동네 + 거리 선택 + 반경 표시
/// 위치 인증 상태에 따라 UI 변경
/// [accentColor]: 테마 색상
/// [currentDistance]: 현재 거리 (km)
/// [onDistanceChanged]: 거리 변경 콜백
/// [distanceOptions]: 거리 옵션 목록
/// ------------------------------------------------------------
class LocationDistanceBar extends ConsumerWidget {
  final Color accentColor;
  final double currentDistance;
  final ValueChanged<double> onDistanceChanged;
  final List<double> distanceOptions;
  final String? locationLabel;

  const LocationDistanceBar({
    super.key,
    required this.accentColor,
    required this.currentDistance,
    required this.onDistanceChanged,
    this.distanceOptions = const [1, 3, 5, 10, 20, 50],
    this.locationLabel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // 사용자 정보 가져오기
    final userAsync = ref.watch(currentUserStreamProvider);
    final user = userAsync.valueOrNull;
    final isLocationVerified = user?.isLocationVerified ?? false;
    final homeAddress = user?.homeAddress;
    
    // 위치 인증이 안 된 경우 안내 표시
    final displayLabel = locationLabel ?? 
        (isLocationVerified && homeAddress != null 
            ? homeAddress 
            : '내 동네');
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL, vertical: AppSizes.paddingXS),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          // 위치 아이콘 (인증 상태에 따라 색상 변경)
          Icon(
            isLocationVerified ? Icons.location_on : Icons.location_off_outlined,
            size: 18,
            color: isLocationVerified ? accentColor : colorScheme.outline,
          ),
          const SizedBox(width: AppSizes.gapSM),
          
          // 위치 라벨
          Expanded(
            child: Text(
              displayLabel,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isLocationVerified ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSizes.gapMS),
          
          // 거리 선택 버튼
          GestureDetector(
            onTap: () => _showDistanceSelector(context, ref),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingS, vertical: AppSizes.paddingXS),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppSizes.radiusS),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${currentDistance.toInt()}km',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(width: AppSizes.gapXS),
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: 18,
                    color: accentColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDistanceSelector(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final userAsync = ref.read(currentUserStreamProvider);
    final user = userAsync.valueOrNull;
    final isLocationVerified = user?.isLocationVerified ?? false;
    final homeAddress = user?.homeAddress;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSizes.bottomSheetRadius)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BottomSheetHandle(),
            // 헤더
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL, vertical: AppSizes.paddingS),
              child: Text(
                '거리 설정',
                style: AppTextStyles.headlineSmall(context),
                textAlign: TextAlign.center,
              ),
            ),
            // 안내 문구 (위치 인증 상태에 따라 다르게 표시)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL),
              child: isLocationVerified
                  ? Text(
                      homeAddress ?? '집 주소 기준으로 필터링합니다',
                      style: AppTextStyles.secondary(context),
                      textAlign: TextAlign.center,
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline, size: 14, color: colorScheme.outline),
                        const SizedBox(width: AppSizes.gapXS),
                        Text(
                          '위치 인증 후 정확한 거리 필터링이 가능합니다',
                          style: AppTextStyles.secondarySmall(context),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: AppSizes.gapM),
            // 스크롤 가능한 리스트
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingXL),
                children: distanceOptions.map((distance) {
                  final isSelected = currentDistance == distance;
                  return ListTile(
                    onTap: () {
                      onDistanceChanged(distance);
                      Navigator.pop(context);
                    },
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: Icon(
                      isSelected ? Icons.check_circle : Icons.circle_outlined,
                      color: isSelected ? accentColor : colorScheme.onSurfaceVariant,
                    ),
                    title: Text(
                      '${distance.toInt()}km',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? accentColor : colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      _getDistanceDescription(distance),
                      style: AppTextStyles.secondarySmall(context),
                    ),
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  String _getDistanceDescription(double distance) {
    if (distance <= 1) return '가까운 이웃';
    if (distance <= 3) return '동네 범위';
    if (distance <= 5) return '조금 넓은 범위';
    if (distance <= 10) return '넓은 범위';
    if (distance <= 20) return '광역 범위';
    return '최대 범위';
  }
}

/// ------------------------------------------------------------
/// 카테고리 필터 칩 (가로 스크롤)
/// 
/// [categories]: 카테고리 목록 (label, emoji 또는 icon)
/// [selectedIndex]: 선택된 인덱스
/// [onSelected]: 선택 콜백
/// [accentColor]: 테마 색상
/// [showDropdownIcon]: 드롭다운 아이콘 표시 여부
/// ------------------------------------------------------------
class CategoryFilterChips extends StatelessWidget {
  final List<({String label, String? emoji, IconData? icon})> categories;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final Color accentColor;
  final bool showDropdownIcon;

  const CategoryFilterChips({
    super.key,
    required this.categories,
    required this.selectedIndex,
    required this.onSelected,
    required this.accentColor,
    this.showDropdownIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingS),
      color: colorScheme.surface,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL),
        child: Row(
          children: List.generate(categories.length, (index) {
            final category = categories[index];
            final isSelected = index == selectedIndex;
            
            return Padding(
              padding: const EdgeInsets.only(right: AppSizes.paddingS),
              child: GestureDetector(
                onTap: () => onSelected(index),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppSizes.paddingS),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? accentColor.withValues(alpha: 0.15) 
                        : colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppSizes.radiusL),
                    border: Border.all(
                      color: isSelected ? accentColor : colorScheme.outline,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 드롭다운 아이콘 (첫 번째 항목만)
                      if (showDropdownIcon && index == 0) ...[
                        Icon(
                          Icons.keyboard_arrow_down,
                          size: 18,
                          color: isSelected ? accentColor : colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 2),
                      ],
                      // 이모지
                      if (category.emoji != null) ...[
                        Text(category.emoji!, style: AppTextStyles.labelLarge(context)),
                        const SizedBox(width: AppSizes.gapXS),
                      ],
                      // 아이콘
                      if (category.icon != null) ...[
                        Icon(
                          category.icon,
                          size: 16,
                          color: isSelected ? accentColor : colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: AppSizes.gapXS),
                      ],
                      // 라벨
                      Text(
                        category.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected ? accentColor : colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

/// ------------------------------------------------------------
/// 지역 선택 바 (소모임 등에서 사용)
/// 
/// LocationDistanceBar와 동일한 패턴으로 공통화
/// [accentColor]: 강조 색상
/// [selectedLocations]: 선택된 지역 목록
/// [onTap]: 지역 선택 버튼 탭 콜백
/// [onReset]: 초기화 버튼 탭 콜백
/// [onRemoveLocation]: 개별 지역 제거 콜백
/// ------------------------------------------------------------
class LocationRegionBar extends StatelessWidget {
  final Color accentColor;
  final List<String> selectedLocations;
  final VoidCallback onTap;
  final VoidCallback onReset;
  final ValueChanged<String> onRemoveLocation;

  const LocationRegionBar({
    super.key,
    required this.accentColor,
    required this.selectedLocations,
    required this.onTap,
    required this.onReset,
    required this.onRemoveLocation,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL, vertical: AppSizes.paddingXS),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(bottom: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LocationConstants.distanceIcon, size: 18, color: accentColor),
              const SizedBox(width: AppSizes.gapSM),
              GestureDetector(
                onTap: onTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingS, vertical: AppSizes.paddingXS),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppSizes.radiusS),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        selectedLocations.isEmpty ? '전체 지역' : '지역 선택',
                        style: AppTextStyles.titleSmall(context).copyWith(color: accentColor),
                      ),
                      const SizedBox(width: AppSizes.gapXS),
                      Icon(Icons.keyboard_arrow_down, size: 18, color: accentColor),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              if (selectedLocations.isNotEmpty)
                GestureDetector(
                  onTap: onReset,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingS, vertical: AppSizes.paddingXS),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(AppSizes.radiusS),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.refresh, size: 14, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 2),
                        Text('초기화', style: AppTextStyles.cardMeta(context)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          if (selectedLocations.isNotEmpty) ...[
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: selectedLocations.map((location) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingS, vertical: AppSizes.paddingXS),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppSizes.radiusS),
                        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(location, style: AppTextStyles.tag(context).copyWith(color: accentColor)),
                          const SizedBox(width: AppSizes.gapXS),
                          GestureDetector(
                            onTap: () => onRemoveLocation(location),
                            child: Icon(Icons.close, size: 14, color: accentColor),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
