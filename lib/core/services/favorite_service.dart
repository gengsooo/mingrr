import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/pet_model.dart';
import '../../models/marketplace_model.dart';
import '../../models/group_model.dart';
import 'firebase_service.dart';

/// ============================================================
/// 찜 서비스
/// 
/// 기능:
/// - 반려동물 찜하기/취소
/// - 상품 찜하기/취소
/// - 소모임 찜하기/취소
/// - 찜 목록 조회
/// ============================================================
class FavoriteService {
  final FirebaseService _firebase = FirebaseService();
  
  FirebaseFirestore get _firestore => _firebase.firestore;
  
  // ===== 컬렉션 참조 =====
  
  CollectionReference<Map<String, dynamic>> get _favoritesCollection =>
      _firestore.collection('favorites');
  
  // ===== 반려동물 찜 =====
  
  /// 반려동물 찜하기
  Future<void> favoritePet(String petId) async {
    final userId = _firebase.currentUserId;
    if (userId == null) throw Exception('로그인이 필요합니다');
    
    final favoriteId = '${userId}_pet_$petId';
    
    await _favoritesCollection.doc(favoriteId).set({
      'userId': userId,
      'targetId': petId,
      'targetType': 'pet',
      'createdAt': Timestamp.fromDate(DateTime.now()),
    });
    
    // 펫 좋아요 수 증가
    await _firebase.petsCollection.doc(petId).update({
      'likeCount': FieldValue.increment(1),
    });
  }
  
  /// 반려동물 찜 취소
  Future<void> unfavoritePet(String petId) async {
    final userId = _firebase.currentUserId;
    if (userId == null) throw Exception('로그인이 필요합니다');
    
    final favoriteId = '${userId}_pet_$petId';
    
    await _favoritesCollection.doc(favoriteId).delete();
    
    // 펫 좋아요 수 감소
    await _firebase.petsCollection.doc(petId).update({
      'likeCount': FieldValue.increment(-1),
    });
  }
  
  /// 반려동물 찜 여부 확인
  Future<bool> isPetFavorited(String petId) async {
    final userId = _firebase.currentUserId;
    if (userId == null) return false;
    
    final favoriteId = '${userId}_pet_$petId';
    final doc = await _favoritesCollection.doc(favoriteId).get();
    return doc.exists;
  }
  
  /// 찜한 반려동물 목록 조회
  Future<List<PetModel>> getFavoritePets() async {
    final userId = _firebase.currentUserId;
    if (userId == null) return [];
    
    final snapshot = await _favoritesCollection
        .where('userId', isEqualTo: userId)
        .where('targetType', isEqualTo: 'pet')
        .orderBy('createdAt', descending: true)
        .get();
    
    final petIds = snapshot.docs.map((doc) => doc.data()['targetId'] as String).toList();
    
    if (petIds.isEmpty) return [];
    
    // 펫 정보 조회
    final pets = <PetModel>[];
    for (final petId in petIds) {
      final petDoc = await _firebase.petsCollection.doc(petId).get();
      if (petDoc.exists) {
        pets.add(PetModel.fromFirestore(petDoc));
      }
    }
    
    return pets;
  }
  
