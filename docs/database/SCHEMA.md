# Firestore 스키마 정의

> **최종 수정일**: 2026-02-06  
> **버전**: 1.0.0  
> **작성자**: MINGRR 개발팀

---

## 📋 개요

이 문서는 MINGRR 앱의 Firestore 데이터베이스 스키마를 정의합니다.  
모든 컬렉션의 구조, 필드 타입, 권한 규칙을 명시하여 일관성 있는 개발을 지원합니다.

### 문서 규칙

- **필드 타입**: `string`, `number`, `boolean`, `timestamp`, `geopoint`, `array`, `map`
- **필수 여부**: ✅ 필수, ❌ 선택
- **문서 ID 형식**: 각 컬렉션별로 명시

### 관련 문서

- [SECURITY_RULES.md](./SECURITY_RULES.md) - 보안 규칙 상세
- [INDEXES.md](./INDEXES.md) - 복합 인덱스 정의

---

## 📚 컬렉션 목록

| 컬렉션 | 설명 | 모델 파일 | 주요 쿼리 |
|--------|------|----------|----------|
| [users](#users) | 사용자(보호자) 정보 | `user_model.dart` | userId |
| [pets](#pets) | 반려동물 정보 | `pet_model.dart` | ownerId |
| [chatRooms](#chatrooms) | 채팅방 | `chat_model.dart` | participantIds |
| [dating_requests](#dating_requests) | 데이팅 신청 | `dating_model.dart` | fromUserId, toUserId |
| [breeding_requests](#breeding_requests) | 교배 신청 | `dating_model.dart` | senderId, receiverId |
| [matches](#matches) | 매칭 성공 | `dating_model.dart` | userIds |
| [likes](#likes) | 반려동물 좋아요 | - | fromUserId, toUserId |
| [products](#products) | 마켓플레이스 상품 | `marketplace_model.dart` | sellerId, status |
| [productLikes](#productlikes) | 상품 찜 | - | userId |
| [groups](#groups) | 소모임 | `group_model.dart` | memberIds, isPublic |
| [groupJoinRequests](#groupjoinrequests) | 소모임 가입 신청 | - | groupId, userId |
| [groupLikes](#grouplikes) | 소모임 좋아요 | - | userId |
| [schedules](#schedules) | 모임 일정 | - | groupId |
| [jobs](#jobs) | 알바 (펫시터/산책) | `marketplace_model.dart` | userId, status |
| [job_applications](#job_applications) | 알바 지원 | `job_application_model.dart` | applicantId, employerId |
| [walks](#walks) | 산책 기록 | - | userId |
| [feedPosts](#feedposts) | 커뮤니티 게시글 | `community_post_model.dart` | authorId, category |
| [feedComments](#feedcomments) | 커뮤니티 댓글 | - | postId |
| [feedLikes](#feedlikes) | 커뮤니티 좋아요 | - | userId, postId |
| [breedingPosts](#breedingposts) | 교배 게시글 | `breeding_model.dart` | authorId |
| [notifications](#notifications) | 알림 | `notification_model.dart` | recipientId |
| [ratings](#ratings) | 꼬순내 평가 | `rating_model.dart` | raterId, targetId |
| [blocks](#blocks) | 차단 | - | blockerId |
| [reports](#reports) | 신고 | - | reporterId |
| [favorites](#favorites) | 통합 찜 | - | userId, targetType |
| [nicknames](#nicknames) | 닉네임 중복 체크 | - | 문서ID = 닉네임 |
| [config](#config) | 앱 설정 | - | - |
| [transactions](#transactions) | 거래 상태 | - | sellerId, buyerId |

### 건강수첩 컬렉션

| 컬렉션 | 설명 | 주요 쿼리 |
|--------|------|----------|
| [weightRecords](#healthrecords) | 체중 기록 | petId |
| [walkRecords](#healthrecords) | 산책 기록 | petId |
| [groomingRecords](#healthrecords) | 미용 기록 | petId |
| [vaccinationRecords](#healthrecords) | 예방접종 기록 | petId |
| [checkupRecords](#healthrecords) | 검진 기록 | petId |
| [medicationRecords](#healthrecords) | 투약 기록 | petId |
| [special_notes](#healthrecords) | 특이사항 | petId |

---

## 🔷 users

사용자(보호자) 정보를 저장합니다.

### 문서 ID
- **형식**: Firebase Auth UID
- **예시**: `abc123def456ghi789`

### 필드 정의

| 필드명 | 타입 | 필수 | 설명 | 예시 |
|--------|------|------|------|------|
| `nickname` | string | ✅ | 닉네임 (2-12자) | `"밍글러"` |
| `email` | string | ❌ | 이메일 | `"user@example.com"` |
| `phoneNumber` | string | ❌ | 전화번호 | `"010-1234-5678"` |
| `profileImageUrl` | string | ❌ | 프로필 이미지 URL | `"https://..."` |
| `gender` | string | ❌ | 성별 (`male`/`female`/`other`) | `"male"` |
| `birthDate` | timestamp | ❌ | 생년월일 | |
| `bio` | string | ❌ | 자기소개 | `"반려견과 함께..."` |
| `location` | geopoint | ❌ | 현재 위치 | |
| `address` | string | ❌ | 주소 (표시용) | `"서울시 강남구"` |
| `homeAddress` | string | ❌ | 집 주소 | |
| `homeLocation` | geopoint | ❌ | 집 위치 | |
| `homeHealthCategories` | array | ❌ | 메인화면 건강기록 카테고리 | `["weight", "walk"]` |
| `homeSafetyEnabled` | boolean | ❌ | 200m 안전구역 활성화 | `true` |
| `loginProvider` | string | ✅ | 로그인 제공자 | `"kakao"` |
| `isVerified` | boolean | ❌ | 동물등록 인증 여부 | `false` |
| `isIdentityVerified` | boolean | ❌ | 본인 인증 여부 | `false` |
| `isLocationVerified` | boolean | ❌ | 위치 인증 여부 | `false` |
| `locationVerifiedAt` | timestamp | ❌ | 위치 인증 시간 | |
| `lastLocationCheckAt` | timestamp | ❌ | 마지막 위치 체크 시간 | |
| `locationMismatchCount` | number | ❌ | 위치 불일치 횟수 | `0` |
| `locationReminderDismissedAt` | timestamp | ❌ | 위치 알림 무시 시간 | |
| `isWalking` | boolean | ❌ | 산책 중 상태 | `false` |
| `walkStartedAt` | timestamp | ❌ | 마지막 산책 시작 시간 | |
| `petIds` | array | ❌ | 보유 반려동물 ID 목록 | `["pet1", "pet2"]` |
| `fcmToken` | string | ❌ | FCM 토큰 | |
| `createdAt` | timestamp | ✅ | 계정 생성일 | |
| `lastActiveAt` | timestamp | ✅ | 마지막 활동 시간 | |
| `isPremium` | boolean | ❌ | 프리미엄 회원 여부 | `false` |
| `premiumExpiresAt` | timestamp | ❌ | 프리미엄 만료일 | |

### 코드 참조
```dart
// lib/models/user_model.dart
class UserModel extends Equatable {
  final String id;
  final String nickname;
  // ...
}
```

---

## 🔷 pets

반려동물 정보를 저장합니다.

### 문서 ID
- **형식**: UUID v4 또는 자동 생성
- **예시**: `pet_abc123`

### 필드 정의

| 필드명 | 타입 | 필수 | 설명 | 예시 |
|--------|------|------|------|------|
| `ownerId` | string | ✅ | 보호자 ID (users 문서 ID) | `"user123"` |
| `isPrimary` | boolean | ❌ | 대표 반려동물 여부 | `true` |
| `name` | string | ✅ | 반려동물 이름 | `"초코"` |
| `breed` | string | ❌ | 품종 | `"골든 리트리버"` |
| `gender` | string | ✅ | 성별 (`male`/`female`) | `"male"` |
| `birthDate` | timestamp | ❌ | 생년월일 | |
| `weight` | number | ❌ | 몸무게 (kg) | `15.5` |
| `isNeutered` | boolean | ❌ | 중성화 여부 | `true` |
| `traits` | array | ❌ | 특성 목록 | `["friendly", "active"]` |
| `bio` | string | ❌ | 자기소개/특징 | |
| `profileImageUrl` | string | ❌ | 프로필 이미지 URL | |
| `photoUrls` | array | ❌ | 추가 사진 URL 목록 | `["url1", "url2"]` |
| `registrationNumber` | string | ❌ | 동물등록번호 | |
| `isRegistrationVerified` | boolean | ❌ | 동물등록 인증 여부 | `false` |
| `isVaccinationVerified` | boolean | ❌ | 예방접종 인증 여부 | `false` |
| `hasPedigree` | boolean | ❌ | 혈통서 보유 여부 | `false` |
| `pedigreeImageUrl` | string | ❌ | 혈통서 이미지 URL | |
| `lastHealthCheckDate` | timestamp | ❌ | 마지막 건강검진일 | |
| `isBreedingAvailable` | boolean | ❌ | 교배 가능 여부 | `false` |
| `healthBookEnabled` | boolean | ❌ | 건강수첩 활성화 | `false` |
| `enabledHealthCategories` | array | ❌ | 활성화된 건강 카테고리 | |
| `walkFeatureEnabled` | boolean | ❌ | 산책 기능 활성화 | `true` |
| `likeCount` | number | ❌ | 좋아요 수 | `10` |
| `createdAt` | timestamp | ✅ | 생성일 | |
| `updatedAt` | timestamp | ✅ | 수정일 | |

### 코드 참조
```dart
// lib/models/pet_model.dart
class PetModel extends Equatable {
  final String id;
  final String ownerId;
  // ...
}
```

---

## 🔷 chatRooms

채팅방 정보를 저장합니다.

### 문서 ID
- **형식**: UUID v4 또는 자동 생성
- **예시**: `chatRoom_abc123`

### 필드 정의

| 필드명 | 타입 | 필수 | 설명 | 예시 |
|--------|------|------|------|------|
| `participantIds` | array | ✅ | 참여자 ID 목록 | `["user1", "user2"]` |
| `type` | string | ✅ | 채팅 타입 | `"dating"`, `"breeding"`, `"market"` |
| `lastMessage` | string | ❌ | 마지막 메시지 | `"안녕하세요"` |
| `lastMessageAt` | timestamp | ❌ | 마지막 메시지 시간 | |
| `lastMessageSenderId` | string | ❌ | 마지막 메시지 발신자 | |
| `unreadCounts` | map | ❌ | 사용자별 읽지 않은 메시지 수 | `{"user1": 0, "user2": 3}` |
| `participants` | array | ❌ | 참여자 상세 정보 | |
| `createdAt` | timestamp | ✅ | 생성일 | |
| `updatedAt` | timestamp | ❌ | 수정일 | |

### 서브컬렉션: messages

| 필드명 | 타입 | 필수 | 설명 |
|--------|------|------|------|
| `chatRoomId` | string | ✅ | 채팅방 ID |
| `senderId` | string | ✅ | 발신자 ID |
| `content` | string | ✅ | 메시지 내용 (최대 1000자) |
| `type` | string | ✅ | 메시지 타입 (`text`/`image`/`system`) |
| `imageUrl` | string | ❌ | 이미지 URL |
| `isRead` | boolean | ❌ | 읽음 여부 |
| `sentAt` | timestamp | ✅ | 발신 시간 |

---

## 🔷 dating_requests

데이팅 신청 정보를 저장합니다.

### 문서 ID
- **형식**: UUID v4 또는 자동 생성
- **예시**: `request_abc123`

### ⚠️ 필드명 규칙
- **이 컬렉션**: `fromUserId`, `toUserId`, `fromPetId`, `toPetId` 사용
- **breeding_requests**: `senderId`, `receiverId`, `senderPetId`, `receiverPetId` 사용

### 필드 정의

| 필드명 | 타입 | 필수 | 설명 | 예시 |
|--------|------|------|------|------|
| `fromUserId` | string | ✅ | 신청자 ID | `"user1"` |
| `fromPetId` | string | ✅ | 신청자 반려동물 ID | `"pet1"` |
| `toUserId` | string | ✅ | 수신자 ID | `"user2"` |
| `toPetId` | string | ✅ | 수신자 반려동물 ID | `"pet2"` |
| `status` | string | ✅ | 상태 | `"pending"`, `"accepted"`, `"rejected"`, `"cancelled"`, `"expired"` |
| `isSuperRequest` | boolean | ❌ | 슈퍼 신청 여부 | `false` |
| `message` | string | ❌ | 신청 메시지 | |
| `createdAt` | timestamp | ✅ | 생성일 | |
| `respondedAt` | timestamp | ❌ | 응답일 | |

### 코드 참조
```dart
// lib/models/dating_model.dart
class DatingRequestModel extends Equatable {
  final String fromUserId;
  final String toUserId;
  // ...
}
```

---

## 🔷 breeding_requests

교배 신청 정보를 저장합니다.

### 문서 ID
- **형식**: UUID v4 또는 자동 생성

### ⚠️ 필드명 규칙
- **이 컬렉션**: `senderId`, `receiverId`, `senderPetId`, `receiverPetId` 사용
- **dating_requests**: `fromUserId`, `toUserId`, `fromPetId`, `toPetId` 사용

### 필드 정의

| 필드명 | 타입 | 필수 | 설명 | 예시 |
|--------|------|------|------|------|
| `senderId` | string | ✅ | 신청자 ID | `"user1"` |
| `senderName` | string | ❌ | 신청자 이름 | `"홍길동"` |
| `senderPetId` | string | ✅ | 신청자 반려동물 ID | `"pet1"` |
| `senderPetName` | string | ❌ | 신청자 반려동물 이름 | `"초코"` |
| `senderPetImageUrl` | string | ❌ | 신청자 반려동물 이미지 | |
| `receiverId` | string | ✅ | 수신자 ID | `"user2"` |
| `receiverPetId` | string | ✅ | 수신자 반려동물 ID | `"pet2"` |
| `type` | string | ✅ | 타입 | `"breeding"` |
| `status` | string | ✅ | 상태 | `"pending"`, `"accepted"`, `"rejected"`, `"cancelled"`, `"expired"` |
| `message` | string | ❌ | 신청 메시지 | |
| `createdAt` | timestamp | ✅ | 생성일 | |
| `respondedAt` | timestamp | ❌ | 응답일 | |

---

## 🔷 matches

매칭 성공 정보를 저장합니다.

### 문서 ID
- **형식**: UUID v4 또는 자동 생성

### 필드 정의

| 필드명 | 타입 | 필수 | 설명 | 예시 |
|--------|------|------|------|------|
| `userIds` | array | ✅ | 사용자 ID 목록 | `["user1", "user2"]` |
| `petIds` | array | ✅ | 반려동물 ID 목록 | `["pet1", "pet2"]` |
| `chatRoomId` | string | ❌ | 채팅방 ID | |
| `type` | string | ✅ | 매칭 타입 | `"dating"`, `"breeding"` |
| `compatibilityScore` | number | ❌ | AI 궁합 점수 (0-100) | `85` |
| `compatibilityAnalysis` | string | ❌ | AI 궁합 분석 | |
| `matchedAt` | timestamp | ✅ | 매칭일 | |
| `isActive` | boolean | ✅ | 활성 상태 | `true` |

---

## 🔷 likes

반려동물 좋아요 정보를 저장합니다.

### 문서 ID
- **형식**: `{userId}_{petId}`
- **예시**: `user123_pet456`

### 필드 정의

| 필드명 | 타입 | 필수 | 설명 | 예시 |
|--------|------|------|------|------|
| `fromUserId` | string | ✅ | 좋아요 누른 사용자 ID | `"user1"` |
| `toUserId` | string | ✅ | 반려동물 주인 ID | `"user2"` |
| `petId` | string | ✅ | 반려동물 ID | `"pet1"` |
| `status` | string | ❌ | 상태 | `"pending"`, `"accepted"` |
| `createdAt` | timestamp | ✅ | 생성일 | |

---

## 🔷 products

마켓플레이스 상품 정보를 저장합니다.

### 문서 ID
- **형식**: UUID v4 또는 자동 생성

### 필드 정의

| 필드명 | 타입 | 필수 | 설명 | 예시 |
|--------|------|------|------|------|
| `sellerId` | string | ✅ | 판매자 ID | `"user1"` |
| `title` | string | ✅ | 상품명 | `"강아지 사료"` |
| `description` | string | ❌ | 상품 설명 | |
| `price` | number | ✅ | 가격 | `15000` |
| `type` | string | ✅ | 상품 타입 | `"sell"`, `"buy"`, `"share"` |
| `category` | string | ❌ | 카테고리 | `"food"`, `"toy"` |
| `status` | string | ✅ | 상태 | `"active"`, `"reserved"`, `"sold"` |
| `imageUrls` | array | ❌ | 이미지 URL 목록 | |
| `location` | geopoint | ❌ | 위치 | |
| `geohash` | string | ❌ | 위치 해시 | |
| `address` | string | ❌ | 주소 | |
| `viewCount` | number | ❌ | 조회수 | `100` |
| `likeCount` | number | ❌ | 찜 수 | `5` |
| `createdAt` | timestamp | ✅ | 생성일 | |
| `updatedAt` | timestamp | ❌ | 수정일 | |

---

## 🔷 productLikes

상품 찜 정보를 저장합니다.

### 문서 ID
- **형식**: `{userId}_{productId}`
- **예시**: `user123_product456`

### 필드 정의

| 필드명 | 타입 | 필수 | 설명 |
|--------|------|------|------|
| `userId` | string | ✅ | 사용자 ID |
| `productId` | string | ✅ | 상품 ID |
| `createdAt` | timestamp | ✅ | 생성일 |

---

## 🔷 groups

소모임 정보를 저장합니다.

### 문서 ID
- **형식**: UUID v4 또는 자동 생성

### 필드 정의

| 필드명 | 타입 | 필수 | 설명 | 예시 |
|--------|------|------|------|------|
| `creatorId` | string | ✅ | 생성자 ID | `"user1"` |
| `adminIds` | array | ❌ | 관리자 ID 목록 | `["user1", "user2"]` |
| `name` | string | ✅ | 모임 이름 | `"강남 댕댕이 모임"` |
| `description` | string | ❌ | 모임 설명 | |
| `category` | string | ❌ | 카테고리 | `"walk"`, `"play"` |
| `coverImageUrl` | string | ❌ | 커버 이미지 URL | |
| `isPublic` | boolean | ✅ | 공개 여부 | `true` |
| `memberIds` | array | ✅ | 멤버 ID 목록 | `["user1", "user2"]` |
| `memberCount` | number | ✅ | 멤버 수 | `10` |
| `maxMembers` | number | ❌ | 최대 멤버 수 | `50` |
| `location` | geopoint | ❌ | 위치 | |
| `geohash` | string | ❌ | 위치 해시 | |
| `address` | string | ❌ | 주소 | |
| `likeCount` | number | ❌ | 좋아요 수 | `20` |
| `createdAt` | timestamp | ✅ | 생성일 | |
| `updatedAt` | timestamp | ❌ | 수정일 | |

---

## 🔷 groupJoinRequests

소모임 가입 신청 정보를 저장합니다.

### 문서 ID
- **형식**: UUID v4 또는 자동 생성

### 필드 정의

| 필드명 | 타입 | 필수 | 설명 | 예시 |
|--------|------|------|------|------|
| `groupId` | string | ✅ | 모임 ID | `"group1"` |
| `userId` | string | ✅ | 신청자 ID | `"user1"` |
| `userName` | string | ❌ | 신청자 이름 | `"홍길동"` |
| `userProfileImageUrl` | string | ❌ | 신청자 프로필 이미지 | |
| `message` | string | ❌ | 가입 메시지 | |
| `status` | string | ✅ | 상태 | `"pending"`, `"approved"`, `"rejected"` |
| `createdAt` | timestamp | ✅ | 생성일 | |
| `respondedAt` | timestamp | ❌ | 응답일 | |

---

## 🔷 groupLikes

소모임 좋아요 정보를 저장합니다.

### 문서 ID
- **형식**: `{userId}_{groupId}`

### 필드 정의

| 필드명 | 타입 | 필수 | 설명 |
|--------|------|------|------|
| `userId` | string | ✅ | 사용자 ID |
| `groupId` | string | ✅ | 모임 ID |
| `createdAt` | timestamp | ✅ | 생성일 |

---

## 🔷 schedules

모임 일정 정보를 저장합니다.

### 문서 ID
- **형식**: UUID v4 또는 자동 생성

### 필드 정의

| 필드명 | 타입 | 필수 | 설명 |
|--------|------|------|------|
| `groupId` | string | ✅ | 모임 ID |
| `creatorId` | string | ✅ | 생성자 ID |
| `title` | string | ✅ | 일정 제목 |
| `description` | string | ❌ | 일정 설명 |
| `startTime` | timestamp | ✅ | 시작 시간 |
| `endTime` | timestamp | ❌ | 종료 시간 |
| `location` | string | ❌ | 장소 |
| `participantIds` | array | ❌ | 참가자 ID 목록 |
| `maxParticipants` | number | ❌ | 최대 참가자 수 |
| `createdAt` | timestamp | ✅ | 생성일 |

---

## 🔷 jobs

알바 (펫시터/산책) 정보를 저장합니다.

### 문서 ID
- **형식**: UUID v4 또는 자동 생성

### 필드 정의

| 필드명 | 타입 | 필수 | 설명 | 예시 |
|--------|------|------|------|------|
| `userId` | string | ✅ | 작성자 ID | `"user1"` |
| `title` | string | ✅ | 제목 | `"펫시터 구합니다"` |
| `description` | string | ❌ | 설명 | |
| `type` | string | ✅ | 타입 | `"petsitter"`, `"walker"` |
| `status` | string | ✅ | 상태 | `"active"`, `"closed"` |
| `pay` | number | ❌ | 급여 | `50000` |
| `payType` | string | ❌ | 급여 타입 | `"hourly"`, `"daily"` |
| `location` | geopoint | ❌ | 위치 | |
| `address` | string | ❌ | 주소 | |
| `startDate` | timestamp | ❌ | 시작일 | |
| `endDate` | timestamp | ❌ | 종료일 | |
| `createdAt` | timestamp | ✅ | 생성일 | |

---

## 🔷 job_applications

알바 지원 정보를 저장합니다. 데이팅 신청(dating_requests)과 동일한 패턴으로 설계되었습니다.

### 문서 ID
- **형식**: UUID v4 또는 자동 생성

### 필드 정의

| 필드명 | 타입 | 필수 | 설명 | 예시 |
|--------|------|------|------|------|
| `jobId` | string | ✅ | 알바 ID | `"job1"` |
| `jobTitle` | string | ✅ | 알바 제목 (비정규화) | `"펫시터 구합니다"` |
| `jobType` | string | ✅ | 알바 타입 (비정규화) | `"care"`, `"walk"` |
| `applicantId` | string | ✅ | 지원자 ID | `"user1"` |
| `applicantName` | string | ✅ | 지원자 닉네임 (비정규화) | `"홍길동"` |
| `applicantImageUrl` | string | ❌ | 지원자 프로필 이미지 | |
| `applicantKkosunnaeScore` | number | ❌ | 지원자 꼬순내 지수 | `75.5` |
| `employerId` | string | ✅ | 알바 등록자 ID | `"user2"` |
| `message` | string | ❌ | 한줄 메시지 | `"열심히 하겠습니다!"` |
| `status` | string | ✅ | 상태 | `"pending"`, `"accepted"`, `"rejected"`, `"cancelled"` |
| `createdAt` | timestamp | ✅ | 지원 시간 | |
| `respondedAt` | timestamp | ❌ | 응답 시간 | |
| `chatRoomId` | string | ❌ | 수락 시 생성된 채팅방 ID | |

### 상태 값
- `pending`: 대기 중
- `accepted`: 수락됨 (채팅 시작)
- `rejected`: 거절됨
- `cancelled`: 지원 취소

---

## 🔷 walks

산책 기록을 저장합니다.

### 문서 ID
- **형식**: UUID v4 또는 자동 생성

### 필드 정의

| 필드명 | 타입 | 필수 | 설명 |
|--------|------|------|------|
| `userId` | string | ✅ | 사용자 ID |
| `petIds` | array | ❌ | 함께한 반려동물 ID 목록 |
| `startTime` | timestamp | ✅ | 시작 시간 |
| `endTime` | timestamp | ❌ | 종료 시간 |
| `distance` | number | ❌ | 거리 (m) |
| `duration` | number | ❌ | 시간 (초) |
| `route` | array | ❌ | 경로 (GeoPoint 배열) |
| `createdAt` | timestamp | ✅ | 생성일 |

---

## 🔷 feedPosts

커뮤니티 게시글을 저장합니다.

### 문서 ID
- **형식**: UUID v4 또는 자동 생성

### 필드 정의

| 필드명 | 타입 | 필수 | 설명 | 예시 |
|--------|------|------|------|------|
| `authorId` | string | ✅ | 작성자 ID | `"user1"` |
| `authorName` | string | ❌ | 작성자 이름 | `"홍길동"` |
| `authorProfileImageUrl` | string | ❌ | 작성자 프로필 이미지 | |
| `content` | string | ✅ | 내용 (최대 5000자) | |
| `category` | string | ❌ | 카테고리 | `"daily"`, `"question"` |
| `imageUrls` | array | ❌ | 이미지 URL 목록 | |
| `likeCount` | number | ❌ | 좋아요 수 | `10` |
| `commentCount` | number | ❌ | 댓글 수 | `5` |
| `viewCount` | number | ❌ | 조회수 | `100` |
| `createdAt` | timestamp | ✅ | 생성일 | |
| `updatedAt` | timestamp | ❌ | 수정일 | |

---

## 🔷 feedComments

커뮤니티 댓글을 저장합니다.

### 문서 ID
- **형식**: UUID v4 또는 자동 생성

### 필드 정의

| 필드명 | 타입 | 필수 | 설명 |
|--------|------|------|------|
| `postId` | string | ✅ | 게시글 ID |
| `authorId` | string | ✅ | 작성자 ID |
| `authorName` | string | ❌ | 작성자 이름 |
| `authorProfileImageUrl` | string | ❌ | 작성자 프로필 이미지 |
| `content` | string | ✅ | 내용 (최대 1000자) |
| `parentId` | string | ❌ | 부모 댓글 ID (대댓글) |
| `createdAt` | timestamp | ✅ | 생성일 |

---

## 🔷 feedLikes

커뮤니티 좋아요를 저장합니다.

### 문서 ID
- **형식**: `{userId}_{postId}`

### 필드 정의

| 필드명 | 타입 | 필수 | 설명 |
|--------|------|------|------|
| `userId` | string | ✅ | 사용자 ID |
| `postId` | string | ✅ | 게시글 ID |
| `createdAt` | timestamp | ✅ | 생성일 |

---

## 🔷 breedingPosts

교배 게시글을 저장합니다.

### 문서 ID
- **형식**: UUID v4 또는 자동 생성

### 필드 정의

| 필드명 | 타입 | 필수 | 설명 |
|--------|------|------|------|
| `authorId` | string | ✅ | 작성자 ID |
| `petId` | string | ✅ | 반려동물 ID |
| `title` | string | ✅ | 제목 |
| `description` | string | ❌ | 설명 |
| `status` | string | ✅ | 상태 (`active`/`closed`) |
| `createdAt` | timestamp | ✅ | 생성일 |
| `updatedAt` | timestamp | ❌ | 수정일 |

---

## 🔷 notifications

알림을 저장합니다.

### 문서 ID
- **형식**: UUID v4 또는 자동 생성

### 필드 정의

| 필드명 | 타입 | 필수 | 설명 | 예시 |
|--------|------|------|------|------|
| `recipientId` | string | ✅ | 수신자 ID | `"user1"` |
| `type` | string | ✅ | 알림 타입 | `"dating_request"`, `"chat"` |
| `title` | string | ✅ | 제목 | `"새로운 데이팅 신청"` |
| `body` | string | ❌ | 내용 | |
| `data` | map | ❌ | 추가 데이터 | `{"requestId": "..."}` |
| `isRead` | boolean | ✅ | 읽음 여부 | `false` |
| `createdAt` | timestamp | ✅ | 생성일 | |

---

## 🔷 ratings

꼬순내 평가를 저장합니다.

### 문서 ID
- **형식**: UUID v4 또는 자동 생성

### 평가 정책
- **활동 기반 평가만 허용**: `relatedId` 필수 (채팅방 ID, 거래 ID 등)
- **동일 활동 1회 평가**: `raterId` + `relatedId` 조합으로 중복 방지
- **쿨다운 30일**: 동일 대상에게 동일 타입으로 30일 내 재평가 불가
- **평가 만료 14일**: 활동 완료 후 14일 이내에만 평가 가능
- **이상 탐지**: 1시간 내 최대 5개, 하루 최대 20개 평가 제한
- **평가 가중치**: 최근 30일 이내 평가에 1.2배 가중치 적용
- **상호 평가**: 양쪽 모두 평가 완료 시 공개 (`isVisible` 필드)

### 필드 정의

| 필드명 | 타입 | 필수 | 설명 |
|--------|------|------|------|
| `raterId` | string | ✅ | 평가자 ID |
| `targetId` | string | ✅ | 평가 대상 ID |
| `type` | string | ✅ | 평가 타입 (`dating`/`breeding`/`marketplace`) |
| `relatedId` | string | ✅ | 관련 활동 ID (채팅방 ID, 거래 ID 등) |
| `result` | string | ✅ | 활동 결과 (`completed`/`noShow`/`cancelled`/`failed`) |
| `score` | number | ✅ | 점수 (1-5) |
| `tags` | array | ❌ | 평가 태그 목록 |
| `comment` | string | ❌ | 코멘트 |
| `isVisible` | boolean | ✅ | 상호 평가 공개 여부 (양쪽 모두 평가 완료 시 true) |
| `createdAt` | timestamp | ✅ | 생성일 |
| `updatedAt` | timestamp | ❌ | 수정일 |

---

## 🔷 blocks

차단 정보를 저장합니다.

### 문서 ID
- **형식**: `{blockerId}_{blockedId}`

### 필드 정의

| 필드명 | 타입 | 필수 | 설명 |
|--------|------|------|------|
| `blockerId` | string | ✅ | 차단한 사용자 ID |
| `blockedId` | string | ✅ | 차단된 사용자 ID |
| `createdAt` | timestamp | ✅ | 생성일 |

---

## 🔷 reports

신고 정보를 저장합니다.

### 문서 ID
- **형식**: UUID v4 또는 자동 생성

### 필드 정의

| 필드명 | 타입 | 필수 | 설명 |
|--------|------|------|------|
| `reporterId` | string | ✅ | 신고자 ID |
| `targetId` | string | ✅ | 신고 대상 ID |
| `targetType` | string | ✅ | 대상 타입 (`user`/`post`/`product`) |
| `reason` | string | ✅ | 신고 사유 |
| `description` | string | ❌ | 상세 설명 |
| `status` | string | ✅ | 처리 상태 (`pending`/`resolved`) |
| `createdAt` | timestamp | ✅ | 생성일 |
| `resolvedAt` | timestamp | ❌ | 처리일 |

---

## 🔷 favorites

통합 찜 정보를 저장합니다.

### 문서 ID
- **형식**: `{userId}_{targetType}_{targetId}`

### 필드 정의

| 필드명 | 타입 | 필수 | 설명 |
|--------|------|------|------|
| `userId` | string | ✅ | 사용자 ID |
| `targetId` | string | ✅ | 대상 ID |
| `targetType` | string | ✅ | 대상 타입 (`pet`/`product`/`group`) |
| `createdAt` | timestamp | ✅ | 생성일 |

---

## 🔷 nicknames

닉네임 중복 체크용 인덱스입니다.

### 문서 ID
- **형식**: 정규화된 닉네임 (소문자)
- **예시**: `밍글러`

### 필드 정의

| 필드명 | 타입 | 필수 | 설명 |
|--------|------|------|------|
| `userId` | string | ✅ | 사용자 ID |
| `createdAt` | timestamp | ✅ | 생성일 |

---

## 🔷 config

앱 설정을 저장합니다.

### 문서 ID
- **형식**: 설정 키
- **예시**: `app_version`, `kkosunnae_config`

### 필드 정의

설정에 따라 다양한 필드 사용

---

## 🔷 transactions

거래 상태를 저장합니다.

### 문서 ID
- **형식**: UUID v4 또는 자동 생성

### 필드 정의

| 필드명 | 타입 | 필수 | 설명 |
|--------|------|------|------|
| `sellerId` | string | ✅ | 판매자 ID |
| `buyerId` | string | ✅ | 구매자 ID |
| `productId` | string | ✅ | 상품 ID |
| `status` | string | ✅ | 상태 (`pending`/`completed`) |
| `createdAt` | timestamp | ✅ | 생성일 |
| `completedAt` | timestamp | ❌ | 완료일 |

---

## 🔷 healthRecords

건강수첩 관련 컬렉션들입니다.

### 공통 필드

| 필드명 | 타입 | 필수 | 설명 |
|--------|------|------|------|
| `petId` | string | ✅ | 반려동물 ID |
| `userId` | string | ✅ | 사용자 ID |
| `createdAt` | timestamp | ✅ | 생성일 |

### 컬렉션별 추가 필드

#### weightRecords
| 필드명 | 타입 | 설명 |
|--------|------|------|
| `weight` | number | 체중 (kg) |
| `recordDate` | timestamp | 기록일 |

#### walkRecords
| 필드명 | 타입 | 설명 |
|--------|------|------|
| `distance` | number | 거리 (m) |
| `duration` | number | 시간 (분) |
| `startTime` | timestamp | 시작 시간 |

#### groomingRecords
| 필드명 | 타입 | 설명 |
|--------|------|------|
| `type` | string | 미용 종류 |
| `recordDate` | timestamp | 기록일 |
| `note` | string | 메모 |

#### vaccinationRecords
| 필드명 | 타입 | 설명 |
|--------|------|------|
| `vaccineName` | string | 백신 이름 |
| `vaccinationDate` | timestamp | 접종일 |
| `nextDate` | timestamp | 다음 접종일 |

#### checkupRecords
| 필드명 | 타입 | 설명 |
|--------|------|------|
| `hospitalName` | string | 병원 이름 |
| `checkupDate` | timestamp | 검진일 |
| `result` | string | 결과 |

#### medicationRecords
| 필드명 | 타입 | 설명 |
|--------|------|------|
| `medicineName` | string | 약 이름 |
| `startDate` | timestamp | 시작일 |
| `endDate` | timestamp | 종료일 |
| `dosage` | string | 용량 |

#### special_notes
| 필드명 | 타입 | 설명 |
|--------|------|------|
| `title` | string | 제목 |
| `content` | string | 내용 |
| `recordDate` | timestamp | 기록일 |

---

## 📝 변경 이력

| 날짜 | 버전 | 변경 내용 |
|------|------|----------|
| 2026-02-06 | 1.0.0 | 최초 작성 |

---

## ⚠️ 주의사항

### 필드명 일관성

1. **dating_requests vs breeding_requests**
   - `dating_requests`: `fromUserId`, `toUserId`, `fromPetId`, `toPetId`
   - `breeding_requests`: `senderId`, `receiverId`, `senderPetId`, `receiverPetId`
   - 향후 통일 예정

2. **작성자 필드**
   - `feedPosts`, `feedComments`, `breedingPosts`: `authorId`
   - `jobs`: `userId`
   - `products`: `sellerId`

3. **좋아요 컬렉션**
   - `likes`: 반려동물 좋아요 (데이팅)
   - `productLikes`: 상품 찜
   - `groupLikes`: 소모임 좋아요
   - `feedLikes`: 커뮤니티 좋아요
   - `favorites`: 통합 찜 (신규)

### 레거시 컬렉션

다음 컬렉션들은 레거시로 유지되며 향후 정리 예정:
- `joinRequests` → `groupJoinRequests`로 통합
- `posts`, `comments` → `feedPosts`, `feedComments`로 통합
- `kkosunnae_config` → `config`로 통합
- `transaction_statuses` → `transactions`로 통합
