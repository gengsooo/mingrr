import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/svg_icons.dart';
import '../providers/auth_provider.dart';

/// ============================================================
/// 로그인 화면
/// 전화번호, 카카오, 네이버, 구글 로그인 지원
/// 포근한 노란톤의 귀여운 디자인
/// ============================================================
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isCodeSent = false;
  bool _isPhoneLogin = true; // true: 전화번호, false: 이메일

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final authNotifier = ref.read(authNotifierProvider.notifier);

    // 에러 메시지 표시
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
          ),
        );
        authNotifier.clearError();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.paddingXL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: AppSizes.gapXXL),
              
              // ===== 로고 및 타이틀 =====
              _buildHeader(),
              
              const SizedBox(height: AppSizes.gapXXL * 2),
              
              // ===== 로그인 방법 선택 탭 =====
              _buildLoginTabs(),
              
              const SizedBox(height: AppSizes.gapL),
              
              // ===== 로그인 폼 =====
              _isPhoneLogin
                  ? _buildPhoneLoginForm(authState, authNotifier)
                  : _buildEmailLoginForm(authState, authNotifier),
              
              const SizedBox(height: AppSizes.gapXL),
              
              // ===== 구분선 =====
              _buildDivider(),
              
              const SizedBox(height: AppSizes.gapXL),
              
              // ===== 소셜 로그인 버튼들 =====
              _buildSocialLoginButtons(authState, authNotifier),
              
              const SizedBox(height: AppSizes.gapXXL),
              
              // ===== 하단 안내 문구 =====
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  /// 헤더 (로고 + 타이틀)
  Widget _buildHeader() {
    return Column(
      children: [
        // 로고 아이콘
        const AppLogoIcon(size: 120),
        const SizedBox(height: AppSizes.gapXL),
        
        // 앱 이름
        const Text(
          AppStrings.appName,
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: AppSizes.gapS),
        
        // 슬로건
        const Text(
          AppStrings.appSlogan,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  /// 로그인 방법 선택 탭
  Widget _buildLoginTabs() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() {
              _isPhoneLogin = true;
              _isCodeSent = false;
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingM),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: _isPhoneLogin ? AppColors.primary : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                '전화번호',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: _isPhoneLogin ? FontWeight.w600 : FontWeight.w400,
                  color: _isPhoneLogin ? AppColors.primary : AppColors.textHint,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _isPhoneLogin = false),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingM),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: !_isPhoneLogin ? AppColors.primary : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                '이메일',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: !_isPhoneLogin ? FontWeight.w600 : FontWeight.w400,
                  color: !_isPhoneLogin ? AppColors.primary : AppColors.textHint,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 전화번호 로그인 폼
  Widget _buildPhoneLoginForm(AuthState authState, AuthNotifier authNotifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
          
        // 전화번호 입력
        MingrrTextField(
          controller: _phoneController,
          hintText: '010-1234-5678',
          prefixIcon: Icons.phone_android,
          keyboardType: TextInputType.phone,
          enabled: !_isCodeSent,
        ),
          
        // 인증 코드 입력 (코드 전송 후 표시)
        if (_isCodeSent) ...[
          const SizedBox(height: AppSizes.gapM),
          MingrrTextField(
            controller: _codeController,
            hintText: '인증번호 6자리',
            prefixIcon: Icons.lock_outline,
            keyboardType: TextInputType.number,
          ),
        ],
          
        const SizedBox(height: AppSizes.gapL),
        
        // 버튼
        if (!_isCodeSent)
          MingrrButton(
            text: AppStrings.sendVerificationCode,
            isLoading: authState.isLoading,
            onPressed: () => _sendCode(authNotifier),
          )
        else
          Column(
            children: [
              MingrrButton(
                text: AppStrings.verify,
                isLoading: authState.isLoading,
                onPressed: () => _verifyCode(authNotifier),
              ),
              const SizedBox(height: AppSizes.gapS),
              TextButton(
                onPressed: authState.isLoading
                    ? null
                    : () {
                        setState(() {
                          _isCodeSent = false;
                          _codeController.clear();
                        });
                      },
                child: const Text(AppStrings.resendCode),
              ),
            ],
          ),
      ],
    );
  }

  /// 이메일/비밀번호 로그인 폼
  Widget _buildEmailLoginForm(AuthState authState, AuthNotifier authNotifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 이메일 입력
        MingrrTextField(
          controller: _emailController,
          hintText: 'test@mingrr.com',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: AppSizes.gapM),
        
        // 비밀번호 입력
        MingrrTextField(
          controller: _passwordController,
          hintText: '비밀번호',
          prefixIcon: Icons.lock_outline,
          obscureText: true,
        ),
        const SizedBox(height: AppSizes.gapL),
        
        // 로그인 버튼
        MingrrButton(
          text: '로그인',
          isLoading: authState.isLoading,
          onPressed: () => _signInWithEmail(authNotifier),
        ),
        const SizedBox(height: AppSizes.gapS),
        
        // 회원가입 버튼
        TextButton(
          onPressed: authState.isLoading ? null : () => _signUpWithEmail(authNotifier),
          child: const Text('계정이 없으신가요? 회원가입'),
        ),
      ],
    );
  }

  /// 구분선
  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: AppColors.divider)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM),
          child: Text(
            '또는',
            style: TextStyle(
              color: AppColors.textHint,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(child: Divider(color: AppColors.divider)),
      ],
    );
  }

  /// 소셜 로그인 버튼들
  Widget _buildSocialLoginButtons(
    AuthState authState,
    AuthNotifier authNotifier,
  ) {
    return Column(
      children: [
        // 카카오 로그인
        SocialLoginButton.kakao(
          onPressed: authState.isLoading
              ? null
              : () => authNotifier.signInWithKakao(),
        ),
        const SizedBox(height: AppSizes.gapM),
        
        // 네이버 로그인
        SocialLoginButton.naver(
          onPressed: authState.isLoading
              ? null
              : () => authNotifier.signInWithNaver(),
        ),
        const SizedBox(height: AppSizes.gapM),
        
        // 구글 로그인
        SocialLoginButton.google(
          onPressed: authState.isLoading
              ? null
              : () => authNotifier.signInWithGoogle(),
        ),
      ],
    );
  }

  /// 하단 안내 문구
  Widget _buildFooter() {
    return Column(
      children: [
        Text(
          '로그인 시 이용약관 및 개인정보처리방침에 동의합니다.',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textHint,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// 인증 코드 전송
  void _sendCode(AuthNotifier authNotifier) {
    final phone = _phoneController.text;
    final validation = Validators.phone(phone);
    if (!validation.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validation.errorMessage!),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    authNotifier.sendPhoneCode(phone).then((_) {
      // 인증 코드 전송 성공 시 UI 업데이트
      final state = ref.read(authNotifierProvider);
      if (state.verificationId != null) {
        setState(() {
          _isCodeSent = true;
        });
      }
    });
  }

  /// 인증 코드 확인
  void _verifyCode(AuthNotifier authNotifier) {
    final code = _codeController.text.trim();
    if (code.isEmpty || code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('6자리 인증번호를 입력해주세요.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    authNotifier.verifyPhoneCode(code);
  }

  /// 이메일 로그인
  void _signInWithEmail(AuthNotifier authNotifier) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    
    final emailValidation = Validators.email(email);
    if (!emailValidation.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(emailValidation.errorMessage!),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    
    final passwordValidation = Validators.password(password);
    if (!passwordValidation.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(passwordValidation.errorMessage!),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    
    authNotifier.signInWithEmail(email, password);
  }

  /// 이메일 회원가입
  void _signUpWithEmail(AuthNotifier authNotifier) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    
    final emailValidation = Validators.email(email);
    if (!emailValidation.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(emailValidation.errorMessage!),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    
    final passwordValidation = Validators.password(password);
    if (!passwordValidation.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(passwordValidation.errorMessage!),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    
    authNotifier.signUpWithEmail(email, password);
  }
}
