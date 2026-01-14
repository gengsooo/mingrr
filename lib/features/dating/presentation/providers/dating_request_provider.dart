import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/chat_service.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../models/chat_model.dart';
import '../../../../models/dating_request_model.dart';

/// ============================================================
/// 데이팅/교배 신청 Provider
/// Firebase 연동 + 채팅방 자동 생성
/// ============================================================

final _chatService = ChatService();
final _firebaseService = FirebaseService();
final _notificationService = NotificationService();

/// 받은 신청 목록 (로컬 상태)
final receivedRequestsProvider = StateNotifierProvider<ReceivedRequestsNotifier, List<DatingRequestModel>>((ref) {
  return ReceivedRequestsNotifier();
});

/// 보낸 신청 목록 (로컬 상태)
final sentRequestsProvider = StateNotifierProvider<SentRequestsNotifier, List<DatingRequestModel>>((ref) {
  return SentRequestsNotifier();
});

/// 대기 중인 받은 신청 개수
final pendingRequestCountProvider = Provider<int>((ref) {
  final requests = ref.watch(receivedRequestsProvider);
  return requests.where((r) => r.status == DatingRequestStatus.pending).length;
});

/// 받은 신청 관리 Notifier
class ReceivedRequestsNotifier extends StateNotifier<List<DatingRequestModel>> {
  ReceivedRequestsNotifier() : super(_mockReceivedRequests);

  /// 신청 수락 + 채팅방 자동 생성
  Future<String?> acceptRequest(String requestId) async {
    DatingRequestModel? acceptedRequest;
    
    state = state.map((request) {
      if (request.id == requestId) {
        acceptedRequest = request.copyWith(
          status: DatingRequestStatus.accepted,
          respondedAt: DateTime.now(),
        );
        return acceptedRequest!;
      }
      return request;
    }).toList();

    // 채팅방 자동 생성
    if (acceptedRequest != null) {
      try {
        final myUserId = _firebaseService.currentUserId;
        if (myUserId == null) return null;

        // 내 정보 가져오기
        final myUserDoc = await _firebaseService.usersCollection.doc(myUserId).get();
        final myUserData = myUserDoc.data();

        // 상대방 정보
        final senderDoc = await _firebaseService.usersCollection.doc(acceptedRequest!.senderId).get();
        final senderData = senderDoc.data();

        final myInfo = ChatParticipant(
          id: myUserId,
          nickname: myUserData?['nickname'] ?? '사용자',
          profileImageUrl: myUserData?['profileImageUrl'],
          petName: acceptedRequest!.receiverPetId,
        );

        final senderInfo = ChatParticipant(
          id: acceptedRequest!.senderId,
          nickname: senderData?['nickname'] ?? acceptedRequest!.senderName,
          profileImageUrl: senderData?['profileImageUrl'],
          petName: acceptedRequest!.senderPetName,
          petImageUrl: acceptedRequest!.senderPetImageUrl,
        );

        // 채팅방 생성
        final chatType = acceptedRequest!.type == DatingRequestType.breeding ? 'breeding' : 'dating';
        final chatRoom = await _chatService.getOrCreateChatRoom(
          myUserId: myUserId,
          otherUserId: acceptedRequest!.senderId,
          type: chatType,
          myInfo: myInfo,
          otherInfo: senderInfo,
          relatedId: requestId,
        );

        // 시스템 메시지 전송
        final isBreeding = acceptedRequest!.type == DatingRequestType.breeding;
        await _chatService.sendSystemMessage(
          chatRoomId: chatRoom.id,
          content: '${isBreeding ? '교배' : '데이팅'} 신청이 수락되었습니다! 대화를 시작해보세요 💕',
        );

        // 상대방에게 알림 전송
        await _notificationService.sendDatingAcceptedNotification(
          recipientId: acceptedRequest!.senderId,
          accepterName: myUserData?['nickname'] ?? '사용자',
          accepterPetName: acceptedRequest!.receiverPetId,
          chatRoomId: chatRoom.id,
          isBreeding: isBreeding,
        );

        return chatRoom.id;
      } catch (e) {
        // 에러 발생해도 상태는 유지
        return null;
      }
    }
    return null;
  }

  /// 신청 거절
  void rejectRequest(String requestId) {
    state = state.map((request) {
      if (request.id == requestId) {
        return request.copyWith(
          status: DatingRequestStatus.rejected,
          respondedAt: DateTime.now(),
        );
      }
      return request;
    }).toList();
  }

  /// 신청 삭제 (목록에서 제거)
  void removeRequest(String requestId) {
    state = state.where((r) => r.id != requestId).toList();
  }

  /// 새 신청 추가 (테스트용)
  void addRequest(DatingRequestModel request) {
    state = [...state, request];
  }
}

/// 보낸 신청 관리 Notifier
class SentRequestsNotifier extends StateNotifier<List<DatingRequestModel>> {
  SentRequestsNotifier() : super(_mockSentRequests);

  /// 새 신청 보내기
  void sendRequest(DatingRequestModel request) {
    state = [...state, request];
  }

  /// 신청 취소
  void cancelRequest(String requestId) {
    state = state.where((r) => r.id != requestId).toList();
  }
}

/// 테스트용 더미 데이터 - 받은 신청
final _mockReceivedRequests = [
  DatingRequestModel(
    id: 'req_1',
    senderId: 'user_2',
    senderName: '김민수',
    senderPetId: 'pet_2',
    senderPetName: '초코',
    senderPetImageUrl: null,
    receiverId: 'current_user',
    receiverPetId: 'pet_1',
    type: DatingRequestType.date,
    status: DatingRequestStatus.pending,
    message: '우리 강아지들 산책 같이 해요!',
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
  ),
  DatingRequestModel(
    id: 'req_2',
    senderId: 'user_3',
    senderName: '이영희',
    senderPetId: 'pet_3',
    senderPetName: '뽀삐',
    senderPetImageUrl: null,
    receiverId: 'current_user',
    receiverPetId: 'pet_1',
    type: DatingRequestType.breeding,
    status: DatingRequestStatus.pending,
    message: '교배 문의드립니다.',
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
  DatingRequestModel(
    id: 'req_3',
    senderId: 'user_4',
    senderName: '박철수',
    senderPetId: 'pet_4',
    senderPetName: '몽이',
    senderPetImageUrl: null,
    receiverId: 'current_user',
    receiverPetId: 'pet_1',
    type: DatingRequestType.date,
    status: DatingRequestStatus.accepted,
    createdAt: DateTime.now().subtract(const Duration(days: 3)),
    respondedAt: DateTime.now().subtract(const Duration(days: 2)),
  ),
];

/// 테스트용 더미 데이터 - 보낸 신청
final _mockSentRequests = [
  DatingRequestModel(
    id: 'sent_1',
    senderId: 'current_user',
    senderName: '나',
    senderPetId: 'pet_1',
    senderPetName: '뭉치',
    receiverId: 'user_5',
    receiverPetId: 'pet_5',
    type: DatingRequestType.date,
    status: DatingRequestStatus.pending,
    createdAt: DateTime.now().subtract(const Duration(hours: 5)),
  ),
];
