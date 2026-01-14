import 'package:flutter/material.dart';
import '../constants/app_sizes.dart';
import 'mingrr_bottom_sheet.dart';

/// ============================================================
/// 공통 필터 위젯 모음
/// 
/// 데이팅, 마켓, 소모임 화면에서 통일된 디자인으로 사용
/// - DistanceFilterBar: 거리 필터 바
/// - LocationFilterBar: 시군구 위치 필터 바
/// - DistanceBottomSheet: 거리 선택 바텀시트
/// - LocationBottomSheet: 위치 선택 바텀시트
/// ============================================================

/// ------------------------------------------------------------
/// 거리 필터 옵션
/// 데이팅, 마켓에서 공통으로 사용
/// ------------------------------------------------------------
class DistanceOption {
  final double km;
  final String label;
  final String description;

  const DistanceOption({
    required this.km,
    required this.label,
    required this.description,
  });

  /// 기본 거리 옵션 목록 (1km, 3km, 5km, 10km, 20km, 50km)
  static const List<DistanceOption> defaultOptions = [
    DistanceOption(km: 1, label: '1km', description: '가까운 이웃'),
    DistanceOption(km: 3, label: '3km', description: '동네 범위'),
    DistanceOption(km: 5, label: '5km', description: '조금 넓은 범위'),
    DistanceOption(km: 10, label: '10km', description: '넓은 범위'),
    DistanceOption(km: 20, label: '20km', description: '광역 범위'),
    DistanceOption(km: 50, label: '50km', description: '최대 범위'),
  ];
}

/// ------------------------------------------------------------
/// 거리 필터 바
/// 
/// 화면 상단에 표시되는 거리 필터 UI
/// [accentColor]: 테마 색상 (데이팅: pink, 마켓: orange 등)
/// [currentDistance]: 현재 선택된 거리 (km)
/// [onDistanceChanged]: 거리 변경 콜백
/// [distanceOptions]: 거리 옵션 목록 (기본값: 1/3/5/10/20/50km)
/// ------------------------------------------------------------
class DistanceFilterBar extends StatelessWidget {
  final Color accentColor;
  final double currentDistance;
  final ValueChanged<double> onDistanceChanged;
  final List<DistanceOption> distanceOptions;
  final String? locationLabel;

  const DistanceFilterBar({
    super.key,
    required this.accentColor,
    required this.currentDistance,
    required this.onDistanceChanged,
    this.distanceOptions = DistanceOption.defaultOptions,
    this.locationLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.5)),
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
            onTap: () => _showDistanceBottomSheet(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
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
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// 거리 선택 바텀시트 표시
  void _showDistanceBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      isScrollControlled: true,
      builder: (context) => DistanceBottomSheet(
        accentColor: accentColor,
        currentDistance: currentDistance,
        distanceOptions: distanceOptions,
        onDistanceSelected: (distance) {
          onDistanceChanged(distance);
          Navigator.pop(context);
        },
      ),
    );
  }
}

/// ------------------------------------------------------------
/// 거리 선택 바텀시트
/// 
/// 거리 옵션을 선택할 수 있는 바텀시트
/// ------------------------------------------------------------
class DistanceBottomSheet extends StatelessWidget {
  final Color accentColor;
  final double currentDistance;
  final List<DistanceOption> distanceOptions;
  final ValueChanged<double> onDistanceSelected;

