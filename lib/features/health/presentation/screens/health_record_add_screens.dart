import 'package:flutter/material.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/feature_colors.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/pet_constants.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/mingrr_bottom_sheet.dart';
import '../../../../core/widgets/form_components.dart';
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

// ===== 공통 바텀시트 래퍼 (MingrrInputBottomSheet 사용) =====
// 키보드가 올라와도 저장 버튼이 키보드 위에 표시됨
Widget _buildRecordBottomSheet({
  required BuildContext context,
  required String title,
  required VoidCallback onSave,
  required Widget child,
}) {
  return MingrrInputBottomSheet(
    title: title,
    buttonLabel: '저장',
    buttonColor: context.features.health,
    onSave: onSave,
    child: child,
  );
}

// ===== 공통 위젯 (MingrrDateSelector 사용) =====
Widget _buildDateSelector(BuildContext context, DateTime date, Function(DateTime) onSelect) {
  return MingrrDateSelector(
    date: date,
    onSelect: onSelect,
    accentColor: context.features.health,
  );
}

Widget _buildMemoField(BuildContext context, TextEditingController controller, {String? hint, int maxLines = 3}) {
  return TextField(
    controller: controller,
    maxLines: maxLines,
    decoration: InputDecoration(
      hintText: hint ?? '메모를 입력하세요',
      hintStyle: AppTextStyles.secondary(context).copyWith(color: Theme.of(context).colorScheme.outlineVariant),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusS),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusS),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusS),
        borderSide: BorderSide(color: context.features.health, width: 1.5),
      ),
    ),
  );
}

