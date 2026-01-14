import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/feature_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/pet_constants.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/utils/image_utils.dart';
import '../../../../core/widgets/dialogs/dialogs.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/mingrr_bottom_sheet.dart';
import '../../../../core/widgets/location_selector.dart';
import '../../../../core/widgets/tag_input.dart';
import '../../../../models/group_model.dart';

/// ============================================================
/// 소모임(Group) 등록/수정 화면
/// 
/// 소셜 > 소모임 > 모임 만들기/수정
/// 모임 정보 입력, 이미지, 위치, 설정
/// ============================================================

class GroupWriteScreen extends ConsumerStatefulWidget {
  final GroupModel? group;

  const GroupWriteScreen({super.key, this.group});

  @override
  ConsumerState<GroupWriteScreen> createState() => _GroupWriteScreenState();
}

class _GroupWriteScreenState extends ConsumerState<GroupWriteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _maxMembersController = TextEditingController();

  GroupType _selectedType = GroupType.social;
  XFile? _selectedImage;
  String? _existingImageUrl;
  bool _isPublic = true;
  bool _requireApproval = false;
  bool _isPetAccompanied = true;
  final List<String> _tags = [];
  bool _isLoading = false;
  String? _selectedLocation;
  GeoPoint? _selectedGeoPoint;

  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseService _firebaseService = FirebaseService();

  bool get _isEditMode => widget.group != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      final group = widget.group!;
      _nameController.text = group.name;
      _descriptionController.text = group.description;
      _maxMembersController.text = group.maxMembers > 0 ? group.maxMembers.toString() : '';
      _selectedType = group.type;
      _existingImageUrl = group.imageUrl;
      _isPublic = group.isPublic;
      _requireApproval = group.requireApproval;
      _isPetAccompanied = group.isPetAccompanied;
      _tags.addAll(group.tags);
      _selectedLocation = group.address;
      _selectedGeoPoint = group.location;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _maxMembersController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = context.features.social;

    return Scaffold(
      backgroundColor: context.detailBackground,
      appBar: AppBar(
        title: Text(_isEditMode ? '소모임 수정' : '소모임 만들기'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.paddingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 대표 이미지
              const Text('대표 이미지', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSizes.gapS),
              _buildImagePicker(),
              const SizedBox(height: AppSizes.gapXL),

              // 모임 종류
              const Text('모임 종류', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSizes.gapS),
              _buildTypeSelector(accentColor),
              const SizedBox(height: AppSizes.gapXL),

              // 모임 이름
              MingrrTextField(
                controller: _nameController,
                labelText: '모임 이름',
                hintText: '모임 이름을 입력해주세요',
                validator: (value) {
                  if (value == null || value.isEmpty) return '모임 이름을 입력해주세요';
                  return null;
                },
              ),
              const SizedBox(height: AppSizes.gapL),

              // 모임 소개
              MingrrTextField(
                controller: _descriptionController,
                labelText: '모임 소개',
                hintText: '모임에 대해 소개해주세요',
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) return '모임 소개를 입력해주세요';
                  return null;
                },
              ),
              const SizedBox(height: AppSizes.gapL),

              // 활동 지역
              const Text('활동 지역', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSizes.gapS),
              _buildLocationSelector(accentColor),
              const SizedBox(height: AppSizes.gapL),

              // 최대 인원
              MingrrTextField(
                controller: _maxMembersController,
                labelText: '최대 인원 (선택)',
                hintText: '0 = 무제한',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppSizes.gapL),

              // 태그
              MingrrTagInput(
                tags: _tags,
                onTagsChanged: (tags) => setState(() {
                  _tags.clear();
                  _tags.addAll(tags);
                }),
                accentColor: accentColor,
                labelText: '태그 (선택)',
              ),
              const SizedBox(height: AppSizes.gapL),

              // 설정
              _buildSettingsSection(accentColor),
              const SizedBox(height: AppSizes.gapXXL),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomButton(accentColor),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        height: 180,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          image: _selectedImage != null
              ? DecorationImage(
                  image: FileImage(File(_selectedImage!.path)),
                  fit: BoxFit.cover,
                )
              : _existingImageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(_existingImageUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
        ),
        child: (_selectedImage == null && _existingImageUrl == null)
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate, size: 48, color: Theme.of(context).colorScheme.outlineVariant),
                  const SizedBox(height: 8),
                  Text('이미지 추가', style: TextStyle(color: Theme.of(context).colorScheme.outlineVariant)),
                ],
              )
            : null,
      ),
    );
  }

  Widget _buildTypeSelector(Color accentColor) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: GroupCategory.values.map((category) {
        final type = _categoryToGroupType(category);
        final isSelected = _selectedType == type;
        return GestureDetector(
          onTap: () => setState(() => _selectedType = type),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? accentColor : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? accentColor : Theme.of(context).colorScheme.outline,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(category.icon, size: 14, color: isSelected ? Colors.white : accentColor),
                const SizedBox(width: 4),
                Text(
                  category.label.replaceAll(' 모임', ''),
                  style: TextStyle(
                    fontSize: 13,
                    color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  GroupType _categoryToGroupType(GroupCategory category) {
    switch (category) {
      case GroupCategory.walk:
        return GroupType.walking;
      case GroupCategory.play:
      case GroupCategory.coffee:
        return GroupType.social;
      case GroupCategory.training:
        return GroupType.training;
      case GroupCategory.health:
        return GroupType.health;
      default:
        return GroupType.other;
    }
  }

  Widget _buildLocationSelector(Color accentColor) {
    final hasLocation = _selectedLocation != null && _selectedLocation!.isNotEmpty;

    return GestureDetector(
      onTap: () => showLocationSelectorWithCoordinates(
        context: context,
        initialLocation: _selectedLocation,
        accentColor: accentColor,
        onLocationResultSelected: (result) {
          setState(() {
            _selectedLocation = result.address;
            _selectedGeoPoint = result.location;
          });
        },
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.paddingM),
        decoration: BoxDecoration(
          color: hasLocation ? accentColor.withOpacity(0.08) : context.inputBackground,
          border: Border.all(
            color: hasLocation ? accentColor.withOpacity(0.3) : Theme.of(context).colorScheme.outline,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: hasLocation ? accentColor.withOpacity(0.15) : Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                hasLocation ? Icons.location_on : Icons.location_on_outlined,
                size: 22,
                color: hasLocation ? accentColor : Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                hasLocation ? _selectedLocation! : '활동 지역 선택',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: hasLocation ? FontWeight.w600 : FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.outlineVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('설정', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSizes.gapS),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.inputBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildSwitchRow(
                title: '공개 모임',
                subtitle: '누구나 모임을 볼 수 있습니다',
                value: _isPublic,
                onChanged: (value) => setState(() => _isPublic = value),
                accentColor: accentColor,
              ),
              const Divider(),
              _buildSwitchRow(
                title: '가입 승인 필요',
                subtitle: '관리자가 가입을 승인해야 합니다',
                value: _requireApproval,
                onChanged: (value) => setState(() => _requireApproval = value),
                accentColor: accentColor,
              ),
              const Divider(),
              _buildSwitchRow(
                title: '반려동물 동반',
                subtitle: '모임 활동 시 반려동물과 함께합니다',
                value: _isPetAccompanied,
                onChanged: (value) => setState(() => _isPetAccompanied = value),
                accentColor: accentColor,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color accentColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
              Text(subtitle, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.white,
          activeTrackColor: accentColor,
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: Theme.of(context).colorScheme.outlineVariant,
          trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
        ),
      ],
    );
  }

  Widget _buildBottomButton(Color accentColor) {
    return MingrrSubmitButtonBar(
      label: _isEditMode ? '수정' : '등록',
      onPressed: _onSubmit,
      isLoading: _isLoading,
      backgroundColor: accentColor,
    );
  }

  Future<void> _pickImage() async {
    final croppedFile = await ImageUtils.pickCoverImage(
      context: context,
      toolbarColor: context.features.social,
    );

    if (croppedFile != null) {
      setState(() => _selectedImage = XFile(croppedFile.path));
    }
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final currentUser = _firebaseService.currentUser;
      if (currentUser == null) throw Exception('로그인이 필요합니다');

      String? imageUrl = _existingImageUrl;
      if (_selectedImage != null) {
        imageUrl = await _firebaseService.uploadImage(
          File(_selectedImage!.path),
          'groups/${const Uuid().v4()}',
        );
      }

      final maxMembers = int.tryParse(_maxMembersController.text) ?? 0;
      final now = DateTime.now();

      final group = GroupModel(
        id: _isEditMode ? widget.group!.id : const Uuid().v4(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _selectedType,
        imageUrl: imageUrl,
        creatorId: currentUser.uid,
        adminIds: _isEditMode ? widget.group!.adminIds : [currentUser.uid],
        memberIds: _isEditMode ? widget.group!.memberIds : [currentUser.uid],
        maxMembers: maxMembers,
        location: _selectedGeoPoint,
        address: _selectedLocation,
        isPublic: _isPublic,
        requireApproval: _requireApproval,
        isPetAccompanied: _isPetAccompanied,
        tags: _tags,
        createdAt: _isEditMode ? widget.group!.createdAt : now,
        updatedAt: now,
      );

      if (_isEditMode) {
        await _firestoreService.updateGroup(group);
      } else {
        await _firestoreService.createGroup(group);
      }

      if (mounted) {
        Navigator.pop(context, true);
        MingrrSnackBar.success(context, _isEditMode ? '모임이 수정되었습니다' : '모임이 생성되었습니다');
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.handle(
          context,
          error: e,
          tag: 'GroupWrite',
          operation: '모임 저장',
          themeColor: context.features.social,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
