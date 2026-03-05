import 'package:flutter/material.dart';
import '../../constants/app_icons.dart';
import '../../constants/app_sizes.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../dividers/app_dividers.dart';

// 미디어 피커 컴포넌트 re-export (하위 호환성 유지)
export 'media_picker_components.dart';

/// ============================================================
/// MINGRR 폼 공통 컴포넌트 모음
/// 
/// 등록/수정 화면에서 사용되는 재사용 가능한 UI 컴포넌트
/// 
/// 포함 컴포넌트:
/// - MingrrSectionLabel: 섹션 라벨
/// - MingrrSwitchRow: 토글 스위치 행
/// - MingrrSwitchCard: 토글 스위치 카드 (여러 개 묶음)
/// - MingrrChipSelector: 칩 선택기 (단일/다중)
/// - MingrrImagePicker: 이미지 피커 (단일/다중)
/// - MingrrFormAppBar: 폼 화면용 앱바
/// ============================================================

// ===== 섹션 라벨 =====
/// 폼 섹션의 제목 라벨
/// 
/// 사용 예시:
/// ```dart
/// MingrrSectionLabel('카테고리')
/// MingrrSectionLabel('사진', isRequired: true)
/// MingrrSectionLabel('태그', suffix: '(선택)')
/// ```
class MingrrSectionLabel extends StatelessWidget {
  final String text;
  final bool isRequired;
  final String? suffix;

  const MingrrSectionLabel(
    this.text, {
    super.key,
    this.isRequired = false,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.gapS),
      child: Row(
        children: [
          Text(
            text,
            style: AppTextStyles.titleMedium(context).withWeight(FontWeight.w600),
          ),
          if (isRequired)
            Text(
              ' *',
              style: AppTextStyles.titleMedium(context).withWeight(FontWeight.w600).withColor(Theme.of(context).colorScheme.error),
            ),
          if (suffix != null)
            Text(
              ' $suffix',
              style: AppTextStyles.bodyLarge(context).withColor(Theme.of(context).colorScheme.onSurfaceVariant),
            ),
        ],
      ),
    );
  }
}

// ===== 토글 스위치 행 =====
/// 단일 토글 스위치 행
/// 
/// 사용 예시:
/// ```dart
/// MingrrSwitchRow(
///   title: '공개 모임',
///   subtitle: '누구나 모임을 볼 수 있습니다',
///   value: _isPublic,
///   onChanged: (value) => setState(() => _isPublic = value),
///   accentColor: accentColor,
/// )
/// ```
class MingrrSwitchRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color accentColor;
  final IconData? icon;

  const MingrrSwitchRow({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    required this.accentColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSizes.gapM),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.titleLarge(context).withWeight(FontWeight.w500),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: AppTextStyles.bodySmall(context).withColor(colorScheme.onSurfaceVariant),
                ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: Colors.white,
          activeTrackColor: accentColor,
          // 다크모드에서 OFF 상태 thumb이 track과 구분되도록 설정
          inactiveThumbColor: colorScheme.outline,
          inactiveTrackColor: colorScheme.surfaceContainerHighest,
          trackOutlineColor: WidgetStateProperty.all(colorScheme.outline),
        ),
      ],
    );
  }
}

// ===== 토글 스위치 카드 =====
/// 여러 토글 스위치를 카드로 묶어서 표시
/// 
/// 사용 예시:
/// ```dart
/// MingrrSwitchCard(
///   title: '설정',
///   accentColor: accentColor,
///   items: [
///     MingrrSwitchItem(title: '공개', subtitle: '설명', value: v1, onChanged: ...),
///     MingrrSwitchItem(title: '승인', subtitle: '설명', value: v2, onChanged: ...),
///   ],
/// )
/// ```
class MingrrSwitchItem {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData? icon;

  const MingrrSwitchItem({
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.icon,
  });
}

class MingrrSwitchCard extends StatelessWidget {
  final String? title;
  final List<MingrrSwitchItem> items;
  final Color accentColor;

