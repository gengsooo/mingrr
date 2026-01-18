# 🐾 소모임 기능 기획서

## 📋 목차
1. [현재 상태 분석](#1-현재-상태-분석)
2. [모임 일정 기능](#2-모임-일정-기능)
3. [역할 및 권한 체계](#3-역할-및-권한-체계)
4. [참여/취소 시스템](#4-참여취소-시스템)
5. [알림 시스템](#5-알림-시스템)
6. [데이터 모델](#6-데이터-모델)
7. [구현 우선순위](#7-구현-우선순위)

---

## 1. 현재 상태 분석

### 1.1 기존 모델 구조

| 모델 | 설명 | 상태 |
|-----|-----|-----|
| `GroupModel` | 소모임 기본 정보 | ✅ 구현됨 |
| `GroupScheduleModel` | 모임 일정 | ✅ 모델만 존재 |
| `GroupJoinRequestModel` | 가입 신청 | ✅ 모델만 존재 |
| `GroupLikeModel` | 좋아요 | ✅ 구현됨 |

### 1.2 기존 필드 현황

**GroupModel 주요 필드:**
- `creatorId`: 모임장 ID
- `adminIds`: 운영진 ID 목록 ✅ 이미 존재
- `memberIds`: 멤버 ID 목록
- `maxMembers`: 최대 인원
- `requireApproval`: 가입 승인 필요 여부

**GroupScheduleModel 주요 필드:**
- `participantIds`: 참여자 ID 목록
- `maxParticipants`: 최대 참여 인원
- `status`: 일정 상태 (upcoming/ongoing/completed/cancelled)

### 1.3 부족한 기능

| 기능 | 현재 상태 | 필요 작업 |
|-----|---------|---------|
| 모임 일정 생성 UI | ❌ 없음 | 신규 개발 |
| 일정 참여/취소 | ❌ 없음 | 신규 개발 |
| 운영진 관리 | ❌ 없음 | 신규 개발 |
| 푸시 알림 | ❌ 없음 | 신규 개발 |
| 참가비 정보 | ❌ 없음 | 모델 확장 |

---

## 2. 모임 일정 기능

### 2.1 일정 생성 (모임 열기)

**입력 필드:**

| 필드 | 타입 | 필수 | 설명 |
|-----|-----|-----|-----|
| `title` | String | ✅ | 일정 제목 (예: "한강 산책 모임") |
| `description` | String | ❌ | 상세 설명 |
| `purpose` | String | ✅ | 모임 목적 (산책/훈련/친목/기타) |
| `startTime` | DateTime | ✅ | 시작 일시 |
| `endTime` | DateTime | ❌ | 종료 일시 (예상) |
| `place` | String | ✅ | 장소명 |
| `location` | GeoPoint | ❌ | 위치 좌표 (지도 선택) |
| `address` | String | ❌ | 상세 주소 |
| `fee` | int | ❌ | 참가비 (0 = 무료) |
| `feeDescription` | String | ❌ | 참가비 설명 (예: "음료비 포함") |
| `maxParticipants` | int | ❌ | 제한 인원 (0 = 무제한) |
| `isPetRequired` | bool | ✅ | 반려동물 동반 필수 여부 |
| `requirements` | String | ❌ | 참여 조건 (예: "소형견만") |

### 2.2 일정 상태 관리

```
[예정] → [진행중] → [완료]
   ↓
[취소됨]
```

| 상태 | 설명 | 전환 조건 |
|-----|-----|---------|
| `upcoming` | 예정된 일정 | 생성 시 기본값 |
| `ongoing` | 진행 중 | 시작 시간 도달 (자동) |
| `completed` | 완료됨 | 종료 시간 도달 또는 수동 완료 |
| `cancelled` | 취소됨 | 모임장/운영진이 취소 |

### 2.3 일정 수정/삭제 권한

| 작업 | 모임장 | 운영진 | 일반 멤버 |
|-----|-------|-------|---------|
| 일정 생성 | ✅ | ✅ | ❌ |
| 일정 수정 | ✅ | ✅ (본인 생성만) | ❌ |
| 일정 취소 | ✅ | ✅ (본인 생성만) | ❌ |
| 일정 삭제 | ✅ | ❌ | ❌ |

---

## 3. 역할 및 권한 체계

### 3.1 역할 정의

| 역할 | 설명 | 인원 제한 |
|-----|-----|---------|
| **모임장 (Creator)** | 소모임 생성자, 최고 권한 | 1명 |
| **운영진 (Admin)** | 모임장이 지정, 관리 권한 | 최대 5명 |
| **멤버 (Member)** | 일반 가입 멤버 | 무제한 |

### 3.2 권한 매트릭스

| 기능 | 모임장 | 운영진 | 멤버 |
|-----|-------|-------|-----|
| **소모임 관리** |
| 소모임 정보 수정 | ✅ | ❌ | ❌ |
| 소모임 삭제 | ✅ | ❌ | ❌ |
| 운영진 임명/해제 | ✅ | ❌ | ❌ |
| 멤버 강퇴 | ✅ | ✅ | ❌ |
| 멤버 차단/차단 해제 | ✅ | ❌ | ❌ |
| 차단 목록 조회 | ✅ | ❌ | ❌ |
| 가입 신청 승인/거절 | ✅ | ✅ | ❌ |
| **일정 관리** |
| 일정 생성 (모임 열기) | ✅ | ✅ | ❌ |
| 일정 수정 | ✅ | ✅ (본인) | ❌ |
| 일정 취소 (모임 닫기) | ✅ | ✅ (본인) | ❌ |
| 참여자 강제 취소 | ✅ | ✅ (본인 일정) | ❌ |
| **참여** |
| 일정 참여 | ✅ | ✅ | ✅ |
| 참여 취소 | ✅ | ✅ | ✅ |
| 참여자 목록 조회 | ✅ | ✅ | ✅ |

### 3.3 운영진 관리 UI

**운영진 임명:**
1. 모임장이 멤버 목록에서 선택
2. "운영진으로 임명" 버튼
3. 확인 다이얼로그
4. 대상자에게 푸시 알림

**운영진 해제:**
1. 모임장이 운영진 목록에서 선택
2. "운영진 해제" 버튼
3. 확인 다이얼로그
4. 대상자에게 푸시 알림

### 3.4 멤버 차단 기능

**차단 기능 개요:**
- 모임장만 차단/차단 해제 가능
- 차단된 사용자는 해당 소모임에 재가입 불가
- 차단 시 닉네임으로 표시 (개인정보 보호)

**차단 플로우:**
```
[강퇴하기] → [차단 여부 선택] → [강퇴만] / [강퇴 + 차단]
                                          ↓
                                  [차단 시 재가입 불가]
```

**차단 UI:**
1. 모임장이 멤버 목록에서 선택
2. "강퇴하기" 버튼
3. "차단도 함께 하시겠습니까?" 체크박스
4. 확인 다이얼로그
5. 처리 완료

**차단 해제:**
1. 모임장이 "차단 목록" 메뉴 진입
2. 차단된 사용자 목록 표시 (닉네임, 차단일)
3. "차단 해제" 버튼
4. 확인 다이얼로그

**차단된 사용자 가입 시도 시:**
```
┌─────────────────────────────────┐
│  ⚠️ 가입 불가                      │
│                                 │
│  해당 소모임에서 차단되어       │
│  가입이 불가능합니다.             │
│                                 │
│  [확인]                          │
└─────────────────────────────────┘
```

---

## 4. 참여/취소 시스템

### 4.1 참여 플로우

```
[일정 상세] → [참여하기 버튼] → [참여 확인 팝업] → [참여 완료]
                                      ↓
                              [참가비 안내 표시]
                              [참여 조건 확인]
```

**참여 조건 체크:**
1. 소모임 멤버인지 확인
2. 제한 인원 초과 여부
3. 이미 참여 중인지 확인
4. 일정이 취소/완료되지 않았는지

### 4.2 참여 취소 플로우

```
[참여 중 상태] → [참여 취소 버튼] → [취소 확인 팝업] → [취소 완료]
```

**취소 안내:**
- 자유롭게 취소 가능
- 일정 시작 24시간 이내 취소 시 안내 메시지 표시

### 4.3 일정 후기
- 완료된 일정에 후기 작성 가능
- 사진 첨부 (최대 5장)
- 소모임 피드에 자동 게시
---

## 5. 알림 시스템

### 5.1 푸시 알림 종류

| 이벤트 | 대상 | 알림 내용 |
|-------|-----|---------|
| **일정 생성** | 전체 멤버 | "[모임명] 새 일정이 등록되었어요!" |
| **일정 수정** | 참여자 | "[모임명][일정명] 일정이 변경되었어요" |
| **일정 취소** | 참여자 | "[모임명][일정명] 일정이 취소되었어요 😢" |
| **일정 리마인더** | 참여자 | "[모임명][일정명] 내일 모임이 있어요! ⏰" |
| **운영진 임명** | 대상자 | "[모임명] 운영진이 되었어요! 🎉" |
| **운영진 해제** | 대상자 | "[모임명] 운영진에서 해제되었어요" |

### 5.2 알림 발송 시점

| 알림 | 발송 시점 |
|-----|---------|
| 일정 리마인더 | 일정 시작 24시간 전 |
| 일정 리마인더 | 일정 시작 1시간 전 |
| 일정 시작 | 일정 시작 시간 |

### 5.3 알림 설정 (사용자별)

| 설정 | 기본값 | 설명 |
|-----|-------|-----|
| 새 일정 알림 | ✅ ON | 소모임에 새 일정 등록 시 |
| 일정 변경 알림 | ✅ ON | 참여 중인 일정 변경 시 |
| 리마인더 알림 | ✅ ON | 일정 시작 전 알림 |

---

## 6. 데이터 모델

### 6.1 GroupScheduleModel 확장

```dart
class GroupScheduleModel {
  // 기존 필드
  final String id;
  final String groupId;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime? endTime;
  final String? place;
  final GeoPoint? location;
  final List<String> participantIds;
  final int maxParticipants;
  final String creatorId;
  final ScheduleStatus status;
  final DateTime createdAt;
  
  // 🆕 추가 필드
  final String? purpose;           // 모임 목적
  final String? address;           // 상세 주소
  final int fee;                   // 참가비 (0 = 무료)
  final String? feeDescription;    // 참가비 설명
  final bool isPetRequired;        // 반려동물 동반 필수
  final String? requirements;      // 참여 조건
  final DateTime? completedAt;     // 완료 처리 시간
}
```

### 6.2 ScheduleParticipation 모델 (신규)

```dart
/// 일정 참여 기록 (히스토리 및 통계용)
class ScheduleParticipationModel {
  final String id;
  final String scheduleId;
  final String groupId;
  final String userId;
  final ParticipationStatus status;  // joined/cancelled/completed
  final DateTime joinedAt;
  final DateTime? cancelledAt;
  final String? cancelReason;
}

enum ParticipationStatus {
  joined,     // 참여 신청
  cancelled,  // 취소
  completed,  // 참여 완료
}
```

### 6.3 UserModel 확장

```dart
// 기존 UserModel에 추가
class UserModel {
  // ... 기존 필드
  
  // 🆕 소모임 통계 필드
  final int groupParticipationCount;  // 총 참여 횟수
  final List<String> adminGroupIds;   // 운영진인 소모임 목록
}
```

### 6.4 Firestore 구조

```
groups/
  {groupId}/
    ...기존 필드
    blockedUsers/                 # 서브컬렉션 (차단 목록)
      {blockedUserId}/
        nickname: "홍길동"        # 차단 시점 닉네임
        blockedAt: Timestamp
        blockedBy: "creatorId"
    schedules/                    # 서브컬렉션
      {scheduleId}/
        title, description, ...
        participantIds: []
        
scheduleParticipations/           # 별도 컬렉션 (통계용)
  {participationId}/
    scheduleId, groupId, userId
    status, joinedAt, cancelledAt
```

---

## 7. 구현 우선순위

### Phase 1: 핵심 기능 (MVP)
| 순서 | 기능 | 예상 공수 |
|-----|-----|---------|
| 1 | GroupScheduleModel 확장 | 0.5일 |
| 2 | 일정 생성 UI/로직 | 1일 |
| 3 | 일정 목록/상세 UI | 1일 |
| 4 | 참여/취소 기능 | 0.5일 |
| 5 | 일정 수정/취소 기능 | 0.5일 |

### Phase 2: 권한 및 관리
| 순서 | 기능 | 예상 공수 |
|-----|-----|---------|
| 6 | 운영진 임명/해제 UI | 0.5일 |
| 7 | 권한 체크 로직 | 0.5일 |
| 8 | 멤버 관리 UI 개선 | 0.5일 |
| 9 | 멤버 차단/차단 해제 기능 | 0.5일 |

### Phase 3: 알림 및 연동
| 순서 | 기능 | 예상 공수 |
|-----|-----|---------|
| 10 | 푸시 알림 연동 | 1일 |

### Phase 4: 고도화
| 순서 | 기능 | 예상 공수 |
|-----|-----|---------|
| 11 | 일정 리마인더 (Cloud Functions) | 1일 |

---

## 📝 변경 이력

| 날짜 | 버전 | 변경 내용 |
|-----|-----|---------|
| 2024.01.16 | v1.0 | 초안 작성 |
| 2026.01.17 | v1.1 | 노쇼 기능 삭제, 멤버 차단 기능 추가 |
