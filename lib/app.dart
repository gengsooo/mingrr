// ============================================================
// 필요한 패키지들을 불러옵니다 (import)
// ============================================================
import 'package:flutter/material.dart';  // Flutter의 기본 UI 위젯들
import 'package:flutter_riverpod/flutter_riverpod.dart';  // 상태 관리 라이브러리
import 'package:flutter_localizations/flutter_localizations.dart';  // 한글화 지원

// 우리 앱의 커스텀 파일들
import 'core/theme/app_theme.dart';  // 앱 테마
import 'core/constants/app_strings.dart';  // 텍스트 상수
import 'core/providers/theme_provider.dart';  // 테마 Provider

// 라우터 (분리됨)
import 'router/app_router.dart';

// 외부에서 rootNavigatorKey, routerProvider 접근 가능하도록 re-export
export 'router/app_router.dart' show rootNavigatorKey, routerProvider;

/// ============================================================
/// MINGRR 앱 메인 위젯 (Firebase 연동 버전)
/// 라우팅, 테마, 전역 상태 관리 설정
/// ============================================================

// ============================================================
// 📱 MingrrApp - 앱의 최상위 위젯 (Firebase 연동 버전)
// ============================================================
// - 로그인 상태를 확인하는 라우터를 사용합니다
// - Firebase 인증이 연동되어 있습니다
class MingrrApp extends ConsumerWidget {
  const MingrrApp({super.key});

  // build 메서드: 화면에 무엇을 그릴지 정의하는 함수
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 위에서 정의한 라우터를 가져옵니다 (로그인 체크 기능 포함)
    final router = ref.watch(routerProvider);

    // 테마 모드 가져오기 (상태 변경 감지를 위해 state를 watch)
    // ignore: unused_local_variable - 상태 변경 감지용으로 watch 필요
    final _ = ref.watch(themeModeProvider);
    final themeModeNotifier = ref.read(themeModeProvider.notifier);

    // MaterialApp.router: Flutter 앱의 최상위 위젯
    return MaterialApp.router(
      title: AppStrings.appName,  // 앱 이름
      debugShowCheckedModeBanner: false,  // 디버그 배너 숨기기
      theme: AppTheme.lightTheme,  // 라이트 테마
      darkTheme: AppTheme.darkTheme,  // 다크 테마
      themeMode: themeModeNotifier.themeMode,  // 테마 모드 (시스템/라이트/다크) - themeMode 변경 시 rebuild됨
      routerConfig: router,  // 라우터 설정 (로그인 체크 포함)
      // 한글화 설정
      locale: const Locale('ko', 'KR'),
      supportedLocales: const [
        Locale('ko', 'KR'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
