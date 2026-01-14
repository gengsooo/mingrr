/**
 * MINGRR Cloud Functions
 * 
 * 주요 기능:
 * 1. 회원탈퇴 30일 후 물리삭제 (scheduledDeleteExpiredUsers)
 * 2. 거래 기록 익명화 보관
 * 
 * 배포 방법:
 * cd functions
 * npm install
 * npm run build
 * firebase deploy --only functions
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

const db = admin.firestore();
const auth = admin.auth();

// ============================================================
// 상수 정의
// ============================================================

/** 탈퇴 후 물리삭제까지 대기 일수 */
const DELETION_GRACE_PERIOD_DAYS = 30;

/** 거래 기록 보관 기간 (년) - 전자상거래법 */
const TRANSACTION_RETENTION_YEARS = 5;

// ============================================================
// 1. 회원탈퇴 30일 후 물리삭제 (매일 자정 실행)
// ============================================================

/**
 * 매일 자정(KST)에 실행되는 스케줄 함수
 * 30일이 경과한 탈퇴 사용자의 데이터를 물리삭제
 */
export const scheduledDeleteExpiredUsers = functions
  .region("asia-northeast3") // 서울 리전
  .pubsub.schedule("0 0 * * *") // 매일 자정
  .timeZone("Asia/Seoul")
  .onRun(async (context) => {
    console.log("=== 탈퇴 사용자 물리삭제 배치 시작 ===");
    
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - DELETION_GRACE_PERIOD_DAYS);
    
    try {
      // 30일이 경과한 탈퇴 사용자 조회
      const expiredUsersSnapshot = await db
        .collection("users")
        .where("isDeleted", "==", true)
        .where("deletedAt", "<=", cutoffDate)
        .get();
      
      console.log(`삭제 대상 사용자 수: ${expiredUsersSnapshot.size}`);
      
      const batch = db.batch();
      const deletePromises: Promise<void>[] = [];
      
      for (const userDoc of expiredUsersSnapshot.docs) {
        const userId = userDoc.id;
        const userData = userDoc.data();
        
        console.log(`사용자 삭제 처리 중: ${userId}`);
        
        // 1. 거래 기록 익명화 및 보관
        await anonymizeTransactionRecords(userId, userData);
        
        // 2. 관련 데이터 삭제
        deletePromises.push(deleteUserRelatedData(userId));
        
        // 3. 사용자 문서 삭제
        batch.delete(userDoc.ref);
        
        // 4. Firebase Auth 계정 삭제
        try {
          await auth.deleteUser(userId);
          console.log(`Firebase Auth 계정 삭제 완료: ${userId}`);
        } catch (authError) {
          console.error(`Firebase Auth 계정 삭제 실패: ${userId}`, authError);
          // Auth 삭제 실패해도 Firestore 삭제는 계속 진행
        }
      }
      
      // 배치 커밋
      await Promise.all(deletePromises);
      await batch.commit();
      
      console.log(`=== 탈퇴 사용자 물리삭제 완료: ${expiredUsersSnapshot.size}명 ===`);
      
      return null;
    } catch (error) {
      console.error("탈퇴 사용자 물리삭제 중 오류:", error);
      throw error;
    }
  });

// ============================================================
// 2. 거래 기록 익명화
// ============================================================

/**
 * 거래 기록을 익명화하여 별도 컬렉션에 보관
 * 전자상거래법에 따라 5년간 보관
 */
async function anonymizeTransactionRecords(
  userId: string,
  userData: FirebaseFirestore.DocumentData
): Promise<void> {
  try {
    // 사용자의 거래 기록 조회 (판매자로서)
    const sellerTransactions = await db
      .collection("transactions")
      .where("sellerId", "==", userId)
      .get();
    
    // 사용자의 거래 기록 조회 (구매자로서)
    const buyerTransactions = await db
      .collection("transactions")
      .where("buyerId", "==", userId)
      .get();
    
    const batch = db.batch();
    const anonymizedUserId = `DELETED_${hashUserId(userId)}`;
    
    // 판매자 거래 기록 익명화
    for (const doc of sellerTransactions.docs) {
      const archiveRef = db.collection("archived_transactions").doc(doc.id);
      batch.set(archiveRef, {
        ...doc.data(),
        sellerId: anonymizedUserId,
        sellerNickname: "탈퇴한 사용자",
        sellerProfileImageUrl: null,
        archivedAt: admin.firestore.FieldValue.serverTimestamp(),
        retentionUntil: getRetentionDate(),
      });
    }
    
    // 구매자 거래 기록 익명화
    for (const doc of buyerTransactions.docs) {
      const archiveRef = db.collection("archived_transactions").doc(doc.id);
      batch.set(archiveRef, {
        ...doc.data(),
        buyerId: anonymizedUserId,
        buyerNickname: "탈퇴한 사용자",
        buyerProfileImageUrl: null,
        archivedAt: admin.firestore.FieldValue.serverTimestamp(),
        retentionUntil: getRetentionDate(),
      }, { merge: true });
    }
    
    await batch.commit();
    
    console.log(`거래 기록 익명화 완료: ${userId} (판매: ${sellerTransactions.size}, 구매: ${buyerTransactions.size})`);
  } catch (error) {
    console.error(`거래 기록 익명화 실패: ${userId}`, error);
    // 익명화 실패해도 삭제는 계속 진행 (로그만 남김)
  }
}

