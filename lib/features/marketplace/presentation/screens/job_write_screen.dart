import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/confirm_bottom_sheet.dart';
// TODO: 실제 기기 테스트 시 주석 해제
// import '../../../../core/widgets/map_location_picker.dart';
// import 'package:kakao_maps_flutter/kakao_maps_flutter.dart';
import '../../../../core/widgets/map_location_picker_placeholder.dart';
import '../../../../models/marketplace_model.dart';
import '../../../pet/presentation/providers/pet_provider.dart';
import 'product_write_screen.dart';

/// ============================================================
/// 알바 등록/수정 화면
/// Firebase Firestore와 연동하여 실제 데이터 저장
/// ============================================================

class JobWriteScreen extends ConsumerStatefulWidget {
  final JobModel? job; // 수정 시 기존 알바 데이터

  const JobWriteScreen({super.key, this.job});

  @override
  ConsumerState<JobWriteScreen> createState() => _JobWriteScreenState();
}

class _JobWriteScreenState extends ConsumerState<JobWriteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();

  JobType _selectedType = JobType.care;
  String _priceUnit = '회';
  DateTime? _startDate;
  DateTime? _endDate;
  final List<String> _selectedPetIds = [];
  bool _isLoading = false;
  
  // 근무 지역
  String? _selectedLocation;
  LocationCoord? _selectedLocationLatLng;

  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseService _firebaseService = FirebaseService();

  bool get _isEditMode => widget.job != null;

  @override
  void initState() {
    super.initState();

    if (_isEditMode) {
      final job = widget.job!;
      _titleController.text = job.title;
      _priceController.text = formatPrice(job.price);
      _descriptionController.text = job.description;
      _selectedType = job.type;
      _priceUnit = job.priceUnit;
      _startDate = job.startDate;
      _endDate = job.endDate;
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_isEditMode ? '알바 수정' : '알바 등록'),
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
              _buildMarketTypeSelector(),
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
              _buildPriceField(),
              const SizedBox(height: AppSizes.gapL),

              // 근무 지역
              const Text('근무 지역', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSizes.gapS),
              _buildLocationSelector(),
              const SizedBox(height: AppSizes.gapL),

              // 상세 설명
              MingrrTextField(
                controller: _descriptionController,
                labelText: '상세내용',
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
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomButton(),
    );
  }

  /// 입력된 정보가 있는지 확인
  bool get _hasInputData {
    return _titleController.text.isNotEmpty ||
           _priceController.text.isNotEmpty ||
           _descriptionController.text.isNotEmpty ||
           _selectedPetIds.isNotEmpty ||
           _startDate != null ||
           _endDate != null;
  }

  /// 마켓 종류 선택 (판매/나눔/알바)
  Widget _buildMarketTypeSelector() {
    return Row(
      children: [
        _buildMarketTypeButton(ProductType.sell, '판매', Icons.sell),
        const SizedBox(width: 8),
        _buildMarketTypeButton(ProductType.share, '나눔', Icons.volunteer_activism),
        const SizedBox(width: 8),
        _buildMarketTypeButton(ProductType.job, '알바', Icons.work_outline),
      ],
    );
  }

  Widget _buildMarketTypeButton(ProductType type, String label, IconData icon) {
    final isSelected = type == ProductType.job; // 현재 알바 화면이므로 알바만 선택됨
    return Expanded(
      child: GestureDetector(
        onTap: () => _onMarketTypeChanged(type),
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

  /// 마켓 종류 변경 처리
  void _onMarketTypeChanged(ProductType newType) async {
    if (newType == ProductType.job) return; // 이미 알바 화면
    
    if (_hasInputData) {
      final confirmed = await showConfirmBottomSheetWithResult(
        context,
        type: ConfirmType.productTypeChange,
        message: '${newType == ProductType.sell ? '판매' : '나눔'} 등록 화면으로 이동합니다.\n현재 입력된 정보가 사라집니다.\n계속하시겠습니까?',
        confirmText: '이동',
      );
      if (confirmed != true) return;
    }
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ProductWriteScreen(initialType: newType),
        ),
      );
    }
  }

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
        final isSelected = _selectedType == item.type;
        return GestureDetector(
          onTap: () => setState(() => _selectedType = item.type),
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
        return Column(
          children: [
            // 선택된 강아지 목록
            ...pets.where((pet) => _selectedPetIds.contains(pet.id)).map((pet) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.divider.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.pets, size: 20, color: AppColors.market),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(pet.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                          Text(
                            '${pet.breed ?? '품종 미상'} · ${pet.weight ?? 0}kg',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _selectedPetIds.remove(pet.id)),
                      child: const Icon(Icons.close, size: 18, color: AppColors.textHint),
                    ),
                  ],
                ),
              );
            }),
            // 강아지 추가 버튼
            GestureDetector(
              onTap: () => _showPetSelector(pets),
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

  void _showPetSelector(List pets) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(AppSizes.paddingM),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('강아지 선택', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text(
              '프로필에 등록된 강아지 중 선택해주세요',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ...pets.map((pet) {
              final isAlreadySelected = _selectedPetIds.contains(pet.id);
              return GestureDetector(
                onTap: isAlreadySelected
                    ? null
                    : () {
                        setState(() => _selectedPetIds.add(pet.id));
                        Navigator.pop(ctx);
                      },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isAlreadySelected ? AppColors.divider.withOpacity(0.5) : AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppColors.divider,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.pets, color: AppColors.textHint),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pet.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isAlreadySelected ? AppColors.textHint : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${pet.breed ?? '품종 미상'} · ${pet.weight ?? 0}kg',
                              style: TextStyle(
                                fontSize: 12,
                                color: isAlreadySelected ? AppColors.textHint : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isAlreadySelected)
                        const Icon(Icons.check_circle, color: AppColors.market, size: 20),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
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

  Widget _buildPriceField() {
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

  Widget _buildLocationSelector() {
    // 지도에서 직접 선택만 가능
    return GestureDetector(
      onTap: () async {
        final result = await showMapLocationPicker(
          context: context,
          initialPosition: _selectedLocationLatLng,
          accentColor: AppColors.market,
          title: '근무 지역 선택',
        );
        if (result != null) {
          setState(() {
            _selectedLocationLatLng = result;
            _selectedLocation = '위도: ${result.latitude.toStringAsFixed(4)}, 경도: ${result.longitude.toStringAsFixed(4)}';
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _selectedLocationLatLng != null ? AppColors.market.withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: _selectedLocationLatLng != null ? AppColors.market : AppColors.divider,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              _selectedLocationLatLng != null ? Icons.location_on : Icons.map_outlined,
              size: 20,
              color: _selectedLocationLatLng != null ? AppColors.market : AppColors.textHint,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedLocationLatLng != null 
                        ? '위치가 선택되었습니다'
                        : '근무 지역을 선택해주세요',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: _selectedLocationLatLng != null ? FontWeight.w500 : FontWeight.w400,
                      color: _selectedLocationLatLng != null ? AppColors.textPrimary : AppColors.textHint,
                    ),
                  ),
                  if (_selectedLocationLatLng != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      _selectedLocation ?? '',
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
                color: _selectedLocationLatLng != null ? AppColors.market : AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _selectedLocationLatLng != null ? '변경' : '지도에서 선택',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _selectedLocationLatLng != null ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
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
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
        ),
      ),
    );
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final currentUser = _firebaseService.currentUser;
      if (currentUser == null) {
        throw Exception('로그인이 필요합니다');
      }

      final price = parsePriceString(_priceController.text);
      final now = DateTime.now();

      final job = JobModel(
        id: _isEditMode ? widget.job!.id : const Uuid().v4(),
        userId: currentUser.uid,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _selectedType,
        status: _isEditMode ? widget.job!.status : JobStatus.recruiting,
        price: price,
        priceUnit: _priceUnit,
        startDate: _startDate,
        endDate: _endDate,
        chatCount: _isEditMode ? widget.job!.chatCount : 0,
        createdAt: _isEditMode ? widget.job!.createdAt : now,
        updatedAt: now,
      );

      if (_isEditMode) {
        await _firebaseService.jobsCollection.doc(job.id).update(job.toFirestore());
      } else {
        await _firestoreService.createJob(job);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode ? '알바가 수정되었습니다' : '알바가 등록되었습니다'),
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

class _PriceInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    final numericValue = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (numericValue.isEmpty) return const TextEditingValue(text: '');

    final intValue = int.tryParse(numericValue) ?? 0;
    final formattedValue = formatPrice(intValue);

    return TextEditingValue(
      text: formattedValue,
      selection: TextSelection.collapsed(offset: formattedValue.length),
    );
  }
}
