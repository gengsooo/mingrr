// ============================================================
// 🏠 MainShell - 바텀 네비게이션이 있는 메인 레이아웃
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_icons.dart';
import '../core/constants/app_sizes.dart';
import '../core/theme/app_text_styles.dart';
import '../core/widgets/network_status_banner.dart';
import '../features/chat/presentation/providers/chat_provider.dart';

// ============================================================
// 로그인 후 사용하는 메인 화면의 레이아웃입니다
// 홈, 데이팅, 채팅, 마켓, 전체 5개 탭을 관리합니다
class MainShell extends StatelessWidget {
  // child: 바텀바 위에 표시될 실제 화면
  final Widget child;

  const MainShell({
    super.key,
    required this.child,  // 반드시 값을 전달해야 함
  });

  @override
  Widget build(BuildContext context) {
    // Scaffold: Flutter의 기본 화면 구조
    // NetworkAwareWidget: 네트워크 상태 변경 시 스낵바 표시
    return NetworkAwareWidget(
      child: Scaffold(
        body: Column(
          children: [
            // 네트워크 오프라인 시 상단 배너 표시
            const NetworkStatusBanner(),
            // 본문: 현재 선택된 화면
            Expanded(child: child),
          ],
        ),
        bottomNavigationBar: const MingrrBottomNavBar(),  // 하단 네비게이션 바
      ),
    );
  }
}

// ============================================================
// 📊 MingrrBottomNavBar - 하단 네비게이션 바 (5개 탭)
// ============================================================
// 홈, 데이팅, 마켓, 채팅, 프로필 5개 버튼을 표시합니다
class MingrrBottomNavBar extends ConsumerWidget {
  const MingrrBottomNavBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 현재 URL 경로를 가져옵니다
    final location = GoRouterState.of(context).matchedLocation;
    
    // URL 경로를 숫자 인덱스로 변환 (0=홈, 1=데이팅, 2=마켓, 3=채팅, 4=프로필)
    final currentIndex = _getIndexFromLocation(location);
    
    // 읽지 않은 채팅 메시지 수 가져오기
    final unreadCount = ref.watch(totalUnreadCountProvider);

    // 다크모드 여부 확인
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surface : Colors.white,
        border: Border(
          top: BorderSide(
            color: colorScheme.outline,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Container(
          height: AppSizes.bottomNavHeight,
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingS),
          
          // Row: 자식 위젯들을 가로로 나열
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 1️⃣ 홈 버튼
              Expanded(
                child: _buildNavItem(
                  context: context,
                  icon: AppIcons.homeOutlined,
                  activeIcon: AppIcons.home,
                  label: '홈',
                  index: 0,
                  currentIndex: currentIndex,
                  route: '/',
                ),
              ),
              
              // 2️⃣ 데이팅 버튼
              Expanded(
                child: _buildNavItem(
                  context: context,
                  icon: AppIcons.datingOutlined,
                  activeIcon: AppIcons.dating,
                  label: '데이팅',
                  index: 1,
                  currentIndex: currentIndex,
                  route: '/dating',
                ),
              ),
              
              // 3️⃣ 채팅 버튼
              Expanded(
                child: _buildNavItem(
                  context: context,
                  icon: AppIcons.chatBubbleOutlined,
                  activeIcon: AppIcons.chatBubble,
                  label: '채팅',
                  index: 2,
                  currentIndex: currentIndex,
                  route: '/chat',
                  badge: unreadCount,
                ),
              ),
              
              // 4️⃣ 마켓 버튼
              Expanded(
                child: _buildNavItem(
                  context: context,
                  icon: AppIcons.marketOutlined,
                  activeIcon: AppIcons.market,
                  label: '마켓',
                  index: 3,
                  currentIndex: currentIndex,
                  route: '/market',
                ),
              ),
              
              // 5️⃣ 전체 버튼
              Expanded(
                child: _buildNavItem(
                  context: context,
                  icon: AppIcons.menuOutlined,
                  activeIcon: AppIcons.menu,
                  label: '전체',
                  index: 4,
                  currentIndex: currentIndex,
                  route: '/more',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 🔘 _buildNavItem - 네비게이션 버튼 하나를 만드는 함수
  // ============================================================
  // 각 탭 버튼의 UI를 생성합니다
  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required int currentIndex,
    required String route,
    int? badge,
  }) {
    final isActive = index == currentIndex;
    final colorScheme = Theme.of(context).colorScheme;
    final activeColor = isActive ? colorScheme.primary : colorScheme.onSurfaceVariant;

    return GestureDetector(
      onTap: () {
        if (!isActive) context.go(route);
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: AppSizes.bottomNavHeight,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isActive ? activeIcon : icon,
                  color: activeColor,
                  size: AppSizes.bottomNavIconSize,
                ),
                if (badge != null && badge > 0)
                  Positioned(
                    top: -4,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: colorScheme.error,
                        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                      ),
                      child: Text(
                        badge > 99 ? '99+' : '$badge',
                        style: AppTextStyles.captionSmall(context).withSize(9).withWeight(FontWeight.w600).withColor(Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTextStyles.captionSmall(context).withSize(10)
                  .withWeight(isActive ? FontWeight.w600 : FontWeight.w400)
                  .withColor(activeColor),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 🔢 _getIndexFromLocation - URL 경로를 인덱스 번호로 변환
  // ============================================================
  int _getIndexFromLocation(String location) {
    switch (location) {
      case '/': return 0;
      case '/dating': return 1;
      case '/chat': return 2;
      case '/market': return 3;
      case '/more': return 4;
      default: return 0;
    }
  }
}
