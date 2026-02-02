import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/legal_texts.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/sheets/mingrr_bottom_sheet.dart';
import '../../data/consent_data.dart';
import '../providers/auth_provider.dart';

/// ============================================================
/// 회원가입 화면
/// 
/// 업계 표준 UX 적용:
/// - 실시간 이메일 중복 검사 (입력 완료 후)
/// - 실시간 비밀번호 강도 표시
/// - 약관동의를 한 화면에 통합
/// - 모든 조건 충족 시에만 가입 버튼 활성화
/// ============================================================
class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  
  // 유효성 검사 상태
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  bool _isCheckingEmail = false;
  bool _isEmailAvailable = false;
  PasswordStrength _passwordStrength = PasswordStrength.none;
  
  // 약관 동의 상태
  bool _termsAgreed = false;
  bool _privacyAgreed = false;
  bool _ageConfirmed = false;
  bool _locationAgreed = false;
  bool _marketingAgreed = false;
  
  // 디바운스 타이머
  Timer? _emailDebounce;
  
  bool get _allRequiredAgreed => _termsAgreed && _privacyAgreed && _ageConfirmed;
  bool get _allAgreed => _allRequiredAgreed && _locationAgreed && _marketingAgreed;
  
  bool get _canSubmit =>
      _isEmailAvailable &&
      _emailError == null &&
      _passwordError == null &&
      _confirmPasswordError == null &&
      _emailController.text.isNotEmpty &&
      _passwordController.text.isNotEmpty &&
      _confirmPasswordController.text.isNotEmpty &&
      _allRequiredAgreed;

  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(_onEmailFocusChange);
    _passwordController.addListener(_validatePassword);
    _confirmPasswordController.addListener(_validateConfirmPassword);
  }

  @override
  void dispose() {
    _emailDebounce?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailFocusNode.removeListener(_onEmailFocusChange);
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  void _onEmailFocusChange() {
    if (!_emailFocusNode.hasFocus) {
      _validateEmail();
    }
  }

  void _validateEmail() {
    final email = _emailController.text.trim();
    
    // 빈 값이면 검사 안함
    if (email.isEmpty) {
      setState(() {
        _emailError = null;
        _isEmailAvailable = false;
      });
      return;
    }
    
    // 이메일 형식 검사
    final validation = Validators.email(email);
    if (!validation.isValid) {
      setState(() {
        _emailError = validation.errorMessage;
        _isEmailAvailable = false;
      });
      return;
    }
    
    // 디바운스로 중복 검사
    _emailDebounce?.cancel();
    _emailDebounce = Timer(const Duration(milliseconds: 500), () {
      _checkEmailDuplicate(email);
    });
  }

  Future<void> _checkEmailDuplicate(String email) async {
    setState(() {
      _isCheckingEmail = true;
      _emailError = null;
    });
    
    try {
      final authNotifier = ref.read(authNotifierProvider.notifier);
      final exists = await authNotifier.checkEmailExists(email);
      
      if (mounted) {
        setState(() {
          _isCheckingEmail = false;
          if (exists) {
            _emailError = '이미 사용 중인 이메일입니다';
            _isEmailAvailable = false;
          } else {
            _emailError = null;
            _isEmailAvailable = true;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingEmail = false;
          _emailError = '이메일 확인 중 오류가 발생했습니다';
          _isEmailAvailable = false;
        });
      }
    }
  }

  void _validatePassword() {
    final password = _passwordController.text;
    
    setState(() {
      _passwordStrength = Validators.getPasswordStrength(password);
      
      if (password.isEmpty) {
        _passwordError = null;
      } else {
        final validation = Validators.password(password);
        _passwordError = validation.errorMessage;
      }
    });
    
    // 비밀번호 확인도 다시 검사
    if (_confirmPasswordController.text.isNotEmpty) {
      _validateConfirmPassword();
    }
  }

  void _validateConfirmPassword() {
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;
    
    setState(() {
      if (confirm.isEmpty) {
        _confirmPasswordError = null;
      } else {
        final validation = Validators.confirmPassword(password, confirm);
        _confirmPasswordError = validation.errorMessage;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final colorScheme = Theme.of(context).colorScheme;
    
    // 에러 메시지 표시
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next.error != null) {
        MingrrSnackBar.error(context, next.error!);
        ref.read(authNotifierProvider.notifier).clearError();
      }
    });

    return Scaffold(
      appBar: const MingrrAppBar(title: '회원가입'),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSizes.paddingL),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 안내 문구
                      Text(
                        '밍그르르에 오신 것을 환영해요!',
                        style: AppTextStyles.headlineMedium(context),
                      ),
                      const SizedBox(height: AppSizes.gapS),
                      Text(
                        '아래 정보를 입력하고 가입을 완료해주세요.',
                        style: AppTextStyles.bodyMedium(context).withColor(colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: AppSizes.gapXL),
                      
                      // ===== 이메일 입력 =====
                      _buildEmailField(colorScheme),
                      const SizedBox(height: AppSizes.gapL),
                      
                      // ===== 비밀번호 입력 =====
                      _buildPasswordField(colorScheme),
                      const SizedBox(height: AppSizes.gapL),
                      
                      // ===== 비밀번호 확인 =====
                      _buildConfirmPasswordField(colorScheme),
                      const SizedBox(height: AppSizes.gapXXL),
                      
                      // ===== 약관 동의 =====
                      _buildConsentSection(colorScheme),
                    ],
                  ),
                ),
              ),
            ),
            
            // 하단 버튼
            _buildBottomButton(authState, colorScheme),
          ],
        ),
      ),
    );
  }

  /// 이메일 입력 필드
  Widget _buildEmailField(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '이메일',
          style: AppTextStyles.labelLarge(context).withWeight(FontWeight.w600),
        ),
        const SizedBox(height: AppSizes.gapS),
        MingrrTextField(
          controller: _emailController,
          focusNode: _emailFocusNode,
          hintText: 'example@mingrr.com',
          prefixIcon: AppIcons.email,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          onChanged: (value) {
            // 입력 중에는 에러만 초기화
            if (_emailError != null) {
              setState(() {
                _emailError = null;
                _isEmailAvailable = false;
              });
            }
          },
          onFieldSubmitted: (_) {
            _validateEmail();
            _passwordFocusNode.requestFocus();
          },
          suffixIcon: _buildEmailSuffix(colorScheme),
        ),
        if (_emailError != null) ...[
          const SizedBox(height: AppSizes.gapXS),
          Text(
            _emailError!,
            style: AppTextStyles.bodySmall(context).withColor(colorScheme.error),
          ),
        ] else if (_isEmailAvailable) ...[
          const SizedBox(height: AppSizes.gapXS),
          Text(
            '사용 가능한 이메일입니다',
            style: AppTextStyles.bodySmall(context).withColor(colorScheme.primary),
          ),
        ],
      ],
    );
  }

  Widget? _buildEmailSuffix(ColorScheme colorScheme) {
    if (_isCheckingEmail) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: colorScheme.primary,
        ),
      );
    }
    if (_isEmailAvailable) {
      return Icon(AppIcons.check, color: colorScheme.primary, size: 20);
    }
    if (_emailError != null) {
      return Icon(AppIcons.close, color: colorScheme.error, size: 20);
    }
    return null;
  }

  /// 비밀번호 입력 필드
  Widget _buildPasswordField(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '비밀번호',
          style: AppTextStyles.labelLarge(context).withWeight(FontWeight.w600),
        ),
        const SizedBox(height: AppSizes.gapS),
        MingrrTextField(
          controller: _passwordController,
          focusNode: _passwordFocusNode,
          hintText: '8~16자 영문, 숫자, 특수문자 사용',
          prefixIcon: AppIcons.lock,
          obscureText: true,
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) => _confirmPasswordFocusNode.requestFocus(),
        ),
        const SizedBox(height: AppSizes.gapS),
        _buildPasswordStrengthIndicator(colorScheme),
        if (_passwordError != null) ...[
          const SizedBox(height: AppSizes.gapXS),
          Text(
            _passwordError!,
            style: AppTextStyles.bodySmall(context).withColor(colorScheme.error),
          ),
        ],
      ],
    );
  }

  /// 비밀번호 강도 표시
  Widget _buildPasswordStrengthIndicator(ColorScheme colorScheme) {
    if (_passwordStrength == PasswordStrength.none) {
      return const SizedBox.shrink();
    }
    
    final strengthColor = Color(_passwordStrength.colorValue ?? 0xFF9E9E9E);
    final strengthRatio = switch (_passwordStrength) {
      PasswordStrength.weak => 0.33,
      PasswordStrength.medium => 0.66,
      PasswordStrength.strong => 1.0,
      _ => 0.0,
    };
    
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: strengthRatio,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
              minHeight: 4,
            ),
          ),
        ),
        const SizedBox(width: AppSizes.gapS),
        Text(
          _passwordStrength.label,
          style: AppTextStyles.bodySmall(context).withColor(strengthColor),
        ),
      ],
    );
  }

  /// 비밀번호 확인 필드
  Widget _buildConfirmPasswordField(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '비밀번호 확인',
          style: AppTextStyles.labelLarge(context).withWeight(FontWeight.w600),
        ),
        const SizedBox(height: AppSizes.gapS),
        MingrrTextField(
          controller: _confirmPasswordController,
          focusNode: _confirmPasswordFocusNode,
          hintText: '비밀번호를 다시 입력해주세요',
          prefixIcon: AppIcons.lock,
          obscureText: true,
          textInputAction: TextInputAction.done,
          suffixIcon: _confirmPasswordController.text.isNotEmpty && _confirmPasswordError == null
              ? Icon(AppIcons.check, color: colorScheme.primary, size: 20)
              : null,
        ),
        if (_confirmPasswordError != null) ...[
          const SizedBox(height: AppSizes.gapXS),
          Text(
            _confirmPasswordError!,
            style: AppTextStyles.bodySmall(context).withColor(colorScheme.error),
          ),
        ],
      ],
    );
  }

  /// 약관 동의 섹션
  Widget _buildConsentSection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '약관 동의',
          style: AppTextStyles.titleMedium(context).withWeight(FontWeight.w600),
        ),
        const SizedBox(height: AppSizes.gapM),
        
        // 전체 동의
        _buildAllAgreeItem(colorScheme),
        const SizedBox(height: AppSizes.gapM),
        
        // 필수 동의 항목
        _buildConsentItem(
          title: '[필수] 이용약관 동의',
          isChecked: _termsAgreed,
          onChanged: (v) => setState(() => _termsAgreed = v ?? false),
          onViewDetail: () => _showTermsDetail(context),
          colorScheme: colorScheme,
        ),
        _buildConsentItem(
          title: '[필수] 개인정보 수집·이용 동의',
          isChecked: _privacyAgreed,
          onChanged: (v) => setState(() => _privacyAgreed = v ?? false),
          onViewDetail: () => _showPrivacyDetail(context),
          colorScheme: colorScheme,
        ),
        _buildConsentItem(
          title: '[필수] 만 14세 이상입니다',
          isChecked: _ageConfirmed,
          onChanged: (v) => setState(() => _ageConfirmed = v ?? false),
          colorScheme: colorScheme,
        ),
        
        const SizedBox(height: AppSizes.gapS),
        
        // 선택 동의 항목
        _buildConsentItem(
          title: '[선택] 위치정보 이용 동의',
          isChecked: _locationAgreed,
          onChanged: (v) => setState(() => _locationAgreed = v ?? false),
          onViewDetail: () => _showLocationDetail(context),
          colorScheme: colorScheme,
          isOptional: true,
        ),
        _buildConsentItem(
          title: '[선택] 마케팅 정보 수신 동의',
          isChecked: _marketingAgreed,
          onChanged: (v) => setState(() => _marketingAgreed = v ?? false),
          onViewDetail: () => _showMarketingDetail(context),
          colorScheme: colorScheme,
          isOptional: true,
        ),
      ],
    );
  }

  /// 전체 동의 항목
  Widget _buildAllAgreeItem(ColorScheme colorScheme) {
    return InkWell(
      onTap: () {
        final newValue = !_allAgreed;
        setState(() {
          _termsAgreed = newValue;
          _privacyAgreed = newValue;
          _ageConfirmed = newValue;
          _locationAgreed = newValue;
          _marketingAgreed = newValue;
        });
      },
      borderRadius: BorderRadius.circular(AppSizes.radiusS),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.paddingM),
        decoration: BoxDecoration(
          color: _allAgreed 
              ? colorScheme.primary.withValues(alpha: 0.1)
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(AppSizes.radiusS),
          border: Border.all(
            color: _allAgreed ? colorScheme.primary : colorScheme.outline,
            width: _allAgreed ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _allAgreed ? AppIcons.checkCircle : AppIcons.successOutlined,
              color: _allAgreed ? colorScheme.primary : colorScheme.outline,
              size: 24,
            ),
            const SizedBox(width: AppSizes.gapM),
            Expanded(
              child: Text(
                '전체 동의',
                style: AppTextStyles.titleMedium(context).copyWith(
                  fontWeight: FontWeight.w600,
                  color: _allAgreed ? colorScheme.primary : colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 개별 동의 항목
  Widget _buildConsentItem({
    required String title,
    required bool isChecked,
    required ValueChanged<bool?> onChanged,
    VoidCallback? onViewDetail,
    required ColorScheme colorScheme,
    bool isOptional = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingXS),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: isChecked,
              onChanged: onChanged,
              activeColor: colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: AppSizes.gapS),
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(!isChecked),
              child: Text(
                title,
                style: AppTextStyles.bodyMedium(context).copyWith(
                  color: isOptional 
                      ? colorScheme.onSurfaceVariant 
                      : colorScheme.onSurface,
                ),
              ),
            ),
          ),
          if (onViewDetail != null)
            TextButton(
              onPressed: onViewDetail,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingS),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                '보기',
                style: AppTextStyles.bodySmall(context).copyWith(
                  color: colorScheme.outline,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 하단 버튼
  Widget _buildBottomButton(AuthState authState, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSizes.paddingL,
        AppSizes.paddingM,
        AppSizes.paddingL,
        AppSizes.paddingL + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: MingrrButton(
        text: '가입하기',
        isLoading: authState.isLoading,
        onPressed: _canSubmit ? _onSubmit : null,
      ),
    );
  }

  // ===== 약관 상세 보기 =====
  
  void _showTermsDetail(BuildContext context) {
    _showPolicySheet(context, title: '이용약관', content: termsOfService);
  }

  void _showPrivacyDetail(BuildContext context) {
    _showPolicySheet(context, title: '개인정보 수집·이용 동의', content: privacyPolicy);
  }

  void _showLocationDetail(BuildContext context) {
    _showPolicySheet(context, title: '위치정보 이용약관', content: locationPolicy);
  }

  void _showMarketingDetail(BuildContext context) {
    _showPolicySheet(context, title: '마케팅 정보 수신 동의', content: marketingPolicy);
  }

  void _showPolicySheet(BuildContext context, {required String title, required String content}) {
    showMingrrBottomSheet(
      context: context,
      title: title,
      height: 0.85,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingS),
        child: Text(
          content,
          style: AppTextStyles.bodyLarge(context).copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.6,
          ),
        ),
      ),
    );
  }

  // ===== 가입 처리 =====
  
  Future<void> _onSubmit() async {
    // 최종 유효성 검사
    _validateEmail();
    _validatePassword();
    _validateConfirmPassword();
    
    if (!_canSubmit) return;
    
    final authNotifier = ref.read(authNotifierProvider.notifier);
    
    // 동의 정보 생성
    final consentData = ConsentData(
      termsAgreed: _termsAgreed,
      privacyAgreed: _privacyAgreed,
      ageConfirmed: _ageConfirmed,
      locationAgreed: _locationAgreed,
      marketingAgreed: _marketingAgreed,
      agreedAt: DateTime.now(),
    );
    
    final success = await authNotifier.signUpWithEmail(
      _emailController.text.trim(),
      _passwordController.text,
      consentData: consentData,
    );
    
    if (success && mounted) {
      // 회원가입 성공 - 자동으로 로그인되어 라우터가 처리
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }
}
