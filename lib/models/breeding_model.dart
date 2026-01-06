import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// ============================================================
/// 교배 글 모델
/// 교배 상대를 찾는 글 데이터
/// ============================================================

/// 교배 글 상태
enum BreedingStatus {
  active('모집중'),
  matched('매칭완료'),
  closed('마감');

  final String label;
  const BreedingStatus(this.label);
}

/// 교배 글 모델
class BreedingPostModel extends Equatable {
  /// 글 ID
  final String id;
  
  /// 작성자 ID
  final String userId;
  
  /// 교배할 반려동물 ID
  final String petId;
  
  /// 제목
  final String title;
  
  /// 상세 내용
  final String description;
  
  /// 상태
  final BreedingStatus status;
  
  /// 원하는 상대 성별 (null: 무관)
  final String? preferredGender;
  
  /// 원하는 상대 크기 (복수 선택 가능)
  final List<String> preferredSizes;
  
  /// 같은 품종만 원하는지
  final bool sameBreedOnly;
  
  /// 원하는 최소 나이
  final int? minAge;
  
  /// 원하는 최대 나이
  final int? maxAge;
  
  /// 위치 (GeoPoint)
  final GeoPoint? location;
  
  /// 주소
  final String? address;
  
  /// 조회수
  final int viewCount;
  
  /// 관심 수
  final int likeCount;
  
  /// 채팅 수
  final int chatCount;
  
  /// 생성일
  final DateTime createdAt;
  
  /// 수정일
  final DateTime updatedAt;

  const BreedingPostModel({
    required this.id,
    required this.userId,
    required this.petId,
    required this.title,
    required this.description,
    this.status = BreedingStatus.active,
    this.preferredGender,
    this.preferredSizes = const [],
    this.sameBreedOnly = false,
    this.minAge,
    this.maxAge,
    this.location,
    this.address,
    this.viewCount = 0,
    this.likeCount = 0,
    this.chatCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 상태 문자열
  String get statusString => status.label;

  factory BreedingPostModel.fromFirestore(Map<String, dynamic> data, {String? id}) {
    return BreedingPostModel(
      id: id ?? data['id'] ?? '',
      userId: data['userId'] ?? '',
      petId: data['petId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      status: BreedingStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => BreedingStatus.active,
      ),
      preferredGender: data['preferredGender'],
      preferredSizes: List<String>.from(data['preferredSizes'] ?? []),
      sameBreedOnly: data['sameBreedOnly'] ?? false,
      minAge: data['minAge'],
      maxAge: data['maxAge'],
      location: data['location'],
      address: data['address'],
      viewCount: data['viewCount'] ?? 0,
      likeCount: data['likeCount'] ?? 0,
      chatCount: data['chatCount'] ?? 0,
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
      'userId': userId,
      'petId': petId,
      'title': title,
      'description': description,
      'status': status.name,
      'preferredGender': preferredGender,
      'preferredSizes': preferredSizes,
      'sameBreedOnly': sameBreedOnly,
      'minAge': minAge,
      'maxAge': maxAge,
      'location': location,
      'address': address,
      'viewCount': viewCount,
      'likeCount': likeCount,
      'chatCount': chatCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  BreedingPostModel copyWith({
    String? id,
    String? userId,
    String? petId,
    String? title,
    String? description,
    BreedingStatus? status,
    String? preferredGender,
    List<String>? preferredSizes,
    bool? sameBreedOnly,
    int? minAge,
    int? maxAge,
    GeoPoint? location,
    String? address,
    int? viewCount,
    int? likeCount,
    int? chatCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BreedingPostModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      petId: petId ?? this.petId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      preferredGender: preferredGender ?? this.preferredGender,
      preferredSizes: preferredSizes ?? this.preferredSizes,
      sameBreedOnly: sameBreedOnly ?? this.sameBreedOnly,
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      location: location ?? this.location,
      address: address ?? this.address,
      viewCount: viewCount ?? this.viewCount,
      likeCount: likeCount ?? this.likeCount,
      chatCount: chatCount ?? this.chatCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        petId,
        title,
        description,
        status,
        preferredGender,
        preferredSizes,
        sameBreedOnly,
        minAge,
        maxAge,
        location,
        address,
        viewCount,
        likeCount,
        chatCount,
        createdAt,
        updatedAt,
      ];
}
