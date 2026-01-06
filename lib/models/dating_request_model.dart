import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// ============================================================
/// 데이팅/교배 신청 모델
/// 데이트 신청 및 교배 신청의 수락/거절 관리
/// ============================================================

/// 신청 타입
enum DatingRequestType {
  date,     // 데이트 신청
  breeding, // 교배 신청
}

/// 신청 상태
enum DatingRequestStatus {
  pending,  // 대기 중
  accepted, // 수락됨
  rejected, // 거절됨
}

class DatingRequestModel extends Equatable {
  /// 신청 ID
  final String id;
  
  /// 신청자 ID
  final String senderId;
  
  /// 신청자 이름
  final String senderName;
  
  /// 신청자 반려동물 ID
  final String senderPetId;
  
  /// 신청자 반려동물 이름
  final String senderPetName;
  
  /// 신청자 반려동물 이미지
  final String? senderPetImageUrl;
  
  /// 수신자 ID
  final String receiverId;
  
  /// 수신자 반려동물 ID
  final String receiverPetId;
  
  /// 신청 타입 (데이트/교배)
  final DatingRequestType type;
  
  /// 신청 상태
  final DatingRequestStatus status;
  
  /// 신청 메시지 (선택)
  final String? message;
  
  /// 생성일
  final DateTime createdAt;
  
  /// 응답일
  final DateTime? respondedAt;

  const DatingRequestModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderPetId,
    required this.senderPetName,
    this.senderPetImageUrl,
    required this.receiverId,
    required this.receiverPetId,
    required this.type,
    this.status = DatingRequestStatus.pending,
    this.message,
    required this.createdAt,
    this.respondedAt,
  });

  /// Firestore에서 변환
  factory DatingRequestModel.fromFirestore(Map<String, dynamic> data, {String? id}) {
    return DatingRequestModel(
      id: id ?? data['id'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      senderPetId: data['senderPetId'] ?? '',
      senderPetName: data['senderPetName'] ?? '',
      senderPetImageUrl: data['senderPetImageUrl'],
      receiverId: data['receiverId'] ?? '',
      receiverPetId: data['receiverPetId'] ?? '',
      type: DatingRequestType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => DatingRequestType.date,
      ),
      status: DatingRequestStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => DatingRequestStatus.pending,
      ),
      message: data['message'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      respondedAt: data['respondedAt'] != null
          ? (data['respondedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Firestore로 변환
  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'senderPetId': senderPetId,
      'senderPetName': senderPetName,
      'senderPetImageUrl': senderPetImageUrl,
      'receiverId': receiverId,
      'receiverPetId': receiverPetId,
      'type': type.name,
      'status': status.name,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
      'respondedAt': respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
    };
  }

  /// 상태 변경된 복사본 생성
  DatingRequestModel copyWith({
    DatingRequestStatus? status,
    DateTime? respondedAt,
  }) {
    return DatingRequestModel(
      id: id,
      senderId: senderId,
      senderName: senderName,
      senderPetId: senderPetId,
      senderPetName: senderPetName,
      senderPetImageUrl: senderPetImageUrl,
      receiverId: receiverId,
      receiverPetId: receiverPetId,
      type: type,
      status: status ?? this.status,
      message: message,
      createdAt: createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
    );
  }

  /// 타입 라벨
  String get typeLabel => type == DatingRequestType.date ? '데이트 신청' : '교배 신청';
  
  /// 상태 라벨
  String get statusLabel {
    switch (status) {
      case DatingRequestStatus.pending:
        return '대기 중';
      case DatingRequestStatus.accepted:
        return '수락됨';
      case DatingRequestStatus.rejected:
        return '거절됨';
    }
  }

  @override
  List<Object?> get props => [
    id, senderId, senderName, senderPetId, senderPetName, senderPetImageUrl,
    receiverId, receiverPetId, type, status, message, createdAt, respondedAt,
  ];
}
