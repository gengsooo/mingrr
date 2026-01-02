import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/pet_constants.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/utils/image_utils.dart';
import '../../../../core/widgets/common_widgets.dart';
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
  final List<String> _tags = [];
  bool _isLoading = false;
  String? _selectedLocation; // 활동 지역

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
      _tags.addAll(group.tags);
      _selectedLocation = group.address;
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_isEditMode ? '모임 수정' : '모임 만들기'),
        backgroundColor: Colors.white,
        elevation: 0,
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
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
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
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate, size: 48, color: AppColors.textHint),
                  SizedBox(height: 8),
                  Text('이미지 추가', style: TextStyle(color: AppColors.textHint)),
                ],
              )
            : null,
      ),
    );
  }

  Widget _buildLocationSelector() {
    return GestureDetector(
      onTap: () => showLocationSelector(
        context: context,
        initialLocation: _selectedLocation,
        accentColor: AppColors.community,
        onLocationSelected: (location) {
          setState(() => _selectedLocation = location);
        },
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Icon(
              Icons.location_on_outlined,
              color: _selectedLocation != null ? AppColors.community : AppColors.textHint,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _selectedLocation ?? '활동 지역을 선택해주세요',
                style: TextStyle(
                  fontSize: 14,
                  color: _selectedLocation != null ? AppColors.textPrimary : AppColors.textHint,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: AppColors.textHint),
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
              color: isSelected ? AppColors.community : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppColors.community : AppColors.divider,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(category.emoji, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  category.label.replaceAll(' 모임', ''),
                  style: TextStyle(
                    fontSize: 13,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
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
                  color: AppColors.community.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('#$tag', style: const TextStyle(fontSize: 13, color: AppColors.community)),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => setState(() => _tags.remove(tag)),
                      child: const Icon(Icons.close, size: 14, color: AppColors.community),
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
              border: Border.all(color: AppColors.divider),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, size: 20, color: AppColors.community),
                SizedBox(width: 8),
                Text('태그 추가', style: TextStyle(color: AppColors.community, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showAddTagDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('태그 추가'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '태그를 입력해주세요',
            prefixText: '#',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              final tag = controller.text.trim();
              if (tag.isNotEmpty && !_tags.contains(tag)) {
                setState(() => _tags.add(tag));
              }
              Navigator.pop(ctx);
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );
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
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('공개 모임', style: TextStyle(fontWeight: FontWeight.w500)),
                      Text('누구나 모임을 볼 수 있습니다', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                  Switch(
                    value: _isPublic,
                    onChanged: (value) => setState(() => _isPublic = value),
                    activeColor: AppColors.community,
                  ),
                ],
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('가입 승인 필요', style: TextStyle(fontWeight: FontWeight.w500)),
                      Text('관리자가 가입을 승인해야 합니다', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                  Switch(
                    value: _requireApproval,
                    onChanged: (value) => setState(() => _requireApproval = value),
                    activeColor: AppColors.community,
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
    return Container(
      padding: EdgeInsets.only(
        left: AppSizes.paddingL,
        right: AppSizes.paddingL,
        top: AppSizes.paddingM,
        bottom: MediaQuery.of(context).padding.bottom + AppSizes.paddingM,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _onSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.community,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  _isEditMode ? '수정' : '등록',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    // 16:9 커버 이미지 크롭
    final croppedFile = await ImageUtils.pickCoverImage(
      context: context,
      toolbarColor: AppColors.community,
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
        address: _selectedLocation,
        isPublic: _isPublic,
        requireApproval: _requireApproval,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode ? '모임이 수정되었습니다' : '모임이 생성되었습니다'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류가 발생했습니다: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
