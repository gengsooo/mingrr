import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// ============================================================
/// 커뮤니티 피드(게시판) 관련 모델
/// SNS형 게시글, 댓글, 좋아요 등 데이터 구조
/// ============================================================

/// 게시글 카테고리
enum FeedCategory {
  daily,      // 일상
  question,   // 질문
  info,       // 정보공유
  review,     // 후기
  lost,       // 실종/목격
  event,      // 이벤트
  other,      // 기타
}

extension FeedCategoryLabel on FeedCategory {
  String get label {
    switch (this) {
      case FeedCategory.daily:
        return '일상';
      case FeedCategory.question:
        return '질문';
      case FeedCategory.info:
        return '정보공유';
      case FeedCategory.review:
        return '후기';
      case FeedCategory.lost:
        return '실종/목격';
      case FeedCategory.event:
        return '이벤트';
      case FeedCategory.other:
        return '기타';
    }
  }
  
  String get emoji {
    switch (this) {
      case FeedCategory.daily:
        return '🐕';
      case FeedCategory.question:
        return '❓';
      case FeedCategory.info:
        return '📢';
      case FeedCategory.review:
        return '⭐';
      case FeedCategory.lost:
        return '🔍';
      case FeedCategory.event:
        return '🎉';
      case FeedCategory.other:
        return '💬';
    }
  }
}

/// 게시글 모델
class FeedPostModel extends Equatable {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorProfileUrl;
  final FeedCategory category;
  final String content;
  final List<String> imageUrls;
  final List<String> tags;
  final int likeCount;
  final int commentCount;
  final int viewCount;
  final bool isAnonymous;
  final String? location;
  final GeoPoint? geoPoint;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FeedPostModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorProfileUrl,
    required this.category,
    required this.content,
    this.imageUrls = const [],
    this.tags = const [],
    this.likeCount = 0,
    this.commentCount = 0,
    this.viewCount = 0,
    this.isAnonymous = false,
    this.location,
    this.geoPoint,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 표시용 작성자 이름
  String get displayAuthorName => isAnonymous ? '익명' : authorName;
  
  /// 이미지가 있는지 확인
  bool get hasImages => imageUrls.isNotEmpty;
  
  /// 첫 번째 이미지
  String? get firstImage => imageUrls.isNotEmpty ? imageUrls.first : null;

  factory FeedPostModel.fromFirestore(Map<String, dynamic> data, {String? id}) {
    return FeedPostModel(
      id: id ?? data['id'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      authorProfileUrl: data['authorProfileUrl'],
      category: FeedCategory.values.firstWhere(
        (e) => e.name == data['category'],
        orElse: () => FeedCategory.daily,
      ),
      content: data['content'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      tags: List<String>.from(data['tags'] ?? []),
      likeCount: data['likeCount'] ?? 0,
      commentCount: data['commentCount'] ?? 0,
      viewCount: data['viewCount'] ?? 0,
      isAnonymous: data['isAnonymous'] ?? false,
      location: data['location'],
      geoPoint: data['geoPoint'],
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
      'authorId': authorId,
      'authorName': authorName,
      'authorProfileUrl': authorProfileUrl,
      'category': category.name,
      'content': content,
      'imageUrls': imageUrls,
      'tags': tags,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'viewCount': viewCount,
      'isAnonymous': isAnonymous,
      'location': location,
      'geoPoint': geoPoint,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
  
  FeedPostModel copyWith({
    String? id,
    String? authorId,
    String? authorName,
    String? authorProfileUrl,
    FeedCategory? category,
    String? content,
    List<String>? imageUrls,
    List<String>? tags,
    int? likeCount,
    int? commentCount,
    int? viewCount,
    bool? isAnonymous,
    String? location,
    GeoPoint? geoPoint,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FeedPostModel(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorProfileUrl: authorProfileUrl ?? this.authorProfileUrl,
      category: category ?? this.category,
      content: content ?? this.content,
      imageUrls: imageUrls ?? this.imageUrls,
      tags: tags ?? this.tags,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      viewCount: viewCount ?? this.viewCount,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      location: location ?? this.location,
      geoPoint: geoPoint ?? this.geoPoint,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id, authorId, authorName, authorProfileUrl, category, content,
        imageUrls, tags, likeCount, commentCount, viewCount, isAnonymous,
        location, geoPoint, createdAt, updatedAt,
      ];
}

/// 댓글 모델
class FeedCommentModel extends Equatable {
  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String? authorProfileUrl;
  final String content;
  final String? parentId;
  final int likeCount;
  final bool isAnonymous;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const FeedCommentModel({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    this.authorProfileUrl,
    required this.content,
    this.parentId,
    this.likeCount = 0,
    this.isAnonymous = false,
    required this.createdAt,
    this.updatedAt,
  });

  /// 대댓글인지 확인
  bool get isReply => parentId != null;
  
  /// 표시용 작성자 이름
  String get displayAuthorName => isAnonymous ? '익명' : authorName;

  factory FeedCommentModel.fromFirestore(Map<String, dynamic> data, {String? id}) {
    return FeedCommentModel(
      id: id ?? data['id'] ?? '',
      postId: data['postId'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      authorProfileUrl: data['authorProfileUrl'],
      content: data['content'] ?? '',
      parentId: data['parentId'],
      likeCount: data['likeCount'] ?? 0,
      isAnonymous: data['isAnonymous'] ?? false,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'postId': postId,
      'authorId': authorId,
      'authorName': authorName,
      'authorProfileUrl': authorProfileUrl,
      'content': content,
      'parentId': parentId,
      'likeCount': likeCount,
      'isAnonymous': isAnonymous,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  @override
  List<Object?> get props => [
        id, postId, authorId, authorName, authorProfileUrl, content,
        parentId, likeCount, isAnonymous, createdAt, updatedAt,
      ];
}

/// 게시글 좋아요 모델
class FeedLikeModel extends Equatable {
  final String id;
  final String userId;
  final String postId;
  final DateTime createdAt;

  const FeedLikeModel({
    required this.id,
    required this.userId,
    required this.postId,
    required this.createdAt,
  });

  factory FeedLikeModel.fromFirestore(Map<String, dynamic> data, {String? id}) {
    return FeedLikeModel(
      id: id ?? data['id'] ?? '',
      userId: data['userId'] ?? '',
      postId: data['postId'] ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'postId': postId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  @override
  List<Object?> get props => [id, userId, postId, createdAt];
}

/// 댓글 좋아요 모델
class CommentLikeModel extends Equatable {
  final String id;
  final String userId;
  final String commentId;
  final DateTime createdAt;

  const CommentLikeModel({
    required this.id,
    required this.userId,
    required this.commentId,
    required this.createdAt,
  });

  factory CommentLikeModel.fromFirestore(Map<String, dynamic> data, {String? id}) {
    return CommentLikeModel(
      id: id ?? data['id'] ?? '',
      userId: data['userId'] ?? '',
      commentId: data['commentId'] ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'commentId': commentId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  @override
  List<Object?> get props => [id, userId, commentId, createdAt];
}
