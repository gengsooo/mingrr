import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../models/marketplace_model.dart';

/// ============================================================
/// 마켓플레이스 관련 Provider
/// Firebase Firestore와 연동하여 상품 데이터 관리
/// ============================================================

// FirestoreService Provider (chat_provider에서 이미 정의됨, 여기서는 import해서 사용)
final _firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

// 판매 상품 목록
final sellProductsProvider = FutureProvider.autoDispose<List<ProductModel>>((ref) async {
  final firestoreService = ref.watch(_firestoreServiceProvider);
  final products = await firestoreService.getProducts(
    status: ProductStatus.available,
  );
  return products.where((p) => p.type == ProductType.sell).toList();
});

// 나눔 상품 목록
final shareProductsProvider = FutureProvider.autoDispose<List<ProductModel>>((ref) async {
  final firestoreService = ref.watch(_firestoreServiceProvider);
  final products = await firestoreService.getProducts(
    status: ProductStatus.available,
  );
  return products.where((p) => p.type == ProductType.share).toList();
});

// 카테고리별 상품 목록
final productsByCategoryProvider = FutureProvider.autoDispose.family<List<ProductModel>, ProductCategory?>((ref, category) async {
  final firestoreService = ref.watch(_firestoreServiceProvider);
  return firestoreService.getProducts(
    status: ProductStatus.available,
    category: category,
  );
});

// 특정 상품 상세
final productDetailProvider = FutureProvider.autoDispose.family<ProductModel?, String>((ref, productId) async {
  final firestoreService = ref.watch(_firestoreServiceProvider);
  return firestoreService.getProduct(productId);
});

// 상품 타입별 필터링 (판매/나눔)
final filteredProductsProvider = FutureProvider.autoDispose.family<List<ProductModel>, ProductType>((ref, type) async {
  final firestoreService = ref.watch(_firestoreServiceProvider);
  final products = await firestoreService.getProducts(
    status: ProductStatus.available,
  );
  return products.where((p) => p.type == type).toList();
});

// ===== 알바(Job) 관련 Provider =====

// 전체 알바 목록
final jobsProvider = FutureProvider.autoDispose<List<JobModel>>((ref) async {
  final firestoreService = ref.watch(_firestoreServiceProvider);
  return firestoreService.getJobs();
});

// 알바 타입별 필터링
final filteredJobsProvider = FutureProvider.autoDispose.family<List<JobModel>, JobType?>((ref, type) async {
  final firestoreService = ref.watch(_firestoreServiceProvider);
  return firestoreService.getJobs(type: type);
});

// 알바 상세
final jobDetailProvider = FutureProvider.autoDispose.family<JobModel?, String>((ref, jobId) async {
  final firestoreService = ref.watch(_firestoreServiceProvider);
  return firestoreService.getJob(jobId);
});
