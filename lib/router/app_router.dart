// ============================================================
// 📍 MINGRR 라우터 설정
// GoRouter 기반 화면 이동 + 로그인 체크
// ============================================================
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// 인증 관련
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/email_verification_screen.dart';

// 각 기능별 화면들
import '../features/home/presentation/screens/home_screen.dart';
import '../features/dating/presentation/screens/dating_screen.dart';
import '../features/dating/presentation/screens/pet_detail_screen.dart';
import '../features/walk/presentation/screens/walk_screen.dart';
import '../features/marketplace/presentation/screens/marketplace_screen.dart';
import '../features/health/presentation/screens/health_screen.dart';
import '../features/social/presentation/screens/social_screen.dart';
import '../features/social/presentation/screens/group_detail_screen.dart';
import '../features/social/presentation/screens/community_detail_screen.dart';
import '../features/chat/presentation/screens/chat_list_screen.dart';
import '../features/chat/presentation/screens/chat_detail_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/profile/presentation/screens/pending_ratings_screen.dart';
import '../features/profile/presentation/screens/rating_history_screen.dart';
import '../features/dev/dev_tools_screen.dart';
import '../features/notification/presentation/screens/notification_screen.dart';
import '../features/marketplace/presentation/screens/job_detail_screen.dart';
import '../features/marketplace/presentation/screens/product_detail_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';

// 쉘 & 스플래시
import '../shell/main_shell.dart';
import '../shell/splash_screen.dart';

// ============================================================
// 라우터 Provider (화면 이동 + 로그인 체크)
// ============================================================
// 최적화: refreshListenable을 사용하여 라우터 재생성 방지
// authStateProvider를 watch하면 상태 변경 시 라우터가 재생성되어 깜빡임 발생

/// 인증 상태 변경을 감지하는 Listenable
class AuthStateNotifier extends ChangeNotifier {
  AuthStateNotifier(this._ref) {
    _ref.listen(authStateProvider, (_, _) {
      notifyListeners();
    });
  }
  final Ref _ref;
}

final _authStateListenableProvider = Provider<AuthStateNotifier>((ref) {
  return AuthStateNotifier(ref);
});

