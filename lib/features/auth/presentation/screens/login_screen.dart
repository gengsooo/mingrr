import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/common_widgets.dart';
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
  bool _isCodeSent = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
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
              
              // ===== 로그인 폼 =====
              _buildLoginForm(authState, authNotifier),
              
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
        // 로고 아이콘 (귀여운 발바닥 모양)
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            gradient: AppColors.warmGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.pets,
            size: 60,
            color: AppColors.textPrimary,
          ),
        ),
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

  /// 전화번호 로그인 폼
  Widget _buildLoginForm(AuthState authState, AuthNotifier authNotifier) {
    return MingrrCard(
      padding: const EdgeInsets.all(AppSizes.paddingL),
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '전화번호로 시작하기',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSizes.gapM),
          
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
      ),
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
    final phone = _phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (phone.isEmpty || phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('올바른 전화번호를 입력해주세요.'),
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
}
