import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../constants/app_icons.dart';
import '../../constants/app_sizes.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/responsive_utils.dart';
import '../sheets/mingrr_bottom_sheet.dart';

// ===== 날짜+시간 통합 선택 결과 =====
class DateTimeRangeResult {
  final DateTime startDate;
  final DateTime? endDate;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final bool isTimeFlexible;

  const DateTimeRangeResult({
    required this.startDate,
    this.endDate,
    this.startTime,
    this.endTime,
    this.isTimeFlexible = false,
  });
}

// ===== 날짜+시간 통합 선택 바텀시트 =====
enum DateTimeSelectionStep { startDate, endDate, startTime, endTime, complete }

class DateTimeRangePickerSheet extends StatefulWidget {
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final TimeOfDay? initialStartTime;
  final TimeOfDay? initialEndTime;
  final bool initialIsTimeFlexible;
  final Color accentColor;
  final String title;

  const DateTimeRangePickerSheet({
    super.key,
    this.initialStartDate,
    this.initialEndDate,
    this.initialStartTime,
    this.initialEndTime,
    this.initialIsTimeFlexible = false,
    required this.accentColor,
    required this.title,
  });

  @override
  State<DateTimeRangePickerSheet> createState() => _DateTimeRangePickerSheetState();
}

class _DateTimeRangePickerSheetState extends State<DateTimeRangePickerSheet> {
  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isStartTimeFlexible = false;
  bool _isEndTimeFlexible = false;
  late DateTimeSelectionStep _currentStep;
  late DateTime _displayedMonth;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
    _startTime = widget.initialStartTime;
    _endTime = widget.initialEndTime;
    // 기존 isTimeFlexible이 true면 둘 다 미정
    _isStartTimeFlexible = widget.initialIsTimeFlexible;
    _isEndTimeFlexible = widget.initialIsTimeFlexible;
    _displayedMonth = widget.initialStartDate ?? DateTime.now();
    
