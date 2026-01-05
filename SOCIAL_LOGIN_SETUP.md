# 소셜 로그인 및 공유 기능 설정 가이드

## 1. 카카오 로그인 설정

### 1.1 카카오 개발자 콘솔 설정
1. [카카오 개발자 콘솔](https://developers.kakao.com/) 접속
2. 애플리케이션 추가하기
3. 앱 키 확인 (네이티브 앱 키, REST API 키, JavaScript 키)

### 1.2 Flutter 설정

#### pubspec.yaml
```yaml
dependencies:
  kakao_flutter_sdk: ^1.9.0
```

#### Android 설정 (android/app/src/main/AndroidManifest.xml)
```xml
<manifest>
    <application>
        <!-- 카카오 로그인 커스텀 URL 스킴 -->
        <activity 
            android:name="com.kakao.sdk.flutter.AuthCodeCustomTabsActivity"
            android:exported="true">
            <intent-filter android:label="flutter_web_auth">
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />
                <data android:scheme="kakao{NATIVE_APP_KEY}" android:host="oauth" />
            </intent-filter>
        </activity>
    </application>
</manifest>
```

#### iOS 설정 (ios/Runner/Info.plist)
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>kakao{NATIVE_APP_KEY}</string>
        </array>
    </dict>
</array>
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>kakaokompassauth</string>
    <string>kakaolink</string>
</array>
```

#### main.dart 초기화
```dart
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';

void main() async {
  KakaoSdk.init(nativeAppKey: 'YOUR_NATIVE_APP_KEY');
  runApp(MyApp());
}
```

---

## 2. 네이버 로그인 설정

### 2.1 네이버 개발자 센터 설정
1. [네이버 개발자 센터](https://developers.naver.com/) 접속
2. 애플리케이션 등록
3. Client ID, Client Secret 확인

### 2.2 Flutter 설정

#### pubspec.yaml
```yaml
dependencies:
  flutter_naver_login: ^1.8.0
```

#### Android 설정 (android/app/src/main/res/values/strings.xml)
```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="client_id">YOUR_CLIENT_ID</string>
    <string name="client_secret">YOUR_CLIENT_SECRET</string>
    <string name="client_name">앱이름</string>
</resources>
```

#### iOS 설정 (ios/Runner/Info.plist)
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>YOUR_URL_SCHEME</string>
        </array>
    </dict>
</array>
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>naversearchapp</string>
    <string>naversearchthirdlogin</string>
</array>
<key>naverServiceAppUrlScheme</key>
<string>YOUR_URL_SCHEME</string>
<key>naverConsumerKey</key>
<string>YOUR_CLIENT_ID</string>
<key>naverConsumerSecret</key>
<string>YOUR_CLIENT_SECRET</string>
<key>naverServiceAppName</key>
<string>앱이름</string>
```

---

## 3. 구글 로그인 설정 (웹)

### 3.1 Google Cloud Console 설정
1. [Google Cloud Console](https://console.cloud.google.com/) 접속
2. OAuth 2.0 클라이언트 ID 생성 (웹 애플리케이션)
3. 승인된 JavaScript 원본에 `http://localhost:8080` 추가

### 3.2 웹 설정 (web/index.html)
```html
<head>
    <meta name="google-signin-client_id" content="YOUR_CLIENT_ID.apps.googleusercontent.com">
</head>
```

---

## 4. 카카오톡 공유 설정

### 4.1 카카오 개발자 콘솔
1. 내 애플리케이션 > 플랫폼 > Web 플랫폼 등록
2. 사이트 도메인 등록

### 4.2 Flutter 설정
카카오 로그인과 동일한 SDK 사용 (kakao_flutter_sdk)

```dart
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';

// 카카오톡 공유
await ShareClient.instance.shareDefault(
  template: FeedTemplate(
    content: Content(
      title: '제목',
      description: '설명',
      imageUrl: Uri.parse('https://example.com/image.png'),
      link: Link(
        webUrl: Uri.parse('https://example.com'),
        mobileWebUrl: Uri.parse('https://example.com'),
      ),
    ),
  ),
);
```

---

## 5. 일반 공유 기능 (API 키 불필요)

링크 복사, 시스템 공유 시트는 별도 API 키가 필요하지 않습니다.

### pubspec.yaml
```yaml
dependencies:
  share_plus: ^7.2.0
```

### 사용 예시
```dart
import 'package:share_plus/share_plus.dart';

await Share.share('공유할 텍스트');
```

---

## 주의사항

1. **API 키는 절대 Git에 커밋하지 마세요**
   - `.gitignore`에 키 파일 추가
   - 환경 변수 또는 별도 설정 파일 사용

2. **프로덕션 배포 전 확인사항**
   - 카카오: 앱 검수 신청
   - 네이버: 서비스 URL 등록
   - 구글: OAuth 동의 화면 설정

3. **테스트 환경**
   - 개발 중에는 테스트 사용자 등록 필요
   - 카카오/네이버 모두 팀원 등록 기능 제공
