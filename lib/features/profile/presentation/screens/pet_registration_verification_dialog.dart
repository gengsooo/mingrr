import 'package:flutter/material.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/theme/feature_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/animal_registration_service.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/dialogs/dialog_buttons.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../models/pet_model.dart';

/// ============================================================
/// 동물등록 인증 통합 다이얼로그
/// 
/// 입력 → 로딩 → 결과(성공/실패) → PetModel 매칭
/// ============================================================
class PetRegistrationVerificationDialog extends StatefulWidget {
  final String userId;
  final FirestoreService firestoreService;

  const PetRegistrationVerificationDialog({
    super.key,
    required this.userId,
    required this.firestoreService,
  });

  @override
  State<PetRegistrationVerificationDialog> createState() => _PetRegistrationVerificationDialogState();
}

enum _VerificationStep { input, loading, success, error, petSelection }

class _PetRegistrationVerificationDialogState extends State<PetRegistrationVerificationDialog> {
  // 상태
  _VerificationStep _step = _VerificationStep.input;
  String _statusMessage = '';
  String? _errorMessage;
  
  // 입력 컨트롤러
  final _registrationController = TextEditingController();
  final _ownerNameController = TextEditingController();
  
  // 결과 데이터
  AnimalInfo? _animalInfo;
  List<PetModel> _userPets = [];
  PetModel? _selectedPet;
  
  @override
  void dispose() {
    _registrationController.dispose();
    _ownerNameController.dispose();
    super.dispose();
  }
  
  /// 인증 시작
  Future<void> _startVerification() async {
    final regNo = _registrationController.text.trim();
    final ownerName = _ownerNameController.text.trim();
    
    // 입력 검증
    if (regNo.isEmpty) {
      setState(() => _errorMessage = '동물등록번호를 입력해주세요.');
      return;
    }
    if (ownerName.isEmpty) {
      setState(() => _errorMessage = '소유자 성명을 입력해주세요.');
      return;
    }
    
    setState(() {
      _step = _VerificationStep.loading;
      _statusMessage = '동물등록 정보 확인 중...';
      _errorMessage = null;
    });
    
    try {
      // API 호출
      final result = await AnimalRegistrationService.verify(
        registrationNumber: regNo,
        ownerName: ownerName,
      );
      
      if (!mounted) return;
      
      if (result.isSuccess && result.animalInfo != null) {
        _animalInfo = result.animalInfo;
        
        // 사용자의 반려동물 목록 조회
        setState(() => _statusMessage = '반려동물 정보 확인 중...');
        _userPets = await widget.firestoreService.getUserPets(widget.userId);
        
        // 이미 등록된 동물등록번호인지 확인
        final existingPet = await widget.firestoreService.findPetByRegistrationNumber(
          widget.userId, 
          regNo,
        );
        
        if (existingPet != null) {
          // 이미 인증된 반려동물
          _selectedPet = existingPet;
          setState(() => _step = _VerificationStep.success);
        } else if (_userPets.isEmpty) {
          // 등록된 반려동물이 없음 → 바로 인증 완료
          setState(() => _step = _VerificationStep.success);
        } else {
          // 반려동물 선택 화면으로 이동
          setState(() => _step = _VerificationStep.petSelection);
        }
      } else {
        setState(() {
          _step = _VerificationStep.error;
          _errorMessage = result.errorMessage ?? '인증에 실패했습니다.';
        });
      }
    } catch (e) {
      AppLogger.error('ProfileScreen', '동물등록 인증 오류', e);
      setState(() {
        _step = _VerificationStep.error;
        _errorMessage = '인증 중 오류가 발생했습니다.';
      });
    }
  }
  
