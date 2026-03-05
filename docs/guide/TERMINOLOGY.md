# MINGRR 프로젝트 용어 사전

효율적인 의사소통과 협업을 위한 UI/UX, Flutter, 개발 용어 정리입니다.

---

## 1. UI 컴포넌트 용어

### 바텀시트 (Bottom Sheet)

**정의**: 화면 하단에서 위로 올라오는 UI 요소입니다.

**특징**
- 화면 일부를 덮으며, 배경은 반투명 처리됩니다.
- 드래그하거나 배경을 탭하여 닫을 수 있습니다.
- 복잡한 UI나 많은 정보를 표시할 때 적합합니다.

**MINGRR 사용처**
- `GuardianProfileModal` → 보호자 프로필 표시
- `PetProfileModal` → 반려동물 프로필 표시
- `ConfirmSheet` → 삭제, 탈퇴 확인
- `MingrrOptionsSheet` → 더보기 옵션 메뉴
- `MingrrDateSelector` → 날짜/시간 선택기
- `ImagePickerSheet` → 이미지 선택
- `ReportSheet` → 신고하기
- `RequestSheet` → 요청하기

---

### 다이얼로그 (Dialog)

**정의**: 화면 중앙에 표시되는 팝업 창입니다.

**특징**
- 화면 중앙에 떠있는 형태입니다.
- 바텀시트보다 작고 간결합니다.
- 간단한 알림이나 확인/취소 선택에 적합합니다.

**MINGRR 사용처**
- `AppDialog` → 확인/경고 다이얼로그
- `InfoDialog` → 정보 안내 (강아지 크기, 꼬순내지수 설명)
- `MingrrLoadingDialog` → 로딩 중 표시

**바텀시트 vs 다이얼로그 선택 기준**
- 바텀시트: 복잡한 UI, 많은 정보, 스크롤 필요할 때
- 다이얼로그: 간단한 메시지, 확인/취소 선택

---

### 스낵바 (SnackBar)

**정의**: 화면 하단에 잠깐 나타났다 사라지는 알림 메시지입니다.

**특징**
- 자동으로 사라집니다. (보통 2-3초)
- 화면을 가리지 않습니다.
- 사용자 행동에 대한 피드백을 제공합니다.

**MINGRR 사용처**
- `MingrrSnackBar.success()` → 성공 메시지 (녹색)
- `MingrrSnackBar.warning()` → 경고 메시지 (노란색)
- `MingrrSnackBar.error()` → 에러 메시지 (빨간색)
- `MingrrSnackBar.info()` → 정보 메시지 (파란색)

**사용 예시**
- "좋아요를 보냈어요! 💕"
- "로그인이 필요합니다"
- "저장되었습니다"

---

### 토스트 (Toast)

**정의**: 스낵바와 유사하게 잠깐 나타났다 사라지는 메시지입니다.

**스낵바와의 차이**
- 스낵바: Material Design 공식 용어, 액션 버튼 포함 가능
- 토스트: Android 네이티브 용어, 단순 메시지만 표시

**참고**: MINGRR에서는 `MingrrSnackBar`를 사용합니다.

---

### 배너 (Banner)

**정의**: 화면 상단에 표시되는 알림/안내 영역입니다.

**종류**
- 홈 배너: 메인 화면 상단의 알림 배너 (앱 내부)
- 인앱 배너: 특정 화면 상단 안내 (앱 내부)
- 푸시 알림: 모바일 기기 알림 센터 (앱 외부)

**MINGRR 사용처**
- `HomeReminderBanner` → 건강검진, 예방접종 리마인더

---

### 모달 (Modal)

**정의**: 사용자의 주의를 요구하는 오버레이 UI의 총칭입니다.

**특징**
- 모달이 열리면 뒤의 화면과 상호작용이 불가능합니다.
- 모달을 닫아야 다른 작업이 가능합니다.

**모달의 종류**
- 바텀시트: 하단에서 올라오는 모달
- 다이얼로그: 화면 중앙에 표시되는 모달
- 풀스크린 모달: 전체 화면을 차지하는 모달

---

### 카드 (Card)

**정의**: 관련 정보를 담는 시각적 컨테이너입니다.

**특징**
- 그림자나 테두리로 구분됩니다.
- 클릭 가능한 경우가 많습니다.
- 정보를 그룹화하여 표시합니다.

