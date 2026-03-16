import 'package:flutter/material.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/theme/feature_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/dialogs/dialogs.dart';
import '../../../../core/utils/format_utils.dart';

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
      appBar: MingrrAppBar(
        title: '체중 기록',
        actions: [
          IconButton(
            icon: const Icon(AppIcons.editOutlined),
            onPressed: () => _showEditDialog(context),
          ),
          IconButton(
            icon: Icon(AppIcons.deleteOutlined, color: Theme.of(context).colorScheme.error),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingL),
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
                      color: context.features.health.withValues(alpha: AppOpacity.o10),
                      shape: BoxShape.circle,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${record.weight}',
                          style: AppTextStyles.displayLarge(context).withColor(context.features.health),
                        ),
                        Text(
                          'kg',
                          style: AppTextStyles.titleLarge(context).copyWith(
                            color: context.features.health,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.gapL),
                  
                  // 변화량
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        record.change > 0
                            ? AppIcons.arrowUp
                            : record.change < 0
                                ? AppIcons.arrowDown
                                : AppIcons.more,
                        color: record.change > 0
                            ? Theme.of(context).colorScheme.error
                            : record.change < 0
                                ? context.features.success
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      const SizedBox(width: AppSizes.gapXS),
                      Text(
                        '${record.change > 0 ? '+' : ''}${record.change}kg',
                        style: AppTextStyles.headlineSmall(context).withWeight(FontWeight.w600).withColor(
                          record.change > 0
                              ? Theme.of(context).colorScheme.error
                              : record.change < 0
                                  ? context.features.success
                                  : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        ' (이전 대비)',
                        style: AppTextStyles.bodyMedium(context).copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: AppSizes.gapL),
                  const MingrrDivider(),
                  const SizedBox(height: AppSizes.gapM),
                  
                  // 날짜/시간
                  _buildInfoRow(context, '측정일', formatDateKorean(record.date)),
                  _buildInfoRow(context, '측정 시간', formatTime(record.date)),
                  _buildInfoRow(context, '반려동물', record.petName),
                ],
              ),
            ),
            
            const SizedBox(height: AppSizes.gapL),
            
            // 목표 체중
            MingrrCard(
              margin: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '목표 체중',
                    style: AppTextStyles.headlineSmall(context),
                  ),
                  const SizedBox(height: AppSizes.gapM),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${record.targetWeight}kg',
                              style: AppTextStyles.displaySmall(context),
                            ),
                            Text(
                              '${(record.weight - record.targetWeight).abs().toStringAsFixed(1)}kg ${record.weight > record.targetWeight ? '감량' : '증량'} 필요',
                              style: AppTextStyles.bodySmall(context),
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
                                style: AppTextStyles.titleLarge(context),
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
              const SizedBox(height: AppSizes.gapL),
              MingrrCard(
                margin: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(AppIcons.note, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        const SizedBox(width: AppSizes.gapS),
                        Text('메모', style: AppTextStyles.headlineSmall(context)),
                      ],
                    ),
                    const SizedBox(height: AppSizes.gapM),
                    Text(
                      record.memo!,
                      style: AppTextStyles.bodyMedium(context).copyWith(height: 1.5),
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
      padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingXS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySmall(context)),
          Text(value, style: AppTextStyles.labelLarge(context)),
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

// ===== 예방접종 기록 상세 화면 =====
class VaccinationRecordDetailScreen extends StatelessWidget {
  final VaccinationRecord record;

  const VaccinationRecordDetailScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.detailBackground,
      appBar: MingrrAppBar(
        title: '예방접종 기록',
        actions: [
          IconButton(
            icon: Icon(AppIcons.deleteOutlined, color: Theme.of(context).colorScheme.error),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingL),
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
                      color: context.features.health.withValues(alpha: AppOpacity.o10),
                      borderRadius: BorderRadius.circular(AppSizes.radiusL),
                    ),
                    child: Icon(AppIcons.vaccination, size: 40, color: context.features.health),
                  ),
                  const SizedBox(height: AppSizes.gapL),
                  Text(
                    record.vaccineName,
                    style: AppTextStyles.headlineMedium(context).copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: AppSizes.gapS),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM, vertical: 4),
                    decoration: BoxDecoration(
                      color: record.isCompleted
                          ? context.features.success.withValues(alpha: AppOpacity.o10)
                          : Colors.orange.withValues(alpha: AppOpacity.o10),
                      borderRadius: BorderRadius.circular(AppSizes.radiusS),
                    ),
                    child: Text(
                      record.isCompleted ? '접종 완료' : '접종 예정',
                      style: AppTextStyles.labelLarge(context).withWeight(FontWeight.w600).withColor(
                        record.isCompleted ? context.features.success : Colors.orange,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.gapL),
                  const MingrrDivider(),
                  const SizedBox(height: AppSizes.gapM),
                  _buildInfoRow(context, '접종일', formatDateKorean(record.date)),
                  _buildInfoRow(context, '병원', record.hospital),
                  _buildInfoRow(context, '담당 수의사', record.veterinarian ?? '-'),
                  _buildInfoRow(context, '반려동물', record.petName),
                  if (record.nextDate != null)
                    _buildInfoRow(context, '다음 접종일', formatDateKorean(record.nextDate!)),
                ],
              ),
            ),
            
            // 다음 접종 알림
            if (record.nextDate != null) ...[
              const SizedBox(height: AppSizes.gapL),
              MingrrCard(
                margin: EdgeInsets.zero,
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: AppOpacity.o10),
                        borderRadius: BorderRadius.circular(AppSizes.radiusS),
                      ),
                      child: const Center(
                        child: Icon(AppIcons.notification, color: Colors.orange),
                      ),
                    ),
                    const SizedBox(width: AppSizes.gapM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '다음 접종 알림',
                            style: AppTextStyles.labelLarge(context).copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            _getRemainingDays(record.nextDate!),
                            style: AppTextStyles.bodySmall(context),
                          ),
                        ],
                      ),
                    ),
                    Tooltip(
                      message: '알림 기능은 추후 업데이트 예정입니다',
                      child: Switch(
                        value: false,
                        onChanged: null,
                        // 다크모드에서 OFF 상태 thumb이 track과 구분되도록 설정
                        inactiveThumbColor: Theme.of(context).colorScheme.outline,
                        inactiveTrackColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                        trackOutlineColor: WidgetStateProperty.all(Theme.of(context).colorScheme.outline),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            if (record.memo != null && record.memo!.isNotEmpty) ...[
              const SizedBox(height: AppSizes.gapL),
              MingrrCard(
                margin: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(AppIcons.note, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        const SizedBox(width: AppSizes.gapS),
                        Text('메모', style: AppTextStyles.headlineSmall(context)),
                      ],
                    ),
                    const SizedBox(height: AppSizes.gapM),
                    Text(record.memo!, style: AppTextStyles.bodyMedium(context).copyWith(height: 1.5)),
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
      padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingXS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySmall(context)),
          Text(value, style: AppTextStyles.labelLarge(context)),
        ],
      ),
    );
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
      appBar: MingrrAppBar(
        title: '검진 기록',
        actions: [
          IconButton(
            icon: Icon(AppIcons.deleteOutlined, color: Theme.of(context).colorScheme.error),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingL),
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
                      color: context.features.health.withValues(alpha: AppOpacity.o10),
                      borderRadius: BorderRadius.circular(AppSizes.radiusL),
                    ),
                    child: Icon(AppIcons.checkup, size: 40, color: context.features.health),
                  ),
                  const SizedBox(height: AppSizes.gapL),
                  Text(
                    record.checkupType,
                    style: AppTextStyles.headlineMedium(context).copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: AppSizes.gapL),
                  const MingrrDivider(),
                  const SizedBox(height: AppSizes.gapM),
                  _buildInfoRow(context, '검진일', formatDateKorean(record.date)),
                  _buildInfoRow(context, '병원', record.hospital),
                  _buildInfoRow(context, '담당 수의사', record.veterinarian ?? '-'),
                  _buildInfoRow(context, '반려동물', record.petName),
                  if (record.cost != null)
                    _buildInfoRow(context, '비용', '${record.cost!.toStringAsFixed(0)}원'),
                ],
              ),
            ),
            
            // 검진 결과
            const SizedBox(height: AppSizes.gapL),
            MingrrCard(
              margin: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '검진 결과',
                    style: AppTextStyles.headlineSmall(context),
                  ),
                  const SizedBox(height: AppSizes.gapM),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSizes.paddingL),
                    decoration: BoxDecoration(
                      color: _getResultColor(context, record.result).withValues(alpha: AppOpacity.o10),
                      borderRadius: BorderRadius.circular(AppSizes.radiusS),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getResultIcon(record.result),
                          color: _getResultColor(context, record.result),
                          size: 28,
                        ),
                        const SizedBox(width: AppSizes.gapM),
                        Text(
                          record.result,
                          style: AppTextStyles.headlineSmall(context).withWeight(FontWeight.w600).withColor(_getResultColor(context, record.result)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // 검진 항목
            if (record.items.isNotEmpty) ...[
              const SizedBox(height: AppSizes.gapL),
              MingrrCard(
                margin: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '검진 항목',
                      style: AppTextStyles.headlineSmall(context),
                    ),
                    const SizedBox(height: AppSizes.gapM),
                    ...record.items.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingXS),
                      child: Row(
                        children: [
                          Icon(AppIcons.success, color: context.features.success, size: 18),
                          const SizedBox(width: AppSizes.gapS),
                          Text(item, style: AppTextStyles.bodyMedium(context)),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ],
            
            if (record.memo != null && record.memo!.isNotEmpty) ...[
              const SizedBox(height: AppSizes.gapL),
              MingrrCard(
                margin: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(AppIcons.note, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        const SizedBox(width: AppSizes.gapS),
                        Text('메모', style: AppTextStyles.headlineSmall(context)),
                      ],
                    ),
                    const SizedBox(height: AppSizes.gapM),
                    Text(record.memo!, style: AppTextStyles.bodyMedium(context).copyWith(height: 1.5)),
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
      padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingXS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySmall(context)),
          Text(value, style: AppTextStyles.labelLarge(context)),
        ],
      ),
    );
  }

  Color _getResultColor(BuildContext context, String result) {
    if (result.contains('정상') || result.contains('양호')) return context.features.success;
    if (result.contains('주의') || result.contains('관찰')) return Theme.of(context).colorScheme.tertiary;
    return Theme.of(context).colorScheme.error;
  }

  IconData _getResultIcon(String result) {
    if (result.contains('정상') || result.contains('양호')) return AppIcons.checkCircle;
    if (result.contains('주의') || result.contains('관찰')) return AppIcons.warning;
    return AppIcons.error;
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
      appBar: MingrrAppBar(
        title: '치아 관리 기록',
        actions: [
          IconButton(
            icon: Icon(AppIcons.deleteOutlined, color: Theme.of(context).colorScheme.error),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingL),
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
                      color: context.features.health.withValues(alpha: AppOpacity.o10),
                      borderRadius: BorderRadius.circular(AppSizes.radiusL),
                    ),
                    child: Icon(AppIcons.teethBrushing, size: 40, color: context.features.health),
                  ),
                  const SizedBox(height: AppSizes.gapL),
                  Text(
                    record.careType,
                    style: AppTextStyles.headlineMedium(context).copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: AppSizes.gapL),
                  const MingrrDivider(),
                  const SizedBox(height: AppSizes.gapM),
                  _buildInfoRow(context, '날짜', formatDateKorean(record.date)),
                  _buildInfoRow(context, '장소', record.location),
                  _buildInfoRow(context, '반려동물', record.petName),
                  if (record.cost != null)
                    _buildInfoRow(context, '비용', '${record.cost!.toStringAsFixed(0)}원'),
                ],
              ),
            ),
            
            // 치아 상태
            const SizedBox(height: AppSizes.gapL),
            MingrrCard(
              margin: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '치아 상태',
                    style: AppTextStyles.headlineSmall(context),
                  ),
                  const SizedBox(height: AppSizes.gapM),
                  _buildConditionBar(context, '치석', record.tartarLevel),
                  const SizedBox(height: AppSizes.gapS),
                  _buildConditionBar(context, '잇몸', record.gumHealth),
                  const SizedBox(height: AppSizes.gapS),
                  _buildConditionBar(context, '구취', record.breathLevel),
                ],
              ),
            ),
            
            if (record.memo != null && record.memo!.isNotEmpty) ...[
              const SizedBox(height: AppSizes.gapL),
              MingrrCard(
                margin: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(AppIcons.description, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        const SizedBox(width: AppSizes.gapS),
                        Text('메모', style: AppTextStyles.headlineSmall(context)),
                      ],
                    ),
                    const SizedBox(height: AppSizes.gapM),
                    Text(record.memo!, style: AppTextStyles.bodyMedium(context).copyWith(height: 1.5)),
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
      padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingXS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySmall(context)),
          Text(value, style: AppTextStyles.labelLarge(context)),
        ],
      ),
    );
  }

  Widget _buildConditionBar(BuildContext context, String label, int level) {
    final colors = [context.features.success, context.features.success, Theme.of(context).colorScheme.tertiary, Theme.of(context).colorScheme.tertiary, Theme.of(context).colorScheme.error];
    final labels = ['매우 좋음', '좋음', '보통', '주의', '나쁨'];
    
    return Row(
      children: [
        SizedBox(
          width: 50,
          child: Text(label, style: AppTextStyles.bodySmall(context)),
        ),
        Expanded(
          child: Row(
            children: List.generate(5, (index) {
              return Expanded(
                child: Container(
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: AppSizes.paddingXXS),
                  decoration: BoxDecoration(
                    color: index < level ? colors[level - 1] : Theme.of(context).colorScheme.outline,
                    borderRadius: BorderRadius.circular(AppSizes.radiusS),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: AppSizes.gapS),
        Text(
          labels[level - 1],
          style: AppTextStyles.labelLarge(context).withWeight(FontWeight.w500).withColor(colors[level - 1]),
        ),
      ],
    );
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
      appBar: MingrrAppBar(
        title: '특이사항 기록',
        actions: [
          IconButton(
            icon: Icon(AppIcons.deleteOutlined, color: Theme.of(context).colorScheme.error),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingL),
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
                          color: _getCategoryColor(context, record.category).withValues(alpha: AppOpacity.o10),
                          borderRadius: BorderRadius.circular(AppSizes.radiusS),
                        ),
                        child: Icon(
                          _getCategoryIcon(record.category),
                          size: 24,
                          color: _getCategoryColor(context, record.category),
                        ),
                      ),
                      const SizedBox(width: AppSizes.gapM),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              record.title,
                              style: AppTextStyles.headlineSmall(context).copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: AppSizes.gapXS),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingS, vertical: AppSizes.paddingXXS),
                              decoration: BoxDecoration(
                                color: _getCategoryColor(context, record.category).withValues(alpha: AppOpacity.o10),
                                borderRadius: BorderRadius.circular(AppSizes.radiusS),
                              ),
                              child: Text(
                                record.category,
                                style: AppTextStyles.labelSmall(context).copyWith(
                                  color: _getCategoryColor(context, record.category),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.gapL),
                  const MingrrDivider(),
                  const SizedBox(height: AppSizes.gapM),
                  _buildInfoRow(context, '날짜', formatDateKorean(record.date)),
                  _buildInfoRow(context, '반려동물', record.petName),
                  if (record.severity != null)
                    _buildInfoRow(context, '심각도', record.severity!),
                ],
              ),
            ),
            
            // 상세 내용
            const SizedBox(height: AppSizes.gapL),
            MingrrCard(
              margin: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '상세 내용',
                    style: AppTextStyles.headlineSmall(context),
                  ),
                  const SizedBox(height: AppSizes.gapM),
                  Text(
                    record.description,
                    style: AppTextStyles.bodyMedium(context).copyWith(height: 1.6),
                  ),
                ],
              ),
            ),
            
            // 조치 사항
            if (record.action != null && record.action!.isNotEmpty) ...[
              const SizedBox(height: AppSizes.gapL),
              MingrrCard(
                margin: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(AppIcons.healthOutlined, size: 20, color: context.features.health),
                        const SizedBox(width: AppSizes.gapS),
                        Text('조치 사항', style: AppTextStyles.headlineSmall(context)),
                      ],
                    ),
                    const SizedBox(height: AppSizes.gapM),
                    Text(
                      record.action!,
                      style: AppTextStyles.bodyMedium(context).copyWith(height: 1.5),
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
      padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingXS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySmall(context)),
          Text(value, style: AppTextStyles.labelLarge(context)),
        ],
      ),
    );
  }

  Color _getCategoryColor(BuildContext context, String category) {
    switch (category) {
      case '증상': return Theme.of(context).colorScheme.error;
      case '행동': return Theme.of(context).colorScheme.tertiary;
      case '식이': return context.features.success;
      case '기타': return Theme.of(context).colorScheme.onSurfaceVariant;
      default: return context.features.health;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case '증상': return AppIcons.health;
      case '행동': return AppIcons.pet;
      case '식이': return AppIcons.food;
      case '기타': return AppIcons.special;
      default: return AppIcons.starOutlined;
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
