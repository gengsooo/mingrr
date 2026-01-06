import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/pet_constants.dart';
import '../providers/health_provider.dart';

/// ============================================================
/// 건강수첩 기록 추가 바텀시트 모음 (단순화 버전)
/// - 체중: 체중 + 날짜 + 메모
/// - 그루밍: 종류 + 날짜 + 메모 (양치/치석 포함)
/// - 예방접종: 날짜 + 메모
/// - 검진: 날짜 + 메모
/// - 약: 약이름 + 아이콘 + 날짜 + 메모
/// - 특이사항: 날짜 + 메모
/// ============================================================

final _healthService = HealthService();

// ===== 공통 바텀시트 래퍼 =====
class _RecordBottomSheet extends StatelessWidget {
  final String title;
  final VoidCallback onSave;
  final Widget child;

  const _RecordBottomSheet({required this.title, required this.onSave, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 핸들바
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)),
          ),
          // 헤더
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
            child: Row(
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton(
                  onPressed: onSave,
                  child: const Text('저장', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // 컨텐츠
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: child,
            ),
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }
}

// ===== 공통 위젯 =====
Widget _buildDateSelector(BuildContext context, DateTime date, Function(DateTime) onSelect) {
  return GestureDetector(
    onTap: () async {
      final picked = await showDatePicker(
        context: context,
        initialDate: date,
        firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
        lastDate: DateTime.now().add(const Duration(days: 365)),
      );
      if (picked != null) onSelect(picked);
    },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, color: AppColors.health, size: 20),
          const SizedBox(width: 12),
          Text('${date.year}년 ${date.month}월 ${date.day}일'),
          const Spacer(),
          const Icon(Icons.chevron_right, color: AppColors.textHint, size: 20),
        ],
      ),
    ),
  );
}

Widget _buildMemoField(TextEditingController controller, {String? hint, int maxLines = 3}) {
  return TextField(
    controller: controller,
    maxLines: maxLines,
    decoration: InputDecoration(
      hintText: hint ?? '메모를 입력하세요',
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: AppColors.background,
    ),
  );
}

Widget _buildLabel(String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
  );
}

// ===== 체중 기록 바텀시트 =====
class AddWeightRecordScreen extends StatefulWidget {
  final String petId;
  final String petName;

  const AddWeightRecordScreen({super.key, required this.petId, required this.petName});

  static void show(BuildContext context, String petId, String petName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddWeightRecordScreen(petId: petId, petName: petName),
    );
  }

  @override
  State<AddWeightRecordScreen> createState() => _AddWeightRecordScreenState();
}

class _AddWeightRecordScreenState extends State<AddWeightRecordScreen> {
  final _weightController = TextEditingController();
  final _memoController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _weightController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _RecordBottomSheet(
      title: '체중 기록',
      onSave: _saveRecord,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('체중 (kg) *'),
          TextField(
            controller: _weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: '예: 5.2',
              suffixText: 'kg',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: AppColors.background,
            ),
          ),
          const SizedBox(height: 16),
          _buildLabel('날짜 *'),
          _buildDateSelector(context, _selectedDate, (d) => setState(() => _selectedDate = d)),
          const SizedBox(height: 16),
          _buildLabel('메모'),
          _buildMemoField(_memoController),
        ],
      ),
    );
  }

  Future<void> _saveRecord() async {
    if (_weightController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('체중을 입력해주세요')));
      return;
    }
    final weight = double.tryParse(_weightController.text);
    if (weight == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('올바른 체중을 입력해주세요')));
      return;
    }
    try {
      await _healthService.addWeightRecord(petId: widget.petId, weight: weight, recordDate: _selectedDate, notes: _memoController.text.isNotEmpty ? _memoController.text : null);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('체중 기록이 저장되었습니다'), backgroundColor: AppColors.success));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('저장 실패: $e')));
    }
  }
}

// ===== 그루밍 기록 바텀시트 (양치/치석 포함) =====
class AddGroomingRecordScreen extends StatefulWidget {
  final String petId;
  final String petName;

