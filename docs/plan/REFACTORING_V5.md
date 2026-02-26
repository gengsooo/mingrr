# MINGRR 5차 리팩토링 가이드 (V5)

> 작성일: 2026-02-10  
> 최종 수정일: 2026-02-10  
> 상태: ✅ **Phase 1~9 완료**  
> 목적: 사용자 경험 개선, 기능 완성, 신청/수락 패턴 통일, 검색 기능 강화

---

## 📊 V5 리팩토링 개요

V1~V4에서 공통 컴포넌트화, 백엔드 연동, 성능 최적화를 완료했습니다.  
V5에서는 **사용자 경험(UX) 개선**과 **미완성 기능 완성**에 집중합니다.

| 영역 | 목표 |
|------|------|
| **🔐 평가 시스템** | 중복 평가 방지, 진입 경로 정리 |
| **🔍 검색 기능** | 라우트 오류 수정, 통합 검색 개선 |
| **📅 소모임 일정** | 일정 등록/수정/참여 기능 완성 |
| **💕 교배찾기** | 리스트 카드 개선, 상세 화면 기획 |
| **🤝 신청/수락 패턴** | 공통 컴포넌트화, 디자인 통일 |

---

## 📋 현재 문제점 분석

### 1. 평가 시스템 문제

#### 1.1 현재 상태
```
평가 진입 경로:
├── 채팅 상세 → 옵션 → 평가하기 버튼
├── 채팅 상세 → 거래/만남 완료 → 자동 평가 모달
├── 홈 배너 → 평가 대기 목록 → 평가하기 버튼
└── 프로필 → (경로 불명확)

문제점:
├── ❌ 동일 거래에 대해 여러 번 평가 가능
├── ❌ 평가 완료 상태가 UI에 즉시 반영되지 않음
├── ❌ 프로필에서 평가 진입 경로가 불명확
└── ❌ hasRated() 메서드가 UI에서 미사용
```

#### 1.2 코드 분석

| 파일 | 위치 | 문제 |
|------|------|------|
| `rating_widgets.dart` | `_submitRating()` | 중복 체크 없이 바로 `createRating()` 호출 |
| `chat_detail_screen.dart` | `_showRatingSheet()` | `canRate` 조건이 `transaction` 기반이나 불완전 |
| `pending_ratings_screen.dart` | `_showRatingDialog()` | 평가 후 `markAsRated()` 미호출 |
| `rating_service.dart` | `hasRated()` | 존재하나 UI에서 미사용 |

#### 1.3 해결 방안

```dart
// 1. 평가 모달에서 중복 체크 추가
Future<void> _submitRating() async {
  // 중복 평가 체크
  if (widget.relatedId != null) {
    final alreadyRated = await _ratingService.hasRated(
      currentUser.uid, 
      widget.relatedId!,
    );
    if (alreadyRated) {
      MingrrSnackBar.warning(context, '이미 평가를 완료했습니다');
      Navigator.pop(context);
      return;
    }
  }
  // ... 기존 로직
}

// 2. TransactionStatusModel에 isRated 필드 활용
// 현재: sellerRated, buyerRated 필드 존재
// 개선: 평가 완료 시 markAsRated() 호출 보장

// 3. 평가 대기 목록에서 평가 완료 후 처리
void _showRatingDialog(BuildContext context, bool isSeller) {
  showRatingModal(
    context,
    // ...
    onComplete: () async {
      // 평가 완료 표시 추가
      await RatingService().markAsRated(widget.transaction.id, isSeller);
      ref.invalidate(pendingRatingsProvider);
    },
  );
}
```

---

### 2. 검색 기능 문제

#### 2.1 마켓 상품 상세 라우트 미등록

```
현재 상태:
├── 검색 결과에서 상품 클릭 → context.push('/market/product/${product.id}')
├── app.dart에 해당 라우트 미등록
└── 결과: Page Not Found 오류

해결:
├── /market/product/:id 라우트 추가
└── ProductDetailScreen 연결
```

#### 2.2 마켓 검색에서 알바 글 미포함

```
현재 상태:
├── SearchType.market → searchProducts() 호출
├── SearchType.job → searchJobs() 호출 (별도)
└── 마켓 화면에서 검색 시 상품만 검색됨

해결 방안:
├── 방안 1: 통합 검색 (searchMarketplace)
│   └── 상품 + 알바 동시 검색, 결과에 타입 배지 표시
├── 방안 2: 탭 기반 검색
│   └── 검색 화면에 상품/알바 탭 추가
└── 권장: 방안 1 (사용자 편의성)
```

#### 2.3 커뮤니티 검색에서 제목 미포함

```dart
// 현재 (firestore_service.dart:848-861)
.where((p) => 
    p.content.toLowerCase().contains(lowerQuery) ||  // 내용만
    p.tags.any((t) => t.toLowerCase().contains(lowerQuery)))  // 태그

// 개선
.where((p) => 
    p.title.toLowerCase().contains(lowerQuery) ||  // 제목 추가
    p.content.toLowerCase().contains(lowerQuery) ||
    p.tags.any((t) => t.toLowerCase().contains(lowerQuery)))
```

---

### 3. 소모임 일정 기능 미완성

#### 3.1 현재 상태

