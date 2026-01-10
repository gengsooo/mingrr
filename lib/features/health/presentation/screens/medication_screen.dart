import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/svg_icons.dart';
import '../../../../core/widgets/dialogs/dialogs.dart';

/// ============================================================
/// 약 관리 화면
/// 약 종류별 아이콘 선택 및 관리 기능
/// ============================================================

/// 약 종류 enum - 모든 아이콘을 약 관련으로 통일
enum MedicationType {
  pill('알약', Icons.medication, '💊'),
  capsule('캡슐', Icons.medication_liquid, '💊'),
  liquid('물약', Icons.vaccines, '💧'),
  injection('주사', Icons.vaccines, '💉'),
  ointment('연고', Icons.medication, '🧴'),
  eyeDrop('안약', Icons.medication_liquid, '💧'),
  earDrop('귀약', Icons.medication_liquid, '💧'),
  powder('가루약', Icons.medication, '💊'),
  chewable('츄어블', Icons.medication, '💊'),
  supplement('영양제', Icons.local_pharmacy, '💊');

  final String label;
  final IconData icon;
  final String emoji;
  const MedicationType(this.label, this.icon, this.emoji);
}

/// 복용 주기 enum
enum MedicationFrequency {
  daily('매일'),
  twiceDaily('하루 2회'),
  threeTimesDaily('하루 3회'),
  weekly('매주'),
  biweekly('2주마다'),
  monthly('매월'),
  asNeeded('필요시');

  final String label;
  const MedicationFrequency(this.label);
}

/// 약 데이터 모델
class Medication {
  final String id;
  final String name;
  final MedicationType type;
  final String? customEmoji;
  final MedicationFrequency frequency;
  final List<TimeOfDay> times;
  final DateTime startDate;
  final DateTime? endDate;
  final String? dosage;
  final String? memo;
  final bool isActive;
  final String petId;
  final String petName;

  const Medication({
    required this.id,
    required this.name,
    required this.type,
    this.customEmoji,
    required this.frequency,
    required this.times,
    required this.startDate,
    this.endDate,
    this.dosage,
    this.memo,
    this.isActive = true,
    required this.petId,
    required this.petName,
  });

  String get displayEmoji => customEmoji ?? type.emoji;

  Medication copyWith({
    String? id,
    String? name,
    MedicationType? type,
    String? customEmoji,
    MedicationFrequency? frequency,
    List<TimeOfDay>? times,
    DateTime? startDate,
    DateTime? endDate,
    String? dosage,
    String? memo,
    bool? isActive,
    String? petId,
    String? petName,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      customEmoji: customEmoji ?? this.customEmoji,
      frequency: frequency ?? this.frequency,
      times: times ?? this.times,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      dosage: dosage ?? this.dosage,
      memo: memo ?? this.memo,
      isActive: isActive ?? this.isActive,
      petId: petId ?? this.petId,
      petName: petName ?? this.petName,
    );
  }

  factory Medication.demo({int index = 0}) {
    final types = MedicationType.values;
    final frequencies = MedicationFrequency.values;
    final names = ['심장약', '피부약', '관절 영양제', '구충제', '항생제', '소화제', '진통제', '비타민'];
    
    return Medication(
      id: 'med_$index',
      name: names[index % names.length],
      type: types[index % types.length],
      frequency: frequencies[index % frequencies.length],
      times: [TimeOfDay(hour: 8 + index % 12, minute: 0)],
      startDate: DateTime.now().subtract(Duration(days: index * 7)),
      endDate: index % 3 == 0 ? DateTime.now().add(Duration(days: 30 - index * 5)) : null,
      dosage: '${1 + index % 3}정',
      memo: index % 2 == 0 ? '식후 30분에 복용' : null,
      isActive: index < 5,
      petId: 'pet_1',
      petName: '뽀삐',
    );
  }
}

/// 약 관리 화면
class MedicationScreen extends ConsumerStatefulWidget {
  const MedicationScreen({super.key});

