# iOS 테스트 준비 가이드

## 📱 현재 프로젝트 상태

### ✅ 완료된 작업
1. **산책 기능 완전 구현**
   - 경로 추적 (GPS 기반)
   - 발자국 남기기 기능
   - Firebase 실시간 저장
   - 산책 기록 상세 보기 (경로 표시)

2. **Firebase 백엔드 연동**
   - Authentication (이메일/비밀번호, Google)
   - Firestore (모든 데이터 모델)
   - Storage (이미지 업로드)
   - Cloud Messaging (푸시 알림)

3. **iOS 설정 완료**
   - Info.plist에 위치 권한 설정 완료
   - 카카오맵 API 키 설정 완료
   - Podfile에 카카오맵 SDK 추가 완료

## 🚀 iOS 테스트 시작 전 체크리스트

### 1. 카카오맵 활성화
현재 카카오맵 관련 코드가 주석 처리되어 있습니다. iOS 테스트 시 다음 파일들의 주석을 해제하세요:

#### `lib/main.dart`
```dart
// kakao_map_sdk 패키지 사용
import 'package:kakao_map_sdk/kakao_map_sdk.dart';

// SDK 초기화
await KakaoMapSdk.instance.initialize('e80e09aa4db6c1f3d1eedb1be73ee8c6');
```

#### `lib/features/walk/presentation/screens/walk_screen.dart`
```dart
import 'package:kakao_map_sdk/kakao_map_sdk.dart';
```

### 2. CocoaPods 설치 및 설정

```bash
# iOS 디렉토리로 이동
cd ios

# Pod 설치
pod install

# 프로젝트 루트로 돌아가기
cd ..
```

### 3. Firebase 설정 확인

`ios/Runner/GoogleService-Info.plist` 파일이 존재하는지 확인하세요.
- 없다면 Firebase Console에서 iOS 앱을 추가하고 다운로드하세요.

### 4. Xcode에서 프로젝트 열기

```bash
# Xcode에서 workspace 열기 (중요: .xcworkspace를 열어야 함)
open ios/Runner.xcworkspace
```

### 5. Xcode 설정

1. **Signing & Capabilities**
   - Team 선택
   - Bundle Identifier 확인: `com.example.mingrr`

2. **Deployment Target**
   - iOS 13.0 이상으로 설정

3. **Capabilities 추가**
   - Background Modes → Location updates 체크
   - Push Notifications 활성화

### 6. 실제 기기 또는 시뮬레이터 선택

- **실제 기기 권장** (위치 추적 기능 테스트를 위해)
- 시뮬레이터 사용 시: Debug → Location → Custom Location으로 위치 시뮬레이션 가능

### 7. 빌드 및 실행

```bash
# Flutter 명령어로 실행
flutter run -d <device-id>

# 또는 Xcode에서 직접 Run (⌘ + R)
```

## 🧪 테스트해야 할 주요 기능

### 1. 산책 기능 테스트
- [ ] 산책 시작 버튼 클릭
- [ ] GPS 위치 추적 확인
- [ ] 발자국 남기기 버튼 테스트
- [ ] 산책 종료 후 기록 저장 확인
- [ ] 건강수첩 → 산책 탭에서 기록 확인
- [ ] 산책 기록 상세 화면에서 경로 표시 확인

### 2. 위치 권한 테스트
- [ ] 앱 최초 실행 시 위치 권한 요청 확인
- [ ] 권한 거부 시 적절한 안내 메시지 표시 확인

### 3. Firebase 연동 테스트
- [ ] 회원가입/로그인
- [ ] 반려동물 등록
- [ ] 산책 기록 Firebase 저장 확인
- [ ] 실시간 동기화 확인

## ⚠️ 알려진 제한사항

### 웹 테스트에서 제외된 기능들
현재 웹 테스트를 위해 다음 기능들이 플레이스홀더로 대체되어 있습니다:

1. **카카오맵** → iOS에서는 실제 지도 표시
2. **GPS 위치 추적** → iOS에서는 실제 위치 사용
3. **소셜 로그인 (카카오, 네이버)** → 아직 미구현 (요청에 따라 제외)

### 현재 활성화된 로그인 방법
- ✅ 이메일/비밀번호
- ✅ Google 소셜 로그인
- ❌ 카카오 로그인 (미구현)
- ❌ 네이버 로그인 (미구현)

## 🔧 문제 해결

### Pod install 오류
```bash
cd ios
pod deintegrate
pod install
```

### 빌드 오류
```bash
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter run
```

### 위치 권한 오류
Info.plist에 다음 키가 있는지 확인:
- `NSLocationWhenInUseUsageDescription`
- `NSLocationAlwaysUsageDescription`

## 📊 프로젝트 구조

```
lib/
├── main.dart                          # 앱 진입점 (카카오맵 초기화)
├── features/
│   ├── walk/                          # 산책 기능
│   │   └── presentation/
│   │       └── screens/
│   │           └── walk_screen.dart   # 산책 화면 (GPS 추적)
│   ├── health/                        # 건강수첩
│   │   ├── presentation/
│   │   │   ├── providers/
│   │   │   │   └── health_provider.dart  # 산책 기록 CRUD
│   │   │   └── screens/
│   │   │       ├── health_screen.dart
│   │   │       └── walk_record_detail_screen.dart  # 경로 표시
│   └── ...
├── models/
│   └── health_model.dart              # WalkRecordModel (경로, 발자국 포함)
└── core/
    └── services/
        └── location_service.dart      # 위치 계산 유틸리티
```

## 🎯 다음 단계

iOS 테스트가 성공적으로 완료되면:

1. **소셜 로그인 추가** (선택사항)
   - 카카오 로그인
   - 네이버 로그인

2. **추가 기능 구현**
   - 실시간 산책 친구 찾기
   - 산책 경로 공유
   - 산책 챌린지

3. **성능 최적화**
   - GPS 배터리 최적화
   - 이미지 캐싱
   - 오프라인 모드

## 📞 지원

문제가 발생하면 다음을 확인하세요:
1. Flutter Doctor: `flutter doctor -v`
2. iOS 로그: Xcode Console
3. Firebase Console: 실시간 데이터베이스 확인
