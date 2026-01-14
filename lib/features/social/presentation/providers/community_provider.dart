import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../models/community_post_model.dart';

/// ============================================================
/// 커뮤니티(Community) 게시판 Provider
/// 
/// 소셜 > 커뮤니티 기능의 상태 관리
/// - 게시글 CRUD (CommunityPostModel)
/// - 댓글 CRUD (CommunityCommentModel)
/// - 좋아요 토글
/// - 조회수 증가
/// ============================================================

/// 커뮤니티 게시글 목록 (카테고리 필터)
final communityPostsProvider = FutureProvider.autoDispose.family<List<CommunityPostModel>, CommunityCategory?>((ref, category) async {
  // 캐시 유지 - 자주 사용되는 데이터이므로 자동 해제 방지
  ref.keepAlive();
  
  final firebase = FirebaseService();
  
  Query<Map<String, dynamic>> query = firebase.feedPostsCollection
      .orderBy('createdAt', descending: true)
      .limit(50);
  
  if (category != null) {
    query = firebase.feedPostsCollection
        .where('category', isEqualTo: category.name)
        .orderBy('createdAt', descending: true)
        .limit(50);
  }
  
  final snapshot = await query.get();
  return snapshot.docs
      .map((doc) => CommunityPostModel.fromFirestore(doc.data(), id: doc.id))
      .toList();
});

/// 특정 게시글 상세
final communityPostDetailProvider = FutureProvider.autoDispose.family<CommunityPostModel?, String>((ref, postId) async {
  // 캐시 유지 - 상세 화면에서 자주 사용
  ref.keepAlive();
  
  final firebase = FirebaseService();
  final doc = await firebase.feedPostsCollection.doc(postId).get();
  if (!doc.exists) return null;
  return CommunityPostModel.fromFirestore(doc.data()!, id: doc.id);
});

/// 게시글 댓글 목록
final communityCommentsProvider = FutureProvider.autoDispose.family<List<CommunityCommentModel>, String>((ref, postId) async {
  // 캐시 유지 - 댓글 목록은 상세 화면에서 자주 사용
  ref.keepAlive();
  
  final firebase = FirebaseService();
  final snapshot = await firebase.feedCommentsCollection
      .where('postId', isEqualTo: postId)
      .orderBy('createdAt', descending: false)
      .get();
  
  return snapshot.docs
      .map((doc) => CommunityCommentModel.fromFirestore(doc.data(), id: doc.id))
      .toList();
});

/// 사용자가 좋아요한 커뮤니티 게시글 ID 목록
final userLikedCommunityPostsProvider = FutureProvider.autoDispose<Set<String>>((ref) async {
  final firebase = FirebaseService();
  final userId = firebase.currentUserId;
  if (userId == null) return {};
  
  final snapshot = await firebase.feedLikesCollection
      .where('userId', isEqualTo: userId)
      .get();
  
  return snapshot.docs.map((doc) => doc.data()['postId'] as String).toSet();
});

/// 커뮤니티 게시판 관리 Notifier
class CommunityNotifier extends StateNotifier<AsyncValue<void>> {
  final FirebaseService _firebase = FirebaseService();
  
  CommunityNotifier(Ref ref) : super(const AsyncValue.data(null));
  
