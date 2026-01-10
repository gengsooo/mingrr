import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/dialogs/dialogs.dart';

/// ============================================================
/// 건강수첩 상세 화면 모음
/// 체중, 그루밍, 예방접종, 검진, 치아관리, 특이사항 상세 화면
/// ============================================================

// ===== 체중 기록 상세 화면 =====
class WeightRecordDetailScreen extends StatelessWidget {
  final WeightRecord record;

  const WeightRecordDetailScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('체중 기록'),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _showEditDialog(context),
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
            // 메인 카드
            MingrrCard(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  // 체중 표시
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.health.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${record.weight}',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color: AppColors.health,
                          ),
                        ),
                        const Text(
                          'kg',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.health,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // 변화량
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        record.change > 0
                            ? Icons.arrow_upward
                            : record.change < 0
                                ? Icons.arrow_downward
                                : Icons.remove,
                        color: record.change > 0
                            ? AppColors.error
                            : record.change < 0
                                ? AppColors.success
                                : AppColors.textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${record.change > 0 ? '+' : ''}${record.change}kg',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: record.change > 0
                              ? AppColors.error
                              : record.change < 0
                                  ? AppColors.success
                                  : AppColors.textSecondary,
                        ),
                      ),
                      const Text(
                        ' (이전 대비)',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),
                  
                  // 날짜/시간
                  _buildInfoRow('측정일', _formatDate(record.date)),
                  _buildInfoRow('측정 시간', _formatTime(record.date)),
                  _buildInfoRow('반려동물', record.petName),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 목표 체중
            MingrrCard(
              margin: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '목표 체중',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${record.targetWeight}kg',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '${(record.weight - record.targetWeight).abs().toStringAsFixed(1)}kg ${record.weight > record.targetWeight ? '감량' : '증량'} 필요',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 진행률
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: Stack(
                          children: [
                            CircularProgressIndicator(
                              value: _calculateProgress(record),
                              strokeWidth: 8,
                              backgroundColor: AppColors.divider,
                              valueColor: const AlwaysStoppedAnimation(AppColors.health),
                            ),
                            Center(
                              child: Text(
                                '${(_calculateProgress(record) * 100).toInt()}%',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // 메모
            if (record.memo != null && record.memo!.isNotEmpty) ...[
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
                        Text('메모', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      record.memo!,
                      style: const TextStyle(fontSize: 14, height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
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
          Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  double _calculateProgress(WeightRecord record) {
    // 간단한 진행률 계산 (실제로는 시작 체중 기준으로 계산)
    final diff = (record.weight - record.targetWeight).abs();
    if (diff < 0.5) return 1.0;
    return (1 - diff / 5).clamp(0.0, 1.0);
  }

  String _formatDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showEditDialog(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('수정 기능은 준비 중입니다')),
    );
  }

  void _confirmDelete(BuildContext context) {
    showConfirmSheet(
      context,
      type: ConfirmSheetType.healthRecordDelete,
      message: '이 체중 기록을 삭제하시겠습니까?\n삭제된 기록은 복구할 수 없습니다.',
      onConfirm: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('기록이 삭제되었습니다')),
        );
      },
    );
  }
}

/// 체중 기록 모델
class WeightRecord {
  final String id;
  final DateTime date;
  final double weight;
  final double change;
  final double targetWeight;
  final String petName;
  final String? memo;

  const WeightRecord({
    required this.id,
    required this.date,
    required this.weight,
    required this.change,
    required this.targetWeight,
    required this.petName,
    this.memo,
  });

  factory WeightRecord.demo({int index = 0}) {
    return WeightRecord(
      id: 'weight_$index',
      date: DateTime.now().subtract(Duration(days: index)),
      weight: 5.2 - index * 0.1,
      change: index == 0 ? 0 : -0.1,
      targetWeight: 5.0,
      petName: '뽀삐',
      memo: index % 2 == 0 ? '아침 식사 전 측정' : null,
    );
  }
}

// ===== 그루밍 기록 상세 화면 =====
class GroomingRecordDetailScreen extends StatelessWidget {
  final GroomingRecord record;

  const GroomingRecordDetailScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('그루밍 기록'),
        backgroundColor: Colors.white,
        actions: [
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
            MingrrCard(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  // 그루밍 타입 아이콘
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.health.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(record.type.emoji, style: const TextStyle(fontSize: 40)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    record.type.label,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),
                  _buildInfoRow('날짜', _formatDate(record.date)),
                  _buildInfoRow('장소', record.location),
                  _buildInfoRow('반려동물', record.petName),
                  if (record.cost != null)
                    _buildInfoRow('비용', '${record.cost!.toStringAsFixed(0)}원'),
                ],
              ),
            ),
            
            if (record.memo != null && record.memo!.isNotEmpty) ...[
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
                        Text('메모', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(record.memo!, style: const TextStyle(fontSize: 14, height: 1.5)),
                  ],
                ),
              ),
            ],
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
          Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }

  void _confirmDelete(BuildContext context) {
    showConfirmSheet(
      context,
      type: ConfirmSheetType.healthRecordDelete,
      message: '이 그루밍 기록을 삭제하시겠습니까?\n삭제된 기록은 복구할 수 없습니다.',
      onConfirm: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('기록이 삭제되었습니다')),
        );
      },
    );
  }
}

