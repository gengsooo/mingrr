import 'package:flutter/material.dart';
import '../../constants/app_icons.dart';
import '../../constants/app_sizes.dart';
import '../../theme/feature_colors.dart';
import '../../theme/app_text_styles.dart';
import '../sheets/mingrr_bottom_sheet.dart';
import '../dividers/app_dividers.dart';
import '../../utils/responsive_utils.dart';
import 'korea_location_data.dart';

// 하위 호환성 유지를 위한 re-export
export 'korea_location_data.dart';

/// ============================================================
/// 지역 선택 바텀시트 (3단계 선택 - 단일 선택용)
/// ============================================================
class LocationSelectorSheet extends StatefulWidget {
  final String? initialLocation;
  final Color? accentColor;
  final Function(String location)? onLocationSelected;
  final Function(LocationResult result)? onLocationResultSelected;

  const LocationSelectorSheet({
    super.key,
    this.initialLocation,
    this.accentColor,
    this.onLocationSelected,
    this.onLocationResultSelected,
  });

  @override
  State<LocationSelectorSheet> createState() => _LocationSelectorSheetState();
}

class _LocationSelectorSheetState extends State<LocationSelectorSheet> {
  String? selectedProvince;
  String? selectedCity;
  String? selectedDistrict;

  Color get accentColor => widget.accentColor ?? context.features.social;

  @override
  void initState() {
    super.initState();
    // 기존 선택된 지역 파싱
    if (widget.initialLocation != null) {
      final parts = widget.initialLocation!.split(' ');
      if (parts.isNotEmpty) selectedProvince = parts[0];
      if (parts.length > 1) selectedCity = parts[1];
      if (parts.length > 2) selectedDistrict = parts[2];
    }
  }