| 기능 | 상태 | 비고 |
|------|:----:|------|
| 일정 조회 | ✅ | `groupSchedulesProvider`, `_buildScheduleTab()` |
| 일정 등록 | ❌ | UI/로직 없음 |
| 일정 수정 | ❌ | UI/로직 없음 |
| 일정 삭제 | ❌ | UI/로직 없음 |
| 일정 참여 | ❌ | UI/로직 없음 |
| 일정 참여 취소 | ❌ | UI/로직 없음 |
| DB 모델 | ✅ | `GroupScheduleModel` |
| DB 서비스 | ⚠️ | `createSchedule()` 존재, 나머지 미구현 |

#### 3.2 필요한 작업

```
소모임 일정 기능 완성 로드맵
├── Phase 1: 일정 등록 (필수)
│   ├── 일정 탭에 FAB 버튼 추가 (멤버만)
│   ├── ScheduleWriteSheet 바텀시트 생성
│   │   ├── 제목 (필수)
│   │   ├── 날짜/시간 선택 (필수)
│   │   ├── 장소 (선택)
│   │   ├── 최대 참여 인원 (선택)
│   │   └── 상세 설명 (선택)
│   └── FirestoreService.createSchedule() 연동
│
├── Phase 2: 일정 관리 (권장)
│   ├── 일정 카드 탭 → 상세 바텀시트
│   │   ├── 일정 정보 표시
│   │   ├── 참여자 목록
│   │   └── 참여/취소 버튼
│   ├── 수정/삭제 기능 (생성자/관리자만)
│   └── FirestoreService 메서드 추가
│       ├── updateSchedule()
│       ├── deleteSchedule()
│       ├── joinSchedule()
│       └── leaveSchedule()
│
└── Phase 3: 알림 연동 (선택)
    ├── 일정 생성 시 멤버 알림
    ├── 일정 1일 전 리마인더
    └── 일정 변경/취소 알림
```

#### 3.3 UI 설계

```
일정 등록 바텀시트 (ScheduleWriteSheet)
┌─────────────────────────────────────────┐
│ ━━━━━━━━━━ (핸들)                        │
│                                         │
│ 📅 새 일정 만들기                        │
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │ 일정 제목                            │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ 📆 날짜 선택                            │
│ ┌─────────────────────────────────────┐ │
│ │ 2026년 2월 15일 (토)                 │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ ⏰ 시간 선택                            │
│ ┌─────────────────────────────────────┐ │
│ │ 오후 2:00                            │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ 📍 장소 (선택)                          │
│ ┌─────────────────────────────────────┐ │
│ │ 장소를 입력하세요                     │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ 👥 최대 인원 (선택)                      │
│ ┌─────────────────────────────────────┐ │
│ │ 제한 없음                            │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │           일정 만들기                 │ │
│ └─────────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

---

### 4. 교배찾기 기능 개선

#### 4.1 리스트 카드 문제

```
현재 DatingBreedingCard 표시 정보:
├── 이름
├── 품종
├── 크기 · 나이
├── 거리
├── 혈통서 배지
└── ❌ 교배글 제목/상세내용 미표시

문제점:
├── 교배글(BreedingPostModel)에 title, description 필드 존재
├── 하지만 카드에서 표시하지 않음
└── 사용자가 어떤 조건의 교배를 원하는지 알 수 없음
```

#### 4.2 리스트 카드 개선안

```
개선된 DatingBreedingCard 레이아웃
┌─────────────────────────────────────────┐
│ ┌───────┐                               │
│ │       │ 이름              거리 1.2km  │
│ │ 이미지 │ 품종                         │
│ │       │ 크기 · 나이                   │
│ │ 성별  │ ─────────────────────────────│
│ │ 배지  │ [교배글 제목]                 │
│ │       │ 상세내용 1줄...               │
│ └───────┘ [혈통서 배지]                 │
└─────────────────────────────────────────┘

필요한 변경:
├── DatingBreedingCard에 title 파라미터 추가
├── PetWithDistance에 breedingTitle 필드 추가
├── dating_provider.dart에서 교배글 정보 조회 로직 추가
└── 카드 높이 조정 (130 → 150)
```

#### 4.3 상세 화면 개선

```
현재 상태:
├── 교배찾기 카드 탭 → PetDetailScreen(isBreeding: true)
├── 반려동물 정보만 표시
└── 교배글 정보(제목, 상세내용, 희망 조건) 미표시

개선 방안:
├── 방안 1: PetDetailScreen 확장 (권장)
│   ├── isBreeding=true 시 교배글 정보 섹션 추가
│   ├── 교배글 제목, 상세내용, 조건 표시
│   └── 작성자인 경우 수정/삭제 버튼 표시
│
└── 방안 2: BreedingDetailScreen 신규 생성
    ├── 교배글 중심 레이아웃
    ├── 라우트 추가 필요 (/dating/breeding/:id)
    └── 코드 중복 발생 가능

권장: 방안 1 (기존 화면 확장)
```

#### 4.4 PetDetailScreen 확장 설계

```
PetDetailScreen (isBreeding: true)
├── 헤더: 반려동물 이미지 슬라이더 + 기본 정보
│
├── 섹션 1: 교배글 정보 (신규) ─────────────────
│   ├── 📝 교배글 제목
│   ├── 상세 내용 (접기/펼치기)
│   └── 희망 조건
│       ├── 희망 성별: 암컷
│       ├── 희망 크기: 소형, 중형
│       ├── 같은 품종만: 예
│       └── 희망 나이: 2~5세
│
├── 섹션 2: 반려동물 상세 (기존)
│   ├── 특성 태그
│   ├── 인증 정보 (혈통서, 건강검진 등)
│   └── 건강 정보
│
├── 섹션 3: 보호자 정보 (기존)
│   └── 꼬순내 지수, 프로필
│
└── 하단 버튼
    ├── 교배 신청 (타인의 글)
    └── 수정 / 삭제 (본인의 글)
