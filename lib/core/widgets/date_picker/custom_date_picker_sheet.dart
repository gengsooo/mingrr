import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../constants/app_icons.dart';
import '../../constants/app_sizes.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/responsive_utils.dart';
import '../dividers/app_dividers.dart';
import '../sheets/mingrr_bottom_sheet.dart';

/// 커스텀 날짜 선택 바텀시트 (yyyy.mm.dd 자동 포맷팅 지원)
class CustomDatePickerSheet extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final Color accentColor;
  final String title;
  final bool enableYearMonthPicker;

  const CustomDatePickerSheet({
    super.key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.accentColor,
    required this.title,
    this.enableYearMonthPicker = false,
  });

  @override
  State<CustomDatePickerSheet> createState() => _CustomDatePickerSheetState();
}

class _CustomDatePickerSheetState extends State<CustomDatePickerSheet> {
  late DateTime _selectedDate;
  late DateTime _displayedMonth;
  final _dateController = TextEditingController();
  String? _errorText;
  bool _isInputMode = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _displayedMonth = DateTime(widget.initialDate.year, widget.initialDate.month);
    _updateDateText();
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  void _updateDateText() {
    _dateController.text = '${_selectedDate.year}.${_selectedDate.month.toString().padLeft(2, '0')}.${_selectedDate.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = ResponsiveUtils.keyboardHeight(context);
    final screenHeight = ResponsiveUtils.screenHeight(context);
    
    // 입력 모드일 때 키보드 높이를 고려하여 높이 조정
    final sheetHeight = _isInputMode && keyboardHeight > 0
        ? screenHeight * 0.9
        : screenHeight * 0.65;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: sheetHeight,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.bottomSheetRadius)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          _isInputMode ? _buildInputMode() : _buildCalendarMode(),
          _buildBottomButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const BottomSheetHandle(),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSizes.paddingL, 8, 20, 8),
          child: Row(
            children: [
              const SizedBox(width: 40),
              Expanded(
                child: Text(
                  widget.title,
                  style: AppTextStyles.headlineSmall(context),
                  textAlign: TextAlign.center,
                ),
              ),
              // 입력 모드 토글 버튼
              IconButton(
                icon: Icon(
                  _isInputMode ? AppIcons.calendarMonth : AppIcons.edit,
                  color: widget.accentColor,
                ),
                onPressed: () => setState(() {
                  _isInputMode = !_isInputMode;
                  if (!_isInputMode) {
                    _errorText = null;
                  }
                }),
                tooltip: _isInputMode ? '캘린더로 선택' : '직접 입력',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputMode() {
    final keyboardHeight = ResponsiveUtils.keyboardHeight(context);
    
    return Expanded(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: AppSizes.paddingL,
          right: AppSizes.paddingL,
          top: AppSizes.paddingL,
          bottom: keyboardHeight > 0 ? keyboardHeight + AppSizes.paddingL : AppSizes.paddingL,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '날짜 직접 입력',
              style: AppTextStyles.titleMedium(context),
            ),
            const SizedBox(height: AppSizes.gapS),
            Text(
              '숫자만 입력하면 자동으로 형식이 적용됩니다',
              style: AppTextStyles.caption(context),
            ),
            const SizedBox(height: AppSizes.gapL),
            TextField(
              controller: _dateController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'YYYY.MM.DD',
                hintStyle: AppTextStyles.bodyLarge(context).withColor(Theme.of(context).colorScheme.outlineVariant),
                errorText: _errorText,
                prefixIcon: Icon(AppIcons.calendar, color: widget.accentColor),
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
                  borderSide: BorderSide(color: widget.accentColor, width: 1.5),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusS),
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
                ),
              ),
              onChanged: _onDateTextChanged,
            ),
            const SizedBox(height: AppSizes.gapXL),
            // 선택된 날짜 미리보기
            if (_errorText == null)
              Container(
                padding: const EdgeInsets.all(AppSizes.paddingL),
                decoration: BoxDecoration(
                  color: widget.accentColor.withValues(alpha: AppOpacity.o05),
                  borderRadius: BorderRadius.circular(AppSizes.radiusS),
                  border: Border.all(color: widget.accentColor.withValues(alpha: AppOpacity.o20)),
                ),
                child: Row(
                  children: [
                    Icon(AppIcons.success, color: widget.accentColor, size: 20),
                    const SizedBox(width: AppSizes.gapM),
                    Text(
                      '${_selectedDate.year}년 ${_selectedDate.month}월 ${_selectedDate.day}일',
                      style: AppTextStyles.titleLarge(context),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _onDateTextChanged(String value) {
    // 숫자만 추출
    final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
    
    // 자동 포맷팅 적용
    String formatted = '';
    for (int i = 0; i < digitsOnly.length && i < 8; i++) {
      if (i == 4 || i == 6) {
        formatted += '.';
      }
      formatted += digitsOnly[i];
    }
    
    // 커서 위치 계산
    final cursorOffset = formatted.length;
    
    // 텍스트 업데이트 (무한 루프 방지)
    if (_dateController.text != formatted) {
      _dateController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: cursorOffset),
      );
    }
    
    // 날짜 유효성 검사
    if (digitsOnly.length == 8) {
      final year = int.tryParse(digitsOnly.substring(0, 4));
      final month = int.tryParse(digitsOnly.substring(4, 6));
      final day = int.tryParse(digitsOnly.substring(6, 8));
      
      if (year != null && month != null && day != null &&
          month >= 1 && month <= 12 && day >= 1 && day <= 31) {
        try {
          final parsedDate = DateTime(year, month, day);
          // 범위 검사
          if (parsedDate.isBefore(widget.firstDate)) {
            setState(() => _errorText = '선택 가능한 가장 이른 날짜: ${_formatDateShort(widget.firstDate)}');
          } else if (parsedDate.isAfter(widget.lastDate)) {
            setState(() => _errorText = '선택 가능한 가장 늦은 날짜: ${_formatDateShort(widget.lastDate)}');
          } else {
            setState(() {
              _selectedDate = parsedDate;
              _displayedMonth = DateTime(parsedDate.year, parsedDate.month);
              _errorText = null;
            });
          }
        } catch (e) {
          setState(() => _errorText = '올바른 날짜 형식이 아닙니다');
        }
      } else {
        setState(() => _errorText = '올바른 날짜 형식이 아닙니다');
      }
    } else {
      setState(() => _errorText = null);
    }
  }

  String _formatDateShort(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  Widget _buildCalendarMode() {
    return Expanded(
      child: Column(
        children: [
          // 월 네비게이션
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingXL, vertical: AppSizes.paddingS),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(AppIcons.chevronLeft, color: widget.accentColor),
                  onPressed: () {
                    setState(() {
                      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1);
                    });
                  },
                ),
                // 년도/월 선택 (enableYearMonthPicker가 true일 때 클릭 가능)
                GestureDetector(
                  onTap: widget.enableYearMonthPicker ? _showYearMonthPicker : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM, vertical: AppSizes.paddingXS),
                    decoration: widget.enableYearMonthPicker ? BoxDecoration(
                      color: widget.accentColor.withValues(alpha: AppOpacity.o10),
                      borderRadius: BorderRadius.circular(AppSizes.radiusS),
                    ) : null,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_displayedMonth.year}년 ${_displayedMonth.month}월',
                          style: AppTextStyles.titleLarge(context),
                        ),
                        if (widget.enableYearMonthPicker) ...[
                          const SizedBox(width: AppSizes.gapXS),
                          Icon(AppIcons.chevronDown, color: widget.accentColor, size: 20),
                        ],
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(AppIcons.chevronRight, color: widget.accentColor),
                  onPressed: () {
                    setState(() {
                      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1);
                    });
                  },
                ),
              ],
            ),
          ),
          
          // 요일 헤더
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingXL),
            child: Row(
              children: ['일', '월', '화', '수', '목', '금', '토'].map((day) {
                final isWeekend = day == '일' || day == '토';
                return Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: AppTextStyles.labelLarge(context)
                          .withWeight(FontWeight.w600)
                          .withColor(isWeekend ? Colors.red : Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: AppSizes.gapS),
          
          // 캘린더 그리드
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingXL),
              child: _buildCalendarGrid(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final daysInMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0).day;
    final firstWeekday = DateTime(_displayedMonth.year, _displayedMonth.month, 1).weekday % 7;
    
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1,
      ),
      itemCount: 42,
      itemBuilder: (context, index) {
        final dayOffset = index - firstWeekday;
        if (dayOffset < 0 || dayOffset >= daysInMonth) {
          return const SizedBox();
        }
        
        final date = DateTime(_displayedMonth.year, _displayedMonth.month, dayOffset + 1);
        final isBeforeFirst = date.isBefore(widget.firstDate);
        final isAfterLast = date.isAfter(widget.lastDate);
        final isDisabled = isBeforeFirst || isAfterLast;
        final isSelected = _isSameDay(date, _selectedDate);
        final isToday = _isSameDay(date, DateTime.now());
        
        return GestureDetector(
          onTap: isDisabled ? null : () {
            setState(() {
              _selectedDate = date;
              _updateDateText();
            });
          },
          child: Container(
            margin: const EdgeInsets.all(AppSizes.paddingXXS),
            decoration: BoxDecoration(
              color: isSelected ? widget.accentColor : null,
              shape: BoxShape.circle,
              border: isToday && !isSelected
                  ? Border.all(color: widget.accentColor, width: 1)
                  : null,
            ),
            child: Center(
              child: Text(
                '${dayOffset + 1}',
                style: AppTextStyles.titleMedium(context)
                    .withWeight(isSelected ? FontWeight.w600 : FontWeight.w400)
                    .withColor(isSelected 
                        ? Colors.white
                        : isDisabled
                            ? Theme.of(context).colorScheme.outlineVariant
                            : (index % 7 == 0 ? Colors.red : Theme.of(context).colorScheme.onSurface)),
              ),
            ),
          ),
        );
      },
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// 년도/월 빠른 선택 모달
  void _showYearMonthPicker() {
    // 동적 년도 범위 계산
    final minYear = widget.firstDate.year;
    final maxYear = widget.lastDate.year;
    final years = List.generate(maxYear - minYear + 1, (i) => minYear + i);
    
    int selectedYear = _displayedMonth.year;
    int selectedMonth = _displayedMonth.month;
    
    // 현재 선택된 년도의 인덱스
    int yearIndex = years.indexOf(selectedYear);
    if (yearIndex < 0) yearIndex = years.length - 1;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          // 선택한 년도에 따라 월 범위 제한
          int minMonth = 1;
          int maxMonth = 12;
          if (selectedYear == widget.firstDate.year) {
            minMonth = widget.firstDate.month;
          }
          if (selectedYear == widget.lastDate.year) {
            maxMonth = widget.lastDate.month;
          }
          // 선택된 월이 범위를 벗어나면 조정
          if (selectedMonth < minMonth) selectedMonth = minMonth;
          if (selectedMonth > maxMonth) selectedMonth = maxMonth;
          
          return Container(
            height: 350,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.bottomSheetRadius)),
            ),
            child: Column(
              children: [
                // 헤더
                Container(
                  padding: const EdgeInsets.fromLTRB(AppSizes.paddingL, 16, 12, 8),
                  child: Row(
                    children: [
                      Text('년도/월 선택', style: AppTextStyles.headlineSmall(context)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(AppIcons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const MingrrDivider(),
                // Picker
                Expanded(
                  child: Row(
                    children: [
                      // 년도 Picker
                      Expanded(
                        child: CupertinoPicker(
                          scrollController: FixedExtentScrollController(initialItem: yearIndex),
                          itemExtent: 40,
                          onSelectedItemChanged: (index) {
                            setModalState(() {
                              selectedYear = years[index];
                            });
                          },
                          children: years.map((year) => Center(
                            child: Text('$year년', style: AppTextStyles.headlineSmall(context)),
                          )).toList(),
                        ),
                      ),
                      // 월 Picker
                      Expanded(
                        child: CupertinoPicker(
                          key: ValueKey('month_picker_$selectedYear'),
                          scrollController: FixedExtentScrollController(initialItem: selectedMonth - minMonth),
                          itemExtent: 40,
                          onSelectedItemChanged: (index) {
                            setModalState(() {
                              selectedMonth = minMonth + index;
                            });
                          },
                          children: List.generate(maxMonth - minMonth + 1, (i) => Center(
                            child: Text('${minMonth + i}월', style: AppTextStyles.headlineSmall(context)),
                          )),
                        ),
                      ),
                    ],
                  ),
                ),
                // 확인 버튼
                Container(
                  padding: EdgeInsets.only(left: AppSizes.paddingL, right: AppSizes.paddingL, top: 16, bottom: ResponsiveUtils.bottomPaddingWith(context, 16)),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {
                        _displayedMonth = DateTime(selectedYear, selectedMonth);
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.accentColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusS)),
                    ),
                    child: Text('확인', style: AppTextStyles.titleLarge(context)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: EdgeInsets.only(
        left: AppSizes.paddingL,
        right: AppSizes.paddingL,
        top: AppSizes.paddingL,
        bottom: ResponsiveUtils.bottomPaddingWith(context, AppSizes.paddingL),
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: AppShadows.shadowL(Theme.of(context).brightness == Brightness.dark),
      ),
      child: ElevatedButton(
        onPressed: _errorText == null ? () => Navigator.pop(context, _selectedDate) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.accentColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Theme.of(context).colorScheme.outline,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusS),
          ),
        ),
        child: Text(
          '선택',
          style: AppTextStyles.titleLarge(context),
        ),
      ),
    );
  }
}
