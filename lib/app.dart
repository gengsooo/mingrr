import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_strings.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_sizes.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'features/dating/presentation/screens/dating_screen.dart';
import 'features/walk/presentation/screens/walk_screen.dart';
import 'features/marketplace/presentation/screens/marketplace_screen.dart';
import 'features/health/presentation/screens/health_screen.dart';
import 'features/community/presentation/screens/community_screen.dart';
import 'features/chat/presentation/screens/chat_list_screen.dart';
import 'features/profile/presentation/screens/profile_screen.dart';

/// ============================================================
/// MINGRR 앱 메인 위젯
/// 라우팅, 테마, 전역 상태 관리 설정
/// ============================================================

// ===== 라우터 Provider =====
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isLoginRoute = state.matchedLocation == '/login';

      // 로그인 안 된 상태에서 로그인 페이지가 아니면 로그인으로 리다이렉트
      if (!isLoggedIn && !isLoginRoute) {
        return '/login';
      }

      // 로그인 된 상태에서 로그인 페이지면 홈으로 리다이렉트
      if (isLoggedIn && isLoginRoute) {
        return '/';
      }

      return null;
    },
    routes: [
      // 로그인 화면
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      
      // 메인 쉘 (바텀 네비게이션)
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/dating',
            builder: (context, state) => const DatingScreen(),
          ),
          GoRoute(
            path: '/market',
            builder: (context, state) => const MarketplaceScreen(),
          ),
          GoRoute(
            path: '/chat',
            builder: (context, state) => const ChatListScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      
      // 독립 화면들 (바텀 네비게이션 없음)
      GoRoute(
        path: '/walk',
        builder: (context, state) => const WalkScreen(),
      ),
      GoRoute(
        path: '/health',
        builder: (context, state) => const HealthScreen(),
      ),
      GoRoute(
        path: '/community',
        builder: (context, state) => const CommunityScreen(),
      ),
    ],
  );
});

/// MINGRR 앱 위젯
class MingrrApp extends ConsumerWidget {
  const MingrrApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}

/// ============================================================
/// 메인 쉘 (바텀 네비게이션 포함)
/// 홈, 데이팅, 마켓, 채팅, 프로필 탭 관리
/// ============================================================
class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: const MingrrBottomNavBar(),
    );
  }
}

/// 커스텀 바텀 네비게이션 바
class MingrrBottomNavBar extends StatelessWidget {
  const MingrrBottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    // 현재 경로 확인
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _getIndexFromLocation(location);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: AppSizes.bottomNavHeight,
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingS),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context: context,
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: '홈',
                index: 0,
                currentIndex: currentIndex,
                route: '/',
              ),
              _buildNavItem(
                context: context,
                icon: Icons.favorite_outline,
                activeIcon: Icons.favorite,
                label: '데이팅',
                index: 1,
                currentIndex: currentIndex,
                route: '/dating',
                color: AppColors.dating,
              ),
              _buildNavItem(
                context: context,
                icon: Icons.store_outlined,
                activeIcon: Icons.store,
                label: '마켓',
                index: 2,
                currentIndex: currentIndex,
                route: '/market',
                color: AppColors.market,
              ),
              _buildNavItem(
                context: context,
                icon: Icons.chat_bubble_outline,
                activeIcon: Icons.chat_bubble,
                label: '채팅',
                index: 3,
                currentIndex: currentIndex,
                route: '/chat',
                badge: 3, // 읽지 않은 메시지 수
              ),
              _buildNavItem(
                context: context,
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: '프로필',
                index: 4,
                currentIndex: currentIndex,
                route: '/profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 네비게이션 아이템
  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required int currentIndex,
    required String route,
    Color? color,
    int? badge,
  }) {
    final isActive = index == currentIndex;
    final activeColor = color ?? AppColors.primary;

    return GestureDetector(
      onTap: () {
        if (!isActive) {
          context.go(route);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingM,
          vertical: AppSizes.paddingS,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isActive
                        ? activeColor.withOpacity(0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppSizes.radiusM),
                  ),
                  child: Icon(
                    isActive ? activeIcon : icon,
                    color: isActive ? activeColor : AppColors.textHint,
                    size: AppSizes.bottomNavIconSize,
                  ),
                ),
                // 배지
                if (badge != null && badge > 0)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        badge > 99 ? '99+' : '$badge',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? activeColor : AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 경로에서 인덱스 추출
  int _getIndexFromLocation(String location) {
    switch (location) {
      case '/':
        return 0;
      case '/dating':
        return 1;
      case '/market':
        return 2;
      case '/chat':
        return 3;
      case '/profile':
        return 4;
      default:
        return 0;
    }
  }
}
