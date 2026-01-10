import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// ============================================================
/// 공통 상단 네비게이션 컴포넌트
/// 
/// 이미지 참고 디자인:
/// - 3개 탭 (pill 형태, 둥근 모서리)
/// - 위치/거리 필터 바 (선택적)
/// - 카테고리 필터 (선택적)
/// 
/// 사용 화면: 데이팅, 마켓, 소모임, 채팅
/// ============================================================

/// ------------------------------------------------------------
/// 탭 아이템 정의
/// ------------------------------------------------------------
class TopNavTab {
  final String label;
  final String? emoji;
  final IconData? icon;
  final Color color;

  const TopNavTab({
    required this.label,
    this.emoji,
    this.icon,
    required this.color,
  });
}

/// ------------------------------------------------------------
/// Pill 형태의 탭 바
/// 
/// 3개 탭을 가로로 배치, 선택된 탭은 색상으로 강조
/// [tabs]: 탭 목록
/// [selectedIndex]: 선택된 탭 인덱스
/// [onTabSelected]: 탭 선택 콜백
/// [backgroundColor]: 배경색 (기본: 투명)
/// ------------------------------------------------------------
class PillTabBar extends StatelessWidget {
  final List<TopNavTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final Color? backgroundColor;

  const PillTabBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: backgroundColor,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.divider.withOpacity(0.3),
          borderRadius: BorderRadius.circular(30),
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
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? tab.color : Colors.transparent,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: tab.color.withOpacity(0.3),
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
                          style: const TextStyle(fontSize: 16),
                        )
                      else if (tab.icon != null)
                        Icon(
                          tab.icon,
                          size: 18,
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                        ),
                      const SizedBox(width: 6),
                      // 라벨
                      Text(
                        tab.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected ? Colors.white : AppColors.textPrimary,
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
/// 위치/거리 필터 바
/// 
/// 내 동네 + 거리 선택 + 반경 표시
/// [accentColor]: 테마 색상
/// [currentDistance]: 현재 거리 (km)
/// [onDistanceChanged]: 거리 변경 콜백
/// [distanceOptions]: 거리 옵션 목록
/// ------------------------------------------------------------
class LocationDistanceBar extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.divider.withOpacity(0.5)),
        ),
      ),
      child: Row(
        children: [
          // 위치 아이콘
          Icon(Icons.location_on, size: 18, color: accentColor),
          const SizedBox(width: 6),
          
          // 위치 라벨
          Text(
            locationLabel ?? '내 동네',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 10),
          
          // 거리 선택 버튼
          GestureDetector(
            onTap: () => _showDistanceSelector(context),
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
                    '${currentDistance.toInt()}km',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: 18,
                    color: accentColor,
                  ),
                ],
              ),
            ),
          ),
          
          const Spacer(),
          
          // 반경 표시
          Text(
            '반경 ${currentDistance.toInt()}km 이내',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _showDistanceSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 드래그 핸들
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // 헤더 (타이틀 + X 버튼)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const SizedBox(width: 40),
                  const Expanded(
                    child: Text(
                      '거리 설정',
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
            // 안내 문구
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '집 주소 기준으로 필터링합니다',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 12),
            // 구분선
            const Divider(height: 1),
            // 스크롤 가능한 리스트
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 20),
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
                      color: isSelected ? accentColor : AppColors.textHint,
                    ),
                    title: Text(
                      '${distance.toInt()}km',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? accentColor : AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      _getDistanceDescription(distance),
                      style: const TextStyle(fontSize: 12),
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: List.generate(categories.length, (index) {
            final category = categories[index];
            final isSelected = index == selectedIndex;
            
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => onSelected(index),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? accentColor.withOpacity(0.15) 
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? accentColor : AppColors.divider,
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
                          color: isSelected ? accentColor : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 2),
                      ],
                      // 이모지
                      if (category.emoji != null) ...[
                        Text(category.emoji!, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 4),
                      ],
                      // 아이콘
                      if (category.icon != null) ...[
                        Icon(
                          category.icon,
                          size: 16,
                          color: isSelected ? accentColor : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                      ],
                      // 라벨
                      Text(
                        category.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected ? accentColor : AppColors.textPrimary,
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
