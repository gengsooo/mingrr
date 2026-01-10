import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('찜한 목록'),
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
          return _buildEmptyState(
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
                trailing: const Icon(Icons.chevron_right),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('데이터를 불러올 수 없습니다')),
    );
  }
  
  Widget _buildPetWishlist() {
    // 반려동물 찜 기능은 추후 구현
    return _buildEmptyState(
      svgAsset: SvgAssets.emptyHeart,
      title: '찜한 반려동물이 없어요',
      subtitle: '데이팅에서 마음에 드는 친구를 찜해보세요!',
    );
  }
  
  Widget _buildEmptyState({
    required String svgAsset,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          MingrrSvgIcon(
            assetPath: svgAsset,
            width: 120,
            height: 120,
          ),
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
