import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../models/marketplace_model.dart';

/// ============================================================
/// 마켓플레이스 화면
/// 중고거래 & 나눔 기능
/// 당근마켓 스타일의 지역 기반 거래
/// ============================================================
class MarketplaceScreen extends ConsumerStatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  ConsumerState<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends ConsumerState<MarketplaceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ProductCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('마켓'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: 검색 화면
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '판매'),
            Tab(text: '나눔'),
          ],
          indicatorColor: AppColors.market,
          labelColor: AppColors.market,
        ),
      ),
      body: Column(
        children: [
          // 카테고리 필터
          _buildCategoryFilter(),
          
          // 상품 목록
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildProductList(ProductType.sell),
                _buildProductList(ProductType.share),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showAddProductSheet();
        },
        backgroundColor: AppColors.market,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          '글쓰기',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  /// 카테고리 필터
  Widget _buildCategoryFilter() {
    final categories = [
      {'value': null, 'label': '전체'},
      {'value': ProductCategory.food, 'label': '사료/간식'},
      {'value': ProductCategory.clothes, 'label': '의류'},
      {'value': ProductCategory.toys, 'label': '장난감'},
      {'value': ProductCategory.supplies, 'label': '용품'},
      {'value': ProductCategory.furniture, 'label': '가구'},
      {'value': ProductCategory.health, 'label': '건강'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingS),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM),
        child: Row(
          children: categories.map((cat) {
            final isSelected = _selectedCategory == cat['value'];
            return Padding(
              padding: const EdgeInsets.only(right: AppSizes.gapS),
              child: FilterChip(
                label: Text(cat['label'] as String),
                selected: isSelected,
                onSelected: (value) {
                  setState(() {
                    _selectedCategory = cat['value'] as ProductCategory?;
                  });
                },
                selectedColor: AppColors.market.withOpacity(0.2),
                checkmarkColor: AppColors.market,
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.market : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// 상품 목록
  Widget _buildProductList(ProductType type) {
    // 데모 데이터
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
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppSizes.radiusM),
            ),
            child: Stack(
              children: [
                const Center(
                  child: Icon(
                    Icons.image,
                    size: 40,
                    color: AppColors.primary,
                  ),
                ),
                // 상태 배지
                if (index % 5 == 0)
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
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
                // 제목
                Text(
                  isShare
                      ? '안 먹는 간식 나눔해요 ${index + 1}'
                      : '강아지 옷 팔아요 ${index + 1}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                
                // 위치 & 시간
                Text(
                  '강남구 · ${index + 1}시간 전',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textHint,
                  ),
                ),
                const SizedBox(height: 6),
                
                // 가격
                Text(
                  isShare ? '무료나눔' : '${(index + 1) * 5000}원',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isShare ? AppColors.walk : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                
                // 하단 정보
                Row(
                  children: [
                    // 카테고리
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.market.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        ['사료/간식', '의류', '장난감', '용품'][index % 4],
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.market,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // 관심 & 채팅
                    Row(
                      children: [
                        const Icon(
                          Icons.favorite_border,
                          size: 14,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${index + 3}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textHint,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.chat_bubble_outline,
                          size: 14,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${index + 1}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textHint,
                          ),
                        ),
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
  void _showAddProductSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSizes.radiusXL),
          ),
        ),
        child: Column(
          children: [
            // 핸들
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // 헤더
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
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // TODO: 상품 등록 처리
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
            
            // 폼
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSizes.paddingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 사진 추가
                    const Text(
                      '사진',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSizes.gapS),
                    SizedBox(
                      height: 80,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          // 사진 추가 버튼
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
                                Text(
                                  '0/10',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textHint,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: AppSizes.gapXL),
                    
                    // 거래 유형
                    const Text(
                      '거래 유형',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSizes.gapS),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTypeButton('판매', true),
                        ),
                        const SizedBox(width: AppSizes.gapM),
                        Expanded(
                          child: _buildTypeButton('나눔', false),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: AppSizes.gapXL),
                    
                    // 제목
                    const MingrrTextField(
                      labelText: '제목',
                      hintText: '상품명을 입력해주세요',
                    ),
                    
                    const SizedBox(height: AppSizes.gapL),
                    
                    // 카테고리
                    const Text(
                      '카테고리',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSizes.gapS),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildCategoryChip('사료/간식'),
                        _buildCategoryChip('의류/악세서리'),
                        _buildCategoryChip('장난감'),
                        _buildCategoryChip('용품'),
                        _buildCategoryChip('가구/하우스'),
                        _buildCategoryChip('건강/위생'),
                        _buildCategoryChip('기타'),
                      ],
                    ),
                    
                    const SizedBox(height: AppSizes.gapXL),
                    
                    // 가격
                    const MingrrTextField(
                      labelText: '가격',
                      hintText: '가격을 입력해주세요',
                      prefixIcon: Icons.attach_money,
                      keyboardType: TextInputType.number,
                    ),
                    
                    const SizedBox(height: AppSizes.gapL),
                    
                    // 설명
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

  /// 거래 유형 버튼
  Widget _buildTypeButton(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.market.withOpacity(0.1) : Colors.white,
        border: Border.all(
          color: isSelected ? AppColors.market : AppColors.divider,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isSelected ? AppColors.market : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  /// 카테고리 칩
  Widget _buildCategoryChip(String label) {
    return ChoiceChip(
      label: Text(label),
      selected: false,
      onSelected: (value) {
        // TODO: 카테고리 선택
      },
    );
  }
}
