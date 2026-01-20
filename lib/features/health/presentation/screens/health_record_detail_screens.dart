import 'package:flutter/material.dart';
import '../../../../core/theme/feature_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_sizes.dart';
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
      backgroundColor: context.detailBackground,
      appBar: AppBar(
        title: const Text('체중 기록'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _showEditDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
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
                      color: context.features.health.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${record.weight}',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color: context.features.health,
                          ),
                        ),
                        Text(
                          'kg',
                          style: TextStyle(
                            fontSize: 16,
                            color: context.features.health,
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
                            ? Colors.red
                            : record.change < 0
                                ? context.features.success
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${record.change > 0 ? '+' : ''}${record.change}kg',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: record.change > 0
                              ? Colors.red
                              : record.change < 0
                                  ? context.features.success
                                  : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        ' (이전 대비)',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),
                  
                  // 날짜/시간
                  _buildInfoRow(context, '측정일', _formatDate(record.date)),
                  _buildInfoRow(context, '측정 시간', _formatTime(record.date)),
                  _buildInfoRow(context, '반려동물', record.petName),
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
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                            MingrrLoadingIndicator.progress(
                              value: _calculateProgress(record),
                              size: 80,
                              strokeWidth: 8,
                              backgroundColor: Theme.of(context).colorScheme.outline,
                              customColor: context.features.health,
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
                    Row(
                      children: [
                        Icon(Icons.note_outlined, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        const SizedBox(width: 8),
                        const Text('메모', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant)),
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
    MingrrSnackBar.info(context, '수정 기능은 준비 중입니다');
  }

  void _confirmDelete(BuildContext context) {
    showConfirmSheet(
      context,
      type: ConfirmSheetType.healthRecordDelete,
      message: '이 체중 기록을 삭제하시겠습니까?\n삭제된 기록은 복구할 수 없습니다.',
      onConfirm: () {
        Navigator.pop(context);
        MingrrSnackBar.success(context, '기록이 삭제되었습니다');
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
}

// ===== 그루밍 기록 상세 화면 =====
class GroomingRecordDetailScreen extends StatelessWidget {
  final GroomingRecord record;

  const GroomingRecordDetailScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.detailBackground,
      appBar: AppBar(
        title: const Text('그루밍 기록'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
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
                      color: context.features.health.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(record.type.icon, size: 40, color: context.features.health),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    record.type.label,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),
                  _buildInfoRow(context, '날짜', _formatDate(record.date)),
                  _buildInfoRow(context, '장소', record.location),
                  _buildInfoRow(context, '반려동물', record.petName),
                  if (record.cost != null)
                    _buildInfoRow(context, '비용', '${record.cost!.toStringAsFixed(0)}원'),
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
                    Row(
                      children: [
                        Icon(Icons.note_outlined, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        const SizedBox(width: 8),
                        const Text('메모', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant)),
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
        MingrrSnackBar.success(context, '기록이 삭제되었습니다');
      },
    );
  }
}

/// 그루밍 타입
enum _LocalGroomingType {
  shower('샤워', Icons.shower_outlined),
  brushing('빗질', Icons.brush_outlined),
  nailTrim('발톱정리', Icons.content_cut),
  haircut('이발', Icons.cut_outlined),
  earCleaning('귀청소', Icons.hearing_outlined),
  tearStain('눈물자국', Icons.visibility_outlined),
  analGland('항문낭', Icons.circle_outlined),
  pawCare('발바닥', Icons.pets);

  final String label;
  final IconData icon;
  const _LocalGroomingType(this.label, this.icon);
}

/// 그루밍 기록 모델
class GroomingRecord {
  final String id;
  final DateTime date;
  final _LocalGroomingType type;
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
}

// ===== 예방접종 기록 상세 화면 =====
class VaccinationRecordDetailScreen extends StatelessWidget {
  final VaccinationRecord record;

  const VaccinationRecordDetailScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.detailBackground,
      appBar: AppBar(
        title: const Text('예방접종 기록'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
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
                      color: context.features.health.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(Icons.vaccines_outlined, size: 40, color: context.features.health),
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
                          ? context.features.success.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSizes.radiusS),
                    ),
                    child: Text(
                      record.isCompleted ? '접종 완료' : '접종 예정',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: record.isCompleted ? context.features.success : Colors.orange,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),
                  _buildInfoRow(context, '접종일', _formatDate(record.date)),
                  _buildInfoRow(context, '병원', record.hospital),
                  _buildInfoRow(context, '담당 수의사', record.veterinarian ?? '-'),
                  _buildInfoRow(context, '반려동물', record.petName),
                  if (record.nextDate != null)
                    _buildInfoRow(context, '다음 접종일', _formatDate(record.nextDate!)),
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
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppSizes.radiusS),
                      ),
                      child: const Center(
                        child: Icon(Icons.notifications_outlined, color: Colors.orange),
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
                            style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: true,
                      onChanged: (value) {},
                      activeColor: Colors.white,
                      activeTrackColor: context.features.health,
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: Theme.of(context).colorScheme.outlineVariant,
                      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
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
                    Row(
                      children: [
                        Icon(Icons.note_outlined, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        const SizedBox(width: 8),
                        const Text('메모', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant)),
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
        MingrrSnackBar.success(context, '기록이 삭제되었습니다');
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
}

// ===== 검진 기록 상세 화면 =====
class CheckupRecordDetailScreen extends StatelessWidget {
  final CheckupRecord record;

  const CheckupRecordDetailScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.detailBackground,
      appBar: AppBar(
        title: const Text('검진 기록'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
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
                      color: context.features.health.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(Icons.local_hospital_outlined, size: 40, color: context.features.health),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    record.checkupType,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),
                  _buildInfoRow(context, '검진일', _formatDate(record.date)),
                  _buildInfoRow(context, '병원', record.hospital),
                  _buildInfoRow(context, '담당 수의사', record.veterinarian ?? '-'),
                  _buildInfoRow(context, '반려동물', record.petName),
                  if (record.cost != null)
                    _buildInfoRow(context, '비용', '${record.cost!.toStringAsFixed(0)}원'),
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
                      color: _getResultColor(context, record.result).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSizes.radiusS),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getResultIcon(record.result),
                          color: _getResultColor(context, record.result),
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          record.result,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _getResultColor(context, record.result),
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
                          Icon(Icons.check_circle, color: context.features.success, size: 18),
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
                    Row(
                      children: [
                        Icon(Icons.note_outlined, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        const SizedBox(width: 8),
                        const Text('메모', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }

  Color _getResultColor(BuildContext context, String result) {
    if (result.contains('정상') || result.contains('양호')) return context.features.success;
    if (result.contains('주의') || result.contains('관찰')) return Colors.orange;
    return Colors.red;
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
        MingrrSnackBar.success(context, '기록이 삭제되었습니다');
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
}

// ===== 치아 관리 기록 상세 화면 =====
class TeethCareRecordDetailScreen extends StatelessWidget {
  final TeethCareRecord record;

  const TeethCareRecordDetailScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.detailBackground,
      appBar: AppBar(
        title: const Text('치아 관리 기록'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
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
                      color: context.features.health.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(Icons.clean_hands_outlined, size: 40, color: context.features.health),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    record.careType,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),
                  _buildInfoRow(context, '날짜', _formatDate(record.date)),
                  _buildInfoRow(context, '장소', record.location),
                  _buildInfoRow(context, '반려동물', record.petName),
                  if (record.cost != null)
                    _buildInfoRow(context, '비용', '${record.cost!.toStringAsFixed(0)}원'),
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
                  _buildConditionBar(context, '치석', record.tartarLevel),
                  const SizedBox(height: 8),
                  _buildConditionBar(context, '잇몸', record.gumHealth),
                  const SizedBox(height: 8),
                  _buildConditionBar(context, '구취', record.breathLevel),
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
                    Row(
                      children: [
                        Icon(Icons.note_outlined, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        const SizedBox(width: 8),
                        const Text('메모', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildConditionBar(BuildContext context, String label, int level) {
    final colors = [context.features.success, context.features.success, Colors.orange, Colors.orange, Colors.red];
    final labels = ['매우 좋음', '좋음', '보통', '주의', '나쁨'];
    
    return Row(
      children: [
        SizedBox(
          width: 50,
          child: Text(label, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ),
        Expanded(
          child: Row(
            children: List.generate(5, (index) {
              return Expanded(
                child: Container(
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: index < level ? colors[level - 1] : Theme.of(context).colorScheme.outline,
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
        MingrrSnackBar.success(context, '기록이 삭제되었습니다');
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
}

// ===== 특이사항 기록 상세 화면 =====
class SpecialRecordDetailScreen extends StatelessWidget {
  final SpecialRecord record;

  const SpecialRecordDetailScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.detailBackground,
      appBar: AppBar(
        title: const Text('특이사항 기록'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
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
                          color: _getCategoryColor(context, record.category).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppSizes.radiusS),
                        ),
                        child: Icon(
                          _getCategoryIcon(record.category),
                          size: 24,
                          color: _getCategoryColor(context, record.category),
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
                                color: _getCategoryColor(context, record.category).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                record.category,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: _getCategoryColor(context, record.category),
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
                  _buildInfoRow(context, '날짜', _formatDate(record.date)),
                  _buildInfoRow(context, '반려동물', record.petName),
                  if (record.severity != null)
                    _buildInfoRow(context, '심각도', record.severity!),
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
                    Row(
                      children: [
                        Icon(Icons.medical_services_outlined, size: 20, color: context.features.health),
                        const SizedBox(width: 8),
                        const Text('조치 사항', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }

  Color _getCategoryColor(BuildContext context, String category) {
    switch (category) {
      case '증상': return Colors.red;
      case '행동': return Colors.orange;
      case '식이': return context.features.success;
      case '기타': return Theme.of(context).colorScheme.onSurfaceVariant;
      default: return context.features.health;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case '증상': return Icons.sick_outlined;
      case '행동': return Icons.pets;
      case '식이': return Icons.restaurant_outlined;
      case '기타': return Icons.note_alt_outlined;
      default: return Icons.star_outline;
    }
  }

  void _confirmDelete(BuildContext context) {
    showConfirmSheet(
      context,
      type: ConfirmSheetType.healthRecordDelete,
      message: '이 특이사항 기록을 삭제하시겠습니까?\n삭제된 기록은 복구할 수 없습니다.',
      onConfirm: () {
        Navigator.pop(context);
        MingrrSnackBar.success(context, '기록이 삭제되었습니다');
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
}
