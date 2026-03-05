import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../constants/app_icons.dart';
import '../../constants/app_sizes.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/feature_colors.dart';
import '../../services/firebase_service.dart';
import '../../services/firestore_service.dart';
import '../../utils/error_handler.dart';
import '../common_widgets.dart';
import '../../../models/group_model.dart';
import '../../../features/social/presentation/providers/group_provider.dart';

// ============================================================
// 일정 등록/수정 바텀시트
// ============================================================

/// 일정 등록/수정 바텀시트 표시
Future<void> showScheduleWriteSheet(
  BuildContext context, {
  required String groupId,
  GroupScheduleModel? schedule,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    builder: (ctx) => ScheduleWriteSheet(
      groupId: groupId,
      schedule: schedule,
    ),
  );
}

class ScheduleWriteSheet extends ConsumerStatefulWidget {
  final String groupId;
  final GroupScheduleModel? schedule;

  const ScheduleWriteSheet({
    super.key,
    required this.groupId,
    this.schedule,
  });

  @override
  ConsumerState<ScheduleWriteSheet> createState() => _ScheduleWriteSheetState();
}

class _ScheduleWriteSheetState extends ConsumerState<ScheduleWriteSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _placeController = TextEditingController();
  final _maxParticipantsController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 14, minute: 0);
  bool _isSubmitting = false;
  
  bool get _isEditing => widget.schedule != null;
  
  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final schedule = widget.schedule!;
      _titleController.text = schedule.title;
      _descriptionController.text = schedule.description ?? '';
      _placeController.text = schedule.place ?? '';
      _maxParticipantsController.text = schedule.maxParticipants > 0 
          ? schedule.maxParticipants.toString() 
          : '';
      _selectedDate = schedule.startTime;
      _selectedTime = TimeOfDay.fromDateTime(schedule.startTime);
    }
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _placeController.dispose();
    _maxParticipantsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = context.features.social;
    
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSizes.radiusL)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 핸들
          Container(
            margin: const EdgeInsets.only(top: AppSizes.paddingM),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // 헤더
          Padding(
            padding: const EdgeInsets.all(AppSizes.paddingL),
            child: Row(
              children: [
                Text(
                  _isEditing ? '일정 수정' : '일정 등록',
                  style: AppTextStyles.headlineSmall(context),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(AppIcons.close, color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // 폼
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.paddingL),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 제목
                    MingrrTextField(
                      controller: _titleController,
                      labelText: '일정 제목',
                      hintText: '예: 주말 산책 모임',
                      maxLength: 30,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '일정 제목을 입력해주세요';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSizes.gapL),
                    
                    // 날짜/시간
                    Text('날짜 및 시간', style: AppTextStyles.labelLarge(context)),
                    const SizedBox(height: AppSizes.gapS),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDateButton(context, accentColor),
                        ),
                        const SizedBox(width: AppSizes.gapM),
                        Expanded(
                          child: _buildTimeButton(context, accentColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.gapL),
                    
                    // 장소
                    MingrrTextField(
                      controller: _placeController,
                      labelText: '장소 (선택)',
                      hintText: '예: 한강공원 여의도지구',
                      maxLength: 50,
                    ),
                    const SizedBox(height: AppSizes.gapL),
                    
                    // 최대 인원
                    MingrrTextField(
                      controller: _maxParticipantsController,
                      labelText: '최대 인원 (선택)',
                      hintText: '0 = 제한 없음',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: AppSizes.gapL),
                    
                    // 설명
                    MingrrTextField(
                      controller: _descriptionController,
                      labelText: '상세 설명 (선택)',
                      hintText: '일정에 대한 추가 설명을 입력해주세요',
                      maxLines: 3,
                      maxLength: 200,
                    ),
                    const SizedBox(height: AppSizes.gapXL),
                  ],
                ),
              ),
            ),
          ),
          
          // 제출 버튼
          Container(
            padding: EdgeInsets.fromLTRB(
              AppSizes.paddingL,
              AppSizes.paddingM,
              AppSizes.paddingL,
              AppSizes.paddingL + MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(top: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3))),
            ),
            child: MingrrButton(
              text: _isEditing ? '수정 완료' : '일정 등록',
              onPressed: _isSubmitting ? null : _submit,
              isLoading: _isSubmitting,
              backgroundColor: accentColor,
              textColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDateButton(BuildContext context, Color accentColor) {
    final colorScheme = Theme.of(context).colorScheme;
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final dateText = '${_selectedDate.month}/${_selectedDate.day}(${weekdays[_selectedDate.weekday - 1]})';
    
    return InkWell(
      onTap: () => _selectDate(context),
      borderRadius: BorderRadius.circular(AppSizes.radiusS),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM, vertical: AppSizes.paddingM),
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outline),
          borderRadius: BorderRadius.circular(AppSizes.radiusS),
        ),
        child: Row(
          children: [
            Icon(AppIcons.calendar, size: 20, color: accentColor),
            const SizedBox(width: AppSizes.gapS),
            Text(dateText, style: AppTextStyles.bodyMedium(context)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTimeButton(BuildContext context, Color accentColor) {
    final colorScheme = Theme.of(context).colorScheme;
    final timeText = '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';
    
    return InkWell(
      onTap: () => _selectTime(context),
      borderRadius: BorderRadius.circular(AppSizes.radiusS),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM, vertical: AppSizes.paddingM),
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outline),
          borderRadius: BorderRadius.circular(AppSizes.radiusS),
        ),
        child: Row(
          children: [
            Icon(AppIcons.accessTime, size: 20, color: accentColor),
            const SizedBox(width: AppSizes.gapS),
            Text(timeText, style: AppTextStyles.bodyMedium(context)),
          ],
        ),
      ),
    );
  }
  
  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }
  
  Future<void> _selectTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }
  
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    final myUserId = FirebaseService().currentUserId;
    if (myUserId == null) return;
    
    setState(() => _isSubmitting = true);
    
    try {
      final firestoreService = FirestoreService();
      
      final startTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );
      
      final maxParticipants = int.tryParse(_maxParticipantsController.text.trim()) ?? 0;
      
      final schedule = GroupScheduleModel(
        id: _isEditing ? widget.schedule!.id : const Uuid().v4(),
        groupId: widget.groupId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        startTime: startTime,
        place: _placeController.text.trim().isEmpty 
            ? null 
            : _placeController.text.trim(),
        participantIds: _isEditing 
            ? widget.schedule!.participantIds 
            : [myUserId],
        maxParticipants: maxParticipants,
        creatorId: _isEditing ? widget.schedule!.creatorId : myUserId,
        createdAt: _isEditing ? widget.schedule!.createdAt : DateTime.now(),
      );
      
      if (_isEditing) {
        await firestoreService.updateSchedule(schedule);
      } else {
        await firestoreService.createSchedule(schedule);
      }
      
      if (mounted) {
        ref.invalidate(groupSchedulesProvider(widget.groupId));
        Navigator.pop(context);
        MingrrSnackBar.success(
          context, 
          _isEditing ? '일정이 수정되었습니다' : '일정이 등록되었습니다',
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e, tag: 'Schedule', operation: _isEditing ? '일정 수정' : '일정 등록');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