// ============================================================
// 3. 사용자 관련 데이터 삭제
// ============================================================

/**
 * 사용자와 관련된 모든 데이터 삭제
 * - 반려동물 정보
 * - 채팅 메시지
 * - 좋아요/매칭 기록
 * - 게시글/댓글
 * - 알림
 */
async function deleteUserRelatedData(userId: string): Promise<void> {
  const collectionsToDelete = [
    { collection: "pets", field: "ownerId" },
    { collection: "chats", field: "participants", isArray: true },
    { collection: "likes", field: "fromUserId" },
    { collection: "likes", field: "toUserId" },
    { collection: "matches", field: "user1Id" },
    { collection: "matches", field: "user2Id" },
    { collection: "products", field: "sellerId" },
    { collection: "jobs", field: "userId" },
    { collection: "notifications", field: "userId" },
    { collection: "walk_records", field: "userId" },
    { collection: "health_records", field: "userId" },
  ];
  
  for (const { collection, field, isArray } of collectionsToDelete) {
    try {
      let query: FirebaseFirestore.Query;
      
      if (isArray) {
        query = db.collection(collection).where(field, "array-contains", userId);
      } else {
        query = db.collection(collection).where(field, "==", userId);
      }
      
      const snapshot = await query.get();
      
      if (snapshot.empty) continue;
      
      const batch = db.batch();
      snapshot.docs.forEach((doc) => batch.delete(doc.ref));
      await batch.commit();
      
      console.log(`${collection} 삭제 완료: ${snapshot.size}개`);
    } catch (error) {
      console.error(`${collection} 삭제 실패:`, error);
    }
  }
  
  // Storage 파일 삭제 (프로필 이미지, 반려동물 이미지 등)
  try {
    const bucket = admin.storage().bucket();
    await bucket.deleteFiles({
      prefix: `users/${userId}/`,
    });
    await bucket.deleteFiles({
      prefix: `pets/${userId}/`,
    });
    console.log(`Storage 파일 삭제 완료: ${userId}`);
  } catch (error) {
    console.error(`Storage 파일 삭제 실패: ${userId}`, error);
  }
}

// ============================================================
// 4. 보관 기간 만료 거래 기록 삭제 (매월 1일 실행)
// ============================================================

/**
 * 5년이 경과한 익명화된 거래 기록 삭제
 */
export const scheduledDeleteExpiredTransactions = functions
  .region("asia-northeast3")
  .pubsub.schedule("0 0 1 * *") // 매월 1일 자정
  .timeZone("Asia/Seoul")
  .onRun(async (context) => {
    console.log("=== 만료된 거래 기록 삭제 배치 시작 ===");
    
    const now = new Date();
    
    try {
      const expiredTransactions = await db
        .collection("archived_transactions")
        .where("retentionUntil", "<=", now)
        .get();
      
      console.log(`삭제 대상 거래 기록 수: ${expiredTransactions.size}`);
      
      const batch = db.batch();
      expiredTransactions.docs.forEach((doc) => batch.delete(doc.ref));
      await batch.commit();
      
      console.log(`=== 만료된 거래 기록 삭제 완료: ${expiredTransactions.size}개 ===`);
      
      return null;
    } catch (error) {
      console.error("만료된 거래 기록 삭제 중 오류:", error);
      throw error;
    }
  });

// ============================================================
// 유틸리티 함수
// ============================================================

/**
 * 사용자 ID 해시 (익명화용)
 */
function hashUserId(userId: string): string {
  let hash = 0;
  for (let i = 0; i < userId.length; i++) {
    const char = userId.charCodeAt(i);
    hash = ((hash << 5) - hash) + char;
    hash = hash & hash;
  }
  return Math.abs(hash).toString(16).substring(0, 8);
}

/**
 * 보관 기간 만료일 계산 (현재 + 5년)
 */
function getRetentionDate(): Date {
  const date = new Date();
  date.setFullYear(date.getFullYear() + TRANSACTION_RETENTION_YEARS);
  return date;
}
