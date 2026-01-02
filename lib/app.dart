// ============================================================
// 필요한 패키지들을 불러옵니다 (import)
// ============================================================
import 'package:flutter/material.dart';  // Flutter의 기본 UI 위젯들
import 'package:flutter_riverpod/flutter_riverpod.dart';  // 상태 관리 라이브러리
import 'package:go_router/go_router.dart';  // 화면 이동(라우팅) 관리

// 우리 앱의 커스텀 파일들
import 'core/theme/app_theme.dart';  // 앱 테마
import 'core/constants/app_strings.dart';  // 텍스트 상수
import 'core/constants/app_colors.dart';  // 색상 상수
import 'core/constants/app_sizes.dart';  // 크기/간격 상수

// 인증 관련
import 'features/auth/presentation/providers/auth_provider.dart';  // 로그인 상태 관리 Provider
import 'features/auth/presentation/screens/login_screen.dart';  // 로그인 화면

// 각 기능별 화면들
import 'features/home/presentation/screens/home_screen.dart';  // 홈 화면
import 'features/dating/presentation/screens/dating_screen.dart';  // 데이팅 화면
import 'features/dating/presentation/screens/pet_detail_screen.dart';  // 반려동물 상세 화면
import 'features/walk/presentation/screens/walk_screen.dart';  // 산책 화면
import 'features/marketplace/presentation/screens/marketplace_screen.dart';  // 마켓 화면
import 'features/health/presentation/screens/health_screen.dart';  // 건강수첩 화면
import 'features/community/presentation/screens/community_screen.dart';  // 소모임 화면
import 'features/community/presentation/screens/group_detail_screen.dart';  // 소모임 상세 화면
import 'features/chat/presentation/screens/chat_list_screen.dart';  // 채팅 목록 화면
import 'features/profile/presentation/screens/profile_screen.dart';  // 프로필 화면
import 'features/dev/dev_tools_screen.dart';  // 개발자 도구 화면

/// ============================================================
/// MINGRR 앱 메인 위젯 (Firebase 연동 버전)
/// 라우팅, 테마, 전역 상태 관리 설정
/// ============================================================

// ============================================================
// 📍 라우터 Provider (화면 이동 + 로그인 체크)
// ============================================================
// 최적화: refreshListenable을 사용하여 라우터 재생성 방지
// authStateProvider를 watch하면 상태 변경 시 라우터가 재생성되어 깜빡임 발생

/// 인증 상태 변경을 감지하는 Listenable
class AuthStateNotifier extends ChangeNotifier {
  AuthStateNotifier(this._ref) {
    _ref.listen(authStateProvider, (_, __) {
      notifyListeners();
    });
  }
  final Ref _ref;
}

final _authStateListenableProvider = Provider<AuthStateNotifier>((ref) {
  return AuthStateNotifier(ref);
});

/// 인증 초기화 완료 여부를 추적하는 Provider
/// 웹에서 Firebase Auth가 세션을 복원할 때까지 대기
final _authInitializedProvider = FutureProvider<bool>((ref) async {
  // authStateProvider의 첫 번째 값을 기다림 (로딩 상태 아님)
  final authState = ref.watch(authStateProvider);
  // 로딩이 아니면 초기화 완료
  return !authState.isLoading;
});

