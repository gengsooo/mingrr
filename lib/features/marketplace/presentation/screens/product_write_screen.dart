import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../core/utils/image_utils.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/confirm_bottom_sheet.dart';
// TODO: 실제 기기 테스트 시 주석 해제
// import '../../../../core/widgets/map_location_picker.dart';
// import 'package:kakao_maps_flutter/kakao_maps_flutter.dart';
import '../../../../core/widgets/map_location_picker_placeholder.dart';
import '../../../../models/marketplace_model.dart';
import '../../../../models/pet_model.dart';
import '../../../pet/presentation/providers/pet_provider.dart';
import '../../../../core/widgets/pet_selector_card.dart';

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
  ProductCategory? _selectedCategory;
  final List<XFile> _selectedImages = [];
  final List<String> _existingImageUrls = [];
  bool _isLoading = false;
  
  // 알바 전용 필드
  JobType _selectedJobType = JobType.care;
  String _priceUnit = '회';
  DateTime? _startDate;
  DateTime? _endDate;
  final List<String> _selectedPetIds = [];
  
  // 희망지역 (판매/나눔)
  String? _selectedLocation;
  LocationCoord? _selectedLocationLatLng;
  
  // 알바 지역
  String? _selectedJobLocation;
  LocationCoord? _selectedJobLocationLatLng;

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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_isEditMode ? '마켓 수정' : '마켓 등록'),
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
              // 종류 선택 (판매/나눔/알바)
              const Text('종류', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSizes.gapS),
              Row(
                children: [
                  _buildTypeButton(ProductType.sell, '판매', Icons.sell),
                  const SizedBox(width: 8),
                  _buildTypeButton(ProductType.share, '나눔', Icons.volunteer_activism),
                  const SizedBox(width: 8),
                  _buildTypeButton(ProductType.job, '알바', Icons.work_outline),
                ],
              ),
              const SizedBox(height: AppSizes.gapXL),

              // === 알바 전용 UI ===
              if (isJob) ...[
                // 사진 (선택)
                const Text('사진 (선택)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: AppSizes.gapS),
                _buildImagePicker(),
                const SizedBox(height: AppSizes.gapXL),
                
                // 알바 유형
                const Text('알바 유형', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: AppSizes.gapS),
                _buildJobTypeSelector(),
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

                // 기간
                const Text('기간', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: AppSizes.gapS),
                _buildDateSelector(),
                const SizedBox(height: AppSizes.gapL),

                // 돌봄 대상 강아지
                const Text('돌봄 대상 강아지', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: AppSizes.gapS),
                _buildPetSelector(),
                const SizedBox(height: AppSizes.gapL),

                // 급여
                const Text('급여', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: AppSizes.gapS),
                _buildPriceUnitSelector(),
                const SizedBox(height: AppSizes.gapS),
                _buildJobPriceField(),
                const SizedBox(height: AppSizes.gapL),

                // 근무 지역
                const Text('근무 지역', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: AppSizes.gapS),
                _buildLocationSelector(),
                const SizedBox(height: AppSizes.gapL),

                // 상세 설명
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
                const SizedBox(height: AppSizes.gapXXL),
              ]
              // === 판매/나눔 UI ===
              else ...[
                // 사진
                const Text('사진', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: AppSizes.gapS),
                _buildImagePicker(),
                const SizedBox(height: AppSizes.gapXL),

                // 카테고리
                const Text('카테고리', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: AppSizes.gapS),
                _buildCategorySelector(),
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

                // 가격 (판매일 때만)
                if (!isShare) ...[
                  _buildPriceField(),
                  const SizedBox(height: AppSizes.gapL),
                ],

                // 희망지역
                const Text('희망지역', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: AppSizes.gapS),
                _buildLocationSelector(),
                const SizedBox(height: AppSizes.gapL),

                // 설명
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
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.market : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.market : AppColors.divider,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isSelected ? Colors.white : AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
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
      
      final confirmed = await showConfirmBottomSheetWithResult(
        context,
        type: ConfirmType.productTypeChange,
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

  Widget _buildImagePicker() {
    final totalImages = _existingImageUrls.length + _selectedImages.length;
    
    return SizedBox(
      height: 80,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // 추가 버튼
          GestureDetector(
            onTap: _pickImages,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.divider),
                borderRadius: BorderRadius.circular(AppSizes.radiusM),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.camera_alt, color: AppColors.textHint),
                  const SizedBox(height: 4),
                  Text('$totalImages/10', style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 기존 이미지
          ..._existingImageUrls.asMap().entries.map((entry) {
            return _buildImageItem(
              imageUrl: entry.value,
              onRemove: () {
                setState(() => _existingImageUrls.removeAt(entry.key));
              },
            );
          }),
          // 새로 선택한 이미지
          ..._selectedImages.asMap().entries.map((entry) {
            return _buildImageItem(
              file: File(entry.value.path),
              onRemove: () {
                setState(() => _selectedImages.removeAt(entry.key));
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildImageItem({String? imageUrl, File? file, required VoidCallback onRemove}) {
    return Container(
      width: 80,
      height: 80,
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusM),
            child: imageUrl != null
                ? Image.network(imageUrl, width: 80, height: 80, fit: BoxFit.cover)
                : Image.file(file!, width: 80, height: 80, fit: BoxFit.cover),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ProductCategory.values.map((category) {
        final isSelected = _selectedCategory == category;
        return GestureDetector(
          onTap: () => setState(() => _selectedCategory = category),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.market : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppColors.market : AppColors.divider,
              ),
            ),
            child: Text(
              _getCategoryLabel(category),
              style: TextStyle(
                fontSize: 13,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _getCategoryLabel(ProductCategory category) {
    switch (category) {
      case ProductCategory.food:
        return '사료/간식';
      case ProductCategory.clothes:
        return '의류/악세서리';
      case ProductCategory.toys:
        return '장난감';
      case ProductCategory.supplies:
        return '용품';
      case ProductCategory.furniture:
        return '가구/하우스';
      case ProductCategory.health:
        return '건강/위생';
      case ProductCategory.other:
        return '기타';
    }
  }

  // ============================================================
  // 알바 전용 위젯들
  // ============================================================

  Widget _buildJobTypeSelector() {
    final types = [
      (type: JobType.care, label: '돌봄'),
      (type: JobType.walk, label: '산책'),
      (type: JobType.bath, label: '목욕'),
      (type: JobType.training, label: '훈련'),
      (type: JobType.other, label: '기타'),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: types.map((item) {
        final isSelected = _selectedJobType == item.type;
        return GestureDetector(
          onTap: () => setState(() => _selectedJobType = item.type),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.market : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppColors.market : AppColors.divider,
              ),
            ),
            child: Text(
              item.label,
              style: TextStyle(
                fontSize: 13,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDateSelector() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _selectDate(isStart: true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.divider),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    _startDate != null ? formatDate(_startDate!) : '시작일',
                    style: TextStyle(
                      color: _startDate != null ? AppColors.textPrimary : AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text('~'),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => _selectDate(isStart: false),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.divider),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    _endDate != null ? formatDate(_endDate!) : '종료일',
                    style: TextStyle(
                      color: _endDate != null ? AppColors.textPrimary : AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate({required bool isStart}) async {
    final initialDate = isStart ? (_startDate ?? DateTime.now()) : (_endDate ?? DateTime.now());
    final firstDate = isStart ? DateTime.now() : (_startDate ?? DateTime.now());

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.market),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() {
        if (isStart) {
          _startDate = date;
          if (_endDate != null && _endDate!.isBefore(date)) {
            _endDate = null;
          }
        } else {
          _endDate = date;
        }
      });
    }
  }

  Widget _buildPetSelector() {
    final petsAsync = ref.watch(userPetsProvider);

    return petsAsync.when(
      data: (pets) {
        final selectedPets = pets.where((pet) => _selectedPetIds.contains(pet.id)).toList();
        
        return Column(
          children: [
            // 선택된 강아지 목록 (PetSelectorCard 스타일)
            ...selectedPets.map((pet) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Stack(
                  children: [
                    PetSelectorCard(
                      pet: pet,
                      isSelected: true,
                      accentColor: AppColors.market,
                    ),
                    // 삭제 버튼
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedPetIds.remove(pet.id)),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            // 강아지 추가 버튼
            GestureDetector(
              onTap: () => _showPetSelectorSheet(pets),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.divider),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, size: 20, color: AppColors.market),
                    SizedBox(width: 8),
                    Text(
                      '강아지 추가',
                      style: TextStyle(color: AppColors.market, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Text('강아지 목록을 불러올 수 없습니다'),
    );
  }

  void _showPetSelectorSheet(List pets) {
    showPetSelectorSheet(
      context,
      pets: pets.cast<PetModel>(),
      title: '강아지 선택',
      description: '프로필에 등록된 강아지 중 선택해주세요',
      accentColor: AppColors.market,
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
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.market.withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? AppColors.market : AppColors.divider,
                ),
              ),
              child: Text(
                unit,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? AppColors.market : AppColors.textSecondary,
                ),
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
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.market),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
    final latLng = isJob ? _selectedJobLocationLatLng : _selectedLocationLatLng;
    
    // 지도에서 직접 선택만 가능
    return GestureDetector(
      onTap: () async {
        final result = await showMapLocationPicker(
          context: context,
          initialPosition: latLng,
          accentColor: AppColors.market,
          title: isJob ? '근무 지역 선택' : '희망 지역 선택',
        );
        if (result != null) {
          setState(() {
            if (isJob) {
              _selectedJobLocationLatLng = result;
              _selectedJobLocation = '위도: ${result.latitude.toStringAsFixed(4)}, 경도: ${result.longitude.toStringAsFixed(4)}';
            } else {
              _selectedLocationLatLng = result;
              _selectedLocation = '위도: ${result.latitude.toStringAsFixed(4)}, 경도: ${result.longitude.toStringAsFixed(4)}';
            }
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: latLng != null ? AppColors.market.withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: latLng != null ? AppColors.market : AppColors.divider,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              latLng != null ? Icons.location_on : Icons.map_outlined,
              size: 20,
              color: latLng != null ? AppColors.market : AppColors.textHint,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    latLng != null 
                        ? '위치가 선택되었습니다'
                        : (isJob ? '근무 지역을 선택해주세요' : '희망 지역을 선택해주세요'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: latLng != null ? FontWeight.w500 : FontWeight.w400,
                      color: latLng != null ? AppColors.textPrimary : AppColors.textHint,
                    ),
                  ),
                  if (latLng != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      location ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: latLng != null ? AppColors.market : AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                latLng != null ? '변경' : '지도에서 선택',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: latLng != null ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceField() {
    final isJob = _selectedType == ProductType.job;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(isJob ? '시급' : '가격', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
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
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.market),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
            backgroundColor: AppColors.market,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _pickImages() async {
    final totalImages = _existingImageUrls.length + _selectedImages.length;
    if (totalImages >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('최대 10장까지 등록할 수 있습니다')),
      );
      return;
    }

    // 이미지 소스 선택 다이얼로그
    final source = await ImageUtils.showImageSourceDialog(context);
    if (source == null) return;

    // 이미지 선택 및 크롭
    final croppedFile = await ImageUtils.pickAndCropImage(
      context: context,
      source: source,
      toolbarColor: AppColors.market,
    );

    if (croppedFile != null) {
      setState(() => _selectedImages.add(XFile(croppedFile.path)));
    }
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    
    final isJob = _selectedType == ProductType.job;
    
    // 판매/나눔일 때 카테고리 선택 검증
    if (!isJob && _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('카테고리를 선택해주세요'),
          backgroundColor: AppColors.error,
        ),
      );
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
          if (url != null) {
            imageUrls.add(url);
          }
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
          address: _selectedJobLocation,
          imageUrls: imageUrls,
          chatCount: 0,
          createdAt: now,
          updatedAt: now,
        );

        await _firestoreService.createJob(job);

        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('알바가 등록되었습니다'),
              backgroundColor: AppColors.success,
            ),
          );
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
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode ? '상품이 수정되었습니다' : '상품이 등록되었습니다'),
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
