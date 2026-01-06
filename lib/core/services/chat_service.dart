import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../models/chat_model.dart';
import '../../models/user_model.dart';
import '../../models/pet_model.dart';
import 'firebase_service.dart';

/// ============================================================
/// 채팅 서비스
/// 채팅방 생성, 메시지 전송, 읽음 처리 등 채팅 관련 기능
/// ============================================================
class ChatService {
  final FirebaseService _firebase = FirebaseService();
  final _uuid = const Uuid();

  // ===== 채팅방 관련 =====

  /// 채팅방 생성
  Future<ChatRoomModel> createChatRoom({
    required List<String> participantIds,
    required Map<String, ChatParticipant> participants,
    required String type,
    String? relatedId,
  }) async {
    final chatRoomId = _uuid.v4();
    final now = DateTime.now();

    final chatRoom = ChatRoomModel(
      id: chatRoomId,
      participantIds: participantIds,
      participants: participants,
      type: type,
      relatedId: relatedId,
      createdAt: now,
      isActive: true,
      unreadCounts: {for (var id in participantIds) id: 0},
    );

    await _firebase.chatRoomsCollection.doc(chatRoomId).set(chatRoom.toFirestore());
    return chatRoom;
  }

  /// 기존 채팅방 찾기 또는 생성 (1:1 채팅용)
  Future<ChatRoomModel> getOrCreateChatRoom({
    required String myUserId,
    required String otherUserId,
    required String type,
    required ChatParticipant myInfo,
    required ChatParticipant otherInfo,
    String? relatedId,
  }) async {
    // 기존 채팅방 찾기
    final existingRoom = await findExistingChatRoom(
      myUserId: myUserId,
      otherUserId: otherUserId,
      type: type,
      relatedId: relatedId,
    );

    if (existingRoom != null) {
      return existingRoom;
    }

    // 새 채팅방 생성
    return createChatRoom(
      participantIds: [myUserId, otherUserId],
      participants: {
        myUserId: myInfo,
        otherUserId: otherInfo,
      },
      type: type,
      relatedId: relatedId,
    );
  }

  /// 기존 채팅방 찾기
  Future<ChatRoomModel?> findExistingChatRoom({
    required String myUserId,
    required String otherUserId,
    required String type,
    String? relatedId,
  }) async {
    Query<Map<String, dynamic>> query = _firebase.chatRoomsCollection
        .where('participantIds', arrayContains: myUserId)
        .where('type', isEqualTo: type)
        .where('isActive', isEqualTo: true);

    if (relatedId != null) {
      query = query.where('relatedId', isEqualTo: relatedId);
    }

    final snapshot = await query.get();

    for (final doc in snapshot.docs) {
      final room = ChatRoomModel.fromFirestore(doc.data(), id: doc.id);
      if (room.participantIds.contains(otherUserId)) {
        return room;
      }
    }

    return null;
  }

  /// 채팅방 조회
  Future<ChatRoomModel?> getChatRoom(String chatRoomId) async {
    final doc = await _firebase.chatRoomsCollection.doc(chatRoomId).get();
    if (!doc.exists) return null;
    return ChatRoomModel.fromFirestore(doc.data()!, id: doc.id);
  }

