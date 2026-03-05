// ============================================================
// 필요한 패키지들을 불러옵니다 (import)
// ============================================================
import 'package:flutter/material.dart';  // Flutter의 기본 UI 위젯들 (버튼, 텍스트 등)
import 'package:flutter_riverpod/flutter_riverpod.dart';  // 상태 관리 라이브러리 (데이터를 여러 화면에서 공유)
import 'package:go_router/go_router.dart';  // 화면 이동(라우팅)을 관리하는 라이브러리

// 우리 앱의 커스텀 파일들을 불러옵니다
import 'core/constants/app_icons.dart';  // 앱에서 사용하는 아이콘 상수
import 'core/theme/app_theme.dart';  // 앱의 전체적인 디자인 테마 (색상, 폰트 등)
import 'core/constants/app_strings.dart';  // 앱에서 사용하는 모든 텍스트 상수
import 'core/theme/feature_colors.dart';  // 앱에서 사용하는 색상 상수
import 'core/constants/app_sizes.dart';  // 앱에서 사용하는 크기/간격 상수
import 'core/theme/app_text_styles.dart';  // 텍스트 스타일

// 각 기능별 화면들을 불러옵니다
import 'features/home/presentation/screens/home_screen.dart';  // 홈 화면
import 'features/dating/presentation/screens/dating_screen.dart';  // 데이팅 화면
import 'features/marketplace/presentation/screens/marketplace_screen.dart';  // 마켓 화면
import 'features/health/presentation/screens/health_screen.dart';  // 건강수첩 화면
import 'features/social/presentation/screens/social_screen.dart';  // 소셜 화면
import 'features/chat/presentation/screens/chat_list_screen.dart';  // 채팅 목록 화면
import 'features/profile/presentation/screens/profile_screen.dart';  // 프로필 화면

/// ============================================================
/// MINGRR 데모 앱 (V1 리팩토링)
/// 바텀 네비게이션: 홈, 데이팅, 채팅, 마켓, 소모임
/// 프로필은 홈 우상단에서 접근
/// ============================================================

// ============================================================
// 📍 라우터 Provider (화면 이동 관리자)
// ============================================================
// Provider란? 앱 전체에서 공유되는 데이터나 기능을 제공하는 것
// 여기서는 "어떤 URL로 가면 어떤 화면을 보여줄지" 정의합니다
final demoRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    // 앱이 처음 시작될 때 보여줄 화면 경로
    initialLocation: '/',  // '/' = 홈 화면
    
    // 앱의 모든 화면 경로를 정의합니다
    routes: [
      // ========================================
      // ShellRoute: 바텀 네비게이션이 있는 메인 화면들
      // ========================================
      // ShellRoute는 여러 화면이 공통으로 사용하는 레이아웃(바텀바)을 제공합니다
      ShellRoute(
        // builder: 모든 자식 화면을 감싸는 레이아웃을 만듭니다
        builder: (context, state, child) => DemoMainShell(child: child),
        
        // 바텀 네비게이션이 있는 5개 화면들
        routes: [
          // 1️⃣ 홈 화면 (경로: '/')
          GoRoute(
            path: '/',  // URL 경로
            builder: (context, state) => const HomeScreen(),  // 보여줄 화면
          ),
          
          // 2️⃣ 데이팅 화면 (경로: '/dating', 쿼리: ?tab=0,1,2)
          GoRoute(
            path: '/dating',
            builder: (context, state) {
              final tabParam = state.uri.queryParameters['tab'];
              final initialTab = int.tryParse(tabParam ?? '0') ?? 0;
              return DatingScreen(initialTab: initialTab);
            },
          ),
          
          // 3️⃣ 채팅 화면 (경로: '/chat')
          GoRoute(
            path: '/chat',
            builder: (context, state) => const ChatListScreen(),
          ),
          
          // 4️⃣ 마켓 화면 (경로: '/market')
          GoRoute(
            path: '/market',
            builder: (context, state) => const MarketplaceScreen(),
          ),
          
          // 5️⃣ 소셜 화면 (경로: '/social')
          GoRoute(
            path: '/social',
            builder: (context, state) => const SocialScreen(),
          ),
        ],
      ),
      
      // ========================================
      // 독립 화면들 (바텀 네비게이션 없음)
      // ========================================
      // 이 화면들은 바텀바 없이 전체 화면으로 표시됩니다
      
      // 프로필 화면 (경로: '/profile')
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      
      // 건강수첩 화면 (경로: '/health')
      GoRoute(
        path: '/health',
        builder: (context, state) => const HealthScreen(),
      ),
    ],
  );
});