```

---

### 5. 신청/수락 패턴 분석

#### 5.1 현재 신청 패턴

| 기능 | 신청 UI | 수락 UI | 상태 관리 | 알림 |
|------|---------|---------|----------|:----:|
| 데이팅 신청 | `RequestSheet(type: date)` | 채팅 상세 | `dating_requests` | ✅ |
| 교배 신청 | `RequestSheet(type: breeding)` | 채팅 상세 | `breeding_requests` | ✅ |
| 소모임 가입 | `RequestSheet(type: groupJoin)` | 소모임 상세 | `group_join_requests` | ✅ |
| 알바 지원 | `RequestSheet(type: jobApply)` | 알바 상세 | `job_applications` | ⚠️ |
| 마켓 채팅 | 직접 채팅방 생성 | - | `chat_rooms` | ✅ |

#### 5.2 공통화 현황

```
✅ 이미 공통화된 부분
├── RequestSheet: 4가지 타입 지원 (date, breeding, groupJoin, jobApply)
├── NotificationService: 알림 통합
└── ChatService: 채팅 연동 통합

⚠️ 개선 필요한 부분
├── 수락/거절 UI 통일 필요
│   ├── 데이팅: 채팅 상세에서 처리
│   ├── 소모임: 가입 신청 관리 화면
│   └── 알바: 알바 상세에서 처리
│
├── 상태 표시 배지 통일 필요
│   ├── 현재: 각 화면에서 개별 구현
│   └── 개선: RequestStatusBadge 공통 컴포넌트
│
└── 신청 목록 화면 패턴 통일 필요
    ├── 현재: 기능별 개별 화면
    └── 개선: 통합 신청 관리 화면 또는 패턴 통일
```

#### 5.3 공통 컴포넌트 설계

```dart
/// 1. 신청 상태 배지 (공통)
class RequestStatusBadge extends StatelessWidget {
  final RequestStatus status;  // pending, accepted, rejected, cancelled
  final RequestType type;      // dating, breeding, groupJoin, jobApply
  
  // 상태별 색상/텍스트 통일
  // pending: 노란색 "대기중"
  // accepted: 초록색 "수락됨"
  // rejected: 빨간색 "거절됨"
  // cancelled: 회색 "취소됨"
}

/// 2. 신청 수락/거절 액션 시트 (공통)
class RequestActionSheet extends StatelessWidget {
  final RequestType type;
  final String requesterName;
  final String? requesterImageUrl;
  final String? message;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback? onBlock;
}

