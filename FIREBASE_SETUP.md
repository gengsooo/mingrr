# Firebase 백엔드 설정 가이드

## ✅ 완료된 설정

### 1. Firebase 프로젝트 생성
- 프로젝트명: `mingrr`
- 리전: `asia-northeast3 (Seoul)`
- Firebase Authentication, Firestore, Storage 활성화

### 2. Flutter 앱 연동
- Firebase CLI 설치 완료
- FlutterFire 설정 완료
- `firebase_options.dart` 생성
- Android/iOS 설정 파일 생성

### 3. 보안 규칙 배포
- `firestore.rules` 작성 및 배포 완료
- 12개 Collections 보안 규칙 설정

### 4. 서비스 레이어 구현
- `AuthService`: 이메일/비밀번호, Google 로그인
- `FirestoreService`: Firestore CRUD 작업
- `StorageService`: 이미지 업로드/삭제
- Riverpod Providers 설정

## 🌱 더미 데이터 생성

### 개발자 도구 화면 접근

앱 실행 후 다음 URL로 이동:
```
/dev-tools
```

또는 코드에서 직접 호출:
```dart
import 'package:mingrr/core/utils/seed_data.dart';

// 더미 데이터 생성
final seedData = SeedData();
await seedData.seedAll();

// 모든 데이터 삭제
await seedData.clearAllData();
```

### 생성되는 더미 데이터

**사용자 5명**
- user_001 ~ user_005
- 이메일: test1@mingrr.com ~ test5@mingrr.com
- 서울 각 지역 위치 정보

**강아지 6마리**
- dog_001 ~ dog_006
- 다양한 견종 (포메라니안, 골든리트리버, 토이푸들, 웰시코기, 시바견)

**상품 5개**
- product_001 ~ product_005
- 판매/나눔 상품

**모임 3개**
- group_001 ~ group_003
- 산책, 소셜, 훈련 모임

## 📁 프로젝트 구조

```
lib/
├── main.dart                          # 앱 진입점 (Firebase 초기화)
├── firebase_options.dart              # Firebase 설정
├── app.dart                          # 라우팅 및 앱 설정
├── core/
│   ├── services/
│   │   ├── firebase_service.dart     # Firebase 인스턴스 관리
│   │   ├── auth_service.dart         # 인증 서비스
│   │   ├── firestore_service.dart    # Firestore CRUD
│   │   └── storage_service.dart      # Storage 업로드/삭제
│   ├── providers/
│   │   ├── firebase_providers.dart   # Firebase Provider
│   │   ├── user_providers.dart       # 사용자 데이터 Provider
│   │   ├── chat_providers.dart       # 채팅 Provider
│   │   └── dating_providers.dart     # 데이팅 Provider
│   └── utils/
│       └── seed_data.dart            # 더미 데이터 생성
├── models/                           # 데이터 모델
│   ├── user_model.dart
│   ├── pet_model.dart
│   ├── chat_model.dart
│   ├── dating_model.dart
│   ├── marketplace_model.dart
│   └── community_model.dart
└── features/                         # 기능별 화면
    ├── auth/
    ├── home/
    ├── dating/
    ├── marketplace/
    ├── chat/
    ├── profile/
    └── dev/
        └── dev_tools_screen.dart     # 개발자 도구 화면
```

## 🔥 Firebase Collections 구조

자세한 내용은 `FIRESTORE_STRUCTURE.md` 참조

- `users` - 사용자(보호자)
- `dogs` - 강아지
- `chatRooms` - 채팅방
- `messages` - 메시지 (하위 컬렉션)
- `likes` - 데이팅 좋아요
- `matches` - 매칭
- `products` - 마켓플레이스 상품
- `productLikes` - 상품 찜
- `groups` - 소모임
- `schedules` - 일정
- `joinRequests` - 가입 신청
- `healthRecords` - 건강 기록 (하위 컬렉션)

## 🚀 앱 실행

```bash
# 의존성 설치
flutter pub get

# Android 실행
flutter run

# iOS 실행 (Mac only)
flutter run -d ios

# 웹 실행
flutter run -d chrome
```

## 🧪 테스트 계정

더미 데이터 생성 후 다음 계정으로 로그인 가능:

- test1@mingrr.com
- test2@mingrr.com
- test3@mingrr.com
- test4@mingrr.com
- test5@mingrr.com

비밀번호는 Firebase Authentication에서 직접 설정 필요

## 📱 Firebase App Distribution (테스트 배포)

### 1. Firebase CLI로 배포

```bash
# Android APK 빌드
flutter build apk --release

# Firebase App Distribution에 업로드
firebase appdistribution:distribute build/app/outputs/flutter-apk/app-release.apk \
  --app 1:355588618342:android:ee38434c08c8871be255a7 \
  --groups testers
```

### 2. 테스터 추가

Firebase Console > App Distribution > 테스터 및 그룹에서 이메일 추가

## 🔐 보안 규칙 업데이트

```bash
# 보안 규칙 배포
firebase deploy --only firestore:rules

# 보안 규칙 테스트
firebase emulators:start --only firestore
```

## 💰 Firebase 요금

### 무료 할당량 (Spark → Blaze 플랜)

**Firestore**
- 저장: 1GB
- 읽기: 50,000/일
- 쓰기: 20,000/일
- 삭제: 20,000/일

**Storage**
- 저장: 5GB
- 다운로드: 1GB/일
- 업로드: 20,000회/일

**Authentication**
- 무제한 (무료)

개발/테스트 단계에서는 거의 무료 범위 내 사용 가능

## 🐛 문제 해결

### Firebase 초기화 오류
```dart
// main.dart에서 Firebase 초기화 확인
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

### Firestore 권한 오류
- `firestore.rules` 확인
- Firebase Console에서 보안 규칙 배포 상태 확인

### Storage 업로드 오류
- Firebase Console에서 Storage 활성화 확인
- Blaze 플랜으로 업그레이드 확인

## 📚 참고 자료

- [FlutterFire 공식 문서](https://firebase.flutter.dev/)
- [Firebase Console](https://console.firebase.google.com/project/mingrr)
- [Firestore 보안 규칙](https://firebase.google.com/docs/firestore/security/get-started)
