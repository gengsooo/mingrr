# 홈 리마인더 배너 기획서

## 1. 개요

### 1.1 목적
홈 화면 상단에 사용자에게 필요한 알림/리마인더를 배너 형태로 표시하여 앱 참여도를 높이고 중요한 액션을 유도합니다.

### 1.2 현재 구현 상태
- ✅ 범용 `HomeReminderBanner` 위젯 구현
- ✅ 스와이프 캐러셀 (`HomeReminderBannerCarousel`) 구현
- ✅ 점 인디케이터 구현
- ✅ 홈 화면 연동
- ⚠️ 배너 클릭 시 이동 기능 일부 미구현

---

## 2. 배너 타입

### 2.1 지원 배너 목록

| 우선순위 | 타입 | 아이콘 | 제목 | 부제목 |
|---------|-----|-------|-----|-------|
| P1 | `rating` | rate_review | 평가하지 않은 활동이 있어요 | N건의 평가가 기다리고 있어요 |
| P1 | `groupSchedule` | event | 오늘 소모임 일정이 있어요 | N개의 일정을 확인해보세요 |
| P2 | `petLike` | pets | 내 반려동물이 관심을 받았어요 | N명이 좋아요를 눌렀어요 |
| P2 | `receivedRating` | star | 새로운 평가를 받았어요 | N건의 새 평가가 있어요 |
| P2 | `verification` | verified | 프로필 인증을 완료해보세요 | N개의 인증이 남았어요 |
| P2 | `groupJoinRequest` | group_add | 가입 승인 대기 중인 신청이 있어요 | N건의 신청을 확인해보세요 |
| P3 | `healthRecord` | medical_services | 건강 기록을 확인해보세요 | N개의 일정이 다가오고 있어요 |

### 2.2 표시 조건

```dart
// 각 배너는 해당 조건이 충족될 때만 표시
rating: pendingRatings > 0
groupSchedule: todaySchedules > 0
petLike: recentPetLikes > 0 (최근 24시간)
receivedRating: unreadRatings > 0
verification: incompleteVerifications > 0
groupJoinRequest: pendingJoinRequests > 0 (내가 운영하는 그룹)
healthRecord: upcomingHealth > 0 (7일 이내)
```

---

## 3. UI/UX 설계

### 3.1 배너 레이아웃

```
┌─────────────────────────────────────────────────┐
│                                                 │
│  [🐾]  내 반려동물이 관심을 받았어요            │
│        3명이 좋아요를 눌렀어요            [›]   │
│                                                 │
│                    ● ○ ○                        │
└─────────────────────────────────────────────────┘
```

### 3.2 인터랙션

| 동작 | 결과 |
|-----|-----|
| 탭 | 해당 상세 화면으로 이동 |
| 좌우 스와이프 | 다음/이전 배너 전환 |
| 끝에서 스와이프 | 바운스 효과 |

### 3.3 상태별 UI

| 상태 | UI |
|-----|---|
| 배너 0개 | 영역 완전 숨김 |
| 배너 1개 | 단일 배너, 인디케이터 숨김 |
| 배너 2개 이상 | 스와이프 가능, 점 인디케이터 표시 |
| 최대 7개 | 우선순위 상위 7개만 표시 |

### 3.4 디자인 스펙

```dart
// 배너 컨테이너
height: 80.0
padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14)
borderRadius: 12.0
backgroundColor: colorScheme.surfaceContainerHighest.withOpacity(0.5)
border: colorScheme.outlineVariant.withOpacity(0.3)

// 아이콘 컨테이너
size: 40x40
shape: circle
backgroundColor: colorScheme.primaryContainer
iconColor: colorScheme.primary
iconSize: 20

// 점 인디케이터
dotSize: 6.0
dotSpacing: 6.0 (margin horizontal: 3)
activeDotColor: colorScheme.primary
inactiveDotColor: colorScheme.outlineVariant.withOpacity(0.5)
```

---

## 4. 배너 클릭 시 이동 기능

### 4.1 현재 구현 상태

| 배너 타입 | 이동 경로 | 상태 | 비고 |
|----------|---------|------|-----|
| `rating` | - | ❌ 미구현 | SnackBar만 표시 |
| `groupSchedule` | `/social` | ⚠️ 부분 | 오늘 일정 필터 없음 |
| `petLike` | `/profile/received-likes` | ❌ 잘못됨 | 데이팅 신청 화면으로 이동됨 |
| `receivedRating` | `/notifications` | ⚠️ 부분 | 평가 필터 없음 |
| `verification` | `/profile` | ✅ 완료 | |
| `groupJoinRequest` | `/social` | ⚠️ 부분 | 가입 신청 관리 없음 |
| `healthRecord` | `/health` | ✅ 완료 | |

### 4.2 필요한 신규 화면

#### 4.2.1 평가 대기 목록 화면
**경로:** `/rating/pending`

**기능:**
- 평가하지 않은 활동 목록 표시 (산책, 거래, 소모임 등)
- 각 항목 탭 시 평가 바텀시트 표시
- 완료된 항목 자동 제거

**UI 설계:**
```
┌─────────────────────────────────────────┐
│  ← 평가 대기 목록                       │
├─────────────────────────────────────────┤
│  [프로필] 홍길동님과의 산책              │
│  2024.01.15 · 평가하기 →                │
├─────────────────────────────────────────┤
│  [프로필] 김철수님과의 거래              │
│  2024.01.14 · 평가하기 →                │
├─────────────────────────────────────────┤
│                                         │
│  평가를 완료하면 꼬순내 지수가 올라가요! │
│                                         │
└─────────────────────────────────────────┘
```

