# Firestore 복합 인덱스 정의

> **최종 수정일**: 2026-02-06  
> **버전**: 1.0.0  
> **인덱스 파일**: `firestore.indexes.json`

---

## 📋 개요

이 문서는 MINGRR 앱의 Firestore 복합 인덱스를 정의합니다.  
복합 쿼리(여러 필드 조건 + 정렬)를 사용하려면 인덱스가 필요합니다.

### 관련 문서

- [SCHEMA.md](./SCHEMA.md) - 스키마 정의
- [SECURITY_RULES.md](./SECURITY_RULES.md) - 보안 규칙

---

## 🔍 인덱스 기본 개념

### 단일 필드 인덱스
- Firestore가 자동 생성
- 별도 정의 불필요

### 복합 인덱스
- 여러 필드 조건 + 정렬 시 필요
- `firestore.indexes.json`에 정의
- 수동 배포 필요

### 배포 명령

```bash
# 인덱스만 배포
firebase deploy --only firestore:indexes

# 규칙 + 인덱스 배포
firebase deploy --only firestore
```

---

## 📊 컬렉션별 인덱스

### pets

| 필드 조합 | 용도 |
|----------|------|
| `ownerId` ASC + `isPrimary` DESC | 사용자의 대표 반려동물 조회 |
| `ownerId` ASC + `createdAt` DESC | 사용자의 반려동물 목록 (최신순) |
| `isBreedingAvailable` ASC + `createdAt` DESC | 교배 가능 반려동물 목록 |
| `ownerId` ASC + `isBreedingAvailable` ASC | 사용자의 교배 가능 반려동물 |

```json
{
  "collectionGroup": "pets",
  "fields": [
    { "fieldPath": "ownerId", "order": "ASCENDING" },
    { "fieldPath": "isPrimary", "order": "DESCENDING" }
  ]
}
```

---

### products

| 필드 조합 | 용도 |
|----------|------|
| `status` ASC + `createdAt` DESC | 상태별 상품 목록 (최신순) |
| `type` ASC + `createdAt` DESC | 타입별 상품 목록 |
| `sellerId` ASC + `createdAt` DESC | 판매자별 상품 목록 |
| `status` ASC + `type` ASC + `createdAt` DESC | 상태+타입 필터링 |
| `geohash` ASC + `status` ASC | 위치 기반 상품 검색 |

---

### groups

| 필드 조합 | 용도 |
|----------|------|
| `memberIds` ARRAY_CONTAINS + `updatedAt` DESC | 내 모임 목록 (최근 활동순) |
| `isPublic` ASC + `createdAt` DESC | 공개 모임 목록 (최신순) |
| `isPublic` ASC + `likeCount` DESC | 공개 모임 목록 (인기순) |
| `isPublic` ASC + `category` ASC + `createdAt` DESC | 카테고리별 모임 |
| `geohash` ASC + `isPublic` ASC | 위치 기반 모임 검색 |

---

### jobs

| 필드 조합 | 용도 |
|----------|------|
| `status` ASC + `createdAt` DESC | 상태별 알바 목록 |
| `userId` ASC + `createdAt` DESC | 사용자별 알바 목록 |
| `status` ASC + `type` ASC + `createdAt` DESC | 상태+타입 필터링 |

---

### breedingPosts

| 필드 조합 | 용도 |
|----------|------|
| `status` ASC + `createdAt` DESC | 상태별 교배글 목록 |
| `userId` ASC + `createdAt` DESC | 사용자별 교배글 목록 |

---

### likes

| 필드 조합 | 용도 |
|----------|------|
| `toUserId` ASC + `status` ASC + `createdAt` DESC | 받은 좋아요 (상태별) |
| `fromUserId` ASC + `createdAt` DESC | 보낸 좋아요 목록 |
| `toUserId` ASC + `createdAt` DESC | 받은 좋아요 목록 |

---

### matches

| 필드 조합 | 용도 |
|----------|------|
| `userIds` ARRAY_CONTAINS + `matchedAt` DESC | 내 매칭 목록 (최신순) |
| `userIds` ARRAY_CONTAINS + `isActive` ASC + `matchedAt` DESC | 활성 매칭 목록 |

---

### chatRooms

| 필드 조합 | 용도 |
|----------|------|
| `participantIds` ARRAY_CONTAINS + `lastMessageAt` DESC | 내 채팅방 목록 |
| `participantIds` ARRAY_CONTAINS + `type` ASC + `lastMessageAt` DESC | 타입별 채팅방 |

