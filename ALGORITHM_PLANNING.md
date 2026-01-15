# MINGRR 알고리즘 및 평가 시스템 종합 기획서

## 📊 현재 프로젝트 상태 분석

### 1. 주요 기능 현황

| 기능 | 상태 | 설명 |
|------|------|------|
| **데이팅** | ✅ 구현됨 | 좋아요/매칭/궁합 알고리즘 |
| **마켓플레이스** | ✅ 구현됨 | 중고거래/나눔/알바 |
| **소모임** | ✅ 구현됨 | 그룹/일정/가입신청 |
| **채팅** | ✅ 구현됨 | 1:1 채팅 (타입별 분류) |
| **꼬순내지수** | ✅ 구현됨 | 신뢰도 점수 시스템 |
| **평가 시스템** | ⚠️ 부분 구현 | 모델만 존재, 트리거 미구현 |
| **교배** | ✅ 구현됨 | 교배글/매칭 |
| **건강수첩** | ✅ 구현됨 | 산책/건강기록 |

### 2. 현재 DB 모델링 구조

```
users/
├── kkosunnaeScore: 50.0 (기본값)
├── ratingCount: 0
├── matchCount: 0
├── walkCount: 0
├── transactionCount: 0
├── groupCount: 0
├── reportCount: 0
├── noShowCount: 0
└── averageRating: 0.0

ratings/
├── raterId, targetId
├── type: dating/breeding/marketplace/community
├── result: completed/noShow/cancelled/failed
├── score: 1~5
├── tags: []
└── comment

transactions/ (거래 상태 추적)
├── chatRoomId
├── type, relatedId
├── sellerId, buyerId
├── status: pending/in_progress/completed/cancelled/no_show
├── sellerRated, buyerRated
└── completedAt
```

---

## 🔴 현재 문제점 및 개선 필요 사항

### 1. 평가 트리거 미구현
**현재**: `RatingModel`, `TransactionStatusModel` 모델은 있지만, 실제로 평가를 요청하는 UI/로직이 없음

**필요한 트리거 포인트**:
- 마켓 거래 완료 시
- 데이팅 만남 완료 시
- 소모임 일정 참여 완료 시
- 교배 완료 시
- 채팅방 나가기 시 (선택적)

### 2. 활동 카운트 업데이트 미연동
**현재**: `matchCount`, `walkCount`, `transactionCount`, `groupCount`가 실제 활동과 연동되지 않음

### 3. 커뮤니티 활동 반영 부재
**현재**: 게시글 작성, 댓글, 좋아요 등이 꼬순내지수에 반영되지 않음

---

## 📋 평가 시스템 기획

### 1. 평가 트리거 시점 및 방법

#### A. 마켓플레이스 거래

```
[트리거 시점]
1. 판매자가 "거래 완료" 버튼 클릭
2. 또는 채팅방에서 "거래 완료하기" 선택

[평가 플로우]
┌─────────────────────────────────────────────────────┐
│  거래 완료 버튼 클릭                                  │
│         ↓                                           │
│  상품 상태 → "completed"로 변경                      │
│         ↓                                           │
│  양쪽 사용자에게 평가 요청 푸시 알림                   │
│         ↓                                           │
│  평가 화면 표시 (별점 + 태그 + 코멘트)                │
│         ↓                                           │
│  평가 완료 시 꼬순내지수 재계산                       │
└─────────────────────────────────────────────────────┘

[당근마켓 참고]
- 거래 완료 후 24시간 내 평가 요청
- 미평가 시 리마인더 (최대 3회)
- 평가 기한: 7일 (이후 자동 만료)
```

#### B. 데이팅/산책 만남

```
[트리거 시점]
1. 채팅방에서 "만남 완료" 버튼 클릭
2. 또는 산책 종료 후 "함께 산책했어요" 선택

[평가 플로우]
┌─────────────────────────────────────────────────────┐
│  "만남 완료" 버튼 클릭                               │
│         ↓                                           │
│  만남 결과 선택 (완료/노쇼/취소)                      │
│         ↓                                           │
│  완료 시: 평가 화면 표시                             │
│  노쇼 시: 노쇼 신고 + 상대방 감점                     │
│         ↓                                           │
│  matchCount 증가 + 꼬순내지수 재계산                  │
└─────────────────────────────────────────────────────┘

[틴더/범블 참고]
- 매칭 후 일정 기간(7일) 후 "어떠셨나요?" 피드백
- 간단한 이모지 평가 (좋았어요/별로였어요)
- 상세 평가는 선택사항
```

#### C. 소모임 일정 참여