/// 전역 네비게이터 키 (알림 서비스에서 사용)
final rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authStateListenable = ref.watch(_authStateListenableProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: authStateListenable,
    
    // ============================================================
    // redirect: 화면 이동 전에 실행되는 함수 (로그인 체크)
    // ============================================================
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final isLoading = authState.isLoading;
      final user = authState.valueOrNull;
      final isLoggedIn = user != null;
      final path = state.uri.path;
      final isSplashRoute = path == '/splash';
      final isLoginRoute = path == '/login';
      final isDevToolsRoute = path == '/dev-tools';
      final isOnboardingRoute = path == '/onboarding';
      final isEmailVerificationRoute = path == '/email-verification';

      // 로딩 중이면 스플래시 화면으로 (깜빡임 방지)
      if (isLoading) {
        return isSplashRoute ? null : '/splash';
      }

      // 로딩 완료 후 스플래시 화면에 있으면 적절한 화면으로 이동
      // (온보딩 체크는 SplashScreen에서 비동기로 처리)
      if (isSplashRoute) {
        return null; // SplashScreen에서 직접 처리
      }

      // 케이스 1: 로그인 안 된 상태에서 보호된 페이지 접근 시 로그인으로 리다이렉트
      if (!isLoggedIn && !isLoginRoute && !isDevToolsRoute && !isOnboardingRoute) {
        return '/login';
      }

      // 케이스 2: 로그인 된 상태
      if (isLoggedIn) {
        // 이메일 로그인 사용자이고 이메일 미인증인 경우
        final isEmailUser = user.providerData.any((p) => p.providerId == 'password');
        final isEmailVerified = user.emailVerified;
        
        // ============================================================
        // [DEV] 개발용 테스트 계정 이메일 인증 우회
        // kDebugMode 가드로 프로덕션 빌드에서는 절대 우회되지 않음
        // 대상: admin@mingrr.com, test1@mingrr.com ~ test10@mingrr.com
        // ============================================================
        bool shouldBypassVerification = false;
        if (kDebugMode) {
          final devBypassEmails = [
            'admin@mingrr.com',
            ...List.generate(10, (i) => 'test${i + 1}@mingrr.com'),
          ];
          shouldBypassVerification = devBypassEmails.contains(user.email);
        }
        // ============================================================
        
        if (isEmailUser && !isEmailVerified && !shouldBypassVerification) {
          // 이메일 인증 화면이 아니면 인증 화면으로 리다이렉트
          if (!isEmailVerificationRoute) {
            return '/email-verification';
          }
        } else {
          // 인증 완료된 사용자가 로그인/인증 화면에 있으면 홈으로
          if (isLoginRoute || isEmailVerificationRoute) {
            return '/';
          }
        }
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
      // 온보딩 화면 (처음 실행 시)
      // ========================================
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => OnboardingScreen(
          onComplete: () {
            // 온보딩 완료 후 로그인 화면으로 이동
            GoRouter.of(context).go('/login');
          },
        ),
      ),
      
      // ========================================
      // 로그인 화면 (바텀 네비게이션 없음)
      // ========================================
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      
      // ========================================
      // 이메일 인증 대기 화면
      // ========================================
      GoRoute(
        path: '/email-verification',
        builder: (context, state) => const EmailVerificationScreen(),
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
          
          // 2️⃣ 데이팅 화면 (경로: '/dating', 쿼리: ?tab=0,1,2)
          GoRoute(
            path: '/dating',
            builder: (context, state) {
              final tabParam = state.uri.queryParameters['tab'];
              final initialTab = int.tryParse(tabParam ?? '0') ?? 0;
              return DatingScreen(initialTab: initialTab);
            },
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
          
          // 5️⃣ 소셜 화면 (경로: '/social', 쿼리: ?tab=0,1)
          GoRoute(
            path: '/social',
            builder: (context, state) {
              final tabParam = state.uri.queryParameters['tab'];
              final initialTab = int.tryParse(tabParam ?? '0') ?? 0;
              return SocialScreen(initialTab: initialTab);
            },
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
      
      // 건강수첩 화면 (경로: '/health', 쿼리: petId)
      GoRoute(
        path: '/health',
        builder: (context, state) {
          final petId = state.uri.queryParameters['petId'];
          return HealthScreen(initialPetId: petId);
        },
      ),
      
      // 프로필 화면 (경로: '/profile') - 독립 화면
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      
      // 평가 대기 목록 화면 (경로: '/profile/pending-ratings')
      GoRoute(
        path: '/profile/pending-ratings',
        builder: (context, state) => const PendingRatingsScreen(),
      ),
      
      // 평가 이력 화면 (경로: '/profile/rating-history')
      GoRoute(
        path: '/profile/rating-history',
        builder: (context, state) => const RatingHistoryScreen(),
      ),
      
      // 반려동물 상세 화면 (경로: '/dating/detail/:id')
      GoRoute(
        path: '/dating/detail/:id',
        builder: (context, state) {
          final petId = state.pathParameters['id'] ?? '';
          return PetDetailScreen(petId: petId);
        },
      ),
      
      // 소모임 상세 화면 (경로: '/social/group/:id')
      GoRoute(
        path: '/social/group/:id',
        builder: (context, state) {
          final groupId = state.pathParameters['id'] ?? '';
          return GroupDetailScreen(groupId: groupId);
        },
      ),
      
      // 커뮤니티 게시글 상세 화면 (경로: '/social/community/:id')
      GoRoute(
        path: '/social/community/:id',
        builder: (context, state) {
          final postId = state.pathParameters['id'] ?? '';
          return CommunityDetailScreen(postId: postId);
        },
      ),
      
      // 개발자 도구 화면 (경로: '/dev-tools', debug 빌드 전용)
      if (kDebugMode)
        GoRoute(
          path: '/dev-tools',
          builder: (context, state) => const DevToolsScreen(),
        ),
      
      // 알림 화면 (경로: '/notifications')
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationScreen(),
      ),
      
      // 알바 상세 화면 (경로: '/market/job/:id')
      GoRoute(
        path: '/market/job/:id',
        builder: (context, state) {
          final jobId = state.pathParameters['id'] ?? '';
          return JobDetailScreen(jobId: jobId);
        },
      ),
      
      // 상품 상세 화면 (경로: '/market/product/:id')
      GoRoute(
        path: '/market/product/:id',
        builder: (context, state) {
          final productId = state.pathParameters['id'] ?? '';
          return ProductDetailScreen(productId: productId);
        },
      ),
      
      // 채팅 상세 화면 (경로: '/chat/:id')
      GoRoute(
        path: '/chat/:id',
        builder: (context, state) {
          final chatRoomId = state.pathParameters['id'] ?? '';
          return ChatDetailScreen(chatRoomId: chatRoomId);
        },
      ),
    ],
  );
});