**카드의 종류**
- 리스트 카드: 메뉴나 리스트의 각 항목
- 정보 카드: 특정 정보를 담는 카드
- 프로필 카드: 사용자/반려동물 정보 표시

**MINGRR 사용처**
- `MingrrCard` → 기본 카드 컨테이너
- `ProfileModalItemCard` → 프로필 모달 내 카드
- `ProductCard` → 상품 카드
- `PetProfileCard` → 반려동물 카드

---

### 섹션 (Section)

**정의**: 관련 콘텐츠를 그룹화한 영역입니다.

**구성**
- 섹션 타이틀 (제목)
- 섹션 콘텐츠 (내용)

**MINGRR 사용처**
- `ProfileModalSection` → 프로필 모달 내 섹션
- `MingrrSectionHeader` → 섹션 헤더

**예시**: "보호자 정보 바텀시트에 있는 인증 배지 영역 전체" → **인증 배지 섹션**이라고 부릅니다.

---

### 타일 (Tile)

**정의**: 리스트 형태의 항목을 표시하는 UI 요소입니다.

**특징**
- 주로 설정 화면에서 사용됩니다.
- 아이콘 + 텍스트 + 액션으로 구성됩니다.

**카드 vs 타일**
- 카드: 독립적인 정보 블록, 그림자/테두리 있음
- 타일: 리스트의 한 줄, 간결한 형태

**MINGRR 사용처**
- `MingrrSettingsTile` → 설정 항목
- `MingrrRecordTile` → 건강 기록 항목

---

### 배지 (Badge)

**정의**: 작은 정보나 상태를 표시하는 라벨입니다.

**특징**
- 작고 간결합니다.
- 색상으로 의미를 전달합니다.
- 주로 아이콘이나 텍스트 옆에 표시됩니다.

**MINGRR 사용처**
- `VerificationBadgeMedium` → 인증 배지
- `InfoBadge` → 정보 배지
- `MingrrBadge` → 기본 배지
- `TraitBadge` → 성격/특성 배지

---

### 칩 (Chip)

**정의**: 선택 가능한 작은 UI 요소입니다.

**특징**
- 필터, 태그, 선택 옵션에 사용됩니다.
- 선택/해제 상태를 가집니다.

**MINGRR 사용처**
- `FilterChip` → 필터 선택
- `ChoiceChip` → 단일 선택
- `InputChip` → 입력된 태그

---

### 버튼 바 (Button Bar)

**정의**: 화면 하단에 고정된 버튼 영역입니다.

**특징**
- 주요 액션 버튼이 배치됩니다.
- 스크롤해도 항상 보입니다.

**MINGRR 사용처**
- `MingrrBottomButtonBar` → 상세 화면 하단 버튼
- `MingrrSubmitButtonBar` → 등록/수정 화면 제출 버튼

---

### 앱바 (AppBar)

**정의**: 화면 상단에 고정된 네비게이션 바입니다.

**구성**
- 뒤로가기 버튼 (leading)
- 제목 (title)
- 액션 버튼들 (actions)

**MINGRR 사용처**
- `AppBar` → Flutter 기본 앱바
- `SliverAppBar` → 스크롤 시 축소되는 앱바

---

### 탭바 (TabBar)

**정의**: 여러 탭을 전환할 수 있는 네비게이션 요소입니다.

**MINGRR 사용처**
- 데이팅 화면: 전체 / 좋아요 탭
- 마켓 화면: 분양 / 용품 / 구인 탭
- 소모임 상세: 정보 / 멤버 / 일정 탭

---

### 바텀 네비게이션 (Bottom Navigation)

**정의**: 화면 하단에 고정된 메인 네비게이션 바입니다.

**MINGRR 사용처**: 홈 / 데이팅 / 산책 / 채팅 / 프로필 탭

---

### FAB (Floating Action Button)

**정의**: 화면에 떠있는 원형 액션 버튼입니다.

**특징**
- 주요 액션을 위한 버튼입니다.
- 보통 화면 우하단에 위치합니다.

**MINGRR 사용처**: `MingrrFAB` → 글쓰기, 추가하기 버튼

---

### 빈 상태 (Empty State)

**정의**: 데이터가 없을 때 표시하는 UI입니다.

**구성**
- 아이콘
- 메시지
- (선택) 액션 버튼