```
[트리거 시점]
1. 일정 종료 시간 이후 자동 트리거
2. 또는 모임장이 "일정 완료" 처리

[평가 플로우]
┌─────────────────────────────────────────────────────┐
│  일정 종료 시간 도래                                 │
│         ↓                                           │
│  참여자 전원에게 "일정 참여 확인" 알림                │
│         ↓                                           │
│  참여 확인 시: 모임 평가 (선택사항)                   │
│  불참 시: 노쇼 처리 가능                             │
│         ↓                                           │
│  groupCount 증가 + 꼬순내지수 재계산                  │
└─────────────────────────────────────────────────────┘

[소모임 앱 참고]
- 정기 모임 후 간단한 출석 체크
- 모임장만 평가 가능 (악용 방지)
- 누적 참여율 표시
```

#### D. 채팅방 나가기 시 평가

```
[권장하지 않는 이유]
- 실제 만남 없이 채팅만 한 경우 평가 의미 없음
- 평가 피로도 증가
- 악의적 평가 가능성

[대안]
- 채팅방 나가기 시 "만남이 있었나요?" 확인
- "예" 선택 시에만 평가 요청
- "아니오" 선택 시 평가 없이 종료
```

### 2. 평가 UI/UX 설계

#### 평가 화면 구성

```dart
// 평가 화면 구조
class RatingScreen {
  // 1. 결과 선택 (필수)
  ActivityResult result; // completed, noShow, cancelled, failed
  
  // 2. 별점 (완료 시 필수, 1~5점)
  int score;
  
  // 3. 태그 선택 (선택사항, 최대 3개)
  List<String> tags; // 긍정/부정 태그
  
  // 4. 코멘트 (선택사항, 100자 이내)
  String? comment;
}
```

#### 평가 태그 (타입별)

```dart
// 이미 구현됨: PositiveRatingTags, NegativeRatingTags
// 데이팅, 마켓플레이스, 교배 각각 다른 태그 세트
```

### 3. 평가 정책

| 항목 | 정책 |
|------|------|
| 평가 기한 | 활동 완료 후 7일 |
| 리마인더 | 24시간, 72시간, 168시간 후 |
| 수정 가능 | 24시간 내 1회 |
| 삭제 | 불가 (신고 시 관리자 검토) |
| 공개 범위 | 점수만 공개, 코멘트는 비공개 |
| 최소 평가 수 | 3개 이상 시 평균 표시 |

---

## 🎯 꼬순내지수 개선 방안

### 1. 현재 점수 배분 (100점)

```
평판 점수: 40점 (평가 점수 30점 + 평가 개수 보너스 10점)
활동 점수: 25점 (매칭/산책/거래/소모임)
신뢰도 점수: 20점 (인증/프로필/계정연령)
앱 활성도: 15점 (접속빈도/응답률)
감점 요소: 최대 -15점 (신고/노쇼)
```

### 2. 개선 제안: 커뮤니티 활동 반영

```
[추가 제안]
커뮤니티 점수: 5점 (기존 활동 점수에서 재배분)
├── 게시글 작성: 0.5점/개 (최대 2점)
├── 댓글 작성: 0.2점/개 (최대 1점)
├── 받은 좋아요: 0.1점/개 (최대 1점)
└── 도움이 됐어요: 0.3점/개 (최대 1점)

[수정된 점수 배분]
평판 점수: 40점
활동 점수: 20점 (매칭/산책/거래/소모임)
커뮤니티 점수: 5점 (신규)
신뢰도 점수: 20점
앱 활성도: 15점
감점 요소: 최대 -15점
```

### 3. 꼬순내지수 업데이트 트리거

```dart
// 업데이트가 필요한 시점
1. 평가 받았을 때 → RatingService.createRating()
2. 활동 완료 시 → 각 서비스에서 호출
3. 인증 완료 시 → AuthService에서 호출
4. 프로필 수정 시 → ProfileService에서 호출
5. 신고 처리 시 → ReportService에서 호출
6. 일일 배치 → Cloud Functions (접속 빈도 반영)
```

---

## 💕 데이팅 궁합 알고리즘 분석 및 개선

### 1. 현재 알고리즘 (100점)

```
체형 궁합: 18점 (크기 10점 + 체중 8점)
나이 궁합: 15점 (나이차 9점 + 생애단계 6점)
성격 궁합: 15점 (보완 6점 + 동일 5점 + 에너지 4점)
거리: 14점
보호자 인증: 12점
꼬순내 지수: 10점
품종 궁합: 6점
인기도: 6점
앱 활성도: 4점
```

### 2. 알고리즘 평가

