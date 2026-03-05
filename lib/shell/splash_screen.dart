// ============================================================
// 🚀 SplashScreen - 인증 초기화 대기 화면
// ============================================================
// 웹에서 Firebase Auth가 세션을 복원할 때까지 보여주는 화면
// 깜빡거림 방지를 위해 로딩 중에는 이 화면을 표시
// 온보딩 완료 여부도 체크하여 적절한 화면으로 이동
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_strings.dart';
import '../core/theme/app_text_styles.dart';
import '../core/providers/location_verification_provider.dart';
import '../core/widgets/loading/loading_widgets.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAndNavigate();
  }

  Future<void> _checkAndNavigate() async {
    // 인증 상태가 로딩 완료될 때까지 대기
    await Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 150));
      final authState = ref.read(authStateProvider);
      return authState.isLoading;
    });

    if (!mounted) return;

    final authState = ref.read(authStateProvider);
    final isLoggedIn = authState.valueOrNull != null;

    if (isLoggedIn) {
      // 로그인 되어 있으면 홈으로 이동 + 앱 시작 시 위치 체크
      AppStartLocationChecker.checkOnAppStart(ref);
      context.go('/');
    } else {
      // 온보딩 완료 여부 체크
      final onboardingCompleted = await isOnboardingCompleted();
      if (!mounted) return;
      
      if (onboardingCompleted) {
        context.go('/login');
      } else {
        context.go('/onboarding');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 앱 로고 (PNG - Native Splash와 동일)
            ClipOval(
              child: Image.asset(
                'assets/images/app_icon.png',
                width: 120,
                height: 120,
              ),
            ),
            const SizedBox(height: 24),
            // 앱 이름
            Text(
              AppStrings.appName,
              style: AppTextStyles.displayLarge(context).withWeight(FontWeight.bold).withColor(Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 32),
            // 로딩 인디케이터 (공통 컴포넌트)
            const MingrrLoadingIndicator.medium(),
          ],
        ),
      ),
    );
  }
}
