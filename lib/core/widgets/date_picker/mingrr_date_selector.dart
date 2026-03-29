import 'dart:async';
import 'package:flutter/material.dart';
import 'custom_date_picker_sheet.dart';
import 'date_time_range_picker_sheet.dart';
import '../../constants/app_icons.dart';
import '../../constants/app_sizes.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_text_styles.dart';

// ===== 공통 날짜 선택기 =====
/// 날짜 선택 위젯 (단일 날짜, 시작일/종료일, 생년월일, 시간 선택 모두 지원)
class MingrrDateSelector extends StatelessWidget {
  /// 시작일 또는 단일 날짜
  final DateTime? date;
  /// 날짜 선택 콜백
  final Function(DateTime) onSelect;
  /// 테마 색상
  final Color? accentColor;
  /// 선택 가능한 최소 날짜
  final DateTime? firstDate;
  /// 선택 가능한 최대 날짜
  final DateTime? lastDate;
  /// 날짜 선택기 상단 텍스트
  final String? helpText;
  /// 표시 라벨 (null이면 자동 포맷)
  final String? label;
  
  // === 시작일/종료일 모드 ===
  /// 종료일 (null이면 단일 날짜 모드)
  final DateTime? endDate;
  /// 종료일 선택 콜백
  final Function(DateTime?)? onEndDateSelect;
  /// 시작일 라벨
  final String startLabel;
  /// 종료일 라벨
  final String endLabel;
  
  // === 생년월일 모드 ===
  /// 생년월일 모드 (과거 날짜만 선택 가능)
  final bool isBirthDate;
  /// 생년월일 최소 연도
  final int birthDateMinYear;
  
  // === 시간 선택 모드 ===
  /// 시간 선택 활성화 여부
  final bool enableTimeSelection;
  /// 시작 시간
  final TimeOfDay? startTime;
  /// 종료 시간
  final TimeOfDay? endTime;
  /// 시간 선택 콜백
  final Function(TimeOfDay?, TimeOfDay?)? onTimeSelect;
  /// 시간 미정 여부
  final bool isTimeFlexible;
  /// 시간 미정 변경 콜백
  final Function(bool)? onTimeFlexibleChanged;

  const MingrrDateSelector({
    super.key,
    this.date,
    required this.onSelect,
    this.accentColor,
    this.firstDate,
    this.lastDate,
    this.helpText,
    this.label,
    this.endDate,
    this.onEndDateSelect,
    this.startLabel = '시작일',
    this.endLabel = '종료일',
    this.isBirthDate = false,
    this.birthDateMinYear = 1950,
    this.enableTimeSelection = false,
    this.startTime,
    this.endTime,
    this.onTimeSelect,
    this.isTimeFlexible = false,
    this.onTimeFlexibleChanged,
  });

  /// 시작일/종료일 모드인지 확인
  bool get isRangeMode => onEndDateSelect != null;

  @override
  Widget build(BuildContext context) {
    // 시간 선택이 활성화된 범위 모드는 통합 바텀시트 사용
    if (isRangeMode && enableTimeSelection) {
      return _buildDateTimeRangeSelector(context);
    }
    if (isRangeMode) {
      return _buildRangeSelector(context);
    }
    return _buildSingleSelector(context);
  }
  
