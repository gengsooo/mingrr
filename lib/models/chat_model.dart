import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// ============================================================
/// 채팅 관련 모델
/// 채팅방과 메시지 데이터 구조
/// ============================================================

/// 채팅방 모델
class ChatRoomModel extends Equatable {
  /// 채팅방 ID
  final String id;
  
  /// 참여자 사용자 ID 목록
  final List<String> participantIds;
  
  /// 참여자 정보 (닉네임, 프로필 이미지 등)
  final Map<String, ChatParticipant> participants;
  
  /// 마지막 메시지
  final String? lastMessage;
  
  /// 마지막 메시지 발신자 ID
  final String? lastMessageSenderId;
  
  /// 마지막 메시지 시간
  final DateTime? lastMessageAt;
  
  /// 읽지 않은 메시지 수 (사용자별)
  final Map<String, int> unreadCounts;
  
  /// 채팅방 타입 (dating, breeding, marketplace, community)
  final String type;
  
  /// 관련 ID (데이팅 매칭 ID, 상품 ID 등)
  final String? relatedId;
  
  /// 생성일
  final DateTime createdAt;
  
  /// 활성 상태
  final bool isActive;

  const ChatRoomModel({
    required this.id,
    required this.participantIds,
    required this.participants,
    this.lastMessage,
    this.lastMessageSenderId,
    this.lastMessageAt,
    this.unreadCounts = const {},
    required this.type,
    this.relatedId,
    required this.createdAt,
    this.isActive = true,
  });

  factory ChatRoomModel.fromFirestore(Map<String, dynamic> data, {String? id}) {
    // 참여자 정보 파싱
    final participantsData = data['participants'] as Map<String, dynamic>? ?? {};
    final participants = participantsData.map(
      (key, value) => MapEntry(
        key,
        ChatParticipant.fromMap(value as Map<String, dynamic>),
      ),
    );
    
    return ChatRoomModel(
      id: id ?? data['id'] ?? '',
      participantIds: List<String>.from(data['participantIds'] ?? []),
      participants: participants,
      lastMessage: data['lastMessage'],
      lastMessageSenderId: data['lastMessageSenderId'],
      lastMessageAt: data['lastMessageAt'] != null
          ? (data['lastMessageAt'] as Timestamp).toDate()
          : null,
      unreadCounts: Map<String, int>.from(data['unreadCounts'] ?? {}),
      type: data['type'] ?? 'dating',
      relatedId: data['relatedId'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'participantIds': participantIds,
      'participants': participants.map(
        (key, value) => MapEntry(key, value.toMap()),
      ),
      'lastMessage': lastMessage,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageAt': lastMessageAt != null
          ? Timestamp.fromDate(lastMessageAt!)
          : null,
      'unreadCounts': unreadCounts,
      'type': type,
      'relatedId': relatedId,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
    };
  }

  /// 상대방 정보 가져오기
  ChatParticipant? getOtherParticipant(String myUserId) {
    final otherUserId = participantIds.firstWhere(
      (id) => id != myUserId,
      orElse: () => '',
    );
    return participants[otherUserId];
  }

  @override
  List<Object?> get props => [
        id,
        participantIds,
        participants,
        lastMessage,
        lastMessageSenderId,
        lastMessageAt,
        unreadCounts,
        type,
        relatedId,
        createdAt,
        isActive,
      ];
}

/// 채팅 참여자 정보
class ChatParticipant extends Equatable {
  final String id;
  final String nickname;
  final String? profileImageUrl;
  final String? petName;
  final String? petImageUrl;

  const ChatParticipant({
    required this.id,
    required this.nickname,
    this.profileImageUrl,
    this.petName,
    this.petImageUrl,
  });

  factory ChatParticipant.fromMap(Map<String, dynamic> map) {
    return ChatParticipant(
      id: map['id'] ?? '',
      nickname: map['nickname'] ?? '',
      profileImageUrl: map['profileImageUrl'],
      petName: map['petName'],
      petImageUrl: map['petImageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nickname': nickname,
      'profileImageUrl': profileImageUrl,
      'petName': petName,
      'petImageUrl': petImageUrl,
    };
  }

  @override
  List<Object?> get props => [id, nickname, profileImageUrl, petName, petImageUrl];
}

/// 메시지 타입
enum MessageType {
  text,     // 텍스트
  image,    // 이미지
  location, // 위치
  system,   // 시스템 메시지
}

/// 메시지 모델
class MessageModel extends Equatable {
  /// 메시지 ID
  final String id;
  
  /// 채팅방 ID
  final String chatRoomId;
  
  /// 발신자 ID
  final String senderId;
  
  /// 메시지 타입
  final MessageType type;
  
  /// 메시지 내용
  final String content;
  
  /// 이미지 URL (이미지 메시지인 경우)
  final String? imageUrl;
  
  /// 위치 정보 (위치 메시지인 경우)
  final GeoPoint? location;
  
  /// 전송 시간
  final DateTime sentAt;
  
  /// 읽음 여부 (상대방 기준)
  final bool isRead;
  
  /// 읽은 시간
  final DateTime? readAt;

  const MessageModel({
    required this.id,
    required this.chatRoomId,
    required this.senderId,
    required this.type,
    required this.content,
    this.imageUrl,
    this.location,
    required this.sentAt,
    this.isRead = false,
    this.readAt,
  });

  factory MessageModel.fromFirestore(Map<String, dynamic> data, {String? id}) {
    return MessageModel(
      id: id ?? data['id'] ?? '',
      chatRoomId: data['chatRoomId'] ?? '',
      senderId: data['senderId'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => MessageType.text,
      ),
      content: data['content'] ?? '',
      imageUrl: data['imageUrl'],
      location: data['location'],
      sentAt: data['sentAt'] != null
          ? (data['sentAt'] as Timestamp).toDate()
          : DateTime.now(),
      isRead: data['isRead'] ?? false,
      readAt: data['readAt'] != null
          ? (data['readAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'chatRoomId': chatRoomId,
      'senderId': senderId,
      'type': type.name,
      'content': content,
      'imageUrl': imageUrl,
      'location': location,
      'sentAt': Timestamp.fromDate(sentAt),
      'isRead': isRead,
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
    };
  }

  @override
  List<Object?> get props => [
        id,
        chatRoomId,
        senderId,
        type,
        content,
        imageUrl,
        location,
        sentAt,
        isRead,
        readAt,
      ];
}
