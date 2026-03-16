import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:kakao_map_sdk/kakao_map_sdk.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao_sdk;
import 'firebase_options.dart';
import 'app.dart';
import 'core/config/api_config.dart';
import 'core/services/kkosunnae_service.dart';
import 'core/services/network_service.dart';
import 'core/services/firebase_service.dart';
import 'core/services/rating_service.dart';
import 'core/utils/app_logger.dart';
import 'features/dating/presentation/providers/dating_request_provider.dart';
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
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Firestore 설정 초기화 (오프라인 지속성, 캐시 크기 등)
    await FirebaseService.initializeFirestore();
  } catch (e) {
    AppLogger.error('Main', 'Firebase 초기화 실패', e);
  }

  // 카카오 SDK 초기화 (로그인용) — ApiConfig에서 키 관리 단일화
  kakao_sdk.KakaoSdk.init(nativeAppKey: ApiConfig.kakaoNativeAppKey);

  // FCM 백그라운드 핸들러 등록
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // 푸시 알림 서비스 초기화
  await NotificationService().initialize();
  
  // ── 병렬 초기화 그룹 ──
  // Firebase 초기화 완료 후 독립적인 서비스들을 동시에 실행하여 앱 시작 시간 단축
  await Future.wait([
    // 1) ApiConfig → 카카오맵 SDK (순차 의존)
    _initApiConfigAndKakaoMap(),
    // 2) 꼬순내지수 등급 구간 (Firestore config 컬렉션만 의존)
    _initKkosunnae(),
    // 3) 만료된 비공개 평가 공개 (Firestore만 의존)
    _initRevealExpiredRatings(),
    // 4) 네트워크 서비스 (완전 독립)
    _initNetworkService(),
  ]);
  
  // 만료된 신청 자동 처리 (백그라운드 fire-and-forget)
  _processExpiredRequests();
  
  // 앱 실행
  runApp(
    const ProviderScope(
      child: MingrrApp(),
    ),
  );
}

/// ApiConfig 초기화 → 카카오맵 SDK 초기화 (순차 의존)
Future<void> _initApiConfigAndKakaoMap() async {
  try {
    await ApiConfig.initialize();
    AppLogger.info('Main', 'API Config 초기화 완료');
  } catch (e) {
    AppLogger.error('Main', 'API Config 초기화 실패', e);
    return;
  }

  if (ApiConfig.hasKakaoMapKey) {
    try {
      AppLogger.debug('Main', '카카오맵 SDK 초기화 시작...');
      AppLogger.debug('Main', '카카오맵 키: ${ApiConfig.kakaoMapKey.substring(0, 8)}...');
      await KakaoMapSdk.instance.initialize(ApiConfig.kakaoMapKey);
      ApiConfig.setKakaoMapSdkInitialized(true);
      AppLogger.info('Main', '카카오맵 SDK 초기화 성공');
    } catch (e) {
      AppLogger.error('Main', '카카오맵 초기화 실패', e);
      ApiConfig.setKakaoMapSdkInitialized(false);
    }
  } else {
    AppLogger.warning('Main', '카카오맵 API 키가 설정되지 않음 (Firebase Remote Config에서 kakao_map_key 설정 필요)');
    ApiConfig.setKakaoMapSdkInitialized(false);
  }
}

/// 꼬순내지수 등급 구간 로드
Future<void> _initKkosunnae() async {
  try {
    await KkosunnaeService.loadGradeThresholds();
    AppLogger.info('Main', '꼬순내지수 등급 구간 로드 완료');
  } catch (e) {
    AppLogger.error('Main', '꼬순내지수 등급 구간 로드 실패', e);
  }
}

/// 만료된 비공개 평가 공개 처리
Future<void> _initRevealExpiredRatings() async {
  try {
    await RatingService().revealExpiredRatings();
    AppLogger.info('Main', '만료된 평가 공개 처리 완료');
  } catch (e) {
    AppLogger.error('Main', '만료된 평가 공개 처리 실패', e);
  }
}

/// 네트워크 서비스 초기화
Future<void> _initNetworkService() async {
  try {
    await NetworkService().initialize();
    AppLogger.info('Main', '네트워크 서비스 초기화 완료');
  } catch (e) {
    AppLogger.error('Main', '네트워크 서비스 초기화 실패', e);
  }
}

/// 만료된 신청 자동 처리 (백그라운드)
Future<void> _processExpiredRequests() async {
  try {
    final count = await DatingRequestActionService.expireOldRequests();
    if (count > 0) {
      AppLogger.info('Main', '$count개의 만료된 신청 처리 완료');
    }
  } catch (e) {
    AppLogger.warning('Main', '만료 신청 처리 중 오류 (무시됨)');
  }
}