/// 그루밍 타입
enum GroomingType {
  shower('샤워', '🚿'),
  brushing('빗질', '🪮'),
  nailTrim('발톱정리', '✂️'),
  haircut('이발', '💇'),
  earCleaning('귀청소', '👂'),
  tearStain('눈물자국', '👁️'),
  analGland('항문낭', '🔘'),
  pawCare('발바닥', '🐾');

  final String label;
  final String emoji;
  const GroomingType(this.label, this.emoji);
}

/// 그루밍 기록 모델
class GroomingRecord {
  final String id;
  final DateTime date;
  final GroomingType type;
  final String location;
  final String petName;
  final double? cost;
  final String? memo;

  const GroomingRecord({
    required this.id,
    required this.date,
    required this.type,
    required this.location,
    required this.petName,
    this.cost,
    this.memo,
  });

  factory GroomingRecord.demo({int index = 0}) {
    final types = GroomingType.values;
    final locations = ['집에서', '미용실', '동물병원'];
    return GroomingRecord(
      id: 'grooming_$index',
      date: DateTime.now().subtract(Duration(days: index * 2)),
      type: types[index % types.length],
      location: locations[index % locations.length],
      petName: '뽀삐',
      cost: index % 2 == 0 ? 30000 + index * 5000 : null,
      memo: index % 3 == 0 ? '피부 상태 양호' : null,
    );
  }
}

// ===== 예방접종 기록 상세 화면 =====
class VaccinationRecordDetailScreen extends StatelessWidget {
  final VaccinationRecord record;

  const VaccinationRecordDetailScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('예방접종 기록'),
        backgroundColor: Colors.white,
        actions: [
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
            MingrrCard(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.health.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(
                      child: Text('💉', style: TextStyle(fontSize: 40)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    record.vaccineName,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: record.isCompleted
                          ? AppColors.success.withOpacity(0.1)
                          : AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      record.isCompleted ? '접종 완료' : '접종 예정',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: record.isCompleted ? AppColors.success : AppColors.warning,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),
                  _buildInfoRow('접종일', _formatDate(record.date)),
                  _buildInfoRow('병원', record.hospital),
                  _buildInfoRow('담당 수의사', record.veterinarian ?? '-'),
                  _buildInfoRow('반려동물', record.petName),
                  if (record.nextDate != null)
                    _buildInfoRow('다음 접종일', _formatDate(record.nextDate!)),
                ],
              ),
            ),
            
