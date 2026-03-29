import 'package:flutter/material.dart';
import '../constants/app_sizes.dart';
import '../theme/app_text_styles.dart';

/// ============================================================
/// 공통 필터 칩 바 (V2 리팩토링)
/// 
/// 데이팅/채팅/마켓 등 모든 화면에서 동일한 필터 UX 제공
/// 
/// 사용법:
/// ```dart
/// MingrrFilterChipBar<String?>(
///   items: [
///     (key: null, label: '전체'),
///     (key: 'dating', label: '데이팅'),
///     (key: 'market', label: '마켓'),
///   ],
///   selected: selectedFilter,
///   onSelected: (key) => ref.read(provider.notifier).state = key,
///   accentColor: context.features.accent,
/// )
/// ```
/// ============================================================
class MingrrFilterChipBar<T> extends StatelessWidget {
  final List<({T key, String label})> items;
  final T selected;
  final ValueChanged<T> onSelected;
  final Color accentColor;

  const MingrrFilterChipBar({
    super.key,
    required this.items,
    required this.selected,
    required this.onSelected,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.screenPaddingH,
        vertical: AppSizes.paddingS,
      ),
      child: Row(
        children: items.map((item) {
          final isSelected = item.key == selected;
          return Padding(
            padding: const EdgeInsets.only(right: AppSizes.gapS),
            child: GestureDetector(
              onTap: () => onSelected(item.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingL,
                  vertical: AppSizes.paddingS,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? accentColor
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
                child: Text(
                  item.label,
                  style: AppTextStyles.labelLarge(context).withColor(
                    isSelected ? Colors.white : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