    // 초기 단계 설정
    _currentStep = DateTimeSelectionStep.startDate;
  }
  
  // 완료 여부 확인
  bool get _isComplete {
    if (_startDate == null || _endDate == null) return false;
    final startTimeOk = _isStartTimeFlexible || _startTime != null;
    final endTimeOk = _isEndTimeFlexible || _endTime != null;
    return startTimeOk && endTimeOk;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: ResponsiveUtils.heightPercent(context, 0.75),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.bottomSheetRadius)),
      ),
      child: Column(
        children: [
          _buildPickerHeader(),
          _buildStepIndicatorRow(),
          Expanded(child: _buildPickerContent()),
          // 완료 단계에서만 하단 확인 버튼 표시
          if (_currentStep == DateTimeSelectionStep.complete && _isComplete)
            _buildFinalConfirmButton(),
        ],
      ),
    );
  }

  Widget _buildPickerHeader() {
    return Column(
      children: [
        const BottomSheetHandle(),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSizes.paddingL, 8, 20, 8),
          child: Text(
            widget.title,
            style: AppTextStyles.headlineSmall(context),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildStepIndicatorRow() {
    final isDateStep = _currentStep == DateTimeSelectionStep.startDate || _currentStep == DateTimeSelectionStep.endDate;
    final isTimeStep = _currentStep == DateTimeSelectionStep.startTime || _currentStep == DateTimeSelectionStep.endTime;
    final hasDateCompleted = _startDate != null && _endDate != null;
    final startTimeOk = _isStartTimeFlexible || _startTime != null;
    final endTimeOk = _isEndTimeFlexible || _endTime != null;
    final hasTimeCompleted = startTimeOk && endTimeOk;
    
    // 날짜 표시 텍스트
    String dateValue;
    if (_startDate != null && _endDate != null) {
      dateValue = '${_startDate!.month}/${_startDate!.day} ~ ${_endDate!.month}/${_endDate!.day}';
    } else if (_startDate != null) {
      dateValue = '${_startDate!.month}/${_startDate!.day} ~';
    } else {
      dateValue = '선택';
    }
    
    // 시간 표시 텍스트
    String timeValue;
    final startTimeText = _isStartTimeFlexible ? '미정' : (_startTime != null ? _fmtTime(_startTime!) : null);
    final endTimeText = _isEndTimeFlexible ? '미정' : (_endTime != null ? _fmtTime(_endTime!) : null);
    if (startTimeText != null && endTimeText != null) {
      timeValue = '$startTimeText ~ $endTimeText';
    } else if (startTimeText != null) {
      timeValue = '$startTimeText ~';
    } else {
      timeValue = '선택';
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingXL, vertical: AppSizes.paddingM),
      child: Row(
        children: [
          _buildPickerStepChip(
            label: '날짜 선택',
            value: dateValue,
            isActive: isDateStep,
            isCompleted: hasDateCompleted,
            onTap: () => setState(() => _currentStep = DateTimeSelectionStep.startDate),
          ),
          const SizedBox(width: AppSizes.gapM),
          _buildPickerStepChip(
            label: '시간 선택',
            value: timeValue,
            isActive: isTimeStep || _currentStep == DateTimeSelectionStep.complete,
            isCompleted: hasTimeCompleted,
            onTap: hasDateCompleted ? () => setState(() {
              // 시간 선택 탭 클릭 시 기본값 설정
              if (!_isStartTimeFlexible && _startTime == null) {
                _startTime = const TimeOfDay(hour: 9, minute: 0);
              }
              _currentStep = DateTimeSelectionStep.startTime;
            }) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildPickerStepChip({required String label, String? value, required bool isActive, required bool isCompleted, VoidCallback? onTap}) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingS, horizontal: 8),
          decoration: BoxDecoration(
            color: isActive 
                ? widget.accentColor.withValues(alpha: AppOpacity.o10) 
                : (isCompleted 
                    ? widget.accentColor.withValues(alpha: AppOpacity.o05) 
                    : colorScheme.surface),
            border: Border.all(
              color: isActive 
                  ? widget.accentColor 
                  : (isCompleted 
                      ? widget.accentColor.withValues(alpha: AppOpacity.o30) 
                      : colorScheme.outline), 
              width: isActive ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(AppSizes.radiusS),
          ),
          child: Column(
            children: [
              Text(label, style: AppTextStyles.labelSmall(context).copyWith(color: isActive ? widget.accentColor : colorScheme.onSurfaceVariant)),
              const SizedBox(height: AppSizes.gapXXS),
              Text(value ?? '선택', style: AppTextStyles.labelMedium(context).copyWith(fontWeight: FontWeight.w600, color: value != null ? colorScheme.onSurface : colorScheme.outlineVariant), overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPickerContent() {
    switch (_currentStep) {
      case DateTimeSelectionStep.startDate:
      case DateTimeSelectionStep.endDate:
        return _buildPickerCalendar();
      case DateTimeSelectionStep.startTime:
      case DateTimeSelectionStep.endTime:
        return _buildPickerTimeSelector();
      case DateTimeSelectionStep.complete:
        return _buildPickerSummary();
    }
  }

  Widget _buildPickerCalendar() {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, now.day);
    final lastDay = DateTime(now.year + 1, now.month, now.day);
    final isStartDateStep = _currentStep == DateTimeSelectionStep.startDate;
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingXL),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(icon: Icon(AppIcons.chevronLeft, color: widget.accentColor), onPressed: () => setState(() => _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1))),
              Text('${_displayedMonth.year}년 ${_displayedMonth.month}월', style: AppTextStyles.titleLarge(context)),
              IconButton(icon: Icon(AppIcons.chevronRight, color: widget.accentColor), onPressed: () => setState(() => _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1))),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingXL),
          child: Row(
            children: ['일', '월', '화', '수', '목', '금', '토'].map((day) {
              return Expanded(child: Center(child: Text(day, style: AppTextStyles.labelMedium(context).copyWith(fontWeight: FontWeight.w600, color: day == '일' || day == '토' ? Colors.red : Theme.of(context).colorScheme.onSurfaceVariant))));
            }).toList(),
          ),
        ),
        const SizedBox(height: AppSizes.gapS),
        Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingXL), child: _buildPickerCalendarGrid(firstDay, lastDay))),
        // 날짜 선택 하단 이전/다음 버튼
        _buildDateNavigationButtons(isStartDateStep),
      ],
    );
  }

  Widget _buildPickerCalendarGrid(DateTime firstDay, DateTime lastDay) {
    final daysInMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0).day;
    final firstWeekday = DateTime(_displayedMonth.year, _displayedMonth.month, 1).weekday % 7;
    
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, childAspectRatio: 1),
      itemCount: 42,
      itemBuilder: (context, index) {
        final dayOffset = index - firstWeekday;
        if (dayOffset < 0 || dayOffset >= daysInMonth) return const SizedBox();
        
        final date = DateTime(_displayedMonth.year, _displayedMonth.month, dayOffset + 1);
        final isBeforeToday = date.isBefore(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day));
        final isDisabled = isBeforeToday || date.isAfter(lastDay);
        final isBeforeStartDate = _currentStep == DateTimeSelectionStep.endDate && _startDate != null && date.isBefore(_startDate!);
        final isStartDate = _startDate != null && _sameDay(date, _startDate!);
        final isEndDate = _endDate != null && _sameDay(date, _endDate!);
        final isInRange = _startDate != null && _endDate != null && date.isAfter(_startDate!) && date.isBefore(_endDate!);
        final isToday = _sameDay(date, DateTime.now());
        
        return GestureDetector(
          onTap: (isDisabled || isBeforeStartDate) ? null : () => _onPickerDateSelected(date),
          child: Container(
            margin: const EdgeInsets.all(AppSizes.paddingXXS),
            decoration: BoxDecoration(
              color: isStartDate || isEndDate ? widget.accentColor : (isInRange ? widget.accentColor.withValues(alpha: AppOpacity.o15) : null),
              shape: BoxShape.circle,
              border: isToday && !isStartDate && !isEndDate ? Border.all(color: widget.accentColor, width: 1) : null,
            ),
            child: Center(child: Text('${dayOffset + 1}', style: AppTextStyles.labelLarge(context).copyWith(fontWeight: isStartDate || isEndDate ? FontWeight.w600 : FontWeight.w400, color: isStartDate || isEndDate ? Colors.white : (isDisabled || isBeforeStartDate) ? Theme.of(context).colorScheme.outlineVariant : (index % 7 == 0 ? Colors.red : Theme.of(context).colorScheme.onSurface)))),
          ),
        );
      },
    );
  }

  void _onPickerDateSelected(DateTime date) {
    setState(() {
      if (_currentStep == DateTimeSelectionStep.startDate) {
        _startDate = date;
        if (_endDate != null && date.isAfter(_endDate!)) _endDate = null;
        // 자동 전환 제거 - 버튼으로만 전환
      } else if (_currentStep == DateTimeSelectionStep.endDate) {
        _endDate = date;
        // 자동 전환 제거 - 버튼으로만 전환
      }
    });
  }

  Widget _buildPickerTimeSelector() {
    final isStartTime = _currentStep == DateTimeSelectionStep.startTime;
    final isFlexible = isStartTime ? _isStartTimeFlexible : _isEndTimeFlexible;
    final currentTime = isStartTime 
        ? (_startTime ?? const TimeOfDay(hour: 9, minute: 0)) 
        : (_endTime ?? const TimeOfDay(hour: 18, minute: 0));
    
    return Column(
      children: [
        // 시간 미정 옵션 (시작/종료 각각)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingXL, vertical: AppSizes.paddingS),
          child: GestureDetector(
            onTap: () => setState(() {
              if (isStartTime) {
                _isStartTimeFlexible = !_isStartTimeFlexible;
                if (_isStartTimeFlexible) {
                  _startTime = null;
                } else {
                  // 미정 해제 시 기본값 설정
                  _startTime ??= const TimeOfDay(hour: 9, minute: 0);
                }
              } else {
                _isEndTimeFlexible = !_isEndTimeFlexible;
                if (_isEndTimeFlexible) {
                  _endTime = null;
                } else {
                  // 미정 해제 시 기본값 설정
                  _endTime ??= const TimeOfDay(hour: 18, minute: 0);
                }
              }
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM, vertical: AppSizes.paddingM),
              decoration: BoxDecoration(
                color: isFlexible 
                    ? widget.accentColor.withValues(alpha: AppOpacity.o10) 
                    : Colors.white,
                border: Border.all(color: isFlexible ? widget.accentColor : Theme.of(context).colorScheme.outline),
                borderRadius: BorderRadius.circular(AppSizes.radiusS),
              ),
              child: Row(
                children: [
                  Icon(isFlexible ? AppIcons.checkCircle : AppIcons.circleOutlined, size: 20, color: isFlexible ? widget.accentColor : Theme.of(context).colorScheme.outlineVariant),
                  const SizedBox(width: AppSizes.gapS),
                  Text(isStartTime ? '시작 시간 미정' : '종료 시간 미정', style: AppTextStyles.labelLarge(context)),
                ],
              ),
            ),
          ),
        ),
        // 시간 선택 Picker (미정이 아닐 때만)
        if (!isFlexible) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingM),
            child: Text(
              '${currentTime.hour.toString().padLeft(2, '0')}:${currentTime.minute.toString().padLeft(2, '0')}',
              style: AppTextStyles.displayLarge(context).withColor(widget.accentColor),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: CupertinoPicker(
                    key: ValueKey('hour_picker_$isStartTime'),
                    scrollController: FixedExtentScrollController(initialItem: currentTime.hour),
                    itemExtent: 40,
                    onSelectedItemChanged: (i) => _updatePickerTime(isStartTime, i, currentTime.minute),
                    children: List.generate(24, (i) => Center(child: Text('${i.toString().padLeft(2, '0')}시', style: AppTextStyles.headlineSmall(context)))),
                  ),
                ),
                Expanded(
                  child: CupertinoPicker(
                    key: ValueKey('minute_picker_$isStartTime'),
                    scrollController: FixedExtentScrollController(initialItem: currentTime.minute ~/ 10),
                    itemExtent: 40,
                    onSelectedItemChanged: (i) => _updatePickerTime(isStartTime, currentTime.hour, i * 10),
                    children: List.generate(6, (i) => Center(child: Text('${(i * 10).toString().padLeft(2, '0')}분', style: AppTextStyles.headlineSmall(context)))),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (isFlexible) const Spacer(),
        // 시간 선택 하단 이전/다음 버튼
        _buildTimeNavigationButtons(isStartTime),
      ],
    );
  }

  void _updatePickerTime(bool isStartTime, int hour, int minute) {
    setState(() {
      if (isStartTime) {
        _startTime = TimeOfDay(hour: hour, minute: minute);
      } else {
        _endTime = TimeOfDay(hour: hour, minute: minute);
      }
    });
  }

  Widget _buildPickerSummary() {
    // 시간 표시 텍스트 생성
    final startTimeText = _isStartTimeFlexible ? '미정' : (_startTime != null ? _fmtTime(_startTime!) : '미정');
    final endTimeText = _isEndTimeFlexible ? '미정' : (_endTime != null ? _fmtTime(_endTime!) : '미정');
    final timeValue = '$startTimeText ~ $endTimeText';
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.paddingXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('선택 완료', style: AppTextStyles.titleLarge(context)),
          const SizedBox(height: AppSizes.gapL),
          _buildPickerSummaryItem(icon: AppIcons.calendar, label: '기간', value: '${_fmtDateFull(_startDate!)} ~ ${_fmtDateFull(_endDate!)}'),
          const SizedBox(height: AppSizes.gapM),
          _buildPickerSummaryItem(icon: AppIcons.accessTime, label: '시간', value: timeValue),
          const SizedBox(height: AppSizes.gapXL),
          Container(
            padding: const EdgeInsets.all(AppSizes.paddingM),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(AppSizes.radiusS)),
            child: Row(children: [Icon(AppIcons.info, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant), const SizedBox(width: AppSizes.gapS), Expanded(child: Text('상단 탭을 눌러 날짜나 시간을 수정할 수 있습니다', style: AppTextStyles.caption(context)))]),
          ),
        ],
      ),
    );
  }

  Widget _buildPickerSummaryItem({required IconData icon, required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingL),
      decoration: BoxDecoration(color: widget.accentColor.withValues(alpha: AppOpacity.o05), border: Border.all(color: widget.accentColor.withValues(alpha: AppOpacity.o20)), borderRadius: BorderRadius.circular(AppSizes.radiusS)),
      child: Row(
        children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: widget.accentColor.withValues(alpha: AppOpacity.o15), borderRadius: BorderRadius.circular(AppSizes.radiusS)), child: Icon(icon, size: 20, color: widget.accentColor)),
          const SizedBox(width: AppSizes.gapM),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: AppTextStyles.caption(context)), const SizedBox(height: AppSizes.gapXXS), Text(value, style: AppTextStyles.labelLarge(context).copyWith(fontWeight: FontWeight.w600))])),
        ],
      ),
    );
  }

  // 날짜 선택 이전/다음 버튼
  Widget _buildDateNavigationButtons(bool isStartDateStep) {
    final canGoPrev = !isStartDateStep; // 종료일 선택 시에만 이전 가능
    final canGoNext = isStartDateStep ? _startDate != null : _endDate != null;
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSizes.paddingL, 8, 20, 16),
      child: Row(
        children: [
          // 이전 버튼
          Expanded(
            child: OutlinedButton(
              onPressed: canGoPrev ? () => setState(() => _currentStep = DateTimeSelectionStep.startDate) : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: widget.accentColor,
                side: BorderSide(color: canGoPrev ? widget.accentColor : Theme.of(context).colorScheme.outline),
                minimumSize: const Size(0, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusS)),
              ),
              child: Text('이전: 시작일', style: AppTextStyles.labelLarge(context).copyWith(fontWeight: FontWeight.w600, color: canGoPrev ? widget.accentColor : Theme.of(context).colorScheme.outlineVariant)),
            ),
          ),
          const SizedBox(width: AppSizes.gapM),
          // 다음 버튼
          Expanded(
            child: ElevatedButton(
              onPressed: canGoNext 
                  ? () => setState(() {
                      if (isStartDateStep) {
                        _currentStep = DateTimeSelectionStep.endDate;
                      } else {
                        // 시간 선택 진입 시 기본값 설정 (미정이 아닐 때)
                        if (!_isStartTimeFlexible && _startTime == null) {
                          _startTime = const TimeOfDay(hour: 9, minute: 0);
                        }
                        _currentStep = DateTimeSelectionStep.startTime;
                      }
                    })
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.accentColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Theme.of(context).colorScheme.outline,
                minimumSize: const Size(0, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusS)),
              ),
              child: Text(
                isStartDateStep ? '다음: 종료일' : '다음: 시간 선택',
                style: AppTextStyles.labelLarge(context).copyWith(fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 시간 선택 이전/다음 버튼
  Widget _buildTimeNavigationButtons(bool isStartTime) {
    // 다음 버튼: 시간이 선택되었거나 미정이면 활성화
    final canGoNext = isStartTime 
        ? (_isStartTimeFlexible || _startTime != null) 
        : (_isEndTimeFlexible || _endTime != null);
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSizes.paddingL, 8, 20, 16),
      child: Row(
        children: [
          // 이전 버튼 (항상 활성화)
          Expanded(
            child: OutlinedButton(
              onPressed: () => setState(() {
                if (isStartTime) {
                  _currentStep = DateTimeSelectionStep.endDate;
                } else {
                  _currentStep = DateTimeSelectionStep.startTime;
                }
              }),
              style: OutlinedButton.styleFrom(
                foregroundColor: widget.accentColor,
                side: BorderSide(color: widget.accentColor),
                minimumSize: const Size(0, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusS)),
              ),
              child: Text(
                isStartTime ? '이전: 종료일' : '이전: 시작 시간',
                style: AppTextStyles.labelLarge(context).copyWith(fontWeight: FontWeight.w600, color: widget.accentColor),
              ),
            ),
          ),
          const SizedBox(width: AppSizes.gapM),
          // 다음 버튼
          Expanded(
            child: ElevatedButton(
              onPressed: canGoNext 
                  ? () => setState(() {
                      if (isStartTime) {
                        // 시작 시간이 미정이 아니면 기본값 설정
                        if (!_isStartTimeFlexible) {
                          _startTime ??= const TimeOfDay(hour: 9, minute: 0);
                        }
                        // 종료 시간 진입 시 기본값 설정 (미정이 아닐 때)
                        if (!_isEndTimeFlexible && _endTime == null) {
                          _endTime = const TimeOfDay(hour: 18, minute: 0);
                        }
                        _currentStep = DateTimeSelectionStep.endTime;
                      } else {
                        // 종료 시간이 미정이 아니면 기본값 설정
                        if (!_isEndTimeFlexible) {
                          _endTime ??= const TimeOfDay(hour: 18, minute: 0);
                        }
                        _currentStep = DateTimeSelectionStep.complete;
                      }
                    })
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.accentColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Theme.of(context).colorScheme.outline,
                minimumSize: const Size(0, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusS)),
              ),
              child: Text(
                isStartTime ? '다음: 종료 시간' : '완료',
                style: AppTextStyles.labelLarge(context).copyWith(fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 완료 단계 하단 확인 버튼
  Widget _buildFinalConfirmButton() {
    return Container(
      padding: EdgeInsets.only(left: AppSizes.paddingL, right: AppSizes.paddingL, top: 16, bottom: ResponsiveUtils.bottomPaddingWith(context, 16)),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, boxShadow: AppShadows.shadowL(Theme.of(context).brightness == Brightness.dark)),
      child: ElevatedButton(
        onPressed: _onPickerConfirm,
        style: ElevatedButton.styleFrom(backgroundColor: widget.accentColor, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusS))),
        child: Text('확인', style: AppTextStyles.titleLarge(context)),
      ),
    );
  }

  void _onPickerConfirm() {
    if (_startDate == null || _endDate == null) return;
    // 시작/종료 시간이 각각 미정이거나 선택되어야 함
    final startTimeOk = _isStartTimeFlexible || _startTime != null;
    final endTimeOk = _isEndTimeFlexible || _endTime != null;
    if (!startTimeOk || !endTimeOk) return;
    
    // isTimeFlexible은 둘 다 미정일 때만 true
    final isTimeFlexible = _isStartTimeFlexible && _isEndTimeFlexible;
    Navigator.pop(context, DateTimeRangeResult(
      startDate: _startDate!, 
      endDate: _endDate, 
      startTime: _startTime, 
      endTime: _endTime, 
      isTimeFlexible: isTimeFlexible,
    ));
  }

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
  String _fmtTime(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  String _fmtDateFull(DateTime d) => '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
}
