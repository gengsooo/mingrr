import '../../../models/marketplace_model.dart';
import '../../../models/group_model.dart';
import '../../../models/breeding_model.dart';
import '../../../models/community_post_model.dart';
import '../../utils/app_logger.dart';
import 'firestore_base.dart';

/// 검색(Search) 도메인 Firestore mixin
/// 
/// 상품, 소모임, 알바, 교배글, 커뮤니티 게시글의 통합 검색을 담당합니다.
/// Firestore는 전문 검색을 지원하지 않으므로 클라이언트 사이드 필터링을 사용합니다.
mixin SearchFirestore on FirestoreBase {

  /// 상품 검색
  Future<List<ProductModel>> searchProducts(String query) async {
    try {
      // 데이터베이스는 전문 검색을 지원하지 않으므로 제목 기반 검색
      final snapshot = await firebase.productsCollection
          .where('status', isEqualTo: 'available')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();
      
      final lowerQuery = query.toLowerCase();
      return snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc.data(), id: doc.id))
          .where((p) => 
              p.title.toLowerCase().contains(lowerQuery) ||
              p.description.toLowerCase().contains(lowerQuery))
          .toList();
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'searchProducts (query: $query)', e);
      rethrow;
    }
  }

  /// 소모임 검색
  Future<List<GroupModel>> searchGroups(String query) async {
    try {
      final snapshot = await firebase.groupsCollection
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();
      
      final lowerQuery = query.toLowerCase();
      return snapshot.docs
          .map((doc) => GroupModel.fromFirestore(doc.data(), id: doc.id))
          .where((g) => 
              g.name.toLowerCase().contains(lowerQuery) ||
              g.description.toLowerCase().contains(lowerQuery) ||
              g.tags.any((t) => t.toLowerCase().contains(lowerQuery)))
          .toList();
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'searchGroups (query: $query)', e);
      rethrow;
    }
  }

  /// 알바 검색
  Future<List<JobModel>> searchJobs(String query) async {
    try {
      final snapshot = await firebase.jobsCollection
          .where('status', isEqualTo: 'recruiting')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();
      
      final lowerQuery = query.toLowerCase();
      return snapshot.docs
          .map((doc) => JobModel.fromFirestore(doc.data(), id: doc.id))
          .where((j) => 
              j.title.toLowerCase().contains(lowerQuery) ||
              j.description.toLowerCase().contains(lowerQuery))
          .toList();
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'searchJobs (query: $query)', e);
      rethrow;
    }
  }

  /// 마켓 통합 검색 (상품 + 알바)
  /// 상품과 알바를 병렬로 검색하여 최신순으로 정렬된 결과 반환
  Future<List<dynamic>> searchMarketAll(String query) async {
    try {
      // 상품과 알바를 병렬로 검색
      final results = await Future.wait([
        searchProducts(query),
        searchJobs(query),
      ]);
      
      final products = results[0] as List<ProductModel>;
      final jobs = results[1] as List<JobModel>;
      
      // 통합 후 최신순 정렬
      final combined = <dynamic>[...products, ...jobs];
      combined.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return combined;
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'searchMarketAll (query: $query)', e);
      rethrow;
    }
  }

  /// 교배 글 검색
  Future<List<BreedingPostModel>> searchBreedingPosts(String query) async {
    try {
      final snapshot = await firebase.breedingPostsCollection
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();
      
      final lowerQuery = query.toLowerCase();
      return snapshot.docs
          .map((doc) => BreedingPostModel.fromFirestore(doc.data(), id: doc.id))
          .where((p) => 
              p.title.toLowerCase().contains(lowerQuery) ||
              p.description.toLowerCase().contains(lowerQuery))
          .toList();
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'searchBreedingPosts (query: $query)', e);
      rethrow;
    }
  }

  /// 커뮤니티 게시글 검색
  Future<List<CommunityPostModel>> searchCommunityPosts(String query) async {
    try {
      final snapshot = await firebase.feedPostsCollection
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();
      
      final lowerQuery = query.toLowerCase();
      return snapshot.docs
          .map((doc) => CommunityPostModel.fromFirestore(doc.data(), id: doc.id))
          .where((p) => 
              p.title.toLowerCase().contains(lowerQuery) ||
              p.content.toLowerCase().contains(lowerQuery) ||
              p.tags.any((t) => t.toLowerCase().contains(lowerQuery)))
          .toList();
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'searchCommunityPosts (query: $query)', e);
      rethrow;
    }
  }
}
