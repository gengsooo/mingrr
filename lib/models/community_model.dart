import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// ============================================================
/// 커뮤니티(소모임/클래스) 관련 모델
/// 모임, 일정, 멤버 등 데이터 구조
/// ============================================================

/// 모임 타입
enum GroupType {
  walking,    // 산책 모임
  training,   // 훈련/교육
  social,     // 친목 모임
  health,     // 건강/케어
  craft,      // 수제 간식/용품 만들기
  other,      // 기타
}

/// 모임 모델
class GroupModel extends Equatable {
  /// 모임 ID
  final String id;
  
  /// 모임 이름
  final String name;
  
  /// 설명
  final String description;
  
  /// 타입
  final GroupType type;
  
  /// 대표 이미지 URL
  final String? imageUrl;
  
  /// 생성자 ID
  final String creatorId;
  
  /// 관리자 ID 목록
  final List<String> adminIds;
  
  /// 멤버 ID 목록
  final List<String> memberIds;
  
  /// 최대 멤버 수 (0 = 무제한)
  final int maxMembers;
  
  /// 위치 (GeoPoint)
  final GeoPoint? location;
  
  /// 주소 (표시용)
  final String? address;
  
  /// 대상 반려동물 종류 (선택사항)
  final String? targetPetType;
  
  /// 공개 여부
  final bool isPublic;
  
  /// 가입 승인 필요 여부
  final bool requireApproval;
  
  /// 태그 목록
  final List<String> tags;
  
  /// 생성일
  final DateTime createdAt;
  
  /// 수정일
  final DateTime updatedAt;

  const GroupModel({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    this.imageUrl,
    required this.creatorId,
    this.adminIds = const [],
    this.memberIds = const [],
    this.maxMembers = 0,
    this.location,
    this.address,
    this.targetPetType,
    this.isPublic = true,
    this.requireApproval = false,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// 타입 한글 표시
  String get typeString {
    switch (type) {
      case GroupType.walking:
        return '산책 모임';
      case GroupType.training:
        return '훈련/교육';
      case GroupType.social:
        return '친목 모임';
      case GroupType.health:
        return '건강/케어';
      case GroupType.craft:
        return '수제 간식/용품';
      case GroupType.other:
        return '기타';
    }
  }

  /// 멤버 수
  int get memberCount => memberIds.length;

  /// 자리 있는지 확인
  bool get hasSpace => maxMembers == 0 || memberCount < maxMembers;

  factory GroupModel.fromFirestore(Map<String, dynamic> data, {String? id}) {
    return GroupModel(
      id: id ?? data['id'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      type: GroupType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => GroupType.other,
      ),
      imageUrl: data['imageUrl'],
      creatorId: data['creatorId'] ?? '',
      adminIds: List<String>.from(data['adminIds'] ?? []),
      memberIds: List<String>.from(data['memberIds'] ?? []),
      maxMembers: data['maxMembers'] ?? 0,
      location: data['location'],
      address: data['address'],
      targetPetType: data['targetPetType'],
      isPublic: data['isPublic'] ?? true,
      requireApproval: data['requireApproval'] ?? false,
      tags: List<String>.from(data['tags'] ?? []),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
  
  /// 카테고리 문자열 (홈 화면용)
  String get category => typeString;

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'type': type.name,
      'imageUrl': imageUrl,
      'creatorId': creatorId,
      'adminIds': adminIds,
      'memberIds': memberIds,
      'maxMembers': maxMembers,
      'location': location,
      'address': address,
      'targetPetType': targetPetType,
      'isPublic': isPublic,
      'requireApproval': requireApproval,
      'tags': tags,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        type,
        imageUrl,
        creatorId,
        adminIds,
        memberIds,
        maxMembers,
        location,
        address,
        targetPetType,
        isPublic,
        requireApproval,
        tags,
        createdAt,
        updatedAt,
      ];
}

/// 모임 일정 모델
class ScheduleModel extends Equatable {
  /// 일정 ID
  final String id;
  
  /// 모임 ID
  final String groupId;
  
  /// 제목
  final String title;
  
  /// 설명
  final String? description;
  
  /// 시작 시간
  final DateTime startTime;
  
  /// 종료 시간
  final DateTime? endTime;
  
  /// 장소
  final String? place;
  
  /// 위치 (GeoPoint)
  final GeoPoint? location;
  
  /// 참가자 ID 목록
  final List<String> participantIds;
  
  /// 최대 참가자 수 (0 = 무제한)
  final int maxParticipants;
  
  /// 생성자 ID
  final String creatorId;
  
  /// 생성일
  final DateTime createdAt;

  const ScheduleModel({
    required this.id,
    required this.groupId,
    required this.title,
    this.description,
    required this.startTime,
    this.endTime,
    this.place,
    this.location,
    this.participantIds = const [],
    this.maxParticipants = 0,
    required this.creatorId,
    required this.createdAt,
  });

  /// 참가자 수
  int get participantCount => participantIds.length;

  /// 자리 있는지 확인
  bool get hasSpace => maxParticipants == 0 || participantCount < maxParticipants;

  factory ScheduleModel.fromFirestore(Map<String, dynamic> data, {String? id}) {
    return ScheduleModel(
      id: id ?? data['id'] ?? '',
      groupId: data['groupId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'],
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: data['endTime'] != null
          ? (data['endTime'] as Timestamp).toDate()
          : null,
      place: data['place'],
      location: data['location'],
      participantIds: List<String>.from(data['participantIds'] ?? []),
      maxParticipants: data['maxParticipants'] ?? 0,
      creatorId: data['creatorId'] ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'groupId': groupId,
      'title': title,
      'description': description,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'place': place,
      'location': location,
      'participantIds': participantIds,
      'maxParticipants': maxParticipants,
      'creatorId': creatorId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  @override
  List<Object?> get props => [
        id,
        groupId,
        title,
        description,
        startTime,
        endTime,
        place,
        location,
        participantIds,
        maxParticipants,
        creatorId,
        createdAt,
      ];
}

/// 모임 가입 신청 모델
class JoinRequestModel extends Equatable {
  final String id;
  final String groupId;
  final String userId;
  final String? message;
  final String status; // pending, approved, rejected
  final DateTime createdAt;
  final DateTime? respondedAt;

  const JoinRequestModel({
    required this.id,
    required this.groupId,
    required this.userId,
    this.message,
    this.status = 'pending',
    required this.createdAt,
    this.respondedAt,
  });

  factory JoinRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return JoinRequestModel(
      id: doc.id,
      groupId: data['groupId'] ?? '',
      userId: data['userId'] ?? '',
      message: data['message'],
      status: data['status'] ?? 'pending',
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
      'groupId': groupId,
      'userId': userId,
      'message': message,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'respondedAt': respondedAt != null
          ? Timestamp.fromDate(respondedAt!)
          : null,
    };
  }

  @override
  List<Object?> get props => [
        id,
        groupId,
        userId,
        message,
        status,
        createdAt,
        respondedAt,
      ];
}