**MINGRR 사용처**
- `MingrrEmptyState` → 전체 화면 빈 상태
- `MingrrEmptySection` → 섹션 내 빈 상태

---

### 로딩 상태 (Loading State)

**정의**: 데이터를 불러오는 중일 때 표시하는 UI입니다.

**MINGRR 사용처**
- `MingrrLoadingState` → 로딩 인디케이터
- `MingrrLoadingDialog` → 로딩 다이얼로그
- `MingrrLoadingOverlay` → 로딩 오버레이

---

### 에러 상태 (Error State)

**정의**: 에러가 발생했을 때 표시하는 UI입니다.

**MINGRR 사용처**: `MingrrErrorState` → 에러 메시지 + 재시도 버튼

---

### 아바타 (Avatar)

**정의**: 사용자나 반려동물의 프로필 이미지를 표시하는 원형 UI입니다.

**MINGRR 사용처**
- `MingrrAvatar` → 기본 아바타
- `ProfileModalAvatar` → 프로필 모달용 아바타

---

### 디바이더 (Divider)

**정의**: 콘텐츠를 구분하는 가로선입니다.

**MINGRR 사용처**
- `Divider` → 기본 구분선
- `SizedBox` → 여백으로 구분

---

### 툴팁 (Tooltip)

**정의**: 요소를 길게 누르거나 호버할 때 나타나는 설명 텍스트입니다.

---

## 2. Flutter 위젯 용어

### 위젯 (Widget)

**정의**: Flutter에서 UI를 구성하는 모든 요소입니다.

**핵심 개념**: "Everything is a Widget" - Flutter의 핵심 철학입니다.

**위젯 종류**
- StatelessWidget: 상태가 없는 위젯 (변하지 않음)
- StatefulWidget: 상태가 있는 위젯 (변할 수 있음)

---

### 컨테이너 (Container)

**정의**: 다른 위젯을 담는 박스입니다.

**기능**
- 패딩, 마진 적용
- 배경색, 테두리 설정
- 크기 조절

---

### 레이아웃 위젯

**Row**: 자식 위젯들을 가로로 배치합니다.

**Column**: 자식 위젯들을 세로로 배치합니다.

**Stack**: 자식 위젯들을 겹쳐서 배치합니다.

**Wrap**: 자식 위젯들을 줄바꿈하며 배치합니다.

**Padding**: 내부 여백을 추가합니다.

**SizedBox**: 고정 크기의 박스입니다.

**Expanded**: 남은 공간을 채웁니다.

**Flexible**: 유연한 크기로 공간을 차지합니다.

---

### 스크롤 위젯

**SingleChildScrollView**: 단일 자식 위젯을 스크롤합니다.

**ListView**: 리스트 형태로 스크롤합니다.

**GridView**: 그리드 형태로 스크롤합니다.

**CustomScrollView**: 복잡한 스크롤 효과를 구현합니다. (Sliver 사용)

**NestedScrollView**: 중첩 스크롤을 구현합니다. (탭 + 스크롤)

---

### 슬리버 (Sliver)

**정의**: CustomScrollView 또는 NestedScrollView 내부에서 사용하는 스크롤 가능 요소입니다.

**왜 필요한가?**
- 일반 위젯(ListView, Column 등)은 CustomScrollView 안에 직접 넣을 수 없습니다.
- Sliver는 스크롤 영역 내에서 "조각(slice)"처럼 동작하는 특수 위젯입니다.
- 복잡한 스크롤 효과(앱바 축소, 탭바 고정 등)를 구현할 때 필수입니다.

**주요 Sliver 위젯**
- `SliverList`: 리스트 형태의 스크롤 요소
- `SliverGrid`: 그리드 형태의 스크롤 요소
- `SliverAppBar`: 스크롤 시 축소/확장되는 앱바
- `SliverToBoxAdapter`: 일반 위젯을 Sliver로 변환
- `SliverPersistentHeader`: 스크롤 시 상단에 고정되는 헤더 (탭바 고정에 사용)
- `SliverFillRemaining`: 남은 공간을 채우는 요소

**SliverPersistentHeader와 SliverPersistentHeaderDelegate**
- `SliverPersistentHeader`: 스크롤해도 상단에 고정되는 헤더 위젯
- `SliverPersistentHeaderDelegate`: 헤더의 크기와 빌드 방법을 정의하는 추상 클래스
- 탭바를 스크롤 시 상단에 고정하려면 이 조합이 필요합니다.

