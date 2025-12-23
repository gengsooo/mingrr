import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/top_navigation.dart';
import '../../../../models/marketplace_model.dart';

/// ============================================================
/// 마켓플레이스 화면
/// 
/// 디자인:
/// - 2개 탭 (판매 / 나눔) - pill 형태
/// - 위치/거리 필터 바
/// - 카테고리 필터
/// - 상품 목록
/// ============================================================

/// 선택된 탭 (0: 판매, 1: 나눔)
final _selectedTabProvider = StateProvider<int>((ref) => 0);

/// 선택된 카테고리 인덱스
final _selectedCategoryProvider = StateProvider<int>((ref) => 0);

/// 거리 필터
final _distanceFilterProvider = StateProvider<double>((ref) => 3.0);

class MarketplaceScreen extends ConsumerWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTab = ref.watch(_selectedTabProvider);
    final selectedCategory = ref.watch(_selectedCategoryProvider);
    final distanceFilter = ref.watch(_distanceFilterProvider);

    // 탭 정의 (판매 / 나눔)
    final tabs = [
      TopNavTab(label: '판매', icon: Icons.sell, color: AppColors.market),
      TopNavTab(label: '나눔', icon: Icons.volunteer_activism, color: AppColors.market),
    ];

    // 카테고리 정의
    final categories = [
      (label: '전체', emoji: null, icon: null),
      (label: '사료/간식', emoji: null, icon: null),
      (label: '의류', emoji: null, icon: null),
      (label: '장난감', emoji: null, icon: null),
      (label: '용품', emoji: null, icon: null),
      (label: '가구', emoji: null, icon: null),
    ];

    return Scaffold(
      backgroundColor: AppColors.marketLight,
      appBar: AppBar(
        title: const Text('마켓'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: 검색 화면
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 2개 탭 (판매 / 나눔)
          Container(
            color: Colors.white,
            child: PillTabBar(
              tabs: tabs,
              selectedIndex: selectedTab,
              onTabSelected: (index) {
                ref.read(_selectedTabProvider.notifier).state = index;
              },
            ),
          ),
          
          // 위치/거리 필터 바
          LocationDistanceBar(
            accentColor: AppColors.market,
            currentDistance: distanceFilter,
            onDistanceChanged: (distance) {
              ref.read(_distanceFilterProvider.notifier).state = distance;
            },
          ),
          
          // 카테고리 필터
          Container(
            color: Colors.white,
            child: CategoryFilterChips(
              categories: categories,
              selectedIndex: selectedCategory,
              onSelected: (index) {
                ref.read(_selectedCategoryProvider.notifier).state = index;
              },
              accentColor: AppColors.market,
            ),
          ),
          
          // 상품 목록
          Expanded(
            child: _buildProductList(selectedTab == 0 ? ProductType.sell : ProductType.share),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddProductSheet(context),
        backgroundColor: AppColors.market,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          '글쓰기',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  /// 상품 목록
  Widget _buildProductList(ProductType type) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSizes.paddingM),
      itemCount: 10,
      itemBuilder: (context, index) {
        return _buildProductItem(index, type);
      },
    );
  }

  /// 상품 아이템
  Widget _buildProductItem(int index, ProductType type) {
    final isShare = type == ProductType.share;
    
    return MingrrCard(
      margin: const EdgeInsets.only(bottom: AppSizes.gapM),
      onTap: () {
        // TODO: 상품 상세 페이지
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 이미지
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.marketLight,
              borderRadius: BorderRadius.circular(AppSizes.radiusM),
            ),
            child: Stack(
              children: [
                const Center(
                  child: Icon(Icons.image, size: 40, color: AppColors.market),
                ),
                if (index % 5 == 0)
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '예약중',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSizes.gapM),
          
          // 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isShare
                      ? '안 먹는 간식 나눔해요 ${index + 1}'
                      : '강아지 옷 팔아요 ${index + 1}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '강남구 · ${index + 1}시간 전',
                  style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                ),
                const SizedBox(height: 6),
                Text(
                  isShare ? '무료나눔' : '${(index + 1) * 5000}원',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isShare ? AppColors.walk : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.market.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        ['사료/간식', '의류', '장난감', '용품'][index % 4],
                        style: const TextStyle(fontSize: 10, color: AppColors.market),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        const Icon(Icons.favorite_border, size: 14, color: AppColors.textHint),
                        const SizedBox(width: 2),
                        Text('${index + 3}', style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                        const SizedBox(width: 8),
                        const Icon(Icons.chat_bubble_outline, size: 14, color: AppColors.textHint),
                        const SizedBox(width: 2),
                        Text('${index + 1}', style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 상품 등록 바텀시트
  void _showAddProductSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXL)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSizes.paddingM),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      '상품 등록',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('상품이 등록되었습니다!'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    },
                    child: const Text('완료'),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSizes.paddingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('사진', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: AppSizes.gapS),
                    SizedBox(
                      height: 80,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.divider),
                              borderRadius: BorderRadius.circular(AppSizes.radiusM),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.camera_alt, color: AppColors.textHint),
                                SizedBox(height: 4),
                                Text('0/10', style: TextStyle(fontSize: 11, color: AppColors.textHint)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSizes.gapXL),
                    const MingrrTextField(labelText: '제목', hintText: '상품명을 입력해주세요'),
                    const SizedBox(height: AppSizes.gapL),
                    const MingrrTextField(
                      labelText: '가격',
                      hintText: '가격을 입력해주세요',
                      prefixIcon: Icons.attach_money,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: AppSizes.gapL),
                    const MingrrTextField(
                      labelText: '상품 설명',
                      hintText: '상품에 대해 자세히 설명해주세요',
                      maxLines: 5,
                    ),
                    const SizedBox(height: AppSizes.gapXXL),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