  /// 사용자의 채팅방 목록 스트림
  Stream<List<ChatRoomModel>> watchUserChatRooms(String userId) {
    return _firebase.chatRoomsCollection
        .where('participantIds', arrayContains: userId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final rooms = snapshot.docs
              .map((doc) => ChatRoomModel.fromFirestore(doc.data(), id: doc.id))
              .toList();
          // 클라이언트에서 정렬 (인덱스 문제 방지)
          rooms.sort((a, b) {
            final aTime = a.lastMessageAt ?? a.createdAt;
            final bTime = b.lastMessageAt ?? b.createdAt;
            return bTime.compareTo(aTime);
          });
          return rooms;
        });
  }

  /// 채팅방 나가기 (비활성화)
  Future<void> leaveChatRoom(String chatRoomId, String userId) async {
    await _firebase.chatRoomsCollection.doc(chatRoomId).update({
      'isActive': false,
    });
  }

  /// 채팅방 참여자 정보 업데이트
  Future<void> updateParticipantInfo(
    String chatRoomId,
    String userId,
    ChatParticipant info,
  ) async {
    await _firebase.chatRoomsCollection.doc(chatRoomId).update({
      'participants.$userId': info.toMap(),
    });
  }

  // ===== 메시지 관련 =====

  /// 텍스트 메시지 전송
  Future<MessageModel> sendTextMessage({
    required String chatRoomId,
    required String senderId,
    required String content,
  }) async {
    return _sendMessage(
      chatRoomId: chatRoomId,
      senderId: senderId,
      type: MessageType.text,
      content: content,
    );
  }

  /// 이미지 메시지 전송
  Future<MessageModel> sendImageMessage({
    required String chatRoomId,
    required String senderId,
    required String imageUrl,
  }) async {
    return _sendMessage(
      chatRoomId: chatRoomId,
      senderId: senderId,
      type: MessageType.image,
      content: '사진',
      imageUrl: imageUrl,
    );
  }

  /// 위치 메시지 전송
  Future<MessageModel> sendLocationMessage({
    required String chatRoomId,
    required String senderId,
    required double latitude,
    required double longitude,
    String? address,
  }) async {
    return _sendMessage(
      chatRoomId: chatRoomId,
      senderId: senderId,
      type: MessageType.location,
      content: address ?? '위치 공유',
      location: GeoPoint(latitude, longitude),
    );
  }

  /// 시스템 메시지 전송
  Future<MessageModel> sendSystemMessage({
    required String chatRoomId,
    required String content,
  }) async {
    return _sendMessage(
      chatRoomId: chatRoomId,
      senderId: 'system',
      type: MessageType.system,
      content: content,
    );
  }

  /// 메시지 전송 (내부)
  Future<MessageModel> _sendMessage({
    required String chatRoomId,
    required String senderId,
    required MessageType type,
    required String content,
    String? imageUrl,
    GeoPoint? location,
  }) async {
    final messageId = _uuid.v4();
    final now = DateTime.now();

    final message = MessageModel(
      id: messageId,
      chatRoomId: chatRoomId,
      senderId: senderId,
      type: type,
      content: content,
      imageUrl: imageUrl,
      location: location,
      sentAt: now,
      isRead: false,
    );

    // 배치로 메시지 저장 + 채팅방 업데이트
    final batch = _firebase.firestore.batch();

    // 메시지 저장
    batch.set(
      _firebase.messagesCollection(chatRoomId).doc(messageId),
      message.toFirestore(),
    );

    // 채팅방 마지막 메시지 업데이트
    batch.update(
      _firebase.chatRoomsCollection.doc(chatRoomId),
      {
        'lastMessage': content,
        'lastMessageSenderId': senderId,
        'lastMessageAt': Timestamp.fromDate(now),
      },
    );

    // 상대방 읽지 않은 수 증가
    final chatRoom = await getChatRoom(chatRoomId);
    if (chatRoom != null) {
      for (final participantId in chatRoom.participantIds) {
        if (participantId != senderId) {
          batch.update(
            _firebase.chatRoomsCollection.doc(chatRoomId),
            {'unreadCounts.$participantId': FieldValue.increment(1)},
          );
        }
      }
    }

    await batch.commit();
    return message;
  }

  /// 메시지 목록 스트림
  Stream<List<MessageModel>> watchMessages(String chatRoomId, {int limit = 50}) {
    return _firebase.messagesCollection(chatRoomId)
        .orderBy('sentAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromFirestore(doc.data(), id: doc.id))
            .toList());
  }

  /// 이전 메시지 로드 (페이지네이션)
  Future<List<MessageModel>> loadMoreMessages(
    String chatRoomId, {
    required DateTime beforeTime,
    int limit = 20,
  }) async {
    final snapshot = await _firebase.messagesCollection(chatRoomId)
        .orderBy('sentAt', descending: true)
        .where('sentAt', isLessThan: Timestamp.fromDate(beforeTime))
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => MessageModel.fromFirestore(doc.data(), id: doc.id))
        .toList();
  }

  // ===== 읽음 처리 =====

  /// 채팅방 메시지 읽음 처리
  Future<void> markAsRead(String chatRoomId, String userId) async {
    // 읽지 않은 수 초기화
    await _firebase.chatRoomsCollection.doc(chatRoomId).update({
      'unreadCounts.$userId': 0,
    });

    // 상대방이 보낸 메시지들 읽음 처리
    final unreadMessages = await _firebase.messagesCollection(chatRoomId)
        .where('senderId', isNotEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    if (unreadMessages.docs.isEmpty) return;

    final batch = _firebase.firestore.batch();
    final now = Timestamp.fromDate(DateTime.now());

    for (final doc in unreadMessages.docs) {
      batch.update(doc.reference, {
        'isRead': true,
        'readAt': now,
      });
    }

    await batch.commit();
  }

  /// 총 읽지 않은 메시지 수
  Future<int> getTotalUnreadCount(String userId) async {
    final snapshot = await _firebase.chatRoomsCollection
        .where('participantIds', arrayContains: userId)
        .where('isActive', isEqualTo: true)
        .get();

    int total = 0;
    for (final doc in snapshot.docs) {
      final unreadCounts = doc.data()['unreadCounts'] as Map<String, dynamic>?;
      if (unreadCounts != null) {
        total += (unreadCounts[userId] as int?) ?? 0;
      }
    }
    return total;
  }

  // ===== 헬퍼 메서드 =====

  /// UserModel에서 ChatParticipant 생성
  ChatParticipant createParticipantFromUser(UserModel user, {PetModel? pet}) {
    return ChatParticipant(
      id: user.id,
      nickname: user.nickname,
      profileImageUrl: user.profileImageUrl,
      petName: pet?.name,
      petImageUrl: pet?.profileImageUrl,
    );
  }

  /// 채팅방 타입 라벨
  String getChatTypeLabel(String type) {
    switch (type) {
      case 'dating':
        return '데이팅';
      case 'breeding':
        return '교배';
      case 'market':
        return '마켓';
      case 'community':
        return '소모임';
      default:
        return '채팅';
    }
  }
}