**MINGRR 사용처**
- `group_detail_screen.dart`: 소모임 상세 화면에서 탭바 고정
- `MingrrImageHeader`: 이미지 헤더 (SliverAppBar 기반)

**일반 위젯과의 차이**
```dart
// ❌ 불가능: 일반 위젯을 CustomScrollView에 직접 사용
CustomScrollView(
  slivers: [
    Container(),  // 에러 발생
  ],
)

// ✅ 가능: SliverToBoxAdapter로 감싸기
CustomScrollView(
  slivers: [
    SliverToBoxAdapter(child: Container()),
  ],
)
```

---

### GestureDetector

**정의**: 터치 이벤트를 감지하는 위젯입니다.

**감지 가능한 이벤트**
- onTap: 탭
- onDoubleTap: 더블탭
- onLongPress: 길게 누르기
- onPanUpdate: 드래그

---

### InkWell

**정의**: 터치 시 물결 효과(ripple)가 나타나는 위젯입니다.

**GestureDetector와의 차이**
- GestureDetector: 시각적 피드백 없음
- InkWell: Material 물결 효과 있음

---

## 3. 개발 기술 용어

### Race Condition (경쟁 상태)

**정의**: 여러 작업이 동시에 실행될 때 실행 순서에 따라 결과가 달라지는 상황입니다.

**문제 상황**
```dart
_isLiked = !_isLiked;      // UI 먼저 업데이트
await updateDatabase();     // DB 업데이트 (실패 가능)
// DB 실패 시 UI와 DB 불일치 발생
```

**해결 방법: 낙관적 업데이트 + 롤백**
```dart
final wasLiked = _isLiked;
_isLiked = !_isLiked;  // UI 먼저 업데이트

try {
  await updateDatabase();
} catch (e) {
  _isLiked = wasLiked;  // 실패 시 롤백
}
```

---

### 낙관적 업데이트 (Optimistic Update)

**정의**: 서버 응답을 기다리지 않고 UI를 먼저 업데이트하는 방식입니다.

**장점**
- 빠른 반응
- 좋은 사용자 경험

**MINGRR 사용처**
- 좋아요 버튼 클릭 시 즉시 UI 변경
- Firebase 업데이트 실패 시 상태 롤백

---

### Semantics (접근성)

**정의**: 시각 장애인을 위한 스크린 리더 지원입니다.

**기능**
- 화면의 요소를 음성으로 읽어줍니다.
- 버튼, 이미지 등에 설명을 추가합니다.

**중요성**
- 모든 사용자가 앱을 사용할 수 있도록 합니다.
- 앱스토어 심사 기준 중 하나입니다.

---

### 비동기 (Async/Await)

**정의**: 시간이 걸리는 작업을 기다리는 방식입니다.

**사용처**
- 네트워크 요청
- 데이터베이스 조회
- 파일 읽기/쓰기

**문법**
```dart
Future<void> loadData() async {
  final user = await FirebaseService().getUser(userId);
  setState(() => _user = user);
}
```

---

### 상태 관리 (State Management)

**정의**: 앱의 데이터와 UI를 동기화하는 방법입니다.

**MINGRR의 상태 관리**
- Riverpod: 전역 상태 관리
- StatefulWidget: 로컬 상태 관리
- Firebase: 서버 상태 관리

---

### 라이프사이클 (Lifecycle)

**정의**: 위젯이나 화면이 생성되고 소멸되는 과정입니다.

**주요 메서드**
- `initState()`: 위젯 생성 시 한 번 실행
- `build()`: UI 그릴 때마다 실행
- `dispose()`: 위젯 소멸 시 실행

---

### 핫 리로드 (Hot Reload)

**정의**: 앱을 재시작하지 않고 코드 변경사항을 즉시 반영하는 기능입니다.

**장점**
- 개발 속도 향상
- 상태 유지하면서 UI만 업데이트

---

### 빌드 컨텍스트 (BuildContext)

**정의**: 위젯 트리에서 현재 위젯의 위치 정보입니다.

