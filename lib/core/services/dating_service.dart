import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../models/dating_model.dart';
import '../../models/chat_model.dart';
import '../../models/notification_model.dart';
import 'firebase_service.dart';

/// ============================================================
/// 데이팅 서비스
/// 
/// 기능:
/// - 좋아요 보내기/수락/거절
/// - 매칭 생성
/// - 채팅방 생성
/// - 알림 전송
/// ============================================================
class DatingService {
  final FirebaseService _firebase = FirebaseService();
  final _uuid = const Uuid();
  
  FirebaseFirestore get _firestore => _firebase.firestore;
  
  // ===== 좋아요 관련 =====
  
  /// 좋아요 보내기 (데이팅 신청)
  Future<LikeModel> sendLike({
    required String fromUserId,
    required String fromPetId,
    required String toUserId,
    required String toPetId,
    String? message,
    bool isSuperLike = false,
  }) async {
    // 이미 좋아요를 보냈는지 확인
    final existingLike = await _checkExistingLike(fromPetId, toPetId);
    if (existingLike != null) {
      throw Exception('이미 좋아요를 보냈습니다');
    }
    
    final likeId = _uuid.v4();
    final like = LikeModel(
      id: likeId,
      fromUserId: fromUserId,
      fromPetId: fromPetId,
      toUserId: toUserId,
      toPetId: toPetId,
      status: LikeStatus.pending,
      isSuperLike: isSuperLike,
      message: message,
      createdAt: DateTime.now(),
    );
    
    await _firebase.likesCollection.doc(likeId).set(like.toFirestore());
    
    // 상대방에게 알림 전송
    await _sendNotification(
      userId: toUserId,
      type: NotificationType.likeReceived,
      title: '새로운 좋아요가 도착했어요! 💕',
      body: message ?? '누군가 관심을 보내왔어요',
      data: {
        'targetId': likeId,
        'targetType': 'like',
        'fromPetId': fromPetId,
      },
    );
    
    // 상대방도 좋아요를 보냈는지 확인 (상호 좋아요 = 매칭)
    final reverseLike = await _checkExistingLike(toPetId, fromPetId);
    if (reverseLike != null && reverseLike.status == LikeStatus.pending) {
      // 상호 좋아요! 자동 매칭
      await acceptLike(reverseLike.id);
    }
    
    return like;
  }
  
  /// 좋아요 수락
  Future<MatchModel?> acceptLike(String likeId) async {
    final likeDoc = await _firebase.likesCollection.doc(likeId).get();
    if (!likeDoc.exists) {
      throw Exception('좋아요를 찾을 수 없습니다');
    }
    
    final like = LikeModel.fromFirestore(likeDoc.data()!, id: likeDoc.id);
    
    // 좋아요 상태 업데이트
    await _firebase.likesCollection.doc(likeId).update({
      'status': LikeStatus.accepted.name,
      'respondedAt': Timestamp.fromDate(DateTime.now()),
    });
    
    // 매칭 생성
    final match = await _createMatch(
      userIds: [like.fromUserId, like.toUserId],
      petIds: [like.fromPetId, like.toPetId],
      type: 'dating',
    );
    
    // 상대방에게 알림 전송
    await _sendNotification(
      userId: like.fromUserId,
      type: NotificationType.matchSuccess,
      title: '매칭 성공! 🎉',
      body: '상대방이 좋아요를 수락했어요! 채팅을 시작해보세요',
      data: {
        'targetId': match.chatRoomId,
        'targetType': 'chat',
        'matchId': match.id,
      },
    );
    
    return match;
  }
  
  /// 좋아요 거절
  Future<void> rejectLike(String likeId) async {
    final likeDoc = await _firebase.likesCollection.doc(likeId).get();
    if (!likeDoc.exists) {
      throw Exception('좋아요를 찾을 수 없습니다');
    }
    
    await _firebase.likesCollection.doc(likeId).update({
      'status': LikeStatus.rejected.name,
      'respondedAt': Timestamp.fromDate(DateTime.now()),
    });
  }
  
  /// 기존 좋아요 확인
  Future<LikeModel?> _checkExistingLike(String fromPetId, String toPetId) async {
    final snapshot = await _firebase.likesCollection
        .where('fromPetId', isEqualTo: fromPetId)
        .where('toPetId', isEqualTo: toPetId)
        .limit(1)
        .get();
    
    if (snapshot.docs.isEmpty) return null;
    return LikeModel.fromFirestore(snapshot.docs.first.data(), id: snapshot.docs.first.id);
  }
  
  // ===== 교배 신청 관련 =====
  