            // 다음 접종 알림
            if (record.nextDate != null) ...[
              const SizedBox(height: 16),
              MingrrCard(
                margin: EdgeInsets.zero,
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(Icons.notifications_outlined, color: AppColors.warning),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '다음 접종 알림',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            _getRemainingDays(record.nextDate!),
                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: true,
                      onChanged: (value) {},
                      activeColor: AppColors.health,
                    ),
                  ],
                ),
              ),
            ],
            
            if (record.memo != null && record.memo!.isNotEmpty) ...[
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
                        Text('메모', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(record.memo!, style: const TextStyle(fontSize: 14, height: 1.5)),
                  ],
                ),
              ),
            ],
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
          Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }

  String _getRemainingDays(DateTime date) {
    final remaining = date.difference(DateTime.now()).inDays;
    if (remaining < 0) return '${-remaining}일 지남';
    if (remaining == 0) return '오늘';
    return '$remaining일 후';
  }

  void _confirmDelete(BuildContext context) {
    showConfirmSheet(
      context,
      type: ConfirmSheetType.healthRecordDelete,
      message: '이 예방접종 기록을 삭제하시겠습니까?\n삭제된 기록은 복구할 수 없습니다.',
      onConfirm: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('기록이 삭제되었습니다')),
        );
      },
    );
  }
}

/// 예방접종 기록 모델
class VaccinationRecord {
  final String id;
  final DateTime date;
  final String vaccineName;
  final String hospital;
  final String? veterinarian;
  final String petName;
  final DateTime? nextDate;
  final bool isCompleted;
  final String? memo;

  const VaccinationRecord({
    required this.id,
    required this.date,
    required this.vaccineName,
    required this.hospital,
    this.veterinarian,
    required this.petName,
    this.nextDate,
    this.isCompleted = true,
    this.memo,
  });

  factory VaccinationRecord.demo({int index = 0}) {
    final vaccines = ['종합백신 (DHPPL)', '광견병', '코로나', '켄넬코프', '인플루엔자'];
    return VaccinationRecord(
      id: 'vaccine_$index',
      date: DateTime.now().subtract(Duration(days: index * 30)),
      vaccineName: vaccines[index % vaccines.length],
      hospital: '행복 동물병원',
      veterinarian: '김수의 원장',
      petName: '뽀삐',
      nextDate: index < 3 ? DateTime.now().add(Duration(days: 365 - index * 30)) : null,
      isCompleted: true,
      memo: index % 2 == 0 ? '접종 후 이상 반응 없음' : null,
    );
  }
}

// ===== 검진 기록 상세 화면 =====
class CheckupRecordDetailScreen extends StatelessWidget {
  final CheckupRecord record;

  const CheckupRecordDetailScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('검진 기록'),
        backgroundColor: Colors.white,
        actions: [
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
            MingrrCard(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.health.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(
                      child: Text('🏥', style: TextStyle(fontSize: 40)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    record.checkupType,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),
                  _buildInfoRow('검진일', _formatDate(record.date)),
                  _buildInfoRow('병원', record.hospital),
                  _buildInfoRow('담당 수의사', record.veterinarian ?? '-'),
                  _buildInfoRow('반려동물', record.petName),
                  if (record.cost != null)
                    _buildInfoRow('비용', '${record.cost!.toStringAsFixed(0)}원'),
                ],
              ),
            ),
            
            // 검진 결과
            const SizedBox(height: 16),
            MingrrCard(
              margin: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '검진 결과',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _getResultColor(record.result).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getResultIcon(record.result),
                          color: _getResultColor(record.result),
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          record.result,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _getResultColor(record.result),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // 검진 항목
            if (record.items.isNotEmpty) ...[
              const SizedBox(height: 16),
              MingrrCard(
                margin: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '검진 항목',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    ...record.items.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: AppColors.success, size: 18),
                          const SizedBox(width: 8),
                          Text(item, style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ],
            
            if (record.memo != null && record.memo!.isNotEmpty) ...[
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
                        Text('메모', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(record.memo!, style: const TextStyle(fontSize: 14, height: 1.5)),
                  ],
                ),
              ),
            ],
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
          Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }

  Color _getResultColor(String result) {
    if (result.contains('정상') || result.contains('양호')) return AppColors.success;
    if (result.contains('주의') || result.contains('관찰')) return AppColors.warning;
    return AppColors.error;
  }

  IconData _getResultIcon(String result) {
    if (result.contains('정상') || result.contains('양호')) return Icons.check_circle;
    if (result.contains('주의') || result.contains('관찰')) return Icons.warning;
    return Icons.error;
  }

  void _confirmDelete(BuildContext context) {
    showConfirmSheet(
      context,
      type: ConfirmSheetType.healthRecordDelete,
      message: '이 검진 기록을 삭제하시겠습니까?\n삭제된 기록은 복구할 수 없습니다.',
      onConfirm: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('기록이 삭제되었습니다')),
        );
      },
    );
  }
}

