import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/pet_constants.dart';
import '../../../../core/services/image_crop_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/dialogs/dialogs.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/widgets/image_picker_sheet.dart';
import '../../../../models/pet_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../pet/data/pet_repository.dart';
import '../../../pet/presentation/providers/pet_provider.dart';

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
  final String? petId; // null이면 신규 추가, 값이 있으면 수정 모드
  
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
  
  bool _isLoading = false;
  bool _isDataLoaded = false;
  PetModel? _existingPet;
  
  final ImagePicker _imagePicker = ImagePicker();
  final StorageService _storageService = StorageService();
  
  // 프로필 이미지 관련
  XFile? _selectedProfileImage;
  String? _profileImageUrl;
  DefaultAvatar? _selectedDefaultAvatar;
  
  // 추가 사진 관련 (최대 5장, 첫 번째가 대표사진)
  List<XFile> _selectedAdditionalPhotos = [];
  List<String> _additionalPhotoUrls = [];
  
  bool get isEditMode => widget.petId != null;
  
  @override
  void initState() {
    super.initState();
    if (isEditMode) {
      _loadPetData();
    }
  }
  
  Future<void> _loadPetData() async {
    if (_isDataLoaded || widget.petId == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      final petRepository = PetRepository();
      final pet = await petRepository.getPetById(widget.petId!);
      
      if (pet != null && mounted) {
        _existingPet = pet;
        _nameController.text = pet.name;
        _breedController.text = pet.breed ?? '';
        _weightController.text = pet.weight?.toString() ?? '';
        _bioController.text = pet.bio ?? '';
        _selectedGender = pet.gender;
        _birthDate = pet.birthDate;
        _isNeutered = pet.isNeutered;
        _hasPedigree = pet.hasPedigree;
        _selectedTraits.addAll(pet.traits);
        _profileImageUrl = pet.profileImageUrl;
        _additionalPhotoUrls = List.from(pet.photoUrls);
        _isDataLoaded = true;
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        MingrrSnackBar.error(context, '데이터 로드 실패: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          if (isEditMode && !_isLoading)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: _showDeleteConfirmation,
            ),
        ],
      ),
      body: _isLoading && isEditMode && !_isDataLoaded
          ? const MingrrLoadingState()
          : Form(
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
      child: GestureDetector(
        onTap: _showProfileImagePicker,
        child: Stack(
          children: [
            // 프로필 이미지 표시
            _buildProfileImageWidget(),
            // 카메라 아이콘
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
    
    // 기본 이미지
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
        Icons.pets,
        size: 60,
        color: AppColors.primary,
      ),
    );
  }
  
  Future<void> _showProfileImagePicker() async {
    final result = await showImagePickerSheet(
      context,
      title: '프로필 이미지 선택',
      avatarType: DefaultAvatarType.pet,
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
          // 이름
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: '이름',
              hintText: '반려동물 이름을 입력해주세요',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '반려동물 이름을 입력해주세요';
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
              const Text('성별', style: TextStyle(fontSize: 14)),
              const Spacer(),
              SegmentedButton<PetGender>(
                segments: PetGender.values.map((gender) {
                  return ButtonSegment<PetGender>(
                    value: gender,
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(gender.icon, size: 16),
                        const SizedBox(width: 4),
                        Text(gender.label),
                      ],
                    ),
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
          const Text('생년월일', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          MingrrDateSelector(
            date: _birthDate,
            onSelect: (d) => setState(() => _birthDate = d),
            isBirthDate: true,
            birthDateMinYear: 2000,
            label: _birthDate != null ? null : '선택해주세요',
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
              selectedColor: AppColors.background,
              checkmarkColor: AppColors.primary,
              labelStyle: TextStyle(
                fontSize: 12,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
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
          hintText: '반려동물을 소개해주세요\n예: 활발하고 사람을 좋아하는 아이입니다.',
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildAdditionalInfoSection() {
    return MingrrCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const SizedBox(height: AppSizes.gapM),
          
          // 추가 사진 섹션
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '추가 사진',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Text(
                '${_getTotalPhotoCount()}/5장',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.gapS),
          const Text(
            '길게 누르고 드래그하여 순서를 변경하세요. 가장 왼쪽 사진이 대표사진으로 사용됩니다.',
            style: TextStyle(fontSize: 11, color: AppColors.textHint),
          ),
          const SizedBox(height: AppSizes.gapM),
          
          // 사진 리스트 (드래그 가능)
          _buildDraggablePhotoList(),
        ],
      ),
    );
  }
  
  int _getTotalPhotoCount() {
    return _additionalPhotoUrls.length + _selectedAdditionalPhotos.length;
  }
  
  /// 드래그 가능한 사진 리스트 (첫 번째가 대표사진)
  Widget _buildDraggablePhotoList() {
    final totalPhotos = _getTotalPhotoCount();
    final canAddMore = totalPhotos < 5;
    
    // 모든 사진을 하나의 리스트로 통합 (URL + XFile)
    final List<dynamic> allPhotos = [
      ..._additionalPhotoUrls,
      ..._selectedAdditionalPhotos,
    ];
    
    return SizedBox(
      height: 90,
      child: Row(
        children: [
          // 드래그 가능한 사진 리스트
          Expanded(
            child: ReorderableListView.builder(
              scrollDirection: Axis.horizontal,
              buildDefaultDragHandles: false,
              itemCount: allPhotos.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  
                  // URL과 로컬 파일(XFile)을 분리하여 처리
                  final urlCount = _additionalPhotoUrls.length;
                  
                  if (oldIndex < urlCount && newIndex < urlCount) {
                    // 둘 다 서버 URL인 경우
                    final item = _additionalPhotoUrls.removeAt(oldIndex);
                    _additionalPhotoUrls.insert(newIndex, item);
                  } else if (oldIndex >= urlCount && newIndex >= urlCount) {
                    // 둘 다 로컬 파일(XFile)인 경우
                    final xOld = oldIndex - urlCount;
                    final xNew = newIndex - urlCount;
                    final item = _selectedAdditionalPhotos.removeAt(xOld);
                    _selectedAdditionalPhotos.insert(xNew, item);
                  } else {
                    // URL과 로컬 파일 간 이동 - 전체 리스트로 처리
                    final item = allPhotos.removeAt(oldIndex);
                    allPhotos.insert(newIndex, item);
                    
                    // 다시 분리
                    _additionalPhotoUrls.clear();
                    _selectedAdditionalPhotos.clear();
                    for (final photo in allPhotos) {
                      if (photo is String) {
                        _additionalPhotoUrls.add(photo);
                      } else if (photo is XFile) {
                        _selectedAdditionalPhotos.add(photo);
                      }
                    }
                  }
                });
              },
              itemBuilder: (context, index) {
                final isPrimary = index == 0;
                final photo = allPhotos[index];
                final isUrl = photo is String;
                
                return ReorderableDragStartListener(
                  key: ValueKey('photo_$index'),
                  index: index,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildDraggablePhotoItem(
                      index: index,
                      isPrimary: isPrimary,
                      isUrl: isUrl,
                      imageUrl: isUrl ? photo : null,
                      imageFile: isUrl ? null : photo as XFile,
                    ),
                  ),
                );
              },
            ),
          ),
          
          // 추가 버튼
          if (canAddMore) _buildAddPhotoButton(),
        ],
      ),
    );
  }
  
  Widget _buildDraggablePhotoItem({
    required int index,
    required bool isPrimary,
    required bool isUrl,
    String? imageUrl,
    XFile? imageFile,
  }) {
    return Stack(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isPrimary ? AppColors.primary : AppColors.divider,
              width: isPrimary ? 3 : 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: isUrl
                ? Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                  )
                : kIsWeb
                    ? Image.network(imageFile!.path, fit: BoxFit.cover)
                    : Image.file(File(imageFile!.path), fit: BoxFit.cover),
          ),
        ),
        // 대표사진 표시
        if (isPrimary)
          Positioned(
            top: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.star, size: 14, color: Colors.white),
            ),
          ),
        // 삭제 버튼
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _deletePhotoAt(index),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildAddPhotoButton() {
    return GestureDetector(
      onTap: _pickAdditionalPhotos,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate, color: AppColors.primary, size: 28),
            SizedBox(height: 4),
            Text(
              '추가',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
  
  void _deletePhotoAt(int index) {
    showConfirmSheet(
      context,
      type: ConfirmSheetType.photoDelete,
      onConfirm: () {
        setState(() {
          final urlCount = _additionalPhotoUrls.length;
          if (index < urlCount) {
            _additionalPhotoUrls.removeAt(index);
          } else {
            _selectedAdditionalPhotos.removeAt(index - urlCount);
          }
        });
      },
    );
  }

  Widget _buildSaveButton() {
    final canSubmit = _selectedTraits.length >= 5 && !_isLoading;
    
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: canSubmit ? _savePet : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.divider,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusM),
          ),
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

  Future<void> _pickProfileImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (image != null) {
        // 웹에서는 크롭 미지원, 모바일에서만 크롭 적용
        if (!kIsWeb) {
          final croppedPath = await ImageCropService().cropImage(
            imagePath: image.path,
            style: ImageCropStyle.circle,
            context: context,
            maxWidth: 800,
            maxHeight: 800,
            compressQuality: 85,
          );
          
          if (croppedPath != null) {
            setState(() {
              _selectedProfileImage = XFile(croppedPath);
            });
            return;
          }
        }
        
        // 웹이거나 크롭 취소 시 원본 사용
        setState(() {
          _selectedProfileImage = image;
        });
      }
    } catch (e) {
      if (mounted) {
        MingrrSnackBar.error(context, '이미지 선택 실패: $e');
      }
    }
  }

  Future<void> _pickAdditionalPhotos() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (images.isNotEmpty) {
        // 웹에서는 크롭 미지원, 모바일에서만 크롭 적용
        if (!kIsWeb) {
          final List<XFile> croppedImages = [];
          for (final image in images) {
            final croppedPath = await ImageCropService().cropImage(
              imagePath: image.path,
              style: ImageCropStyle.square,
              context: context,
              maxWidth: 800,
              maxHeight: 800,
              compressQuality: 85,
            );
            
            if (croppedPath != null) {
              croppedImages.add(XFile(croppedPath));
            }
          }
          
          if (croppedImages.isNotEmpty) {
            setState(() {
              _selectedAdditionalPhotos.addAll(croppedImages);
            });
            return;
          }
        }
        
        // 웹이거나 크롭 취소 시 원본 사용
        setState(() {
          _selectedAdditionalPhotos.addAll(images);
        });
      }
    } catch (e) {
      if (mounted) {
        MingrrSnackBar.error(context, '이미지 선택 실패: $e');
      }
    }
  }
  
  Future<String?> _uploadProfileImage(String petId) async {
    // 대표 아이콘을 선택한 경우 - 아이콘 ID를 URL로 저장
    if (_selectedDefaultAvatar != null) {
      return 'default_avatar:${_selectedDefaultAvatar!.id}';
    }
    
    // 새로 선택한 이미지가 없으면 기존 URL 반환
    if (_selectedProfileImage == null) return _profileImageUrl;
    
    if (kIsWeb) {
      // 웹에서는 bytes로 업로드
      try {
        final bytes = await _selectedProfileImage!.readAsBytes();
        final url = await _storageService.uploadDogImageBytes(petId, 'profile.jpg', bytes);
        return url;
      } catch (e) {
        throw Exception('프로필 이미지 업로드 실패: $e');
      }
    }
    
    try {
      final file = File(_selectedProfileImage!.path);
      final url = await _storageService.uploadDogImage(petId, 'profile.jpg', file);
      return url;
    } catch (e) {
      throw Exception('프로필 이미지 업로드 실패: $e');
    }
  }
  
  Future<List<String>> _uploadAdditionalPhotos(String petId) async {
    if (_selectedAdditionalPhotos.isEmpty) return _additionalPhotoUrls;
    
    final List<String> uploadedUrls = List.from(_additionalPhotoUrls);
    
    if (kIsWeb) {
      // 웹에서는 bytes로 업로드
      try {
        for (int i = 0; i < _selectedAdditionalPhotos.length; i++) {
          final bytes = await _selectedAdditionalPhotos[i].readAsBytes();
          final url = await _storageService.uploadDogImageBytes(
            petId, 
            'photo_${DateTime.now().millisecondsSinceEpoch}_$i.jpg', 
            bytes,
          );
          uploadedUrls.add(url);
        }
        return uploadedUrls;
      } catch (e) {
        throw Exception('추가 이미지 업로드 실패: $e');
      }
    }
    
    try {
      final files = _selectedAdditionalPhotos.map((x) => File(x.path)).toList();
      final urls = await _storageService.uploadDogImages(petId, files);
      return [..._additionalPhotoUrls, ...urls];
    } catch (e) {
      throw Exception('추가 이미지 업로드 실패: $e');
    }
  }


  Future<void> _savePet() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedTraits.length < 5) {
        MingrrSnackBar.warning(context, '특성을 최소 5개 이상 선택해주세요');
        return;
      }
      
      setState(() => _isLoading = true);
      
      try {
        final currentUser = ref.read(authStateProvider).valueOrNull;
        if (currentUser == null) {
          throw Exception('로그인이 필요합니다');
        }
        
        final petRepository = PetRepository();
        final now = DateTime.now();
        
        // 기존 반려동물이 있는지 확인 (첫 번째 반려동물이면 isPrimary = true)
        final existingPets = await petRepository.getAllPets();
        final userPets = existingPets.where((p) => p.ownerId == currentUser.uid).toList();
        final isFirstPet = userPets.isEmpty;
        
        final petId = isEditMode ? widget.petId! : const Uuid().v4();
        
        // 이미지 업로드
        final uploadedProfileUrl = await _uploadProfileImage(petId);
        final uploadedPhotoUrls = await _uploadAdditionalPhotos(petId);
        
        final pet = PetModel(
          id: petId,
          ownerId: currentUser.uid,
          isPrimary: isEditMode ? (_existingPet?.isPrimary ?? isFirstPet) : isFirstPet,
          name: _nameController.text.trim(),
          breed: _breedController.text.trim().isEmpty ? null : _breedController.text.trim(),
          gender: _selectedGender,
          birthDate: _birthDate,
          weight: double.tryParse(_weightController.text),
          isNeutered: _isNeutered,
          hasPedigree: _hasPedigree,
          bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
          traits: _selectedTraits.toList(),
          profileImageUrl: uploadedProfileUrl,
          photoUrls: uploadedPhotoUrls,
          createdAt: isEditMode ? (_existingPet?.createdAt ?? now) : now,
          updatedAt: now,
        );
        
        if (isEditMode) {
          await petRepository.updatePet(pet);
        } else {
          await petRepository.createPet(pet);
        }
        
        // 상태 관리 새로고침
        ref.invalidate(userPetsProvider);
        
        if (mounted) {
          MingrrSnackBar.success(context, isEditMode ? '반려동물 정보가 수정되었습니다!' : '반려동물이 등록되었습니다!');
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ErrorHandler.handle(
            context,
            error: e,
            tag: 'PetEdit',
            operation: '반려동물 저장',
            themeColor: AppColors.primary,
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showDeleteConfirmation() {
    showConfirmSheet(
      context,
      type: ConfirmSheetType.petDelete,
      onConfirm: _deletePet,
    );
  }
  
  Future<void> _deletePet() async {
    if (widget.petId == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      final petRepository = PetRepository();
      await petRepository.deletePet(widget.petId!);
      
      // Provider 리프레시
      ref.invalidate(userPetsProvider);
      
      if (mounted) {
        MingrrSnackBar.success(context, '반려동물이 삭제되었습니다');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.handle(
          context,
          error: e,
          tag: 'PetEdit',
          operation: '반려동물 삭제',
          themeColor: AppColors.primary,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
