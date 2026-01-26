import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/favorite_service.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../models/group_model.dart';
import '../../../../models/marketplace_model.dart';
import '../../../../models/pet_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// 데이터베이스 서비스 상태 관리
final _firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

/// 사용자 활동 기록 Provider
/// 순서: 산책 → 매칭 → 거래 → 커뮤니티 → 모임
final userActivityStatsProvider = FutureProvider.autoDispose<Map<String, int>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final userId = authState.valueOrNull?.uid;
  
  if (userId == null) {
    return {
      'walks': 0,
      'matches': 0,
      'transactions': 0,
      'posts': 0,
      'groups': 0,
    };
  }
  
  final firestoreService = ref.watch(_firestoreServiceProvider);
  return firestoreService.getUserActivityStats(userId);
});

/// 산책 횟수 Provider
final userWalkCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final stats = await ref.watch(userActivityStatsProvider.future);
  return stats['walks'] ?? 0;
});

/// 매칭 수 Provider
final userMatchCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final stats = await ref.watch(userActivityStatsProvider.future);
  return stats['matches'] ?? 0;
});

/// 거래 수 Provider
final userTransactionCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final stats = await ref.watch(userActivityStatsProvider.future);
  return stats['transactions'] ?? 0;
});

/// 커뮤니티 게시글 수 Provider
final userPostCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final stats = await ref.watch(userActivityStatsProvider.future);
  return stats['posts'] ?? 0;
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
  
  final firestoreService = ref.watch(_firestoreServiceProvider);
  return firestoreService.getUserLikedProducts(userId);
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
  return firestoreService.watchUserVerifications(userId).handleError((error, stackTrace) {
    AppLogger.error('ProfileProvider', '인증 상태 스트림 오류 (userId: $userId)', error, stackTrace);
    return {'identity': false, 'location': false, 'petRegistration': false};
  });
});

/// FavoriteService Provider
final _favoriteServiceProvider = Provider<FavoriteService>((ref) {
  return FavoriteService();
});

/// 찜한 반려동물 목록 Provider
final wishlistPetsProvider = FutureProvider.autoDispose<List<PetModel>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final userId = authState.valueOrNull?.uid;
  
  if (userId == null) return [];
  
  final favoriteService = ref.watch(_favoriteServiceProvider);
  return favoriteService.getFavoritePets();
});

/// 찞한 반려동물 ID 목록 스트림 Provider
final wishlistPetIdsProvider = StreamProvider.autoDispose<List<String>>((ref) {
  final favoriteService = ref.watch(_favoriteServiceProvider);
  return favoriteService.watchFavoritePetIds().handleError((error, stackTrace) {
    AppLogger.error('ProfileProvider', '찜한 반려동물 ID 스트림 오류', error, stackTrace);
    return <String>[];
  });
});

/// 반려동물 찜 토글 Provider
final petFavoriteToggleProvider = Provider<Future<void> Function(String petId, bool isLiked)>((ref) {
  final favoriteService = ref.watch(_favoriteServiceProvider);
  
  return (String petId, bool isLiked) async {
    if (isLiked) {
      await favoriteService.unlikePet(petId);
    } else {
      await favoriteService.likePet(petId);
    }
    // 목록 갱신
    ref.invalidate(wishlistPetsProvider);
  };
});