/// 검진 기록 모델
class CheckupRecord {
  final String id;
  final DateTime date;
  final String checkupType;
  final String hospital;
  final String? veterinarian;
  final String petName;
  final String result;
  final List<String> items;
  final double? cost;
  final String? memo;

  const CheckupRecord({
    required this.id,
    required this.date,
    required this.checkupType,
    required this.hospital,
    this.veterinarian,
    required this.petName,
    required this.result,
    this.items = const [],
    this.cost,
    this.memo,
  });

  factory CheckupRecord.demo({int index = 0}) {
    final types = ['정기 검진', '혈액 검사', '초음파 검사', 'X-ray 검사', '심장 검사'];
    final results = ['정상', '양호 (관찰 필요)', '주의 필요'];
    return CheckupRecord(
      id: 'checkup_$index',
      date: DateTime.now().subtract(Duration(days: index * 60)),
      checkupType: types[index % types.length],
      hospital: '행복 동물병원',
      veterinarian: '김수의 원장',
      petName: '뽀삐',
      result: results[index % results.length],
      items: ['체중 측정', '심박수 체크', '치아 검사', '피부 검사'],
      cost: 50000 + index * 10000,
      memo: index % 2 == 0 ? '전반적으로 건강 상태 양호' : null,
    );
  }
}

// ===== 치아 관리 기록 상세 화면 =====
class TeethCareRecordDetailScreen extends StatelessWidget {
  final TeethCareRecord record;

  const TeethCareRecordDetailScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('치아 관리 기록'),
        backgroundColor: Colors.white,
        actions: [
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
            MingrrCard(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.health.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(
                      child: Text('🦷', style: TextStyle(fontSize: 40)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    record.careType,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),
                  _buildInfoRow('날짜', _formatDate(record.date)),
                  _buildInfoRow('장소', record.location),
                  _buildInfoRow('반려동물', record.petName),
                  if (record.cost != null)
                    _buildInfoRow('비용', '${record.cost!.toStringAsFixed(0)}원'),
                ],
              ),
            ),
            