**사용처**
```dart
Theme.of(context).colorScheme.primary;      // 테마 색상 가져오기
MediaQuery.of(context).size.width;          // 화면 크기 가져오기
Navigator.of(context).push(...);            // 네비게이션
```

---

### Provider / Riverpod

**정의**: Flutter의 상태 관리 라이브러리입니다.

**MINGRR 사용 예시**
```dart
final group = ref.watch(groupDetailProvider(groupId));                    // 상태 읽기
ref.read(groupNotifierProvider.notifier).toggleLike(groupId);             // 상태 변경
ref.invalidate(groupDetailProvider(groupId));                             // 상태 새로고침
```

---

### setState

**정의**: StatefulWidget에서 상태 변경을 알리고 UI를 다시 그리는 메서드입니다.

**사용법**
```dart
setState(() {
  _isLiked = true;
  _likeCount += 1;
});
```

---

### Navigator

**정의**: 화면 간 이동을 관리하는 클래스입니다.

**주요 메서드**
- `push()`: 새 화면으로 이동
- `pop()`: 이전 화면으로 돌아가기
- `pushReplacement()`: 현재 화면을 대체

---

### Future

**정의**: 미래에 완료될 비동기 작업을 나타내는 객체입니다.

---

### Stream

**정의**: 시간에 따라 여러 값을 전달하는 비동기 데이터 흐름입니다.

**사용처**
- 실시간 데이터 업데이트
- Firebase 실시간 리스너

---

## 4. 협업 용어

### PR (Pull Request)

**정의**: 코드 변경사항을 리뷰받고 병합을 요청하는 것입니다.

**과정**
1. 브랜치 생성
2. 코드 작성
3. PR 생성
4. 리뷰 받기
5. 병합 (Merge)

---

### 코드 리뷰 (Code Review)

**정의**: 다른 개발자가 작성한 코드를 검토하는 과정입니다.

**목적**
- 버그 발견
- 코드 품질 향상
- 지식 공유

---

### 리팩토링 (Refactoring)

**정의**: 기능은 그대로 두고 코드 구조를 개선하는 것입니다.

**목적**
- 가독성 향상
- 유지보수 용이
- 중복 코드 제거

---

### 컴포넌트화 (Componentization)

**정의**: 재사용 가능한 UI 조각으로 분리하는 것입니다.

**장점**
- 코드 중복 제거
- 일관된 디자인
- 유지보수 용이

---

### DRY 원칙

**정의**: Don't Repeat Yourself - 같은 코드를 반복하지 말라는 원칙입니다.

**예시**
- ❌ 각 화면마다 좋아요 버튼 코드 복사
- ✅ `LikeButton` 컴포넌트 만들어서 재사용

---

### 기술 부채 (Technical Debt)

**정의**: 빠른 개발을 위해 임시로 작성한 코드가 쌓인 것입니다.

**문제점**
- 나중에 수정하기 어려움
- 버그 발생 가능성 증가
- 개발 속도 저하

---

### 이슈 (Issue)

**정의**: 버그, 기능 요청, 개선 사항 등을 기록하는 것입니다.

---

### 마일스톤 (Milestone)

**정의**: 프로젝트의 중요한 목표 지점입니다.

---

### 브랜치 (Branch)

**정의**: 코드의 독립적인 작업 공간입니다.

**종류**
- main/master: 메인 브랜치
- feature: 기능 개발 브랜치
- hotfix: 긴급 수정 브랜치

---

### 커밋 (Commit)

**정의**: 코드 변경사항을 저장하는 단위입니다.

---

### 머지 (Merge)

**정의**: 브랜치를 합치는 것입니다.

---

### 컨플릭트 (Conflict)

**정의**: 같은 코드를 여러 사람이 수정하여 충돌이 발생한 상황입니다.

---

## 5. 앱 화면 용어

### 스플래시 (Splash Screen)

**정의**: 앱 실행 시 로딩 중 잠깐 표시되는 화면입니다.

**특징**
- 앱 로고나 브랜드 이미지를 표시합니다.
- 앱이 초기화되는 동안 표시됩니다.
- 보통 1-3초 정도 표시됩니다.

**MINGRR 사용처**
- `flutter_native_splash` 패키지로 구현
- 설정 파일: `flutter_native_splash.yaml`
- 이미지: `assets/images/splash_logo.png`

---

### 온보딩 (Onboarding)

