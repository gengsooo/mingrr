import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_icons.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/form_strings.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/pet_constants.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/nickname_service.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/sheets/mingrr_bottom_sheet.dart';
import '../../../../core/widgets/forms/form_components.dart';
import '../../../../core/widgets/sheets/image_picker_sheet.dart';
import '../../../../core/widgets/map/map_widgets.dart';
import '../../../../core/models/location_model.dart';
import '../../../../core/utils/error_handler.dart';
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
  
  UserGender? _selectedGender;
  DateTime? _birthDate;
  String _originalNickname = '';
  bool _isLoading = false;
  bool _isDataLoaded = false;
  
  // 프로필 이미지 관련
  final StorageService _storageService = StorageService();
  final FirestoreService _firestoreService = FirestoreService();
  XFile? _selectedProfileImage;
  String? _profileImageUrl;
  DefaultAvatar? _selectedDefaultAvatar;
  
  // 위치 정보
  LocationData? _selectedLocation;
  
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
    _selectedGender = currentUser.gender;
    _birthDate = currentUser.birthDate;
    _profileImageUrl = currentUser.profileImageUrl;
    
    // 기존 위치 정보 로드
    if (currentUser.address != null && currentUser.address!.isNotEmpty) {
      _selectedLocation = LocationData(
        latitude: currentUser.location?.latitude ?? 0,
        longitude: currentUser.location?.longitude ?? 0,
        fullAddress: currentUser.address,
        shortAddress: currentUser.address,
      );
    }
    
    _isDataLoaded = true;
    setState(() {});
  }
  
  @override
  void dispose() {
    _nicknameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.detailBackground,
      appBar: MingrrFormAppBar(
        title: '프로필 수정',
        onClose: () => Navigator.pop(context),
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
            const MingrrSectionLabel('기본 정보'),
            const SizedBox(height: AppSizes.gapM),
            _buildBasicInfoSection(),
            const SizedBox(height: AppSizes.gapXL),
            
            // 자기소개 섹션
            const MingrrSectionLabel('자기소개'),
            const SizedBox(height: AppSizes.gapM),
            _buildBioSection(),
            const SizedBox(height: AppSizes.gapXL),
            
            // 위치 정보 섹션
            const MingrrSectionLabel('위치 정보'),
            const SizedBox(height: AppSizes.gapM),
            _buildLocationSection(),
            const SizedBox(height: AppSizes.gapXL),
          ],
        ),
      ),
      bottomNavigationBar: MingrrSubmitButtonBar(
        label: '저장하기',
        isLoading: _isLoading,
        onPressed: _saveProfile,
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
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  AppIcons.camera,
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
          border: Border.all(color: Theme.of(context).colorScheme.primary, width: 3),
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
          border: Border.all(color: Theme.of(context).colorScheme.primary, width: 3),
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
          border: Border.all(color: Theme.of(context).colorScheme.primary, width: 3),
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
        color: Theme.of(context).colorScheme.primary.withValues(alpha: AppOpacity.o15),
        shape: BoxShape.circle,
        border: Border.all(color: Theme.of(context).colorScheme.primary, width: 3),
      ),
      child: Icon(
        AppIcons.profile,
        size: 60,
        color: Theme.of(context).colorScheme.primary,
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
    return MingrrCard(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          // 닉네임
          MingrrTextField(
            controller: _nicknameController,
            labelText: FormStrings.labelNickname,
            hintText: FormStrings.hintNickname,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return FormStrings.hintNickname;
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
              Text('성별', style: AppTextStyles.labelLarge(context)),
              const Spacer(),
              SegmentedButton<UserGender>(
                segments: UserGender.values.map((gender) {
                  return ButtonSegment<UserGender>(
                    value: gender,
                    label: Text(gender.label),
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
          Align(
            alignment: Alignment.centerLeft,
            child: Text('생년월일', style: AppTextStyles.labelLarge(context)),
          ),
          const SizedBox(height: AppSizes.gapS),
          MingrrDateSelector(
            date: _birthDate,
            onSelect: (d) => setState(() => _birthDate = d),
            isBirthDate: true,
            birthDateMinYear: 1950,
            label: _birthDate != null ? null : '선택해주세요',
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
          Text(
            FormStrings.hintUserBio,
            style: AppTextStyles.caption(context).copyWith(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          const SizedBox(height: AppSizes.gapM),
          MingrrTextField(
            controller: _bioController,
            maxLines: 4,
            hintText: '예: 반려동물과 함께하는 행복한 일상을 보내고 있습니다.\n산책 친구를 찾고 있어요!',
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return Column(
      children: [
        LocationDisplayCard(
          location: _selectedLocation,
          accentColor: Theme.of(context).colorScheme.primary,
          placeholder: '지도에서 위치를 선택해주세요',
          onTap: _selectLocation,
        ),
        const SizedBox(height: AppSizes.gapS),
        
        // 안내 텍스트
        Row(
          children: [
            Icon(AppIcons.info, size: 14, color: Theme.of(context).colorScheme.outlineVariant),
            const SizedBox(width: AppSizes.gapXS),
            Expanded(
              child: Text(
                '위치 정보는 근처 마켓 상품 추천에 사용됩니다',
                style: AppTextStyles.caption(context).copyWith(color: Theme.of(context).colorScheme.outlineVariant),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _selectLocation() async {
    final result = await showMapLocationPicker(
      context: context,
      initialLocation: _selectedLocation,
      accentColor: Theme.of(context).colorScheme.primary,
      title: '내 위치 선택',
    );
    
    if (result != null) {
      setState(() {
        _selectedLocation = result;
      });
    }
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
        
        final newNickname = _nicknameController.text.trim();
        
        // 닉네임 변경 시 중복 체크 및 트랜잭션 처리
        if (newNickname != _originalNickname) {
          final isAvailable = await NicknameService.isAvailable(
            newNickname,
            excludeUserId: authUser.uid,
          );
          
          if (!isAvailable) {
            if (mounted) {
              MingrrSnackBar.warning(context, '이미 사용 중인 닉네임입니다');
            }
            setState(() => _isLoading = false);
            return;
          }
          
          // 닉네임 변경 (트랜잭션 처리 - nicknames 컬렉션 업데이트)
          await NicknameService.change(
            userId: authUser.uid,
            oldNickname: _originalNickname,
            newNickname: newNickname,
          );
        }
        
        // 프로필 이미지 업로드
        String? uploadedImageUrl = _profileImageUrl;
        if (_selectedDefaultAvatar != null) {
          uploadedImageUrl = 'default_avatar:${_selectedDefaultAvatar!.id}';
        } else if (_selectedProfileImage != null) {
          uploadedImageUrl = await _uploadProfileImage(authUser.uid);
        }
        
        // 닉네임은 NicknameService.change()에서 이미 업데이트됨
        final updateData = <String, dynamic>{
          if (newNickname == _originalNickname) 'nickname': newNickname,
          'gender': _selectedGender?.name,
          'birthDate': _birthDate != null ? Timestamp.fromDate(_birthDate!) : null,
          'bio': _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
          'address': _selectedLocation?.displayAddress,
          'location': _selectedLocation?.toGeoPoint(),
          'profileImageUrl': uploadedImageUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        
        await FirebaseFirestore.instance
            .collection('users')
            .doc(authUser.uid)
            .update(updateData);
        
        // 상태 관리 새로고침
        ref.invalidate(currentUserProvider);
        
        if (mounted) {
          MingrrSnackBar.success(context, '프로필이 수정되었습니다!');
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ErrorHandler.showError(context, e, tag: 'ProfileEdit', operation: '프로필 저장');
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
