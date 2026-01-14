import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// ============================================================
/// 소모임(Group) 모델
/// 
/// 소셜 > 소모임 기능의 데이터 모델
/// - GroupModel: 모임 정보
/// - GroupScheduleModel: 모임 일정
/// - GroupJoinRequestModel: 가입 신청
/// - GroupLikeModel: 모임 좋아요
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

/// GroupType 한글 라벨 extension
extension GroupTypeLabel on GroupType {
  String get label {
    switch (this) {
      case GroupType.walking:
        return '산책 모임';
      case GroupType.training:
        return '훈련/교육';
      case GroupType.social:
        return '친목 모임';
      case GroupType.health:
        return '건강/케어';
      case GroupType.craft:
        return '수제 간식';
      case GroupType.other:
        return '기타';
    }
  }
  
  /// 영어 문자열에서 GroupType으로 변환
  static GroupType fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'walking':
        return GroupType.walking;
      case 'training':
        return GroupType.training;
      case 'social':
        return GroupType.social;
      case 'health':
        return GroupType.health;
      case 'craft':
        return GroupType.craft;
      default:
        return GroupType.other;
    }
  }
  
  /// 영어 문자열을 한글 라벨로 변환
  static String labelFromString(String? value) {
    return fromString(value).label;
  }
}

/// 모임 상태
enum GroupStatus {
  active,     // 활성
  inactive,   // 비활성
  closed,     // 종료
}

/// 모임 모델
class GroupModel extends Equatable {
  final String id;
  final String name;
  final String description;
  final GroupType type;
  final String? imageUrl;
  final String creatorId;
  final List<String> adminIds;
  final List<String> memberIds;
  final int maxMembers;
  final GeoPoint? location;
  final String? address;
  final String? targetPetType;
  final bool isPetAccompanied;
  final bool isPublic;
  final bool requireApproval;
  final List<String> tags;
  final int likeCount;
  final GroupStatus status;
  final DateTime createdAt;
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
    this.isPetAccompanied = true,
    this.isPublic = true,
    this.requireApproval = false,
    this.tags = const [],
    this.likeCount = 0,
    this.status = GroupStatus.active,
    required this.createdAt,
    required this.updatedAt,
  });

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

  int get memberCount => memberIds.length;
  bool get hasSpace => maxMembers == 0 || memberCount < maxMembers;
  String get category => typeString;
  
  /// 사용자가 멤버인지 확인
  bool isMember(String userId) => memberIds.contains(userId);
  
  /// 사용자가 관리자인지 확인
  bool isAdmin(String userId) => adminIds.contains(userId);
  
  /// 사용자가 모임장인지 확인
  bool isCreator(String userId) => creatorId == userId;

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
      isPetAccompanied: data['isPetAccompanied'] ?? true,
      isPublic: data['isPublic'] ?? true,
      requireApproval: data['requireApproval'] ?? false,
      tags: List<String>.from(data['tags'] ?? []),
      likeCount: data['likeCount'] ?? 0,
      status: GroupStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => GroupStatus.active,
      ),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

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
      'isPetAccompanied': isPetAccompanied,
      'isPublic': isPublic,
      'requireApproval': requireApproval,
      'tags': tags,
      'likeCount': likeCount,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
  
  GroupModel copyWith({
    String? id,
    String? name,
    String? description,
    GroupType? type,
    String? imageUrl,
    String? creatorId,
    List<String>? adminIds,
    List<String>? memberIds,
    int? maxMembers,
    GeoPoint? location,
    String? address,
    String? targetPetType,
    bool? isPetAccompanied,
    bool? isPublic,
    bool? requireApproval,
    List<String>? tags,
    int? likeCount,
    GroupStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      imageUrl: imageUrl ?? this.imageUrl,
      creatorId: creatorId ?? this.creatorId,
      adminIds: adminIds ?? this.adminIds,
      memberIds: memberIds ?? this.memberIds,
      maxMembers: maxMembers ?? this.maxMembers,
      location: location ?? this.location,
      address: address ?? this.address,
      targetPetType: targetPetType ?? this.targetPetType,
      isPetAccompanied: isPetAccompanied ?? this.isPetAccompanied,
      isPublic: isPublic ?? this.isPublic,
      requireApproval: requireApproval ?? this.requireApproval,
      tags: tags ?? this.tags,
      likeCount: likeCount ?? this.likeCount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id, name, description, type, imageUrl, creatorId, adminIds,
        memberIds, maxMembers, location, address, targetPetType,
        isPetAccompanied, isPublic, requireApproval, tags, likeCount,
        status, createdAt, updatedAt,
      ];
}

