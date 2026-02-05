import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
// TODO: Personal Team 테스트 시 주석 처리 (Push Notifications 미지원)
// import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:kakao_map_sdk/kakao_map_sdk.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'core/config/api_config.dart';
import 'core/services/kkosunnae_service.dart';
import 'core/services/network_service.dart';
import 'core/services/firebase_service.dart';
import 'core/utils/app_logger.dart';
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
    
    // Firestore 설정 초기화 (오프라인 지속성, 캐시 크기 등)
    await FirebaseService.initializeFirestore();
  } catch (e) {
    AppLogger.error('Main', 'Firebase 초기화 실패', e);
  }

  // TODO: Personal Team 테스트 시 주석 처리
  // FCM 백그라운드 핸들러 등록
  // FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // 푸시 알림 서비스 초기화
  // await NotificationService().initialize();
  
  // Firebase Remote Config 초기화 (API 키 로드)
  try {
    await ApiConfig.initialize();
    AppLogger.info('Main', 'API Config 초기화 완료');
  } catch (e) {
    AppLogger.error('Main', 'API Config 초기화 실패', e);
  }
  
  // 카카오 지도 SDK 초기화 (API 키가 설정된 경우에만)
  if (ApiConfig.hasKakaoMapKey) {
    try {
      AppLogger.debug('Main', '카카오맵 SDK 초기화 시작...');
      await KakaoMapSdk.instance.initialize(ApiConfig.kakaoMapKey);
      AppLogger.info('Main', '카카오맵 SDK 초기화 성공');
    } catch (e) {
      AppLogger.error('Main', '카카오맵 초기화 실패', e);
    }
  } else {
    AppLogger.warning('Main', '카카오맵 API 키가 설정되지 않음 (Firebase Remote Config에서 kakao_map_key 설정 필요)');
  }
  
  // 꼬순내지수 등급 구간 로드 (하이브리드 방식)
  try {
    await KkosunnaeService.loadGradeThresholds();
    AppLogger.info('Main', '꼬순내지수 등급 구간 로드 완료');
  } catch (e) {
    AppLogger.error('Main', '꼬순내지수 등급 구간 로드 실패', e);
  }
  
  // 네트워크 서비스 초기화
  try {
    await NetworkService().initialize();
    AppLogger.info('Main', '네트워크 서비스 초기화 완료');
  } catch (e) {
    AppLogger.error('Main', '네트워크 서비스 초기화 실패', e);
  }
  
  // 앱 실행
  runApp(
    const ProviderScope(
      child: MingrrApp(),
    ),
  );
}
