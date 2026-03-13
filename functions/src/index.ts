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
// 5. 푸시 알림 전송 (notifications 컬렉션 트리거)
// ============================================================

/**
 * notifications 컬렉션에 문서가 생성되면 FCM 푸시 알림 전송
 * 
 * 트리거 흐름:
 * 앱에서 _saveNotification() → Firestore 'notifications' 문서 생성
 * → 이 Cloud Function 트리거
 * → 수신자 fcmToken 조회 + 알림 설정 확인
 * → FCM 메시지 발송
 */
export const onNotificationCreate = functions
  .region("asia-northeast3")
  .firestore.document("notifications/{notificationId}")
  .onCreate(async (snap, context) => {
    const notification = snap.data();
    const recipientId = notification.recipientId as string;
    const type = notification.type as string;
    const title = notification.title as string;
    const body = notification.body as string;
    const data = notification.data as Record<string, string> || {};

    console.log(`알림 전송 시작: type=${type}, recipientId=${recipientId}`);

    try {
      // 1. 수신자 정보 조회
      const userDoc = await db.collection("users").doc(recipientId).get();
      if (!userDoc.exists) {
        console.log(`수신자를 찾을 수 없음: ${recipientId}`);
        return null;
      }

      const userData = userDoc.data()!;
      const fcmToken = userData.fcmToken as string | undefined;

      if (!fcmToken) {
        console.log(`FCM 토큰 없음: ${recipientId}`);
        return null;
      }

      // 2. 알림 설정 확인
      const settings = userData.notificationSettings as Record<string, boolean> | undefined;
      if (settings) {
        // 전체 알림 OFF
        if (settings.allEnabled === false) {
          console.log(`전체 알림 OFF: ${recipientId}`);
          return null;
        }

        // 카테고리별 알림 설정 확인
        const categoryMap: Record<string, string> = {
          "chat": "chatEnabled",
          "marketInquiry": "chatEnabled",
          "datingRequest": "datingEnabled",
          "datingAccepted": "datingEnabled",
          "datingRejected": "datingEnabled",
          "breedingRequest": "datingEnabled",
          "breedingAccepted": "datingEnabled",
          "petLike": "datingEnabled",
          "marketSold": "marketEnabled",
          "productLike": "marketEnabled",
          "groupJoinRequest": "groupEnabled",
          "groupJoinApproved": "groupEnabled",
          "groupJoinRejected": "groupEnabled",
          "groupSchedule": "groupEnabled",
          "walkInvite": "communityEnabled",
          "walkReminder": "communityEnabled",
          "rating": "communityEnabled",
          "ratingReminder": "communityEnabled",
          "gradeChange": "communityEnabled",
          "scoreChange": "communityEnabled",
          "jobApplication": "marketEnabled",
          "jobAccepted": "marketEnabled",
        };

        const settingKey = categoryMap[type];
        if (settingKey && settings[settingKey] === false) {
          console.log(`카테고리 알림 OFF: ${type} → ${settingKey}`);
          return null;
        }

        // 야간 방해금지 확인
        if (settings.nightModeEnabled === true) {
          const now = new Date();
          const kstOffset = 9 * 60; // KST = UTC+9
          const kstMinutes = (now.getUTCHours() * 60 + now.getUTCMinutes() + kstOffset) % 1440;
          
          const startStr = (userData.notificationSettings?.nightModeStart as string) || "22:00";
          const endStr = (userData.notificationSettings?.nightModeEnd as string) || "08:00";
          const [startH, startM] = startStr.split(":").map(Number);
          const [endH, endM] = endStr.split(":").map(Number);
          const startMinutes = startH * 60 + startM;
          const endMinutes = endH * 60 + endM;

          let isNightMode = false;
          if (startMinutes > endMinutes) {
            // 예: 22:00 ~ 08:00 (자정 넘김)
            isNightMode = kstMinutes >= startMinutes || kstMinutes < endMinutes;
          } else {
            isNightMode = kstMinutes >= startMinutes && kstMinutes < endMinutes;
          }

          if (isNightMode) {
            console.log(`야간 방해금지 시간: ${recipientId}`);
            return null;
          }
        }
      }

      // 3. FCM 메시지 전송
      const message: admin.messaging.Message = {
        token: fcmToken,
        notification: {
          title: title,
          body: body,
        },
        data: {
          ...data,
          notificationId: context.params.notificationId,
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        android: {
          priority: "high",
          notification: {
            channelId: "mingrr_default",
            sound: "default",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
              contentAvailable: true,
            },
          },
        },
      };

      const response = await admin.messaging().send(message);
      console.log(`FCM 전송 성공: ${response}, recipientId=${recipientId}`);

      return null;
    } catch (error: unknown) {
      // 토큰이 만료되었거나 유효하지 않은 경우 토큰 삭제
      if (error instanceof Error && "code" in error) {
        const fcmError = error as { code: string };
        if (
          fcmError.code === "messaging/invalid-registration-token" ||
          fcmError.code === "messaging/registration-token-not-registered"
        ) {
          console.log(`만료된 FCM 토큰 삭제: ${recipientId}`);
          await db.collection("users").doc(recipientId).update({
            fcmToken: admin.firestore.FieldValue.delete(),
          });
          return null;
        }
      }
      console.error(`FCM 전송 실패: ${recipientId}`, error);
      return null;
    }
  });

