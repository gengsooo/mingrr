import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/paginated_state.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../../../core/providers/location_provider.dart';
import '../../../../core/providers/block_provider.dart';
import '../../../../core/providers/paginated_provider.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/transaction_service.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../models/marketplace_model.dart';

/// ============================================================
/// 마켓플레이스 관련 Provider
/// Firebase Firestore와 연동하여 상품 데이터 관리
/// ============================================================

/// 상품 + 거리 정보 (`ItemWithDistance<ProductModel>` 확장)
class ProductWithDistance extends ItemWithDistance<ProductModel> {
  ProductWithDistance({
    required ProductModel product,
    required super.distanceMeters,
  }) : super(item: product);
  
  /// 기존 코드 호환성을 위한 접근자
  ProductModel get product => item;
}

/// 알바 + 거리 정보 (`ItemWithDistance<JobModel>` 확장)
class JobWithDistance extends ItemWithDistance<JobModel> {
  JobWithDistance({
    required JobModel job,
    required super.distanceMeters,
  }) : super(item: job);
  
  /// 기존 코드 호환성을 위한 접근자
  JobModel get job => item;
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
    // 사용자 위치 없음 - 모든 상품 거리를 infinity로 설정 (위치 정보 없음 표시)
    return filteredProducts.map((p) => ProductWithDistance(
      product: p,
      distanceMeters: double.infinity,
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
      final isAllDistance = params.radiusKm == 0; // 0 = 전체 (거리 제한 없음)
      
      for (final product in filteredProducts) {
        double distance = double.infinity; // 위치 정보 없으면 infinity (가장 나중에 표시)
        if (product.location != null && userLocation != null) {
          distance = LocationService.calculateDistanceFromGeoPoints(
            userLocation,
            product.location!,
          );
          // 거리 필터 적용 (전체가 아닌 경우에만)
          if (!isAllDistance && distance > params.radiusKm * 1000) {
            continue; // 거리 초과 시 제외
          }
        }
        result.add(ProductWithDistance(product: product, distanceMeters: distance));
      }
      
      // 거리순 정렬 (위치 없는 상품은 가장 나중에 표시)
      result.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
      return result;
    },
  );
});

// ===== 찜(좋아요) 관련 Provider =====

/// 상품 찜 여부 확인
final isProductLikedProvider = FutureProvider.autoDispose.family<bool, String>((ref, productId) async {
  final firebase = FirebaseService();
  final userId = firebase.currentUserId;
  if (userId == null) return false;

  final likeId = '${userId}_$productId';
  final doc = await firebase.productLikesCollection.doc(likeId).get();
  return doc.exists;
});

/// 알바 찜 여부 확인
final isJobLikedProvider = FutureProvider.autoDispose.family<bool, String>((ref, jobId) async {
  final firebase = FirebaseService();
  final userId = firebase.currentUserId;
  if (userId == null) return false;

  final likeId = '${userId}_$jobId';
  final doc = await firebase.jobLikesCollection.doc(likeId).get();
  return doc.exists;
});

/// 마켓플레이스 Notifier (찜 토글 등 액션 처리)
class MarketplaceNotifier extends StateNotifier<AsyncValue<void>> {
  final FirebaseService _firebase = FirebaseService();

  MarketplaceNotifier(Ref ref) : super(const AsyncValue.data(null));

  /// 상품 찜 토글
  Future<bool> toggleProductLike(String productId) async {
    try {
      final userId = _firebase.currentUserId;
      if (userId == null) return false;

      final result = await TransactionService.toggleProductLike(
        productId: productId,
        userId: userId,
      );
      return result;
    } catch (e) {
      AppLogger.error('MarketplaceNotifier', '상품 찜 토글 오류', e);
      return false;
    }
  }

  /// 알바 찜 토글
  Future<bool> toggleJobLike(String jobId) async {
    try {
      final userId = _firebase.currentUserId;
      if (userId == null) return false;

      final result = await TransactionService.toggleJobLike(
        jobId: jobId,
        userId: userId,
      );
      return result;
    } catch (e) {
      AppLogger.error('MarketplaceNotifier', '알바 찜 토글 오류', e);
      return false;
    }
  }
}

/// 마켓플레이스 Notifier Provider
final marketplaceNotifierProvider = StateNotifierProvider<MarketplaceNotifier, AsyncValue<void>>((ref) {
  return MarketplaceNotifier(ref);
});

/// 페이지네이션 알바 목록 Provider (거리 정보 포함)
final paginatedJobsProvider = StateNotifierProvider<
    ClientPaginatedNotifier<JobWithDistance>,
    PaginatedState<JobWithDistance>>((ref) {
  // 캐싱: 화면 전환 시 상태 유지 (5분 후 자동 해제)
  final link = ref.keepAlive();
  Future.delayed(const Duration(minutes: 5), () => link.close());
  
  final userLocation = ref.watch(currentUserLocationProvider);
  final blockedUserIds = ref.watch(blockedUserIdsProvider).valueOrNull ?? [];
  
  return ClientPaginatedNotifier<JobWithDistance>(
    pageSize: 20,
    fetchAll: () async {
      final firestoreService = ref.read(firestoreServiceProvider);
      final jobs = await firestoreService.getJobs();
      
      // 차단된 사용자 알바 제외
      final filteredJobs = jobs.where((j) => !blockedUserIds.contains(j.userId)).toList();
      
      final result = <JobWithDistance>[];
      for (final job in filteredJobs) {
        double distance = double.infinity; // 위치 정보 없으면 infinity (가장 나중에 표시)
        if (job.location != null && userLocation != null) {
          distance = LocationService.calculateDistanceFromGeoPoints(
            userLocation,
            job.location!,
          );
        }
        result.add(JobWithDistance(job: job, distanceMeters: distance));
      }
      
      // 거리순 정렬 (위치 없는 알바는 가장 나중에 표시)
      result.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
      return result;
    },
  );
});
