import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/community_post_model.dart';
import 'firestore_base.dart';

/// 커뮤니티(Community) 도메인 Firestore mixin
mixin CommunityFirestore on FirestoreBase {

  /// 커뮤니티 게시글 조회 (서버 사이드 필터링 + 페이지네이션)
  Future<({List<CommunityPostModel> items, DocumentSnapshot? lastDoc, bool hasMore})> 
      getCommunityPostsPaginated({
    CommunityCategory? category,
    DocumentSnapshot? lastDocument,
    int limit = 20,
  }) async {
    try {
      Query<Map<String, dynamic>> query = firebase.feedPostsCollection;
      
      // 서버 사이드 필터링
      if (category != null) {
        query = query.where('category', isEqualTo: category.name);
      }
      
      query = query.orderBy('createdAt', descending: true);
      
      // 페이지네이션
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }
      
      final snapshot = await query.limit(limit + 1).get();
      final hasMore = snapshot.docs.length > limit;
      final docs = hasMore ? snapshot.docs.take(limit).toList() : snapshot.docs;
      
      return (
        items: docs.map((doc) => CommunityPostModel.fromFirestore(doc.data(), id: doc.id)).toList(),
        lastDoc: docs.isNotEmpty ? docs.last : null,
        hasMore: hasMore,
      );
    } catch (e) {
      rethrow;
    }
  }
}