// ============================================================
// 6. 카카오 소셜 로그인 - Custom Token 발급
// ============================================================

/**
 * 카카오 액세스 토큰을 받아 Firebase Custom Token을 발급
 * 
 * 플로우:
 * 1. Flutter에서 카카오 SDK로 로그인 → accessToken 획득
 * 2. 이 함수 호출 (accessToken 전달)
 * 3. 카카오 API로 사용자 정보 조회
 * 4. Firebase Custom Token 생성 후 반환
 */
export const createCustomTokenForKakao = functions
  .region("asia-northeast3")
  .https.onCall(async (data, context) => {
    const accessToken = data.accessToken as string;

    if (!accessToken) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "카카오 액세스 토큰이 필요합니다."
      );
    }

    try {
      // 카카오 API로 사용자 정보 조회
      const response = await fetch("https://kapi.kakao.com/v2/user/me", {
        method: "GET",
        headers: {
          "Authorization": `Bearer ${accessToken}`,
          "Content-Type": "application/x-www-form-urlencoded;charset=utf-8",
        },
      });

      if (!response.ok) {
        throw new functions.https.HttpsError(
          "unauthenticated",
          "카카오 인증에 실패했습니다."
        );
      }

      const kakaoUser = await response.json() as {
        id: number;
        kakao_account?: {
          profile?: { nickname?: string; profile_image_url?: string };
          email?: string;
        };
      };

      const kakaoId = kakaoUser.id.toString();
      const uid = `kakao:${kakaoId}`;
      const nickname = kakaoUser.kakao_account?.profile?.nickname || null;
      const profileImage = kakaoUser.kakao_account?.profile?.profile_image_url || null;
      const email = kakaoUser.kakao_account?.email || null;

      // Firebase Auth에 사용자가 없으면 생성
      try {
        await auth.getUser(uid);
      } catch {
        await auth.createUser({
          uid: uid,
          displayName: nickname || undefined,
          photoURL: profileImage || undefined,
          email: email || undefined,
        });
      }

      // Custom Token 생성
      const customToken = await auth.createCustomToken(uid);

      return {
        customToken: customToken,
        uid: uid,
        nickname: nickname,
        profileImage: profileImage,
        email: email,
      };
    } catch (error) {
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }
      console.error("카카오 Custom Token 생성 실패:", error);
      throw new functions.https.HttpsError(
        "internal",
        "카카오 로그인 처리 중 오류가 발생했습니다."
      );
    }
  });

// ============================================================
// 7. 네이버 소셜 로그인 - Custom Token 발급
// ============================================================

/**
 * 네이버 액세스 토큰을 받아 Firebase Custom Token을 발급
 */
export const createCustomTokenForNaver = functions
  .region("asia-northeast3")
  .https.onCall(async (data, context) => {
    const accessToken = data.accessToken as string;

    if (!accessToken) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "네이버 액세스 토큰이 필요합니다."
      );
    }

    try {
      // 네이버 API로 사용자 정보 조회
      const response = await fetch("https://openapi.naver.com/v1/nid/me", {
        method: "GET",
        headers: {
          "Authorization": `Bearer ${accessToken}`,
        },
      });

      if (!response.ok) {
        throw new functions.https.HttpsError(
          "unauthenticated",
          "네이버 인증에 실패했습니다."
        );
      }

      const result = await response.json() as {
        resultcode: string;
        message: string;
        response: {
          id: string;
          nickname?: string;
          profile_image?: string;
          email?: string;
          name?: string;
        };
      };

      if (result.resultcode !== "00") {
        throw new functions.https.HttpsError(
          "unauthenticated",
          "네이버 사용자 정보 조회에 실패했습니다."
        );
      }

      const naverUser = result.response;
      const uid = `naver:${naverUser.id}`;
      const nickname = naverUser.nickname || naverUser.name || null;
      const profileImage = naverUser.profile_image || null;
      const email = naverUser.email || null;

      // Firebase Auth에 사용자가 없으면 생성
      try {
        await auth.getUser(uid);
      } catch {
        await auth.createUser({
          uid: uid,
          displayName: nickname || undefined,
          photoURL: profileImage || undefined,
          email: email || undefined,
        });
      }

      // Custom Token 생성
      const customToken = await auth.createCustomToken(uid);

      return {
        customToken: customToken,
        uid: uid,
        nickname: nickname,
        profileImage: profileImage,
        email: email,
      };
    } catch (error) {
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }
      console.error("네이버 Custom Token 생성 실패:", error);
      throw new functions.https.HttpsError(
        "internal",
        "네이버 로그인 처리 중 오류가 발생했습니다."
      );
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