/// 3. 신청 카드 (공통)
class RequestCard extends StatelessWidget {
  final RequestType type;
  final RequestStatus status;
  final String title;
  final String subtitle;
  final String? imageUrl;
  final DateTime createdAt;
  final VoidCallback? onTap;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
}
```

---

## 🗓️ 개발 로드맵

### Phase 1: 긴급 버그 수정 (1일) ✅ 완료

| # | 작업 | 대상 파일 | 예상 시간 | 상태 |
|:-:|------|----------|:--------:|:----:|
| 1-1 | 마켓 상품 상세 라우트 추가 | `app.dart` | 30분 | ✅ 완료 |
| 1-2 | 커뮤니티 검색에 제목 검색 추가 | `firestore_service.dart` | 30분 | ✅ 완료 |
| 1-3 | 평가 중복 방지 로직 추가 | `rating_widgets.dart` | 1시간 | ✅ 완료 |
| 1-4 | 평가 완료 후 markAsRated 호출 보장 | `pending_ratings_screen.dart` | 30분 | ✅ 완료 |

#### Phase 1 완료 내역 (2026-02-10)

**1-1. 마켓 상품 상세 라우트 추가**
- `app.dart`에 `/market/product/:id` 라우트 추가
- `ProductDetailScreen` import 추가
- 검색 결과에서 상품 클릭 시 Page Not Found 오류 해결

**1-2. 커뮤니티 검색에 제목 검색 추가**
- `firestore_service.dart`의 `searchCommunityPosts()` 수정
- 기존: 내용 + 태그 검색
- 개선: 제목 + 내용 + 태그 검색

**1-3. 평가 중복 방지 로직 추가**
- `rating_widgets.dart`의 `_submitRating()` 수정
- `hasRated()` 메서드를 활용하여 중복 평가 차단
- 이미 평가한 경우 "이미 평가를 완료했습니다" 메시지 표시

**1-4. 평가 완료 후 markAsRated 호출 보장**
- `pending_ratings_screen.dart`의 `_showRatingDialog()` 수정
- `onComplete` 콜백에서 `markAsRated()` 호출 추가
- 평가 대기 목록에서 평가 시에도 완료 상태 정상 반영

### Phase 2: 검색 기능 개선 (1일) ✅ 완료

| # | 작업 | 대상 파일 | 예상 시간 | 상태 |
|:-:|------|----------|:--------:|:----:|
| 2-1 | 마켓 통합 검색 메서드 추가 | `firestore_service.dart` | 1시간 | ✅ 완료 |
| 2-2 | 검색 결과 타입 배지 추가 | `search_screen.dart` | 1시간 | ✅ 완료 |
| 2-3 | 마켓 화면 검색 호출 수정 | `search_screen.dart` | 30분 | ✅ 완료 |
| 2-4 | 검색 힌트 텍스트 수정 | `search_screen.dart` | 15분 | ✅ 완료 |

#### Phase 2 완료 내역 (2026-02-10)

**2-1. 마켓 통합 검색 메서드 추가**
- `firestore_service.dart`에 `searchMarketAll()` 메서드 추가
- `Future.wait`로 상품/알바 병렬 검색
- 최신순 정렬하여 통합 결과 반환

**2-2. 검색 결과 타입 배지 추가**
- `_buildMarketItem()`: 상품/알바 타입 분기 처리
- `_buildProductItemWithBadge()`: 판매/나눔 배지 표시
- `_buildJobItemWithBadge()`: 알바 배지 표시
- 배지 스타일: 좌상단 라운드 코너, 피처 컬러 배경

**2-3. 마켓 화면 검색 호출 수정**
- `SearchType.market` 케이스에서 `searchMarketAll()` 호출
- 기존 `marketplace_screen.dart` 수정 불필요 (자동 적용)

**2-4. 검색 힌트 텍스트 수정**
- 마켓: `'상품, 알바 제목으로 검색'`
- 커뮤니티: `'게시글 제목, 내용, 태그로 검색'`
- 소모임: `'모임명, 설명, 태그로 검색'`

### Phase 3: 소모임 일정 기능 (2일) ✅ 완료

| # | 작업 | 대상 파일 | 예상 시간 | 상태 |
|:-:|------|----------|:--------:|:----:|
| 3-1 | FirestoreService 일정 메서드 추가 | `firestore_service.dart` | 1시간 | ✅ 완료 |
| 3-2 | ScheduleWriteSheet 생성 | `schedule_sheet.dart` (신규) | 2시간 | ✅ 완료 |
| 3-3 | ScheduleDetailSheet 생성 | `schedule_sheet.dart` | 1.5시간 | ✅ 완료 |
| 3-4 | 일정 탭 FAB 버튼 추가 | `group_detail_screen.dart` | 30분 | ✅ 완료 |
| 3-5 | 일정 카드 탭 → 상세 시트 연동 | `group_detail_screen.dart` | 30분 | ✅ 완료 |
| 3-6 | 일정 참여/취소 기능 | `schedule_sheet.dart` | 1시간 | ✅ 완료 |
| 3-7 | 일정 수정/삭제 기능 | `schedule_sheet.dart` | 1시간 | ✅ 완료 |

#### Phase 3 완료 내역 (2026-02-10)

**3-1. FirestoreService 일정 메서드 추가**
- `updateSchedule()`: 일정 수정
- `deleteSchedule()`: 일정 삭제
- `joinSchedule()`: 일정 참여 (FieldValue.arrayUnion)
- `leaveSchedule()`: 일정 참여 취소 (FieldValue.arrayRemove)

**3-2. ScheduleWriteSheet 생성**
- 일정 등록/수정 통합 바텀시트
- 제목, 날짜/시간, 장소, 최대 인원, 설명 입력
- 날짜/시간 선택 DatePicker, TimePicker 연동

**3-3. ScheduleDetailSheet 생성**
- 일정 상세 정보 표시 바텀시트
- 상태 배지 (예정/종료), 참여자 수, 정원 표시
- 참여/취소 버튼, 수정/삭제 버튼 (권한에 따라)

**3-4. 일정 탭 FAB 버튼 추가**
- AnimatedBuilder로 탭 변경 감지
- 일정 탭(index=2) + 멤버인 경우에만 FAB 표시

**3-5. 일정 카드 탭 → 상세 시트 연동**
- GestureDetector로 카드 탭 감지
- showScheduleDetailSheet() 호출
- 관리자 권한 전달

**3-6. 일정 참여/취소 기능**
- 참여 상태에 따라 버튼 텍스트 변경
- 정원 초과 시 "정원이 마감되었습니다" 표시
- 참여/취소 후 목록 자동 갱신

**3-7. 일정 수정/삭제 기능**
- 생성자 또는 그룹 관리자만 수정/삭제 가능
- 삭제 시 확인 다이얼로그 표시
- 수정 시 기존 데이터 폼에 자동 입력

### Phase 4: 교배찾기 개선 (2일) ✅ 완료

| # | 작업 | 대상 파일 | 예상 시간 | 상태 |
|:-:|------|----------|:--------:|:----:|
| 4-1 | PetWithDistance에 breedingTitle, breedingPostId 추가 | `dating_provider.dart` | 1시간 | ✅ 완료 |
| 4-2 | DatingBreedingCard에 breedingTitle 파라미터 추가 | `dating_card.dart` | 30분 | ✅ 완료 |
| 4-3 | 카드 레이아웃 재설계 (제목 우선 표시) | `dating_card.dart` | 1시간 | ✅ 완료 |
| 4-4 | PetDetailScreen 교배글 정보 섹션 추가 | `pet_detail_screen.dart` | 2시간 | ✅ 완료 |
| 4-5 | 교배글 조회 로직 추가 | `pet_detail_screen.dart` | 1시간 | ✅ 완료 |
| 4-6 | 교배글 수정/삭제 버튼 추가 | `pet_detail_screen.dart` | 1시간 | ✅ 완료 |
| 4-7 | 교배 조건 표시 UI | `pet_detail_screen.dart` | 1시간 | ✅ 완료 |

#### Phase 4 완료 내역 (2026-02-10)

**4-1. PetWithDistance에 breedingTitle, breedingPostId 추가**
- `breedingPostId`: 교배글 ID (상세 화면에서 직접 조회용)
- `breedingTitle`: 교배글 제목 (카드에 표시용)
- Provider에서 교배글 조회 시 id, title, description 모두 저장

**4-2. DatingBreedingCard에 breedingTitle 파라미터 추가**
- `breedingTitle` 파라미터 추가
- dating_screen.dart에서 전달하도록 수정

**4-3. 카드 레이아웃 재설계**
- 교배글 제목을 상단에 강조 표시 (데이팅 테마 색상)
- 반려동물 정보 압축 (이름 · 품종 · 나이)
- 상세 설명 2줄 제한

**4-4. PetDetailScreen 교배글 정보 섹션 추가**
- `_buildBreedingDescription()` 메서드 개선
- 교배글 제목, 조건, 설명 표시
- 내 글인 경우 수정/삭제 버튼 표시

**4-5. 교배글 조회 로직 추가**
- `_getBreedingPost()` 메서드 추가
- breedingPostId가 있으면 직접 조회, 없으면 petId로 검색
- BreedingPostModel 반환

**4-6. 교배글 수정/삭제 버튼 추가**
- `_editBreedingPost()`: BreedingWriteScreen으로 이동
- `_deleteBreedingPost()`: 확인 시트 후 삭제

**4-7. 교배 조건 표시 UI**
- `_buildBreedingConditions()` 메서드 추가
- 성별, 품종, 크기, 나이 조건 배지로 표시
- 데이팅 테마 색상 적용

### Phase 5: 신청/수락 패턴 통일 (2일) ✅ 완료

| # | 작업 | 대상 파일 | 예상 시간 | 상태 |
|:-:|------|----------|:--------:|:----:|
| 5-1 | UnifiedRequestStatus enum 정의 | `request_status_badge.dart` (신규) | 30분 | ✅ 완료 |
| 5-2 | RequestStatusBadge 공통 컴포넌트 생성 | `request_status_badge.dart` (신규) | 1시간 | ✅ 완료 |
| 5-3 | RequestActionSheet 공통 컴포넌트 생성 | `request_action_sheet.dart` (신규) | 1.5시간 | ✅ 완료 |
| 5-4 | RequestCard 공통 컴포넌트 생성 | `request_card.dart` (신규) | 1.5시간 | ✅ 완료 |
| 5-5 | 공통 컴포넌트 export 추가 | `badges.dart`, `cards.dart`, `sheets.dart` | 30분 | ✅ 완료 |
| 5-6 | chat_list_screen.dart에 RequestCard 적용 | `chat_list_screen.dart` | 30분 | ✅ 완료 |
| 5-7 | 사용되지 않는 코드 정리 | `chat_list_screen.dart` | 15분 | ✅ 완료 |
| 5-8 | AsyncRequestCard 컴포넌트 생성 | `request_card.dart` | 1시간 | ✅ 완료 |
| 5-9 | group_detail_screen.dart에 AsyncRequestCard 적용 | `group_detail_screen.dart` | 30분 | ✅ 완료 |
| 5-10 | _JoinRequestTile 클래스 삭제 | `group_detail_screen.dart` | 10분 | ✅ 완료 |

#### Phase 5 완료 내역 (2026-02-10)

**5-1. UnifiedRequestStatus enum 정의**
- 통합 신청 상태 enum (pending, accepted, rejected, cancelled)
- 기존 Enum에서 변환하는 팩토리 메서드 제공
- DB 호환성 유지 (기존 Enum 수정 없음)

**5-2. RequestStatusBadge 공통 컴포넌트 생성**
- 신청 상태 배지 위젯 (아이콘 + 텍스트)
- 크기별 variant (small, medium, large)
- 팩토리 생성자: `fromDating()`, `fromGroup()`, `fromJob()`

**5-3. RequestActionSheet 공통 컴포넌트 생성**
- 신청 수락/거절 액션 시트
- 발신자 정보, 메시지, 시간 표시
- 타입별 테마 색상 자동 적용

**5-4. RequestCard 공통 컴포넌트 생성**
- 신청 카드 위젯 (프로필, 상태, 메시지, 액션 버튼)
- 대기 중일 때만 수락/거절 버튼 표시
- RequestCardList: 빈 상태 포함 리스트 위젯

**5-5. 공통 컴포넌트 export 추가**
- `badges/badges.dart`: request_status_badge.dart 추가
- `cards/cards.dart`: request_card.dart 추가
- `sheets/sheets.dart`: request_action_sheet.dart, schedule_sheet.dart 추가

**5-6. chat_list_screen.dart에 RequestCard 적용**
- `_buildRequestItem()`: 데이팅/교배 신청 카드를 RequestCard로 교체
- `_buildJobApplicationItem()`: 알바 지원 카드를 RequestCard로 교체
- 코드 약 180줄 → 30줄로 축소 (83% 감소)

**5-7. 사용되지 않는 코드 정리**
- `_formatRequestTime()` 메서드 삭제 (RequestCard 내부에서 처리)

**5-8. AsyncRequestCard 컴포넌트 생성**
- 비동기 사용자 정보 로딩 지원
- 스켈레톤 로딩 UI 포함
- 처리 중 상태 표시 (CircularProgressIndicator)

**5-9. group_detail_screen.dart에 AsyncRequestCard 적용**
- `_showJoinRequests()`: _JoinRequestTile → AsyncRequestCard 교체
- 비동기 사용자 정보 로딩 로직 통합

**5-10. _JoinRequestTile 클래스 삭제**
- 약 225줄 코드 삭제
- AsyncRequestCard로 완전 대체

### Phase 6: 평가 시스템 개선 (1일) ✅ 완료

| # | 작업 | 대상 파일 | 예상 시간 | 상태 |
|:-:|------|----------|:--------:|:----:|
| 6-1 | RatingType 유틸리티 통합 | `rating_model.dart` | 30분 | ✅ 완료 |
| 6-2 | 중복 함수 제거 (4개 파일) | `rating_widgets.dart` 외 3개 | 1시간 | ✅ 완료 |
| 6-3 | RatingCard 공통 컴포넌트 생성 | `rating_widgets.dart` | 1시간 | ✅ 완료 |
| 6-4 | pending_ratings_screen.dart에 RatingCard 적용 | `pending_ratings_screen.dart` | 30분 | ✅ 완료 |

#### Phase 6 완료 내역 (2026-02-10)

**6-1. RatingType 유틸리티 통합**
- `RatingType.fromActivityType()`: 문자열에서 RatingType 변환
- `RatingType.activityLabel`: 활동 타입 라벨 (한글)
- `RatingType.positiveTags`, `negativeTags`: 평가 태그 목록

**6-2. 중복 함수 제거 (DRY 원칙)**
- `rating_widgets.dart`: `_getRatingType()`, `_getActivityTypeLabel()` 삭제
- `chat_detail_screen.dart`: `_getRatingType()` 삭제
- `pending_ratings_screen.dart`: `_getRatingType()`, `_getTypeLabel()` 간소화
- `notification_service.dart`: `_getActivityTypeLabel()` 삭제
- 총 약 60줄 중복 코드 제거

**6-3. RatingCard 공통 컴포넌트 생성**
- `RatingCard`: 평가 카드 위젯 (프로필, 타입 배지, 별점, 태그)
- `AsyncRatingCard`: 비동기 사용자 정보 로딩 지원
- 스켈레톤 로딩 UI 포함

**6-4. pending_ratings_screen.dart에 RatingCard 적용**
- `_PendingRatingCard` 클래스 삭제
- `AsyncRatingCard` 공통 컴포넌트 적용
- 코드 243줄 → 117줄로 축소 (52% 감소)

### Phase 7: 평가 이력 기능 완성 (0.5일) ✅ 완료

| # | 작업 | 대상 파일 | 예상 시간 | 상태 |
|:-:|------|----------|:--------:|:----:|
| 7-1 | 평가 이력 조회 화면 생성 | `rating_history_screen.dart` (신규) | 2시간 | ✅ 완료 |
| 7-2 | 프로필 화면에 평가 이력 진입점 추가 | `profile_screen.dart` | 30분 | ✅ 완료 |
| 7-3 | app.dart에 라우트 추가 | `app.dart` | 10분 | ✅ 완료 |

#### Phase 7 완료 내역 (2026-02-10)

**7-1. 평가 이력 조회 화면 생성**
- `rating_history_screen.dart` 신규 생성
- 탭 구성: 받은 평가 / 보낸 평가
- `RatingCard` 공통 컴포넌트 활용
- `receivedRatingsProvider`, `givenRatingsProvider` 생성

**7-2. 프로필 화면에 평가 이력 진입점 추가**
- 메뉴 목록에 "평가 이력" 추가 (내 활동, 좋아요 목록 사이)
- `AppIcons.starOutlined` 아이콘 사용

**7-3. app.dart에 라우트 추가**
- `/profile/rating-history` 라우트 추가
- `RatingHistoryScreen` import 추가

### Phase 8: 코드 정리 (0.5일) ✅ 완료

| # | 작업 | 대상 파일 | 예상 시간 | 상태 |
|:-:|------|----------|:--------:|:----:|
| 8-1 | `_formatDate()` 중복 제거 | `format_utils.dart` + 2개 파일 | 30분 | ✅ 완료 |
| 8-2 | 미사용 import 정리 | 12개 파일 | 30분 | ✅ 완료 |

#### Phase 8 완료 내역 (2026-02-10)

**8-1. `_formatDate()` 중복 제거**
- `format_utils.dart`에 `formatRelativeDate()` 함수 추가
- `rating_widgets.dart`: `_formatDate()` 삭제, `formatRelativeDate()` 사용
- `my_activity_screen.dart`: `_formatDate()` 삭제, `formatRelativeDate()` 사용

**8-2. 미사용 import 정리**
- `app.dart`: `svg_icons.dart`, `flutter_svg.dart` 제거
- `network_provider.dart`: `dart:async` 제거
- `bottom_sheet_stack_manager.dart`: `flutter/material.dart` 제거
- `location_helper.dart`: `flutter/foundation.dart` 제거
- `request_status_badge.dart`: `feature_colors.dart` 제거
- `product_card.dart`: `distance_badge.dart` 제거
- `common_widgets.dart`: `cached_network_image.dart`, `svg_icons.dart` 제거
- `form_components.dart`: `image_utils.dart` 제거
- `skeleton_widgets.dart`: `feature_colors.dart` 제거
- `location_bubble_widget.dart`: `feature_colors.dart` 제거
- `mingrr_app_bar.dart`: `app_theme.dart` 제거
- `mingrr_image_viewer.dart`: `loading_widgets.dart` 제거
- `chat_options_modal.dart`: `common_widgets.dart` 제거
- `profile_icon.dart`: `go_router.dart`, `app_sizes.dart` 제거
- `search_screen.dart`: `svg_icons.dart` 제거
- `confirm_sheet.dart`: `common_widgets.dart` 제거
- `request_action_sheet.dart`: `dialog_buttons.dart` 제거

### Phase 9: format_utils 확장 (1시간) ✅ 완료

| # | 작업 | 대상 파일 | 예상 시간 | 상태 |
|:-:|------|----------|:--------:|:----:|
| 9-1 | format_utils.dart 함수 추가 | `format_utils.dart` | 15분 | ✅ 완료 |
| 9-2 | marketplace_screen.dart 중복 함수 제거 | `marketplace_screen.dart` | 10분 | ✅ 완료 |
| 9-3 | health_screen.dart 중복 함수 제거 | `health_screen.dart` | 10분 | ✅ 완료 |
| 9-4 | health_record_detail_screens.dart 중복 함수 제거 | `health_record_detail_screens.dart` | 15분 | ✅ 완료 |
| 9-5 | walk_record_detail_screen.dart 중복 함수 제거 | `walk_record_detail_screen.dart` | 10분 | ✅ 완료 |

#### Phase 9 완료 내역 (2026-02-10)

**9-1. format_utils.dart 함수 추가**
- `formatShortDateTime()`: 짧은 날짜+시간 (M/d HH:mm)
- `formatTimeRange()`: 시간 범위 (HH:mm ~ HH:mm)
- `formatDateWithWeekday()`: 날짜+요일 (yyyy년 M월 d일 (요일))

**9-2. marketplace_screen.dart 중복 함수 제거**
- `_formatDate()` 삭제 → `formatShortDate()` 사용
- 약 4줄 중복 코드 제거

**9-3. health_screen.dart 중복 함수 제거**
- `_formatDate()` 삭제 → `formatShortDate()` 사용
- `_formatDateTime()` 삭제 → `formatShortDateTime()` 사용
- 약 8줄 중복 코드 제거

**9-4. health_record_detail_screens.dart 중복 함수 제거**
- 6개 `_formatDate()` 삭제 → `formatDateKorean()` 사용
- 1개 `_formatTime()` 삭제 → `formatTime()` 사용
- 약 28줄 중복 코드 제거

**9-5. walk_record_detail_screen.dart 중복 함수 제거**
- `_formatDate()` 삭제 → `formatDateWithWeekday()` 사용
- `_formatTime()` 삭제 → `formatTime()`, `formatTimeRange()` 사용
- 약 8줄 중복 코드 제거

---

## 📁 파일 변경 목록

### 수정 필요 파일

```
lib/
├── app.dart                                    # 라우트 추가
├── core/
│   ├── services/
│   │   ├── firestore_service.dart              # 검색/일정 메서드
│   │   ├── notification_service.dart           # 일정 알림
│   │   └── rating_service.dart                 # 평가 로직 개선
│   └── widgets/
│       ├── cards/
│       │   └── dating_card.dart                # 교배 카드 개선
│       ├── rating_widgets.dart                 # 중복 평가 방지
│       └── search_screen.dart                  # 통합 검색
├── features/
│   ├── dating/
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── dating_provider.dart        # 교배글 정보 조회
│   │       └── screens/
│   │           └── pet_detail_screen.dart      # 교배글 섹션 추가
│   ├── profile/
│   │   └── presentation/
│   │       └── screens/
│   │           └── pending_ratings_screen.dart # 평가 완료 처리
│   └── social/
│       └── presentation/
│           ├── providers/
│           │   └── group_provider.dart         # 일정 참여 로직
│           └── screens/
│               └── group_detail_screen.dart    # 일정 FAB, 상세
└── models/
    └── group_model.dart                        # 일정 모델 확장
