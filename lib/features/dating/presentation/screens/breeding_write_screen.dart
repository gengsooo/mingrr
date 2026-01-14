import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/feature_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/mingrr_bottom_sheet.dart';
import '../../../../core/widgets/pet_selector_card.dart';
import '../../../../models/breeding_model.dart';
import '../../../../models/pet_model.dart';
import '../../../pet/presentation/providers/pet_provider.dart';

/// ============================================================
/// 교배 글쓰기 화면
/// Firebase Firestore와 연동하여 실제 데이터 저장
/// ============================================================

class BreedingWriteScreen extends ConsumerStatefulWidget {
  final BreedingPostModel? post; // 수정 시 기존 글 데이터

  const BreedingWriteScreen({super.key, this.post});

  @override
  ConsumerState<BreedingWriteScreen> createState() => _BreedingWriteScreenState();
}

class _BreedingWriteScreenState extends ConsumerState<BreedingWriteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  PetModel? _selectedPet;
  String? _preferredGender;
  final List<String> _preferredSizes = [];
  bool _sameBreedOnly = false;
  int? _minAge;
  int? _maxAge;
  bool _isLoading = false;

  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseService _firebaseService = FirebaseService();

  bool get _isEditMode => widget.post != null;

  @override
  void initState() {
    super.initState();

    if (_isEditMode) {
      final post = widget.post!;
      _titleController.text = post.title;
      _descriptionController.text = post.description;
      _preferredGender = post.preferredGender;
      _preferredSizes.addAll(post.preferredSizes);
      _sameBreedOnly = post.sameBreedOnly;
      _minAge = post.minAge;
      _maxAge = post.maxAge;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final petsAsync = ref.watch(userPetsProvider);

    return Scaffold(
      backgroundColor: context.detailBackground,
      appBar: AppBar(
        title: Text(_isEditMode ? '교배 글 수정' : '교배 글쓰기'),
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
              // 교배할 강아지 선택
              const Text('교배할 강아지', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSizes.gapS),
              _buildPetSelector(petsAsync),
              const SizedBox(height: AppSizes.gapXL),

              // 제목
              MingrrTextField(
                controller: _titleController,
                labelText: '제목',
                hintText: '제목을 입력해주세요',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '제목을 입력해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSizes.gapL),

              // 상세 내용
              MingrrTextField(
                controller: _descriptionController,
                labelText: '상세 내용',
                hintText: '상세 내용을 입력해주세요',
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '상세 내용을 입력해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSizes.gapXL),

              // 원하는 상대 성별
              const Text('원하는 상대 성별', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSizes.gapS),
              _buildGenderSelector(),
              const SizedBox(height: AppSizes.gapL),

              // 원하는 상대 크기
              const Text('원하는 상대 크기 (중복 선택 가능)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSizes.gapS),
              _buildSizeSelector(),
              const SizedBox(height: AppSizes.gapL),

              // 같은 품종만
              _buildSameBreedSwitch(),
              const SizedBox(height: AppSizes.gapL),

              // 나이 범위
              const Text('원하는 상대 나이', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSizes.gapS),
              _buildAgeSelector(),
              const SizedBox(height: AppSizes.gapXXL),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomButton(),
    );
  }

  Widget _buildPetSelector(AsyncValue<List<PetModel>> petsAsync) {
    return petsAsync.when(
      data: (pets) {
        // 수정 모드일 때 기존 선택된 펫 찾기
        if (_isEditMode && _selectedPet == null && pets.isNotEmpty) {
          _selectedPet = pets.firstWhere(
            (p) => p.id == widget.post!.petId,
            orElse: () => pets.first,
          );
        }

        return GestureDetector(
          onTap: () => _showPetSelectorSheet(pets),
          child: _selectedPet != null
              ? PetSelectorCard(
                  pet: _selectedPet!,
                  isSelected: true,
                  accentColor: context.features.dating,
                )
              : Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.inputBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).colorScheme.outline),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.pets, size: 20, color: Theme.of(context).colorScheme.outlineVariant),
                      const SizedBox(width: 12),
                      Text('강아지를 선택해주세요', style: TextStyle(color: Theme.of(context).colorScheme.outlineVariant)),
                      const Spacer(),
                      Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.outlineVariant),
                    ],
                  ),
                ),
        );
      },
      loading: () => const MingrrLoadingState(),
      error: (_, __) => const Text('강아지 목록을 불러올 수 없습니다'),
    );
  }

  void _showPetSelectorSheet(List<PetModel> pets) {
    showPetSelectorSheet(
      context,
      pets: pets,
      selectedPet: _selectedPet,
      title: '교배할 강아지 선택',
      description: '교배 글에 등록할 강아지를 선택해주세요',
      accentColor: context.features.dating,
      onSelect: (pet) {
        setState(() => _selectedPet = pet);
      },
    );
  }

  Widget _buildGenderSelector() {
    final genders = [
      (value: null, label: '무관', icon: null as IconData?),
      (value: 'male', label: '남아', icon: Icons.male as IconData?),
      (value: 'female', label: '여아', icon: Icons.female as IconData?),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: genders.map((gender) {
        final isSelected = _preferredGender == gender.value;
        return GestureDetector(
          onTap: () => setState(() => _preferredGender = gender.value),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? context.features.dating : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? context.features.dating : Theme.of(context).colorScheme.outline,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (gender.icon != null) ...[
                  Icon(gender.icon, size: 16, color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                ],
                Text(
                  gender.label,
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

  Widget _buildSizeSelector() {
    final sizes = [
      (value: 'tiny', label: '초소형 (0~4kg)'),
      (value: 'small', label: '소형 (4~10kg)'),
      (value: 'medium', label: '중형 (10~25kg)'),
      (value: 'large', label: '대형 (25~45kg)'),
      (value: 'giant', label: '초대형 (45kg~)'),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: sizes.map((size) {
        final isSelected = _preferredSizes.contains(size.value);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _preferredSizes.remove(size.value);
              } else {
                _preferredSizes.add(size.value);
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? context.features.dating : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? context.features.dating : Theme.of(context).colorScheme.outline,
              ),
            ),
            child: Text(
              size.label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSameBreedSwitch() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.inputBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('같은 품종만', style: TextStyle(fontWeight: FontWeight.w500)),
              Text('같은 품종의 상대만 원해요', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          ),
          Switch(
            value: _sameBreedOnly,
            onChanged: (value) => setState(() => _sameBreedOnly = value),
            activeColor: Colors.white,
            activeTrackColor: context.features.dating,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Theme.of(context).colorScheme.outlineVariant,
            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
          ),
        ],
      ),
    );
  }

  Widget _buildAgeSelector() {
    final ages = [
      (value: null, label: '무관'),
      (value: 3, label: '~3살'),
      (value: 5, label: '~5살'),
      (value: 10, label: '~10살'),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ages.map((age) {
        final isSelected = _maxAge == age.value;
        return GestureDetector(
          onTap: () => setState(() => _maxAge = age.value),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? context.features.dating : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? context.features.dating : Theme.of(context).colorScheme.outline,
              ),
            ),
            child: Text(
              age.label,
              style: TextStyle(
                fontSize: 13,
                color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomButton() {
    return MingrrSubmitButtonBar(
      label: _isEditMode ? '수정' : '등록',
      onPressed: _onSubmit,
      isLoading: _isLoading,
      backgroundColor: context.features.dating,
    );
  }

  Future<void> _onSubmit() async {
    if (_selectedPet == null) {
      MingrrSnackBar.warning(context, '교배할 강아지를 선택해주세요');
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final currentUser = _firebaseService.currentUser;
      if (currentUser == null) {
        throw Exception('로그인이 필요합니다');
      }

      final now = DateTime.now();

      final post = BreedingPostModel(
        id: _isEditMode ? widget.post!.id : const Uuid().v4(),
        userId: currentUser.uid,
        petId: _selectedPet!.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        status: _isEditMode ? widget.post!.status : BreedingStatus.active,
        preferredGender: _preferredGender,
        preferredSizes: _preferredSizes,
        sameBreedOnly: _sameBreedOnly,
        minAge: _minAge,
        maxAge: _maxAge,
        viewCount: _isEditMode ? widget.post!.viewCount : 0,
        likeCount: _isEditMode ? widget.post!.likeCount : 0,
        chatCount: _isEditMode ? widget.post!.chatCount : 0,
        createdAt: _isEditMode ? widget.post!.createdAt : now,
        updatedAt: now,
      );

      if (_isEditMode) {
        await _firestoreService.updateBreedingPost(post);
      } else {
        await _firestoreService.createBreedingPost(post);
      }

      if (mounted) {
        Navigator.pop(context, true);
        MingrrSnackBar.success(context, _isEditMode ? '교배 글이 수정되었습니다' : '교배 글이 등록되었습니다 🐶');
      }
    } catch (e) {
      if (mounted) {
        MingrrSnackBar.error(context, '오류가 발생했습니다: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
