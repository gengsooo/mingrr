import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/chat_service.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../models/chat_model.dart';
import '../../../../models/job_application_model.dart';
import '../../../../models/marketplace_model.dart';

/// ============================================================
/// 알바 지원 Provider
/// 
/// 데이팅 신청(dating_request_provider.dart)과 동일한 패턴
/// Firebase 실시간 연동 + 채팅방 자동 생성
/// ============================================================

final _firebase = FirebaseService();

/// 받은 알바 지원 목록 (알바 등록자용 - Firebase Stream)
final receivedJobApplicationsProvider = StreamProvider.autoDispose<List<JobApplicationModel>>((ref) {
  final userId = _firebase.currentUserId;
  if (userId == null) return Stream.value([]);
  
  return _firebase.jobApplicationsCollection
      .where('employerId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => JobApplicationModel.fromFirestore(doc.data(), id: doc.id))
          .toList());
});

/// 대기 중인 받은 지원 목록
final pendingJobApplicationsProvider = Provider.autoDispose<List<JobApplicationModel>>((ref) {
  final applications = ref.watch(receivedJobApplicationsProvider).valueOrNull ?? [];
  return applications.where((a) => a.status == JobApplicationStatus.pending).toList();
});

/// 대기 중인 받은 지원 개수
final pendingJobApplicationCountProvider = Provider.autoDispose<int>((ref) {
  return ref.watch(pendingJobApplicationsProvider).length;
});

/// 보낸 알바 지원 목록 (지원자용 - Firebase Stream)
final sentJobApplicationsProvider = StreamProvider.autoDispose<List<JobApplicationModel>>((ref) {
  final userId = _firebase.currentUserId;
  if (userId == null) return Stream.value([]);
  
  return _firebase.jobApplicationsCollection
      .where('applicantId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => JobApplicationModel.fromFirestore(doc.data(), id: doc.id))
          .toList());
});

/// 특정 알바에 대한 내 지원 상태
final myJobApplicationProvider = FutureProvider.autoDispose.family<JobApplicationModel?, String>((ref, jobId) async {
  final userId = _firebase.currentUserId;
  if (userId == null) return null;
  
  final snapshot = await _firebase.jobApplicationsCollection
      .where('jobId', isEqualTo: jobId)
      .where('applicantId', isEqualTo: userId)
      .limit(1)
      .get();
  
  if (snapshot.docs.isEmpty) return null;
  return JobApplicationModel.fromFirestore(snapshot.docs.first.data(), id: snapshot.docs.first.id);
});

/// ============================================================
/// 알바 지원 액션 서비스
/// 
/// DatingRequestActionService와 동일한 패턴
/// ============================================================
class JobApplicationActionService {
  static final _firebase = FirebaseService();
  static final _chatService = ChatService();
  static final _notificationService = NotificationService();

  /// 알바 지원하기
  /// [job]: 지원할 알바
  /// [message]: 한줄 메시지 (선택)
  /// 반환값: 생성된 지원 ID (실패 시 null)
  static Future<String?> applyForJob({
    required JobModel job,
    String? message,
  }) async {
    try {
      final myUserId = _firebase.currentUserId;
      if (myUserId == null) return null;

      // 내 정보 가져오기
      final myUserDoc = await _firebase.usersCollection.doc(myUserId).get();
      final myUserData = myUserDoc.data();
      if (myUserData == null) return null;

      // 이미 지원했는지 확인
      final existingApplication = await _firebase.jobApplicationsCollection
          .where('jobId', isEqualTo: job.id)
          .where('applicantId', isEqualTo: myUserId)
          .limit(1)
          .get();
      
      if (existingApplication.docs.isNotEmpty) {
        AppLogger.warning('JobApplicationAction', '이미 지원한 알바입니다');
        return null;
      }

      // 지원 생성
      final applicationData = JobApplicationModel(
        id: '',
        jobId: job.id,
        jobTitle: job.title,
        jobType: job.type,
        applicantId: myUserId,
        applicantName: myUserData['nickname'] ?? '사용자',
        applicantImageUrl: myUserData['profileImageUrl'],
        applicantKkosunnaeScore: (myUserData['kkosunnaeScore'] ?? 0.0).toDouble(),
        employerId: job.userId,
        message: message,
        status: JobApplicationStatus.pending,
        createdAt: DateTime.now(),
      );

      final docRef = await _firebase.jobApplicationsCollection.add(applicationData.toFirestore());

      // 알바 등록자에게 알림 전송
      await _notificationService.sendJobApplicationNotification(
        recipientId: job.userId,
        applicantName: myUserData['nickname'] ?? '사용자',
        jobTitle: job.title,
        applicationId: docRef.id,
      );

      return docRef.id;
    } catch (e) {
      AppLogger.error('JobApplicationAction', '알바 지원 오류', e);
      return null;
    }
  }

