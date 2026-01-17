import 'package:flutter/material.dart';
import '../constants/app_sizes.dart';

/// ============================================================
/// 공통 필터 컴포넌트
/// 
/// 모든 화면에서 일관된 디자인으로 사용:
/// - MingrrFilterChip: 기본 필터 칩
/// - MingrrFilterRow: 타이틀 + 칩 행
/// - MingrrFilterSection: 필터 섹션 컨테이너
/// - MingrrCategoryChips: 카테고리 칩 목록 (가로 스크롤)
/// - MingrrSortChip: 정렬 칩 (오름차순/내림차순)
/// 
/// 디자인 기준: 데이팅-교배찾기 화면
/// ============================================================

/// ------------------------------------------------------------
/// 기본 필터 칩
/// 
/// [label]: 칩 텍스트
/// [isSelected]: 선택 상태
/// [onTap]: 탭 콜백
/// [icon]: 아이콘 (선택)
/// [accentColor]: 강조 색상 (선택, 기본: context에서 가져옴)
/// ------------------------------------------------------------
class MingrrFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? accentColor;

  const MingrrFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final chipColor = accentColor ?? Theme.of(context).primaryColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? chipColor : colorScheme.outline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 12,
                color: isSelected ? Colors.white : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? Colors.white : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ------------------------------------------------------------
/// 정렬 칩 (오름차순/내림차순 표시)
/// 
/// [label]: 칩 텍스트
/// [isSelected]: 선택 상태
/// [isAscending]: 오름차순 여부 (선택된 경우에만 표시)
/// [onTap]: 탭 콜백
/// [accentColor]: 강조 색상
/// ------------------------------------------------------------
class MingrrSortChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isAscending;
  final VoidCallback onTap;
  final Color? accentColor;

  const MingrrSortChip({
    super.key,
    required this.label,
    required this.isSelected,
    this.isAscending = false,
    required this.onTap,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final chipColor = accentColor ?? Theme.of(context).primaryColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? chipColor : colorScheme.outline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? Colors.white : colorScheme.onSurfaceVariant,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 2),
              Icon(
                isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 12,
                color: Colors.white,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// ------------------------------------------------------------
/// 필터 행 내 세로 구분선 (성별/품종 사이 등)
/// ------------------------------------------------------------
class MingrrFilterDivider extends StatelessWidget {
  const MingrrFilterDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        width: 1,
        height: 20,
        color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
      ),
    );
  }
}

/// ------------------------------------------------------------
/// 필터 섹션 가로 구분선 (행 사이 구분선)
/// 
/// LocationDistanceBar 하단 구분선과 동일한 스타일
/// ------------------------------------------------------------
class MingrrFilterSectionDivider extends StatelessWidget {
  const MingrrFilterSectionDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
    );
  }
}

/// ------------------------------------------------------------
/// 필터 행 (타이틀 + 칩 목록)
/// 
/// [title]: 행 타이틀 (예: "성별/품종")
/// [children]: 칩 위젯 목록
/// [accentColor]: 타이틀 배경 색상
/// [showTitle]: 타이틀 표시 여부 (기본: true)
/// ------------------------------------------------------------
class MingrrFilterRow extends StatelessWidget {
  final String? title;
  final List<Widget> children;
  final Color? accentColor;
  final bool showTitle;

