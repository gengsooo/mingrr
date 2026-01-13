import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../../../core/providers/location_provider.dart';
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

// 모든 상품 목록 (거리 정보 포함)
final _allProductsWithDistanceProvider = FutureProvider.autoDispose<List<ProductWithDistance>>((ref) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final userLocation = ref.watch(currentUserLocationProvider);
  
  final products = await firestoreService.getProducts(
    status: ProductStatus.available,
  );
  
  if (userLocation == null) {
    return products.map((p) => ProductWithDistance(
      product: p,
      distanceMeters: 0,
    )).toList();
  }
  
  final result = <ProductWithDistance>[];
  for (final product in products) {
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

// 상품 타입별 필터링 (판매/나눔) - 거리 필터 적용
final filteredProductsProvider = Provider.autoDispose.family<List<ProductWithDistance>, ({ProductType type, double radiusKm})>((ref, params) {
  final productsAsync = ref.watch(_allProductsWithDistanceProvider);
  final products = productsAsync.valueOrNull ?? [];
  
  return products
      .where((p) => p.product.type == params.type)
      .where((p) => p.distanceMeters <= params.radiusKm * 1000)
      .toList();
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