  const DistanceBottomSheet({
    super.key,
    required this.accentColor,
    required this.currentDistance,
    required this.distanceOptions,
    required this.onDistanceSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.5,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const BottomSheetHandle(),
          // 헤더 (타이틀만)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: const Text(
              '거리 설정',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // 안내 문구 (중앙 정렬)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '집 주소 기준으로 필터링합니다',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          
          // 거리 옵션 목록 (스크롤 가능)
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: distanceOptions.length,
              itemBuilder: (context, index) {
                final option = distanceOptions[index];
                final isSelected = currentDistance == option.km;
                return ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  onTap: () => onDistanceSelected(option.km),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  leading: Icon(
                    isSelected ? Icons.check_circle : Icons.circle_outlined,
                    color: isSelected ? accentColor : Theme.of(context).colorScheme.outlineVariant,
                    size: 22,
                  ),
                  title: Text(
                    option.label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? accentColor : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    option.description,
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}

/// ------------------------------------------------------------
/// 시군구 위치 필터 바
/// 
/// 소모임 화면에서 사용하는 위치 필터
/// [accentColor]: 테마 색상
/// [selectedCity]: 선택된 시/도
/// [selectedDistrict]: 선택된 시군구
/// [onLocationChanged]: 위치 변경 콜백
/// ------------------------------------------------------------
class LocationFilterBar extends StatelessWidget {
  final Color accentColor;
  final String? selectedCity;
  final String? selectedDistrict;
  final void Function(String? city, String? district) onLocationChanged;

  const LocationFilterBar({
    super.key,
    required this.accentColor,
    this.selectedCity,
    this.selectedDistrict,
    required this.onLocationChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasLocation = selectedCity != null;
    final locationText = hasLocation
        ? (selectedDistrict != null
            ? '$selectedCity $selectedDistrict'
            : selectedCity!)
        : '전체 지역';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.5)),
        ),
      ),
      child: Row(
        children: [
          // 위치 아이콘
          Icon(Icons.location_on, size: 18, color: accentColor),
          const SizedBox(width: 6),
          
          // 위치 선택 버튼
          GestureDetector(
            onTap: () => _showLocationBottomSheet(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    locationText,
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
          
          // 초기화 버튼 (위치가 선택된 경우에만 표시)
          if (hasLocation)
            GestureDetector(
              onTap: () => onLocationChanged(null, null),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.close, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(width: 2),
                    Text(
                      '초기화',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 위치 선택 바텀시트 표시
  void _showLocationBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => LocationBottomSheet(
        accentColor: accentColor,
        selectedCity: selectedCity,
        selectedDistrict: selectedDistrict,
        onLocationSelected: (city, district) {
          onLocationChanged(city, district);
          Navigator.pop(context);
        },
      ),
    );
  }
}

/// ------------------------------------------------------------
/// 위치 선택 바텀시트
/// 
/// 시/도 → 시군구 2단계 선택
/// ------------------------------------------------------------
class LocationBottomSheet extends StatefulWidget {
  final Color accentColor;
  final String? selectedCity;
  final String? selectedDistrict;
  final void Function(String? city, String? district) onLocationSelected;

  const LocationBottomSheet({
    super.key,
    required this.accentColor,
    this.selectedCity,
    this.selectedDistrict,
    required this.onLocationSelected,
  });

  @override
  State<LocationBottomSheet> createState() => _LocationBottomSheetState();
}

class _LocationBottomSheetState extends State<LocationBottomSheet> {
  String? _selectedCity;
  String? _selectedDistrict;

  /// 시/도 목록
  static const List<String> cities = [
    '서울특별시',
    '부산광역시',
    '대구광역시',
    '인천광역시',
    '광주광역시',
    '대전광역시',
    '울산광역시',
    '세종특별자치시',
    '경기도',
    '강원도',
    '충청북도',
    '충청남도',
    '전라북도',
    '전라남도',
    '경상북도',
    '경상남도',
    '제주특별자치도',
  ];

  /// 시/도별 시군구 목록 (주요 지역만 포함)
  static const Map<String, List<String>> districts = {
    '서울특별시': [
      '강남구', '강동구', '강북구', '강서구', '관악구', '광진구', '구로구', '금천구',
      '노원구', '도봉구', '동대문구', '동작구', '마포구', '서대문구', '서초구', '성동구',
      '성북구', '송파구', '양천구', '영등포구', '용산구', '은평구', '종로구', '중구', '중랑구',
    ],
    '부산광역시': [
      '강서구', '금정구', '남구', '동구', '동래구', '부산진구', '북구', '사상구',
      '사하구', '서구', '수영구', '연제구', '영도구', '중구', '해운대구', '기장군',
    ],
    '경기도': [
      '수원시', '성남시', '고양시', '용인시', '부천시', '안산시', '안양시', '남양주시',
      '화성시', '평택시', '의정부시', '시흥시', '파주시', '광명시', '김포시', '군포시',
      '광주시', '이천시', '양주시', '오산시', '구리시', '안성시', '포천시', '의왕시',
      '하남시', '여주시', '양평군', '동두천시', '과천시', '가평군', '연천군',
    ],
    '인천광역시': [
      '계양구', '남동구', '동구', '미추홀구', '부평구', '서구', '연수구', '중구', '강화군', '옹진군',
    ],
  };

  @override
  void initState() {
    super.initState();
    _selectedCity = widget.selectedCity;
    _selectedDistrict = widget.selectedDistrict;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSizes.bottomSheetRadius)),
      ),
      child: Column(
        children: [
          const BottomSheetHandle(),
          // 헤더
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  '지역 선택',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                // 전체 지역 버튼
                TextButton(
                  onPressed: () => widget.onLocationSelected(null, null),
                  child: const Text('전체 지역'),
                ),
              ],
            ),
          ),
          
          // 2단 선택 영역
          Expanded(
            child: Row(
              children: [
                // 시/도 목록
                Expanded(
                  flex: 2,
                  child: Container(
                    color: Theme.of(context).colorScheme.surface,
                    child: ListView.builder(
                      itemCount: cities.length,
                      itemBuilder: (context, index) {
                        final city = cities[index];
                        final isSelected = _selectedCity == city;
                        return ListTile(
                          onTap: () {
                            setState(() {
                              _selectedCity = city;
                              _selectedDistrict = null;
                            });
                          },
                          selected: isSelected,
                          selectedTileColor: Colors.white,
                          title: Text(
                            city,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              color: isSelected ? widget.accentColor : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          trailing: isSelected
                              ? Icon(Icons.chevron_right, color: widget.accentColor)
                              : null,
                        );
                      },
                    ),
                  ),
                ),
                
                // 시군구 목록
                Expanded(
                  flex: 3,
                  child: _selectedCity != null && districts.containsKey(_selectedCity)
                      ? ListView.builder(
                          itemCount: districts[_selectedCity]!.length,
                          itemBuilder: (context, index) {
                            final district = districts[_selectedCity]![index];
                            final isSelected = _selectedDistrict == district;
                            return ListTile(
                              onTap: () {
                                widget.onLocationSelected(_selectedCity, district);
                              },
                              title: Text(
                                district,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                  color: isSelected ? widget.accentColor : Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              trailing: isSelected
                                  ? Icon(Icons.check, color: widget.accentColor)
                                  : null,
                            );
                          },
                        )
                      : Center(
                          child: Text(
                            _selectedCity != null
                                ? '시군구 정보가 없습니다'
                                : '시/도를 선택해주세요',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
          
          // 하단 안전 영역
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

/// ------------------------------------------------------------
/// 카테고리 필터 칩 목록
/// 
/// 가로 스크롤 가능한 필터 칩 목록
/// [accentColor]: 테마 색상
/// [categories]: 카테고리 목록 (label, emoji, icon)
/// [selectedIndex]: 선택된 인덱스
/// [onSelected]: 선택 콜백
/// [showDropdownIcon]: 드롭다운 아이콘 표시 여부
/// ------------------------------------------------------------
class CategoryFilterChips extends StatelessWidget {
  final Color accentColor;
  final List<({String label, String? emoji, IconData? icon})> categories;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool showDropdownIcon;

  const CategoryFilterChips({
    super.key,
    required this.accentColor,
    required this.categories,
    required this.selectedIndex,
    required this.onSelected,
    this.showDropdownIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 70,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = index == selectedIndex;
          
          return GestureDetector(
            onTap: () => onSelected(index),
            child: Container(
              width: 60,
              margin: const EdgeInsets.only(right: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 아이콘/이모지 원형 배경
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? accentColor
                          : accentColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: category.icon != null
                          ? Icon(
                              category.icon,
                              size: 20,
                              color: isSelected ? Colors.white : accentColor,
                            )
                          : Icon(
                              Icons.grid_view,
                              size: 20,
                              color: isSelected ? Colors.white : accentColor,
                            ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // 라벨
                  Text(
                    category.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? accentColor : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
