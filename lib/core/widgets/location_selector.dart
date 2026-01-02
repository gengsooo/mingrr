import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// ============================================================
/// 한국 지역 데이터 (특별시/광역시/특례시 정식 명칭 사용)
/// ============================================================
class KoreaLocationData {
  static const Map<String, Map<String, List<String>>> data = {
    '서울특별시': {
      '서울특별시': ['강남구', '서초구', '송파구', '강동구', '마포구', '영등포구', '용산구', '종로구', '중구', '성동구', '광진구', '동대문구', '중랑구', '성북구', '강북구', '도봉구', '노원구', '은평구', '서대문구', '양천구', '강서구', '구로구', '금천구', '동작구', '관악구'],
    },
    '경기도': {
      '수원특례시': ['장안구', '권선구', '팔달구', '영통구'],
      '성남시': ['수정구', '중원구', '분당구'],
      '용인특례시': ['처인구', '기흥구', '수지구'],
      '고양특례시': ['덕양구', '일산동구', '일산서구'],
      '부천시': [],
      '안산시': ['상록구', '단원구'],
      '안양시': ['만안구', '동안구'],
      '남양주시': [],
      '화성시': [],
      '평택시': [],
      '의정부시': [],
      '시흥시': [],
      '파주시': [],
      '김포시': [],
      '광명시': [],
      '광주시': [],
      '군포시': [],
      '하남시': [],
      '오산시': [],
      '이천시': [],
      '안성시': [],
      '의왕시': [],
      '양주시': [],
      '포천시': [],
      '구리시': [],
      '여주시': [],
      '동두천시': [],
      '과천시': [],
      '가평군': [],
      '양평군': [],
      '연천군': [],
    },
    '인천광역시': {
      '인천광역시': ['중구', '동구', '미추홀구', '연수구', '남동구', '부평구', '계양구', '서구', '강화군', '옹진군'],
    },
    '부산광역시': {
      '부산광역시': ['중구', '서구', '동구', '영도구', '부산진구', '동래구', '남구', '북구', '해운대구', '사하구', '금정구', '강서구', '연제구', '수영구', '사상구', '기장군'],
    },
    '대구광역시': {
      '대구광역시': ['중구', '동구', '서구', '남구', '북구', '수성구', '달서구', '달성군', '군위군'],
    },
    '대전광역시': {
      '대전광역시': ['동구', '중구', '서구', '유성구', '대덕구'],
    },
    '광주광역시': {
      '광주광역시': ['동구', '서구', '남구', '북구', '광산구'],
    },
    '울산광역시': {
      '울산광역시': ['중구', '남구', '동구', '북구', '울주군'],
    },
    '세종특별자치시': {
      '세종특별자치시': [],
    },
    '강원특별자치도': {
      '춘천시': [],
      '원주시': [],
      '강릉시': [],
      '동해시': [],
      '태백시': [],
      '속초시': [],
      '삼척시': [],
      '홍천군': [],
      '횡성군': [],
      '영월군': [],
      '평창군': [],
      '정선군': [],
      '철원군': [],
      '화천군': [],
      '양구군': [],
      '인제군': [],
      '고성군': [],
      '양양군': [],
    },
    '충청북도': {
      '청주시': ['상당구', '서원구', '흥덕구', '청원구'],
      '충주시': [],
      '제천시': [],
      '보은군': [],
      '옥천군': [],
      '영동군': [],
      '증평군': [],
      '진천군': [],
      '괴산군': [],
      '음성군': [],
      '단양군': [],
    },
    '충청남도': {
      '천안시': ['동남구', '서북구'],
      '공주시': [],
      '보령시': [],
      '아산시': [],
      '서산시': [],
      '논산시': [],
      '계룡시': [],
      '당진시': [],
      '금산군': [],
      '부여군': [],
      '서천군': [],
      '청양군': [],
      '홍성군': [],
      '예산군': [],
      '태안군': [],
    },
    '전북특별자치도': {
      '전주시': ['완산구', '덕진구'],
      '군산시': [],
      '익산시': [],
      '정읍시': [],
      '남원시': [],
      '김제시': [],
      '완주군': [],
      '진안군': [],
      '무주군': [],
      '장수군': [],
      '임실군': [],
      '순창군': [],
      '고창군': [],
      '부안군': [],
    },
    '전라남도': {
      '목포시': [],
      '여수시': [],
      '순천시': [],
      '나주시': [],
      '광양시': [],
      '담양군': [],
      '곡성군': [],
      '구례군': [],
      '고흥군': [],
      '보성군': [],
      '화순군': [],
      '장흥군': [],
      '강진군': [],
      '해남군': [],
      '영암군': [],
      '무안군': [],
      '함평군': [],
      '영광군': [],
      '장성군': [],
      '완도군': [],
      '진도군': [],
      '신안군': [],
    },
    '경상북도': {
      '포항시': ['남구', '북구'],
      '경주시': [],
      '김천시': [],
      '안동시': [],
      '구미시': [],
      '영주시': [],
      '영천시': [],
      '상주시': [],
      '문경시': [],
      '경산시': [],
      '의성군': [],
      '청송군': [],
      '영양군': [],
      '영덕군': [],
      '청도군': [],
      '고령군': [],
      '성주군': [],
      '칠곡군': [],
      '예천군': [],
      '봉화군': [],
      '울진군': [],
      '울릉군': [],
    },
    '경상남도': {
      '창원특례시': ['의창구', '성산구', '마산합포구', '마산회원구', '진해구'],
      '진주시': [],
      '통영시': [],
      '사천시': [],
      '김해시': [],
      '밀양시': [],
      '거제시': [],
      '양산시': [],
      '의령군': [],
      '함안군': [],
      '창녕군': [],
      '고성군': [],
      '남해군': [],
      '하동군': [],
      '산청군': [],
      '함양군': [],
      '거창군': [],
      '합천군': [],
    },
    '제주특별자치도': {
      '제주시': [],
      '서귀포시': [],
    },
  };

