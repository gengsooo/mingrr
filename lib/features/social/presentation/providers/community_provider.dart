import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/paginated_state.dart';
import '../../../../core/providers/block_provider.dart';
import '../../../../core/providers/paginated_provider.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/kkosunnae_service.dart';
import '../../../../core/services/transaction_service.dart';
import '../../../../core/utils/input_sanitizer.dart';
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

/// 커뮤니티 게시글 목록 (카테고리 필터, 차단된 사용자 제외)
final communityPostsProvider = FutureProvider.autoDispose.family<List<CommunityPostModel>, CommunityCategory?>((ref, category) async {
  // 캐시 유지 - 자주 사용되는 데이터이므로 자동 해제 방지
  ref.keepAlive();
  
  final firebase = FirebaseService();
  final blockedUserIds = ref.watch(blockedUserIdsProvider).valueOrNull ?? [];
  
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
  final posts = snapshot.docs
      .map((doc) => CommunityPostModel.fromFirestore(doc.data(), id: doc.id))
      .toList();
  
  // 차단된 사용자 게시글 제외
  return posts.where((post) => !blockedUserIds.contains(post.authorId)).toList();
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
    required String title,
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
      
      // 입력 정화 (XSS/Injection 방지)
      final sanitizedTitle = InputSanitizer.sanitizePostTitle(title);
      final sanitizedContent = InputSanitizer.sanitizePostContent(content);
      
      final post = CommunityPostModel(
        id: docRef.id,
        authorId: userId,
        authorName: userData?['nickname'] ?? '사용자',
        authorProfileUrl: userData?['profileImageUrl'],
        category: category,
        title: sanitizedTitle,
        content: sanitizedContent,
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
      
      // 게시글 수 카운터 증가
      await _firebase.usersCollection.doc(userId).update({
        'postCount': FieldValue.increment(1),
      });
      
      // 꼬순내 점수 업데이트 (커뮤니티 활동 반영)
      KkosunnaeService.updateScore(userId);
      
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
    required String title,
    required String content,
    List<String>? imageUrls,
    String? videoUrl,
    String? videoThumbnailUrl,
    List<String>? tags,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      // 입력 정화 (XSS/Injection 방지)
      final sanitizedTitle = InputSanitizer.sanitizePostTitle(title);
      final sanitizedContent = InputSanitizer.sanitizePostContent(content);
      
      final updateData = <String, dynamic>{
        'title': sanitizedTitle,
        'content': sanitizedContent,
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
      final userId = _firebase.currentUserId;
      
      // 게시글 삭제
      await _firebase.feedPostsCollection.doc(postId).delete();
      
      // 게시글 수 카운터 감소
      if (userId != null) {
        await _firebase.usersCollection.doc(userId).update({
          'postCount': FieldValue.increment(-1),
        });
      }
      
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
  
  /// 좋아요 토글 (트랜잭션으로 Race Condition 방지)
  Future<bool> toggleLike(String postId) async {
    try {
      final userId = _firebase.currentUserId;
      if (userId == null) return false;
      
      return await TransactionService.togglePostLike(
        postId: postId,
        userId: userId,
      );
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
      
      // 꼬순내 점수 업데이트 (커뮤니티 활동 반영)
      KkosunnaeService.updateScore(userId);
      
      return docRef.id;
    } catch (e) {
      return null;
    }
  }
  
  /// 댓글 삭제 (트랜잭션으로 Race Condition 방지)
  Future<bool> deleteComment(String commentId, String postId) async {
    try {
      await TransactionService.deleteComment(
        commentId: commentId,
        postId: postId,
      );
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

/// ============================================================
/// 페이지네이션 커뮤니티 게시글 Provider
/// 
/// 서버 사이드 필터링 + 커서 기반 무한 스크롤 + 캐싱
/// - 카테고리별 서버 필터링
/// - 차단된 사용자 제외
/// - 20개씩 로드
/// - keepAlive로 화면 전환 시 상태 유지
/// ============================================================

const int _communityPageSize = 20;

/// 페이지네이션 커뮤니티 게시글 Provider (카테고리별)
final paginatedCommunityPostsProvider = StateNotifierProvider
    .family<PaginatedNotifier<CommunityPostModel>, PaginatedState<CommunityPostModel>, CommunityCategory?>((ref, category) {
  // 캐싱: 화면 전환 시 상태 유지 (5분 후 자동 해제)
  final link = ref.keepAlive();
  Future.delayed(const Duration(minutes: 5), () => link.close());
  
  final blockedUserIds = ref.watch(blockedUserIdsProvider).valueOrNull ?? [];
  
  return PaginatedNotifier<CommunityPostModel>(
    pageSize: _communityPageSize,
    fetchPage: (lastDocument, pageSize) async {
      final firebase = FirebaseService();
      
      // 서버 사이드 필터링
      Query<Map<String, dynamic>> query = firebase.feedPostsCollection;
      
      if (category != null) {
        query = query.where('category', isEqualTo: category.name);
      }
      
      query = query.orderBy('createdAt', descending: true);
      
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }
      
      query = query.limit(pageSize);
      
      final snapshot = await query.get();
      
      // 차단된 사용자 게시글 제외 (클라이언트 사이드)
      final posts = snapshot.docs
          .map((doc) => CommunityPostModel.fromFirestore(doc.data(), id: doc.id))
          .where((post) => !blockedUserIds.contains(post.authorId))
          .toList();
      
      return PaginatedResult<CommunityPostModel>(
        items: posts,
        lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
        hasMore: snapshot.docs.length >= pageSize,
      );
    },
  );
});
