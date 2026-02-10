import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/feature_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/form_strings.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../core/services/image_service.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/sheets/mingrr_bottom_sheet.dart';
import '../../../../core/widgets/dialogs/dialogs.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/widgets/map/map_widgets.dart';
import '../../../../core/widgets/forms/form_components.dart';
import '../../../../core/models/location_model.dart';
import '../../../../models/marketplace_model.dart';
import '../../../../models/pet_model.dart';
import '../../../../core/providers/refresh_notifier.dart';
import '../../../pet/presentation/providers/pet_provider.dart';
import '../../../../core/widgets/cards/pet_selector_card.dart';

/// ============================================================
/// 마켓 상품 등록/수정 화면
/// Firebase Firestore와 연동하여 실제 데이터 저장
/// ============================================================

class ProductWriteScreen extends ConsumerStatefulWidget {
  final ProductModel? product; // 수정 시 기존 상품 데이터
  final ProductType initialType;

  const ProductWriteScreen({
    super.key,
    this.product,
    this.initialType = ProductType.sell,
  });

  @override
  ConsumerState<ProductWriteScreen> createState() => _ProductWriteScreenState();
}

class _ProductWriteScreenState extends ConsumerState<ProductWriteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  late ProductType _selectedType;
  ProductCategory? _selectedCategory = ProductCategory.food;
  final List<XFile> _selectedImages = [];
  final List<String> _existingImageUrls = [];
  bool _isLoading = false;
  
  // 알바 전용 필드
  JobType _selectedJobType = JobType.care;
  String _priceUnit = '회';
  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isTimeFlexible = false;
  final List<String> _selectedPetIds = [];
  
  // 희망지역 (판매/나눔)
  LocationData? _selectedLocation;
  
  // 알바 지역
  LocationData? _selectedJobLocation;

  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseService _firebaseService = FirebaseService();

  bool get _isEditMode => widget.product != null;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.product?.type ?? widget.initialType;
    
    if (_isEditMode) {
      final product = widget.product!;
      _titleController.text = product.title;
      _priceController.text = product.price > 0 ? formatPrice(product.price) : '';
      _descriptionController.text = product.description;
      _selectedCategory = product.category;
      _existingImageUrls.addAll(product.imageUrls);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isShare = _selectedType == ProductType.share;
    final isJob = _selectedType == ProductType.job;

    return Scaffold(
      backgroundColor: context.detailBackground,
      appBar: MingrrFormAppBar(
        title: _isEditMode ? ScreenTitles.productEdit : ScreenTitles.productWrite,
        onClose: () => Navigator.pop(context),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.paddingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 종류 선택 (판매/나눔/알바)
              const MingrrSectionLabel(FormStrings.labelType),
              Row(
                children: [
                  _buildTypeButton(ProductType.sell, '판매', AppIcons.sell),
                  const SizedBox(width: AppSizes.gapS),
                  _buildTypeButton(ProductType.share, '나눔', AppIcons.gift),
                  const SizedBox(width: AppSizes.gapS),
                  _buildTypeButton(ProductType.job, '알바', AppIcons.work),
                ],
              ),
              const SizedBox(height: AppSizes.gapXL),

              // === 알바 전용 UI ===
              if (isJob) ...[
                // 사진 (선택)
                MingrrSectionLabel(
                  '${FormStrings.labelPhoto} (${FormStrings.optional})',
                  suffix: '(최대 ${ImageLimits.maxImageCount}장)',
                ),
                MingrrImagePicker(
                  existingUrls: _existingImageUrls,
                  selectedFiles: _selectedImages,
                  onPickImages: _pickImages,
                  onRemoveExisting: (index) => setState(() => _existingImageUrls.removeAt(index)),
                  onRemoveSelected: (index) => setState(() => _selectedImages.removeAt(index)),
                  maxImages: ImageLimits.maxImageCount,
                ),
                const SizedBox(height: AppSizes.gapXL),
                
                // 알바 유형
                const MingrrSectionLabel('알바 유형'),
                _buildJobTypeSelector(),
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

                // 기간
                const MingrrSectionLabel('기간'),
                _buildDateSelector(),
                const SizedBox(height: AppSizes.gapL),

                // 돌봄 대상 반려동물
                const MingrrSectionLabel('돌봄 대상 반려동물'),
                _buildPetSelector(),
                const SizedBox(height: AppSizes.gapL),

                // 급여
                const MingrrSectionLabel('급여'),
                _buildPriceUnitSelector(),
                const SizedBox(height: AppSizes.gapS),
                _buildJobPriceField(),
                const SizedBox(height: AppSizes.gapL),

                // 근무 지역
                const MingrrSectionLabel('근무 지역'),
                _buildLocationSelector(),
                const SizedBox(height: AppSizes.gapL),

                // 상세 설명
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
                const SizedBox(height: AppSizes.gapXXL),
              ]
              // === 판매/나눔 UI ===
              else ...[
                // 사진
                MingrrSectionLabel(
                  FormStrings.labelPhoto,
                  suffix: '(최대 ${ImageLimits.maxImageCount}장)',
                ),
                MingrrImagePicker(
                  existingUrls: _existingImageUrls,
                  selectedFiles: _selectedImages,
                  onPickImages: _pickImages,
                  onRemoveExisting: (index) => setState(() => _existingImageUrls.removeAt(index)),
                  onRemoveSelected: (index) => setState(() => _selectedImages.removeAt(index)),
                  maxImages: ImageLimits.maxImageCount,
                ),
                const SizedBox(height: AppSizes.gapXL),

                // 카테고리
                const MingrrSectionLabel(FormStrings.labelCategory),
                _buildCategorySelector(),
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

                // 가격 (판매일 때만)
                if (!isShare) ...[
                  _buildPriceField(),
                  const SizedBox(height: AppSizes.gapL),
                ],

                // 희망지역
                const MingrrSectionLabel('희망지역'),
                _buildLocationSelector(),
                const SizedBox(height: AppSizes.gapL),

                // 설명
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
                const SizedBox(height: AppSizes.gapXXL),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomButton(),
    );
  }

  Widget _buildTypeButton(ProductType type, String label, IconData icon) {
    final isSelected = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTypeChanged(type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingM),
          decoration: BoxDecoration(
            color: isSelected ? context.features.market : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSizes.radiusS),
            border: Border.all(
              color: isSelected ? context.features.market : Theme.of(context).colorScheme.outline,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(width: AppSizes.gapSM),
              Text(
                label,
                style: AppTextStyles.titleMedium(context).withWeight(FontWeight.w600).withColor(
                  isSelected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 입력된 정보가 있는지 확인
  bool get _hasInputData {
    return _titleController.text.isNotEmpty ||
           _priceController.text.isNotEmpty ||
           _descriptionController.text.isNotEmpty ||
           _selectedImages.isNotEmpty ||
           _selectedCategory != null ||
           _selectedPetIds.isNotEmpty ||
           _startDate != null ||
           _endDate != null;
  }

  /// 종류 변경 처리 (입력된 정보가 있으면 확인 다이얼로그 표시)
  void _onTypeChanged(ProductType newType) async {
    if (newType == _selectedType) return;
    
    // 입력된 내용이 있는 경우 확인
    if (_hasInputData) {
      final newTypeLabel = switch (newType) {
        ProductType.sell => '판매',
        ProductType.share => '나눔',
        ProductType.job => '알바',
      };
      
      final confirmed = await showConfirmSheetWithResult(
        context,
        type: ConfirmSheetType.productTypeChange,
        message: '$newTypeLabel 등록으로 변경합니다.\n현재 입력된 정보가 초기화됩니다.\n계속하시겠습니까?',
      );
      
      if (confirmed != true) return;
      
      // 종류 변경 시 입력 정보 초기화
      _titleController.clear();
      _priceController.clear();
      _descriptionController.clear();
      _selectedImages.clear();
      _selectedCategory = null;
      _selectedJobType = JobType.care;
      _priceUnit = '회';
      _startDate = null;
      _endDate = null;
      _selectedPetIds.clear();
    }
    
    setState(() => _selectedType = newType);
  }

  Widget _buildCategorySelector() {
    return MingrrChipSelector<ProductCategory>(
      items: ProductCategory.values,
      selectedItem: _selectedCategory,
      onSelected: (category) => setState(() => _selectedCategory = category),
      labelBuilder: (category) => category.label,
      iconBuilder: (category) => category.icon,
      accentColor: context.features.market,
    );
  }

  // ============================================================
  // 알바 전용 위젯들
  // ============================================================

  Widget _buildJobTypeSelector() {
    return MingrrChipSelector<JobType>(
      items: JobType.values,
      selectedItem: _selectedJobType,
      onSelected: (type) => setState(() => _selectedJobType = type),
      labelBuilder: (type) => type.label,
      iconBuilder: (type) => type.icon,
      accentColor: context.features.market,
    );
  }

  Widget _buildDateSelector() {
    return MingrrDateSelector(
      date: _startDate,
      endDate: _endDate,
      onSelect: (d) => setState(() => _startDate = d),
      onEndDateSelect: (d) => setState(() => _endDate = d),
      // 시간 선택 옵션 (알바용)
      enableTimeSelection: true,
      startTime: _startTime,
      endTime: _endTime,
      onTimeSelect: (start, end) => setState(() {
        _startTime = start;
        _endTime = end;
      }),
      isTimeFlexible: _isTimeFlexible,
      onTimeFlexibleChanged: (v) => setState(() => _isTimeFlexible = v),
      accentColor: context.features.market,
    );
  }

  Widget _buildPetSelector() {
    final petsAsync = ref.watch(userPetsProvider);

    return petsAsync.when(
      data: (pets) {
        final selectedPets = pets.where((pet) => _selectedPetIds.contains(pet.id)).toList();
        
        // 선택된 반려동물이 있으면 카드 형태로 표시
        if (selectedPets.isNotEmpty) {
          return Column(
            children: [
              ...selectedPets.map((pet) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.paddingS),
                  child: GestureDetector(
                    onTap: () => _showPetSelectorSheet(pets),
                    child: PetSelectorCard(
                      pet: pet,
                      isSelected: true,
                      accentColor: context.features.market,
                    ),
                  ),
                );
              }),
              // 추가 버튼 (여러 마리 선택 가능)
              GestureDetector(
                onTap: () => _showPetSelectorSheet(pets),
                child: Container(
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
                      Text('반려동물 추가', style: TextStyle(color: Theme.of(context).colorScheme.outlineVariant)),
                      const Spacer(),
                      Icon(AppIcons.chevronRight, color: Theme.of(context).colorScheme.outlineVariant),
                    ],
                  ),
                ),
              ),
            ],
          );
        }
        
        // 선택된 반려동물이 없으면 교배 등록과 동일한 스타일
        return GestureDetector(
          onTap: () => _showPetSelectorSheet(pets),
          child: Container(
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
      loading: () => const MingrrLoadingState(type: MingrrLoadingType.market, message: '카테고리를 불러오고 있어요'),
      error: (_, __) => const Text('일시적인 오류가 발생했어요'),
    );
  }

  void _showPetSelectorSheet(List pets) {
    showPetSelectorSheet(
      context,
      pets: pets.cast<PetModel>(),
      title: '반려동물 선택',
      description: '프로필에 등록된 반려동물 중 선택해주세요',
      accentColor: context.features.market,
      onSelect: (pet) {
        if (!_selectedPetIds.contains(pet.id)) {
          setState(() => _selectedPetIds.add(pet.id));
        }
      },
    );
  }

  Widget _buildPriceUnitSelector() {
    final units = ['회', '시간', '일'];
    return Row(
      children: units.map((unit) {
        final isSelected = _priceUnit == unit;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _priceUnit = unit),
            child: Container(
              margin: EdgeInsets.only(right: unit != '일' ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingS),
              decoration: BoxDecoration(
                color: isSelected ? context.features.market.withValues(alpha: AppOpacity.o10) : Colors.transparent,
                borderRadius: BorderRadius.circular(AppSizes.radiusXS),
                border: Border.all(
                  color: isSelected ? context.features.market : Theme.of(context).colorScheme.outline,
                ),
              ),
              child: Text(
                unit,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium(context)
                    .withWeight(isSelected ? FontWeight.w600 : FontWeight.normal)
                    .withColor(isSelected ? context.features.market : Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildJobPriceField() {
    return TextFormField(
      controller: _priceController,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        _PriceInputFormatter(),
      ],
      decoration: InputDecoration(
        hintText: '금액을 입력해주세요',
        suffixText: '원/$_priceUnit',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusS),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusS),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusS),
          borderSide: BorderSide(color: context.features.market),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL, vertical: AppSizes.paddingM),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '금액을 입력해주세요';
        }
        return null;
      },
    );
  }

  // ============================================================
  // 판매/나눔 전용 위젯들
  // ============================================================

  Widget _buildLocationSelector() {
    final isJob = _selectedType == ProductType.job;
    final location = isJob ? _selectedJobLocation : _selectedLocation;
    
    return LocationDisplayCard(
      location: location,
      accentColor: context.features.market,
      placeholder: isJob ? '근무 지역을 선택해주세요' : '희망 지역을 선택해주세요',
      onTap: () async {
        final result = await showMapLocationPicker(
          context: context,
          initialLocation: location,
          accentColor: context.features.market,
          title: isJob ? '근무 지역 선택' : '희망 지역 선택',
        );
        if (result != null) {
          setState(() {
            if (isJob) {
              _selectedJobLocation = result;
            } else {
              _selectedLocation = result;
            }
          });
        }
      },
    );
  }

  Widget _buildPriceField() {
    final isJob = _selectedType == ProductType.job;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(isJob ? '시급' : '가격', style: AppTextStyles.labelLarge(context).copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSizes.gapS),
        TextFormField(
          controller: _priceController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            _PriceInputFormatter(),
          ],
          decoration: InputDecoration(
            hintText: isJob ? '시급을 입력해주세요' : '가격을 입력해주세요',
            suffixText: '원',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusS),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusS),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusS),
              borderSide: BorderSide(color: context.features.market),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL, vertical: AppSizes.paddingM),
          ),
          validator: (value) {
            if (_selectedType == ProductType.sell && (value == null || value.isEmpty)) {
              return '가격을 입력해주세요';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildBottomButton() {
    return MingrrSubmitButtonBar(
      label: _isEditMode ? '수정' : '등록',
      onPressed: _onSubmit,
      isLoading: _isLoading,
      backgroundColor: context.features.market,
    );
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final remaining = ImageLimits.maxImageCount - (_existingImageUrls.length + _selectedImages.length);
    
    if (remaining <= 0) {
      MingrrSnackBar.warning(context, '이미지는 최대 ${ImageLimits.maxImageCount}장까지 업로드 가능합니다');
      return;
    }
    
    // 바로 갤러리에서 다중 이미지 선택 (커뮤니티와 동일한 UX)
    final images = await picker.pickMultiImage(
      maxWidth: ImageLimits.maxResolution.toDouble(),
      maxHeight: ImageLimits.maxResolution.toDouble(),
      imageQuality: ImageLimits.imageQuality,
    );
    
    if (images.isNotEmpty) {
      // 각 이미지 파일 크기 검사
      final validImages = <XFile>[];
      for (final image in images.take(remaining)) {
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
          continue;
        }
        validImages.add(image);
      }
      
      if (validImages.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(validImages);
        });
      }
    }
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    
    final isJob = _selectedType == ProductType.job;
    
    // 판매/나눔일 때 카테고리 선택 검증
    if (!isJob && _selectedCategory == null) {
      MingrrSnackBar.warning(context, '카테고리를 선택해주세요');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUser = _firebaseService.currentUser;
      if (currentUser == null) {
        throw Exception('로그인이 필요합니다');
      }

      final now = DateTime.now();
      final price = parsePriceString(_priceController.text);

      // 알바 타입일 때 JobModel로 저장
      if (isJob) {
        // 이미지 업로드
        final List<String> imageUrls = [..._existingImageUrls];
        for (final image in _selectedImages) {
          final url = await _firebaseService.uploadImage(
            File(image.path),
            'jobs/${const Uuid().v4()}',
          );
          imageUrls.add(url);
        }
        
        final job = JobModel(
          id: const Uuid().v4(),
          userId: currentUser.uid,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          type: _selectedJobType,
          status: JobStatus.recruiting,
          price: price,
          priceUnit: _priceUnit,
          startDate: _startDate,
          endDate: _endDate,
          startTime: _startTime != null ? '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}' : null,
          endTime: _endTime != null ? '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}' : null,
          isTimeFlexible: _isTimeFlexible,
          address: _selectedJobLocation?.displayAddress,
          imageUrls: imageUrls,
          chatCount: 0,
          createdAt: now,
          updatedAt: now,
        );

        await _firestoreService.createJob(job);

        if (mounted) {
          // 리스트 새로고침 트리거
          ref.read(marketRefreshProvider.notifier).state++;
          Navigator.pop(context, true);
          MingrrSnackBar.success(context, '알바가 등록되었습니다');
        }
        return;
      }

      // 판매/나눔 타입일 때 ProductModel로 저장
      // 이미지 업로드
      final List<String> imageUrls = [..._existingImageUrls];
      for (final image in _selectedImages) {
        final url = await _firebaseService.uploadImage(
          File(image.path),
          'products/${const Uuid().v4()}',
        );
        imageUrls.add(url);
      }

      final productPrice = _selectedType == ProductType.share ? 0 : price;

      final product = ProductModel(
        id: _isEditMode ? widget.product!.id : const Uuid().v4(),
        sellerId: currentUser.uid,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        price: productPrice,
        type: _selectedType,
        category: _selectedCategory!,
        status: _isEditMode ? widget.product!.status : ProductStatus.available,
        imageUrls: imageUrls,
        location: _selectedLocation?.toGeoPoint(),
        address: _selectedLocation?.displayAddress,
        viewCount: _isEditMode ? widget.product!.viewCount : 0,
        likeCount: _isEditMode ? widget.product!.likeCount : 0,
        chatCount: _isEditMode ? widget.product!.chatCount : 0,
        createdAt: _isEditMode ? widget.product!.createdAt : now,
        updatedAt: now,
      );

      if (_isEditMode) {
        await _firestoreService.updateProduct(product);
      } else {
        await _firestoreService.createProduct(product);
      }

      if (mounted) {
        // 리스트 새로고침 트리거
        ref.read(marketRefreshProvider.notifier).state++;
        Navigator.pop(context, true);
        MingrrSnackBar.success(context, _isEditMode ? '상품이 수정되었습니다' : '상품이 등록되었습니다');
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.handle(
          context,
          error: e,
          tag: 'ProductWrite',
          operation: '상품 저장',
          themeColor: context.features.market,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

/// 가격 입력 포맷터 (3자리마다 콤마)
class _PriceInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final numericValue = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (numericValue.isEmpty) {
      return const TextEditingValue(text: '');
    }

    final intValue = int.tryParse(numericValue) ?? 0;
    final formattedValue = formatPrice(intValue);

    return TextEditingValue(
      text: formattedValue,
      selection: TextSelection.collapsed(offset: formattedValue.length),
    );
  }
}