  const MingrrSwitchCard({
    super.key,
    this.title,
    required this.items,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) MingrrSectionLabel(title!),
        Container(
          padding: const EdgeInsets.all(AppSizes.paddingL),
          decoration: BoxDecoration(
            color: context.inputBackground,
            borderRadius: BorderRadius.circular(AppSizes.radiusS),
          ),
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                MingrrSwitchRow(
                  title: items[i].title,
                  subtitle: items[i].subtitle,
                  value: items[i].value,
                  onChanged: items[i].onChanged,
                  accentColor: accentColor,
                  icon: items[i].icon,
                ),
                if (i < items.length - 1) const MingrrDivider.section(),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ===== 칩 선택기 =====
/// 칩 형태의 선택기 (카테고리, 타입 등)
/// 
/// 사용 예시:
/// ```dart
/// MingrrChipSelector<CategoryType>(
///   items: CategoryType.values,
///   selectedItem: _selectedCategory,
///   onSelected: (item) => setState(() => _selectedCategory = item),
///   labelBuilder: (item) => item.label,
///   accentColor: accentColor,
/// )
/// ```
class MingrrChipSelector<T> extends StatelessWidget {
  final List<T> items;
  final T? selectedItem;
  final Set<T>? selectedItems; // 다중 선택용
  final ValueChanged<T> onSelected;
  final String Function(T) labelBuilder;
  final String Function(T)? emojiBuilder;
  final IconData? Function(T)? iconBuilder;
  final Color accentColor;
  final bool multiSelect;

  const MingrrChipSelector({
    super.key,
    required this.items,
    this.selectedItem,
    this.selectedItems,
    required this.onSelected,
    required this.labelBuilder,
    this.emojiBuilder,
    this.iconBuilder,
    required this.accentColor,
    this.multiSelect = false,
  });

  bool _isSelected(T item) {
    if (multiSelect) {
      return selectedItems?.contains(item) ?? false;
    }
    return selectedItem == item;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final isSelected = _isSelected(item);
        final emoji = emojiBuilder?.call(item);
        final icon = iconBuilder?.call(item);
        final label = labelBuilder(item);
        
        return GestureDetector(
          onTap: () => onSelected(item),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppSizes.paddingS),
            decoration: BoxDecoration(
              color: isSelected ? accentColor : Colors.transparent,
              borderRadius: BorderRadius.circular(AppSizes.radiusL),
              border: Border.all(
                color: isSelected ? accentColor : colorScheme.outline,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 16,
                    color: isSelected ? Colors.white : colorScheme.onSurface,
                  ),
                  const SizedBox(width: AppSizes.gapS),
                ],
                if (emoji != null)
                  Text(
                    '$emoji ',
                    style: AppTextStyles.bodySmall(context),
                  ),
                Text(
                  label,
                  style: AppTextStyles.bodySmall(context).copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? Colors.white : colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ===== 선택 버튼 (지역, 날짜 등) =====
/// 선택 버튼 (탭하면 바텀시트나 다이얼로그 표시)
/// 
/// 사용 예시:
/// ```dart
/// MingrrSelectButton(
///   label: '지역',
///   value: _selectedLocation,
///   placeholder: '지역을 선택해주세요',
///   onTap: _showLocationSelector,
///   icon: Icons.location_on_outlined,
/// )
/// ```
class MingrrSelectButton extends StatelessWidget {
  final String label;
  final String? value;
  final String placeholder;
  final VoidCallback onTap;
  final IconData? icon;
  final bool isRequired;

  const MingrrSelectButton({
    super.key,
    required this.label,
    this.value,
    required this.placeholder,
    required this.onTap,
    this.icon,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasValue = value != null && value!.isNotEmpty;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MingrrSectionLabel(label, isRequired: isRequired),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL, vertical: AppSizes.paddingM),
            decoration: BoxDecoration(
              color: context.inputBackground,
              borderRadius: BorderRadius.circular(AppSizes.radiusS),
              border: Border.all(color: colorScheme.outline.withValues(alpha: AppOpacity.o30)),
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 20,
                    color: hasValue ? colorScheme.onSurface : colorScheme.outlineVariant,
                  ),
                  const SizedBox(width: AppSizes.gapM),
                ],
                Expanded(
                  child: Text(
                    hasValue ? value! : placeholder,
                    style: AppTextStyles.titleLarge(context).withWeight(FontWeight.w400).withColor(
                      hasValue ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Icon(
                  AppIcons.chevronRight,
                  color: colorScheme.outlineVariant,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