  /// 교배 신청 보내기
  Future<LikeModel> sendBreedingRequest({
    required String fromUserId,
    required String fromPetId,
    required String toUserId,
    required String toPetId,
    String? message,
  }) async {
    final likeId = _uuid.v4();
    final like = LikeModel(
      id: likeId,
      fromUserId: fromUserId,
      fromPetId: fromPetId,
      toUserId: toUserId,
      toPetId: toPetId,
      status: LikeStatus.pending,
      isSuperLike: false,
      message: message,
      createdAt: DateTime.now(),
    );
    
    // breeding_requests 컬렉션에 저장
    await _firestore.collection('breeding_requests').doc(likeId).set({
      ...like.toFirestore(),
      'type': 'breeding',
    });
    
    // 상대방에게 알림 전송
    await _sendNotification(
      userId: toUserId,
      type: NotificationType.breedingRequest,
      title: '교배 신청이 도착했어요! 🐕',
      body: message ?? '교배 신청을 확인해보세요',
      data: {
        'targetId': likeId,
        'targetType': 'breeding_request',
        'fromPetId': fromPetId,
      },
    );
    
    return like;
  }
  
  /// 교배 신청 수락
  Future<MatchModel?> acceptBreedingRequest(String requestId) async {
    final requestDoc = await _firestore.collection('breeding_requests').doc(requestId).get();
    if (!requestDoc.exists) {
      throw Exception('교배 신청을 찾을 수 없습니다');
    }
    
    final data = requestDoc.data()!;
    
    // 신청 상태 업데이트
    await _firestore.collection('breeding_requests').doc(requestId).update({
      'status': LikeStatus.accepted.name,
      'respondedAt': Timestamp.fromDate(DateTime.now()),
    });
    
    // 매칭 생성
    final match = await _createMatch(
      userIds: [data['fromUserId'], data['toUserId']],
      petIds: [data['fromPetId'], data['toPetId']],
      type: 'breeding',
    );
    
    // 상대방에게 알림 전송
    await _sendNotification(
      userId: data['fromUserId'],
      type: NotificationType.breedingAccepted,
      title: '교배 신청이 수락되었어요! 🎉',
      body: '채팅을 통해 상세 일정을 조율해보세요',
      data: {
        'targetId': match.chatRoomId,
        'targetType': 'chat',
        'matchId': match.id,
      },
    );
    
    return match;
  }
  
  /// 교배 신청 거절
  Future<void> rejectBreedingRequest(String requestId) async {
    await _firestore.collection('breeding_requests').doc(requestId).update({
      'status': LikeStatus.rejected.name,
      'respondedAt': Timestamp.fromDate(DateTime.now()),
    });
  }
  
  // ===== 매칭 관련 =====
  
  /// 매칭 생성 및 채팅방 생성
  Future<MatchModel> _createMatch({
    required List<String> userIds,
    required List<String> petIds,
    required String type,
    int? compatibilityScore,
  }) async {
    // 채팅방 먼저 생성
    final chatRoomId = _uuid.v4();
    final chatRoom = ChatRoomModel(
      id: chatRoomId,
      participantIds: userIds,
      participants: {}, // 참여자 정보는 나중에 업데이트
      type: type,
      createdAt: DateTime.now(),
      lastMessageAt: DateTime.now(),
    );
    
    await _firebase.chatRoomsCollection.doc(chatRoomId).set(chatRoom.toFirestore());
    
    // 매칭 생성
    final matchId = _uuid.v4();
    final match = MatchModel(
      id: matchId,
      userIds: userIds,
      petIds: petIds,
      chatRoomId: chatRoomId,
      type: type,
      compatibilityScore: compatibilityScore,
      matchedAt: DateTime.now(),
    );
    
    await _firebase.matchesCollection.doc(matchId).set(match.toFirestore());
    
    return match;
  }
  
  // ===== 알림 관련 =====
  
  /// 알림 전송
  Future<void> _sendNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final notificationId = _uuid.v4();
    
    await _firestore.collection('notifications').doc(notificationId).set({
      'userId': userId,
      'type': type.name,
      'title': title,
      'body': body,
      'data': data,
      'isRead': false,
      'createdAt': Timestamp.fromDate(DateTime.now()),
    });
  }
  
  // ===== 펫 좋아요 수 업데이트 =====
  
  /// 펫 좋아요 수 증가
  Future<void> incrementPetLikeCount(String petId) async {
    await _firebase.petsCollection.doc(petId).update({
      'likeCount': FieldValue.increment(1),
    });
  }
  
  /// 펫 좋아요 수 감소
  Future<void> decrementPetLikeCount(String petId) async {
    await _firebase.petsCollection.doc(petId).update({
      'likeCount': FieldValue.increment(-1),
    });
  }
}
