# Firestore 데이터베이스 구조

## Collections 목록

### 1. users (사용자/보호자)
```
users/{userId}
├── id: string (Firebase Auth UID)
├── email: string?
├── phoneNumber: string?
├── nickname: string
├── profileImageUrl: string?
├── gender: string? (male, female)
├── birthDate: timestamp?
├── bio: string?
├── location: geopoint?
├── address: string?
├── homeAddress: string?
├── homeLocation: geopoint?
├── homeHealthCategories: array<string>
├── homeSafetyEnabled: boolean
├── loginProvider: string (phone, kakao, naver, google)
├── isVerified: boolean
├── isIdentityVerified: boolean
├── isLocationVerified: boolean
├── isWalking: boolean
├── walkStartedAt: timestamp?
├── petIds: array<string>
├── fcmToken: string?
├── createdAt: timestamp
├── lastActiveAt: timestamp
├── isPremium: boolean
├── kkosunnaeScore: number (0-100)
└── ratingCount: number
```

### 2. dogs (강아지)
```
dogs/{dogId}
├── id: string
├── ownerId: string (users 참조)
├── isPrimary: boolean
├── name: string
├── breed: string?
├── gender: string (male, female)
├── birthDate: timestamp?
├── weight: number?
├── isNeutered: boolean
├── traits: array<string>
├── bio: string?
├── profileImageUrl: string?
├── photoUrls: array<string>
├── registrationNumber: string?
├── isRegistrationVerified: boolean
├── isVaccinationVerified: boolean
├── hasPedigree: boolean
├── pedigreeImageUrl: string?
├── lastHealthCheckDate: timestamp?
├── isBreedingAvailable: boolean
├── healthBookEnabled: boolean
├── enabledHealthCategories: array<string>
├── walkFeatureEnabled: boolean
├── likeCount: number
├── createdAt: timestamp
└── updatedAt: timestamp
```

### 3. chatRooms (채팅방)
```
chatRooms/{chatRoomId}
├── id: string
├── participantIds: array<string>
├── participants: map<string, object>
│   └── {userId}: {
│       ├── id: string
│       ├── nickname: string
│       ├── profileImageUrl: string?
│       ├── petName: string?
│       └── petImageUrl: string?
│   }
├── lastMessage: string?
├── lastMessageSenderId: string?
├── lastMessageAt: timestamp?
├── unreadCounts: map<string, number>
├── type: string (dating, breeding, marketplace, community)
├── relatedId: string?
├── createdAt: timestamp
└── isActive: boolean
```

### 4. messages (메시지 - chatRooms 하위 컬렉션)
```
chatRooms/{chatRoomId}/messages/{messageId}
├── id: string
├── chatRoomId: string
├── senderId: string
├── type: string (text, image, location, system)
├── content: string
├── imageUrl: string?
├── location: geopoint?
├── sentAt: timestamp
├── isRead: boolean
└── readAt: timestamp?
```

### 5. likes (데이팅 좋아요)
```
likes/{likeId}
├── id: string
├── fromUserId: string
├── fromPetId: string
├── toUserId: string
├── toPetId: string
├── status: string (pending, accepted, rejected)
├── isSuperLike: boolean
├── message: string?
├── createdAt: timestamp
└── respondedAt: timestamp?
```

### 6. matches (매칭 성공)
```
matches/{matchId}
├── id: string
├── userIds: array<string>
├── petIds: array<string>
├── chatRoomId: string?
├── type: string (dating, breeding)
├── compatibilityScore: number?
├── compatibilityAnalysis: string?
├── matchedAt: timestamp
└── isActive: boolean
```

### 7. products (마켓플레이스 상품)
```
products/{productId}
├── id: string
├── sellerId: string
├── title: string
├── description: string
├── price: number
├── type: string (sell, share)
├── category: string (food, clothes, toys, supplies, furniture, health, other)
├── status: string (available, reserved, completed, hidden)
├── imageUrls: array<string>
├── location: geopoint?
├── address: string?
├── viewCount: number
├── likeCount: number
├── chatCount: number
├── targetPetType: string?
├── createdAt: timestamp
├── updatedAt: timestamp
└── bumpedAt: timestamp?
```

### 8. productLikes (상품 찜)
```
productLikes/{likeId}
├── id: string
├── userId: string
├── productId: string
└── createdAt: timestamp
```

### 9. groups (소모임)
```
groups/{groupId}
├── id: string
├── name: string
├── description: string
├── type: string (walking, training, social, health, craft, other)
├── imageUrl: string?
├── creatorId: string
├── adminIds: array<string>
├── memberIds: array<string>
├── maxMembers: number
├── location: geopoint?
├── address: string?
├── targetPetType: string?
├── isPublic: boolean
├── requireApproval: boolean
├── tags: array<string>
├── createdAt: timestamp
└── updatedAt: timestamp
```

### 10. schedules (모임 일정)
```
schedules/{scheduleId}
├── id: string
├── groupId: string
├── title: string
├── description: string?
├── startTime: timestamp
├── endTime: timestamp?
├── place: string?
├── location: geopoint?
├── participantIds: array<string>
├── maxParticipants: number
├── creatorId: string
└── createdAt: timestamp
```

### 11. joinRequests (모임 가입 신청)
```
joinRequests/{requestId}
├── id: string
├── groupId: string
├── userId: string
├── message: string?
├── status: string (pending, approved, rejected)
├── createdAt: timestamp
└── respondedAt: timestamp?
```

### 12. healthRecords (건강 기록 - dogs 하위 컬렉션)
```
dogs/{dogId}/healthRecords/{recordId}
├── id: string
├── dogId: string
├── category: string (weight, vaccination, deworming, walk, poop, play, bath, hospital, medication, heat, other)
├── date: timestamp
├── value: number?
├── unit: string?
├── notes: string?
├── imageUrls: array<string>
├── createdAt: timestamp
└── updatedAt: timestamp
```

## 인덱스 설정 (필요한 복합 인덱스)

Firebase Console에서 수동으로 생성하거나, 앱 실행 중 자동 생성 제안을 따라 생성:

1. **products**
   - `sellerId` (ASC) + `createdAt` (DESC)
   - `status` (ASC) + `createdAt` (DESC)
   - `category` (ASC) + `createdAt` (DESC)
   - `type` (ASC) + `createdAt` (DESC)

2. **chatRooms**
   - `participantIds` (ARRAY) + `lastMessageAt` (DESC)

3. **messages**
   - `chatRoomId` (ASC) + `sentAt` (DESC)

4. **likes**
   - `toUserId` (ASC) + `status` (ASC) + `createdAt` (DESC)
   - `fromUserId` (ASC) + `createdAt` (DESC)

5. **groups**
   - `isPublic` (ASC) + `createdAt` (DESC)
   - `type` (ASC) + `createdAt` (DESC)

6. **schedules**
   - `groupId` (ASC) + `startTime` (ASC)

7. **healthRecords**
   - `category` (ASC) + `date` (DESC)

## 데이터 검증 규칙

보안 규칙에 추가할 검증:

- 필수 필드 존재 여부
- 데이터 타입 검증
- 문자열 길이 제한
- 숫자 범위 제한
- 배열 크기 제한