  @override
  Widget build(BuildContext context) {
    final provinces = KoreaLocationData.getProvinces();
    final cities = selectedProvince != null ? KoreaLocationData.getCities(selectedProvince!) : <String>[];
    final districts = (selectedProvince != null && selectedCity != null) 
        ? KoreaLocationData.getDistricts(selectedProvince!, selectedCity!) 
        : <String>[];

    return Container(
      height: ResponsiveUtils.heightPercent(context, 0.7),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSizes.bottomSheetRadius)),
      ),
      child: Column(
        children: [
          const BottomSheetHandle(),
          // 헤더
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSizes.paddingS, AppSizes.paddingS, AppSizes.paddingS, AppSizes.paddingM),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    widget.onLocationSelected?.call('');
                    widget.onLocationResultSelected?.call(const LocationResult(address: ''));
                    Navigator.pop(context);
                  },
                  child: Text('초기화', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ),
                Text(
                  '지역 선택',
                  style: AppTextStyles.headlineSmall(context),
                ),
                const SizedBox(width: 60),
              ],
            ),
          ),
          const MingrrDivider(),
          
          // 3단계 선택 영역
          Expanded(
            child: Row(
              children: [
                // 도/광역시 선택
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(right: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: AppOpacity.o30))),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM, vertical: AppSizes.paddingS),
                          color: Theme.of(context).colorScheme.surface,
                          child: Text('도/광역시', style: AppTextStyles.caption(context).copyWith(fontWeight: FontWeight.w600)),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: provinces.length,
                            itemBuilder: (context, index) {
                              final province = provinces[index];
                              final isSelected = province == selectedProvince;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedProvince = province;
                                    selectedCity = null;
                                    selectedDistrict = null;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM, vertical: AppSizes.paddingM),
                                  color: isSelected ? accentColor.withValues(alpha: AppOpacity.o10) : Colors.transparent,
                                  child: Text(
                                    province,
                                    style: AppTextStyles.bodyLarge(context)
                                        .withWeight(isSelected ? FontWeight.w600 : FontWeight.w400)
                                        .withColor(isSelected ? accentColor : Theme.of(context).colorScheme.onSurface),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // 시/군 선택
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(right: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: AppOpacity.o30))),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM, vertical: AppSizes.paddingS),
                          color: Theme.of(context).colorScheme.surface,
                          child: Text('시/군', style: AppTextStyles.caption(context).copyWith(fontWeight: FontWeight.w600)),
                        ),
                        Expanded(
                          child: cities.isEmpty
                              ? Center(child: Text('도/광역시를\n선택하세요', textAlign: TextAlign.center, style: AppTextStyles.caption(context)))
                              : ListView.builder(
                                  itemCount: cities.length,
                                  itemBuilder: (context, index) {
                                    final city = cities[index];
                                    final isSelected = city == selectedCity;
                                    final cityDistricts = KoreaLocationData.getDistricts(selectedProvince!, city);
                                    
                                    return GestureDetector(
                                      onTap: () {
                                        if (cityDistricts.isEmpty) {
                                          // 구가 없으면 바로 선택 완료
                                          final location = '$selectedProvince $city';
                                          final geoPoint = KoreaLocationData.getCoordinates(location);
                                          widget.onLocationSelected?.call(location);
                                          widget.onLocationResultSelected?.call(LocationResult(
                                            address: location,
                                            location: geoPoint,
                                          ));
                                          Navigator.pop(context);
                                        } else {
                                          setState(() {
                                            selectedCity = city;
                                            selectedDistrict = null;
                                          });
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM, vertical: AppSizes.paddingM),
                                        color: isSelected ? accentColor.withValues(alpha: AppOpacity.o10) : Colors.transparent,
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                city,
                                                style: AppTextStyles.bodyLarge(context)
                                                    .withWeight(isSelected ? FontWeight.w600 : FontWeight.w400)
                                                    .withColor(isSelected ? accentColor : Theme.of(context).colorScheme.onSurface),
                                              ),
                                            ),
                                            if (cityDistricts.isEmpty)
                                              Icon(
                                                isSelected ? AppIcons.check : AppIcons.add,
                                                size: 16,
                                                color: accentColor,
                                              ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // 구/군 선택
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM, vertical: AppSizes.paddingS),
                        color: Theme.of(context).colorScheme.surface,
                        child: Text('구/군', style: AppTextStyles.caption(context).copyWith(fontWeight: FontWeight.w600)),
                      ),
                      Expanded(
                        child: districts.isEmpty
                            ? Center(child: Text('시/군을\n선택하세요', textAlign: TextAlign.center, style: AppTextStyles.caption(context)))
                            : ListView.builder(
                                itemCount: districts.length,
                                itemBuilder: (context, index) {
                                  final district = districts[index];
                                  final isSelected = district == selectedDistrict;
                                  
                                  return GestureDetector(
                                    onTap: () {
                                      final location = '$selectedProvince $selectedCity $district';
                                      final geoPoint = KoreaLocationData.getCoordinates(location);
                                      widget.onLocationSelected?.call(location);
                                      widget.onLocationResultSelected?.call(LocationResult(
                                        address: location,
                                        location: geoPoint,
                                      ));
                                      Navigator.pop(context);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM, vertical: AppSizes.paddingM),
                                      color: isSelected ? accentColor.withValues(alpha: AppOpacity.o10) : Colors.transparent,
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              district,
                                              style: AppTextStyles.bodyLarge(context)
                                                  .withWeight(isSelected ? FontWeight.w600 : FontWeight.w400)
                                                  .withColor(isSelected ? accentColor : Theme.of(context).colorScheme.onSurface),
                                            ),
                                          ),
                                          Icon(
                                            isSelected ? AppIcons.check : AppIcons.add,
                                            size: 16,
                                            color: accentColor,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
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

/// 지역 선택 바텀시트 표시 헬퍼 함수 (기존 호환)
void showLocationSelector({
  required BuildContext context,
  String? initialLocation,
  Color? accentColor,
  required Function(String location) onLocationSelected,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => LocationSelectorSheet(
      initialLocation: initialLocation,
      accentColor: accentColor,
      onLocationSelected: onLocationSelected,
    ),
  );
}

/// 지역 선택 바텀시트 표시 헬퍼 함수 (좌표 포함)
void showLocationSelectorWithCoordinates({
  required BuildContext context,
  String? initialLocation,
  Color? accentColor,
  required Function(LocationResult result) onLocationResultSelected,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => LocationSelectorSheet(
      initialLocation: initialLocation,
      accentColor: accentColor,
      onLocationResultSelected: onLocationResultSelected,
    ),
  );
}

/// ============================================================
/// 지역 선택 바텀시트 (다중 선택용)
/// 소모임 목록 필터 등에서 사용
/// ============================================================
class MultiLocationSelectorSheet extends StatefulWidget {
  final List<String> initialLocations;
  final Color? accentColor;
  final Function(List<String> locations) onLocationsSelected;

  const MultiLocationSelectorSheet({
    super.key,
    this.initialLocations = const [],
    this.accentColor,
    required this.onLocationsSelected,
  });

  @override
  State<MultiLocationSelectorSheet> createState() => _MultiLocationSelectorSheetState();
}

class _MultiLocationSelectorSheetState extends State<MultiLocationSelectorSheet> {
  String? _selectedProvince;
  String? _selectedCity;
  late List<String> _tempSelected;

  Color get accentColor => widget.accentColor ?? context.features.social;

  @override
  void initState() {
    super.initState();
    _tempSelected = List.from(widget.initialLocations);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final districts = (_selectedProvince != null && _selectedCity != null)
        ? KoreaLocationData.getDistricts(_selectedProvince!, _selectedCity!)
        : <String>[];

    return Container(
      height: ResponsiveUtils.heightPercent(context, 0.75),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSizes.bottomSheetRadius)),
      ),
      child: Column(
        children: [
          const BottomSheetHandle(),
          // 헤더
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSizes.paddingS, AppSizes.paddingS, AppSizes.paddingS, AppSizes.paddingM),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => setState(() => _tempSelected.clear()),
                  child: Text('초기화', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                ),
                Column(
                  children: [
                    Text('지역 선택', style: AppTextStyles.headlineSmall(context)),
                    if (_tempSelected.isNotEmpty)
                      Text(
                        '${_tempSelected.length}개 선택됨',
                        style: AppTextStyles.caption(context).copyWith(color: accentColor),
                      ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    widget.onLocationsSelected(_tempSelected);
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
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL, vertical: AppSizes.paddingS),
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _tempSelected.map((location) {
                    return Chip(
                      label: Text(location, style: AppTextStyles.labelMedium(context)),
                      deleteIcon: Icon(AppIcons.close, size: 14),
                      onDeleted: () => setState(() => _tempSelected.remove(location)),
                      backgroundColor: accentColor.withValues(alpha: AppOpacity.o10),
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
          const MingrrDivider(),
          // 3단 선택 영역
          Expanded(
            child: Row(
              children: [
                // 1단계: 시/도
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow,
                      border: Border(right: BorderSide(color: colorScheme.outline.withValues(alpha: AppOpacity.o20))),
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
                            padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM, vertical: AppSizes.paddingM),
                            decoration: BoxDecoration(
                              color: isSelected ? accentColor.withValues(alpha: AppOpacity.o10) : null,
                              border: Border(
                                left: BorderSide(
                                  color: isSelected ? accentColor : Colors.transparent,
                                  width: 3,
                                ),
                              ),
                            ),
                            child: Text(
                              province,
                              style: AppTextStyles.bodyMedium(context)
                                  .withWeight(isSelected ? FontWeight.w600 : FontWeight.w400)
                                  .withColor(isSelected ? accentColor : colorScheme.onSurface),
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
                      border: Border(right: BorderSide(color: colorScheme.outline.withValues(alpha: AppOpacity.o20))),
                    ),
                    child: _selectedProvince == null
                        ? Center(
                            child: Text(
                              '시/도 선택',
                              style: AppTextStyles.bodySmall(context),
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
                                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM, vertical: AppSizes.paddingM),
                                  decoration: BoxDecoration(
                                    color: isSelected ? accentColor.withValues(alpha: AppOpacity.o10) : null,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          city,
                                          style: AppTextStyles.bodyMedium(context)
                                              .withWeight(isSelected ? FontWeight.w600 : FontWeight.w400)
                                              .withColor(isSelected ? accentColor : colorScheme.onSurface),
                                        ),
                                      ),
                                      if (_tempSelected.contains('$_selectedProvince $city'))
                                        Icon(AppIcons.check, size: 18, color: accentColor)
                                      else if (!hasDistricts)
                                        Icon(AppIcons.add, size: 18, color: accentColor),
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
                            style: AppTextStyles.bodySmall(context),
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
                                padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM, vertical: AppSizes.paddingM),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        district,
                                        style: AppTextStyles.bodyMedium(context)
                                            .withWeight(isSelected ? FontWeight.w600 : FontWeight.w400)
                                            .withColor(isSelected ? accentColor : colorScheme.onSurface),
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(AppIcons.check, size: 18, color: accentColor)
                                    else
                                      Icon(AppIcons.add, size: 18, color: accentColor),
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

/// 다중 지역 선택 바텀시트 표시 헬퍼 함수
void showMultiLocationSelector({
  required BuildContext context,
  List<String> initialLocations = const [],
  Color? accentColor,
  required Function(List<String> locations) onLocationsSelected,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => MultiLocationSelectorSheet(
      initialLocations: initialLocations,
      accentColor: accentColor,
      onLocationsSelected: onLocationsSelected,
    ),
  );
}