// ============================================================
// 📱 MingrrDemoApp - 앱의 최상위 위젯 (앱의 시작점)
// ============================================================
// ConsumerWidget이란? Riverpod의 Provider를 사용할 수 있는 위젯
// 일반 StatelessWidget과 비슷하지만 ref를 통해 Provider에 접근 가능
class MingrrDemoApp extends ConsumerWidget {
  const MingrrDemoApp({super.key});

  // build 메서드: 화면에 무엇을 그릴지 정의하는 함수
  // context: 현재 위젯의 위치 정보
  // ref: Provider에 접근할 수 있는 도구
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 위에서 정의한 라우터를 가져옵니다
    // ref.watch()는 Provider의 값을 "구독"합니다 (값이 바뀌면 화면도 자동으로 업데이트)
    final router = ref.watch(demoRouterProvider);

    // MaterialApp.router: Flutter 앱의 최상위 위젯
    // 앱의 전체적인 설정(테마, 라우팅 등)을 담당합니다
    return MaterialApp.router(
      title: AppStrings.appName,  // 앱 이름 (작업 관리자에서 보이는 이름)
      debugShowCheckedModeBanner: false,  // 오른쪽 상단 "DEBUG" 배너 숨기기
      theme: AppTheme.lightTheme,  // 앱의 전체 디자인 테마 적용
      routerConfig: router,  // 위에서 만든 라우터 설정 적용
    );
  }
}

// ============================================================
// 🏠 DemoMainShell - 바텀 네비게이션이 있는 메인 레이아웃
// ============================================================
// StatelessWidget이란? 상태가 변하지 않는 위젯 (한 번 만들어지면 내용이 안 바뀜)
class DemoMainShell extends StatelessWidget {
  // child: 바텀바 위에 표시될 실제 화면 (홈, 데이팅, 채팅 등)
  final Widget child;

  const DemoMainShell({
    super.key,
    required this.child,  // required: 반드시 값을 전달해야 함
  });

  @override
  Widget build(BuildContext context) {
    // Scaffold: Flutter의 기본 화면 구조를 제공하는 위젯
    // 상단바(AppBar), 본문(body), 하단바(bottomNavigationBar) 등을 배치할 수 있음
    return Scaffold(
      body: child,  // 본문 영역: 현재 선택된 화면을 표시
      bottomNavigationBar: const DemoBottomNavBar(),  // 하단 네비게이션 바
    );
  }
}

// ============================================================
// 📊 DemoBottomNavBar - 하단 네비게이션 바 (5개 탭)
// ============================================================
// 홈, 데이팅, 채팅, 마켓, 소모임 5개 버튼을 표시하고
// 현재 어느 화면에 있는지 표시합니다
class DemoBottomNavBar extends StatelessWidget {
  const DemoBottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    // 현재 URL 경로를 가져옵니다 (예: '/', '/dating', '/chat' 등)
    final location = GoRouterState.of(context).matchedLocation;
    
    // URL 경로를 숫자 인덱스로 변환합니다 (0=홈, 1=데이팅, 2=채팅, 3=마켓, 4=소모임)
    final currentIndex = _getIndexFromLocation(location);

