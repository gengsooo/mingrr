import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/feature_colors.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/svg_icons.dart';
import '../../../../core/widgets/top_navigation.dart';
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
      appBar: AppBar(
        title: const Text('거래 내역'),
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            // 탭바
            const MingrrSubTabBar(tabs: ['판매', '구매']),
            // 탭 컨텐츠
            Expanded(
              child: TabBarView(
                children: [
                  _buildSellHistory(ref, sellAsync),
                  _buildBuyHistory(ref, buyAsync),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSellHistory(WidgetRef ref, AsyncValue<List<ProductModel>> sellAsync) {
    return sellAsync.when(
      data: (products) {
        if (products.isEmpty) {
          return MingrrEmptyState(
            icon: Icons.sell_outlined,
            title: '판매 내역이 없어요',
            subtitle: '마켓에서 물건을 판매해보세요',
          );
        }
        return _buildProductList(products, isSell: true);
      },
      loading: () => const MingrrLoadingState(
        type: MingrrLoadingType.market,
        message: '판매 내역을 불러오고 있어요',
      ),
      error: (_, __) => MingrrErrorState(
        onRetry: () => ref.invalidate(sellHistoryProvider),
      ),
    );
  }
  
  Widget _buildBuyHistory(WidgetRef ref, AsyncValue<List<ProductModel>> buyAsync) {
    return buyAsync.when(
      data: (products) {
        if (products.isEmpty) {
          return MingrrEmptyState(
            icon: Icons.shopping_bag_outlined,
            title: '구매 내역이 없어요',
            subtitle: '마켓에서 필요한 물건을 구매해보세요',
          );
        }
        return _buildProductList(products, isSell: false);
      },
      loading: () => const MingrrLoadingState(
        type: MingrrLoadingType.market,
        message: '구매 내역을 불러오고 있어요',
      ),
      error: (_, __) => MingrrErrorState(
        onRetry: () => ref.invalidate(buyHistoryProvider),
      ),
    );
  }
  
  Widget _buildProductList(List<ProductModel> products, {required bool isSell}) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSizes.paddingL),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return Card(
          margin: const EdgeInsets.only(bottom: AppSizes.paddingM),
          child: ListTile(
            leading: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline,
                borderRadius: BorderRadius.circular(AppSizes.radiusXS),
              ),
              child: product.imageUrls.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(AppSizes.radiusXS),
                      child: Image.network(product.imageUrls.first, fit: BoxFit.cover),
                    )
                  : Icon(Icons.image, color: Theme.of(context).colorScheme.outlineVariant),
            ),
            title: Text(product.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text('${product.price.toStringAsFixed(0)}원'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingS, vertical: AppSizes.paddingXS),
              decoration: BoxDecoration(
                color: product.status == ProductStatus.completed 
                    ? context.features.success.withValues(alpha: 0.1)
                    : Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusXXS),
              ),
              child: Text(
                product.status == ProductStatus.completed ? '거래완료' : '판매중',
                style: TextStyle(
                  fontSize: 12,
                  color: product.status == ProductStatus.completed 
                      ? context.features.success 
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
}