  /// 인증 완료 처리
  Future<void> _completeVerification() async {
    if (_animalInfo == null) return;
    
    setState(() {
      _step = _VerificationStep.loading;
      _statusMessage = '인증 정보 저장 중...';
    });
    
    try {
      final regNo = _animalInfo!.dogRegNo;
      final animalData = _animalInfo!.toMap();
      
      // 1. 사용자 인증 정보 저장
      await widget.firestoreService.verifyPetRegistration(
        widget.userId,
        regNo,
        animalData: animalData,
        matchedPetId: _selectedPet?.id,
      );
      
      // 2. 선택된 반려동물에 인증 정보 연결
      if (_selectedPet != null) {
        await widget.firestoreService.linkPetRegistration(
          _selectedPet!.id,
          regNo,
          animalData,
        );
      }
      
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      AppLogger.error('ProfileScreen', '인증 저장 오류', e);
      setState(() {
        _step = _VerificationStep.error;
        _errorMessage = '인증 정보 저장 중 오류가 발생했습니다.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;
    
    return Dialog(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusL)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingXXL),
          child: _buildContent(colorScheme, primaryColor),
        ),
      ),
    );
  }
  
  Widget _buildContent(ColorScheme colorScheme, Color primaryColor) {
    switch (_step) {
      case _VerificationStep.input:
        return _buildInputContent(colorScheme, primaryColor);
      case _VerificationStep.loading:
        return _buildLoadingContent(colorScheme, primaryColor);
      case _VerificationStep.success:
        return _buildSuccessContent(colorScheme, primaryColor);
      case _VerificationStep.error:
        return _buildErrorContent(colorScheme);
      case _VerificationStep.petSelection:
        return _buildPetSelectionContent(colorScheme, primaryColor);
    }
  }
  
  /// 입력 화면
  Widget _buildInputContent(ColorScheme colorScheme, Color primaryColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 아이콘
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: AppOpacity.o10),
            shape: BoxShape.circle,
          ),
          child: Icon(AppIcons.pet, size: 28, color: primaryColor),
        ),
        const SizedBox(height: AppSizes.gapL),
        
        // 제목
        Text(
          '동물등록 인증',
          style: AppTextStyles.headlineSmall(context),
        ),
        const SizedBox(height: AppSizes.gapS),
        Text(
          '동물등록번호와 소유자 성명을 입력해주세요.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall(context),
        ),
        const SizedBox(height: AppSizes.gapL),
        
        // 동물등록번호 입력
        TextField(
          controller: _registrationController,
          decoration: InputDecoration(
            labelText: '동물등록번호',
            hintText: '15자리 숫자',
            prefixIcon: Icon(AppIcons.tag),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.radiusS)),
            counterText: '',
          ),
          keyboardType: TextInputType.number,
          maxLength: 15,
        ),
        const SizedBox(height: AppSizes.gapM),
        
        // 소유자 성명 입력
        TextField(
          controller: _ownerNameController,
          decoration: InputDecoration(
            labelText: '소유자 성명',
            hintText: '실명을 입력해주세요',
            prefixIcon: const Icon(AppIcons.profileOutlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.radiusS)),
          ),
          keyboardType: TextInputType.name,
        ),
        
        // 에러 메시지
        if (_errorMessage != null) ...[
          const SizedBox(height: AppSizes.gapM),
          Text(
            _errorMessage!,
            style: AppTextStyles.bodyMedium(context),
          ),
        ],
        
        const SizedBox(height: AppSizes.gapS),
        Text(
          '※ 동물등록번호는 동물보호관리시스템(animal.go.kr)에서 확인할 수 있습니다.',
          style: AppTextStyles.caption(context),
        ),
        const SizedBox(height: AppSizes.gapL),
        
        // 버튼
        MingrrDialogButtons(
          cancelText: '취소',
          confirmText: '인증하기',
          onCancel: () => Navigator.pop(context, false),
          onConfirm: _startVerification,
          confirmColor: primaryColor,
        ),
      ],
    );
  }
  
  /// 로딩 화면
  Widget _buildLoadingContent(ColorScheme colorScheme, Color primaryColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: AppOpacity.o10),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: MingrrLoadingIndicator(strokeWidth: 3, customColor: primaryColor),
            ),
          ),
        ),
        const SizedBox(height: AppSizes.gapL),
        Text(
          '동물등록 인증 중',
          style: AppTextStyles.headlineSmall(context),
        ),
        const SizedBox(height: AppSizes.gapS),
        Text(
          _statusMessage,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall(context),
        ),
      ],
    );
  }
  
  /// 성공 화면
  Widget _buildSuccessContent(ColorScheme colorScheme, Color primaryColor) {
    final successColor = context.features.success;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 아이콘
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: successColor.withValues(alpha: AppOpacity.o10),
            shape: BoxShape.circle,
          ),
          child: Icon(AppIcons.checkCircle, size: 28, color: successColor),
        ),
        const SizedBox(height: AppSizes.gapL),
        
        // 제목
        Text(
          '인증 완료',
          style: AppTextStyles.headlineSmall(context),
        ),
        const SizedBox(height: AppSizes.gapL),
        
        // 동물 정보 카드
        if (_animalInfo != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSizes.paddingL),
            decoration: BoxDecoration(
              color: successColor.withValues(alpha: AppOpacity.o10),
              borderRadius: BorderRadius.circular(AppSizes.radiusS),
            ),
            child: Column(
              children: [
                // 이름
                Row(
                  children: [
                    Icon(AppIcons.pet, color: successColor, size: 20),
                    const SizedBox(width: AppSizes.gapS),
                    Text(
                      _animalInfo!.dogNm,
                      style: AppTextStyles.titleLarge(context),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.gapM),
                
                // 상세 정보
                _buildInfoRow('품종', _animalInfo!.kindNm ?? '정보 없음'),
                _buildInfoRow('성별', _animalInfo!.sexNm ?? '정보 없음'),
                _buildInfoRow('중성화', _animalInfo!.isNeutered ? 'O' : 'X'),
                _buildInfoRow('생년월일', _animalInfo!.birthDateFormatted),
                _buildInfoRow('등록번호', _animalInfo!.dogRegNo),
              ],
            ),
          ),
        
        // 매칭된 반려동물 정보
        if (_selectedPet != null) ...[
          const SizedBox(height: AppSizes.gapM),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSizes.paddingM),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: AppOpacity.o10),
              borderRadius: BorderRadius.circular(AppSizes.radiusS),
            ),
            child: Row(
              children: [
                Icon(AppIcons.link, color: primaryColor, size: 18),
                const SizedBox(width: AppSizes.gapS),
                Expanded(
                  child: Text(
                    '내 반려동물 "${_selectedPet!.name}"과 연결됨',
                    style: AppTextStyles.bodySmall(context).copyWith(color: primaryColor),
                  ),
                ),
              ],
            ),
          ),
        ],
        
        const SizedBox(height: AppSizes.gapL),
        
        // 완료 버튼
        MingrrButton(
          text: '완료',
          onPressed: _completeVerification,
          backgroundColor: successColor,
          textColor: Colors.white,
          height: 48,
        ),
      ],
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingXXS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySmall(context)),
          Text(value, style: AppTextStyles.titleSmall(context)),
        ],
      ),
    );
  }
  
  /// 에러 화면
  Widget _buildErrorContent(ColorScheme colorScheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.error.withValues(alpha: AppOpacity.o10),
            shape: BoxShape.circle,
          ),
          child: Icon(AppIcons.error, size: 28, color: Theme.of(context).colorScheme.error),
        ),
        const SizedBox(height: AppSizes.gapL),
        Text(
          '인증 실패',
          style: AppTextStyles.headlineSmall(context),
        ),
        const SizedBox(height: AppSizes.gapS),
        Text(
          _errorMessage ?? '알 수 없는 오류가 발생했습니다.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall(context).copyWith(height: 1.5),
        ),
        const SizedBox(height: AppSizes.gapL),
        MingrrDialogButtons(
          cancelText: '닫기',
          confirmText: '다시 시도',
          onCancel: () => Navigator.pop(context, false),
          onConfirm: () => setState(() {
            _step = _VerificationStep.input;
            _errorMessage = null;
          }),
          confirmColor: colorScheme.primary,
        ),
      ],
    );
  }
  
  /// 반려동물 선택 화면
  Widget _buildPetSelectionContent(ColorScheme colorScheme, Color primaryColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 아이콘
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: AppOpacity.o10),
            shape: BoxShape.circle,
          ),
          child: Icon(AppIcons.pet, size: 28, color: primaryColor),
        ),
        const SizedBox(height: AppSizes.gapL),
        
        // 제목
        Text(
          '반려동물 연결',
          style: AppTextStyles.headlineSmall(context),
        ),
        const SizedBox(height: AppSizes.gapS),
        Text(
          '인증된 동물 정보를 연결할 반려동물을 선택해주세요.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall(context),
        ),
        const SizedBox(height: AppSizes.gapL),
        
        // 인증된 동물 정보
        if (_animalInfo != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSizes.paddingM),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: AppOpacity.o10),
              borderRadius: BorderRadius.circular(AppSizes.radiusS),
            ),
            child: Row(
              children: [
                Icon(AppIcons.verified, color: primaryColor, size: 20),
                const SizedBox(width: AppSizes.gapS),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _animalInfo!.dogNm,
                        style: AppTextStyles.labelLarge(context).copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${_animalInfo!.kindNm ?? ''} · ${_animalInfo!.sexNm ?? ''}',
                        style: AppTextStyles.caption(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: AppSizes.gapL),
        
        // 반려동물 목록
        Container(
          constraints: const BoxConstraints(maxHeight: 200),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _userPets.length + 1, // +1 for "연결 안함" 옵션
            itemBuilder: (context, index) {
              if (index == _userPets.length) {
                // 연결 안함 옵션
                return _buildPetOption(
                  null,
                  '연결 안함',
                  '나중에 연결할게요',
                  colorScheme,
                );
              }
              
              final pet = _userPets[index];
              return _buildPetOption(
                pet,
                pet.name,
                '${pet.breed ?? '품종 미입력'} · ${pet.genderString}',
                colorScheme,
              );
            },
          ),
        ),
        const SizedBox(height: AppSizes.gapL),
        
        // 버튼
        MingrrDialogButtons(
          cancelText: '취소',
          confirmText: '다음',
          onCancel: () => Navigator.pop(context, false),
          onConfirm: () {
            setState(() => _step = _VerificationStep.success);
          },
          confirmColor: primaryColor,
        ),
      ],
    );
  }
  
  Widget _buildPetOption(PetModel? pet, String title, String subtitle, ColorScheme colorScheme) {
    final isSelected = _selectedPet?.id == pet?.id;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedPet = pet),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSizes.paddingS),
        padding: const EdgeInsets.all(AppSizes.paddingM),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary.withValues(alpha: AppOpacity.o10) : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppSizes.radiusS),
          border: Border.all(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            // 프로필 이미지 또는 아이콘
            MingrrImage.thumbnail(
              imageUrl: pet?.displayImageUrl,
              width: 40,
              height: 40,
              radius: AppSizes.radiusS,
              errorWidget: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppSizes.radiusS),
                ),
                child: Icon(
                  pet == null ? AppIcons.linkOff : AppIcons.pet,
                  color: colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: AppSizes.gapM),
            
            // 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.labelLarge(context).copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption(context),
                  ),
                ],
              ),
            ),
            
            // 체크 아이콘
            if (isSelected)
              Icon(AppIcons.checkCircle, color: colorScheme.primary, size: 20),
          ],
        ),
      ),
    );
  }
}
