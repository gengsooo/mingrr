import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/marketplace_model.dart';
import '../../utils/app_logger.dart';
import '../geohash_service.dart';
import '../transaction_service.dart';
import 'firestore_base.dart';

/// 상품/마켓플레이스(Product) 도메인 Firestore CRUD mixin
mixin ProductFirestore on FirestoreBase {

  Future<void> createProduct(ProductModel product) async {
    try {
      await firebase.productsCollection.doc(product.id).set(product.toFirestore());
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'createProduct (productId: ${product.id})', e);
      rethrow;
    }
  }
  
  Future<ProductModel?> getProduct(String productId) async {
    try {
      final doc = await firebase.productsCollection.doc(productId).get();
      if (!doc.exists) return null;
      return ProductModel.fromFirestore(doc.data()!, id: doc.id);
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'getProduct (productId: $productId)', e);
      rethrow;
    }
  }
  
  Future<void> updateProduct(ProductModel product) async {
    try {
      await firebase.productsCollection.doc(product.id).update(product.toFirestore());
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'updateProduct (productId: ${product.id})', e);
      rethrow;
    }
  }
  
  Future<void> deleteProduct(String productId) async {
    try {
      await firebase.productsCollection.doc(productId).delete();
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'deleteProduct (productId: $productId)', e);
      rethrow;
    }
  }
  
  Future<List<ProductModel>> getProducts({
    ProductStatus? status,
    ProductCategory? category,
    ProductType? type,
    int limit = 20,
  }) async {
    try {
      Query<Map<String, dynamic>> query = firebase.productsCollection;
      
      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }
      
      if (type != null) {
        query = query.where('type', isEqualTo: type.name);
      }
      
      if (category != null) {
        query = query.where('category', isEqualTo: category.name);
      }
      
      final snapshot = await query
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc.data(), id: doc.id))
          .toList();
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'getProducts', e);
      rethrow;
    }
  }

  Future<void> incrementProductViewCount(String productId) async {
    try {
      await firebase.productsCollection.doc(productId).update({
        'viewCount': FieldValue.increment(1),
      });
    } catch (e) {
      AppLogger.dbError('FirestoreService', 'incrementProductViewCount (productId: $productId)', e);
      rethrow;
    }
  }

  // ===== 상품 찜(북마크) 관련 =====

  /// 상품 찜하기 토글 (TransactionService 위임)
  /// Returns: true = 찜 추가됨, false = 찜 해제됨
  Future<bool> toggleProductLike(String productId, String userId) async {
    return TransactionService.toggleProductLike(
      productId: productId,
      userId: userId,
    );
  }

  /// 상품 찜 여부 확인
  Future<bool> isProductLiked(String productId, String userId) async {
    try {
      final likeId = '${userId}_$productId';
      final doc = await firebase.productLikesCollection.doc(likeId).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// 사용자가 찜한 상품 ID 목록
  Future<List<String>> getUserLikedProductIds(String userId) async {
    try {
      final snapshot = await firebase.productLikesCollection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map((doc) => doc.data()['productId'] as String).toList();
    } catch (e) {
      return [];
    }
  }

  /// 사용자가 찜한 상품 목록 조회
  Future<List<ProductModel>> getUserLikedProducts(String userId) async {
    try {
      final productIds = await getUserLikedProductIds(userId);
      if (productIds.isEmpty) return [];
      
      final products = <ProductModel>[];
      for (final id in productIds) {
        final product = await getProduct(id);
        if (product != null) {
          products.add(product);
        }
      }
      return products;
    } catch (e) {
      return [];
    }
  }

  /// 찜한 상품 ID 목록 스트림
  Stream<List<String>> watchUserLikedProductIds(String userId) {
    return firebase.productLikesCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => doc.data()['productId'] as String)
            .toList());
  }

  // ===== 서버 사이드 필터링 + 페이지네이션 =====

  /// 상품 목록 조회 (서버 사이드 필터링 + 페이지네이션)
  Future<({List<ProductModel> items, DocumentSnapshot? lastDoc, bool hasMore})> 
      getProductsPaginated({
    ProductType? type,
    ProductStatus? status,
    DocumentSnapshot? lastDocument,
    int limit = 20,
  }) async {
    try {
      Query<Map<String, dynamic>> query = firebase.productsCollection;
      
      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }
      if (type != null) {
        query = query.where('type', isEqualTo: type.name);
      }
      
      query = query.orderBy('createdAt', descending: true);
      
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }
      
      final snapshot = await query.limit(limit + 1).get();
      final hasMore = snapshot.docs.length > limit;
      final docs = hasMore ? snapshot.docs.take(limit).toList() : snapshot.docs;
      
      return (
        items: docs.map((doc) => ProductModel.fromFirestore(doc.data(), id: doc.id)).toList(),
        lastDoc: docs.isNotEmpty ? docs.last : null,
        hasMore: hasMore,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// GeoHash 기반 상품 검색 (반경 내)
  Future<List<ProductModel>> getProductsByGeohash({
    required String centerGeohash,
    required double radiusKm,
    ProductType? type,
    ProductStatus? status,
  }) async {
    try {
      // GeoHash prefix 기반 범위 쿼리
      final precision = radiusKm <= 1 ? 6 : (radiusKm <= 5 ? 5 : 4);
      final prefix = centerGeohash.substring(0, precision);
      
      Query<Map<String, dynamic>> query = firebase.productsCollection
          .where('geohash', isGreaterThanOrEqualTo: prefix)
          .where('geohash', isLessThan: '$prefix~');
      
      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }
      
      final snapshot = await query.get();
      
      var products = snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc.data(), id: doc.id))
          .toList();
      
      // 타입 필터 (클라이언트 사이드 - 복합 인덱스 제한)
      if (type != null) {
        products = products.where((p) => p.type == type).toList();
      }
      
      return products;
    } catch (e) {
      rethrow;
    }
  }

  /// 상품 GeoHash 업데이트
  Future<void> updateProductGeohash(String productId, GeoPoint location) async {
    try {
      final geohash = GeoHashService.encodeGeoPoint(location);
      await firebase.productsCollection.doc(productId).update({
        'geohash': geohash,
        'location': location,
      });
    } catch (e) {
      rethrow;
    }
  }
}
