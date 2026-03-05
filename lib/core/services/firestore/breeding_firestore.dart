import '../../../models/breeding_model.dart';
import '../../utils/app_logger.dart';
import 'firestore_base.dart';

/// 교배(Breeding) 도메인 Firestore CRUD mixin
mixin BreedingFirestore on FirestoreBase {

  /// 교배 글 생성
  Future<void> createBreedingPost(BreedingPostModel post) async {
    try {
      await firebase.breedingPostsCollection.doc(post.id).set(post.toFirestore());
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'createBreedingPost (postId: ${post.id})', e);
      rethrow;
    }
  }

  /// 교배 글 조회
  Future<BreedingPostModel?> getBreedingPost(String postId) async {
    try {
      final doc = await firebase.breedingPostsCollection.doc(postId).get();
      if (!doc.exists) return null;
      return BreedingPostModel.fromFirestore(doc.data()!, id: doc.id);
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'getBreedingPost (postId: $postId)', e);
      rethrow;
    }
  }

  /// 교배 글 수정
  Future<void> updateBreedingPost(BreedingPostModel post) async {
    try {
      await firebase.breedingPostsCollection.doc(post.id).update(post.toFirestore());
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'updateBreedingPost (postId: ${post.id})', e);
      rethrow;
    }
  }

  /// 교배 글 삭제
  Future<void> deleteBreedingPost(String postId) async {
    try {
      await firebase.breedingPostsCollection.doc(postId).delete();
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'deleteBreedingPost (postId: $postId)', e);
      rethrow;
    }
  }

  /// 활성 교배 글 목록 조회
  Future<List<BreedingPostModel>> getActiveBreedingPosts({int limit = 20}) async {
    try {
      final snapshot = await firebase.breedingPostsCollection
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => BreedingPostModel.fromFirestore(doc.data(), id: doc.id))
          .toList();
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'getActiveBreedingPosts', e);
      rethrow;
    }
  }
}
