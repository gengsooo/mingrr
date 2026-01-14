# MINGRR Cloud Functions

회원탈퇴 물리삭제 및 거래 기록 익명화 등 배치 작업을 처리하는 Cloud Functions입니다.

## 주요 기능

### 1. 회원탈퇴 30일 후 물리삭제 (`scheduledDeleteExpiredUsers`)
- **실행 주기**: 매일 자정 (KST)
- **동작**: 
  - `isDeleted: true`이고 `deletedAt`이 30일 이상 경과한 사용자 조회
  - 거래 기록 익명화 후 별도 컬렉션에 보관
  - 사용자 관련 모든 데이터 삭제 (반려동물, 채팅, 좋아요 등)
  - Firebase Auth 계정 삭제
  - Storage 파일 삭제

### 2. 만료된 거래 기록 삭제 (`scheduledDeleteExpiredTransactions`)
- **실행 주기**: 매월 1일 자정 (KST)
- **동작**: 5년이 경과한 익명화된 거래 기록 물리삭제

## 법적 근거

| 법률 | 요구사항 | 적용 |
|------|----------|------|
| 개인정보보호법 | 탈퇴 시 지체 없이 파기 | 30일 유예 후 물리삭제 |
| 전자상거래법 | 거래 기록 5년 보관 | 익명화 후 5년 보관 |

## 배포 방법

### 1. 사전 요구사항
- Node.js 18 이상
- Firebase CLI 설치 (`npm install -g firebase-tools`)
- Firebase 프로젝트 로그인 (`firebase login`)

### 2. 의존성 설치
```bash
cd functions
npm install
```

### 3. 빌드
```bash
npm run build
```

### 4. 배포
```bash
# functions 폴더에서
npm run deploy

# 또는 프로젝트 루트에서
firebase deploy --only functions
```

### 5. 로그 확인
```bash
firebase functions:log
```

## 로컬 테스트

```bash
# 에뮬레이터 실행
npm run serve

# 또는
firebase emulators:start --only functions
```

## 주의사항

1. **서울 리전 사용**: `asia-northeast3` 리전으로 배포됩니다.
2. **Blaze 요금제 필요**: 스케줄 함수는 Blaze 요금제에서만 사용 가능합니다.
3. **첫 배포 시**: Cloud Scheduler API 활성화가 필요할 수 있습니다.

## 데이터 흐름

```
사용자 탈퇴 요청 (앱)
    ↓
논리삭제 (isDeleted: true, deletedAt: now)
    ↓
30일 대기
    ↓
scheduledDeleteExpiredUsers 실행 (매일 자정)
    ↓
├── 거래 기록 익명화 → archived_transactions 컬렉션
├── 관련 데이터 삭제 (pets, chats, likes, etc.)
├── Storage 파일 삭제
├── Firebase Auth 계정 삭제
└── users 문서 삭제
    ↓
5년 후
    ↓
scheduledDeleteExpiredTransactions 실행 (매월 1일)
    ↓
archived_transactions 물리삭제
```

## 익명화된 거래 기록 구조

```javascript
{
  // 원본 거래 정보 (금액, 날짜 등)
  transactionAmount: 50000,
  transactionDate: "2025-01-10",
  productTitle: "강아지 간식",
  
  // 익명화된 사용자 정보
  sellerId: "DELETED_a1b2c3d4",
  sellerNickname: "탈퇴한 사용자",
  sellerProfileImageUrl: null,
  
  // 보관 메타데이터
  archivedAt: Timestamp,
  retentionUntil: "2030-01-10"  // 5년 후
}
```

## 문제 해결

### Cloud Scheduler API 오류
```bash
# Google Cloud Console에서 Cloud Scheduler API 활성화
# 또는
gcloud services enable cloudscheduler.googleapis.com
```

### 권한 오류
Firebase Admin SDK는 기본적으로 모든 권한을 가지지만, 
Storage 삭제 시 권한 오류가 발생하면 서비스 계정에 
`Storage Admin` 역할을 추가하세요.
