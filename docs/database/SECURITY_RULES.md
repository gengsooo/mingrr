# Firestore 보안 규칙 가이드

> **최종 수정일**: 2026-02-06  
> **버전**: 1.0.0  
> **규칙 파일**: `firestore.rules`

---

## 📋 개요

이 문서는 MINGRR 앱의 Firestore 보안 규칙을 설명합니다.  
모든 데이터 접근은 이 규칙에 의해 제어됩니다.

### 관련 문서

- [SCHEMA.md](./SCHEMA.md) - 스키마 정의
- [INDEXES.md](./INDEXES.md) - 복합 인덱스 정의

---

## 🔧 헬퍼 함수

### 인증 관련

| 함수 | 설명 | 사용 예시 |
|------|------|----------|
| `isSignedIn()` | 로그인 여부 확인 | `allow read: if isSignedIn();` |
| `isOwner(userId)` | 본인 데이터인지 확인 | `allow update: if isOwner(userId);` |
| `isAdmin()` | 관리자 계정인지 확인 | `allow write: if isAdmin();` |

### 데이터 접근

| 함수 | 설명 | 사용 예시 |
|------|------|----------|
| `existingData()` | 기존 문서 데이터 | `existingData().ownerId` |
| `incomingData()` | 새로 저장할 데이터 | `incomingData().ownerId` |

### 유효성 검증

| 함수 | 설명 | 파라미터 |
|------|------|----------|
| `isValidTextLength(field, maxLength)` | 텍스트 길이 제한 | 필드명, 최대 길이 |
| `isValidMessageLength()` | 메시지 길이 제한 (1000자) | - |
| `isValidPostContentLength()` | 게시글 길이 제한 (5000자) | - |

> ⚠️ **주의**: `isValidDocSize()` 함수는 Firestore에서 `request.resource.size`를 지원하지 않아 제거되었습니다. Firestore는 문서당 1MB 제한이 기본 적용됩니다.

---

## 👤 관리자 계정

```javascript
function isAdmin() {
  return isSignedIn() && (
    request.auth.token.email == 'admin@mingrr.com' ||
    request.auth.token.email == 'gengsooo@gmail.com'
  );
}
```

관리자는 모든 컬렉션에 대해 전체 권한을 가집니다.

---

## 📊 컬렉션별 권한 규칙

### users - 사용자

| 작업 | 조건 | 설명 |
|------|------|------|
| **read** | `isSignedIn()` | 로그인한 사용자는 모든 사용자 조회 가능 |
| **list** | `limit <= 1` | 이메일 중복 검사용 (회원가입 시) |
| **create** | `isOwner(userId)` | 본인 계정만 생성 |
| **update** | `isOwner(userId)` 또는 카운터 필드만 변경 | 본인 계정만 수정 |
| **delete** | `isOwner(userId)` | 본인 계정만 삭제 |

📌 **카운터 필드 예외**: 다른 사용자도 다음 필드만 변경 가능 (가입/탈퇴/평가 등)
- `groupCount`, `postCount`, `walkCount`, `matchCount`
- `transactionCount`, `reportCount`, `locationMismatchCount`
- `ratingCount`, `averageRating`, `noShowCount`, `kkosunnaeScore`

```javascript
allow update: if isOwner(userId) || 
  (isSignedIn() && request.resource.data.diff(resource.data).affectedKeys()
    .hasOnly(['groupCount', 'postCount', 'walkCount', 'matchCount', 
              'transactionCount', 'reportCount', 'locationMismatchCount',
              'ratingCount', 'averageRating', 'noShowCount', 'kkosunnaeScore']));
```

---

### pets - 반려동물

| 작업 | 조건 | 설명 |
|------|------|------|
| **read** | `isSignedIn()` | 로그인한 사용자는 모든 반려동물 조회 가능 |
| **create** | `incomingData().ownerId == uid` | 본인 소유로만 생성 |
| **update** | `existingData().ownerId == uid` | 본인 소유만 수정 |
| **delete** | `existingData().ownerId == uid` | 본인 소유만 삭제 |

---

### chatRooms - 채팅방

| 작업 | 조건 | 설명 |
|------|------|------|
| **read** | `uid in participantIds` | 참여자만 조회 |
| **create** | `uid in incomingData().participantIds` | 참여자로 포함되어야 생성 |
| **update** | `uid in existingData().participantIds` | 참여자만 수정 |
| **delete** | `uid in existingData().participantIds` | 참여자만 삭제 |

### messages (chatRooms 서브컬렉션)

| 작업 | 조건 | 설명 |
|------|------|------|
| **read** | 부모 채팅방 참여자 | 채팅방 참여자만 조회 |
| **create** | `senderId == uid` + 1000자 제한 | 본인이 발신자 + 메시지 길이 제한 |
| **update** | 부모 채팅방 참여자 | 읽음 상태 수정용 |
| **delete** | `existingData().senderId == uid` | 본인 메시지만 삭제 |

