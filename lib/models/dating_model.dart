import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// ============================================================
/// 데이팅 관련 모델
/// 좋아요, 매칭, AI 추천 등 데이팅 기능 데이터 구조
/// ============================================================

/// 좋아요 상태
enum LikeStatus {
  pending,  // 대기 중
  accepted, // 수락됨
  rejected, // 거절됨
}

/// 좋아요 모델 (데이팅 신청)
class LikeModel extends Equatable {
  /// 좋아요 ID
  final String id;
  
  /// 보낸 사용자 ID
  final String fromUserId;
  
  /// 보낸 반려동물 ID
  final String fromPetId;
  
  /// 받은 사용자 ID
  final String toUserId;
  
  /// 받은 반려동물 ID
  final String toPetId;
  
  /// 상태
  final LikeStatus status;
  
  /// 슈퍼 라이크 여부 (수익화 - 현재 숨김)
  final bool isSuperLike;
  
  /// 메시지 (선택사항)
  final String? message;
  
  /// 생성일
  final DateTime createdAt;
  
  /// 응답일
  final DateTime? respondedAt;

  const LikeModel({
    required this.id,
    required this.fromUserId,
    required this.fromPetId,
    required this.toUserId,
    required this.toPetId,
    this.status = LikeStatus.pending,
    this.isSuperLike = false,
    this.message,
    required this.createdAt,
    this.respondedAt,
  });

  factory LikeModel.fromFirestore(Map<String, dynamic> data, {String? id}) {
    return LikeModel(
      id: id ?? data['id'] ?? '',
      fromUserId: data['fromUserId'] ?? '',
      fromPetId: data['fromPetId'] ?? '',
      toUserId: data['toUserId'] ?? '',
      toPetId: data['toPetId'] ?? '',
      status: LikeStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => LikeStatus.pending,
      ),
      isSuperLike: data['isSuperLike'] ?? false,
      message: data['message'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      respondedAt: data['respondedAt'] != null
          ? (data['respondedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'fromUserId': fromUserId,
      'fromPetId': fromPetId,
      'toUserId': toUserId,
      'toPetId': toPetId,
      'status': status.name,
      'isSuperLike': isSuperLike,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
      'respondedAt': respondedAt != null
          ? Timestamp.fromDate(respondedAt!)
          : null,
    };
  }

  @override
  List<Object?> get props => [
        id,
        fromUserId,
        fromPetId,
        toUserId,
        toPetId,
        status,
        isSuperLike,
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