```

### 신규 생성 파일

```
lib/
├── core/
│   └── widgets/
│       ├── badges/
│       │   └── request_status_badge.dart       # 신청 상태 배지
│       ├── cards/
│       │   └── request_card.dart               # 신청 카드
│       └── sheets/
│           ├── request_action_sheet.dart       # 수락/거절 시트
│           ├── schedule_write_sheet.dart       # 일정 등록 시트
│           └── schedule_detail_sheet.dart      # 일정 상세 시트
├── features/
│   └── profile/
│       └── presentation/
│           └── screens/
│               └── rating_history_screen.dart  # 평가 이력 화면
└── models/
    └── request_model.dart                      # 신청 공통 모델
```

---

## 📊 예상 효과

### 사용자 경험 개선

| 항목 | 현재 | 개선 후 |
|------|------|--------|
| 평가 중복 | 가능 | 불가능 |
| 마켓 검색 | 상품만 | 상품+알바 |
| 커뮤니티 검색 | 내용+태그 | 제목+내용+태그 |
| 소모임 일정 | 조회만 | 등록/수정/참여 |
| 교배찾기 카드 | 기본 정보 | 교배글 정보 포함 |
| 신청 상태 | 화면별 다름 | 통일된 UI |

### 코드 품질 개선

| 항목 | 현재 | 개선 후 |
|------|------|--------|
| 신청 관련 코드 | 분산 | 공통 컴포넌트 |
| 상태 배지 | 개별 구현 | RequestStatusBadge |
| 수락/거절 UI | 화면별 다름 | RequestActionSheet |

### 예상 작업량

| Phase | 작업 수 | 예상 시간 | 난이도 |
|:-----:|:------:|:--------:|:------:|
| Phase 1 | 4 | 2.5시간 | 낮음 |
| Phase 2 | 4 | 2.75시간 | 낮음 |
| Phase 3 | 7 | 8시간 | 중간 |
| Phase 4 | 7 | 8시간 | 중간 |
| Phase 5 | 7 | 8시간 | 중간 |
| Phase 6 | 4 | 5시간 | 중간 |
| **총합** | **33** | **~34시간** | - |

---

## 🔧 기술적 고려사항

### 1. 데이터베이스 스키마 변경

```
schedules 컬렉션 (기존)
├── id: string
├── groupId: string
├── title: string
├── description: string?
├── startTime: timestamp
├── endTime: timestamp?
├── place: string?
├── location: geopoint?
├── participantIds: string[]
├── maxParticipants: number
├── creatorId: string
├── status: string (upcoming/ongoing/completed/cancelled)
└── createdAt: timestamp

