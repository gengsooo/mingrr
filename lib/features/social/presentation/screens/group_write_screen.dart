import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/theme/feature_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/pet_constants.dart';
import '../../../../core/constants/form_strings.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../../../core/services/image_service.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/sheets/mingrr_bottom_sheet.dart';
import '../../../../core/widgets/forms/location_selector.dart';
import '../../../../core/widgets/forms/form_components.dart';
import '../../../../core/widgets/forms/tag_input.dart';
import '../../../../models/group_model.dart';
import '../../../../core/providers/refresh_notifier.dart';

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

  GroupType _selectedType = GroupType.walking;
  XFile? _selectedImage;
  String? _existingImageUrl;
  bool _isPublic = true;
  bool _requireApproval = false;
  bool _isPetAccompanied = true;
  final List<String> _tags = [];
  bool _isLoading = false;
  String? _selectedLocation;
  GeoPoint? _selectedGeoPoint;

  FirestoreService get _firestoreService => ref.read(firestoreServiceProvider);
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
      appBar: MingrrAppBar.form(
        title: _isEditMode ? ScreenTitles.groupEdit : ScreenTitles.groupWrite,
        onClose: () => Navigator.pop(context),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.paddingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 대표 이미지
              const MingrrSectionLabel('대표 이미지', suffix: '(최대 10MB)'),
              MingrrImagePicker.single(
                existingUrl: _existingImageUrl,
                selectedFile: _selectedImage,
                onPickImage: _pickImage,
                onRemove: () => setState(() {
                  _existingImageUrl = null;
                  _selectedImage = null;
                }),
                height: 180,
              ),
              const SizedBox(height: AppSizes.gapXL),

              // 모임 종류
              const MingrrSectionLabel('모임 종류'),
              _buildTypeSelector(accentColor),
              const SizedBox(height: AppSizes.gapXL),

              // 모임 이름
              MingrrTextField(
                controller: _nameController,
                labelText: '소모임 이름',
                hintText: FormStrings.hintGroupName,
                validator: (value) {
                  if (value == null || value.isEmpty) return FormStrings.errorRequired;
                  return null;
                },
              ),
              const SizedBox(height: AppSizes.gapL),

              // 모임 소개
              MingrrTextField(
                controller: _descriptionController,
                labelText: '소모임 소개',
                hintText: FormStrings.hintGroupDescription,
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) return FormStrings.errorRequired;
                  return null;
                },
              ),
              const SizedBox(height: AppSizes.gapL),

              // 활동 지역
              MingrrSelectButton(
                label: '활동 지역',
                value: _selectedLocation,
                placeholder: FormStrings.hintLocation,
                icon: AppIcons.locationOutlined,
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
              ),
              const SizedBox(height: AppSizes.gapL),

              // 최대 인원
              MingrrTextField(
                controller: _maxMembersController,
                labelText: '${FormStrings.labelMaxMembers} (${FormStrings.optional})',
                hintText: FormStrings.hintMaxMembers,
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
                labelText: '${FormStrings.labelTag} (${FormStrings.optional})',
              ),
              const SizedBox(height: AppSizes.gapL),

              // 설정
              MingrrSwitchCard(
                title: FormStrings.labelSettings,
                accentColor: accentColor,
                items: [
                  MingrrSwitchItem(
                    title: SwitchStrings.publicGroup,
                    subtitle: SwitchStrings.publicGroupDesc,
                    value: _isPublic,
                    onChanged: (value) => setState(() => _isPublic = value),
                  ),
                  MingrrSwitchItem(
                    title: SwitchStrings.requireApproval,
                    subtitle: SwitchStrings.requireApprovalDesc,
                    value: _requireApproval,
                    onChanged: (value) => setState(() => _requireApproval = value),
                  ),
                  MingrrSwitchItem(
                    title: SwitchStrings.petAccompanied,
                    subtitle: SwitchStrings.petAccompaniedDesc,
                    value: _isPetAccompanied,
                    onChanged: (value) => setState(() => _isPetAccompanied = value),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.gapXXL),
            ],
          ),
        ),
      ),
      bottomNavigationBar: MingrrSubmitButtonBar(
        label: _isEditMode ? FormStrings.edit : FormStrings.submit,
        onPressed: _onSubmit,
        isLoading: _isLoading,
        backgroundColor: accentColor,
      ),
    );
  }

  Widget _buildTypeSelector(Color accentColor) {
    return MingrrChipSelector<GroupCategory>(
      items: GroupCategory.values,
      selectedItem: GroupCategory.values.firstWhere(
        (c) => _categoryToGroupType(c) == _selectedType,
        orElse: () => GroupCategory.other,
      ),
      onSelected: (category) => setState(() => _selectedType = _categoryToGroupType(category)),
      labelBuilder: (category) => category.label.replaceAll(' 모임', ''),
      iconBuilder: (category) => category.icon,
      accentColor: accentColor,
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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    
    // 바로 갤러리에서 이미지 선택 (커뮤니티와 동일한 UX)
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: ImageLimits.maxResolution.toDouble(),
      maxHeight: ImageLimits.maxResolution.toDouble(),
      imageQuality: ImageLimits.imageQuality,
    );

    if (image != null) {
      // 파일 크기 검사
      final file = File(image.path);
      final fileSize = await file.length();
      if (fileSize > ImageLimits.maxFileSizeBytes) {
        if (mounted) {
          final sizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(1);
          MingrrSnackBar.warning(
            context, 
            '이미지 크기가 너무 큽니다 (${sizeMB}MB). 최대 ${ImageLimits.maxFileSizeMB}MB까지 업로드 가능합니다',
          );
        }
        return;
      }
      setState(() => _selectedImage = image);
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
        // 리스트 새로고침 트리거
        ref.read(groupRefreshProvider.notifier).state++;
        Navigator.pop(context, true);
        MingrrSnackBar.success(context, _isEditMode ? FormStrings.successUpdated : FormStrings.successCreated);
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