Widget _buildLabel(String text, {bool isRequired = false}) {
  final label = text.replaceAll(' *', '');
  return MingrrSectionLabel(label, isRequired: isRequired || text.contains('*'));
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
    return _buildRecordBottomSheet(
      context: context,
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
              hintStyle: AppTextStyles.secondary(context).copyWith(color: Theme.of(context).colorScheme.outlineVariant),
              suffixText: 'kg',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusS),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusS),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusS),
                borderSide: BorderSide(color: context.features.health, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.gapL),
          _buildLabel('날짜 *'),
          _buildDateSelector(context, _selectedDate, (d) => setState(() => _selectedDate = d)),
          const SizedBox(height: AppSizes.gapL),
          _buildLabel('메모'),
          _buildMemoField(context, _memoController),
        ],
      ),
    );
  }

  Future<void> _saveRecord() async {
    if (_weightController.text.isEmpty) {
      MingrrSnackBar.warning(context, '체중을 입력해주세요');
      return;
    }
    final weight = double.tryParse(_weightController.text);
    if (weight == null) {
      MingrrSnackBar.warning(context, '올바른 체중을 입력해주세요');
      return;
    }
    try {
      await _healthService.addWeightRecord(petId: widget.petId, weight: weight, recordDate: _selectedDate, notes: _memoController.text.isNotEmpty ? _memoController.text : null);
      if (mounted) {
        Navigator.pop(context);
        MingrrSnackBar.success(context, '체중 기록이 저장되었습니다');
      }
    } catch (e) {
      if (mounted) ErrorHandler.showSnackBar(context, message: '저장에 실패했습니다');
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
    return _buildRecordBottomSheet(
      context: context,
      title: '그루밍 기록',
      onSave: _saveRecord,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('종류 *'),
          MingrrChipSelector<GroomingType>(
            items: GroomingType.values,
            selectedItem: _selectedType,
            onSelected: (type) => setState(() => _selectedType = type),
            labelBuilder: (type) => type.label,
            iconBuilder: (type) => type.icon,
            accentColor: context.features.health,
          ),
          const SizedBox(height: AppSizes.gapL),
          _buildLabel('날짜 *'),
          _buildDateSelector(context, _selectedDate, (d) => setState(() => _selectedDate = d)),
          const SizedBox(height: AppSizes.gapL),
          _buildLabel('메모'),
          _buildMemoField(context, _memoController),
        ],
      ),
    );
  }

  Future<void> _saveRecord() async {
    try {
      await _healthService.addGroomingRecord(petId: widget.petId, groomingType: _selectedType.name, recordDate: _selectedDate, notes: _memoController.text.isNotEmpty ? _memoController.text : null);
      if (mounted) {
        Navigator.pop(context);
        MingrrSnackBar.success(context, '그루밍 기록이 저장되었습니다');
      }
    } catch (e) {
      if (mounted) ErrorHandler.showSnackBar(context, message: '저장에 실패했습니다');
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
    return _buildRecordBottomSheet(
      context: context,
      title: '예방접종 기록',
      onSave: _saveRecord,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('접종일 *'),
          _buildDateSelector(context, _selectedDate, (d) => setState(() => _selectedDate = d)),
          const SizedBox(height: AppSizes.gapL),
          _buildLabel('메모'),
          _buildMemoField(context, _memoController, hint: '백신 종류, 병원, 다음 접종일, 비용 등'),
        ],
      ),
    );
  }

  Future<void> _saveRecord() async {
    try {
      await _healthService.addVaccinationRecord(petId: widget.petId, vaccineName: '예방접종', vaccinationDate: _selectedDate, notes: _memoController.text.isNotEmpty ? _memoController.text : null);
      if (mounted) {
        Navigator.pop(context);
        MingrrSnackBar.success(context, '예방접종 기록이 저장되었습니다');
      }
    } catch (e) {
      if (mounted) ErrorHandler.showSnackBar(context, message: '저장에 실패했습니다');
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
    return _buildRecordBottomSheet(
      context: context,
      title: '검진 기록',
      onSave: _saveRecord,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('검진일 *'),
          _buildDateSelector(context, _selectedDate, (d) => setState(() => _selectedDate = d)),
          const SizedBox(height: AppSizes.gapL),
          _buildLabel('메모'),
          _buildMemoField(context, _memoController, hint: '검진 종류, 결과, 병원, 비용, 다음 검진일 등'),
        ],
      ),
    );
  }

  Future<void> _saveRecord() async {
    try {
      await _healthService.addCheckupRecord(petId: widget.petId, checkupDate: _selectedDate, notes: _memoController.text.isNotEmpty ? _memoController.text : null);
      if (mounted) {
        Navigator.pop(context);
        MingrrSnackBar.success(context, '검진 기록이 저장되었습니다');
      }
    } catch (e) {
      if (mounted) ErrorHandler.showSnackBar(context, message: '저장에 실패했습니다');
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
  MedicationIconType _selectedIconType = MedicationIconType.blue;

  @override
  void dispose() {
    _nameController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildRecordBottomSheet(
      context: context,
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
              hintStyle: AppTextStyles.secondary(context).copyWith(color: Theme.of(context).colorScheme.outlineVariant),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusS),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusS),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusS),
                borderSide: BorderSide(color: context.features.health, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.gapL),
          _buildLabel('아이콘 색상'),
          const SizedBox(height: AppSizes.gapS),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: MedicationIconType.values.map((iconType) {
              final isSelected = _selectedIconType == iconType;
              final color = Color(iconType.colorValue);
              return GestureDetector(
                onTap: () => setState(() => _selectedIconType = iconType),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSelected ? color.withValues(alpha: 0.15) : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppSizes.radiusS),
                    border: Border.all(
                      color: isSelected ? color : Theme.of(context).colorScheme.outline,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Icon(
                    Icons.medication,
                    size: 26,
                    color: color,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSizes.gapL),
          _buildLabel('날짜 *'),
          _buildDateSelector(context, _selectedDate, (d) => setState(() => _selectedDate = d)),
          const SizedBox(height: AppSizes.gapL),
          _buildLabel('메모'),
          _buildMemoField(context, _memoController),
        ],
      ),
    );
  }

  Future<void> _saveRecord() async {
    if (_nameController.text.isEmpty) {
      MingrrSnackBar.warning(context, '약 이름을 입력해주세요');
      return;
    }
    try {
      // 아이콘 ID와 약 이름을 함께 저장 (형식: "icon_id|약이름")
      final medicationName = '${_selectedIconType.id}|${_nameController.text}';
      await _healthService.addMedicationRecord(
        petId: widget.petId,
        medicationName: medicationName,
        startDate: _selectedDate,
        notes: _memoController.text.isNotEmpty ? _memoController.text : null,
      );
      if (mounted) {
        Navigator.pop(context);
        MingrrSnackBar.success(context, '약 기록이 저장되었습니다');
      }
    } catch (e) {
      if (mounted) ErrorHandler.showSnackBar(context, message: '저장에 실패했습니다');
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
    return _buildRecordBottomSheet(
      context: context,
      title: '특이사항 기록',
      onSave: _saveRecord,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('날짜 *'),
          _buildDateSelector(context, _selectedDate, (d) => setState(() => _selectedDate = d)),
          const SizedBox(height: AppSizes.gapL),
          _buildLabel('메모 *'),
          _buildMemoField(context, _memoController, hint: '증상, 행동, 식이 변화 등 특이사항을 기록하세요', maxLines: 5),
        ],
      ),
    );
  }

  Future<void> _saveRecord() async {
    if (_memoController.text.isEmpty) {
      MingrrSnackBar.warning(context, '메모를 입력해주세요');
      return;
    }
    try {
      await _healthService.addSpecialNote(petId: widget.petId, recordDate: _selectedDate, title: '특이사항', content: _memoController.text, category: '기타');
      if (mounted) {
        Navigator.pop(context);
        MingrrSnackBar.success(context, '특이사항 기록이 저장되었습니다');
      }
    } catch (e) {
      if (mounted) ErrorHandler.showSnackBar(context, message: '저장에 실패했습니다');
    }
  }
}
