import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/chat_service.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../models/chat_model.dart';
import '../../../../models/dating_model.dart';

/// ============================================================
/// 데이팅/교배 신청 Provider
/// Firebase 실시간 연동 + 채팅방 자동 생성
/// ============================================================

final _chatService = ChatService();
final _firebaseService = FirebaseService();
final _notificationService = NotificationService();

/// 받은 데이팅 신청 목록 (Firebase Stream)
/// Firestore 필드: toUserId (dating_model.dart 기준)
final receivedDatingRequestsProvider = StreamProvider.autoDispose<List<DatingRequestModel>>((ref) {
  final userId = _firebaseService.currentUserId;
  if (userId == null) return Stream.value([]);
  
  return _firebaseService.datingRequestsCollection
      .where('toUserId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => DatingRequestModel.fromFirestore(doc.data(), id: doc.id))
          .toList());
});

/// 받은 교배 신청 목록 (Firebase Stream)
final receivedBreedingRequestsProvider = StreamProvider.autoDispose<List<DatingRequestModel>>((ref) {
  final userId = _firebaseService.currentUserId;
  if (userId == null) return Stream.value([]);
  
  return _firebaseService.firestore.collection('breeding_requests')
      .where('receiverId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => DatingRequestModel.fromFirestore(doc.data(), id: doc.id))
          .toList());
});

/// 받은 신청 목록 (데이팅 + 교배 통합)
final receivedRequestsProvider = Provider.autoDispose<List<DatingRequestModel>>((ref) {
  final datingRequests = ref.watch(receivedDatingRequestsProvider).valueOrNull ?? [];
  final breedingRequests = ref.watch(receivedBreedingRequestsProvider).valueOrNull ?? [];
  
  // 두 목록 합치고 날짜순 정렬
  final allRequests = [...datingRequests, ...breedingRequests];
  allRequests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  
  return allRequests;
});

/// 보낸 데이팅 신청 목록 (Firebase Stream)
/// Firestore 필드: fromUserId (dating_model.dart 기준)
final sentDatingRequestsProvider = StreamProvider.autoDispose<List<DatingRequestModel>>((ref) {
  final userId = _firebaseService.currentUserId;
  if (userId == null) return Stream.value([]);
  
  return _firebaseService.datingRequestsCollection
      .where('fromUserId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => DatingRequestModel.fromFirestore(doc.data(), id: doc.id))
          .toList());
});

/// 보낸 교배 신청 목록 (Firebase Stream)
final sentBreedingRequestsProvider = StreamProvider.autoDispose<List<DatingRequestModel>>((ref) {
  final userId = _firebaseService.currentUserId;
  if (userId == null) return Stream.value([]);
  
  return _firebaseService.firestore.collection('breeding_requests')
      .where('senderId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => DatingRequestModel.fromFirestore(doc.data(), id: doc.id))
          .toList());
});

/// 보낸 신청 목록 (데이팅 + 교배 통합)
final sentRequestsProvider = Provider.autoDispose<List<DatingRequestModel>>((ref) {
  final datingRequests = ref.watch(sentDatingRequestsProvider).valueOrNull ?? [];
  final breedingRequests = ref.watch(sentBreedingRequestsProvider).valueOrNull ?? [];
  
  final allRequests = [...datingRequests, ...breedingRequests];
  allRequests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  
  return allRequests;
});

/// 대기 중인 받은 신청 개수
final pendingRequestCountProvider = Provider.autoDispose<int>((ref) {
  final requests = ref.watch(receivedRequestsProvider);
  return requests.where((r) => r.status == DatingRequestStatus.pending).length;
});

/// ============================================================
/// 데이팅/교배 신청 액션 서비스
/// 
/// 신청 수락/거절 등의 액션을 처리하는 서비스
/// Firebase 실시간 연동으로 상태는 자동 갱신됨
/// ============================================================
class DatingRequestActionService {
  static final _firebase = FirebaseService();
  static final _chatService = ChatService();
  static final _notificationService = NotificationService();

  /// 신청 수락 + 채팅방 자동 생성
  /// [request]: 수락할 신청 모델
  /// 반환값: 생성된 채팅방 ID (실패 시 null)
  static Future<String?> acceptRequest(DatingRequestModel request) async {
    try {
      final myUserId = _firebase.currentUserId;
      if (myUserId == null) return null;

      // Firebase에서 신청 상태 업데이트
      final isBreeding = request.type == DatingRequestType.breeding;
      final collection = isBreeding 
          ? _firebase.firestore.collection('breeding_requests')
          : _firebase.datingRequestsCollection;
      
      await collection.doc(request.id).update({
        'status': DatingRequestStatus.accepted.name,
        'respondedAt': Timestamp.fromDate(DateTime.now()),
      });

      // 내 정보 가져오기
      final myUserDoc = await _firebase.usersCollection.doc(myUserId).get();
      final myUserData = myUserDoc.data();

      // 상대방 정보
      final senderDoc = await _firebase.usersCollection.doc(request.senderId).get();
      final senderData = senderDoc.data();

      final myInfo = ChatParticipant(
        id: myUserId,
        nickname: myUserData?['nickname'] ?? '사용자',
        profileImageUrl: myUserData?['profileImageUrl'],
        petName: request.receiverPetId,
      );

      final senderInfo = ChatParticipant(
        id: request.senderId,
        nickname: senderData?['nickname'] ?? request.senderName,
        profileImageUrl: senderData?['profileImageUrl'],
        petName: request.senderPetName,
        petImageUrl: request.senderPetImageUrl,
      );

      // 채팅방 생성
      final chatType = isBreeding ? 'breeding' : 'dating';
      final chatRoom = await _chatService.getOrCreateChatRoom(
        myUserId: myUserId,
        otherUserId: request.senderId,
        type: chatType,
        myInfo: myInfo,
        otherInfo: senderInfo,
        relatedId: request.id,
      );

      // 시스템 메시지 전송
      await _chatService.sendSystemMessage(
        chatRoomId: chatRoom.id,
        content: '${isBreeding ? '교배' : '데이팅'} 신청이 수락되었습니다! 대화를 시작해보세요 💕',
      );

      // 상대방에게 알림 전송
      await _notificationService.sendDatingAcceptedNotification(
        recipientId: request.senderId,
        accepterName: myUserData?['nickname'] ?? '사용자',
        accepterPetName: request.receiverPetId,
        chatRoomId: chatRoom.id,
        isBreeding: isBreeding,
      );

      return chatRoom.id;
    } catch (e) {
      return null;
    }
  }

  /// 신청 거절
  /// [request]: 거절할 신청 모델
  static Future<void> rejectRequest(DatingRequestModel request) async {
    final isBreeding = request.type == DatingRequestType.breeding;
    final collection = isBreeding 
        ? _firebase.firestore.collection('breeding_requests')
        : _firebase.datingRequestsCollection;
    
    await collection.doc(request.id).update({
      'status': DatingRequestStatus.rejected.name,
      'respondedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// 신청 삭제
  /// [request]: 삭제할 신청 모델
  static Future<void> deleteRequest(DatingRequestModel request) async {
    final isBreeding = request.type == DatingRequestType.breeding;
    final collection = isBreeding 
        ? _firebase.firestore.collection('breeding_requests')
        : _firebase.datingRequestsCollection;
    
    await collection.doc(request.id).delete();
  }
}
