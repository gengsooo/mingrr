import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// ============================================================
/// 데이팅 관련 모델
/// 데이팅 신청, 매칭, AI 추천 등 데이팅 기능 데이터 구조
/// 
/// Firestore 컬렉션:
/// - dating_requests: fromUserId, toUserId, fromPetId, toPetId 사용
/// - breeding_requests: senderId, receiverId, senderPetId, receiverPetId 사용
/// ============================================================

/// 데이팅 신청 상태
enum DatingRequestStatus {
  pending,   // 대기 중
  accepted,  // 수락됨
  rejected,  // 거절됨
  cancelled, // 취소됨 (발신자가 취소)
  expired,   // 만료됨 (7일 후 자동 만료)
}

/// 신청 타입
enum DatingRequestType {
  date,     // 데이트 신청
  breeding, // 교배 신청
}

/// 데이팅/교배 신청 모델 (통합)
/// 
/// 필드명 규칙:
/// - 내부 모델: fromUserId, toUserId (통일)
/// - dating_requests 컬렉션: fromUserId, toUserId
/// - breeding_requests 컬렉션: senderId, receiverId (레거시 호환)
class DatingRequestModel extends Equatable {
  /// 신청 ID
  final String id;
  
  /// 보낸 사용자 ID (= senderId)
  final String fromUserId;
  
  /// 보낸 사용자 이름 (UI 표시용)
  final String? senderName;
  
  /// 보낸 반려동물 ID (= senderPetId)
  final String fromPetId;
  
  /// 보낸 반려동물 이름 (UI 표시용)
  final String? senderPetName;
  
  /// 보낸 반려동물 이미지 (UI 표시용)
  final String? senderPetImageUrl;
  
  /// 받은 사용자 ID (= receiverId)
  final String toUserId;
  
  /// 받은 반려동물 ID (= receiverPetId)
  final String toPetId;
  
  /// 신청 타입 (데이트/교배)
  final DatingRequestType type;
  
  /// 상태
  final DatingRequestStatus status;
  
  /// 슈퍼 신청 여부 (수익화 - 현재 숨김)
  final bool isSuperRequest;
  
  /// 메시지 (선택사항)
  final String? message;
  
  /// 생성일
  final DateTime createdAt;
  
  /// 응답일
  final DateTime? respondedAt;

  const DatingRequestModel({
    required this.id,
    required this.fromUserId,
    this.senderName,
    required this.fromPetId,
    this.senderPetName,
    this.senderPetImageUrl,
    required this.toUserId,
    required this.toPetId,
    this.type = DatingRequestType.date,
    this.status = DatingRequestStatus.pending,
    this.isSuperRequest = false,
    this.message,
    required this.createdAt,
    this.respondedAt,
  });

