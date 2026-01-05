import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
// TODO: 실제 기기 테스트 시 주석 해제
// import 'package:kakao_maps_flutter/kakao_maps_flutter.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'core/services/notification_service.dart';

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
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // FCM 백그라운드 핸들러 등록
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // 푸시 알림 서비스 초기화
  await NotificationService().initialize();
  
  // TODO: 실제 기기 테스트 시 주석 해제
  // 카카오 지도 SDK 초기화
  // await KakaoMapsFlutter.init('9d259b071721f1a6c369c9074076c657');
  
  // 앱 실행
  runApp(
    const ProviderScope(
      child: MingrrApp(),
    ),
  );
}
