import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/svg_icons.dart';
import '../providers/profile_provider.dart';

/// 찜한 목록 화면
class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlistAsync = ref.watch(wishlistProductsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('찜한 목록'),
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            // 탭바
            Container(
              color: Theme.of(context).colorScheme.surface,
              child: TabBar(
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
                indicatorColor: Theme.of(context).colorScheme.primary,
                tabs: const [
                  Tab(text: '상품'),
                  Tab(text: '반려동물'),
                ],
              ),
            ),
            // 탭 컨텐츠
            Expanded(
              child: TabBarView(
                children: [
                  _buildProductWishlist(wishlistAsync),
                  _buildPetWishlist(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildProductWishlist(AsyncValue<dynamic> wishlistAsync) {
    return wishlistAsync.when(
      data: (products) {
        if (products.isEmpty) {
          return MingrrEmptyState(
            svgAsset: SvgAssets.emptyWishlist,
            title: '찜한 상품이 없어요',
            subtitle: '마켓에서 마음에 드는 상품을 찜해보세요!',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(AppSizes.paddingM),
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
                    color: Theme.of(context).colorScheme.outline,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: product.imageUrls.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(product.imageUrls.first, fit: BoxFit.cover),
                        )
                      : Icon(Icons.image, color: Theme.of(context).colorScheme.outlineVariant),
                ),
                title: Text(product.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text('${product.price.toStringAsFixed(0)}원'),
                trailing: const Icon(Icons.chevron_right),
              ),
            );
          },
        );
      },
      loading: () => const MingrrLoadingState(),
      error: (_, __) => const MingrrErrorState(title: '데이터를 불러올 수 없습니다'),
    );
  }
  
  Widget _buildPetWishlist() {
    // 반려동물 찜 기능은 추후 구현
    return MingrrEmptyState(
      svgAsset: SvgAssets.emptyHeart,
      title: '찜한 반려동물이 없어요',
      subtitle: '데이팅에서 마음에 드는 친구를 찜해보세요!',
    );
  }
  
}