final routerProvider = Provider<GoRouter>((ref) {
  final authStateListenable = ref.watch(_authStateListenableProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: authStateListenable,
    
    // ============================================================
    // redirect: 화면 이동 전에 실행되는 함수 (로그인 체크)
    // ============================================================
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final isLoading = authState.isLoading;
      final isLoggedIn = authState.valueOrNull != null;
      final path = state.uri.path;
      final isSplashRoute = path == '/splash';
      final isLoginRoute = path == '/login';
      final isDevToolsRoute = path == '/dev-tools';

      // 로딩 중이면 스플래시 화면으로 (깜빡임 방지)
      if (isLoading) {
        return isSplashRoute ? null : '/splash';
      }

      // 로딩 완료 후 스플래시 화면에 있으면 적절한 화면으로 이동
      if (isSplashRoute) {
        return isLoggedIn ? '/' : '/login';
      }

      // 케이스 1: 로그인 안 된 상태에서 보호된 페이지 접근 시 로그인으로 리다이렉트
      if (!isLoggedIn && !isLoginRoute && !isDevToolsRoute) {
        return '/login';
      }

      // 케이스 2: 로그인 된 상태에서 로그인 페이지면 홈으로 리다이렉트
      if (isLoggedIn && isLoginRoute) {
        return '/';
      }

      return null;
    },
    // 앱의 모든 화면 경로를 정의합니다
    routes: [
      // ========================================
      // 스플래시 화면 (인증 초기화 대기)
      // ========================================
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      
      // ========================================
      // 로그인 화면 (바텀 네비게이션 없음)
      // ========================================
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      
      // ========================================
      // ShellRoute: 바텀 네비게이션이 있는 메인 화면들
      // ========================================
      // 로그인 후 사용할 수 있는 화면들입니다
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        
        // 바텀 네비게이션이 있는 5개 화면들
        routes: [
          // 1️⃣ 홈 화면 (경로: '/')
          GoRoute(
            path: '/',
            builder: (context, state) => const HomeScreen(),
          ),
          
          // 2️⃣ 데이팅 화면 (경로: '/dating')
          GoRoute(
            path: '/dating',
            builder: (context, state) => const DatingScreen(),
          ),
          
          // 3️⃣ 마켓 화면 (경로: '/market')
          GoRoute(
            path: '/market',
            builder: (context, state) => const MarketplaceScreen(),
          ),
          
          // 4️⃣ 채팅 화면 (경로: '/chat')
          GoRoute(
            path: '/chat',
            builder: (context, state) => const ChatListScreen(),
          ),
          
          // 5️⃣ 소모임 화면 (경로: '/community') - 바텀바에서 접근
          GoRoute(
            path: '/community',
            builder: (context, state) => const CommunityScreen(),
          ),
        ],
      ),
      
      // ========================================
      // 독립 화면들 (바텀 네비게이션 없음)
      // ========================================
      // 이 화면들은 바텀바 없이 전체 화면으로 표시됩니다
      
      // 산책 화면 (경로: '/walk')
      GoRoute(
        path: '/walk',
        builder: (context, state) => const WalkScreen(),
      ),
      
      // 건강수첩 화면 (경로: '/health')
      GoRoute(
        path: '/health',
        builder: (context, state) => const HealthScreen(),
      ),
      
      // 프로필 화면 (경로: '/profile') - 독립 화면
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      
      // 반려동물 상세 화면 (경로: '/dating/detail/:id')
      GoRoute(
        path: '/dating/detail/:id',
        builder: (context, state) {
          final petId = state.pathParameters['id'] ?? '';
          return PetDetailScreen(petId: petId);
        },
      ),
      
      // 소모임 상세 화면 (경로: '/community/group/:id')
      GoRoute(
        path: '/community/group/:id',
        builder: (context, state) {
          final groupId = state.pathParameters['id'] ?? '';
          return GroupDetailScreen(groupId: groupId);
        },
      ),
      
      // 개발자 도구 화면 (경로: '/dev-tools')
      GoRoute(
        path: '/dev-tools',
        builder: (context, state) => const DevToolsScreen(),
      ),
    ],
  );
});

// ============================================================
// 📱 MingrrApp - 앱의 최상위 위젯 (Firebase 연동 버전)
// ============================================================
// 🔑 app_demo.dart와의 차이점:
// - 로그인 상태를 확인하는 라우터를 사용합니다
// - Firebase 인증이 연동되어 있습니다
class MingrrApp extends ConsumerWidget {
  const MingrrApp({super.key});

  // build 메서드: 화면에 무엇을 그릴지 정의하는 함수
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 위에서 정의한 라우터를 가져옵니다 (로그인 체크 기능 포함)
    final router = ref.watch(routerProvider);

    // MaterialApp.router: Flutter 앱의 최상위 위젯
    return MaterialApp.router(
      title: AppStrings.appName,  // 앱 이름
      debugShowCheckedModeBanner: false,  // 디버그 배너 숨기기
      theme: AppTheme.lightTheme,  // 앱 테마
      routerConfig: router,  // 라우터 설정 (로그인 체크 포함)
    );
  }
}

// ============================================================
// 🏠 MainShell - 바텀 네비게이션이 있는 메인 레이아웃
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
    return Scaffold(
      body: child,  // 본문: 현재 선택된 화면
      bottomNavigationBar: const MingrrBottomNavBar(),  // 하단 네비게이션 바
    );
  }
}

// ============================================================
// 📊 MingrrBottomNavBar - 하단 네비게이션 바 (5개 탭)
// ============================================================
// 홈, 데이팅, 마켓, 채팅, 프로필 5개 버튼을 표시합니다
class MingrrBottomNavBar extends StatelessWidget {
  const MingrrBottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    // 현재 URL 경로를 가져옵니다
    final location = GoRouterState.of(context).matchedLocation;
    
    // URL 경로를 숫자 인덱스로 변환 (0=홈, 1=데이팅, 2=마켓, 3=채팅, 4=프로필)
    final currentIndex = _getIndexFromLocation(location);

