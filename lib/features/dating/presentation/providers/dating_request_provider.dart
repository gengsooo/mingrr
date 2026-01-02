import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/dating_request_model.dart';

/// ============================================================
/// 데이팅/교배 신청 Provider
/// 로컬 상태 관리 (Firebase 연동 전 임시)
/// ============================================================

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

  /// 신청 수락
  void acceptRequest(String requestId) {
    state = state.map((request) {
      if (request.id == requestId) {
        return request.copyWith(
          status: DatingRequestStatus.accepted,
          respondedAt: DateTime.now(),
        );
      }
      return request;
    }).toList();
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
