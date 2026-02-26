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
import '../dialogs/dialogs.dart';
import '../modals/guardian_profile_modal.dart';
import '../../../models/group_model.dart';
import '../../../features/social/presentation/providers/group_provider.dart';

/// ============================================================
/// 소모임 일정 관련 바텀시트 모음
/// 
/// 1. ScheduleWriteSheet - 일정 등록/수정
/// 2. ScheduleDetailSheet - 일정 상세 보기
/// ============================================================

// ============================================================
// 1. 일정 등록/수정 바텀시트
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

// ============================================================
// 2. 일정 상세 바텀시트
// ============================================================

/// 일정 상세 바텀시트 표시
Future<void> showScheduleDetailSheet(
  BuildContext context, {
  required GroupScheduleModel schedule,
  required String groupId,
  bool isGroupAdmin = false,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    builder: (ctx) => ScheduleDetailSheet(
      schedule: schedule,
      groupId: groupId,
      isGroupAdmin: isGroupAdmin,
    ),
  );
}

class ScheduleDetailSheet extends ConsumerStatefulWidget {
  final GroupScheduleModel schedule;
  final String groupId;
  final bool isGroupAdmin;

  const ScheduleDetailSheet({
    super.key,
    required this.schedule,
    required this.groupId,
    this.isGroupAdmin = false,
  });

  @override
  ConsumerState<ScheduleDetailSheet> createState() => _ScheduleDetailSheetState();
}

class _ScheduleDetailSheetState extends ConsumerState<ScheduleDetailSheet> {
  bool _isLoading = false;
  
