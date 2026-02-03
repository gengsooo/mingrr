import 'package:flutter/material.dart';
import '../../constants/app_icons.dart';
import '../../constants/app_sizes.dart';
import '../../constants/pet_constants.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive_utils.dart';
import '../sheets/mingrr_bottom_sheet.dart';

/// ============================================================
/// MINGRR 품종 선택 컴포넌트
/// 
/// SelectBox 스타일의 품종 선택기입니다.
/// 탭하면 바텀시트가 열리고, 검색/직접입력 + 목록에서 선택할 수 있습니다.
/// 
/// 사용 예시:
/// ```dart
/// MingrrBreedPicker(
///   value: _selectedBreed,
///   onChanged: (breed) => setState(() => _selectedBreed = breed),
///   labelText: '품종',
/// )
/// ```
/// ============================================================
class MingrrBreedPicker extends StatelessWidget {
  /// 현재 선택된 품종
  final String? value;
  
  /// 품종 변경 콜백
  final ValueChanged<String> onChanged;
  
  /// 라벨 텍스트
  final String labelText;
  
  /// 힌트 텍스트 (선택되지 않았을 때)
  final String hintText;
  
  /// 액센트 컬러
  final Color? accentColor;

  const MingrrBreedPicker({
    super.key,
    this.value,
    required this.onChanged,
    this.labelText = '품종',
    this.hintText = '품종을 선택하세요',
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasValue = value != null && value!.isNotEmpty;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 라벨
        Text(
          labelText,
          style: AppTextStyles.labelLarge(context),
        ),
        const SizedBox(height: AppSizes.gapS),
        
        // SelectBox
        GestureDetector(
          onTap: () => _showBreedPicker(context),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.paddingM,
              vertical: AppSizes.paddingM,
            ),
            decoration: BoxDecoration(
              color: context.inputBackground,
              borderRadius: BorderRadius.circular(AppSizes.radiusS),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    hasValue ? value! : hintText,
                    style: AppTextStyles.bodyMedium(context).withColor(
                      hasValue ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Icon(
                  AppIcons.chevronDown,
                  size: 20,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showBreedPicker(BuildContext context) {
    showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BreedPickerSheet(
        initialValue: value,
        accentColor: accentColor ?? Theme.of(context).colorScheme.primary,
      ),
    ).then((selectedBreed) {
      if (selectedBreed != null) {
        onChanged(selectedBreed);
      }
    });
  }
}

/// ============================================================
/// 품종 선택 바텀시트 (내부용)
/// ============================================================
class _BreedPickerSheet extends StatefulWidget {
  final String? initialValue;
  final Color accentColor;

  const _BreedPickerSheet({
    this.initialValue,
    required this.accentColor,
  });

  @override
  State<_BreedPickerSheet> createState() => _BreedPickerSheetState();
}

class _BreedPickerSheetState extends State<_BreedPickerSheet> {
  late TextEditingController _searchController;
  late FocusNode _focusNode;
  List<String> _filteredBreeds = [];
  
  // 강아지 + 고양이 전체 품종
  late List<String> _allBreeds;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode();
    
    // 강아지 + 고양이 품종 합치기
    _allBreeds = [
      ...PetBreeds.dogAll,
      ...PetBreeds.catAll,
    ];
    
    // 초기 필터링
    _filterBreeds(_searchController.text);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _filterBreeds(String query) {
    setState(() {
      if (query.isEmpty) {
        // 검색어 없으면 대표 품종만 표시
        _filteredBreeds = [
          ...PetBreeds.dogPopular,
          ...PetBreeds.catPopular,
        ];
      } else {
        // 검색어 있으면 필터링
        final lowerQuery = query.toLowerCase();
        _filteredBreeds = _allBreeds
            .where((breed) => breed.toLowerCase().contains(lowerQuery))
            .toList();
      }
    });
  }

  void _selectBreed(String breed) {
    Navigator.pop(context, breed);
  }

  void _confirmInput() {
    final input = _searchController.text.trim();
    if (input.isNotEmpty) {
      Navigator.pop(context, input);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final keyboardHeight = ResponsiveUtils.keyboardHeight(context);
    final bottomPadding = ResponsiveUtils.bottomSafeArea(context);
    final currentInput = _searchController.text.trim();
    final hasInput = currentInput.isNotEmpty;
    
    // 입력값이 목록에 없으면 직접 입력으로 간주
    final isCustomInput = hasInput && !_allBreeds.contains(currentInput);

    return Container(
      constraints: BoxConstraints(
        maxHeight: ResponsiveUtils.maxSheetHeight(context),
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSizes.bottomSheetRadius),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 핸들
          const BottomSheetHandle(),
          
          // 제목
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL),
            child: Text(
              '품종 선택',
              style: AppTextStyles.headlineSmall(context),
            ),
          ),
          const SizedBox(height: AppSizes.gapM),
          
          // 검색/직접입력 필드
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL),
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              autofocus: true,
              decoration: InputDecoration(
                hintText: '검색 또는 직접 입력',
                hintStyle: AppTextStyles.bodyMedium(context).withColor(
                  colorScheme.onSurfaceVariant,
                ),
                prefixIcon: Icon(
                  AppIcons.search,
                  size: 20,
                  color: colorScheme.onSurfaceVariant,
                ),
                suffixIcon: hasInput
                    ? IconButton(
                        icon: Icon(
                          AppIcons.close,
                          size: 18,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          _filterBreeds('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: context.inputBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusS),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingM,
                  vertical: AppSizes.paddingM,
                ),
              ),
              style: AppTextStyles.bodyMedium(context),
              onChanged: _filterBreeds,
              onSubmitted: (_) => _confirmInput(),
            ),
          ),
          const SizedBox(height: AppSizes.gapM),
          
          // 품종 목록
          Flexible(
            child: _filteredBreeds.isEmpty && hasInput
                ? _buildEmptyState(context, currentInput)
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: _filteredBreeds.length,
                    itemBuilder: (context, index) {
                      final breed = _filteredBreeds[index];
                      final isSelected = breed == currentInput;
                      
                      return ListTile(
                        title: Text(
                          breed,
                          style: AppTextStyles.bodyMedium(context).copyWith(
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected ? widget.accentColor : colorScheme.onSurface,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(AppIcons.check, color: widget.accentColor, size: 20)
                            : null,
                        onTap: () => _selectBreed(breed),
                      );
                    },
                  ),
          ),
          
          // 하단 버튼 (직접 입력 시에만 표시)
          if (isCustomInput)
            Container(
              padding: EdgeInsets.only(
                left: AppSizes.paddingL,
                right: AppSizes.paddingL,
                top: AppSizes.paddingM,
                bottom: keyboardHeight > 0 
                    ? keyboardHeight + AppSizes.paddingM 
                    : bottomPadding + AppSizes.paddingM,
              ),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                boxShadow: AppShadows.shadowL(Theme.of(context).brightness == Brightness.dark),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _confirmInput,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.accentColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusS),
                    ),
                  ),
                  child: Text(
                    '"$currentInput" 입력',
                    style: AppTextStyles.labelLarge(context).withColor(Colors.white),
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: keyboardHeight > 0 
                  ? keyboardHeight + AppSizes.paddingM 
                  : bottomPadding + AppSizes.paddingM,
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String input) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.all(AppSizes.paddingXL),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            AppIcons.search,
            size: 48,
            color: colorScheme.outlineVariant,
          ),
          const SizedBox(height: AppSizes.gapM),
          Text(
            '검색 결과가 없습니다',
            style: AppTextStyles.bodyMedium(context).withColor(
              colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSizes.gapXS),
          Text(
            '"$input"을(를) 직접 입력할 수 있습니다',
            style: AppTextStyles.bodySmall(context).withColor(
              colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
