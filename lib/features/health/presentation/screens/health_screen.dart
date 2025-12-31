import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/pet_constants.dart';
import '../../../../core/widgets/common_widgets.dart';

/// ============================================================
/// 건강수첩 화면 (V4 리팩토링 - 강아지 전용)
/// 
/// 변경사항:
/// - 강아지 전용 앱으로 변경 (PetType 제거)
/// - 대변/소변/음수 카테고리 제거 (사용자 요청)
/// - 산책 ON/OFF 기능 유지
/// - 다중 강아지 동시 산책 지원
/// - 경로 기록 (본인만 확인 가능)
/// ============================================================

// ===== Provider =====
/// 선택된 강아지 인덱스
final _selectedDogProvider = StateProvider<int>((ref) => 0);

/// 선택된 탭 인덱스
final _selectedTabProvider = StateProvider<int>((ref) => 0);

/// 데모용 강아지 목록
final _demoDogsProvider = Provider<List<_DemoDog>>((ref) => [
  _DemoDog(id: '1', name: '뽀삐', breed: '골든 리트리버', isPrimary: true),
  _DemoDog(id: '2', name: '코코', breed: '푸들', isPrimary: false),
]);

/// 데모용 강아지 클래스
class _DemoDog {
  final String id;
  final String name;
  final String breed;
  final bool isPrimary;
  const _DemoDog({required this.id, required this.name, required this.breed, required this.isPrimary});
}