  /// 지원 수락 + 채팅방 자동 생성
  /// [application]: 수락할 지원 모델
  /// 반환값: 생성된 채팅방 ID (실패 시 null)
  static Future<String?> acceptApplication(JobApplicationModel application) async {
    try {
      final myUserId = _firebase.currentUserId;
      if (myUserId == null) return null;

      // 상태 업데이트
      await _firebase.jobApplicationsCollection.doc(application.id).update({
        'status': JobApplicationStatus.accepted.name,
        'respondedAt': Timestamp.fromDate(DateTime.now()),
      });

      // 내 정보 가져오기
      final myUserDoc = await _firebase.usersCollection.doc(myUserId).get();
      final myUserData = myUserDoc.data();

      // 지원자 정보
      final applicantDoc = await _firebase.usersCollection.doc(application.applicantId).get();
      final applicantData = applicantDoc.data();

      final myInfo = ChatParticipant(
        id: myUserId,
        nickname: myUserData?['nickname'] ?? '사용자',
        profileImageUrl: myUserData?['profileImageUrl'],
      );

      final applicantInfo = ChatParticipant(
        id: application.applicantId,
        nickname: applicantData?['nickname'] ?? application.applicantName,
        profileImageUrl: applicantData?['profileImageUrl'] ?? application.applicantImageUrl,
      );

      // 채팅방 생성
      final chatRoom = await _chatService.getOrCreateChatRoom(
        myUserId: myUserId,
        otherUserId: application.applicantId,
        type: 'job',
        myInfo: myInfo,
        otherInfo: applicantInfo,
        relatedId: application.jobId,
      );

      // 채팅방 ID 저장
      await _firebase.jobApplicationsCollection.doc(application.id).update({
        'chatRoomId': chatRoom.id,
      });

      // 시스템 메시지 전송
      await _chatService.sendSystemMessage(
        chatRoomId: chatRoom.id,
        content: '알바 지원이 수락되었습니다! 대화를 시작해보세요 💼',
      );

      // 지원자에게 알림 전송
      await _notificationService.sendJobAcceptedNotification(
        recipientId: application.applicantId,
        employerName: myUserData?['nickname'] ?? '사용자',
        jobTitle: application.jobTitle,
        chatRoomId: chatRoom.id,
      );

      return chatRoom.id;
    } catch (e) {
      AppLogger.error('JobApplicationAction', '지원 수락 오류', e);
      return null;
    }
  }

  /// 지원 거절
  /// [application]: 거절할 지원 모델
  static Future<void> rejectApplication(JobApplicationModel application) async {
    try {
      await _firebase.jobApplicationsCollection.doc(application.id).update({
        'status': JobApplicationStatus.rejected.name,
        'respondedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      AppLogger.error('JobApplicationAction', '지원 거절 오류', e);
    }
  }

  /// 지원 취소 (지원자가 본인 지원 취소)
  /// [application]: 취소할 지원 모델
  static Future<void> cancelApplication(JobApplicationModel application) async {
    try {
      await _firebase.jobApplicationsCollection.doc(application.id).delete();
    } catch (e) {
      AppLogger.error('JobApplicationAction', '지원 취소 오류', e);
    }
  }
}
