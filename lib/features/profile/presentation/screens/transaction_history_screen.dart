import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../models/marketplace_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// 판매 내역 Provider
final _firebaseService = FirebaseService();

final sellHistoryProvider = FutureProvider.autoDispose<List<ProductModel>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final userId = authState.valueOrNull?.uid;
  if (userId == null) return [];
  
  final snapshot = await _firebaseService.productsCollection
      .where('sellerId', isEqualTo: userId)
      .get();
  
  return snapshot.docs
      .map((doc) => ProductModel.fromFirestore(doc.data(), id: doc.id))
      .toList();
});

/// 구매 내역 Provider
final buyHistoryProvider = FutureProvider.autoDispose<List<ProductModel>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final userId = authState.valueOrNull?.uid;
  if (userId == null) return [];
  
  final snapshot = await _firebaseService.productsCollection
      .where('buyerId', isEqualTo: userId)
      .get();
  
  return snapshot.docs
      .map((doc) => ProductModel.fromFirestore(doc.data(), id: doc.id))
      .toList();
});

/// 거래 내역 화면
class TransactionHistoryScreen extends ConsumerWidget {
  const TransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sellAsync = ref.watch(sellHistoryProvider);
    final buyAsync = ref.watch(buyHistoryProvider);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('거래 내역'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            // 탭바
            Container(
              color: Colors.white,
              child: const TabBar(
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                tabs: [
                  Tab(text: '판매'),
                  Tab(text: '구매'),
                ],
              ),
            ),
            // 탭 컨텐츠
            Expanded(
              child: TabBarView(
                children: [
                  _buildSellHistory(sellAsync),
                  _buildBuyHistory(buyAsync),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSellHistory(AsyncValue<List<ProductModel>> sellAsync) {
    return sellAsync.when(
      data: (products) {
        if (products.isEmpty) {
          return _buildEmptyState(
            icon: Icons.sell,
            title: '판매 내역이 없어요',
            subtitle: '마켓에서 물건을 판매해보세요!',
          );
        }
        return _buildProductList(products, isSell: true);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('데이터를 불러올 수 없습니다')),
    );
  }
  
  Widget _buildBuyHistory(AsyncValue<List<ProductModel>> buyAsync) {
    return buyAsync.when(
      data: (products) {
        if (products.isEmpty) {
          return _buildEmptyState(
            icon: Icons.shopping_cart,
            title: '구매 내역이 없어요',
            subtitle: '마켓에서 필요한 물건을 구매해보세요!',
          );
        }
        return _buildProductList(products, isSell: false);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('데이터를 불러올 수 없습니다')),
    );
  }
  
  Widget _buildProductList(List<ProductModel> products, {required bool isSell}) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(8),
              ),
              child: product.imageUrls.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(product.imageUrls.first, fit: BoxFit.cover),
                    )
                  : const Icon(Icons.image, color: AppColors.textHint),
            ),
            title: Text(product.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text('${product.price.toStringAsFixed(0)}원'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: product.status == ProductStatus.completed 
                    ? AppColors.success.withOpacity(0.1)
                    : AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                product.status == ProductStatus.completed ? '거래완료' : '판매중',
                style: TextStyle(
                  fontSize: 12,
                  color: product.status == ProductStatus.completed 
                      ? AppColors.success 
                      : AppColors.primary,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}