  /// 찜한 반려동물 목록 스트림
  Stream<List<String>> watchFavoritePetIds() {
    final userId = _firebase.currentUserId;
    if (userId == null) return Stream.value([]);
    
    return _favoritesCollection
        .where('userId', isEqualTo: userId)
        .where('targetType', isEqualTo: 'pet')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => doc.data()['targetId'] as String)
            .toList());
  }
  
  // ===== 상품 찜 =====
  
  /// 상품 찜하기
  Future<void> favoriteProduct(String productId) async {
    final userId = _firebase.currentUserId;
    if (userId == null) throw Exception('로그인이 필요합니다');
    
    final favoriteId = '${userId}_product_$productId';
    
    await _favoritesCollection.doc(favoriteId).set({
      'userId': userId,
      'targetId': productId,
      'targetType': 'product',
      'createdAt': Timestamp.fromDate(DateTime.now()),
    });
    
    // 상품 좋아요 수 증가
    await _firebase.productsCollection.doc(productId).update({
      'likeCount': FieldValue.increment(1),
    });
  }
  
  /// 상품 찜 취소
  Future<void> unfavoriteProduct(String productId) async {
    final userId = _firebase.currentUserId;
    if (userId == null) throw Exception('로그인이 필요합니다');
    
    final favoriteId = '${userId}_product_$productId';
    
    await _favoritesCollection.doc(favoriteId).delete();
    
    // 상품 좋아요 수 감소
    await _firebase.productsCollection.doc(productId).update({
      'likeCount': FieldValue.increment(-1),
    });
  }
  
  /// 상품 찜 여부 확인
  Future<bool> isProductFavorited(String productId) async {
    final userId = _firebase.currentUserId;
    if (userId == null) return false;
    
    final favoriteId = '${userId}_product_$productId';
    final doc = await _favoritesCollection.doc(favoriteId).get();
    return doc.exists;
  }
  
  /// 찜한 상품 목록 조회
  Future<List<ProductModel>> getFavoriteProducts() async {
    final userId = _firebase.currentUserId;
    if (userId == null) return [];
    
    final snapshot = await _favoritesCollection
        .where('userId', isEqualTo: userId)
        .where('targetType', isEqualTo: 'product')
        .orderBy('createdAt', descending: true)
        .get();
    
    final productIds = snapshot.docs.map((doc) => doc.data()['targetId'] as String).toList();
    
    if (productIds.isEmpty) return [];
    
    final products = <ProductModel>[];
    for (final productId in productIds) {
      final productDoc = await _firebase.productsCollection.doc(productId).get();
      if (productDoc.exists) {
        products.add(ProductModel.fromFirestore(productDoc.data()!, id: productDoc.id));
      }
    }
    
    return products;
  }
  
  /// 찜한 상품 ID 목록 스트림
  Stream<List<String>> watchFavoriteProductIds() {
    final userId = _firebase.currentUserId;
    if (userId == null) return Stream.value([]);
    
    return _favoritesCollection
        .where('userId', isEqualTo: userId)
        .where('targetType', isEqualTo: 'product')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => doc.data()['targetId'] as String)
            .toList());
  }
  
  // ===== 소모임 찜 =====
  
  /// 소모임 찜하기
  Future<void> favoriteGroup(String groupId) async {
    final userId = _firebase.currentUserId;
    if (userId == null) throw Exception('로그인이 필요합니다');
    
    final favoriteId = '${userId}_group_$groupId';
    
    await _favoritesCollection.doc(favoriteId).set({
      'userId': userId,
      'targetId': groupId,
      'targetType': 'group',
      'createdAt': Timestamp.fromDate(DateTime.now()),
    });
    
    // 소모임 좋아요 수 증가
    await _firebase.groupsCollection.doc(groupId).update({
      'likeCount': FieldValue.increment(1),
    });
  }
  
  /// 소모임 찜 취소
  Future<void> unfavoriteGroup(String groupId) async {
    final userId = _firebase.currentUserId;
    if (userId == null) throw Exception('로그인이 필요합니다');
    
    final favoriteId = '${userId}_group_$groupId';
    
    await _favoritesCollection.doc(favoriteId).delete();
    
    // 소모임 좋아요 수 감소
    await _firebase.groupsCollection.doc(groupId).update({
      'likeCount': FieldValue.increment(-1),
    });
  }
  
  /// 소모임 찜 여부 확인
  Future<bool> isGroupFavorited(String groupId) async {
    final userId = _firebase.currentUserId;
    if (userId == null) return false;
    
    final favoriteId = '${userId}_group_$groupId';
    final doc = await _favoritesCollection.doc(favoriteId).get();
    return doc.exists;
  }
  
  /// 찜한 소모임 목록 조회
  Future<List<GroupModel>> getFavoriteGroups() async {
    final userId = _firebase.currentUserId;
    if (userId == null) return [];
    
    final snapshot = await _favoritesCollection
        .where('userId', isEqualTo: userId)
        .where('targetType', isEqualTo: 'group')
        .orderBy('createdAt', descending: true)
        .get();
    
    final groupIds = snapshot.docs.map((doc) => doc.data()['targetId'] as String).toList();
    
    if (groupIds.isEmpty) return [];
    
    final groups = <GroupModel>[];
    for (final groupId in groupIds) {
      final groupDoc = await _firebase.groupsCollection.doc(groupId).get();
      if (groupDoc.exists) {
        groups.add(GroupModel.fromFirestore(groupDoc.data()!, id: groupDoc.id));
      }
    }
    
    return groups;
  }
  
  /// 찜한 소모임 ID 목록 스트림
  Stream<List<String>> watchFavoriteGroupIds() {
    final userId = _firebase.currentUserId;
    if (userId == null) return Stream.value([]);
    
    return _favoritesCollection
        .where('userId', isEqualTo: userId)
        .where('targetType', isEqualTo: 'group')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => doc.data()['targetId'] as String)
            .toList());
  }
  
  // ===== 토글 메서드 =====
  
  /// 반려동물 찜 토글
  Future<bool> togglePetFavorite(String petId) async {
    final isFavorited = await isPetFavorited(petId);
    if (isFavorited) {
      await unfavoritePet(petId);
      return false;
    } else {
      await favoritePet(petId);
      return true;
    }
  }
  
  /// 상품 찜 토글
  Future<bool> toggleProductFavorite(String productId) async {
    final isFavorited = await isProductFavorited(productId);
    if (isFavorited) {
      await unfavoriteProduct(productId);
      return false;
    } else {
      await favoriteProduct(productId);
      return true;
    }
  }
  
  /// 소모임 찜 토글
  Future<bool> toggleGroupFavorite(String groupId) async {
    final isFavorited = await isGroupFavorited(groupId);
    if (isFavorited) {
      await unfavoriteGroup(groupId);
      return false;
    } else {
      await favoriteGroup(groupId);
      return true;
    }
  }
}
