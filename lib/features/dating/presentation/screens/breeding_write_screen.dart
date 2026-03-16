import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/theme/feature_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/form_strings.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/sheets/mingrr_bottom_sheet.dart';
import '../../../../core/widgets/forms/form_components.dart';
import '../../../../core/widgets/cards/pet_selector_card.dart';
import '../../../../models/breeding_model.dart';
import '../../../../models/pet_model.dart';
import '../../../../core/providers/refresh_notifier.dart';
import '../../../pet/presentation/providers/pet_provider.dart';
import '../../../../core/utils/error_handler.dart';

/// ============================================================
/// 교배 등록 화면
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

  FirestoreService get _firestoreService => ref.read(firestoreServiceProvider);
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
      appBar: MingrrAppBar.form(
        title: _isEditMode ? ScreenTitles.breedingEdit : ScreenTitles.breedingWrite,
        onClose: () => Navigator.pop(context),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.paddingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 교배할 반려동물 선택
              const MingrrSectionLabel('교배할 반려동물'),
              _buildPetSelector(petsAsync),
              const SizedBox(height: AppSizes.gapXL),

              // 제목
              MingrrTextField(
                controller: _titleController,
                labelText: FormStrings.labelTitle,
                hintText: FormStrings.hintTitle,
                validator: (value) {
                  if (value == null || value.isEmpty) return FormStrings.errorTitleRequired;
                  return null;
                },
              ),
              const SizedBox(height: AppSizes.gapL),

              // 상세 내용
              MingrrTextField(
                controller: _descriptionController,
                labelText: FormStrings.labelDescription,
                hintText: FormStrings.hintDescription,
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) return FormStrings.errorContentRequired;
                  return null;
                },
              ),
              const SizedBox(height: AppSizes.gapXL),

              // 원하는 상대 성별
              const MingrrSectionLabel('원하는 상대 성별'),
              _buildGenderSelector(),
              const SizedBox(height: AppSizes.gapL),

              // 원하는 상대 크기
              const MingrrSectionLabel('원하는 상대 크기', suffix: '(중복 선택 가능)'),
              _buildSizeSelector(),
              const SizedBox(height: AppSizes.gapL),

              // 같은 품종만
              MingrrSwitchCard(
                accentColor: context.features.dating,
                items: [
                  MingrrSwitchItem(
                    title: SwitchStrings.sameBreedOnly,
                    subtitle: SwitchStrings.sameBreedOnlyDesc,
                    value: _sameBreedOnly,
                    onChanged: (value) => setState(() => _sameBreedOnly = value),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.gapL),
              
              // 선택된 반려동물 혈통서 정보 표시
              if (_selectedPet != null)
                _buildPedigreeInfo(),

              // 나이 범위
              const MingrrSectionLabel('원하는 상대 나이'),
              _buildAgeSelector(),
              const SizedBox(height: AppSizes.gapXXL),
            ],
          ),
        ),
      ),
      bottomNavigationBar: MingrrSubmitButtonBar(
        label: _isEditMode ? FormStrings.edit : FormStrings.submit,
        onPressed: _onSubmit,
        isLoading: _isLoading,
        backgroundColor: context.features.dating,
      ),
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
                  padding: const EdgeInsets.all(AppSizes.paddingM),
                  decoration: BoxDecoration(
                    color: context.inputBackground,
                    borderRadius: BorderRadius.circular(AppSizes.radiusS),
                    border: Border.all(color: Theme.of(context).colorScheme.outline),
                  ),
                  child: Row(
                    children: [
                      Icon(AppIcons.pet, size: 20, color: Theme.of(context).colorScheme.outlineVariant),
                      const SizedBox(width: AppSizes.gapM),
                      Text('반려동물을 선택해주세요', style: TextStyle(color: Theme.of(context).colorScheme.outlineVariant)),
                      const Spacer(),
                      Icon(AppIcons.chevronRight, color: Theme.of(context).colorScheme.outlineVariant),
                    ],
                  ),
                ),
        );
      },
      loading: () => const MingrrLoadingState(type: MingrrLoadingType.dating, message: '반려동물 정보를 불러오고 있어요'),
      error: (_, _) => const Text('일시적인 오류가 발생했어요'),
    );
  }

  void _showPetSelectorSheet(List<PetModel> pets) {
    showPetSelectorSheet(
      context,
      pets: pets,
      selectedPet: _selectedPet,
      title: '교배할 반려동물 선택',
      description: '교배 글에 등록할 반려동물을 선택해주세요',
      accentColor: context.features.dating,
      onSelect: (pet) {
        setState(() => _selectedPet = pet);
      },
    );
  }

  Widget _buildGenderSelector() {
    final genders = [
      (value: null as String?, label: '무관', icon: null as IconData?),
      (value: 'male' as String?, label: '남아', icon: AppIcons.male as IconData?),
      (value: 'female' as String?, label: '여아', icon: AppIcons.female as IconData?),
    ];

    return MingrrChipSelector<({String? value, String label, IconData? icon})>(
      items: genders,
      selectedItem: genders.firstWhere((g) => g.value == _preferredGender, orElse: () => genders.first),
      onSelected: (gender) => setState(() => _preferredGender = gender.value),
      labelBuilder: (gender) => gender.label,
      iconBuilder: (gender) => gender.icon,
      accentColor: context.features.dating,
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

    return MingrrChipSelector<({String value, String label})>(
      items: sizes,
      selectedItems: sizes.where((s) => _preferredSizes.contains(s.value)).toSet(),
      onSelected: (size) {
        setState(() {
          if (_preferredSizes.contains(size.value)) {
            _preferredSizes.remove(size.value);
          } else {
            _preferredSizes.add(size.value);
          }
        });
      },
      labelBuilder: (size) => size.label,
      accentColor: context.features.dating,
      multiSelect: true,
    );
  }

  Widget _buildAgeSelector() {
    final ages = [
      (value: null as int?, label: '무관'),
      (value: 3 as int?, label: '~3살'),
      (value: 5 as int?, label: '~5살'),
      (value: 10 as int?, label: '~10살'),
    ];

    return MingrrChipSelector<({int? value, String label})>(
      items: ages,
      selectedItem: ages.firstWhere((a) => a.value == _maxAge, orElse: () => ages.first),
      onSelected: (age) => setState(() => _maxAge = age.value),
      labelBuilder: (age) => age.label,
      accentColor: context.features.dating,
    );
  }

  /// 선택된 반려동물의 혈통서 정보 표시
  Widget _buildPedigreeInfo() {
    final hasPedigree = _selectedPet?.hasPedigree ?? false;
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSizes.paddingM),
          decoration: BoxDecoration(
            color: hasPedigree 
                ? context.features.dating.withValues(alpha: AppOpacity.o10)
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppSizes.radiusS),
            border: Border.all(
              color: hasPedigree 
                  ? context.features.dating.withValues(alpha: AppOpacity.o30)
                  : colorScheme.outline.withValues(alpha: AppOpacity.o30),
            ),
          ),
          child: Row(
            children: [
              Icon(
                hasPedigree ? AppIcons.verified : AppIcons.info,
                size: 20,
                color: hasPedigree ? context.features.dating : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSizes.gapM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasPedigree ? '혈통서 보유' : '혈통서 미보유',
                      style: AppTextStyles.titleMedium(context).withWeight(FontWeight.w600).withColor(
                        hasPedigree ? context.features.dating : colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSizes.gapXXS),
                    Text(
                      hasPedigree 
                          ? '${_selectedPet!.name}의 혈통서가 등록되어 있어요'
                          : '반려동물 정보에서 혈통서를 등록할 수 있어요',
                      style: AppTextStyles.bodySmall(context).withColor(colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.gapL),
      ],
    );
  }

  Future<void> _onSubmit() async {
    if (_selectedPet == null) {
      MingrrSnackBar.warning(context, '교배할 반려동물을 선택해주세요');
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
        authorId: currentUser.uid,
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
        // 리스트 새로고침 트리거
        ref.read(datingRefreshProvider.notifier).state++;
        Navigator.pop(context, true);
        MingrrSnackBar.success(context, _isEditMode ? FormStrings.successUpdated : FormStrings.successCreated);
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e, tag: 'BreedingWrite', operation: '교배 등록');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
