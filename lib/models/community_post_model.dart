import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../core/constants/app_icons.dart';

/// ============================================================
/// 커뮤니티(Community) 게시판 모델
/// 
/// 소셜 > 커뮤니티 기능의 데이터 모델
/// - CommunityPostModel: 게시글
/// - CommunityCommentModel: 댓글
/// - CommunityLikeModel: 게시글 좋아요
/// - CommunityCommentLikeModel: 댓글 좋아요
/// ============================================================

/// 게시글 카테고리
enum CommunityCategory {
  daily,      // 일상
  question,   // 질문
  info,       // 정보공유
  review,     // 후기
  event,      // 이벤트
  other,      // 기타
}

extension CommunityCategoryLabel on CommunityCategory {
  String get label {
    switch (this) {
      case CommunityCategory.daily:
        return '일상';
      case CommunityCategory.question:
        return '질문';
      case CommunityCategory.info:
        return '정보공유';
      case CommunityCategory.review:
        return '후기';
      case CommunityCategory.event:
        return '이벤트';
      case CommunityCategory.other:
        return '기타';
    }
  }
  
  String get emoji {
    switch (this) {
      case CommunityCategory.daily:
        return '☀️';
      case CommunityCategory.question:
        return '❓';
      case CommunityCategory.info:
        return '📢';
      case CommunityCategory.review:
        return '⭐';
      case CommunityCategory.event:
        return '🎉';
      case CommunityCategory.other:
        return '💬';
    }
  }
  
  IconData get icon {
    switch (this) {
      case CommunityCategory.daily:
        return AppIcons.weather;
      case CommunityCategory.question:
        return AppIcons.help;
      case CommunityCategory.info:
        return AppIcons.campaign;
      case CommunityCategory.review:
        return AppIcons.starOutlined;
      case CommunityCategory.event:
        return AppIcons.celebration;
      case CommunityCategory.other:
        return AppIcons.chatBubbleOutlined;
    }
  }
}

/// 게시글 모델
class CommunityPostModel extends Equatable {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorProfileUrl;
  final CommunityCategory category;
  final String title;
  final String content;
  final List<String> imageUrls;
  final String? videoUrl;
  final String? videoThumbnailUrl;
  final List<String> tags;
  final int likeCount;
  final int commentCount;
  final int viewCount;
  final bool isAnonymous;
  final String? location;
  final GeoPoint? geoPoint;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CommunityPostModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorProfileUrl,
    required this.category,
    this.title = '',
    required this.content,
    this.imageUrls = const [],
    this.videoUrl,
    this.videoThumbnailUrl,
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
  
  /// 동영상이 있는지 확인
  bool get hasVideo => videoUrl != null && videoUrl!.isNotEmpty;
  
  /// 미디어(이미지 또는 동영상)가 있는지 확인
  bool get hasMedia => hasImages || hasVideo;
  
  /// 첫 번째 이미지
  String? get firstImage => imageUrls.isNotEmpty ? imageUrls.first : null;

  factory CommunityPostModel.fromFirestore(Map<String, dynamic> data, {String? id}) {
    return CommunityPostModel(
      id: id ?? data['id'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      authorProfileUrl: data['authorProfileUrl'],
      category: CommunityCategory.values.firstWhere(
        (e) => e.name == data['category'],
        orElse: () => CommunityCategory.daily,
      ),
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      videoUrl: data['videoUrl'],
      videoThumbnailUrl: data['videoThumbnailUrl'],
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
      'title': title,
      'content': content,
      'imageUrls': imageUrls,
      'videoUrl': videoUrl,
      'videoThumbnailUrl': videoThumbnailUrl,
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
  
  CommunityPostModel copyWith({
    String? id,
    String? authorId,
    String? authorName,
    String? authorProfileUrl,
    CommunityCategory? category,
    String? title,
    String? content,
    List<String>? imageUrls,
    String? videoUrl,
    String? videoThumbnailUrl,
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
    return CommunityPostModel(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorProfileUrl: authorProfileUrl ?? this.authorProfileUrl,
      category: category ?? this.category,
      title: title ?? this.title,
      content: content ?? this.content,
      imageUrls: imageUrls ?? this.imageUrls,
      videoUrl: videoUrl ?? this.videoUrl,
      videoThumbnailUrl: videoThumbnailUrl ?? this.videoThumbnailUrl,
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
        id, authorId, authorName, authorProfileUrl, category, title, content,
        imageUrls, videoUrl, videoThumbnailUrl, tags, likeCount, commentCount, 
        viewCount, isAnonymous, location, geoPoint, createdAt, updatedAt,
      ];
}

/// 댓글 모델
class CommunityCommentModel extends Equatable {
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

  const CommunityCommentModel({
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

  factory CommunityCommentModel.fromFirestore(Map<String, dynamic> data, {String? id}) {
    return CommunityCommentModel(
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
class CommunityLikeModel extends Equatable {
  final String id;
  final String userId;
  final String postId;
  final DateTime createdAt;

  const CommunityLikeModel({
    required this.id,
    required this.userId,
    required this.postId,
    required this.createdAt,
  });

  factory CommunityLikeModel.fromFirestore(Map<String, dynamic> data, {String? id}) {
    return CommunityLikeModel(
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
class CommunityCommentLikeModel extends Equatable {
  final String id;
  final String userId;
  final String commentId;
  final DateTime createdAt;

  const CommunityCommentLikeModel({
    required this.id,
    required this.userId,
    required this.commentId,
    required this.createdAt,
  });

  factory CommunityCommentLikeModel.fromFirestore(Map<String, dynamic> data, {String? id}) {
    return CommunityCommentLikeModel(
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