---

### messages

| 필드 조합 | 용도 |
|----------|------|
| `chatRoomId` ASC + `sentAt` ASC | 채팅방 메시지 목록 (시간순) |

---

### feedPosts

| 필드 조합 | 용도 |
|----------|------|
| `category` ASC + `createdAt` DESC | 카테고리별 게시글 |
| `userId` ASC + `createdAt` DESC | 사용자별 게시글 |

---

### feedComments

| 필드 조합 | 용도 |
|----------|------|
| `postId` ASC + `createdAt` ASC | 게시글 댓글 목록 (시간순) |

---

### schedules

| 필드 조합 | 용도 |
|----------|------|
| `groupId` ASC + `startTime` ASC | 모임 일정 목록 (시간순) |

---

### ratings

| 필드 조합 | 용도 |
|----------|------|
| `targetId` ASC + `createdAt` DESC | 대상별 평가 목록 |

---

### notifications

| 필드 조합 | 용도 |
|----------|------|
| `recipientId` ASC + `createdAt` DESC | 사용자 알림 목록 (최신순) |
| `recipientId` ASC + `isRead` ASC | 읽지 않은 알림 조회 |

---

### groupJoinRequests

| 필드 조합 | 용도 |
|----------|------|
| `groupId` ASC + `status` ASC + `createdAt` DESC | 모임별 가입 신청 (상태별) |

---

### walkRecords

| 필드 조합 | 용도 |
|----------|------|
| `petId` ASC + `startTime` DESC | 반려동물별 산책 기록 |
| `userId` ASC + `startTime` DESC | 사용자별 산책 기록 |

---

### productLikes

| 필드 조합 | 용도 |
|----------|------|
| `userId` ASC + `createdAt` DESC | 사용자 찜 목록 |

---

### favorites

| 필드 조합 | 용도 |
|----------|------|
| `userId` ASC + `targetType` ASC + `createdAt` DESC | 타입별 찜 목록 |

---

### dating_requests

| 필드 조합 | 용도 |
|----------|------|
| `toUserId` ASC + `createdAt` DESC | 받은 신청 목록 |
| `fromUserId` ASC + `createdAt` DESC | 보낸 신청 목록 |

---

### breeding_requests

| 필드 조합 | 용도 |
|----------|------|
| `receiverId` ASC + `createdAt` DESC | 받은 신청 목록 |
| `senderId` ASC + `createdAt` DESC | 보낸 신청 목록 |

---

### 건강수첩 컬렉션

| 컬렉션 | 필드 조합 | 용도 |
|--------|----------|------|
| `weightRecords` | `petId` ASC + `recordDate` DESC | 체중 기록 |
| `vaccinationRecords` | `petId` ASC + `vaccinationDate` DESC | 예방접종 기록 |
| `groomingRecords` | `petId` ASC + `recordDate` DESC | 미용 기록 |
| `checkupRecords` | `petId` ASC + `checkupDate` DESC | 검진 기록 |
| `medicationRecords` | `petId` ASC + `startDate` DESC | 투약 기록 |
| `special_notes` | `petId` ASC + `recordDate` DESC | 특이사항 |

---

## 🛠️ 인덱스 관리

### 인덱스 추가 방법

1. `firestore.indexes.json` 파일 수정
2. 배포: `firebase deploy --only firestore:indexes`

### 인덱스 확인

Firebase Console > Firestore > Indexes

### 인덱스 오류 해결

쿼리 실행 시 인덱스 오류가 발생하면:
1. 오류 메시지의 링크 클릭
2. Firebase Console에서 인덱스 자동 생성
3. 또는 `firestore.indexes.json`에 수동 추가

---

## ⚠️ 주의사항

### 인덱스 제한

- 컬렉션당 최대 200개 복합 인덱스
- 문서당 최대 40,000개 인덱스 항목

### 인덱스 생성 시간

- 데이터 양에 따라 수 분 ~ 수 시간 소요
- 생성 중에는 해당 쿼리 사용 불가

### 비용

- 인덱스는 저장 공간 사용
- 불필요한 인덱스는 삭제 권장

---

## 📝 변경 이력

| 날짜 | 버전 | 변경 내용 |
|------|------|----------|
| 2026-02-06 | 1.0.0 | 최초 작성 |
