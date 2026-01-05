import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// 지역 선택 결과 (주소 + 좌표)
class LocationResult {
  final String address;
  final GeoPoint? location;
  
  const LocationResult({
    required this.address,
    this.location,
  });
}

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
  
  /// 지역별 대표 좌표 (시/군/구청 기준)
  /// 키: "도/광역시 시/군" 또는 "도/광역시 시/군 구"
  static const Map<String, List<double>> coordinates = {
    // 서울특별시
    '서울특별시 서울특별시 강남구': [37.5172, 127.0473],
    '서울특별시 서울특별시 서초구': [37.4837, 127.0324],
    '서울특별시 서울특별시 송파구': [37.5145, 127.1066],
    '서울특별시 서울특별시 강동구': [37.5301, 127.1238],
    '서울특별시 서울특별시 마포구': [37.5663, 126.9014],
    '서울특별시 서울특별시 영등포구': [37.5264, 126.8963],
    '서울특별시 서울특별시 용산구': [37.5324, 126.9906],
    '서울특별시 서울특별시 종로구': [37.5735, 126.9790],
    '서울특별시 서울특별시 중구': [37.5641, 126.9979],
    '서울특별시 서울특별시 성동구': [37.5634, 127.0369],
    '서울특별시 서울특별시 광진구': [37.5385, 127.0823],
    '서울특별시 서울특별시 동대문구': [37.5744, 127.0396],
    '서울특별시 서울특별시 중랑구': [37.6066, 127.0927],
    '서울특별시 서울특별시 성북구': [37.5894, 127.0167],
    '서울특별시 서울특별시 강북구': [37.6397, 127.0255],
    '서울특별시 서울특별시 도봉구': [37.6688, 127.0471],
    '서울특별시 서울특별시 노원구': [37.6542, 127.0568],
    '서울특별시 서울특별시 은평구': [37.6027, 126.9291],
    '서울특별시 서울특별시 서대문구': [37.5791, 126.9368],
    '서울특별시 서울특별시 양천구': [37.5170, 126.8667],
    '서울특별시 서울특별시 강서구': [37.5509, 126.8495],
    '서울특별시 서울특별시 구로구': [37.4954, 126.8874],
    '서울특별시 서울특별시 금천구': [37.4569, 126.8956],
    '서울특별시 서울특별시 동작구': [37.5124, 126.9393],
    '서울특별시 서울특별시 관악구': [37.4784, 126.9516],
    
    // 경기도 주요 지역
    '경기도 수원특례시 장안구': [37.3039, 127.0097],
    '경기도 수원특례시 권선구': [37.2578, 126.9717],
    '경기도 수원특례시 팔달구': [37.2825, 127.0201],
    '경기도 수원특례시 영통구': [37.2596, 127.0465],
    '경기도 성남시 수정구': [37.4503, 127.1457],
    '경기도 성남시 중원구': [37.4315, 127.1370],
    '경기도 성남시 분당구': [37.3825, 127.1188],
    '경기도 용인특례시 처인구': [37.2346, 127.2090],
    '경기도 용인특례시 기흥구': [37.2804, 127.1150],
    '경기도 용인특례시 수지구': [37.3220, 127.0980],
    '경기도 고양특례시 덕양구': [37.6376, 126.8320],
    '경기도 고양특례시 일산동구': [37.6586, 126.7740],
    '경기도 고양특례시 일산서구': [37.6753, 126.7510],
    '경기도 부천시': [37.5034, 126.7660],
    '경기도 안산시 상록구': [37.3006, 126.8468],
    '경기도 안산시 단원구': [37.3180, 126.7980],
    '경기도 안양시 만안구': [37.3866, 126.9324],
    '경기도 안양시 동안구': [37.3925, 126.9512],
    '경기도 남양주시': [37.6360, 127.2165],
    '경기도 화성시': [37.1996, 126.8312],
    '경기도 평택시': [36.9921, 127.1126],
    '경기도 의정부시': [37.7381, 127.0337],
    '경기도 시흥시': [37.3800, 126.8030],
    '경기도 파주시': [37.7600, 126.7800],
    '경기도 김포시': [37.6152, 126.7156],
    '경기도 광명시': [37.4786, 126.8644],
    '경기도 광주시': [37.4295, 127.2550],
    '경기도 군포시': [37.3617, 126.9352],
    '경기도 하남시': [37.5393, 127.2148],
    '경기도 오산시': [37.1498, 127.0770],
    '경기도 이천시': [37.2720, 127.4350],
    '경기도 안성시': [37.0080, 127.2800],
    '경기도 의왕시': [37.3446, 126.9687],
    '경기도 양주시': [37.7852, 127.0456],
    '경기도 포천시': [37.8949, 127.2003],
    '경기도 구리시': [37.5943, 127.1295],
    '경기도 여주시': [37.2983, 127.6375],
    '경기도 동두천시': [37.9034, 127.0605],
    '경기도 과천시': [37.4292, 126.9876],
    '경기도 가평군': [37.8315, 127.5095],
    '경기도 양평군': [37.4917, 127.4875],
    '경기도 연천군': [38.0966, 127.0748],
    
    // 인천광역시
    '인천광역시 인천광역시 중구': [37.4738, 126.6217],
    '인천광역시 인천광역시 동구': [37.4737, 126.6432],
    '인천광역시 인천광역시 미추홀구': [37.4635, 126.6502],
    '인천광역시 인천광역시 연수구': [37.4102, 126.6783],
    '인천광역시 인천광역시 남동구': [37.4488, 126.7317],
    '인천광역시 인천광역시 부평구': [37.5076, 126.7219],
    '인천광역시 인천광역시 계양구': [37.5372, 126.7377],
    '인천광역시 인천광역시 서구': [37.5456, 126.6760],
    '인천광역시 인천광역시 강화군': [37.7469, 126.4878],
    '인천광역시 인천광역시 옹진군': [37.4467, 126.6367],
    
    // 부산광역시
    '부산광역시 부산광역시 중구': [35.1064, 129.0324],
    '부산광역시 부산광역시 서구': [35.0977, 129.0241],
    '부산광역시 부산광역시 동구': [35.1294, 129.0455],
    '부산광역시 부산광역시 영도구': [35.0912, 129.0678],
    '부산광역시 부산광역시 부산진구': [35.1629, 129.0532],
    '부산광역시 부산광역시 동래구': [35.1979, 129.0858],
    '부산광역시 부산광역시 남구': [35.1365, 129.0849],
    '부산광역시 부산광역시 북구': [35.1972, 128.9903],
    '부산광역시 부산광역시 해운대구': [35.1631, 129.1635],
    '부산광역시 부산광역시 사하구': [35.1046, 128.9747],
    '부산광역시 부산광역시 금정구': [35.2431, 129.0924],
    '부산광역시 부산광역시 강서구': [35.2122, 128.9808],
    '부산광역시 부산광역시 연제구': [35.1760, 129.0799],
    '부산광역시 부산광역시 수영구': [35.1457, 129.1133],
    '부산광역시 부산광역시 사상구': [35.1526, 128.9913],
    '부산광역시 부산광역시 기장군': [35.2445, 129.2222],
    
    // 대구광역시
    '대구광역시 대구광역시 중구': [35.8694, 128.6062],
    '대구광역시 대구광역시 동구': [35.8863, 128.6357],
    '대구광역시 대구광역시 서구': [35.8718, 128.5592],
    '대구광역시 대구광역시 남구': [35.8460, 128.5974],
    '대구광역시 대구광역시 북구': [35.8858, 128.5828],
    '대구광역시 대구광역시 수성구': [35.8584, 128.6308],
    '대구광역시 대구광역시 달서구': [35.8299, 128.5327],
    '대구광역시 대구광역시 달성군': [35.7746, 128.4314],
    '대구광역시 대구광역시 군위군': [36.2428, 128.5728],
    
    // 대전광역시
    '대전광역시 대전광역시 동구': [36.3121, 127.4549],
    '대전광역시 대전광역시 중구': [36.3256, 127.4212],
    '대전광역시 대전광역시 서구': [36.3555, 127.3836],
    '대전광역시 대전광역시 유성구': [36.3622, 127.3561],
    '대전광역시 대전광역시 대덕구': [36.3467, 127.4156],
    
    // 광주광역시
    '광주광역시 광주광역시 동구': [35.1461, 126.9231],
    '광주광역시 광주광역시 서구': [35.1523, 126.8895],
    '광주광역시 광주광역시 남구': [35.1328, 126.9025],
    '광주광역시 광주광역시 북구': [35.1743, 126.9120],
    '광주광역시 광주광역시 광산구': [35.1396, 126.7936],
    
    // 울산광역시
    '울산광역시 울산광역시 중구': [35.5684, 129.3328],
    '울산광역시 울산광역시 남구': [35.5444, 129.3302],
    '울산광역시 울산광역시 동구': [35.5050, 129.4165],
    '울산광역시 울산광역시 북구': [35.5828, 129.3612],
    '울산광역시 울산광역시 울주군': [35.5225, 129.2414],
    
    // 세종특별자치시
    '세종특별자치시 세종특별자치시': [36.4800, 127.2890],
    
    // 제주특별자치도
    '제주특별자치도 제주시': [33.4996, 126.5312],
    '제주특별자치도 서귀포시': [33.2541, 126.5600],
  };
  
  /// 주소로 좌표 가져오기
  static GeoPoint? getCoordinates(String address) {
    // 정확한 주소로 먼저 검색
    if (coordinates.containsKey(address)) {
      final coords = coordinates[address]!;
      return GeoPoint(coords[0], coords[1]);
    }
    
    // 부분 매칭 시도 (구가 없는 경우)
    for (final key in coordinates.keys) {
      if (key.startsWith(address) || address.startsWith(key)) {
        final coords = coordinates[key]!;
        return GeoPoint(coords[0], coords[1]);
      }
    }
    
    return null;
  }
}

/// ============================================================
/// 지역 선택 바텀시트 (3단계 선택 - 단일 선택용)
/// ============================================================
class LocationSelectorSheet extends StatefulWidget {
  final String? initialLocation;
  final Color accentColor;
  final Function(String location)? onLocationSelected;
  final Function(LocationResult result)? onLocationResultSelected;

  const LocationSelectorSheet({
    super.key,
    this.initialLocation,
    this.accentColor = AppColors.community,
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
                                      final geoPoint = KoreaLocationData.getCoordinates(location);
                                      widget.onLocationSelected?.call(location);
                                      widget.onLocationResultSelected?.call(LocationResult(
                                        address: location,
                                        location: geoPoint,
                                      ));
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

/// 지역 선택 바텀시트 표시 헬퍼 함수 (기존 호환)
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

/// 지역 선택 바텀시트 표시 헬퍼 함수 (좌표 포함)
void showLocationSelectorWithCoordinates({
  required BuildContext context,
  String? initialLocation,
  Color accentColor = AppColors.community,
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
