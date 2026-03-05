import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../models/pet_model.dart';
import '../../models/marketplace_model.dart';
import '../../models/group_model.dart';
import '../../models/notification_model.dart';
import 'firebase_service.dart';
import 'transaction_service.dart';

/// ============================================================
/// 찜(좋아요) 서비스
/// 
/// 기능:
/// - 반려동물 좋아요/취소 + 알림 발송
/// - 상품 찜하기/취소
/// - 소모임 찜하기/취소
/// - 찜 목록 조회
/// ============================================================
class FavoriteService {
  final FirebaseService _firebase = FirebaseService();
  final _uuid = const Uuid();
  
  FirebaseFirestore get _firestore => _firebase.firestore;
  
  // ===== 컬렉션 참조 =====
  
  CollectionReference<Map<String, dynamic>> get _favoritesCollection =>
      _firestore.collection('favorites');
  
  // ===== 반려동물 좋아요 =====
  
  /// 반려동물 좋아요 (알림 발송 포함)
  Future<void> likePet(String petId) async {
    final userId = _firebase.currentUserId;
    if (userId == null) throw Exception('로그인이 필요합니다');
    
    // TransactionService로 좋아요 처리 (트랜잭션 보장)
    await TransactionService.togglePetLike(
      petId: petId,
      userId: userId,
    );
    
    // 반려동물 주인에게 알림 발송
    await _sendPetLikeNotification(petId, userId);
  }
  
  /// 반려동물 좋아요 알림 발송
  Future<void> _sendPetLikeNotification(String petId, String likerId) async {
    // 반려동물 정보 조회
    final petDoc = await _firebase.petsCollection.doc(petId).get();
    if (!petDoc.exists) return;
    
    final petData = petDoc.data()!;
    final ownerId = petData['ownerId'] as String?;
    final petName = petData['name'] as String? ?? '반려동물';
    
    // 자기 자신의 반려동물이면 알림 X
    if (ownerId == null || ownerId == likerId) return;
    
    // 좋아요 누른 사용자 정보 조회
    final likerDoc = await _firebase.usersCollection.doc(likerId).get();
    final likerName = likerDoc.exists 
        ? (likerDoc.data()!['nickname'] as String? ?? '누군가')
        : '누군가';
    
    // 알림 발송
    final notificationId = _uuid.v4();
    await _firestore.collection('notifications').doc(notificationId).set({
      'userId': ownerId,
      'type': NotificationType.petLike.name,
      'title': '$petName이(가) 관심을 받았어요!',
      'body': '$likerName님이 좋아요를 눌렀어요',
      'data': {
        'targetId': petId,
        'targetType': 'pet',
        'likerId': likerId,
      },
      'isRead': false,
      'createdAt': Timestamp.fromDate(DateTime.now()),
    });
  }
  
  /// 반려동물 좋아요 취소
  Future<void> unlikePet(String petId) async {
    final userId = _firebase.currentUserId;
    if (userId == null) throw Exception('로그인이 필요합니다');
    
    // TransactionService로 좋아요 취소 처리 (트랜잭션 보장)
    await TransactionService.togglePetLike(
      petId: petId,
      userId: userId,
    );
  }
  
  /// 반려동물 좋아요 여부 확인
  Future<bool> isPetLiked(String petId) async {
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
  
  /// 상품 찜 토글 (트랜잭션으로 Race Condition 방지)
  Future<bool> toggleProductFavorite(String productId) async {
    final userId = _firebase.currentUserId;
    if (userId == null) throw Exception('로그인이 필요합니다');
    
    return await TransactionService.toggleProductLike(
      productId: productId,
      userId: userId,
    );
  }
  
  /// 상품 찜하기 (하위 호환성 유지)
  Future<void> favoriteProduct(String productId) async {
    final userId = _firebase.currentUserId;
    if (userId == null) throw Exception('로그인이 필요합니다');
    
    final isLiked = await isProductFavorited(productId);
    if (!isLiked) {
      await toggleProductFavorite(productId);
    }
  }
  
  /// 상품 찜 취소 (하위 호환성 유지)
  Future<void> unfavoriteProduct(String productId) async {
    final userId = _firebase.currentUserId;
    if (userId == null) throw Exception('로그인이 필요합니다');
    
    final isLiked = await isProductFavorited(productId);
    if (isLiked) {
      await toggleProductFavorite(productId);
    }
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
  
  /// 소모임 찜 토글 (트랜잭션으로 Race Condition 방지)
  Future<bool> toggleGroupFavorite(String groupId) async {
    final userId = _firebase.currentUserId;
    if (userId == null) throw Exception('로그인이 필요합니다');
    
    return await TransactionService.toggleGroupLike(
      groupId: groupId,
      userId: userId,
    );
  }
  
  /// 소모임 찜하기 (하위 호환성 유지)
  Future<void> favoriteGroup(String groupId) async {
    final userId = _firebase.currentUserId;
    if (userId == null) throw Exception('로그인이 필요합니다');
    
    final isLiked = await isGroupFavorited(groupId);
    if (!isLiked) {
      await toggleGroupFavorite(groupId);
    }
  }
  
  /// 소모임 찜 취소 (하위 호환성 유지)
  Future<void> unfavoriteGroup(String groupId) async {
    final userId = _firebase.currentUserId;
    if (userId == null) throw Exception('로그인이 필요합니다');
    
    final isLiked = await isGroupFavorited(groupId);
    if (isLiked) {
      await toggleGroupFavorite(groupId);
    }
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
  
  /// 반려동물 좋아요 토글
  Future<bool> togglePetLike(String petId) async {
    final userId = _firebase.currentUserId;
    if (userId == null) throw Exception('로그인이 필요합니다');
    
    return await TransactionService.togglePetLike(
      petId: petId,
      userId: userId,
    );
  }
}