class HealthScreen extends ConsumerWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dogs = ref.watch(_demoDogsProvider);
    final selectedDogIndex = ref.watch(_selectedDogProvider);
    final selectedTab = ref.watch(_selectedTabProvider);
    final selectedDog = dogs[selectedDogIndex];

    // 건강수첩 카테고리 (강아지 전용)
    final categories = _getCategories();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('건강수첩'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              // TODO: 건강수첩 설정 화면 구현 예정
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 강아지 선택기
          _buildDogSelector(context, ref, dogs, selectedDogIndex),
          
          // 카테고리 탭
          _buildCategoryTabs(context, ref, categories, selectedTab),
          
          // 탭 컨텐츠
          Expanded(
            child: _buildTabContent(context, ref, categories[selectedTab], selectedDog),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddRecordSheet(context, ref, categories[selectedTab]),
        backgroundColor: AppColors.health,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  /// 강아지 건강수첩 카테고리 목록
  /// - 대변/소변/음수 제거 (사용자 요청)
  /// - 놀이 제거, 그루밍 추가
  List<HealthCategory> _getCategories() {
    return [
      HealthCategory.weight,
      HealthCategory.walk,
      HealthCategory.grooming,
      HealthCategory.medication,
      HealthCategory.vaccination,
      HealthCategory.checkup,
      HealthCategory.teethCare,
      HealthCategory.special,
    ];
  }

  /// 강아지 선택기
  Widget _buildDogSelector(BuildContext context, WidgetRef ref, List<_DemoDog> dogs, int selectedIndex) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(dogs.length, (index) {
            final dog = dogs[index];
            final isSelected = index == selectedIndex;
            
            return GestureDetector(
              onTap: () => ref.read(_selectedDogProvider.notifier).state = index,
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.health : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.health : AppColors.divider,
                  ),
                ),
                child: Row(
                  children: [
                    const Text('🐶', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(
                      dog.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    if (dog.isPrimary) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.star,
                        size: 14,
                        color: isSelected ? Colors.white : AppColors.warning,
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  /// 카테고리 탭
  Widget _buildCategoryTabs(BuildContext context, WidgetRef ref, List<HealthCategory> categories, int selectedTab) {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = index == selectedTab;
          
          return GestureDetector(
            onTap: () => ref.read(_selectedTabProvider.notifier).state = index,
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.health : Colors.transparent,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isSelected ? AppColors.health : AppColors.divider,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(category.emoji, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(
                    category.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// 탭 컨텐츠
  Widget _buildTabContent(BuildContext context, WidgetRef ref, HealthCategory category, _DemoDog dog) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 카테고리별 요약 카드
          _buildSummaryCard(category, dog),
          const SizedBox(height: 20),
          
          // 최근 기록
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '최근 기록',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              GestureDetector(
                onTap: () => _showAllRecords(context, category),
                child: const Text(
                  '더보기',
                  style: TextStyle(fontSize: 14, color: AppColors.health),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildRecentRecords(category),
        ],
      ),
    );
  }

  /// 요약 카드
  Widget _buildSummaryCard(HealthCategory category, _DemoDog dog) {
    return MingrrCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.health.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(category.emoji, style: const TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${dog.name}의 ${category.label}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      category.description,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          // 카테고리별 요약 정보
          _buildCategorySummary(category),
        ],
      ),
    );
  }

  /// 카테고리별 요약 정보
  Widget _buildCategorySummary(HealthCategory category) {
    switch (category) {
      case HealthCategory.weight:
        return _buildWeightSummary();
      case HealthCategory.walk:
        return _buildWalkSummary();
      case HealthCategory.grooming:
        return _buildGroomingSummary();
      default:
        return _buildDefaultSummary(category);
    }
  }

  Widget _buildWeightSummary() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildSummaryItem('현재', '5.2kg', AppColors.health),
        _buildSummaryItem('변화', '+0.1kg', AppColors.warning),
        _buildSummaryItem('목표', '5.0kg', AppColors.success),
      ],
    );
  }

  Widget _buildWalkSummary() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildSummaryItem('오늘', '0회', AppColors.walk),
        _buildSummaryItem('이번주', '5회', AppColors.walk),
        _buildSummaryItem('총 거리', '12.5km', AppColors.walk),
      ],
    );
  }

  Widget _buildGroomingSummary() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildSummaryItem('최근 샤워', '3일 전', AppColors.health),
        _buildSummaryItem('최근 빗질', '오늘', AppColors.health),
        _buildSummaryItem('이번달', '8회', AppColors.health),
      ],
    );
  }

  Widget _buildDefaultSummary(HealthCategory category) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildSummaryItem('최근', '-', AppColors.textSecondary),
        _buildSummaryItem('이번달', '0회', AppColors.textSecondary),
        _buildSummaryItem('다음', '-', AppColors.textSecondary),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  /// 최근 기록 목록
  Widget _buildRecentRecords(HealthCategory category) {
    // 데모 데이터
    final records = List.generate(5, (index) {
      final date = DateTime.now().subtract(Duration(days: index));
      return {
        'date': '${date.month}/${date.day}',
        'time': '${14 - index}:30',
        'value': _getDemoRecordValue(category, index),
      };
    });

    return Column(
      children: records.map((record) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.health.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(category.emoji, style: const TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record['value']!,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '${record['date']} ${record['time']}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textHint),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _getDemoRecordValue(HealthCategory category, int index) {
    switch (category) {
      case HealthCategory.weight:
        return '${5.2 - index * 0.1}kg';
      case HealthCategory.walk:
        return '${30 + index * 5}분, ${(1.2 + index * 0.3).toStringAsFixed(1)}km';
      case HealthCategory.grooming:
        final types = ['샤워', '빗질', '발톱정리', '이발', '귀청소'];
        return types[index % types.length];
      default:
        return '기록됨';
    }
  }

  /// 모든 기록 보기 화면
  void _showAllRecords(BuildContext context, HealthCategory category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _AllRecordsScreen(
          category: category,
          getDemoRecordValue: _getDemoRecordValue,
        ),
      ),
    );
  }

  /// 기록 추가 바텀시트
  void _showAddRecordSheet(BuildContext context, WidgetRef ref, HealthCategory category) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // 핸들
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // 헤더
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(category.emoji, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Text(
                    '${category.label} 기록 추가',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${category.label} 기록이 저장되었습니다'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    },
                    child: const Text('저장'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // 입력 폼 (카테고리별로 다름)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _buildRecordForm(category),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 카테고리별 입력 폼
  Widget _buildRecordForm(HealthCategory category) {
    switch (category) {
      case HealthCategory.weight:
        return _buildWeightForm();
      case HealthCategory.grooming:
        return _buildGroomingForm();
      default:
        return _buildDefaultForm(category);
    }
  }

  Widget _buildWeightForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('체중 (kg)', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        const TextField(
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: '예: 5.2',
            suffixText: 'kg',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        const Text('메모 (선택)', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        const TextField(
          maxLines: 3,
          decoration: InputDecoration(
            hintText: '특이사항을 입력하세요',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildGroomingForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('그루밍 종류', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            '샤워 🚿', 
            '빗질 🪮', 
            '발톱정리 ✂️', 
            '이발 💇', 
            '귀청소 👂',
            '눈물자국 👁️',
            '항문낭 🔘',
            '발바닥 🐾',
          ].map((label) => ChoiceChip(
                label: Text(label),
                selected: label.startsWith('샤워'),
                onSelected: (value) {},
              ))
              .toList(),
        ),
        const SizedBox(height: 16),
        const Text('장소', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['집에서', '미용실', '동물병원']
              .map((label) => ChoiceChip(
                    label: Text(label),
                    selected: label == '집에서',
                    onSelected: (value) {},
                  ))
              .toList(),
        ),
        const SizedBox(height: 16),
        const Text('메모 (선택)', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        const TextField(
          maxLines: 3,
          decoration: InputDecoration(
            hintText: '특이사항을 입력하세요',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultForm(HealthCategory category) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${category.label} 기록', style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        const TextField(
          maxLines: 5,
          decoration: InputDecoration(
            hintText: '내용을 입력하세요',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}

/// 기간 필터 타입
enum _DateFilterType {
  oneWeek('1주일'),
  oneMonth('1개월'),
  threeMonths('3개월'),
  sixMonths('6개월'),
  oneYear('1년'),
  all('전체');

  final String label;
  const _DateFilterType(this.label);
  
  int? get days => switch (this) {
    _DateFilterType.oneWeek => 7,
    _DateFilterType.oneMonth => 30,
    _DateFilterType.threeMonths => 90,
    _DateFilterType.sixMonths => 180,
    _DateFilterType.oneYear => 365,
    _DateFilterType.all => null,
  };
}

/// 전체 기록 보기 화면
class _AllRecordsScreen extends StatefulWidget {
  final HealthCategory category;
  final String Function(HealthCategory, int) getDemoRecordValue;

  const _AllRecordsScreen({
    required this.category,
    required this.getDemoRecordValue,
  });

  @override
  State<_AllRecordsScreen> createState() => _AllRecordsScreenState();
}

class _AllRecordsScreenState extends State<_AllRecordsScreen> {
  _DateFilterType _selectedFilter = _DateFilterType.oneMonth; // 기본값: 1개월
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  /// 필터에 따른 데모 데이터 생성
  List<Map<String, String>> _getFilteredRecords() {
    final int totalDays = _selectedFilter.days ?? 365; // 전체는 1년치 데이터
    final records = <Map<String, String>>[];
    
    for (int i = 0; i < totalDays; i += 2) { // 2일에 1개씩 기록
      final date = DateTime.now().subtract(Duration(days: i));
      
      // 커스텀 날짜 범위 체크
      if (_customStartDate != null && date.isBefore(_customStartDate!)) continue;
      if (_customEndDate != null && date.isAfter(_customEndDate!)) continue;
      
      records.add({
        'date': '${date.year}.${date.month}.${date.day}',
        'time': '${(14 - i % 12).abs()}:${(i * 7) % 60}0',
        'value': widget.getDemoRecordValue(widget.category, i ~/ 2),
        'rawDate': date.toIso8601String(),
      });
    }
    
    return records;
  }

  void _showDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
      lastDate: DateTime.now(),
      initialDateRange: _customStartDate != null && _customEndDate != null
          ? DateTimeRange(start: _customStartDate!, end: _customEndDate!)
          : DateTimeRange(
              start: DateTime.now().subtract(const Duration(days: 30)),
              end: DateTime.now(),
            ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.health,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customStartDate = picked.start;
        _customEndDate = picked.end;
        _selectedFilter = _DateFilterType.all; // 커스텀 날짜 선택 시 필터 해제
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final records = _getFilteredRecords();
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('${widget.category.label} 기록'),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: _showDateRangePicker,
            tooltip: '날짜 선택',
          ),
        ],
      ),
      body: Column(
        children: [
          // 기간 필터 탭
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: _DateFilterType.values.map((filter) {
                  final isSelected = _selectedFilter == filter && 
                      _customStartDate == null && _customEndDate == null;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(filter.label),
                      selected: isSelected,
                      selectedColor: AppColors.health.withOpacity(0.2),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedFilter = filter;
                            _customStartDate = null;
                            _customEndDate = null;
                          });
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          
          // 선택된 날짜 범위 표시
          if (_customStartDate != null && _customEndDate != null)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  const Icon(Icons.date_range, size: 16, color: AppColors.health),
                  const SizedBox(width: 8),
                  Text(
                    '${_customStartDate!.year}.${_customStartDate!.month}.${_customStartDate!.day} ~ '
                    '${_customEndDate!.year}.${_customEndDate!.month}.${_customEndDate!.day}',
                    style: const TextStyle(fontSize: 13, color: AppColors.health),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _customStartDate = null;
                        _customEndDate = null;
                        _selectedFilter = _DateFilterType.oneMonth;
                      });
                    },
                    child: const Icon(Icons.close, size: 18, color: AppColors.textHint),
                  ),
                ],
              ),
            ),
          
          // 기록 개수 표시
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            alignment: Alignment.centerLeft,
            child: Text(
              '총 ${records.length}개의 기록',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          
          // 기록 목록
          Expanded(
            child: records.isEmpty
                ? const Center(
                    child: Text(
                      '해당 기간에 기록이 없습니다',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: records.length,
                    itemBuilder: (context, index) {
                      final record = records[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.health.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  widget.category.emoji,
                                  style: const TextStyle(fontSize: 18),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    record['value']!,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    '${record['date']} ${record['time']}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: AppColors.textHint,
                                size: 20,
                              ),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('기록이 삭제되었습니다')),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