    // Container: 박스 형태의 위젯
    return Container(
      // decoration: 컨테이너 꾸미기
      decoration: BoxDecoration(
        color: Colors.white,  // 배경색: 흰색
        boxShadow: [  // 그림자 효과
          BoxShadow(
            color: Colors.black.withOpacity(0.05),  // 검은색 5% 투명도
            blurRadius: 20,  // 그림자 흐림 정도
            offset: const Offset(0, -5),  // 그림자 위치 (위쪽으로 5픽셀)
          ),
        ],
      ),
      // SafeArea: 노치나 홈 버튼 영역을 피해서 내용 표시
      child: SafeArea(
        child: Container(
          height: AppSizes.bottomNavHeight,  // 바텀바 높이
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingS),  // 좌우 여백
          
          // Row: 자식 위젯들을 가로로 나열
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,  // 균등하게 배치
            children: [
              // 1️⃣ 홈 버튼
              _buildNavItem(
                context: context,
                icon: Icons.home_outlined,  // 비활성 상태 아이콘
                activeIcon: Icons.home,  // 활성 상태 아이콘
                label: '홈',
                index: 0,
                currentIndex: currentIndex,
                route: '/',
              ),
              
              // 2️⃣ 데이팅 버튼
              _buildNavItem(
                context: context,
                icon: Icons.favorite_outline,
                activeIcon: Icons.favorite,
                label: '데이팅',
                index: 1,
                currentIndex: currentIndex,
                route: '/dating',
                color: AppColors.dating,  // 커스텀 색상 (핑크)
              ),
              
              // 3️⃣ 채팅 버튼
              _buildNavItem(
                context: context,
                icon: Icons.chat_bubble_outline,
                activeIcon: Icons.chat_bubble,
                label: '채팅',
                index: 2,
                currentIndex: currentIndex,
                route: '/chat',
                badge: 3,  // 배지 숫자 (읽지 않은 메시지 3개)
              ),
              
              // 4️⃣ 마켓 버튼
              _buildNavItem(
                context: context,
                icon: Icons.store_outlined,
                activeIcon: Icons.store,
                label: '마켓',
                index: 3,
                currentIndex: currentIndex,
                route: '/market',
                color: AppColors.market,  // 커스텀 색상 (주황)
              ),
              
              // 5️⃣ 소모임 버튼
              _buildNavItem(
                context: context,
                icon: Icons.groups_outlined,
                activeIcon: Icons.groups,
                label: '소모임',
                index: 4,
                currentIndex: currentIndex,
                route: '/community',
                color: AppColors.community,
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
    final activeColor = color ?? AppColors.primary;

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
                  duration: const Duration(milliseconds: 200),  // 애니메이션 시간
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    // 활성 상태면 배경색 표시, 아니면 투명
                    color: isActive
                        ? activeColor.withOpacity(0.15)  // 15% 투명도
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppSizes.radiusM),  // 둥근 모서리
                  ),
                  // Icon: 아이콘 위젯
                  child: Icon(
                    isActive ? activeIcon : icon,  // 활성 상태에 따라 아이콘 변경
                    color: isActive ? activeColor : AppColors.textHint,  // 색상 변경
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
                        color: AppColors.error,  // 빨간색 배경
                        borderRadius: BorderRadius.circular(10),  // 둥근 모양
                      ),
                      child: Text(
                        badge > 99 ? '99+' : '$badge',  // 99 초과면 '99+' 표시
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
            
            const SizedBox(height: 2),  // 아이콘과 텍스트 사이 간격
            
            // 버튼 아래 텍스트
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,  // 활성 상태면 굵게
                color: isActive ? activeColor : AppColors.textHint,  // 색상 변경
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 🔢 _getIndexFromLocation - URL 경로를 인덱스 번호로 변환
  // ============================================================
  // 예: '/' -> 0, '/dating' -> 1, '/chat' -> 2, '/market' -> 3, '/community' -> 4
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
      case '/community':  // 소모임 화면
        return 4;
      default:  // 그 외의 경우 (산책, 건강수첩, 프로필 등)
        return 0;  // 기본값으로 홈(0) 반환
    }
  }
}

// ============================================================
// 🚀 SplashScreen - 인증 초기화 대기 화면
// ============================================================
// 웹에서 Firebase Auth가 세션을 복원할 때까지 보여주는 화면
// 깜빡거림 방지를 위해 로딩 중에는 이 화면을 표시
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 앱 로고 또는 아이콘
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.pets,
                size: 50,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            // 앱 이름
            Text(
              AppStrings.appName,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 32),
            // 로딩 인디케이터
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
