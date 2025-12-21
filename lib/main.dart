import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_demo.dart';

/// ============================================================
/// MINGRR - 반려동물 커뮤니티 앱
/// 
/// 주요 기능:
/// - 반려동물 데이팅 (AI 추천 + 위치 기반)
/// - 산책 친구 찾기 & 발자국 남기기
/// - 중고거래 & 나눔
/// - 건강 수첩 (예방접종, 체중, 배변, 산책 기록)
/// - 교배 매칭
/// - 소모임 & 클래스
/// 
/// 기술 스택:
/// - Frontend: Flutter
/// - Backend: Firebase (Auth, Firestore, Storage, Messaging)
/// - State Management: Riverpod
/// 
/// 참고: 현재 데모 모드로 실행됩니다.
/// Firebase 연동 시 app.dart를 import하고 MingrrApp()을 사용하세요.
/// ============================================================

void main() async {
  // Flutter 바인딩 초기화
  WidgetsFlutterBinding.ensureInitialized();

  // 앱 실행 (데모 모드 - Firebase 없이 UI 테스트 가능)
  runApp(
    const ProviderScope(
      child: MingrrDemoApp(),
    ),
  );
}

/// ============================================================
/// Firebase 연동 시 아래 코드로 교체:
/// ============================================================
/// 
/// import 'package:firebase_core/firebase_core.dart';
/// import 'app.dart';
/// 
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await Firebase.initializeApp();
///   runApp(const ProviderScope(child: MingrrApp()));
/// }
/// ============================================================