변경 없음 (기존 스키마 활용)
```

### 2. Firestore 인덱스 추가

```json
// firestore.indexes.json에 추가
{
  "collectionGroup": "schedules",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "groupId", "order": "ASCENDING" },
    { "fieldPath": "startTime", "order": "ASCENDING" }
  ]
}
```

### 3. 보안 규칙 업데이트

```javascript
// 일정 관련 규칙
match /schedules/{scheduleId} {
  // 읽기: 해당 그룹 멤버만
  allow read: if isGroupMember(resource.data.groupId);
  
  // 생성: 해당 그룹 멤버만
  allow create: if isGroupMember(request.resource.data.groupId);
  
  // 수정: 생성자 또는 그룹 관리자만
  allow update: if isScheduleCreator() || isGroupAdmin(resource.data.groupId);
  
  // 삭제: 생성자 또는 그룹 관리자만
  allow delete: if isScheduleCreator() || isGroupAdmin(resource.data.groupId);
}
```

---

## 📝 테스트 체크리스트

### Phase 1 테스트

- [ ] 마켓 검색 → 상품 클릭 → 상세 화면 이동 확인
- [ ] 커뮤니티 검색 → 제목으로 검색 → 결과 표시 확인
- [ ] 동일 거래에 대해 평가 2회 시도 → 차단 확인
- [ ] 평가 완료 후 평가 대기 목록에서 제거 확인

### Phase 2 테스트

- [ ] 마켓 검색 → 상품+알바 동시 검색 확인
- [ ] 검색 결과에 타입 배지 표시 확인
- [ ] 알바 검색 결과 클릭 → 상세 화면 이동 확인

### Phase 3 테스트

- [ ] 소모임 일정 탭 → FAB 버튼 표시 확인 (멤버만)
- [ ] 일정 등록 → 목록에 표시 확인
- [ ] 일정 카드 탭 → 상세 바텀시트 표시 확인
- [ ] 일정 참여/취소 → 참여자 수 변경 확인
- [ ] 일정 수정/삭제 → 권한 체크 확인

### Phase 4 테스트

- [ ] 교배찾기 카드에 제목 표시 확인
- [ ] 교배찾기 상세 → 교배글 정보 섹션 표시 확인
- [ ] 본인 교배글 → 수정/삭제 버튼 표시 확인
- [ ] 타인 교배글 → 교배 신청 버튼 표시 확인

### Phase 5 테스트

- [ ] 신청 상태 배지 통일 확인 (데이팅, 소모임, 알바)
- [ ] 수락/거절 시트 통일 확인
- [ ] 신청 카드 통일 확인

### Phase 6 테스트

- [ ] 평가 진입 경로 정리 확인
- [ ] 평가 완료 상태 즉시 반영 확인
- [ ] 평가 이력 조회 화면 동작 확인

---

## 📌 우선순위 가이드

### 🔴 즉시 수정 (Phase 1)
- 마켓 검색 Page Not Found 오류
- 커뮤니티 검색 제목 미포함
- 평가 중복 가능 문제

### 🟡 기능 완성 (Phase 2-4)
- 마켓 통합 검색
- 소모임 일정 등록/관리
- 교배찾기 카드/상세 개선

### 🟢 UX 개선 (Phase 5-6)
- 신청/수락 패턴 통일
- 평가 시스템 개선

---

## 📚 참고 문서

- [REFACTORING_V1.md](./REFACTORING_V1.md) - 공통 컴포넌트화
- [REFACTORING_V2.md](./REFACTORING_V2.md) - 백엔드 연동, 디자인 통일
- [REFACTORING_V3.md](./REFACTORING_V3.md) - 성능 최적화
- [REFACTORING_V4.md](./REFACTORING_V4.md) - 코드 정리
- [GROUP_PLANNING.md](./GROUP_PLANNING.md) - 소모임 기획
- [SCHEMA.md](../database/SCHEMA.md) - 데이터베이스 스키마

---

> **작성자 노트**  
> V5는 사용자 경험 개선에 집중합니다. 기존 기능의 완성도를 높이고,  
> 신청/수락 패턴을 통일하여 일관된 UX를 제공하는 것이 목표입니다.  
> Phase 1(긴급 버그 수정)을 먼저 진행하고, 나머지는 순차적으로 진행합니다.
