import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
// TODO: Personal Team 테스트 시 주석 처리 (Push Notifications 미지원)
// import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:kakao_map_sdk/kakao_map_sdk.dart';
import 'firebase_options.dart';
import 'app.dart';
// import 'core/services/notification_service.dart';

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
/// ============================================================

void main() async {
  // Flutter 바인딩 초기화
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    if (kDebugMode) debugPrint('Firebase 초기화 실패: $e');
  }

  // TODO: Personal Team 테스트 시 주석 처리
  // FCM 백그라운드 핸들러 등록
  // FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // 푸시 알림 서비스 초기화
  // await NotificationService().initialize();
  
  // 카카오 지도 SDK 초기화 (오류 발생 시 무시)
  try {
    if (kDebugMode) debugPrint('🗺️ 카카오맵 SDK 초기화 시작...');
    await KakaoMapSdk.instance.initialize('e80e09aa4db6c1f3d1eedb1be73ee8c6');
    if (kDebugMode) debugPrint('✅ 카카오맵 SDK 초기화 성공!');
  } catch (e) {
    if (kDebugMode) debugPrint('❌ 카카오맵 초기화 실패: $e');
  }
  
  // 앱 실행
  runApp(
    const ProviderScope(
      child: MingrrApp(),
    ),
  );
}
