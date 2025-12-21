import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_strings.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_sizes.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'features/dating/presentation/screens/dating_screen.dart';
import 'features/walk/presentation/screens/walk_screen.dart';
import 'features/marketplace/presentation/screens/marketplace_screen.dart';
import 'features/health/presentation/screens/health_screen.dart';
import 'features/community/presentation/screens/community_screen.dart';
import 'features/chat/presentation/screens/chat_list_screen.dart';
import 'features/profile/presentation/screens/profile_screen.dart';

/// ============================================================
/// MINGRR 데모 앱
/// Firebase 없이 UI 테스트를 위한 데모 버전
/// 모든 화면을 탐색하고 디자인을 확인할 수 있습니다.
/// ============================================================

// ===== 데모용 라우터 =====
final demoRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      // 메인 쉘 (바텀 네비게이션)
      ShellRoute(
        builder: (context, state, child) => DemoMainShell(child: child),
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
      
      // 독립 화면들
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

/// 데모 앱 위젯
class MingrrDemoApp extends ConsumerWidget {
  const MingrrDemoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(demoRouterProvider);

    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}

/// 데모용 메인 쉘
class DemoMainShell extends StatelessWidget {
  final Widget child;

  const DemoMainShell({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: const DemoBottomNavBar(),
    );
  }
}

/// 데모용 바텀 네비게이션 바
class DemoBottomNavBar extends StatelessWidget {
  const DemoBottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
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
                badge: 3,
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
