import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// ============================================================
/// 평가 모델
/// 사용자 간 평가 데이터 구조 (꼬순내 지수 산정에 사용)
/// ============================================================

/// 평가 타입
/// 소모임/커뮤니티는 평가 기능 없음
enum RatingType {
  dating('데이팅'),      // 데이팅/산책 후 평가
  breeding('교배'),      // 교배 완료 후 평가
  marketplace('거래');   // 마켓 거래 후 평가

  final String label;
  const RatingType(this.label);
  
  /// 채팅/활동 타입 문자열에서 RatingType으로 변환
  /// 
  /// 사용 예시:
  /// ```dart
  /// final ratingType = RatingType.fromActivityType('marketplace');
  /// ```
  static RatingType fromActivityType(String type) {
    switch (type) {
      case 'marketplace':
      case 'market':
        return RatingType.marketplace;
      case 'breeding':
        return RatingType.breeding;
      case 'dating':
      default:
        return RatingType.dating;
    }
  }
  
  /// 활동 타입 라벨 (한글)
  /// 
  /// 사용 예시:
  /// ```dart
  /// final label = RatingType.dating.activityLabel; // '만남'
  /// ```
  String get activityLabel {
    switch (this) {
      case RatingType.dating:
        return '만남';
      case RatingType.marketplace:
        return '거래';
      case RatingType.breeding:
        return '교배';
    }
  }
  
  /// 긍정 평가 태그 목록
  List<String> get positiveTags {
    switch (this) {
      case RatingType.dating:
        return PositiveRatingTags.dating;
      case RatingType.marketplace:
        return PositiveRatingTags.marketplace;
      case RatingType.breeding:
        return PositiveRatingTags.breeding;
    }
  }
  
  /// 부정 평가 태그 목록
  List<String> get negativeTags {
    switch (this) {
      case RatingType.dating:
        return NegativeRatingTags.dating;
      case RatingType.marketplace:
        return NegativeRatingTags.marketplace;
      case RatingType.breeding:
        return NegativeRatingTags.breeding;
    }
  }
}

/// 거래/활동 결과
enum ActivityResult {
  completed('완료'),     // 정상 완료
  noShow('노쇼'),        // 상대방 불참
  cancelled('취소'),     // 상호 합의 취소
  failed('불발');        // 기타 사유로 불발

  final String label;
  const ActivityResult(this.label);
}

/// 평가 모델
class RatingModel extends Equatable {
  /// 평가 ID
  final String id;
  
  /// 평가자 ID
  final String raterId;
  
  /// 평가 대상자 ID
  final String targetId;
  
  /// 평가 타입
  final RatingType type;
  
  /// 관련 ID (채팅방 ID, 상품 ID, 교배글 ID 등)
  final String? relatedId;
  
  /// 활동 결과
  final ActivityResult result;
  
  /// 평점 (1~5점)
  final int score;
  
  /// 평가 태그 (긍정/부정)
  final List<String> tags;
  
  /// 평가 코멘트 (선택)
  final String? comment;
  
  /// 평가 시간
  final DateTime createdAt;
  
  /// 수정 시간
  final DateTime? updatedAt;
  
  /// 상호 평가 공개 여부
  /// - false: 상대방이 아직 평가하지 않음 (비공개)
  /// - true: 양쪽 모두 평가 완료 또는 만료 기간 경과 (공개)
  final bool isVisible;

  const RatingModel({
    required this.id,
    required this.raterId,
    required this.targetId,
    required this.type,
    this.relatedId,
    required this.result,
    required this.score,
    this.tags = const [],
    this.comment,
    required this.createdAt,
    this.updatedAt,
    this.isVisible = false,
  });

  factory RatingModel.fromFirestore(Map<String, dynamic> data, {String? id}) {
    return RatingModel(
      id: id ?? data['id'] ?? '',
      raterId: data['raterId'] ?? '',
      targetId: data['targetId'] ?? '',
      type: RatingType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => RatingType.dating,
      ),
      relatedId: data['relatedId'],
      result: ActivityResult.values.firstWhere(
        (e) => e.name == data['result'],
        orElse: () => ActivityResult.completed,
      ),
      score: data['score'] ?? 3,
      tags: List<String>.from(data['tags'] ?? []),
      comment: data['comment'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      isVisible: data['isVisible'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'raterId': raterId,
      'targetId': targetId,
      'type': type.name,
      'relatedId': relatedId,
      'result': result.name,
      'score': score,
      'tags': tags,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isVisible': isVisible,
    };
  }

  @override
  List<Object?> get props => [
        id,
        raterId,
        targetId,
        type,
        relatedId,
        result,
        score,
        tags,
        comment,
        createdAt,
        updatedAt,
        isVisible,
      ];
}

/// 긍정 평가 태그
class PositiveRatingTags {
  static const List<String> dating = [
    '시간 약속을 잘 지켜요',
    '친절하고 매너가 좋아요',
    '반려동물을 잘 돌봐요',
    '대화가 즐거웠어요',
    '다음에도 만나고 싶어요',
  ];
  