**장점**:
- 다양한 요소를 종합적으로 고려
- 성격 궁합에서 보완/충돌 특성 반영
- 보호자 신뢰도(인증, 꼬순내지수) 반영

**개선 필요**:
- 사용자 선호도 미반영 (원하는 품종, 크기 등)
- 과거 매칭 이력 미반영
- 시간대별 활동 패턴 미반영

### 3. 개선 제안

```dart
// 추가 고려 요소
class EnhancedMatchingService {
  // A. 사용자 선호도 반영 (신규 10점)
  // - 선호 품종 일치: +4점
  // - 선호 크기 일치: +3점
  // - 선호 나이대 일치: +3점
  
  // B. 매칭 이력 반영 (기존 점수 조정)
  // - 이전에 좋아요 보낸 적 있으면 제외
  // - 이전에 거절당한 적 있으면 점수 감소
  
  // C. 활동 시간대 매칭 (신규 3점)
  // - 비슷한 시간대에 활동하는 사용자 우선
  
  // D. 상호 관심 부스트
  // - 상대방이 나를 좋아요 했으면 상단 노출
}
```

### 4. 재미 요소 추가 제안

```dart
// 1. 오늘의 운명의 친구
// - 매일 1명씩 "오늘의 추천" 제공
// - 높은 궁합 점수 + 랜덤 요소

// 2. 궁합 상세 분석
// - "체형이 비슷해요" "성격이 잘 맞아요" 등 문구
// - 공통점 하이라이트

// 3. 궁합 배지
// - 90% 이상: "환상의 궁합 🎉"
// - 80% 이상: "찰떡궁합 💕"
// - 70% 이상: "좋은 친구 😊"

// 4. 주간 매칭 리포트
// - "이번 주 N명과 매칭됐어요"
// - "가장 인기 있는 특성: 활발함"
```

---

## 🗄️ DB 모델링 개선 제안

### 1. 새로운 컬렉션 추가

```
// 사용자 선호도 (데이팅용)
userPreferences/{userId}
├── preferredBreeds: array<string>
├── preferredSizes: array<string> (small, medium, large)
├── preferredAgeMin: number
├── preferredAgeMax: number
├── preferredDistance: number (km)
├── preferredTraits: array<string>
└── updatedAt: timestamp

// 활동 로그 (분석용)
activityLogs/{logId}
├── userId: string
├── type: string (view, like, match, chat, meet, rate)
├── targetId: string
├── metadata: map
├── createdAt: timestamp
└── sessionId: string

// 평가 요청 (대기 중인 평가)
pendingRatings/{requestId}
├── raterId: string
├── targetId: string
├── type: string
├── relatedId: string
├── chatRoomId: string
├── requestedAt: timestamp
├── expiresAt: timestamp
├── reminderCount: number
└── status: string (pending, completed, expired)
```

### 2. 기존 컬렉션 수정

```
// users 컬렉션에 추가
users/{userId}
├── ... (기존 필드)
├── communityScore: number (커뮤니티 활동 점수)
├── postCount: number
├── commentCount: number
├── receivedLikeCount: number
└── lastRatingRequestAt: timestamp

// chatRooms 컬렉션에 추가
chatRooms/{chatRoomId}
├── ... (기존 필드)
├── meetingStatus: string (none, scheduled, completed, cancelled)
├── meetingCompletedAt: timestamp
├── ratingStatus: map<string, string> (userId: pending/completed)
└── transactionId: string (거래 상태 참조)
```

---

## 🔄 구현 우선순위

### Phase 1: 핵심 평가 시스템 (1~2주)

1. **평가 요청 서비스** (`PendingRatingService`)
   - 평가 요청 생성/조회/만료 처리
   - 리마인더 알림 발송

2. **평가 UI 구현**
   - 평가 바텀시트/화면
   - 별점 + 태그 + 코멘트 입력

3. **마켓플레이스 연동**
   - 거래 완료 버튼 추가
   - 완료 시 평가 요청 생성

### Phase 2: 활동 연동 (1주)

1. **활동 카운트 자동 업데이트**
   - 매칭 성사 시 `matchCount++`
   - 산책 완료 시 `walkCount++`
   - 거래 완료 시 `transactionCount++`
   - 소모임 참여 시 `groupCount++`

2. **꼬순내지수 자동 재계산**
   - 각 활동 완료 시 트리거

### Phase 3: 데이팅/소모임 연동 (1주)

1. **데이팅 만남 완료 기능**
   - 채팅방에 "만남 완료" 버튼
   - 완료 시 평가 요청

2. **소모임 일정 완료 기능**
   - 일정 종료 시 참여 확인
   - 모임장 평가 기능