**정의**: 앱 첫 실행 시 표시되는 앱 소개 화면입니다.

**다른 이름**
- 워크스루 (Walkthrough)
- 인트로 (Intro)
- 튜토리얼 (Tutorial)

**특징**
- 앱의 주요 기능을 소개합니다.
- 여러 페이지를 슬라이드로 넘깁니다.
- 첫 실행 시에만 표시됩니다. (SharedPreferences로 저장)
- "건너뛰기" 버튼으로 스킵 가능합니다.

**MINGRR 사용처**
- `OnboardingScreen` → 4페이지 구성
- 이미지: `assets/images/onboarding_1~4.svg`
- 저장 키: `onboarding_completed`

**온보딩 테스트 방법**
- 앱 데이터 삭제: 설정 → 앱 → 밍그르르 → 저장공간 → 데이터 삭제
- 앱 재설치: `flutter clean && flutter run`

---

### 스플래시 vs 온보딩 차이

| 구분 | 스플래시 | 온보딩 |
|------|----------|--------|
| 표시 시점 | 매번 앱 실행 시 | 첫 실행 시에만 |
| 표시 시간 | 1-3초 (자동) | 사용자가 넘김 |
| 목적 | 로딩 대기 | 앱 소개 |
| 상호작용 | 없음 | 슬라이드, 버튼 |

---

## 6. MINGRR 전용 용어

### 꼬순내지수

**정의**: 보호자의 신뢰도를 나타내는 점수입니다. (0-100)

**용도**
- 보호자 평가
- 매칭 알고리즘
- 신뢰도 표시

---

### 프로필 모달 스택

**정의**: 바텀시트가 여러 개 겹쳐질 때 관리하는 시스템입니다.

**기능**
- 순환 참조 방지 (A → B → A)
- 스택 관리
- 자동 닫기

**사용 코드**
```dart
showStackedProfileModal(
  context: context,
  type: BottomSheetType.guardian,
  id: guardianId,
  builder: (ctx) => GuardianProfileModal(...),
);
```

---

### 피처 컬러 (Feature Colors)

**정의**: 각 기능별로 지정된 테마 색상입니다.

**색상 목록**
- 데이팅: 핑크 (`features.dating`)
- 소모임: 보라 (`features.social`)
- 마켓: 오렌지 (`features.market`)
- 산책: 초록 (`features.walk`)
- 건강: 빨강 (`features.health`)
- 채팅: 파랑 (`features.chat`)

---

### 보호자 (Guardian)

**정의**: 반려동물의 주인/보호자를 지칭하는 용어입니다.

---

## 6. 용어 비교표

### UI 요소 지칭

| 상황 | 올바른 용어 | 피해야 할 용어 |
|------|------------|---------------|
| 하단에서 올라오는 UI | 바텀시트 | 모달, 팝업 |
| 화면 중앙 팝업 | 다이얼로그 | 모달, 알림창 |
| 하단 알림 메시지 | 스낵바 | 토스트, 알림 |
| 리스트의 한 항목 | 카드 또는 타일 | 아이템 |
| 관련 정보 그룹 | 섹션 | 영역, 블록 |
| 작은 정보 라벨 | 배지 | 태그, 라벨 |
| 원형 프로필 이미지 | 아바타 | 프로필 사진 |
| 하단 고정 버튼 영역 | 버튼 바 | 하단 버튼 |

### 커뮤니케이션 예시

**좋은 예시**
- "보호자 프로필 바텀시트에서 인증 배지 섹션의 레이아웃을 수정했습니다"
- "좋아요 버튼 클릭 시 스낵바가 표시되도록 했습니다"
- "빈 상태 UI를 MingrrEmptySection 컴포넌트로 통일했습니다"

**피해야 할 예시**
- "프로필 팝업창에서 배지 있는 곳 고쳤어요"
- "좋아요 누르면 알림 뜨게 했어요"
- "빈 화면 UI 만들었어요"

---

## 참고 자료

**Flutter 공식 문서**: https://docs.flutter.dev/ui/widgets

**Material Design 3**: https://m3.material.io/

**MINGRR 프로젝트 문서**
- `docs/COMPONENT_REFACTORING.md` - 컴포넌트 리팩토링 가이드
- `lib/core/widgets/` - 공통 위젯 코드

---

최종 수정일: 2026-02-02 | 버전: 3.1
