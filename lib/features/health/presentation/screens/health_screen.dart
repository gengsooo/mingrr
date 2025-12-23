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

/// 산책 중 여부
final _isWalkingProvider = StateProvider<bool>((ref) => false);

/// 산책 중인 강아지 ID 목록 (다중 선택)
final _walkingDogIdsProvider = StateProvider<List<String>>((ref) => []);

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
    final isWalking = ref.watch(_isWalkingProvider);
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
              // TODO: 건강수첩 설정
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 강아지 선택기
          _buildDogSelector(context, ref, dogs, selectedDogIndex),
          
          // 산책 ON/OFF (강아지는 항상 산책 가능)
          _buildWalkToggle(context, ref, dogs, isWalking),
          
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
  List<HealthCategory> _getCategories() {
    return [
      HealthCategory.weight,
      HealthCategory.walk,
      HealthCategory.play,
      HealthCategory.vaccination,
      HealthCategory.checkup,
      HealthCategory.medication,
      HealthCategory.shower,
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

  /// 산책 ON/OFF 토글 (다중 강아지 지원)
  Widget _buildWalkToggle(BuildContext context, WidgetRef ref, List<_DemoDog> dogs, bool isWalking) {
    final walkingDogIds = ref.watch(_walkingDogIdsProvider);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isWalking ? AppColors.walk.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isWalking ? AppColors.walk : AppColors.divider,
          width: isWalking ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isWalking ? AppColors.walk : AppColors.walk.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.directions_walk,
                  color: isWalking ? Colors.white : AppColors.walk,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isWalking ? '산책 중' : '산책 시작하기',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isWalking ? AppColors.walk : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      isWalking 
                          ? '경로가 기록되고 있어요 (본인만 확인 가능)'
                          : '산책을 시작하면 경로와 시간이 기록돼요',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isWalking,
                onChanged: (value) {
                  if (value && walkingDogIds.isEmpty) {
                    // 산책 시작 시 강아지 선택
                    _showWalkDogSelector(context, ref, dogs);
                  } else {
                    ref.read(_isWalkingProvider.notifier).state = value;
                    if (!value) {
                      ref.read(_walkingDogIdsProvider.notifier).state = [];
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('산책이 종료되었어요. 기록이 저장되었습니다.'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  }
                },
                activeColor: AppColors.walk,
              ),
            ],
          ),
          // 산책 중인 강아지 표시
          if (isWalking && walkingDogIds.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  '산책 중: ',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                ...walkingDogIds.map((id) {
                  final dog = dogs.firstWhere((d) => d.id == id);
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.walk.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '🐶 ${dog.name}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  );
                }),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// 산책할 강아지 선택 바텀시트
  void _showWalkDogSelector(BuildContext context, WidgetRef ref, List<_DemoDog> dogs) {
    final selectedIds = <String>[];
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '산책할 강아지 선택',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                '여러 마리를 동시에 선택할 수 있어요',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              ...dogs.map((dog) {
                final isSelected = selectedIds.contains(dog.id);
                return CheckboxListTile(
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        selectedIds.add(dog.id);
                      } else {
                        selectedIds.remove(dog.id);
                      }
                    });
                  },
                  title: Row(
                    children: [
                      const Text('🐶', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Text(dog.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                  activeColor: AppColors.walk,
                );
              }),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectedIds.isEmpty ? null : () {
                    ref.read(_walkingDogIdsProvider.notifier).state = selectedIds;
                    ref.read(_isWalkingProvider.notifier).state = true;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('산책을 시작했어요! 🐕 경로가 기록됩니다.'),
                        backgroundColor: AppColors.walk,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.walk,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '산책 시작',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
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
          const Text(
            '최근 기록',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
      case HealthCategory.play:
        return _buildPlaySummary();
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

  Widget _buildPlaySummary() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildSummaryItem('오늘', '15분', AppColors.dating),
        _buildSummaryItem('이번주', '2시간', AppColors.dating),
        _buildSummaryItem('평균', '20분/일', AppColors.dating),
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
      case HealthCategory.play:
        return '${15 + index * 5}분';
      default:
        return '기록됨';
    }
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
      case HealthCategory.play:
        return _buildPlayForm();
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

  Widget _buildPlayForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('놀이 시간 (분)', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        const TextField(
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: '예: 30',
            suffixText: '분',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        const Text('놀이 종류', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['공놀이 🎾', '터그놀이 🪢', '숨바꼭질 🙈', '산책놀이 🚶', '훈련 🎓', '기타']
              .map((label) => ChoiceChip(
                    label: Text(label),
                    selected: label.startsWith('공놀이'),
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