  static const List<String> marketplace = [
    '시간 약속을 잘 지켜요',
    '친절하고 매너가 좋아요',
    '상품 상태가 설명과 같아요',
    '응답이 빨라요',
    '거래가 편했어요',
  ];
  
  static const List<String> breeding = [
    '시간 약속을 잘 지켜요',
    '친절하고 매너가 좋아요',
    '반려동물 건강 상태가 좋아요',
    '정확한 정보를 제공해요',
    '책임감이 있어요',
  ];
}

/// 부정 평가 태그
class NegativeRatingTags {
  static const List<String> dating = [
    '시간 약속을 안 지켜요',
    '불친절해요',
    '반려동물 관리가 부족해요',
    '연락이 안 돼요',
    '노쇼했어요',
  ];
  
  static const List<String> marketplace = [
    '시간 약속을 안 지켜요',
    '불친절해요',
    '상품 상태가 설명과 달라요',
    '응답이 느려요',
    '노쇼했어요',
  ];
  
  static const List<String> breeding = [
    '시간 약속을 안 지켜요',
    '불친절해요',
    '반려동물 건강 정보가 부정확해요',
    '연락이 안 돼요',
    '노쇼했어요',
  ];
}

/// 평가 가능 여부 결과
class RatingEligibility {
  /// 평가 가능 여부
  final bool canRate;
  
  /// 불가능한 경우 사유
  final String? reason;

  const RatingEligibility._({
    required this.canRate,
    this.reason,
  });

  /// 평가 가능
  factory RatingEligibility.allowed() => const RatingEligibility._(canRate: true);

  /// 평가 불가능
  factory RatingEligibility.notAllowed(String reason) => RatingEligibility._(
    canRate: false,
    reason: reason,
  );
}

/// 평가 예외
class RatingException implements Exception {
  final String message;
  
  const RatingException(this.message);
  
  @override
  String toString() => message;
}

/// 거래/활동 상태 모델 (채팅방에 연결)
class TransactionStatusModel extends Equatable {
  /// 상태 ID
  final String id;
  
  /// 채팅방 ID
  final String chatRoomId;
  
  /// 타입 (marketplace, dating, breeding)
  final String type;
  
  /// 관련 ID (상품 ID, 교배글 ID 등)
  final String? relatedId;
  
  /// 판매자/요청자 ID
  final String sellerId;
  
  /// 구매자/신청자 ID
  final String buyerId;
  
  /// 상태 (pending, in_progress, completed, cancelled, no_show)
  final String status;
  
  /// 판매자 평가 완료 여부
  final bool sellerRated;
  
  /// 구매자 평가 완료 여부
  final bool buyerRated;
  
  /// 생성일
  final DateTime createdAt;
  
  /// 완료일
  final DateTime? completedAt;

  const TransactionStatusModel({
    required this.id,
    required this.chatRoomId,
    required this.type,
    this.relatedId,
    required this.sellerId,
    required this.buyerId,
    this.status = 'pending',
    this.sellerRated = false,
    this.buyerRated = false,
    required this.createdAt,
    this.completedAt,
  });

  factory TransactionStatusModel.fromFirestore(Map<String, dynamic> data, {String? id}) {
    return TransactionStatusModel(
      id: id ?? data['id'] ?? '',
      chatRoomId: data['chatRoomId'] ?? '',
      type: data['type'] ?? 'marketplace',
      relatedId: data['relatedId'],
      sellerId: data['sellerId'] ?? '',
      buyerId: data['buyerId'] ?? '',
      status: data['status'] ?? 'pending',
      sellerRated: data['sellerRated'] ?? false,
      buyerRated: data['buyerRated'] ?? false,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'chatRoomId': chatRoomId,
      'type': type,
      'relatedId': relatedId,
      'sellerId': sellerId,
      'buyerId': buyerId,
      'status': status,
      'sellerRated': sellerRated,
      'buyerRated': buyerRated,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }

  TransactionStatusModel copyWith({
    String? id,
    String? chatRoomId,
    String? type,
    String? relatedId,
    String? sellerId,
    String? buyerId,
    String? status,
    bool? sellerRated,
    bool? buyerRated,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return TransactionStatusModel(
      id: id ?? this.id,
      chatRoomId: chatRoomId ?? this.chatRoomId,
      type: type ?? this.type,
      relatedId: relatedId ?? this.relatedId,
      sellerId: sellerId ?? this.sellerId,
      buyerId: buyerId ?? this.buyerId,
      status: status ?? this.status,
      sellerRated: sellerRated ?? this.sellerRated,
      buyerRated: buyerRated ?? this.buyerRated,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        chatRoomId,
        type,
        relatedId,
        sellerId,
        buyerId,
        status,
        sellerRated,
        buyerRated,
        createdAt,
        completedAt,
      ];
}
