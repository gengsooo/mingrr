import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../models/community_model.dart';
import '../../../../models/marketplace_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// 데이터베이스 서비스 상태 관리
final _firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

/// 사용자 활동 기록 Provider
final userActivityStatsProvider = FutureProvider.autoDispose<Map<String, int>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final userId = authState.valueOrNull?.uid;
  
  if (userId == null) {
    return {
      'matches': 0,
      'walks': 0,
      'transactions': 0,
      'groups': 0,
    };
  }
  
  final firestoreService = ref.watch(_firestoreServiceProvider);
  return firestoreService.getUserActivityStats(userId);
});

/// 매칭 수 Provider
final userMatchCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final stats = await ref.watch(userActivityStatsProvider.future);
  return stats['matches'] ?? 0;
});

/// 산책 횟수 Provider
final userWalkCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final stats = await ref.watch(userActivityStatsProvider.future);
  return stats['walks'] ?? 0;
});

/// 거래 수 Provider
final userTransactionCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final stats = await ref.watch(userActivityStatsProvider.future);
  return stats['transactions'] ?? 0;
});

/// 모임 수 Provider
final userGroupCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final stats = await ref.watch(userActivityStatsProvider.future);
  return stats['groups'] ?? 0;
});

final _firebaseService = FirebaseService();

/// 사용자가 참여한 모임 목록 Provider
final userGroupsProvider = FutureProvider.autoDispose<List<GroupModel>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final userId = authState.valueOrNull?.uid;
  
  if (userId == null) return [];
  
  final snapshot = await _firebaseService.groupsCollection
      .where('memberIds', arrayContains: userId)
      .get();
  
  return snapshot.docs
      .map((doc) => GroupModel.fromFirestore(doc.data(), id: doc.id))
      .toList();
});

/// 사용자의 거래 내역 Provider (판매 + 구매)
final userTransactionsProvider = FutureProvider.autoDispose<List<ProductModel>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final userId = authState.valueOrNull?.uid;
  
  if (userId == null) return [];
  
  // 판매 완료
  final soldSnapshot = await _firebaseService.productsCollection
      .where('sellerId', isEqualTo: userId)
      .where('status', isEqualTo: 'sold')
      .get();
  
  // 구매
  final boughtSnapshot = await _firebaseService.productsCollection
      .where('buyerId', isEqualTo: userId)
      .get();
  
  final products = <ProductModel>[];
  for (final doc in soldSnapshot.docs) {
    products.add(ProductModel.fromFirestore(doc.data(), id: doc.id));
  }
  for (final doc in boughtSnapshot.docs) {
    products.add(ProductModel.fromFirestore(doc.data(), id: doc.id));
  }
  
  // 날짜순 정렬
  products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return products;
});

/// 찜한 상품 목록 Provider
final wishlistProductsProvider = FutureProvider.autoDispose<List<ProductModel>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final userId = authState.valueOrNull?.uid;
  
  if (userId == null) return [];
  
  // 찜한 상품 ID 목록 조회
  final likesSnapshot = await _firebaseService.productLikesCollection
      .where('userId', isEqualTo: userId)
      .get();
  
  if (likesSnapshot.docs.isEmpty) return [];
  
  final productIds = likesSnapshot.docs.map((doc) => doc.data()['productId'] as String).toList();
  
  // 상품 정보 조회
  final products = <ProductModel>[];
  for (final productId in productIds) {
    final productDoc = await _firebaseService.productsCollection.doc(productId).get();
    if (productDoc.exists) {
      products.add(ProductModel.fromFirestore(productDoc.data()!, id: productDoc.id));
    }
  }
  
  return products;
});

/// 사용자 인증 상태 Provider
final userVerificationsProvider = StreamProvider.autoDispose<Map<String, bool>>((ref) {
  final authState = ref.watch(authStateProvider);
  final userId = authState.valueOrNull?.uid;
  
  if (userId == null) {
    return Stream.value({
      'identity': false,
      'location': false,
      'petRegistration': false,
    });
  }
  
  final firestoreService = ref.watch(_firestoreServiceProvider);
  return firestoreService.watchUserVerifications(userId);
});