  @override
  ConsumerState<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends ConsumerState<MedicationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // 데모 데이터
  late List<Medication> _medications;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _medications = List.generate(8, (i) => Medication.demo(index: i));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Medication> get _activeMedications =>
      _medications.where((m) => m.isActive).toList();
  
  List<Medication> get _inactiveMedications =>
      _medications.where((m) => !m.isActive).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('약 관리'),
        backgroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.health,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.health,
          tabs: [
            Tab(text: '복용 중 (${_activeMedications.length})'),
            Tab(text: '완료 (${_inactiveMedications.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMedicationList(_activeMedications, isActive: true),
          _buildMedicationList(_inactiveMedications, isActive: false),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMedicationSheet(context),
        backgroundColor: AppColors.health,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('약 추가', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildMedicationList(List<Medication> medications, {required bool isActive}) {
    if (medications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? Icons.medication_outlined : Icons.check_circle_outline,
              size: 64,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 16),
            Text(
              isActive ? '복용 중인 약이 없습니다' : '완료된 약이 없습니다',
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    // 타입별로 그룹화
    final groupedMeds = <MedicationType, List<Medication>>{};
    for (final med in medications) {
      groupedMeds.putIfAbsent(med.type, () => []).add(med);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: groupedMeds.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 타입 헤더
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Text(entry.key.emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(
                    entry.key.label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.health.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${entry.value.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.health,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // 약 목록
            ...entry.value.map((med) => _buildMedicationCard(med)),
            const SizedBox(height: 8),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildMedicationCard(Medication medication) {
    return GestureDetector(
      onTap: () => _showMedicationDetail(medication),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            // 아이콘
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.health.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  medication.displayEmoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          medication.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.walk.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          medication.petName,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.walk,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${medication.frequency.label} • ${medication.dosage ?? ''}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (medication.times.isNotEmpty)
                    Text(
                      medication.times.map((t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}').join(', '),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.health,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }

  void _showMedicationDetail(Medication medication) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MedicationDetailScreen(
          medication: medication,
          onUpdate: (updated) {
            setState(() {
              final index = _medications.indexWhere((m) => m.id == updated.id);
              if (index != -1) {
                _medications[index] = updated;
              }
            });
          },
          onDelete: () {
            setState(() {
              _medications.removeWhere((m) => m.id == medication.id);
            });
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _showAddMedicationSheet(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddMedicationScreen(
          onAdd: (medication) {
            setState(() {
              _medications.insert(0, medication);
            });
          },
        ),
      ),
    );
  }
}

/// 약 상세 화면
class MedicationDetailScreen extends StatelessWidget {
  final Medication medication;
  final Function(Medication) onUpdate;
  final VoidCallback onDelete;

  const MedicationDetailScreen({
    super.key,
    required this.medication,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('약 상세'),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              // TODO: 수정 화면
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('수정 기능은 준비 중입니다')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 헤더 카드
            MingrrCard(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  // 아이콘 & 이름
                  Row(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: AppColors.health.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            medication.displayEmoji,
                            style: const TextStyle(fontSize: 36),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              medication.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: medication.isActive
                                    ? AppColors.success.withOpacity(0.1)
                                    : AppColors.textHint.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                medication.isActive ? '복용 중' : '완료',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: medication.isActive
                                      ? AppColors.success
                                      : AppColors.textHint,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),
                  // 기본 정보
                  _buildInfoRow('종류', medication.type.label),
                  _buildInfoRow('복용량', medication.dosage ?? '-'),
                  _buildInfoRow('복용 주기', medication.frequency.label),
                  _buildInfoRow(
                    '복용 시간',
                    medication.times.map((t) => 
                      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}'
                    ).join(', '),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 기간 정보
            MingrrCard(
              margin: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '복용 기간',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow('시작일', _formatDate(medication.startDate)),
                  _buildInfoRow(
                    '종료일',
                    medication.endDate != null
                        ? _formatDate(medication.endDate!)
                        : '계속 복용',
                  ),
                  if (medication.endDate != null)
                    _buildInfoRow(
                      '남은 기간',
                      _getRemainingDays(medication.endDate!),
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 반려동물 정보
            MingrrCard(
              margin: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '복용 대상',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const DefaultPetIcon(size: 24),
                      const SizedBox(width: 12),
                      Text(
                        medication.petName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // 메모
            if (medication.memo != null && medication.memo!.isNotEmpty) ...[
              const SizedBox(height: 16),
              MingrrCard(
                margin: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.note_outlined, size: 20, color: AppColors.textSecondary),
                        SizedBox(width: 8),
                        Text(
                          '메모',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      medication.memo!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            
            // 복용 완료/재시작 버튼
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  onUpdate(medication.copyWith(isActive: !medication.isActive));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        medication.isActive ? '복용이 완료되었습니다' : '복용을 재시작합니다',
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: medication.isActive
                      ? AppColors.success
                      : AppColors.health,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  medication.isActive ? '복용 완료' : '복용 재시작',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month}.${date.day}';
  }

  String _getRemainingDays(DateTime endDate) {
    final remaining = endDate.difference(DateTime.now()).inDays;
    if (remaining < 0) return '종료됨';
    if (remaining == 0) return '오늘 종료';
    return '$remaining일 남음';
  }

  void _confirmDelete(BuildContext context) {
    showConfirmSheet(
      context,
      type: ConfirmSheetType.medicationDelete,
      message: '${medication.name}을(를) 삭제하시겠습니까?',
      onConfirm: () {
        onDelete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('약이 삭제되었습니다')),
        );
      },
    );
  }
}

/// 약 추가 화면
class AddMedicationScreen extends StatefulWidget {
  final Function(Medication) onAdd;

  const AddMedicationScreen({super.key, required this.onAdd});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _memoController = TextEditingController();
  
  MedicationType _selectedType = MedicationType.pill;
  String? _customEmoji;
  MedicationFrequency _selectedFrequency = MedicationFrequency.daily;
  List<TimeOfDay> _times = [const TimeOfDay(hour: 8, minute: 0)];
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('약 추가'),
        backgroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _saveMedication,
            child: const Text('저장'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 약 이름
            const Text('약 이름 *', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: '예: 심장약, 피부약',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // 약 종류 선택
            const Text('약 종류 *', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            _buildTypeSelector(),
            
            const SizedBox(height: 20),
            
            // 아이콘 커스터마이징
            const Text('아이콘 변경 (선택)', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _buildEmojiSelector(),
            
            const SizedBox(height: 20),
            
            // 복용량
            const Text('복용량', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _dosageController,
              decoration: InputDecoration(
                hintText: '예: 1정, 5ml',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // 복용 주기
            const Text('복용 주기 *', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: MedicationFrequency.values.map((freq) {
                final isSelected = _selectedFrequency == freq;
                return ChoiceChip(
                  label: Text(freq.label),
                  selected: isSelected,
                  selectedColor: AppColors.health.withOpacity(0.2),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedFrequency = freq);
                    }
                  },
                );
              }).toList(),
            ),
            
            const SizedBox(height: 20),
            
            // 복용 시간
            const Text('복용 시간', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            _buildTimeSelector(),
            
            const SizedBox(height: 20),
            
            // 시작일
            const Text('시작일 *', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _buildDateSelector('시작일', _startDate, (date) {
              setState(() => _startDate = date);
            }),
            
            const SizedBox(height: 16),
            
            // 종료일
            const Text('종료일 (선택)', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _buildDateSelector('종료일', _endDate, (date) {
              setState(() => _endDate = date);
            }, isOptional: true),
            
            const SizedBox(height: 20),
            
            // 메모
            const Text('메모 (선택)', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _memoController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: '복용 시 주의사항 등',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: MedicationType.values.map((type) {
        final isSelected = _selectedType == type;
        return GestureDetector(
          onTap: () => setState(() => _selectedType = type),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.health.withOpacity(0.15) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppColors.health : AppColors.divider,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(type.emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  type.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? AppColors.health : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmojiSelector() {
    // 약 아이콘만 색상별로 제공 (알약 형태만)
    final medicationIcons = [
      {'icon': Icons.medication, 'color': AppColors.health, 'label': '기본'},
      {'icon': Icons.medication, 'color': Colors.red, 'label': '빨강'},
      {'icon': Icons.medication, 'color': Colors.orange, 'label': '주황'},
      {'icon': Icons.medication, 'color': Colors.amber, 'label': '노랑'},
      {'icon': Icons.medication, 'color': Colors.green, 'label': '초록'},
      {'icon': Icons.medication, 'color': Colors.blue, 'label': '파랑'},
      {'icon': Icons.medication, 'color': Colors.purple, 'label': '보라'},
      {'icon': Icons.medication, 'color': Colors.pink, 'label': '분홍'},
      {'icon': Icons.medication, 'color': Colors.teal, 'label': '청록'},
      {'icon': Icons.medication, 'color': Colors.brown, 'label': '갈색'},
      {'icon': Icons.medication, 'color': Colors.indigo, 'label': '남색'},
      {'icon': Icons.medication, 'color': Colors.grey, 'label': '회색'},
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '약 아이콘 색상을 선택하세요',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: medicationIcons.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isSelected = _customEmoji == index.toString();
            return GestureDetector(
              onTap: () => setState(() {
                _customEmoji = isSelected ? null : index.toString();
              }),
              child: Column(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? (item['color'] as Color).withOpacity(0.2) 
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected 
                            ? (item['color'] as Color) 
                            : AppColors.divider,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        item['icon'] as IconData,
                        size: 28,
                        color: item['color'] as Color,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['label'] as String,
                    style: TextStyle(
                      fontSize: 10,
                      color: isSelected 
                          ? (item['color'] as Color) 
                          : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTimeSelector() {
    return Column(
      children: [
        ...List.generate(_times.length, (index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time, color: AppColors.health),
                const SizedBox(width: 12),
                Text(
                  '${_times[index].hour.toString().padLeft(2, '0')}:${_times[index].minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _times[index],
                    );
                    if (time != null) {
                      setState(() => _times[index] = time);
                    }
                  },
                  child: const Text('변경', style: TextStyle(color: AppColors.health)),
                ),
                if (_times.length > 1) ...[
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () => setState(() => _times.removeAt(index)),
                    child: const Icon(Icons.close, color: AppColors.textHint, size: 20),
                  ),
                ],
              ],
            ),
          );
        }),
        TextButton.icon(
          onPressed: () async {
            final time = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.now(),
            );
            if (time != null) {
              setState(() => _times.add(time));
            }
          },
          icon: const Icon(Icons.add),
          label: const Text('시간 추가'),
        ),
      ],
    );
  }

  Widget _buildDateSelector(String label, DateTime? date, Function(DateTime) onSelect, {bool isOptional = false}) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
        );
        if (picked != null) {
          onSelect(picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              color: date != null ? AppColors.health : AppColors.textHint,
            ),
            const SizedBox(width: 12),
            Text(
              date != null
                  ? '${date.year}.${date.month}.${date.day}'
                  : (isOptional ? '선택 안함 (계속 복용)' : '$label 선택'),
              style: TextStyle(
                fontSize: 14,
                color: date != null ? AppColors.textPrimary : AppColors.textHint,
              ),
            ),
            if (isOptional && date != null) ...[
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _endDate = null),
                child: const Icon(Icons.close, color: AppColors.textHint, size: 20),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _saveMedication() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('약 이름을 입력해주세요')),
      );
      return;
    }

    final medication = Medication(
      id: 'med_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      type: _selectedType,
      customEmoji: _customEmoji,
      frequency: _selectedFrequency,
      times: _times,
      startDate: _startDate,
      endDate: _endDate,
      dosage: _dosageController.text.trim().isEmpty ? null : _dosageController.text.trim(),
      memo: _memoController.text.trim().isEmpty ? null : _memoController.text.trim(),
      isActive: true,
      petId: 'pet_1',
      petName: '뽀삐',
    );

    widget.onAdd(medication);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('약이 추가되었습니다')),
    );
  }
}