  const AddGroomingRecordScreen({super.key, required this.petId, required this.petName});

  static void show(BuildContext context, String petId, String petName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddGroomingRecordScreen(petId: petId, petName: petName),
    );
  }

  @override
  State<AddGroomingRecordScreen> createState() => _AddGroomingRecordScreenState();
}

class _AddGroomingRecordScreenState extends State<AddGroomingRecordScreen> {
  final _memoController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  GroomingType _selectedType = GroomingType.shower;

  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _RecordBottomSheet(
      title: '그루밍 기록',
      onSave: _saveRecord,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('종류 *'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: GroomingType.values.map((type) {
              final isSelected = _selectedType == type;
              return GestureDetector(
                onTap: () => setState(() => _selectedType = type),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.health.withOpacity(0.15) : AppColors.background,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isSelected ? AppColors.health : AppColors.divider, width: isSelected ? 2 : 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(type.emoji, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 4),
                      Text(type.label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400, color: isSelected ? AppColors.health : AppColors.textPrimary)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          _buildLabel('날짜 *'),
          _buildDateSelector(context, _selectedDate, (d) => setState(() => _selectedDate = d)),
          const SizedBox(height: 16),
          _buildLabel('메모'),
          _buildMemoField(_memoController),
        ],
      ),
    );
  }

  Future<void> _saveRecord() async {
    try {
      await _healthService.addGroomingRecord(petId: widget.petId, groomingType: _selectedType.name, recordDate: _selectedDate, notes: _memoController.text.isNotEmpty ? _memoController.text : null);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('그루밍 기록이 저장되었습니다'), backgroundColor: AppColors.success));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('저장 실패: $e')));
    }
  }
}

// ===== 예방접종 기록 바텀시트 =====
class AddVaccinationRecordScreen extends StatefulWidget {
  final String petId;
  final String petName;

  const AddVaccinationRecordScreen({super.key, required this.petId, required this.petName});

  static void show(BuildContext context, String petId, String petName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddVaccinationRecordScreen(petId: petId, petName: petName),
    );
  }

  @override
  State<AddVaccinationRecordScreen> createState() => _AddVaccinationRecordScreenState();
}

class _AddVaccinationRecordScreenState extends State<AddVaccinationRecordScreen> {
  final _memoController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _RecordBottomSheet(
      title: '예방접종 기록',
      onSave: _saveRecord,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('접종일 *'),
          _buildDateSelector(context, _selectedDate, (d) => setState(() => _selectedDate = d)),
          const SizedBox(height: 16),
          _buildLabel('메모'),
          _buildMemoField(_memoController, hint: '백신 종류, 병원, 다음 접종일, 비용 등'),
        ],
      ),
    );
  }

  Future<void> _saveRecord() async {
    try {
      await _healthService.addVaccinationRecord(petId: widget.petId, vaccineName: '예방접종', vaccinationDate: _selectedDate, notes: _memoController.text.isNotEmpty ? _memoController.text : null);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('예방접종 기록이 저장되었습니다'), backgroundColor: AppColors.success));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('저장 실패: $e')));
    }
  }
}

// ===== 검진 기록 바텀시트 =====
class AddCheckupRecordScreen extends StatefulWidget {
  final String petId;
  final String petName;

  const AddCheckupRecordScreen({super.key, required this.petId, required this.petName});

  static void show(BuildContext context, String petId, String petName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddCheckupRecordScreen(petId: petId, petName: petName),
    );
  }

  @override
  State<AddCheckupRecordScreen> createState() => _AddCheckupRecordScreenState();
}

class _AddCheckupRecordScreenState extends State<AddCheckupRecordScreen> {
  final _memoController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _RecordBottomSheet(
      title: '검진 기록',
      onSave: _saveRecord,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('검진일 *'),
          _buildDateSelector(context, _selectedDate, (d) => setState(() => _selectedDate = d)),
          const SizedBox(height: 16),
          _buildLabel('메모'),
          _buildMemoField(_memoController, hint: '검진 종류, 결과, 병원, 비용, 다음 검진일 등'),
        ],
      ),
    );
  }

  Future<void> _saveRecord() async {
    try {
      await _healthService.addCheckupRecord(petId: widget.petId, checkupDate: _selectedDate, notes: _memoController.text.isNotEmpty ? _memoController.text : null);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('검진 기록이 저장되었습니다'), backgroundColor: AppColors.success));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('저장 실패: $e')));
    }
  }
}