### Phase 4: 고급 기능 (2주)

1. **사용자 선호도 설정**
   - 선호 품종/크기/나이 설정 UI
   - 매칭 알고리즘 반영

2. **커뮤니티 활동 반영**
   - 게시글/댓글/좋아요 카운트
   - 꼬순내지수 반영

3. **재미 요소 추가**
   - 오늘의 추천
   - 궁합 상세 분석
   - 주간 리포트

---

## 📱 타 앱 벤치마킹

### 당근마켓 (거래 평가)

```
[좋은 점]
- 거래 완료 후 자연스러운 평가 유도
- 매너온도로 신뢰도 시각화
- 간단한 태그 선택 방식

[적용 포인트]
- 평가 태그 시스템 (이미 구현됨)
- 온도 표시 방식 → 꼬순내지수 %로 대체
```

### 틴더/범블 (데이팅)

```
[좋은 점]
- 간단한 스와이프 UX
- 매칭 후 대화 유도
- 슈퍼라이크로 차별화

[적용 포인트]
- 이미 좋아요/슈퍼라이크 구현됨
- 매칭 후 평가는 가볍게 (이모지 수준)
```

### 소모임/문토 (소모임)

```
[좋은 점]
- 정기 모임 출석 체크
- 모임장 평가 시스템
- 활동 배지/레벨

[적용 포인트]
- 일정 참여 확인 기능 추가
- 소모임 활동 배지 시스템
```

---

## 🎮 재미 요소 아이디어

### 1. 게이미피케이션

```dart
// 배지 시스템
enum Badge {
  firstMatch,      // 첫 매칭
  socialButterfly, // 10회 매칭
  trustedSeller,   // 거래 10회 완료
  groupLeader,     // 소모임 3개 운영
  walkingChamp,    // 산책 100km 달성
  helpfulMember,   // 도움이 됐어요 50개
}

// 레벨 시스템
// Lv.1 새싹 → Lv.2 성장중 → Lv.3 친구 → Lv.4 베테랑 → Lv.5 마스터
// (이미 꼬순내지수 등급으로 구현됨)
```

### 2. 시즌 이벤트

```dart
// 봄: 벚꽃 산책 챌린지
// 여름: 물놀이 친구 찾기
// 가을: 단풍 산책 이벤트
// 겨울: 따뜻한 실내 모임
```

### 3. 통계 대시보드

```dart
// 내 활동 요약
class ActivityDashboard {
  int totalMatches;
  int totalWalks;
  double totalWalkDistance;
  int totalTransactions;
  int totalGroupMeetings;
  int receivedLikes;
  int sentLikes;
  String mostActiveDay; // "토요일"
  String mostActiveTime; // "오후 3시"
}
```

---

## 📝 코드 정리 및 공통화 제안

### 1. 서비스 레이어 통합

```dart
// 현재: 각 기능별 서비스 분산
// 제안: 공통 인터페이스 정의

abstract class ActivityService {
  Future<void> complete(String activityId);
  Future<void> requestRating(String activityId);
  Future<void> updateUserStats(String userId);
}

// MarketplaceActivityService, DatingActivityService 등이 구현
```

### 2. 평가 위젯 공통화

```dart
// 공통 평가 위젯
class RatingBottomSheet extends StatelessWidget {
  final RatingType type;
  final String targetId;
  final String? relatedId;
  
  // 타입에 따라 다른 태그 표시
  // 공통 별점/코멘트 UI
}
```

### 3. 알림 시스템 통합

```dart
// 평가 요청 알림 통합
class NotificationService {
  Future<void> sendRatingRequest({
    required String userId,
    required RatingType type,
    required String targetName,
  });
  
  Future<void> sendRatingReminder({
    required String userId,
    required String pendingRatingId,
  });
}
```

---

## ✅ 결론 및 권장 사항

### 즉시 구현 권장

1. **마켓플레이스 거래 완료 + 평가 요청** - 가장 명확한 트리거
2. **활동 카운트 자동 업데이트** - 꼬순내지수 정확도 향상
3. **평가 UI 공통 컴포넌트** - 재사용성

### 중기 구현 권장

1. **데이팅 만남 완료 기능** - 사용자 피드백 수집
2. **소모임 일정 완료 기능** - 커뮤니티 활성화
3. **사용자 선호도 설정** - 매칭 정확도 향상

### 장기 구현 권장

1. **커뮤니티 활동 점수 반영** - 앱 활성화
2. **게이미피케이션 요소** - 재미 요소
3. **AI 기반 매칭 고도화** - 차별화

---

*작성일: 2026-01-14*
*버전: 1.0*
