import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/pet_constants.dart';
import '../../../../core/widgets/common_widgets.dart';

/// ============================================================
/// 반려동물 추가/수정 화면
/// 
/// 기능:
/// - 강아지 기본 정보 입력 (이름, 품종, 성별, 생년월일, 체중)
/// - 특성 선택 (최소 5개)
/// - 소개글 작성
/// - 중성화 여부, 혈통서 여부
/// - 사진 업로드 (프로필, 추가 사진)
/// ============================================================

class PetEditScreen extends ConsumerStatefulWidget {
  final String? petId; // null이면 추가, 있으면 수정
  
  const PetEditScreen({super.key, this.petId});

  @override
  ConsumerState<PetEditScreen> createState() => _PetEditScreenState();
}

class _PetEditScreenState extends ConsumerState<PetEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _weightController = TextEditingController();
  final _bioController = TextEditingController();
  
  PetGender _selectedGender = PetGender.male;
  DateTime? _birthDate;
  bool _isNeutered = false;
  bool _hasPedigree = false;
  final Set<PetTrait> _selectedTraits = {};
  
  bool get isEditMode => widget.petId != null;
  
  @override
  void initState() {
    super.initState();
    if (isEditMode) {
      _loadPetData();
    }
  }
  
  void _loadPetData() {
    // TODO: Firebase에서 데이터 로드
    // 데모용 데이터
    _nameController.text = '뽀삐';
    _breedController.text = '골든 리트리버';
    _weightController.text = '28.5';
    _bioController.text = '활발하고 사람을 좋아하는 강아지입니다.';
    _selectedGender = PetGender.male;
    _birthDate = DateTime(2022, 3, 15);
    _isNeutered = true;
    _hasPedigree = false;
    _selectedTraits.addAll([
      PetTrait.active,
      PetTrait.friendly,
      PetTrait.playful,
      PetTrait.lovesPeople,
      PetTrait.fetcher,
    ]);
    setState(() {});
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _weightController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEditMode ? '반려동물 수정' : '반려동물 추가'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (isEditMode)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: _showDeleteConfirmation,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.paddingM),
          children: [
            // 프로필 사진
            _buildProfilePhoto(),
            const SizedBox(height: AppSizes.gapXL),
            
            // 기본 정보 섹션
            _buildSectionTitle('기본 정보'),
            const SizedBox(height: AppSizes.gapM),
            _buildBasicInfoSection(),
            const SizedBox(height: AppSizes.gapXL),
            
            // 신체 정보 섹션
            _buildSectionTitle('신체 정보'),
            const SizedBox(height: AppSizes.gapM),
            _buildPhysicalInfoSection(),
            const SizedBox(height: AppSizes.gapXL),
            
            // 특성 선택 섹션
            _buildSectionTitle('특성 선택', subtitle: '최소 5개 이상 선택해주세요'),
            const SizedBox(height: AppSizes.gapM),
            _buildTraitsSection(),
            const SizedBox(height: AppSizes.gapXL),
            
            // 소개글 섹션
            _buildSectionTitle('소개글'),
            const SizedBox(height: AppSizes.gapM),
            _buildBioSection(),
            const SizedBox(height: AppSizes.gapXL),
            
            // 추가 정보 섹션
            _buildSectionTitle('추가 정보'),
            const SizedBox(height: AppSizes.gapM),
            _buildAdditionalInfoSection(),
            const SizedBox(height: AppSizes.gapXXL),
            
            // 저장 버튼
            _buildSaveButton(),
            const SizedBox(height: AppSizes.gapXL),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textHint,
            ),
          ),
        ],
      ],
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
    return MingrrCard(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          // 이름
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: '이름 *',
              hintText: '강아지 이름을 입력해주세요',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '이름을 입력해주세요';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSizes.gapM),
          
          // 품종
          TextFormField(
            controller: _breedController,
            decoration: const InputDecoration(
              labelText: '품종',
              hintText: '예: 골든 리트리버, 말티즈',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSizes.gapM),
          
          // 성별
          Row(
            children: [
              const Text('성별 *', style: TextStyle(fontSize: 14)),
              const Spacer(),
              SegmentedButton<PetGender>(
                segments: PetGender.values.map((gender) {
                  return ButtonSegment<PetGender>(
                    value: gender,
                    label: Text('${gender.symbol} ${gender.label}'),
                  );
                }).toList(),
                selected: {_selectedGender},
                onSelectionChanged: (Set<PetGender> selection) {
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

  Widget _buildPhysicalInfoSection() {
    return MingrrCard(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          // 체중
          TextFormField(
            controller: _weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: '체중 (kg)',
              hintText: '예: 5.5',
              border: OutlineInputBorder(),
              suffixText: 'kg',
            ),
          ),
          const SizedBox(height: AppSizes.gapM),
          
          // 중성화 여부
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('중성화 여부'),
            subtitle: Text(_isNeutered ? '중성화 완료' : '중성화 안함'),
            value: _isNeutered,
            onChanged: (value) {
              setState(() {
                _isNeutered = value;
              });
            },
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildTraitsSection() {
    return MingrrCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 선택된 특성 수
          Row(
            children: [
              Text(
                '선택됨: ${_selectedTraits.length}개',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _selectedTraits.length >= 5 ? AppColors.success : AppColors.warning,
                ),
              ),
              const Spacer(),
              if (_selectedTraits.length < 5)
                const Text(
                  '최소 5개 선택 필요',
                  style: TextStyle(fontSize: 12, color: AppColors.warning),
                ),
            ],
          ),
          const SizedBox(height: AppSizes.gapM),
          
          // 카테고리별 특성
          ...PetTraitCategory.values.map((category) {
            final traits = PetTrait.values.where((t) => t.category == category).toList();
            return _buildTraitCategory(category, traits);
          }),
        ],
      ),
    );
  }

  Widget _buildTraitCategory(PetTraitCategory category, List<PetTrait> traits) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          category.label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSizes.gapS),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: traits.map((trait) {
            final isSelected = _selectedTraits.contains(trait);
            return FilterChip(
              label: Text(trait.label),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedTraits.add(trait);
                  } else {
                    _selectedTraits.remove(trait);
                  }
                });
              },
              selectedColor: AppColors.primary.withOpacity(0.2),
              checkmarkColor: AppColors.primary,
              labelStyle: TextStyle(
                fontSize: 12,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSizes.gapM),
      ],
    );
  }

  Widget _buildBioSection() {
    return MingrrCard(
      margin: EdgeInsets.zero,
      child: TextFormField(
        controller: _bioController,
        maxLines: 4,
        maxLength: 200,
        decoration: const InputDecoration(
          hintText: '강아지를 소개해주세요\n예: 활발하고 사람을 좋아하는 강아지입니다.',
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildAdditionalInfoSection() {
    return MingrrCard(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          // 혈통서 보유 여부
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('혈통서 보유'),
            subtitle: Text(_hasPedigree ? '혈통서 있음' : '혈통서 없음'),
            value: _hasPedigree,
            onChanged: (value) {
              setState(() {
                _hasPedigree = value;
              });
            },
            activeColor: AppColors.primary,
          ),
          const Divider(),
          
          // 추가 사진
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.photo_library, color: AppColors.primary),
            title: const Text('추가 사진'),
            subtitle: const Text('최대 5장까지 등록 가능'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _pickAdditionalPhotos,
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
        onPressed: _selectedTraits.length >= 5 ? _savePet : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.divider,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusM),
          ),
        ),
        child: Text(
          isEditMode ? '수정 완료' : '등록하기',
          style: const TextStyle(
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

  void _pickAdditionalPhotos() {
    // TODO: 다중 이미지 피커 구현
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('추가 사진 선택 기능 (Firebase Storage 연동 예정)')),
    );
  }

  Future<void> _selectBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime.now().subtract(const Duration(days: 365)),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: '생년월일 선택',
    );
    if (picked != null) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  void _savePet() {
    if (_formKey.currentState!.validate()) {
      if (_selectedTraits.length < 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('특성을 최소 5개 이상 선택해주세요'),
            backgroundColor: AppColors.warning,
          ),
        );
        return;
      }
      
      // TODO: Firebase에 저장
      final petData = {
        'name': _nameController.text,
        'breed': _breedController.text,
        'gender': _selectedGender.name,
        'birthDate': _birthDate,
        'weight': double.tryParse(_weightController.text),
        'isNeutered': _isNeutered,
        'hasPedigree': _hasPedigree,
        'bio': _bioController.text,
        'traits': _selectedTraits.map((t) => t.name).toList(),
      };
      
      debugPrint('Pet data to save: $petData');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditMode ? '반려동물 정보가 수정되었습니다!' : '반려동물이 등록되었습니다!'),
          backgroundColor: AppColors.success,
        ),
      );
      
      Navigator.pop(context, true);
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('반려동물 삭제'),
        content: const Text('정말 삭제하시겠습니까?\n삭제된 정보는 복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Firebase에서 삭제
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('반려동물이 삭제되었습니다'),
                  backgroundColor: AppColors.error,
                ),
              );
              Navigator.pop(context, true);
            },
            child: const Text('삭제', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