  const MingrrFilterRow({
    super.key,
    this.title,
    required this.children,
    this.accentColor,
    this.showTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingM,
        vertical: AppSizes.paddingS,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // 타이틀
            if (showTitle && title != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  title!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            // 칩 목록
            ...children.map((child) {
              // MingrrFilterDivider는 그대로, 나머지는 간격 추가
              if (child is MingrrFilterDivider) {
                return child;
              }
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: child,
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// ------------------------------------------------------------
/// 필터 섹션 (여러 행 묶음)
/// 
/// [rows]: 필터 행 목록
/// [showDividers]: 행 사이 구분선 표시 여부
/// ------------------------------------------------------------
class MingrrFilterSection extends StatelessWidget {
  final List<Widget> rows;
  final bool showDividers;

  const MingrrFilterSection({
    super.key,
    required this.rows,
    this.showDividers = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            rows[i],
            if (showDividers && i < rows.length - 1)
              const MingrrFilterSectionDivider(),
          ],
        ],
      ),
    );
  }
}

/// ------------------------------------------------------------
/// 카테고리 칩 목록 (가로 스크롤, 타이틀 포함)
/// 
/// [title]: 타이틀 (선택)
/// [categories]: 카테고리 목록
/// [selectedIndex]: 선택된 인덱스
/// [onSelected]: 선택 콜백
/// [accentColor]: 강조 색상
/// ------------------------------------------------------------
class MingrrCategoryChips extends StatelessWidget {
  final String? title;
  final List<String> categories;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final Color? accentColor;

  const MingrrCategoryChips({
    super.key,
    this.title,
    required this.categories,
    required this.selectedIndex,
    required this.onSelected,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final chipColor = accentColor ?? Theme.of(context).primaryColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // 타이틀
            if (title != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  title!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            // 카테고리 칩 목록
            ...List.generate(categories.length, (index) {
              final category = categories[index];
              final isSelected = index == selectedIndex;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: GestureDetector(
                  onTap: () => onSelected(index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isSelected ? chipColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? chipColor : colorScheme.outline,
                      ),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? Colors.white : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// ------------------------------------------------------------
/// 카테고리 칩 목록 (아이콘 포함, 가로 스크롤)
/// 
/// [title]: 타이틀 (선택)
/// [categories]: 카테고리 목록 (label, icon)
/// [selectedIndex]: 선택된 인덱스
/// [onSelected]: 선택 콜백
/// [accentColor]: 강조 색상
/// ------------------------------------------------------------
class MingrrCategoryChipsWithIcon extends StatelessWidget {
  final String? title;
  final List<({String label, IconData icon})> categories;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final Color? accentColor;

  const MingrrCategoryChipsWithIcon({
    super.key,
    this.title,
    required this.categories,
    required this.selectedIndex,
    required this.onSelected,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final chipColor = accentColor ?? Theme.of(context).primaryColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // 타이틀
            if (title != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  title!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            // 카테고리 칩 목록
            ...List.generate(categories.length, (index) {
              final category = categories[index];
              final isSelected = index == selectedIndex;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: GestureDetector(
                  onTap: () => onSelected(index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isSelected ? chipColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? chipColor : colorScheme.outline,
                      ),
                    ),
                    child: Text(
                      category.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? Colors.white : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// ------------------------------------------------------------
/// 정렬 칩 목록 (가로 스크롤)
/// 
/// [title]: 타이틀 (선택)
/// [options]: 정렬 옵션 목록
/// [selectedIndex]: 선택된 인덱스
/// [isAscending]: 오름차순 여부
/// [onSelected]: 선택 콜백
/// [accentColor]: 강조 색상
/// ------------------------------------------------------------
class MingrrSortChips extends StatelessWidget {
  final String? title;
  final List<String> options;
  final int selectedIndex;
  final bool isAscending;
  final ValueChanged<int> onSelected;
  final Color? accentColor;

  const MingrrSortChips({
    super.key,
    this.title,
    required this.options,
    required this.selectedIndex,
    this.isAscending = false,
    required this.onSelected,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // 타이틀
            if (title != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  title!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            // 정렬 칩 목록
            ...List.generate(options.length, (index) {
              final option = options[index];
              final isOptionSelected = index == selectedIndex;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: MingrrSortChip(
                  label: option,
                  isSelected: isOptionSelected,
                  isAscending: isOptionSelected ? isAscending : false,
                  onTap: () => onSelected(index),
                  accentColor: accentColor,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
