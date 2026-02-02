import 'package:flutter/material.dart';
import '../../constants/app_icons.dart';
import '../../constants/app_sizes.dart';
import '../../theme/app_text_styles.dart';

/// ============================================================
/// MingrrSearchBar - 공통 검색 바 위젯
/// 
/// 일관된 검색 UI를 제공하는 재사용 가능한 위젯
/// 
/// 사용 예:
/// ```dart
/// MingrrSearchBar(
///   hintText: '검색어를 입력하세요',
///   onSearch: (query) => print('검색: $query'),
///   accentColor: context.features.market,
/// )
/// ```
/// ============================================================
class MingrrSearchBar extends StatelessWidget {
  /// 검색 바 힌트 텍스트
  final String hintText;
  
  /// 검색 실행 콜백 (Enter 키 또는 검색 버튼)
  final ValueChanged<String>? onSearch;
  
  /// 텍스트 변경 콜백 (실시간 검색용)
  final ValueChanged<String>? onChanged;
  
  /// 검색 아이콘 색상
  final Color? accentColor;
  
  /// 자동 포커스 여부
  final bool autofocus;
  
  /// 외부 컨트롤러 (선택적)
  final TextEditingController? controller;
  
  /// 검색 바 높이
  final double height;
  
  /// 배경색
  final Color? backgroundColor;
  
  /// 테두리 반경
  final double borderRadius;
  
  /// 접미사 위젯 (예: 취소 버튼)
  final Widget? suffix;

  const MingrrSearchBar({
    super.key,
    this.hintText = '검색어를 입력하세요',
    this.onSearch,
    this.onChanged,
    this.accentColor,
    this.autofocus = false,
    this.controller,
    this.height = 40,
    this.backgroundColor,
    this.borderRadius = 20,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final effectiveAccentColor = accentColor ?? colorScheme.primary;
    final effectiveBackgroundColor = backgroundColor ?? colorScheme.surfaceContainerHighest;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: effectiveBackgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: AppTextStyles.bodyMedium(context).withColor(colorScheme.outlineVariant),
          prefixIcon: Icon(
            AppIcons.search,
            color: effectiveAccentColor,
            size: 20,
          ),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingL,
            vertical: AppSizes.paddingS,
          ),
        ),
        onSubmitted: onSearch,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
      ),
    );
  }
}