    // Container: 박스 형태의 위젯 (배경색, 그림자, 크기 등을 설정 가능)
    return Container(
      // decoration: 컨테이너의 꾸미기 (배경색, 테두리, 그림자 등)
      decoration: BoxDecoration(
        color: Colors.white,  // 배경색: 흰색
        boxShadow: AppShadows.shadowL(Theme.of(context).brightness == Brightness.dark),
      ),
      // SafeArea: 노치(카메라 구멍)나 홈 버튼 영역을 피해서 내용을 표시
      child: SafeArea(
        child: Container(
          height: AppSizes.bottomNavHeight,  // 바텀바 높이
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingS),  // 좌우 여백
          
          // Row: 자식 위젯들을 가로로 나열
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,  // 자식들을 균등하게 배치
            children: [
              // 1️⃣ 홈 버튼
              _buildNavItem(
                context: context,
                icon: AppIcons.homeOutlined,  // 비활성 상태 아이콘 (빈 집)
                activeIcon: AppIcons.home,  // 활성 상태 아이콘 (꽉 찬 집)
                label: '홈',  // 버튼 아래 텍스트
                index: 0,  // 이 버튼의 인덱스 번호
                currentIndex: currentIndex,  // 현재 선택된 인덱스
                route: '/',  // 이 버튼을 누르면 이동할 경로
              ),
              
              // 2️⃣ 데이팅 버튼
              _buildNavItem(
                context: context,
                icon: AppIcons.datingOutlined,
                activeIcon: AppIcons.dating,
                label: '데이팅',
                index: 1,
                currentIndex: currentIndex,
                route: '/dating',
                color: context.features.dating,  // 커스텀 색상 (핑크)
              ),
              
              // 3️⃣ 채팅 버튼
              _buildNavItem(
                context: context,
                icon: AppIcons.chatBubbleOutlined,
                activeIcon: AppIcons.chatBubble,
                label: '채팅',
                index: 2,
                currentIndex: currentIndex,
                route: '/chat',
                color: context.features.chat,  // 커스텀 색상 (파랑)
                badge: 3,  // 배지 숫자 (읽지 않은 메시지 3개)
              ),
              
              // 4️⃣ 마켓 버튼
              _buildNavItem(
                context: context,
                icon: AppIcons.marketOutlined,
                activeIcon: AppIcons.market,
                label: '마켓',
                index: 3,
                currentIndex: currentIndex,
                route: '/market',
                color: context.features.market,  // 커스텀 색상 (주황)
              ),
              
              // 5️⃣ 소셜 버튼
              _buildNavItem(
                context: context,
                icon: AppIcons.forumOutlined,
                activeIcon: AppIcons.forum,
                label: '소셜',
                index: 4,
                currentIndex: currentIndex,
                route: '/social',
                color: context.features.social,  // 커스텀 색상 (보라)
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
  // 매개변수 설명:
  // - icon: 비활성 상태 아이콘
  // - activeIcon: 활성 상태 아이콘
  // - label: 버튼 아래 텍스트
  // - index: 이 버튼의 번호
  // - currentIndex: 현재 선택된 버튼 번호
  // - route: 이 버튼을 누르면 이동할 경로
  // - color: 활성 상태 색상 (선택사항)
  // - badge: 배지 숫자 (선택사항, 예: 읽지 않은 메시지 수)
  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required int currentIndex,
    required String route,
    Color? color,  // ? = null 가능 (선택사항)
    int? badge,
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
          horizontal: AppSizes.paddingM,  // 좌우 여백
          vertical: AppSizes.paddingS,  // 상하 여백
        ),
        
        // Column: 자식 위젯들을 세로로 나열
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
                    color: isActive ? activeColor : Theme.of(context).colorScheme.outlineVariant,  // 색상 변경
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
                  .withColor(isActive ? activeColor : Theme.of(context).colorScheme.outlineVariant),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 🔢 _getIndexFromLocation - URL 경로를 인덱스 번호로 변환
  // ============================================================
  // 예: '/' -> 0, '/dating' -> 1, '/chat' -> 2 등
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
      default:  // 그 외의 경우 (프로필, 건강수첩 등)
        return 0;  // 기본값으로 홈(0) 반환
    }
  }
}