  /// 게시글 작성
  Future<String?> createPost({
    required CommunityCategory category,
    required String content,
    List<String> imageUrls = const [],
    String? videoUrl,
    String? videoThumbnailUrl,
    List<String> tags = const [],
    bool isAnonymous = false,
    String? location,
    GeoPoint? geoPoint,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      final userId = _firebase.currentUserId;
      if (userId == null) throw Exception('로그인이 필요합니다');
      
      // 사용자 정보 가져오기
      final userDoc = await _firebase.usersCollection.doc(userId).get();
      final userData = userDoc.data();
      
      final now = DateTime.now();
      final docRef = _firebase.feedPostsCollection.doc();
      
      final post = CommunityPostModel(
        id: docRef.id,
        authorId: userId,
        authorName: userData?['nickname'] ?? '사용자',
        authorProfileUrl: userData?['profileImageUrl'],
        category: category,
        content: content,
        imageUrls: imageUrls,
        videoUrl: videoUrl,
        videoThumbnailUrl: videoThumbnailUrl,
        tags: tags,
        isAnonymous: isAnonymous,
        location: location,
        geoPoint: geoPoint,
        createdAt: now,
        updatedAt: now,
      );
      
      await docRef.set(post.toFirestore());
      
      state = const AsyncValue.data(null);
      return docRef.id;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
  
  /// 게시글 수정
  Future<bool> updatePost({
    required String postId,
    required String content,
    List<String>? imageUrls,
    String? videoUrl,
    String? videoThumbnailUrl,
    List<String>? tags,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      final updateData = <String, dynamic>{
        'content': content,
        'updatedAt': Timestamp.now(),
      };
      
      if (imageUrls != null) updateData['imageUrls'] = imageUrls;
      if (videoUrl != null) updateData['videoUrl'] = videoUrl;
      if (videoThumbnailUrl != null) updateData['videoThumbnailUrl'] = videoThumbnailUrl;
      if (tags != null) updateData['tags'] = tags;
      
      await _firebase.feedPostsCollection.doc(postId).update(updateData);
      
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
  
  /// 게시글 삭제
  Future<bool> deletePost(String postId) async {
    state = const AsyncValue.loading();
    
    try {
      // 게시글 삭제
      await _firebase.feedPostsCollection.doc(postId).delete();
      
      // 관련 댓글 삭제
      final comments = await _firebase.feedCommentsCollection
          .where('postId', isEqualTo: postId)
          .get();
      for (final doc in comments.docs) {
        await doc.reference.delete();
      }
      
      // 관련 좋아요 삭제
      final likes = await _firebase.feedLikesCollection
          .where('postId', isEqualTo: postId)
          .get();
      for (final doc in likes.docs) {
        await doc.reference.delete();
      }
      
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
  
  /// 좋아요 토글
  Future<bool> toggleLike(String postId) async {
    try {
      final userId = _firebase.currentUserId;
      if (userId == null) return false;
      
      final likeId = '${userId}_$postId';
      final likeDoc = await _firebase.feedLikesCollection.doc(likeId).get();
      
      if (likeDoc.exists) {
        // 좋아요 취소
        await _firebase.feedLikesCollection.doc(likeId).delete();
        await _firebase.feedPostsCollection.doc(postId).update({
          'likeCount': FieldValue.increment(-1),
        });
        return false;
      } else {
        // 좋아요 추가
        await _firebase.feedLikesCollection.doc(likeId).set({
          'userId': userId,
          'postId': postId,
          'createdAt': FieldValue.serverTimestamp(),
        });
        await _firebase.feedPostsCollection.doc(postId).update({
          'likeCount': FieldValue.increment(1),
        });
        return true;
      }
    } catch (e) {
      return false;
    }
  }
  
  /// 조회수 증가
  Future<void> incrementViewCount(String postId) async {
    try {
      await _firebase.feedPostsCollection.doc(postId).update({
        'viewCount': FieldValue.increment(1),
      });
    } catch (_) {}
  }
  
  /// 댓글 작성
  Future<String?> createComment({
    required String postId,
    required String content,
    String? parentId,
    bool isAnonymous = false,
  }) async {
    try {
      final userId = _firebase.currentUserId;
      if (userId == null) return null;
      
      final userDoc = await _firebase.usersCollection.doc(userId).get();
      final userData = userDoc.data();
      
      final docRef = _firebase.feedCommentsCollection.doc();
      
      final comment = CommunityCommentModel(
        id: docRef.id,
        postId: postId,
        authorId: userId,
        authorName: userData?['nickname'] ?? '사용자',
        authorProfileUrl: userData?['profileImageUrl'],
        content: content,
        parentId: parentId,
        isAnonymous: isAnonymous,
        createdAt: DateTime.now(),
      );
      
      await docRef.set(comment.toFirestore());
      
      // 게시글 댓글 수 증가
      await _firebase.feedPostsCollection.doc(postId).update({
        'commentCount': FieldValue.increment(1),
      });
      
      return docRef.id;
    } catch (e) {
      return null;
    }
  }
  
  /// 댓글 삭제
  Future<bool> deleteComment(String commentId, String postId) async {
    try {
      await _firebase.feedCommentsCollection.doc(commentId).delete();
      
      // 게시글 댓글 수 감소
      await _firebase.feedPostsCollection.doc(postId).update({
        'commentCount': FieldValue.increment(-1),
      });
      
      return true;
    } catch (e) {
      return false;
    }
  }
}

/// 커뮤니티 Notifier Provider
final communityNotifierProvider = StateNotifierProvider<CommunityNotifier, AsyncValue<void>>((ref) {
  return CommunityNotifier(ref);
});

/// 커뮤니티 게시글 좋아요 여부 확인
final isCommunityPostLikedProvider = FutureProvider.autoDispose.family<bool, String>((ref, postId) async {
  final firebase = FirebaseService();
  final userId = firebase.currentUserId;
  if (userId == null) return false;
  
  final likeId = '${userId}_$postId';
  final doc = await firebase.feedLikesCollection.doc(likeId).get();
  return doc.exists;
});