---

### dating_requests - 데이팅 신청

| 작업 | 조건 | 설명 |
|------|------|------|
| **read** | `isSignedIn()` | 로그인한 사용자 조회 가능 (fromPetId/toPetId 쿼리 허용) |
| **create** | `incomingData().fromUserId == uid` | 본인이 발신자인 경우만 |
| **update** | `existingData().toUserId == uid` | 받은 사람만 상태 변경 |
| **delete** | `existingData().fromUserId == uid` | 본인이 보낸 신청만 삭제 |

⚠️ **필드명**: `fromUserId`, `toUserId`, `fromPetId`, `toPetId` 사용

---

### breeding_requests - 교배 신청

| 작업 | 조건 | 설명 |
|------|------|------|
| **read** | `uid == senderId \|\| uid == receiverId` | 본인이 보냈거나 받은 신청만 |
| **create** | `incomingData().senderId == uid` | 본인이 발신자인 경우만 |
| **update** | `existingData().receiverId == uid` | 받은 사람만 상태 변경 |
| **delete** | `existingData().senderId == uid` | 본인이 보낸 신청만 삭제 |

⚠️ **필드명**: `senderId`, `receiverId` 사용 (dating_requests와 다름)

---

### matches - 매칭

| 작업 | 조건 | 설명 |
|------|------|------|
| **read** | `uid in userIds` | 매칭 참여자만 조회 |
| **create** | `uid in incomingData().userIds` | 매칭 참여자가 생성 |
| **update** | `uid in existingData().userIds` | 매칭 참여자만 수정 |
| **delete** | `uid in existingData().userIds` | 매칭 참여자만 삭제 |

---

### likes - 반려동물 좋아요

| 작업 | 조건 | 설명 |
|------|------|------|
| **read** | `isSignedIn()` | 로그인한 사용자 조회 가능 (좋아요 여부 확인용) |
| **create** | `incomingData().fromUserId == uid` | 본인이 좋아요 누른 경우만 |
| **update** | `existingData().toUserId == uid` | 받은 사람만 상태 변경 |
| **delete** | `existingData().fromUserId == uid` | 본인이 누른 좋아요만 삭제 |

📌 **문서 ID 형식**: `{userId}_{petId}`

---

### products - 상품

| 작업 | 조건 | 설명 |
|------|------|------|
| **read** | `isSignedIn()` | 로그인한 사용자는 모든 상품 조회 |
| **create** | `incomingData().sellerId == uid` | 본인이 판매자인 경우만 |
| **update** | `existingData().sellerId == uid` | 본인 상품만 수정 |
| **delete** | `existingData().sellerId == uid` | 본인 상품만 삭제 |

> 📝 **참고**: Firestore는 문서당 1MB 제한이 기본 적용되므로 별도 크기 검증이 불필요합니다.

---

### productLikes - 상품 찜

| 작업 | 조건 | 설명 |
|------|------|------|
| **read** | `resource.data.userId == uid` | 본인 찜만 조회 |
| **create** | `incomingData().userId == uid` | 본인 계정으로만 찜 |
| **delete** | `existingData().userId == uid` | 본인 찜만 삭제 |

---

### groups - 소모임

| 작업 | 조건 | 설명 |
|------|------|------|
| **read** | `isSignedIn()` | 로그인한 사용자 조회 가능 (creatorId 쿼리 허용) |
| **create** | `incomingData().creatorId == uid` | 본인이 생성자 |
| **update** | 생성자/관리자 또는 `memberIds`/`memberCount`만 변경 | 가입/탈퇴 허용 |
| **delete** | `existingData().creatorId == uid` | 생성자만 삭제 |

📌 **특수 규칙**: 일반 사용자도 `memberIds`와 `memberCount` 필드만 변경 가능 (가입/탈퇴)

```javascript
allow update: if isAdmin() || (isSignedIn() && (
  request.auth.uid == existingData().creatorId || 
  request.auth.uid in existingData().adminIds ||
  (request.resource.data.diff(resource.data).affectedKeys().hasOnly(['memberIds', 'memberCount']))
));
```

---

### groupJoinRequests - 소모임 가입 신청

| 작업 | 조건 | 설명 |
|------|------|------|
| **read** | `isSignedIn()` | 로그인한 사용자 조회 가능 |
| **create** | `incomingData().userId == uid` | 본인 계정으로만 신청 |
| **update** | `isSignedIn()` | 로그인한 사용자 (모임 관리자 체크는 앱에서) |
| **delete** | `existingData().userId == uid` | 본인 신청만 삭제 |

---

### groupLikes - 소모임 좋아요