**데이터 모델:**
```dart
class PendingRating {
  final String id;
  final String targetUserId;
  final String targetUserName;
  final String? targetUserProfileUrl;
  final String activityType; // walk, transaction, group
  final String activityId;
  final DateTime activityDate;
  final bool isCompleted;
}
```

#### 4.2.2 반려동물 좋아요 목록 화면
**경로:** `/profile/pet-likes`

**기능:**
- 내 반려동물별로 좋아요 누른 사용자 목록 표시
- 최근 24시간 내 좋아요만 하이라이트
- 상대방 프로필/반려동물 조회 가능

**UI 설계:**
```
┌─────────────────────────────────────────┐
│  ← 반려동물 좋아요                       │
├─────────────────────────────────────────┤
│  🐕 뽀삐 (5명이 좋아요)                  │
│  ├─ [프로필] 홍길동 · 1시간 전    [NEW] │
│  ├─ [프로필] 김철수 · 3시간 전    [NEW] │
│  ├─ [프로필] 이영희 · 어제              │
│  └─ 더보기 (2명)                        │
├─────────────────────────────────────────┤
│  🐕 초코 (2명이 좋아요)                  │
│  └─ [프로필] 박민수 · 2일 전            │
└─────────────────────────────────────────┘
```

**데이터 모델:**
```dart
class PetLikeInfo {
  final String petId;
  final String petName;
  final String? petImageUrl;
  final List<LikerInfo> likers;
}

class LikerInfo {
  final String oderId;
  final String nickname;
  final String? profileImageUrl;
  final DateTime likedAt;
  final bool isRecent; // 24시간 이내
}
```

#### 4.2.3 소모임 가입 신청 관리 화면
**경로:** `/social/join-requests`

**기능:**
- 내가 운영하는 소모임의 가입 신청 목록
- 승인/거절 기능
- 신청자 프로필 조회

**UI 설계:**
```
┌─────────────────────────────────────────┐
│  ← 가입 신청 관리                        │
├─────────────────────────────────────────┤
│  📍 강남 댕댕이 모임                     │
│  ├─ [프로필] 홍길동        [승인] [거절] │
│  │  "안녕하세요! 가입하고 싶어요"        │
│  └─ [프로필] 김철수        [승인] [거절] │
├─────────────────────────────────────────┤
│  📍 서초 산책 모임                       │
│  └─ 대기 중인 신청이 없습니다            │
└─────────────────────────────────────────┘
```

### 4.3 기존 화면 개선

#### 4.3.1 소모임 화면 - 오늘 일정 필터
**경로:** `/social?filter=today`

**변경사항:**
- 쿼리 파라미터 `filter=today` 지원
- 해당 파라미터 시 오늘 일정만 필터링

#### 4.3.2 알림 화면 - 평가 필터
**경로:** `/notifications?filter=rating`

**변경사항:**
- 쿼리 파라미터 `filter=rating` 지원
- 해당 파라미터 시 평가 관련 알림만 필터링

---

## 5. 구현 우선순위

### 5.1 P1 (필수)

| 항목 | 설명 | 예상 공수 |
|-----|-----|---------|
| 평가 대기 목록 화면 | 핵심 기능, 꼬순내 지수 연동 | 1일 |
| 반려동물 좋아요 목록 화면 | 현재 잘못된 경로로 이동 중 | 0.5일 |

### 5.2 P2 (권장)

| 항목 | 설명 | 예상 공수 |
|-----|-----|---------|
| 소모임 오늘 일정 필터 | 기존 화면 활용 | 0.5일 |
| 소모임 가입 신청 관리 | 운영자 기능 | 1일 |

### 5.3 P3 (선택)

| 항목 | 설명 | 예상 공수 |
|-----|-----|---------|
| 알림 화면 평가 필터 | 기존 화면 활용 | 0.5일 |

---

## 6. 관련 파일

### 6.1 위젯
- `lib/core/widgets/home_reminder_banner.dart` - 배너 위젯, 캐러셀

### 6.2 Provider
- `lib/core/providers/home_reminder_provider.dart` - 배너 데이터 Provider

### 6.3 화면
- `lib/features/home/presentation/screens/home_screen.dart` - 홈 화면 (배너 연동)

### 6.4 신규 생성 필요
- `lib/features/rating/presentation/screens/pending_ratings_screen.dart`
- `lib/features/profile/presentation/screens/pet_likes_screen.dart`
- `lib/features/social/presentation/screens/join_requests_screen.dart`

---

## 7. 참고 사항

### 7.1 업계 표준
- 토스, 카카오톡 등 대부분의 앱에서 홈 상단 배너 사용
- 스와이프 캐러셀 + 점 인디케이터가 표준

### 7.2 성능 고려
- Provider는 `autoDispose`로 메모리 관리
- 배너 데이터는 캐싱하여 불필요한 DB 호출 방지
- 최대 7개 제한으로 렌더링 부하 최소화

### 7.3 확장성
- `ReminderBannerType` enum에 새 타입 추가로 쉽게 확장 가능
- `_bannerConfigs` 맵에 설정 추가만으로 새 배너 지원

---

## 8. 변경 이력

| 날짜 | 버전 | 변경 내용 |
|-----|-----|---------|
| 2026.01.16 | 1.0 | 초안 작성 |