/// 소모임 좋아요 모델
class GroupLikeModel extends Equatable {
  final String id;
  final String userId;
  final String groupId;
  final DateTime createdAt;

  const GroupLikeModel({
    required this.id,
    required this.userId,
    required this.groupId,
    required this.createdAt,
  });

  factory GroupLikeModel.fromFirestore(Map<String, dynamic> data, {String? id}) {
    return GroupLikeModel(
      id: id ?? data['id'] ?? '',
      userId: data['userId'] ?? '',
      groupId: data['groupId'] ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'groupId': groupId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  @override
  List<Object?> get props => [id, userId, groupId, createdAt];
}

/// 모임 일정 모델
class GroupScheduleModel extends Equatable {
  final String id;
  final String groupId;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime? endTime;
  final String? place;
  final GeoPoint? location;
  final List<String> participantIds;
  final int maxParticipants;
  final String creatorId;
  final ScheduleStatus status;
  final DateTime createdAt;

  const GroupScheduleModel({
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
    this.status = ScheduleStatus.upcoming,
    required this.createdAt,
  });

  int get participantCount => participantIds.length;
  bool get hasSpace => maxParticipants == 0 || participantCount < maxParticipants;
  
  /// 일정이 지났는지 확인
  bool get isPast => startTime.isBefore(DateTime.now());

  factory GroupScheduleModel.fromFirestore(Map<String, dynamic> data, {String? id}) {
    return GroupScheduleModel(
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
      status: ScheduleStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => ScheduleStatus.upcoming,
      ),
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
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  @override
  List<Object?> get props => [
        id, groupId, title, description, startTime, endTime, place,
        location, participantIds, maxParticipants, creatorId, status, createdAt,
      ];
}

/// 일정 상태
enum ScheduleStatus {
  upcoming,   // 예정
  ongoing,    // 진행중
  completed,  // 완료
  cancelled,  // 취소
}

/// 모임 가입 신청 모델
class GroupJoinRequestModel extends Equatable {
  final String id;
  final String groupId;
  final String userId;
  final String? message;
  final JoinRequestStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;
  final String? respondedBy;

  const GroupJoinRequestModel({
    required this.id,
    required this.groupId,
    required this.userId,
    this.message,
    this.status = JoinRequestStatus.pending,
    required this.createdAt,
    this.respondedAt,
    this.respondedBy,
  });

  factory GroupJoinRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GroupJoinRequestModel(
      id: doc.id,
      groupId: data['groupId'] ?? '',
      userId: data['userId'] ?? '',
      message: data['message'],
      status: JoinRequestStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => JoinRequestStatus.pending,
      ),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      respondedAt: data['respondedAt'] != null
          ? (data['respondedAt'] as Timestamp).toDate()
          : null,
      respondedBy: data['respondedBy'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'groupId': groupId,
      'userId': userId,
      'message': message,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'respondedAt': respondedAt != null
          ? Timestamp.fromDate(respondedAt!)
          : null,
      'respondedBy': respondedBy,
    };
  }

  @override
  List<Object?> get props => [
        id, groupId, userId, message, status, createdAt, respondedAt, respondedBy,
      ];
}

/// 가입 신청 상태
enum JoinRequestStatus {
  pending,    // 대기중
  approved,   // 승인됨
  rejected,   // 거절됨
}

/// 멤버 역할
enum GroupMemberRole {
  creator,    // 모임장
  admin,      // 운영진
  member,     // 일반 멤버
}