| 작업 | 조건 | 설명 |
|------|------|------|
| **read** | `isSignedIn()` | 로그인한 사용자 조회 가능 |
| **create** | `incomingData().userId == uid` | 본인 계정으로만 좋아요 |
| **delete** | `existingData().userId == uid` | 본인 좋아요만 삭제 |

---

### schedules - 모임 일정

| 작업 | 조건 | 설명 |
|------|------|------|
| **read** | `isSignedIn()` | 로그인한 사용자 조회 가능 |
| **create** | `incomingData().creatorId == uid` | 본인이 생성자 |
| **update** | `uid == creatorId \|\| uid in participantIds` | 생성자 또는 참가자 |
| **delete** | `existingData().creatorId == uid` | 생성자만 삭제 |

---

### jobs - 알바

| 작업 | 조건 | 설명 |
|------|------|------|
| **read** | `isSignedIn()` | 로그인한 사용자 조회 가능 |
| **create** | `incomingData().userId == uid` | 본인이 작성자 |
| **update** | `existingData().userId == uid` | 본인 글만 수정 |
| **delete** | `existingData().userId == uid` | 본인 글만 삭제 |

---

### walks - 산책 기록

| 작업 | 조건 | 설명 |
|------|------|------|
| **read** | `resource.data.userId == uid` | 본인 기록만 조회 |
| **create** | `incomingData().userId == uid` | 본인 계정으로만 생성 |
| **update** | `existingData().userId == uid` | 본인 기록만 수정 |
| **delete** | `existingData().userId == uid` | 본인 기록만 삭제 |

---

### feedPosts - 커뮤니티 게시글

| 작업 | 조건 | 설명 |
|------|------|------|
| **read** | `isSignedIn()` | 로그인한 사용자 조회 가능 |
| **create** | `incomingData().authorId == uid` + 5000자 | 본인이 작성자 + 글 길이 제한 |
| **update** | `existingData().authorId == uid` | 본인 글만 수정 |
| **delete** | `existingData().authorId == uid` | 본인 글만 삭제 |

---

### feedComments - 커뮤니티 댓글

| 작업 | 조건 | 설명 |
|------|------|------|
| **read** | `isSignedIn()` | 로그인한 사용자 조회 가능 |
| **create** | `incomingData().authorId == uid` + 1000자 | 본인이 작성자 + 댓글 길이 제한 |
| **update** | `existingData().authorId == uid` | 본인 댓글만 수정 |
| **delete** | `existingData().authorId == uid` | 본인 댓글만 삭제 |

---

### feedLikes - 커뮤니티 좋아요

| 작업 | 조건 | 설명 |
|------|------|------|
| **read** | `isSignedIn()` | 로그인한 사용자 조회 가능 |
| **create** | `incomingData().userId == uid` | 본인 계정으로만 좋아요 |
| **delete** | `existingData().userId == uid` | 본인 좋아요만 삭제 |

---

### breedingPosts - 교배 게시글

| 작업 | 조건 | 설명 |
|------|------|------|
| **read** | `isSignedIn()` | 로그인한 사용자 조회 가능 |
| **create** | `incomingData().authorId == uid` | 본인이 작성자 |
| **update** | `existingData().authorId == uid` | 본인 글만 수정 |
| **delete** | `existingData().authorId == uid` | 본인 글만 삭제 |

---

### notifications - 알림

| 작업 | 조건 | 설명 |
|------|------|------|
| **read** | `resource.data.recipientId == uid` | 본인 알림만 조회 |
| **create** | `isSignedIn()` | 로그인한 사용자 생성 가능 |
| **update** | `existingData().recipientId == uid` | 본인 알림만 수정 (읽음 처리) |
| **delete** | `existingData().recipientId == uid` | 본인 알림만 삭제 |

---

### ratings - 꼬순내 평가

| 작업 | 조건 | 설명 |
|------|------|------|
| **read** | `isSignedIn()` | 로그인한 사용자 조회 가능 |
| **create** | `incomingData().raterId == uid` | 본인이 평가자 |
| **update** | `existingData().raterId == uid` | 본인 평가만 수정 |
| **delete** | `isAdmin()` | 관리자만 삭제 |

---

### blocks - 차단

| 작업 | 조건 | 설명 |
|------|------|------|
| **read** | `resource.data.blockerId == uid` | 본인 차단 목록만 조회 |
| **create** | `incomingData().blockerId == uid` | 본인 계정으로만 차단 |
| **delete** | `existingData().blockerId == uid` | 본인 차단만 해제 |

---

### reports - 신고

| 작업 | 조건 | 설명 |
|------|------|------|
| **read** | `isAdmin()` | 관리자만 조회 |
| **create** | `incomingData().reporterId == uid` | 본인 계정으로만 신고 |
| **update** | `isAdmin()` | 관리자만 처리 |
| **delete** | `isAdmin()` | 관리자만 삭제 |

---

### favorites - 통합 찜