  /// 날짜+시간 통합 선택기 (알바 등록용)
  Widget _buildDateTimeRangeSelector(BuildContext context) {
    final color = accentColor ?? Theme.of(context).colorScheme.primary;
    final hasDate = date != null;
    
    return GestureDetector(
      onTap: () => _showDateTimeRangePicker(context),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.paddingM),
        decoration: BoxDecoration(
          color: hasDate ? color.withValues(alpha: AppOpacity.o10) : context.inputBackground,
          border: Border.all(
            color: hasDate ? color.withValues(alpha: AppOpacity.o30) : Theme.of(context).colorScheme.outline,
          ),
          borderRadius: BorderRadius.circular(AppSizes.radiusS),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: hasDate ? color.withValues(alpha: AppOpacity.o15) : Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppSizes.radiusS),
              ),
              child: Icon(
                hasDate ? AppIcons.dateRange : AppIcons.dateRange,
                size: 22,
                color: hasDate ? color : Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            const SizedBox(width: AppSizes.gapM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasDate) ...[
                    Text(
                      _formatDateRangeDisplay(),
                      style: AppTextStyles.titleMedium(context).withWeight(FontWeight.w600),
                    ),
                    const SizedBox(height: AppSizes.gapXXS),
                    Text(
                      _formatTimeDisplay(),
                      style: AppTextStyles.bodySmall(context).withColor(Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ] else ...[
                    Text(
                      '기간 및 시간 선택',
                      style: AppTextStyles.titleMedium(context),
                    ),
                    const SizedBox(height: AppSizes.gapXXS),
                    Text(
                      '탭하여 근무 기간과 시간을 선택하세요',
                      style: AppTextStyles.bodySmall(context).withColor(Theme.of(context).colorScheme.outlineVariant),
                    ),
                  ],
                ],
              ),
            ),
            if (hasDate)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM, vertical: AppSizes.paddingXS),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(AppSizes.radiusM),
                ),
                child: Text(
                  '변경',
                  style: AppTextStyles.labelLarge(context).withColor(Colors.white),
                ),
              )
            else
              Icon(
                AppIcons.chevronRight,
                color: Theme.of(context).colorScheme.outlineVariant,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
  
  String _formatDateRangeDisplay() {
    if (date == null) return '';
    final start = '${date!.month}/${date!.day}';
    if (endDate != null) {
      final end = '${endDate!.month}/${endDate!.day}';
      return '$start ~ $end';
    }
    return start;
  }
  
  String _formatTimeDisplay() {
    if (isTimeFlexible) return '시간 미정';
    final startStr = startTime != null 
        ? '${startTime!.hour.toString().padLeft(2, '0')}:${startTime!.minute.toString().padLeft(2, '0')}' 
        : '시간 미정';
    final endStr = endTime != null 
        ? '${endTime!.hour.toString().padLeft(2, '0')}:${endTime!.minute.toString().padLeft(2, '0')}' 
        : '시간 미정';
    if (startTime != null || endTime != null || isTimeFlexible) {
      return '$startStr ~ $endStr';
    }
    return '시간 미선택';
  }
  
  Future<void> _showDateTimeRangePicker(BuildContext context) async {
    final color = accentColor ?? Theme.of(context).colorScheme.primary;
    
    final result = await showModalBottomSheet<DateTimeRangeResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DateTimeRangePickerSheet(
        initialStartDate: date,
        initialEndDate: endDate,
        initialStartTime: startTime,
        initialEndTime: endTime,
        initialIsTimeFlexible: isTimeFlexible,
        accentColor: color,
        title: helpText ?? '기간 선택',
      ),
    );
    
    if (result != null) {
      onSelect(result.startDate);
      onEndDateSelect?.call(result.endDate);
      onTimeSelect?.call(result.startTime, result.endTime);
      onTimeFlexibleChanged?.call(result.isTimeFlexible);
    }
  }

  /// 단일 날짜 선택기 (LocationDisplayCard와 동일한 스타일)
  Widget _buildSingleSelector(BuildContext context) {
    final color = accentColor ?? Theme.of(context).colorScheme.primary;
    final hasDate = date != null;
    
    return GestureDetector(
      onTap: () => _selectDate(context, isStart: true),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.paddingM),
        decoration: BoxDecoration(
          color: hasDate ? color.withValues(alpha: AppOpacity.o10) : context.inputBackground,
          border: Border.all(
            color: hasDate ? color.withValues(alpha: AppOpacity.o30) : Theme.of(context).colorScheme.outline,
          ),
          borderRadius: BorderRadius.circular(AppSizes.radiusS),
        ),
        child: Row(
          children: [
            // 아이콘
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: hasDate ? color.withValues(alpha: AppOpacity.o15) : Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppSizes.radiusS),
              ),
              child: Icon(
                hasDate ? AppIcons.calendarMonth : AppIcons.calendarMonth,
                size: 22,
                color: hasDate ? color : Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            const SizedBox(width: AppSizes.gapM),
            
            // 날짜 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasDate) ...[
                    Text(
                      _formatDate(date!),
                      style: AppTextStyles.titleMedium(context).withWeight(FontWeight.w600),
                    ),
                    if (isBirthDate) ...[
                      const SizedBox(height: AppSizes.gapXXS),
                      Text(
                        '만 ${_calculateAge(date!)}세',
                        style: AppTextStyles.bodySmall(context).withColor(Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ] else ...[
                    Text(
                      label ?? (isBirthDate ? '생년월일 선택' : '날짜 선택'),
                      style: AppTextStyles.titleMedium(context),
                    ),
                    const SizedBox(height: AppSizes.gapXXS),
                    Text(
                      '탭하여 선택',
                      style: AppTextStyles.bodySmall(context).withColor(Theme.of(context).colorScheme.outlineVariant),
                    ),
                  ],
                ],
              ),
            ),
            
            // 액션 버튼
            if (hasDate)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM, vertical: AppSizes.paddingXS),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(AppSizes.radiusM),
                ),
                child: Text(
                  '변경',
                  style: AppTextStyles.labelLarge(context).withColor(Colors.white),
                ),
              )
            else
              Icon(
                AppIcons.chevronRight,
                color: Theme.of(context).colorScheme.outlineVariant,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
  
  /// 나이 계산
  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month || 
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  /// 시작일/종료일 선택기 (통일된 디자인)
  Widget _buildRangeSelector(BuildContext context) {
    final color = accentColor ?? Theme.of(context).colorScheme.primary;
    final hasStartDate = date != null;
    final hasEndDate = endDate != null;
    
    return GestureDetector(
      onTap: () => _selectDate(context, isStart: true),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.paddingM),
        decoration: BoxDecoration(
          color: (hasStartDate || hasEndDate) ? color.withValues(alpha: AppOpacity.o10) : context.inputBackground,
          border: Border.all(
            color: (hasStartDate || hasEndDate) ? color.withValues(alpha: AppOpacity.o30) : Theme.of(context).colorScheme.outline,
          ),
          borderRadius: BorderRadius.circular(AppSizes.radiusS),
        ),
        child: Row(
          children: [
            // 아이콘
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (hasStartDate || hasEndDate) 
                    ? color.withValues(alpha: AppOpacity.o15)
                    : Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppSizes.radiusS),
              ),
              child: Icon(
                (hasStartDate || hasEndDate) ? AppIcons.dateRange : AppIcons.dateRange,
                size: 22,
                color: (hasStartDate || hasEndDate) ? color : Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            const SizedBox(width: AppSizes.gapM),
            
            // 날짜 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasStartDate || hasEndDate) ...[
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _selectDate(context, isStart: true),
                            child: Text(
                              hasStartDate ? _formatDateShort(date!) : startLabel,
                              style: AppTextStyles.titleMedium(context)
                                  .withWeight(hasStartDate ? FontWeight.w600 : FontWeight.w400)
                                  .withColor(hasStartDate ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.outlineVariant),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingS),
                          child: Text('~', style: AppTextStyles.bodyLarge(context).withColor(Theme.of(context).colorScheme.onSurfaceVariant)),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _selectDate(context, isStart: false),
                            child: Text(
                              hasEndDate ? _formatDateShort(endDate!) : endLabel,
                              style: AppTextStyles.titleMedium(context)
                                  .withWeight(hasEndDate ? FontWeight.w600 : FontWeight.w400)
                                  .withColor(hasEndDate ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.outlineVariant),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Text(
                      '기간 선택',
                      style: AppTextStyles.titleMedium(context),
                    ),
                    const SizedBox(height: AppSizes.gapXXS),
                    Text(
                      '탭하여 시작일/종료일 선택',
                      style: AppTextStyles.bodySmall(context).withColor(Theme.of(context).colorScheme.outlineVariant),
                    ),
                  ],
                ],
              ),
            ),
            
            // 액션 버튼
            if (hasStartDate || hasEndDate)
              GestureDetector(
                onTap: () => _selectDate(context, isStart: true),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM, vertical: AppSizes.paddingXS),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(AppSizes.radiusM),
                  ),
                  child: Text(
                    '변경',
                    style: AppTextStyles.labelLarge(context).withColor(Colors.white),
                  ),
                ),
              )
            else
              Icon(
                AppIcons.chevronRight,
                color: Theme.of(context).colorScheme.outlineVariant,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  
  /// 짧은 날짜 형식 (시작일/종료일용)
  String _formatDateShort(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _selectDate(BuildContext context, {required bool isStart}) async {
    final color = accentColor ?? Theme.of(context).colorScheme.primary;
    
    // 날짜 범위 설정
    DateTime effectiveFirstDate;
    DateTime effectiveLastDate;
    DateTime initialDate;
    
    if (isBirthDate) {
      // 동적 년도 범위: 현재년도 - 100 ~ 현재년도
      final now = DateTime.now();
      effectiveFirstDate = DateTime(now.year - 100);
      effectiveLastDate = now;
      initialDate = date ?? DateTime(now.year - 30);
    } else if (isRangeMode) {
      if (isStart) {
        effectiveFirstDate = firstDate ?? DateTime.now();
        effectiveLastDate = lastDate ?? DateTime.now().add(const Duration(days: 365));
        initialDate = date ?? DateTime.now();
      } else {
        effectiveFirstDate = date ?? DateTime.now();
        effectiveLastDate = lastDate ?? DateTime.now().add(const Duration(days: 365));
        initialDate = endDate ?? (date ?? DateTime.now());
      }
    } else {
      effectiveFirstDate = firstDate ?? DateTime.now().subtract(const Duration(days: 365 * 2));
      effectiveLastDate = lastDate ?? DateTime.now().add(const Duration(days: 365));
      initialDate = date ?? DateTime.now();
    }
    
    // initialDate가 범위 내에 있는지 확인
    if (initialDate.isBefore(effectiveFirstDate)) {
      initialDate = effectiveFirstDate;
    }
    if (initialDate.isAfter(effectiveLastDate)) {
      initialDate = effectiveLastDate;
    }

    // 커스텀 날짜 선택 바텀시트 사용
    final picked = await _showCustomDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: effectiveFirstDate,
      lastDate: effectiveLastDate,
      color: color,
      title: helpText ?? (isBirthDate ? '생년월일 선택' : (isRangeMode ? (isStart ? '시작일 선택' : '종료일 선택') : '날짜 선택')),
      enableYearMonthPicker: isBirthDate,
    );

    if (picked != null) {
      if (isRangeMode && !isStart) {
        onEndDateSelect!(picked);
      } else {
        onSelect(picked);
        // 시작일이 변경되면 종료일이 시작일보다 이전인 경우 초기화
        if (isRangeMode && endDate != null && endDate!.isBefore(picked)) {
          onEndDateSelect!(null);
        }
      }
    }
  }
  
  /// 커스텀 날짜 선택 바텀시트 (yyyy.mm.dd 자동 포맷팅 지원)
  Future<DateTime?> _showCustomDatePicker({
    required BuildContext context,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
    required Color color,
    required String title,
    bool enableYearMonthPicker = false,
  }) async {
    return showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CustomDatePickerSheet(
        initialDate: initialDate,
        firstDate: firstDate,
        lastDate: lastDate,
        accentColor: color,
        title: title,
        enableYearMonthPicker: enableYearMonthPicker,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }
}