            // 치아 상태
            const SizedBox(height: 16),
            MingrrCard(
              margin: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '치아 상태',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  _buildConditionBar('치석', record.tartarLevel),
                  const SizedBox(height: 8),
                  _buildConditionBar('잇몸', record.gumHealth),
                  const SizedBox(height: 8),
                  _buildConditionBar('구취', record.breathLevel),
                ],
              ),
            ),
            
            if (record.memo != null && record.memo!.isNotEmpty) ...[
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
                        Text('메모', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(record.memo!, style: const TextStyle(fontSize: 14, height: 1.5)),
                  ],
                ),
              ),
            ],
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
          Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildConditionBar(String label, int level) {
    final colors = [AppColors.success, AppColors.success, AppColors.warning, AppColors.warning, AppColors.error];
    final labels = ['매우 좋음', '좋음', '보통', '주의', '나쁨'];
    
    return Row(
      children: [
        SizedBox(
          width: 50,
          child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        ),
        Expanded(
          child: Row(
            children: List.generate(5, (index) {
              return Expanded(
                child: Container(
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: index < level ? colors[level - 1] : AppColors.divider,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          labels[level - 1],
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: colors[level - 1],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }

  void _confirmDelete(BuildContext context) {
    showConfirmSheet(
      context,
      type: ConfirmSheetType.healthRecordDelete,
      message: '이 치아 관리 기록을 삭제하시겠습니까?\n삭제된 기록은 복구할 수 없습니다.',
      onConfirm: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('기록이 삭제되었습니다')),
        );
      },
    );
  }
}

/// 치아 관리 기록 모델
class TeethCareRecord {
  final String id;
  final DateTime date;
  final String careType;
  final String location;
  final String petName;
  final int tartarLevel; // 1-5
  final int gumHealth; // 1-5
  final int breathLevel; // 1-5
  final double? cost;
  final String? memo;

  const TeethCareRecord({
    required this.id,
    required this.date,
    required this.careType,
    required this.location,
    required this.petName,
    required this.tartarLevel,
    required this.gumHealth,
    required this.breathLevel,
    this.cost,
    this.memo,
  });

  factory TeethCareRecord.demo({int index = 0}) {
    final types = ['양치질', '스케일링', '치과 검진', '치석 제거'];
    final locations = ['집에서', '동물병원'];
    return TeethCareRecord(
      id: 'teeth_$index',
      date: DateTime.now().subtract(Duration(days: index * 7)),
      careType: types[index % types.length],
      location: locations[index % locations.length],
      petName: '뽀삐',
      tartarLevel: 1 + index % 3,
      gumHealth: 1 + index % 2,
      breathLevel: 1 + index % 3,
      cost: index % 2 == 0 ? 50000 : null,
      memo: index % 2 == 0 ? '정기적인 양치질 권장' : null,
    );
  }
}

// ===== 특이사항 기록 상세 화면 =====
class SpecialRecordDetailScreen extends StatelessWidget {
  final SpecialRecord record;

  const SpecialRecordDetailScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('특이사항 기록'),
        backgroundColor: Colors.white,
        actions: [
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
            MingrrCard(
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
                          color: _getCategoryColor(record.category).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            _getCategoryEmoji(record.category),
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              record.title,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getCategoryColor(record.category).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                record.category,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: _getCategoryColor(record.category),
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
                  _buildInfoRow('날짜', _formatDate(record.date)),
                  _buildInfoRow('반려동물', record.petName),
                  if (record.severity != null)
                    _buildInfoRow('심각도', record.severity!),
                ],
              ),
            ),
            
            // 상세 내용
            const SizedBox(height: 16),
            MingrrCard(
              margin: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '상세 내용',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    record.description,
                    style: const TextStyle(fontSize: 14, height: 1.6),
                  ),
                ],
              ),
            ),
            
            // 조치 사항
            if (record.action != null && record.action!.isNotEmpty) ...[
              const SizedBox(height: 16),
              MingrrCard(
                margin: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.medical_services_outlined, size: 20, color: AppColors.health),
                        SizedBox(width: 8),
                        Text('조치 사항', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      record.action!,
                      style: const TextStyle(fontSize: 14, height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
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
          Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case '증상': return AppColors.error;
      case '행동': return AppColors.warning;
      case '식이': return AppColors.success;
      case '기타': return AppColors.textSecondary;
      default: return AppColors.health;
    }
  }

  String _getCategoryEmoji(String category) {
    switch (category) {
      case '증상': return '🤒';
      case '행동': return '🐕';
      case '식이': return '🍖';
      case '기타': return '📝';
      default: return '⭐';
    }
  }

  void _confirmDelete(BuildContext context) {
    showConfirmSheet(
      context,
      type: ConfirmSheetType.healthRecordDelete,
      message: '이 특이사항 기록을 삭제하시겠습니까?\n삭제된 기록은 복구할 수 없습니다.',
      onConfirm: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('기록이 삭제되었습니다')),
        );
      },
    );
  }
}

/// 특이사항 기록 모델
class SpecialRecord {
  final String id;
  final DateTime date;
  final String title;
  final String category;
  final String description;
  final String petName;
  final String? severity;
  final String? action;

  const SpecialRecord({
    required this.id,
    required this.date,
    required this.title,
    required this.category,
    required this.description,
    required this.petName,
    this.severity,
    this.action,
  });

  factory SpecialRecord.demo({int index = 0}) {
    final titles = ['구토 증상', '식욕 감소', '과도한 짖음', '발 핥기', '설사'];
    final categories = ['증상', '식이', '행동', '행동', '증상'];
    final severities = ['경미', '보통', '심각'];
    return SpecialRecord(
      id: 'special_$index',
      date: DateTime.now().subtract(Duration(days: index * 5)),
      title: titles[index % titles.length],
      category: categories[index % categories.length],
      description: '오늘 아침 ${titles[index % titles.length]}이(가) 관찰되었습니다. 평소와 다른 행동이 보여 기록합니다.',
      petName: '뽀삐',
      severity: severities[index % severities.length],
      action: index % 2 == 0 ? '동물병원 방문 예정' : null,
    );
  }
}