| 작업 | 조건 | 설명 |
|------|------|------|
| **read** | `isSignedIn()` | 로그인한 사용자 조회 가능 (targetId + createdAt 쿼리 허용) |
| **create** | `incomingData().userId == uid` | 본인 계정으로만 찜 |
| **delete** | `existingData().userId == uid` | 본인 찜만 삭제 |

---

### nicknames - 닉네임 중복 체크

| 작업 | 조건 | 설명 |
|------|------|------|
| **read** | `isSignedIn()` | 로그인한 사용자 조회 가능 |
| **create** | `incomingData().userId == uid` | 본인 userId로만 생성 |
| **update** | `existingData().userId == uid` | 본인 userId인 경우만 수정 |
| **delete** | `existingData().userId == uid` | 본인 userId인 경우만 삭제 |

---

### config - 앱 설정

| 작업 | 조건 | 설명 |
|------|------|------|
| **read** | `isSignedIn()` | 로그인한 사용자 조회 가능 |
| **write** | `isAdmin()` | 관리자만 수정 |

---

### transactions - 거래 상태

| 작업 | 조건 | 설명 |
|------|------|------|
| **read** | `uid == sellerId \|\| uid == buyerId` | 거래 당사자만 조회 |
| **create** | `uid == sellerId \|\| uid == buyerId` | 거래 당사자만 생성 |
| **update** | `uid == sellerId \|\| uid == buyerId` | 거래 당사자만 수정 |
| **delete** | `isAdmin()` | 관리자만 삭제 |

---

### 건강수첩 컬렉션

`weightRecords`, `walkRecords`, `groomingRecords`, `vaccinationRecords`, `checkupRecords`, `medicationRecords`, `special_notes`

| 작업 | 조건 | 설명 |
|------|------|------|
| **read** | `isSignedIn()` | 로그인한 사용자 조회 가능 |
| **create** | `isSignedIn()` | 로그인한 사용자 생성 가능 |
| **update** | `isSignedIn()` | 로그인한 사용자 수정 가능 |
| **delete** | `isSignedIn()` | 로그인한 사용자 삭제 가능 |

📌 **참고**: 현재는 로그인만 확인하며, 향후 `petId`로 소유권 검증 추가 예정

---

## 🔒 보안 모범 사례

### 1. 최소 권한 원칙

```javascript
// ❌ 나쁜 예: 모든 사용자에게 전체 권한
allow read, write: if isSignedIn();

// ✅ 좋은 예: 필요한 권한만 부여
allow read: if isSignedIn();
allow create: if isSignedIn() && incomingData().ownerId == request.auth.uid;
allow update, delete: if existingData().ownerId == request.auth.uid;
```

### 2. 데이터 유효성 검증

```javascript
// 문서 크기 제한
allow create: if isValidDocSize(50);

// 텍스트 길이 제한
allow create: if isValidTextLength('content', 1000);
```

### 3. 필드 변경 제한

```javascript
// 특정 필드만 변경 허용
allow update: if request.resource.data.diff(resource.data)
  .affectedKeys().hasOnly(['memberIds', 'memberCount']);
```

---

## 🧪 테스트 방법

### Firebase Emulator 사용

```bash
# Emulator 시작
firebase emulators:start

# 규칙 테스트
firebase emulators:exec --only firestore "npm test"
```

### 규칙 테스트 예시

```javascript
const { assertSucceeds, assertFails } = require('@firebase/rules-unit-testing');

// 본인 프로필 수정 테스트
test('사용자는 본인 프로필만 수정 가능', async () => {
  const db = getFirestore({ uid: 'user1' });
  
  // 성공 케이스
  await assertSucceeds(
    db.collection('users').doc('user1').update({ nickname: 'new' })
  );
  
  // 실패 케이스
  await assertFails(
    db.collection('users').doc('user2').update({ nickname: 'new' })
  );
});
```

---

## 📝 변경 이력

| 날짜 | 버전 | 변경 내용 |
|------|------|----------|
| 2026-02-06 | 1.0.0 | 최초 작성 |
| 2026-02-09 | 1.1.0 | users 컬렉션 update 규칙에 평가 관련 필드 추가 (ratingCount, averageRating, noShowCount) |
| 2026-02-09 | 1.1.1 | users 컬렉션 update 규칙에 kkosunnaeScore 필드 추가 |

---

## ⚠️ 주의사항

### 규칙 배포

```bash
# 규칙만 배포
firebase deploy --only firestore:rules

# 규칙 + 인덱스 배포
firebase deploy --only firestore
```

### 디버깅

규칙 오류 시 Firebase Console > Firestore > Rules에서 시뮬레이터로 테스트 가능

### 성능

- `get()` 함수 호출은 읽기 비용 발생
- 복잡한 규칙은 성능에 영향
- 가능하면 문서 데이터만으로 검증