  String? get _myUserId => FirebaseService().currentUserId;
  bool get _isCreator => _myUserId == widget.schedule.creatorId;
  bool get _isParticipant => _myUserId != null && widget.schedule.participantIds.contains(_myUserId);
  bool get _canEdit => _isCreator || widget.isGroupAdmin;
  bool get _isPast => widget.schedule.isPast;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = context.features.social;
    final schedule = widget.schedule;
    
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSizes.radiusL)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 핸들
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: AppSizes.paddingM),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // 헤더
          Padding(
            padding: const EdgeInsets.all(AppSizes.paddingL),
            child: Row(
              children: [
                // 상태 배지
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingS, vertical: AppSizes.paddingXS),
                  decoration: BoxDecoration(
                    color: _isPast
                        ? colorScheme.surfaceContainerLow
                        : accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusXXS),
                  ),
                  child: Text(
                    _isPast ? '종료' : '예정',
                    style: AppTextStyles.labelMedium(context).copyWith(
                      color: _isPast ? colorScheme.onSurfaceVariant : accentColor,
                    ),
                  ),
                ),
                const Spacer(),
                if (_canEdit && !_isPast) ...[
                  IconButton(
                    onPressed: _showEditSheet,
                    icon: Icon(AppIcons.edit, color: colorScheme.onSurfaceVariant),
                    tooltip: '수정',
                  ),
                  IconButton(
                    onPressed: _showDeleteConfirm,
                    icon: Icon(AppIcons.delete, color: colorScheme.error),
                    tooltip: '삭제',
                  ),
                ],
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(AppIcons.close, color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          
          // 내용
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 제목
                Text(
                  schedule.title,
                  style: AppTextStyles.headlineMedium(context),
                ),
                const SizedBox(height: AppSizes.gapL),
                
                // 날짜/시간
                _buildInfoRow(
                  context,
                  icon: AppIcons.calendar,
                  label: '일시',
                  value: _formatDateTime(schedule.startTime),
                  accentColor: accentColor,
                ),
                
                // 장소
                if (schedule.place != null) ...[
                  const SizedBox(height: AppSizes.gapM),
                  _buildInfoRow(
                    context,
                    icon: AppIcons.locationOutlined,
                    label: '장소',
                    value: schedule.place!,
                    accentColor: accentColor,
                  ),
                ],
                
                // 참여자 섹션
                const SizedBox(height: AppSizes.gapM),
                _buildParticipantsSection(context, accentColor),
                
                // 설명
                if (schedule.description != null && schedule.description!.isNotEmpty) ...[
                  const SizedBox(height: AppSizes.gapL),
                  Text(
                    schedule.description!,
                    style: AppTextStyles.bodyMedium(context).copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                
                const SizedBox(height: AppSizes.gapXL),
              ],
            ),
          ),
          
          // 참여 버튼 (지난 일정이 아닌 경우)
          if (!_isPast && _myUserId != null)
            Container(
              padding: EdgeInsets.fromLTRB(
                AppSizes.paddingL,
                AppSizes.paddingM,
                AppSizes.paddingL,
                AppSizes.paddingL + MediaQuery.of(context).padding.bottom,
              ),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(top: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3))),
              ),
              child: _buildParticipateButton(context, accentColor),
            ),
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color accentColor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Row(
      children: [
        Icon(icon, size: 18, color: accentColor),
        const SizedBox(width: AppSizes.gapS),
        Text(
          '$label: ',
          style: AppTextStyles.bodySmall(context).copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodyMedium(context),
          ),
        ),
      ],
    );
  }
  
  Widget _buildParticipateButton(BuildContext context, Color accentColor) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // 정원 초과 체크
    final isFull = widget.schedule.maxParticipants > 0 && 
        widget.schedule.participantCount >= widget.schedule.maxParticipants;
    
    if (_isParticipant) {
      return MingrrButton(
        text: '참여 취소',
        onPressed: _isLoading ? null : _leaveSchedule,
        isLoading: _isLoading,
        isOutlined: true,
        backgroundColor: colorScheme.error,
        textColor: colorScheme.error,
      );
    }
    
    if (isFull) {
      return MingrrButton(
        text: '정원이 마감되었습니다',
        onPressed: null,
        backgroundColor: colorScheme.surfaceContainerLow,
        textColor: colorScheme.onSurfaceVariant,
      );
    }
    
    return MingrrButton(
      text: '참여하기',
      onPressed: _isLoading ? null : _joinSchedule,
      isLoading: _isLoading,
      backgroundColor: accentColor,
      textColor: Colors.white,
    );
  }
  
  String _formatDateTime(DateTime dateTime) {
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    return '${dateTime.year}년 ${dateTime.month}월 ${dateTime.day}일(${weekdays[dateTime.weekday - 1]}) '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
  
  Future<void> _joinSchedule() async {
    if (_myUserId == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      await FirestoreService().joinSchedule(widget.schedule.id, _myUserId!);
      
      if (mounted) {
        ref.invalidate(groupSchedulesProvider(widget.groupId));
        Navigator.pop(context);
        MingrrSnackBar.success(context, '일정에 참여했습니다');
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e, tag: 'Schedule', operation: '일정 참여');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  Future<void> _leaveSchedule() async {
    if (_myUserId == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      await FirestoreService().leaveSchedule(widget.schedule.id, _myUserId!);
      
      if (mounted) {
        ref.invalidate(groupSchedulesProvider(widget.groupId));
        Navigator.pop(context);
        MingrrSnackBar.info(context, '일정 참여를 취소했습니다');
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e, tag: 'Schedule', operation: '참여 취소');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  void _showEditSheet() {
    Navigator.pop(context);
    showScheduleWriteSheet(
      context,
      groupId: widget.groupId,
      schedule: widget.schedule,
    );
  }
  
  Future<void> _showDeleteConfirm() async {
    final confirmed = await showAppDialog(
      context,
      type: DialogType.warning,
      title: '일정 삭제',
      message: '이 일정을 삭제하시겠습니까?\n삭제된 일정은 복구할 수 없습니다.',
      confirmText: '삭제',
      showCancel: true,
    );
    
    if (confirmed == true) {
      await _deleteSchedule();
    }
  }
  
  Future<void> _deleteSchedule() async {
    setState(() => _isLoading = true);
    
    try {
      await FirestoreService().deleteSchedule(widget.schedule.id);
      
      if (mounted) {
        ref.invalidate(groupSchedulesProvider(widget.groupId));
        Navigator.pop(context);
        MingrrSnackBar.success(context, '일정이 삭제되었습니다');
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e, tag: 'Schedule', operation: '일정 삭제');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  /// 참여자 섹션 빌드
  Widget _buildParticipantsSection(BuildContext context, Color accentColor) {
    final colorScheme = Theme.of(context).colorScheme;
    final schedule = widget.schedule;
    final participantIds = schedule.participantIds;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 헤더
        Row(
          children: [
            Icon(AppIcons.profile, size: 18, color: accentColor),
            const SizedBox(width: AppSizes.gapS),
            Text(
              '참여자: ',
              style: AppTextStyles.bodySmall(context).copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              schedule.maxParticipants > 0
                  ? '${schedule.participantCount}/${schedule.maxParticipants}명'
                  : '${schedule.participantCount}명',
              style: AppTextStyles.bodyMedium(context),
            ),
          ],
        ),
        
        // 참여자 목록 (있는 경우)
        if (participantIds.isNotEmpty) ...[
          const SizedBox(height: AppSizes.gapM),
          SizedBox(
            height: 56,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: participantIds.length,
              itemBuilder: (context, index) {
                return _ParticipantAvatar(
                  userId: participantIds[index],
                  isCreator: participantIds[index] == schedule.creatorId,
                  accentColor: accentColor,
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

/// 참여자 아바타 위젯 (비동기 로딩)
class _ParticipantAvatar extends StatefulWidget {
  final String userId;
  final bool isCreator;
  final Color accentColor;

  const _ParticipantAvatar({
    required this.userId,
    required this.isCreator,
    required this.accentColor,
  });

  @override
  State<_ParticipantAvatar> createState() => _ParticipantAvatarState();
}

class _ParticipantAvatarState extends State<_ParticipantAvatar> {
  String? _nickname;
  String? _profileImageUrl;
  double? _kkosunnaeScore;
  GuardianActivityInfo? _activityInfo;
  bool _isLoading = true;
  bool _isIdentityVerified = false;
  bool _isLocationVerified = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final user = await FirestoreService().getUser(widget.userId);
      if (mounted && user != null) {
        setState(() {
          _nickname = user.nickname;
          _profileImageUrl = user.profileImageUrl;
          _kkosunnaeScore = user.kkosunnaeScore;
          _activityInfo = GuardianActivityInfo.fromUser(user);
          _isIdentityVerified = user.isIdentityVerified;
          _isLocationVerified = user.isLocationVerified;
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return GestureDetector(
      onTap: _showProfile,
      child: Container(
        margin: const EdgeInsets.only(right: AppSizes.gapS),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                // 프로필 이미지
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: widget.isCreator 
                        ? Border.all(color: widget.accentColor, width: 2)
                        : null,
                  ),
                  child: ClipOval(
                    child: _isLoading
                        ? Container(color: colorScheme.surfaceContainerLow)
                        : MingrrImage(
                            imageUrl: _profileImageUrl,
                            fit: BoxFit.cover,
                            placeholderIcon: AppIcons.profile,
                            accentColor: widget.accentColor,
                          ),
                  ),
                ),
                // 주최자 배지
                if (widget.isCreator)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: widget.accentColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: colorScheme.surface, width: 1.5),
                      ),
                      child: Icon(AppIcons.star, size: 8, color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSizes.gapXXS),
            // 닉네임
            SizedBox(
              width: 48,
              child: Text(
                _nickname ?? '...',
                style: AppTextStyles.captionSmall(context),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProfile() {
    if (_isLoading || _nickname == null) return;
    
    showGuardianProfileModal(
      context,
      guardianId: widget.userId,
      guardianName: _nickname!,
      kkosunnaeScore: _kkosunnaeScore ?? 50.0,
      profileImageUrl: _profileImageUrl,
      isIdentityVerified: _isIdentityVerified,
      isLocationVerified: _isLocationVerified,
      activityInfo: _activityInfo,
    );
  }
}