  /// Firestore에서 변환
  /// dating_requests: fromUserId/toUserId 필드 사용
  /// breeding_requests: senderId/receiverId 필드 사용 (레거시 호환)
  factory DatingRequestModel.fromFirestore(Map<String, dynamic> data, {String? id}) {
    return DatingRequestModel(
      id: id ?? data['id'] ?? '',
      // dating_requests: fromUserId, breeding_requests: senderId
      fromUserId: data['fromUserId'] ?? data['senderId'] ?? '',
      senderName: data['senderName'],
      // dating_requests: fromPetId, breeding_requests: senderPetId
      fromPetId: data['fromPetId'] ?? data['senderPetId'] ?? '',
      senderPetName: data['senderPetName'],
      senderPetImageUrl: data['senderPetImageUrl'],
      // dating_requests: toUserId, breeding_requests: receiverId
      toUserId: data['toUserId'] ?? data['receiverId'] ?? '',
      // dating_requests: toPetId, breeding_requests: receiverPetId
      toPetId: data['toPetId'] ?? data['receiverPetId'] ?? '',
      type: DatingRequestType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => DatingRequestType.date,
      ),
      status: DatingRequestStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => DatingRequestStatus.pending,
      ),
      isSuperRequest: data['isSuperRequest'] ?? data['isSuperLike'] ?? false,
      message: data['message'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      respondedAt: data['respondedAt'] != null
          ? (data['respondedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Firestore로 변환 (dating_requests 컬렉션용)
  Map<String, dynamic> toFirestore() {
    return {
      'fromUserId': fromUserId,
      'senderName': senderName,
      'fromPetId': fromPetId,
      'senderPetName': senderPetName,
      'senderPetImageUrl': senderPetImageUrl,
      'toUserId': toUserId,
      'toPetId': toPetId,
      'type': type.name,
      'status': status.name,
      'isSuperRequest': isSuperRequest,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
      'respondedAt': respondedAt != null
          ? Timestamp.fromDate(respondedAt!)
          : null,
    };
  }

  /// 상태 변경된 복사본 생성
  DatingRequestModel copyWith({
    DatingRequestStatus? status,
    DateTime? respondedAt,
  }) {
    return DatingRequestModel(
      id: id,
      fromUserId: fromUserId,
      senderName: senderName,
      fromPetId: fromPetId,
      senderPetName: senderPetName,
      senderPetImageUrl: senderPetImageUrl,
      toUserId: toUserId,
      toPetId: toPetId,
      type: type,
      status: status ?? this.status,
      isSuperRequest: isSuperRequest,
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
      case DatingRequestStatus.cancelled:
        return '취소됨';
      case DatingRequestStatus.expired:
        return '만료됨';
    }
  }
  
  /// 만료 여부 확인 (7일 경과)
  bool get isExpired {
    if (status != DatingRequestStatus.pending) return false;
    return DateTime.now().difference(createdAt).inDays >= 7;
  }

  /// 레거시 호환: senderId getter
  String get senderId => fromUserId;
  
  /// 레거시 호환: receiverId getter
  String get receiverId => toUserId;
  
  /// 레거시 호환: senderPetId getter
  String get senderPetId => fromPetId;
  
  /// 레거시 호환: receiverPetId getter
  String get receiverPetId => toPetId;

  @override
  List<Object?> get props => [
        id,
        fromUserId,
        senderName,
        fromPetId,
        senderPetName,
        senderPetImageUrl,
        toUserId,
        toPetId,
        type,
        status,
        isSuperRequest,
        message,
        createdAt,
        respondedAt,
      ];
}

/// 매칭 모델 (서로 좋아요 성공)
class MatchModel extends Equatable {
  /// 매칭 ID
  final String id;
  
  /// 사용자 ID 목록
  final List<String> userIds;
  
  /// 반려동물 ID 목록
  final List<String> petIds;
  
  /// 채팅방 ID
  final String? chatRoomId;
  
  /// 매칭 타입 (dating: 데이팅, breeding: 교배)
  final String type;
  
  /// AI 궁합 점수 (0-100)
  final int? compatibilityScore;
  
  /// AI 궁합 분석 내용
  final String? compatibilityAnalysis;
  
  /// 매칭일
  final DateTime matchedAt;
  
  /// 활성 상태
  final bool isActive;

  const MatchModel({
    required this.id,
    required this.userIds,
    required this.petIds,
    this.chatRoomId,
    this.type = 'dating',
    this.compatibilityScore,
    this.compatibilityAnalysis,
    required this.matchedAt,
    this.isActive = true,
  });

  factory MatchModel.fromFirestore(Map<String, dynamic> data, {String? id}) {
    return MatchModel(
      id: id ?? data['id'] ?? '',
      userIds: List<String>.from(data['userIds'] ?? []),
      petIds: List<String>.from(data['petIds'] ?? []),
      chatRoomId: data['chatRoomId'],
      type: data['type'] ?? 'dating',
      compatibilityScore: data['compatibilityScore'],
      compatibilityAnalysis: data['compatibilityAnalysis'],
      matchedAt: data['matchedAt'] != null
          ? (data['matchedAt'] as Timestamp).toDate()
          : DateTime.now(),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userIds': userIds,
      'petIds': petIds,
      'chatRoomId': chatRoomId,
      'type': type,
      'compatibilityScore': compatibilityScore,
      'compatibilityAnalysis': compatibilityAnalysis,
      'matchedAt': Timestamp.fromDate(matchedAt),
      'isActive': isActive,
    };
  }

  @override
  List<Object?> get props => [
        id,
        userIds,
        petIds,
        chatRoomId,
        type,
        compatibilityScore,
        compatibilityAnalysis,
        matchedAt,
        isActive,
      ];
}

/// AI 추천 결과 모델
class RecommendationModel extends Equatable {
  /// 추천 대상 반려동물 ID
  final String petId;
  
  /// 추천 대상 사용자 ID
  final String userId;
  
  /// 궁합 점수 (0-100)
  final int compatibilityScore;
  
  /// 추천 이유
  final String reason;
  
  /// 거리 (km)
  final double? distance;
  
  /// 공통점 목록
  final List<String> commonTraits;

  const RecommendationModel({
    required this.petId,
    required this.userId,
    required this.compatibilityScore,
    required this.reason,
    this.distance,
    this.commonTraits = const [],
  });

  factory RecommendationModel.fromMap(Map<String, dynamic> map) {
    return RecommendationModel(
      petId: map['petId'] ?? '',
      userId: map['userId'] ?? '',
      compatibilityScore: map['compatibilityScore'] ?? 0,
      reason: map['reason'] ?? '',
      distance: map['distance']?.toDouble(),
      commonTraits: List<String>.from(map['commonTraits'] ?? []),
    );
  }

  @override
  List<Object?> get props => [
        petId,
        userId,
        compatibilityScore,
        reason,
        distance,
        commonTraits,
      ];
}
