import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/favorite_service.dart';
import '../../models/pet_model.dart';
import '../../models/marketplace_model.dart';
import '../../models/community_model.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

/// ============================================================
/// 찜 관련 Provider
/// Firebase Firestore와 연동하여 찜 데이터 관리
/// ============================================================

/// 찜 서비스 Provider
final favoriteServiceProvider = Provider<FavoriteService>((ref) {
  return FavoriteService();
});

/// 찜한 반려동물 ID 목록 (실시간 스트림)
final favoritePetIdsProvider = StreamProvider.autoDispose<List<String>>((ref) {
  final authState = ref.watch(authStateProvider);
  
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(<String>[]);
      return ref.watch(favoriteServiceProvider).watchFavoritePetIds();
    },
    loading: () => const Stream.empty(),
    error: (_, __) => Stream.value(<String>[]),
  );
});

/// 찜한 상품 ID 목록 (실시간 스트림)
final favoriteProductIdsProvider = StreamProvider.autoDispose<List<String>>((ref) {
  final authState = ref.watch(authStateProvider);
  
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(<String>[]);
      return ref.watch(favoriteServiceProvider).watchFavoriteProductIds();
    },
    loading: () => const Stream.empty(),
    error: (_, __) => Stream.value(<String>[]),
  );
});

/// 찜한 소모임 ID 목록 (실시간 스트림)
final favoriteGroupIdsProvider = StreamProvider.autoDispose<List<String>>((ref) {
  final authState = ref.watch(authStateProvider);
  
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(<String>[]);
      return ref.watch(favoriteServiceProvider).watchFavoriteGroupIds();
    },
    loading: () => const Stream.empty(),
    error: (_, __) => Stream.value(<String>[]),
  );
});

/// 찜한 반려동물 목록 (전체 데이터)
final favoritePetsProvider = FutureProvider.autoDispose<List<PetModel>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  
  if (user == null) return [];
  
  return ref.watch(favoriteServiceProvider).getFavoritePets();
});

/// 찜한 상품 목록 (전체 데이터)
final favoriteProductsProvider = FutureProvider.autoDispose<List<ProductModel>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  
  if (user == null) return [];
  
  return ref.watch(favoriteServiceProvider).getFavoriteProducts();
});

/// 찜한 소모임 목록 (전체 데이터)
final favoriteGroupsProvider = FutureProvider.autoDispose<List<GroupModel>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  
  if (user == null) return [];
  
  return ref.watch(favoriteServiceProvider).getFavoriteGroups();
});

/// 특정 반려동물 찜 여부 확인
final isPetFavoritedProvider = Provider.autoDispose.family<bool, String>((ref, petId) {
  final favoriteIds = ref.watch(favoritePetIdsProvider).valueOrNull ?? [];
  return favoriteIds.contains(petId);
});

/// 특정 상품 찜 여부 확인
final isProductFavoritedProvider = Provider.autoDispose.family<bool, String>((ref, productId) {
  final favoriteIds = ref.watch(favoriteProductIdsProvider).valueOrNull ?? [];
  return favoriteIds.contains(productId);
});

/// 특정 소모임 찜 여부 확인
final isGroupFavoritedProvider = Provider.autoDispose.family<bool, String>((ref, groupId) {
  final favoriteIds = ref.watch(favoriteGroupIdsProvider).valueOrNull ?? [];
  return favoriteIds.contains(groupId);
});
