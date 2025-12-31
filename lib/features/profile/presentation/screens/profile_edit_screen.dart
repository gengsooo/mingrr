import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/pet_constants.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/image_picker_sheet.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// ============================================================
/// 보호자 프로필 수정 화면
/// 
/// 기능:
/// - 기본 정보 수정 (닉네임, 성별, 생년월일)
/// - 자기소개 작성
/// - 프로필 사진 변경
/// - 위치 정보 설정
/// ============================================================

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _bioController = TextEditingController();
  final _addressController = TextEditingController();
  
  UserGender? _selectedGender;
  DateTime? _birthDate;
  DateTime? _lastNicknameChangeDate;
  String _originalNickname = '';
  bool _isLoading = false;
  bool _isDataLoaded = false;
  
  // 프로필 이미지 관련
  final StorageService _storageService = StorageService();
  XFile? _selectedProfileImage;
  String? _profileImageUrl;
  DefaultAvatar? _selectedDefaultAvatar;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }
  
  Future<void> _loadUserData() async {
    if (_isDataLoaded) return;
    
    final currentUser = ref.read(currentUserProvider).valueOrNull;
    if (currentUser == null) return;
    
    _nicknameController.text = currentUser.nickname ?? '';
    _originalNickname = currentUser.nickname ?? '';
    _bioController.text = currentUser.bio ?? '';
    _addressController.text = currentUser.address ?? '';
    _selectedGender = currentUser.gender;
    _birthDate = currentUser.birthDate;
    _lastNicknameChangeDate = currentUser.nicknameChangedAt;
    _profileImageUrl = currentUser.profileImageUrl;
    _isDataLoaded = true;
    setState(() {});
  }
  
  /// 닉네임 변경 가능 여부 확인 (월 1회 제한)
  bool get canChangeNickname {
    if (_lastNicknameChangeDate == null) return true;
    final daysSinceLastChange = DateTime.now().difference(_lastNicknameChangeDate!).inDays;
    return daysSinceLastChange >= 30;
  }
  
  /// 다음 닉네임 변경 가능일까지 남은 일수
  int get daysUntilNicknameChange {
    if (_lastNicknameChangeDate == null) return 0;
    final daysSinceLastChange = DateTime.now().difference(_lastNicknameChangeDate!).inDays;
    return (30 - daysSinceLastChange).clamp(0, 30);
  }
  
  @override
  void dispose() {
    _nicknameController.dispose();
    _bioController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('프로필 수정'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.paddingM),
          children: [
            // 프로필 사진 (선택적)
            _buildProfilePhoto(),
            const SizedBox(height: AppSizes.gapXL),
            
            // 기본 정보 섹션
            _buildSectionTitle('기본 정보'),
            const SizedBox(height: AppSizes.gapM),
            _buildBasicInfoSection(),
            const SizedBox(height: AppSizes.gapXL),
            
            // 자기소개 섹션
            _buildSectionTitle('자기소개'),
            const SizedBox(height: AppSizes.gapM),
            _buildBioSection(),
            const SizedBox(height: AppSizes.gapXL),
            
            // 위치 정보 섹션
            _buildSectionTitle('위치 정보'),
            const SizedBox(height: AppSizes.gapM),
            _buildLocationSection(),
            const SizedBox(height: AppSizes.gapXXL),
            
            // 저장 버튼
            _buildSaveButton(),
            const SizedBox(height: AppSizes.gapXL),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildProfilePhoto() {
    return Center(
      child: GestureDetector(
        onTap: _showProfileImagePicker,
        child: Stack(
          children: [
            _buildProfileImageWidget(),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildProfileImageWidget() {
    // 새로 선택한 이미지가 있는 경우
    if (_selectedProfileImage != null) {
      return Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primary, width: 3),
        ),
        child: ClipOval(
          child: kIsWeb
              ? Image.network(
                  _selectedProfileImage!.path,
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                )
              : Image.file(
                  File(_selectedProfileImage!.path),
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                ),
        ),
      );
    }
    
    // 대표 아이콘을 선택한 경우
    if (_selectedDefaultAvatar != null) {
      return Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: _selectedDefaultAvatar!.backgroundColor,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primary, width: 3),
        ),
        child: Icon(
          _selectedDefaultAvatar!.icon,
          size: 60,
          color: _selectedDefaultAvatar!.iconColor,
        ),
      );
    }
    
    // 기존 이미지 URL이 있는 경우
    if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      return Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primary, width: 3),
        ),
        child: ClipOval(
          child: Image.network(
            _profileImageUrl!,
            width: 120,
            height: 120,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildDefaultProfileImage(),
          ),
        ),
      );
    }
    
    return _buildDefaultProfileImage();
  }
  
  Widget _buildDefaultProfileImage() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.15),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary, width: 3),
      ),
      child: const Icon(
        Icons.person,
        size: 60,
        color: AppColors.primary,
      ),
    );
  }
  
  Future<void> _showProfileImagePicker() async {
    final result = await showImagePickerSheet(
      context,
      title: '프로필 이미지 선택',
      avatarType: DefaultAvatarType.person,
      currentImageUrl: _profileImageUrl,
      currentDefaultAvatar: _selectedDefaultAvatar,
    );
    
    if (result != null) {
      setState(() {
        if (result.cleared) {
          _selectedProfileImage = null;
          _profileImageUrl = null;
          _selectedDefaultAvatar = null;
        } else if (result.hasImage) {
          _selectedProfileImage = result.imageFile;
          _selectedDefaultAvatar = null;
        } else if (result.hasDefaultAvatar) {
          _selectedDefaultAvatar = result.defaultAvatar;
          _selectedProfileImage = null;
        }
      });
    }
  }

  Widget _buildBasicInfoSection() {
    final nicknameChanged = _nicknameController.text != _originalNickname;
    final canChange = canChangeNickname || !nicknameChanged;
    
    return MingrrCard(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          // 닉네임
          TextFormField(
            controller: _nicknameController,
            enabled: canChangeNickname,
            decoration: InputDecoration(
              labelText: '닉네임 *',
              hintText: '닉네임을 입력해주세요',
              border: const OutlineInputBorder(),
              helperText: canChangeNickname 
                  ? '닉네임은 한 달에 한 번만 변경할 수 있습니다'
                  : '$daysUntilNicknameChange일 후에 변경 가능합니다',
              helperStyle: TextStyle(
                color: canChangeNickname ? AppColors.textHint : AppColors.warning,
                fontSize: 12,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '닉네임을 입력해주세요';
              }
              if (value.length < 2) {
                return '닉네임은 2자 이상이어야 합니다';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSizes.gapM),
          
          // 성별
          Row(
            children: [
              const Text('성별', style: TextStyle(fontSize: 14)),
              const Spacer(),
              SegmentedButton<UserGender>(
                segments: UserGender.values.map((gender) {
                  return ButtonSegment<UserGender>(
                    value: gender,
                    label: Text('${gender.symbol} ${gender.label}'),
                  );
                }).toList(),
                selected: {_selectedGender ?? UserGender.male},
                onSelectionChanged: (Set<UserGender> selection) {
                  setState(() {
                    _selectedGender = selection.first;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: AppSizes.gapM),
          
          // 생년월일
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('생년월일'),
            subtitle: Text(
              _birthDate != null
                  ? '${_birthDate!.year}년 ${_birthDate!.month}월 ${_birthDate!.day}일'
                  : '선택해주세요',
              style: TextStyle(
                color: _birthDate != null ? AppColors.textPrimary : AppColors.textHint,
              ),
            ),
            trailing: const Icon(Icons.calendar_today),
            onTap: _selectBirthDate,
          ),
        ],
      ),
    );
  }

  Widget _buildBioSection() {
    return MingrrCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '다른 보호자들에게 보여질 자기소개를 작성해주세요.',
            style: TextStyle(fontSize: 12, color: AppColors.textHint),
          ),
          const SizedBox(height: AppSizes.gapM),
          TextFormField(
            controller: _bioController,
            maxLines: 4,
            maxLength: 200,
            decoration: const InputDecoration(
              hintText: '예: 반려동물과 함께하는 행복한 일상을 보내고 있습니다.\n산책 친구를 찾고 있어요!',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return MingrrCard(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          // 주소
          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: '주소',
              hintText: '예: 서울시 강남구',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.location_on),
            ),
            readOnly: true,
            onTap: _selectLocation,
          ),
          const SizedBox(height: AppSizes.gapM),
          
          // 현재 위치로 설정
          OutlinedButton.icon(
            onPressed: _setCurrentLocation,
            icon: const Icon(Icons.my_location),
            label: const Text('현재 위치로 설정'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusM),
          ),
        ),
        child: const Text(
          '저장하기',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Future<void> _selectBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(1990),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      helpText: '생년월일 선택',
    );
    if (picked != null) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  void _selectLocation() {
    // TODO: 위치 선택 화면 구현 예정 (지도 연동)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('위치 선택 기능 (지도 연동 예정)')),
    );
  }

  void _setCurrentLocation() {
    // TODO: GPS로 현재 위치 가져오기 구현 예정
    setState(() {
      _addressController.text = '서울시 강남구 역삼동';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('현재 위치로 설정되었습니다'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        final currentUser = ref.read(currentUserProvider).valueOrNull;
        final authUser = ref.read(authStateProvider).valueOrNull;
        
        if (currentUser == null || authUser == null) {
          throw Exception('로그인이 필요합니다');
        }
        
        // 닉네임 변경 여부 확인
        final nicknameChanged = _nicknameController.text.trim() != _originalNickname;
        
        // 닉네임 변경 시 30일 제한 체크
        if (nicknameChanged && !canChangeNickname) {
          throw Exception('닉네임은 30일에 한 번만 변경할 수 있습니다. ${daysUntilNicknameChange}일 후에 다시 시도해주세요.');
        }
        
        // 프로필 이미지 업로드
        String? uploadedImageUrl = _profileImageUrl;
        if (_selectedDefaultAvatar != null) {
          uploadedImageUrl = 'default_avatar:${_selectedDefaultAvatar!.id}';
        } else if (_selectedProfileImage != null) {
          uploadedImageUrl = await _uploadProfileImage(authUser.uid);
        }
        
        final updateData = <String, dynamic>{
          'nickname': _nicknameController.text.trim(),
          'gender': _selectedGender?.name,
          'birthDate': _birthDate != null ? Timestamp.fromDate(_birthDate!) : null,
          'bio': _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
          'address': _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
          'profileImageUrl': uploadedImageUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        
        // 닉네임이 변경되었으면 변경일 업데이트
        if (nicknameChanged) {
          updateData['nicknameChangedAt'] = FieldValue.serverTimestamp();
        }
        
        await FirebaseFirestore.instance
            .collection('users')
            .doc(authUser.uid)
            .update(updateData);
        
        // Provider 리프레시
        ref.invalidate(currentUserProvider);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('프로필이 수정되었습니다!'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('저장 실패: $e'), backgroundColor: AppColors.error),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }
  
  Future<String> _uploadProfileImage(String userId) async {
    if (_selectedProfileImage == null) {
      throw Exception('이미지가 선택되지 않았습니다');
    }
    
    if (kIsWeb) {
      try {
        final bytes = await _selectedProfileImage!.readAsBytes();
        return await _storageService.uploadUserProfileImageBytes(userId, bytes);
      } catch (e) {
        throw Exception('프로필 이미지 업로드 실패: $e');
      }
    }
    
    try {
      final file = File(_selectedProfileImage!.path);
      return await _storageService.uploadUserProfileImage(userId, file);
    } catch (e) {
      throw Exception('프로필 이미지 업로드 실패: $e');
    }
  }
}