  static List<String> getProvinces() => data.keys.toList();
  
  static List<String> getCities(String province) => data[province]?.keys.toList() ?? [];
  
  static List<String> getDistricts(String province, String city) => data[province]?[city] ?? [];
}

/// ============================================================
/// 지역 선택 바텀시트 (3단계 선택 - 단일 선택용)
/// ============================================================
class LocationSelectorSheet extends StatefulWidget {
  final String? initialLocation;
  final Color accentColor;
  final Function(String location) onLocationSelected;

  const LocationSelectorSheet({
    super.key,
    this.initialLocation,
    this.accentColor = AppColors.community,
    required this.onLocationSelected,
  });

  @override
  State<LocationSelectorSheet> createState() => _LocationSelectorSheetState();
}

class _LocationSelectorSheetState extends State<LocationSelectorSheet> {
  String? selectedProvince;
  String? selectedCity;
  String? selectedDistrict;

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
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 헤더
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.divider.withOpacity(0.5))),
            ),
            child: Row(
              children: [
                const Text('지역 선택', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          
          // 3단계 선택 영역
          Expanded(
            child: Row(
              children: [
                // 도/광역시 선택
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(right: BorderSide(color: AppColors.divider.withOpacity(0.5))),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          color: AppColors.background,
                          child: const Text('도/광역시', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
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
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  color: isSelected ? widget.accentColor.withOpacity(0.1) : Colors.transparent,
                                  child: Text(
                                    province,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                      color: isSelected ? widget.accentColor : AppColors.textPrimary,
                                    ),
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
                      border: Border(right: BorderSide(color: AppColors.divider.withOpacity(0.5))),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          color: AppColors.background,
                          child: const Text('시/군', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                        ),
                        Expanded(
                          child: cities.isEmpty
                              ? const Center(child: Text('도/광역시를\n선택하세요', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.textHint)))
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
                                          widget.onLocationSelected(location);
                                          Navigator.pop(context);
                                        } else {
                                          setState(() {
                                            selectedCity = city;
                                            selectedDistrict = null;
                                          });
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                        color: isSelected ? widget.accentColor.withOpacity(0.1) : Colors.transparent,
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                city,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                                  color: isSelected ? widget.accentColor : AppColors.textPrimary,
                                                ),
                                              ),
                                            ),
                                            if (cityDistricts.isEmpty)
                                              Icon(
                                                isSelected ? Icons.check : Icons.add,
                                                size: 16,
                                                color: widget.accentColor,
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
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        color: AppColors.background,
                        child: const Text('구/군', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                      ),
                      Expanded(
                        child: districts.isEmpty
                            ? const Center(child: Text('시/군을\n선택하세요', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.textHint)))
                            : ListView.builder(
                                itemCount: districts.length,
                                itemBuilder: (context, index) {
                                  final district = districts[index];
                                  final isSelected = district == selectedDistrict;
                                  
                                  return GestureDetector(
                                    onTap: () {
                                      final location = '$selectedProvince $selectedCity $district';
                                      widget.onLocationSelected(location);
                                      Navigator.pop(context);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      color: isSelected ? widget.accentColor.withOpacity(0.1) : Colors.transparent,
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              district,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                                color: isSelected ? widget.accentColor : AppColors.textPrimary,
                                              ),
                                            ),
                                          ),
                                          Icon(
                                            isSelected ? Icons.check : Icons.add,
                                            size: 16,
                                            color: widget.accentColor,
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

/// 지역 선택 바텀시트 표시 헬퍼 함수
void showLocationSelector({
  required BuildContext context,
  String? initialLocation,
  Color accentColor = AppColors.community,
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
