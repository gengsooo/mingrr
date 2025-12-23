import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/pet_constants.dart';
import '../../../../core/widgets/common_widgets.dart';

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
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  void _loadUserData() {
    // TODO: Firebase에서 데이터 로드
    // 데모용 데이터
    _nicknameController.text = '멍멍이아빠';
    _originalNickname = '멍멍이아빠';
    _bioController.text = '반려동물과 함께하는 행복한 일상을 보내고 있습니다.';
    _addressController.text = '서울시 강남구';
    _selectedGender = UserGender.male;
    _birthDate = DateTime(1990, 5, 15);
    // 데모: 마지막 닉네임 변경일 (실제로는 Firebase에서 로드)
    _lastNicknameChangeDate = DateTime.now().subtract(const Duration(days: 35));
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
      child: Stack(
        children: [
          const MingrrAvatar(
            size: 120,
            showBorder: true,
            borderColor: AppColors.primary,
            placeholderIcon: Icons.person,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _pickProfileImage,
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
          ),
        ],
      ),
    );
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
                selected: _selectedGender != null ? {_selectedGender!} : {},
                onSelectionChanged: (Set<UserGender> selection) {
                  setState(() {
                    _selectedGender = selection.isNotEmpty ? selection.first : null;
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

  void _pickProfileImage() {
    // TODO: 이미지 피커 구현
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('프로필 사진 선택 기능 (Firebase Storage 연동 예정)')),
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
    // TODO: 위치 선택 화면 구현
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('위치 선택 기능 (지도 연동 예정)')),
    );
  }

  void _setCurrentLocation() {
    // TODO: 현재 위치 가져오기
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

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      // TODO: Firebase에 저장
      final profileData = {
        'nickname': _nicknameController.text,
        'gender': _selectedGender?.name,
        'birthDate': _birthDate,
        'bio': _bioController.text,
        'address': _addressController.text,
      };
      
      debugPrint('Profile data to save: $profileData');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('프로필이 수정되었습니다!'),
          backgroundColor: AppColors.success,
        ),
      );
      
      Navigator.pop(context, true);
    }
  }
}