// ===== 약 관리 기록 바텀시트 =====
class AddMedicationRecordScreen extends StatefulWidget {
  final String petId;
  final String petName;

  const AddMedicationRecordScreen({super.key, required this.petId, required this.petName});

  static void show(BuildContext context, String petId, String petName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddMedicationRecordScreen(petId: petId, petName: petName),
    );
  }

  @override
  State<AddMedicationRecordScreen> createState() => _AddMedicationRecordScreenState();
}

class _AddMedicationRecordScreenState extends State<AddMedicationRecordScreen> {
  final _nameController = TextEditingController();
  final _memoController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _selectedIcon = '💊';

  final List<String> _icons = ['💊', '💉', '🩹', '🧴', '🩺', '🏥', '❤️', '⭐'];

  @override
  void dispose() {
    _nameController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _RecordBottomSheet(
      title: '약 기록',
      onSave: _saveRecord,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('약 이름 *'),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: '예: 심장사상충약, 관절영양제',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: AppColors.background,
            ),
          ),
          const SizedBox(height: 16),
          _buildLabel('아이콘'),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _icons.map((icon) {
              final isSelected = _selectedIcon == icon;
              return GestureDetector(
                onTap: () => setState(() => _selectedIcon = icon),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.health.withOpacity(0.15) : AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isSelected ? AppColors.health : AppColors.divider, width: isSelected ? 2 : 1),
                  ),
                  child: Center(child: Text(icon, style: const TextStyle(fontSize: 22))),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          _buildLabel('날짜 *'),
          _buildDateSelector(context, _selectedDate, (d) => setState(() => _selectedDate = d)),
          const SizedBox(height: 16),
          _buildLabel('메모'),
          _buildMemoField(_memoController),
        ],
      ),
    );
  }

  Future<void> _saveRecord() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('약 이름을 입력해주세요')));
      return;
    }
    try {
      await _healthService.addMedicationRecord(petId: widget.petId, medicationName: '$_selectedIcon ${_nameController.text}', startDate: _selectedDate, notes: _memoController.text.isNotEmpty ? _memoController.text : null);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('약 기록이 저장되었습니다'), backgroundColor: AppColors.success));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('저장 실패: $e')));
    }
  }
}

// ===== 특이사항 기록 바텀시트 =====
class AddSpecialRecordScreen extends StatefulWidget {
  final String petId;
  final String petName;

  const AddSpecialRecordScreen({super.key, required this.petId, required this.petName});

  static void show(BuildContext context, String petId, String petName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddSpecialRecordScreen(petId: petId, petName: petName),
    );
  }

  @override
  State<AddSpecialRecordScreen> createState() => _AddSpecialRecordScreenState();
}

class _AddSpecialRecordScreenState extends State<AddSpecialRecordScreen> {
  final _memoController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _RecordBottomSheet(
      title: '특이사항 기록',
      onSave: _saveRecord,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('날짜 *'),
          _buildDateSelector(context, _selectedDate, (d) => setState(() => _selectedDate = d)),
          const SizedBox(height: 16),
          _buildLabel('메모 *'),
          _buildMemoField(_memoController, hint: '증상, 행동, 식이 변화 등 특이사항을 기록하세요', maxLines: 5),
        ],
      ),
    );
  }

  Future<void> _saveRecord() async {
    if (_memoController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('메모를 입력해주세요')));
      return;
    }
    try {
      await _healthService.addSpecialNote(petId: widget.petId, recordDate: _selectedDate, title: '특이사항', content: _memoController.text, category: '기타');
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('특이사항 기록이 저장되었습니다'), backgroundColor: AppColors.success));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('저장 실패: $e')));
    }
  }
}
