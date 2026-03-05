// ============================================================
// 🏠 MainShell - 바텀 네비게이션이 있는 메인 레이아웃
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_icons.dart';
import '../core/constants/app_sizes.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/feature_colors.dart';
import '../core/widgets/network_status_banner.dart';
import '../features/chat/presentation/providers/chat_provider.dart';

// ============================================================
// 로그인 후 사용하는 메인 화면의 레이아웃입니다
// 홈, 데이팅, 마켓, 채팅, 프로필 5개 탭을 관리합니다
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
    
    // Container: 박스 형태의 위젯
    return Container(
      // decoration: 컨테이너 꾸미기
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surface : Colors.white,  // 다크모드 대응
        boxShadow: AppShadows.shadowL(isDark),
      ),
      // SafeArea: 노치나 홈 버튼 영역을 피해서 내용 표시
      child: SafeArea(
        child: Container(
          height: AppSizes.bottomNavHeight,  // 바텀바 높이
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingS),  // 좌우 여백
          
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
                  color: context.features.dating,
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
                  color: context.features.chat,  // 채팅 전용 주황색 테마
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
                  color: context.features.market,
                ),
              ),
              
              // 5️⃣ 소셜 버튼
              Expanded(
                child: _buildNavItem(
                  context: context,
                  icon: AppIcons.forumOutlined,
                  activeIcon: AppIcons.forum,
                  label: '소셜',
                  index: 4,
                  currentIndex: currentIndex,
                  route: '/social',
                  color: context.features.social,
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
    required IconData icon,  // 비활성 상태 아이콘
    required IconData activeIcon,  // 활성 상태 아이콘
    required String label,  // 버튼 아래 텍스트
    required int index,  // 이 버튼의 번호
    required int currentIndex,  // 현재 선택된 버튼 번호
    required String route,  // 이 버튼을 누르면 이동할 경로
    Color? color,  // 활성 상태 색상 (선택사항)
    int? badge,  // 배지 숫자 (선택사항)
  }) {
    // 이 버튼이 현재 선택되어 있는지 확인
    final isActive = index == currentIndex;
    
    // 활성 상태 색상 결정 (color가 없으면 기본 색상 사용)
    final activeColor = color ?? Theme.of(context).colorScheme.primary;

    // GestureDetector: 터치 이벤트를 감지하는 위젯
    return GestureDetector(
      // onTap: 버튼을 눌렀을 때 실행되는 함수
      onTap: () {
        // 이미 선택된 버튼이 아닐 때만 화면 이동
        if (!isActive) {
          context.go(route);  // 지정된 경로로 이동
        }
      },
      behavior: HitTestBehavior.opaque,  // 투명한 영역도 터치 가능하게
      
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingXS,
          vertical: AppSizes.paddingS,
        ),
        
        // Column: 자식 위젯들을 세로로 나열 (아이콘 + 텍스트)
        child: Column(
          mainAxisSize: MainAxisSize.min,  // 필요한 만큼만 공간 차지
          children: [
            // Stack: 자식 위젯들을 겹쳐서 배치 (아이콘 위에 배지를 올리기 위해)
            Stack(
              clipBehavior: Clip.none,  // 영역 밖으로 나가도 잘리지 않음
              children: [
                // AnimatedContainer: 속성이 변할 때 애니메이션 효과
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),  // 애니메이션 시간
                  padding: const EdgeInsets.all(AppSizes.paddingS),
                  decoration: BoxDecoration(
                    // 활성 상태면 배경색 표시, 아니면 투명
                    color: isActive
                        ? activeColor.withValues(alpha: AppOpacity.o15)  // 15% 투명도
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppSizes.radiusM),  // 둥근 모서리
                  ),
                  // Icon: 아이콘 위젯
                  child: Icon(
                    isActive ? activeIcon : icon,  // 활성 상태에 따라 아이콘 변경
                    color: isActive 
                        ? activeColor 
                        : Theme.of(context).brightness == Brightness.dark
                            ? Theme.of(context).colorScheme.onSurfaceVariant
                            : Theme.of(context).colorScheme.outlineVariant,  // 다크모드 대응
                    size: AppSizes.bottomNavIconSize,  // 아이콘 크기
                  ),
                ),
                
                // 배지가 있으면 표시 (if 문)
                if (badge != null && badge > 0)
                  // Positioned: Stack 안에서 위치를 지정
                  Positioned(
                    top: 0,  // 위쪽 끝
                    right: 0,  // 오른쪽 끝
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,  // 빨간색 배경
                        borderRadius: BorderRadius.circular(AppSizes.radiusS),  // 둥근 모양
                      ),
                      child: Text(
                        badge > 99 ? '99+' : '$badge',  // 99 초과면 '99+' 표시
                        style: AppTextStyles.labelSmall(context).withWeight(FontWeight.w600).withColor(Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 2),  // 아이콘과 텍스트 사이 간격
            
            // 버튼 아래 텍스트
            Text(
              label,
              style: AppTextStyles.caption(context)
                  .withWeight(isActive ? FontWeight.w600 : FontWeight.w400)
                  .withColor(isActive 
                      ? activeColor 
                      : Theme.of(context).brightness == Brightness.dark
                          ? Theme.of(context).colorScheme.onSurfaceVariant
                          : Theme.of(context).colorScheme.outlineVariant),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 🔢 _getIndexFromLocation - URL 경로를 인덱스 번호로 변환
  // ============================================================
  // 예: '/' -> 0, '/dating' -> 1, '/chat' -> 2, '/market' -> 3, '/social' -> 4
  // 이 함수는 현재 어느 화면에 있는지 알아내기 위해 사용됩니다
  int _getIndexFromLocation(String location) {
    // switch: 여러 경우의 수를 처리하는 문법
    switch (location) {
      case '/':  // 홈 화면
        return 0;
      case '/dating':  // 데이팅 화면
        return 1;
      case '/chat':  // 채팅 화면
        return 2;
      case '/market':  // 마켓 화면
        return 3;
      case '/social':  // 소셜 화면
        return 4;
      default:  // 그 외의 경우 (산책, 건강수첩, 프로필 등)
        return 0;  // 기본값으로 홈(0) 반환
    }
  }
}
