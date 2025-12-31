import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/top_navigation.dart';
import '../../../../models/marketplace_model.dart';
import '../providers/marketplace_provider.dart';
import 'product_detail_screen.dart';

/// ============================================================
/// 마켓플레이스 화면
/// 
/// 디자인:
/// - 3개 탭 (판매 / 나눔 / 알바) - pill 형태
/// - 위치/거리 필터 바
/// - 카테고리 필터
/// - 상품/알바 목록
/// ============================================================

/// 선택된 탭 (0: 판매, 1: 나눔, 2: 알바)
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

    // 탭 정의 (판매 / 나눔 / 알바)
    final tabs = [
      TopNavTab(label: '판매', icon: Icons.sell, color: AppColors.market),
      TopNavTab(label: '나눔', icon: Icons.volunteer_activism, color: AppColors.market),
      TopNavTab(label: '알바', icon: Icons.work_outline, color: AppColors.market),
    ];

    // 카테고리 정의 (탭에 따라 다름)
    final categories = selectedTab == 2
        ? [
            // 알바 카테고리
            (label: '전체', emoji: null, icon: null),
            (label: '돌봄', emoji: null, icon: null),
            (label: '산책', emoji: null, icon: null),
            (label: '목욕', emoji: null, icon: null),
            (label: '훈련', emoji: null, icon: null),
            (label: '기타', emoji: null, icon: null),
          ]
        : [
            // 판매/나눔 카테고리
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
          
          // 상품/알바 목록
          Expanded(
            child: selectedTab == 2
                ? _buildJobList(context)
                : _buildProductList(context, selectedTab == 0 ? ProductType.sell : ProductType.share),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(context, selectedTab),
        backgroundColor: AppColors.market,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          '글쓰기',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  /// 상품 목록 (Firebase 연동)
  Widget _buildProductList(BuildContext context, ProductType type) {
    return Consumer(
      builder: (context, ref, child) {
        final productsAsync = ref.watch(filteredProductsProvider(type));
        
        return productsAsync.when(
          data: (products) {
            if (products.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      type == ProductType.sell ? Icons.sell : Icons.volunteer_activism,
                      size: 48,
                      color: AppColors.textHint,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      type == ProductType.sell ? '등록된 판매 상품이 없습니다' : '등록된 나눔 상품이 없습니다',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(AppSizes.paddingM),
              itemCount: products.length,
              itemBuilder: (ctx, index) {
                return _buildProductModelItem(context, products[index]);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(child: Text('데이터를 불러올 수 없습니다')),
        );
      },
    );
  }
  
  /// Firebase ProductModel을 사용한 상품 아이템
  Widget _buildProductModelItem(BuildContext context, ProductModel product) {
    final isShare = product.type == ProductType.share;
    
    return MingrrCard(
      margin: const EdgeInsets.only(bottom: AppSizes.gapM),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(
              productId: product.id,
              isShare: isShare,
            ),
          ),
        );
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
              image: product.imageUrls.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(product.imageUrls.first),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: Stack(
              children: [
                if (product.imageUrls.isEmpty)
                  const Center(
                    child: Icon(Icons.image, size: 40, color: AppColors.market),
                  ),
                if (product.status == ProductStatus.reserved)
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
                  product.title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${product.address ?? '위치 미상'} · ${_formatTime(product.createdAt)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                ),
                const SizedBox(height: 6),
                Text(
                  product.priceString,
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
                        product.categoryString,
                        style: const TextStyle(fontSize: 10, color: AppColors.market),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        const Icon(Icons.favorite_border, size: 14, color: AppColors.textHint),
                        const SizedBox(width: 2),
                        Text('${product.likeCount}', style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                        const SizedBox(width: 8),
                        const Icon(Icons.chat_bubble_outline, size: 14, color: AppColors.textHint),
                        const SizedBox(width: 2),
                        Text('${product.chatCount}', style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
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
  
  /// 시간 포맷팅
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inMinutes < 1) return '방금';
    if (diff.inHours < 1) return '${diff.inMinutes}분 전';
    if (diff.inDays < 1) return '${diff.inHours}시간 전';
    return '${diff.inDays}일 전';
  }

  /// 상품 아이템
  Widget _buildProductItem(BuildContext context, int index, ProductType type) {
    final isShare = type == ProductType.share;
    
    return MingrrCard(
      margin: const EdgeInsets.only(bottom: AppSizes.gapM),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(
              productId: 'product_$index',
              isShare: isShare,
            ),
          ),
        );
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

  /// 통합 글쓰기 모달
  void _showAddSheet(BuildContext context, int tabIndex) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MarketWriteSheet(initialType: tabIndex),
    );
  }

  /// 알바 목록 (Firebase 연동)
  Widget _buildJobList(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final jobsAsync = ref.watch(jobsProvider);
        
        return jobsAsync.when(
          data: (jobs) {
            if (jobs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.work_outline, size: 48, color: AppColors.textHint),
                    const SizedBox(height: 16),
                    const Text(
                      '등록된 알바가 없습니다',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(AppSizes.paddingM),
              itemCount: jobs.length,
              itemBuilder: (ctx, index) {
                return _buildJobModelItem(context, jobs[index]);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(child: Text('데이터를 불러올 수 없습니다')),
        );
      },
    );
  }

  /// Firebase JobModel을 사용한 알바 아이템
  Widget _buildJobModelItem(BuildContext context, JobModel job) {
    return MingrrCard(
      margin: const EdgeInsets.only(bottom: AppSizes.gapM),
      onTap: () {
        // TODO: 알바 상세 화면 구현 예정
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 알바 타입 배지
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.market,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  job.typeString,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // 기간
              if (job.periodString.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.schedule, size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        job.periodString,
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              const Spacer(),
              Text(
                _formatJobTime(job.createdAt),
                style: const TextStyle(fontSize: 11, color: AppColors.textHint),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 제목
          Text(
            job.title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          // 위치
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                job.address ?? '위치 미상',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 가격
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                job.priceString,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.market,
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.chat_bubble_outline, size: 14, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text('${job.chatCount}', style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  /// 알바 시간 포맷팅
  String _formatJobTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inMinutes < 1) return '방금';
    if (diff.inHours < 1) return '${diff.inMinutes}분 전';
    if (diff.inDays < 1) return '${diff.inHours}시간 전';
    return '${diff.inDays}일 전';
  }
}

/// 마켓 글쓰기 종류
enum MarketWriteType {
  sell('판매', Icons.sell),
  share('나눔', Icons.volunteer_activism),
  job('알바', Icons.work_outline);

  final String label;
  final IconData icon;
  const MarketWriteType(this.label, this.icon);
}

/// 알바 급여 단위
enum JobPayType {
  total('통합'),
  hourly('시급'),
  daily('일급');

  final String label;
  const JobPayType(this.label);
}

/// 통합 마켓 글쓰기 시트
class _MarketWriteSheet extends StatefulWidget {
  final int initialType;

  const _MarketWriteSheet({required this.initialType});

  @override
  State<_MarketWriteSheet> createState() => _MarketWriteSheetState();
}

class _MarketWriteSheetState extends State<_MarketWriteSheet> {
  late MarketWriteType _selectedType;
  String? _selectedJobCategory;
  JobPayType _payType = JobPayType.total;
  final List<Map<String, String>> _selectedDogs = [];

  @override
  void initState() {
    super.initState();
    _selectedType = MarketWriteType.values[widget.initialType.clamp(0, 2)];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXL)),
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
                    '글쓰기',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ),
                TextButton(
                  onPressed: _onSubmit,
                  child: const Text('완료'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // 본문
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 종류 선택 (판매/나눔/알바)
                  const Text('종류', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: AppSizes.gapS),
                  Row(
                    children: MarketWriteType.values.map((type) {
                      final isSelected = _selectedType == type;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedType = type),
                          child: Container(
                            margin: EdgeInsets.only(right: type != MarketWriteType.job ? 8 : 0),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.market : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? AppColors.market : AppColors.divider,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  type.icon,
                                  size: 18,
                                  color: isSelected ? Colors.white : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  type.label,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? Colors.white : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSizes.gapXL),

                  // 종류별 입력 필드
                  if (_selectedType == MarketWriteType.job) ...[
                    _buildJobFields(),
                  ] else ...[
                    _buildProductFields(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 판매/나눔 입력 필드
  Widget _buildProductFields() {
    final isShare = _selectedType == MarketWriteType.share;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 사진
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
        
        // 제목
        MingrrTextField(
          labelText: '제목',
          hintText: isShare ? '나눔할 물품명을 입력해주세요' : '상품명을 입력해주세요',
        ),
        const SizedBox(height: AppSizes.gapL),
        
        // 가격 (판매일 때만)
        if (!isShare) ...[
          const MingrrTextField(
            labelText: '가격',
            hintText: '가격을 입력해주세요',
            prefixIcon: Icons.attach_money,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: AppSizes.gapL),
        ],
        
        // 설명
        MingrrTextField(
          labelText: isShare ? '나눔 설명' : '상품 설명',
          hintText: isShare ? '나눔 물품에 대해 설명해주세요' : '상품에 대해 자세히 설명해주세요',
          maxLines: 5,
        ),
        const SizedBox(height: AppSizes.gapXXL),
      ],
    );
  }

  /// 알바 입력 필드
  Widget _buildJobFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 알바 유형
        const Text('알바 유형', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSizes.gapS),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['돌봄', '산책', '목욕', '훈련', '기타'].map((type) {
            final isSelected = _selectedJobCategory == type;
            return GestureDetector(
              onTap: () => setState(() => _selectedJobCategory = type),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.market : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.market : AppColors.divider,
                  ),
                ),
                child: Text(
                  type,
                  style: TextStyle(
                    fontSize: 13,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSizes.gapXL),

        // 제목
        const MingrrTextField(
          labelText: '제목',
          hintText: '어떤 도움이 필요하신가요?',
        ),
        const SizedBox(height: AppSizes.gapL),

        // 기간
        const Text('기간', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSizes.gapS),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  // TODO: 시작 날짜 선택 구현 예정
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.divider),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.calendar_today, size: 18, color: AppColors.textSecondary),
                      SizedBox(width: 8),
                      Text('시작일', style: TextStyle(color: AppColors.textHint)),
                    ],
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('~'),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  // TODO: 종료 날짜 선택 구현 예정
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.divider),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.calendar_today, size: 18, color: AppColors.textSecondary),
                      SizedBox(width: 8),
                      Text('종료일', style: TextStyle(color: AppColors.textHint)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.gapL),

        // 강아지 추가
        const Text('돌봄 대상 강아지', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSizes.gapS),
        // 추가된 강아지 목록
        if (_selectedDogs.isNotEmpty) ...[
          ...List.generate(_selectedDogs.length, (index) {
            final dog = _selectedDogs[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.divider.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.pets, size: 20, color: AppColors.market),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dog['name'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '${dog['breed']} · ${dog['weight']}kg',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _selectedDogs.removeAt(index)),
                    child: const Icon(Icons.close, size: 18, color: AppColors.textHint),
                  ),
                ],
              ),
            );
          }),
        ],
        // 강아지 추가 버튼
        GestureDetector(
          onTap: _showAddDogDialog,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.divider, style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, size: 20, color: AppColors.market),
                SizedBox(width: 8),
                Text(
                  '강아지 추가',
                  style: TextStyle(color: AppColors.market, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSizes.gapL),

        // 급여
        const Text('급여', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSizes.gapS),
        // 급여 단위 선택
        Row(
          children: JobPayType.values.map((type) {
            final isSelected = _payType == type;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _payType = type),
                child: Container(
                  margin: EdgeInsets.only(right: type != JobPayType.daily ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.market.withOpacity(0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? AppColors.market : AppColors.divider,
                    ),
                  ),
                  child: Text(
                    type.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? AppColors.market : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSizes.gapS),
        MingrrTextField(
          labelText: '',
          hintText: _payType == JobPayType.total 
              ? '총 금액을 입력해주세요'
              : _payType == JobPayType.hourly 
                  ? '시급을 입력해주세요'
                  : '일급을 입력해주세요',
          prefixIcon: Icons.attach_money,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: AppSizes.gapL),

        // 상세 설명
        const MingrrTextField(
          labelText: '상세 설명',
          hintText: '알바에 대해 자세히 설명해주세요\n(주의사항, 요구사항 등)',
          maxLines: 5,
        ),
        const SizedBox(height: AppSizes.gapXXL),
      ],
    );
  }

  /// 등록된 강아지에서 선택하는 바텀시트
  void _showAddDogDialog() {
    // 데모용 등록된 강아지 목록 (실제로는 Provider에서 가져옴)
    final myDogs = [
      {'id': 'dog_1', 'name': '뽀삐', 'breed': '골든 리트리버', 'weight': '28.5'},
      {'id': 'dog_2', 'name': '초코', 'breed': '말티즈', 'weight': '3.2'},
      {'id': 'dog_3', 'name': '콩이', 'breed': '포메라니안', 'weight': '4.5'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(AppSizes.paddingM),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '강아지 선택',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              '프로필에 등록된 강아지 중 선택해주세요',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            // 등록된 강아지 목록
            ...myDogs.map((dog) {
              final isAlreadySelected = _selectedDogs.any((d) => d['id'] == dog['id']);
              return GestureDetector(
                onTap: isAlreadySelected ? null : () {
                  setState(() {
                    _selectedDogs.add(dog);
                  });
                  Navigator.pop(ctx);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isAlreadySelected 
                        ? AppColors.divider.withOpacity(0.5) 
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isAlreadySelected ? AppColors.divider : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppColors.divider,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.pets, color: AppColors.textHint),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dog['name']!,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isAlreadySelected 
                                    ? AppColors.textHint 
                                    : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${dog['breed']} · ${dog['weight']}kg',
                              style: TextStyle(
                                fontSize: 12,
                                color: isAlreadySelected 
                                    ? AppColors.textHint 
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isAlreadySelected)
                        const Icon(Icons.check_circle, color: AppColors.market, size: 20),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _onSubmit() {
    Navigator.pop(context);
    final message = switch (_selectedType) {
      MarketWriteType.sell => '판매 글이 등록되었습니다!',
      MarketWriteType.share => '나눔 글이 등록되었습니다!',
      MarketWriteType.job => '알바 글이 등록되었습니다!',
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
      ),
    );
  }
}
