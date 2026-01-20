import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/paginated_state.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../../../core/providers/location_provider.dart';
import '../../../../core/providers/block_provider.dart';
import '../../../../core/providers/paginated_provider.dart';
import '../../../../core/services/location_service.dart';
import '../../../../models/marketplace_model.dart';

/// ============================================================
/// 마켓플레이스 관련 Provider
/// Firebase Firestore와 연동하여 상품 데이터 관리
/// ============================================================

/// 상품 + 거리 정보
class ProductWithDistance {
  final ProductModel product;
  final double distanceMeters;
  
  ProductWithDistance({
    required this.product,
    required this.distanceMeters,
  });
  
  String get distanceString => LocationService.formatDistance(distanceMeters);
}

// 모든 상품 목록 (거리 정보 포함, 차단된 사용자 제외)
final _allProductsWithDistanceProvider = FutureProvider.autoDispose<List<ProductWithDistance>>((ref) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final userLocation = ref.watch(currentUserLocationProvider);
  final blockedUserIds = ref.watch(blockedUserIdsProvider).valueOrNull ?? [];
  
  final products = await firestoreService.getProducts(
    status: ProductStatus.available,
  );
  
  // 차단된 사용자 상품 제외
  final filteredProducts = products.where((p) => !blockedUserIds.contains(p.sellerId)).toList();
  
  if (userLocation == null) {
    return filteredProducts.map((p) => ProductWithDistance(
      product: p,
      distanceMeters: 0,
    )).toList();
  }
  
  final result = <ProductWithDistance>[];
  for (final product in filteredProducts) {
    if (product.location != null) {
      final distance = LocationService.calculateDistanceFromGeoPoints(
        userLocation,
        product.location!,
      );
      result.add(ProductWithDistance(product: product, distanceMeters: distance));
    } else {
      result.add(ProductWithDistance(product: product, distanceMeters: double.infinity));
    }
  }
  
  result.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
  return result;
});

// 판매 상품 목록 (거리 필터 적용)
final sellProductsProvider = Provider.autoDispose.family<List<ProductWithDistance>, double>((ref, radiusKm) {
  final productsAsync = ref.watch(_allProductsWithDistanceProvider);
  final products = productsAsync.valueOrNull ?? [];
  
  return products
      .where((p) => p.product.type == ProductType.sell)
      .where((p) => p.distanceMeters <= radiusKm * 1000)
      .toList();
});

// 나눔 상품 목록 (거리 필터 적용)
final shareProductsProvider = Provider.autoDispose.family<List<ProductWithDistance>, double>((ref, radiusKm) {
  final productsAsync = ref.watch(_allProductsWithDistanceProvider);
  final products = productsAsync.valueOrNull ?? [];
  
  return products
      .where((p) => p.product.type == ProductType.share)
      .where((p) => p.distanceMeters <= radiusKm * 1000)
      .toList();
});

// 카테고리별 상품 목록
final productsByCategoryProvider = FutureProvider.autoDispose.family<List<ProductModel>, ProductCategory?>((ref, category) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getProducts(
    status: ProductStatus.available,
    category: category,
  );
});

// 특정 상품 상세
final productDetailProvider = FutureProvider.autoDispose.family<ProductModel?, String>((ref, productId) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getProduct(productId);
});

// 상품 타입별 필터링 (판매/나눔) - 거리 필터 적용 (AsyncValue 유지)
final filteredProductsProvider = Provider.autoDispose.family<AsyncValue<List<ProductWithDistance>>, ({ProductType type, double radiusKm})>((ref, params) {
  final productsAsync = ref.watch(_allProductsWithDistanceProvider);
  
  return productsAsync.whenData((products) {
    return products
        .where((p) => p.product.type == params.type)
        .where((p) => p.distanceMeters <= params.radiusKm * 1000)
        .toList();
  });
});

// ===== 알바(Job) 관련 Provider =====

// 전체 알바 목록
final jobsProvider = FutureProvider.autoDispose<List<JobModel>>((ref) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getJobs();
});

// 알바 타입별 필터링
final filteredJobsProvider = FutureProvider.autoDispose.family<List<JobModel>, JobType?>((ref, type) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getJobs(type: type);
});

// 알바 상세
final jobDetailProvider = FutureProvider.autoDispose.family<JobModel?, String>((ref, jobId) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getJob(jobId);
});

// 알바 상세 (alias)
final jobByIdProvider = jobDetailProvider;

/// ============================================================
/// 페이지네이션 마켓플레이스 Provider
/// 
/// 서버 사이드 필터링 + 클라이언트 거리 계산 + 캐싱
/// - 타입별 서버 필터링 (판매/나눔)
/// - 거리 필터링 (클라이언트)
/// - 20개씩 로드
/// - keepAlive로 화면 전환 시 상태 유지
/// ============================================================

/// 페이지네이션 상품 목록 Provider (타입 + 거리 필터)
final paginatedProductsProvider = StateNotifierProvider
    .family<ClientPaginatedNotifier<ProductWithDistance>, PaginatedState<ProductWithDistance>, ({ProductType type, double radiusKm})>((ref, params) {
  // 캐싱: 화면 전환 시 상태 유지 (5분 후 자동 해제)
  final link = ref.keepAlive();
  Future.delayed(const Duration(minutes: 5), () => link.close());
  
  final userLocation = ref.watch(currentUserLocationProvider);
  final blockedUserIds = ref.watch(blockedUserIdsProvider).valueOrNull ?? [];
  
  return ClientPaginatedNotifier<ProductWithDistance>(
    pageSize: 20,
    fetchAll: () async {
      final firestoreService = ref.read(firestoreServiceProvider);
      // 서버 사이드 필터링: 타입 + 상태
      final products = await firestoreService.getProducts(
        status: ProductStatus.available,
        type: params.type,
      );
      
      // 차단된 사용자 상품 제외
      final filteredProducts = products.where((p) => !blockedUserIds.contains(p.sellerId)).toList();
      
      final result = <ProductWithDistance>[];
      for (final product in filteredProducts) {
        double distance = double.infinity;
        if (product.location != null && userLocation != null) {
          distance = LocationService.calculateDistanceFromGeoPoints(
            userLocation,
            product.location!,
          );
        }
        
        // 거리 필터 적용
        if (distance <= params.radiusKm * 1000) {
          result.add(ProductWithDistance(product: product, distanceMeters: distance));
        }
      }
      
      // 거리순 정렬
      result.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
      return result;
    },
  );
});

/// 페이지네이션 알바 목록 Provider
final paginatedJobsProvider = StateNotifierProvider<
    ClientPaginatedNotifier<JobModel>,
    PaginatedState<JobModel>>((ref) {
  // 캐싱: 화면 전환 시 상태 유지 (5분 후 자동 해제)
  final link = ref.keepAlive();
  Future.delayed(const Duration(minutes: 5), () => link.close());
  
  return ClientPaginatedNotifier<JobModel>(
    pageSize: 20,
    fetchAll: () async {
      final firestoreService = ref.read(firestoreServiceProvider);
      return firestoreService.getJobs();
    },
  );
});
