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
import '../../../../models/community_model.dart';

/// ============================================================
/// 소모임 등록/수정 화면
/// Firebase Firestore와 연동하여 실제 데이터 저장
/// ============================================================

class GroupWriteScreen extends ConsumerStatefulWidget {
  final GroupModel? group; // 수정 시 기존 모임 데이터

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
  bool _isPetAccompanied = true; // 반려동물 동반 여부
  final List<String> _tags = [];
  bool _isLoading = false;
  String? _selectedLocation; // 활동 지역
  GeoPoint? _selectedGeoPoint; // 활동 지역 좌표

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
    return Scaffold(
      backgroundColor: context.detailBackground,
      appBar: AppBar(
        title: Text(_isEditMode ? '모임 수정' : '모임 만들기'),
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
              _buildTypeSelector(),
              const SizedBox(height: AppSizes.gapXL),

              // 모임 이름
              MingrrTextField(
                controller: _nameController,
                labelText: '모임 이름을 입력해주세요',
                hintText: '모임 이름',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '모임 이름을 입력해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSizes.gapL),

              // 모임 소개
              MingrrTextField(
                controller: _descriptionController,
                labelText: '모임 소개',
                hintText: '모임 소개',
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '모임 소개를 입력해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSizes.gapL),

              // 활동 지역
              const Text('활동 지역', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSizes.gapS),
              _buildLocationSelector(),
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
              const Text('태그 (선택)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSizes.gapS),
              _buildTagInput(),
              const SizedBox(height: AppSizes.gapL),

              // 공개 설정
              _buildSettingsSection(),
              const SizedBox(height: AppSizes.gapXXL),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomButton(),
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

  Widget _buildLocationSelector() {
    final hasLocation = _selectedLocation != null && _selectedLocation!.isNotEmpty;
    final color = context.features.community;
    
    return GestureDetector(
      onTap: () => showLocationSelectorWithCoordinates(
        context: context,
        initialLocation: _selectedLocation,
        accentColor: color,
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
          color: hasLocation ? color.withOpacity(0.08) : context.inputBackground,
          border: Border.all(
            color: hasLocation ? color.withOpacity(0.3) : Theme.of(context).colorScheme.outline,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: hasLocation ? color.withOpacity(0.15) : Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                hasLocation ? Icons.location_on : Icons.location_on_outlined,
                size: 22,
                color: hasLocation ? color : Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasLocation) ...[
                    Text(
                      _selectedLocation!,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ] else ...[
                    Text(
                      '활동 지역 선택',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '탭하여 지역을 선택하세요',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (hasLocation)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  '변경',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              )
            else
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

  Widget _buildTypeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: CommunityCategory.values.map((category) {
        final type = _categoryToGroupType(category);
        final isSelected = _selectedType == type;
        return GestureDetector(
          onTap: () => setState(() => _selectedType = type),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? context.features.community : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? context.features.community : Theme.of(context).colorScheme.outline,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(category.icon, size: 14, color: isSelected ? Colors.white : context.features.community),
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

  GroupType _categoryToGroupType(CommunityCategory category) {
    switch (category) {
      case CommunityCategory.walk:
        return GroupType.walking;
      case CommunityCategory.play:
        return GroupType.social;
      case CommunityCategory.share:
        return GroupType.other;
      case CommunityCategory.coffee:
        return GroupType.social;
      case CommunityCategory.training:
        return GroupType.training;
      case CommunityCategory.health:
        return GroupType.health;
      case CommunityCategory.breeding:
        return GroupType.other;
      case CommunityCategory.other:
        return GroupType.other;
    }
  }

  Widget _buildTagInput() {
    return Column(
      children: [
        // 태그 목록
        if (_tags.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tags.map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: context.features.community.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('#$tag', style: TextStyle(fontSize: 13, color: context.features.community)),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => setState(() => _tags.remove(tag)),
                      child: Icon(Icons.close, size: 14, color: context.features.community),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
        ],
        // 태그 추가 버튼
        GestureDetector(
          onTap: _showAddTagDialog,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.outline),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, size: 20, color: context.features.community),
                const SizedBox(width: 8),
                Text('태그 추가', style: TextStyle(color: context.features.community, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showAddTagDialog() async {
    final tag = await showInputDialog(
      context,
      type: DialogType.community,
      title: '태그 추가',
      hintText: '태그를 입력해주세요',
      confirmText: '추가',
    );
    
    if (tag != null && tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() => _tags.add(tag));
    }
  }

  Widget _buildSettingsSection() {
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('공개 모임', style: TextStyle(fontWeight: FontWeight.w500)),
                      Text('누구나 모임을 볼 수 있습니다', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ],
                  ),
                  Switch(
                    value: _isPublic,
                    onChanged: (value) => setState(() => _isPublic = value),
                    activeColor: Colors.white,
                    activeTrackColor: context.features.community,
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: Theme.of(context).colorScheme.outlineVariant,
                    trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
                  ),
                ],
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('가입 승인 필요', style: TextStyle(fontWeight: FontWeight.w500)),
                      Text('관리자가 가입을 승인해야 합니다', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ],
                  ),
                  Switch(
                    value: _requireApproval,
                    onChanged: (value) => setState(() => _requireApproval = value),
                    activeColor: Colors.white,
                    activeTrackColor: context.features.community,
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: Theme.of(context).colorScheme.outlineVariant,
                    trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
                  ),
                ],
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('반려동물 동반', style: TextStyle(fontWeight: FontWeight.w500)),
                      Text('모임 활동 시 반려동물과 함께합니다', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ],
                  ),
                  Switch(
                    value: _isPetAccompanied,
                    onChanged: (value) => setState(() => _isPetAccompanied = value),
                    activeColor: Colors.white,
                    activeTrackColor: context.features.community,
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: Theme.of(context).colorScheme.outlineVariant,
                    trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButton() {
    return MingrrSubmitButtonBar(
      label: _isEditMode ? '수정' : '등록',
      onPressed: _onSubmit,
      isLoading: _isLoading,
      backgroundColor: context.features.community,
    );
  }

  Future<void> _pickImage() async {
    // 16:9 커버 이미지 크롭
    final croppedFile = await ImageUtils.pickCoverImage(
      context: context,
      toolbarColor: context.features.community,
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
      if (currentUser == null) {
        throw Exception('로그인이 필요합니다');
      }

      // 이미지 업로드
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
          themeColor: context.features.community,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
