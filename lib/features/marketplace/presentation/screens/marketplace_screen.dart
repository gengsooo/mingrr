import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/feature_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/location_constants.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/sheets/mingrr_bottom_sheet.dart';
import '../../../../core/widgets/cards/product_card.dart';
import '../../../../core/widgets/search_screen.dart';
import '../../../../core/widgets/navigation/top_navigation.dart';
import '../../../../core/widgets/navigation/appbar_actions.dart';
import '../../../../core/widgets/filter_components.dart';
import '../../../../core/widgets/refresh_wrapper.dart';
import '../../../../core/widgets/empty_states/location_required_empty_state.dart';
import '../../../../models/marketplace_model.dart';
import '../../../../core/providers/refresh_notifier.dart';
import '../../../../core/providers/location_verification_provider.dart';
import '../providers/marketplace_provider.dart';
import 'product_detail_screen.dart';
import 'product_write_screen.dart';
import 'job_detail_screen.dart';
import '../../../../core/utils/responsive_utils.dart';

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

/// 거리 필터 - 기본값 5km
final _distanceFilterProvider = StateProvider<double>((ref) => LocationConstants.defaultRadiusKm);

class MarketplaceScreen extends ConsumerStatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  ConsumerState<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends ConsumerState<MarketplaceScreen> {
  final ScrollController _productScrollController = ScrollController();
  final ScrollController _jobScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _productScrollController.addListener(_onProductScroll);
    _jobScrollController.addListener(_onJobScroll);
  }

  @override
  void dispose() {
    _productScrollController.removeListener(_onProductScroll);
    _jobScrollController.removeListener(_onJobScroll);
    _productScrollController.dispose();
    _jobScrollController.dispose();
    super.dispose();
  }

  void _onProductScroll() {
    if (_productScrollController.position.pixels >=
        _productScrollController.position.maxScrollExtent - 200) {
      final selectedTab = ref.read(_selectedTabProvider);
      final distanceFilter = ref.read(_distanceFilterProvider);
      final type = selectedTab == 0 ? ProductType.sell : ProductType.share;
      ref.read(paginatedProductsProvider((type: type, radiusKm: distanceFilter)).notifier).loadMore();
    }
  }

  void _onJobScroll() {
    if (_jobScrollController.position.pixels >=
        _jobScrollController.position.maxScrollExtent - 200) {
      ref.read(paginatedJobsProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedTab = ref.watch(_selectedTabProvider);
    final selectedCategory = ref.watch(_selectedCategoryProvider);
    final distanceFilter = ref.watch(_distanceFilterProvider);

    // 새로고침 트리거 감지 (등록/수정/삭제 후 자동 새로고침)
    ref.listen(marketRefreshProvider, (prev, next) {
      if (prev != next) {
        final type = selectedTab == 0 ? ProductType.sell : ProductType.share;
        ref.read(paginatedProductsProvider((type: type, radiusKm: distanceFilter)).notifier).refresh();
        ref.read(paginatedJobsProvider.notifier).refresh();
      }
    });

    // 탭 정의 (판매 / 나눔 / 알바)
    final tabs = [
      MingrrTabItem(label: '판매', icon: Icons.sell, color: context.features.market),
      MingrrTabItem(label: '나눔', icon: Icons.volunteer_activism, color: context.features.market),
      MingrrTabItem(label: '알바', icon: Icons.work_outline, color: context.features.market),
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

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? colorScheme.surface : context.features.marketContainer,
      appBar: AppBar(
        title: const Text('마켓'),
        actions: [
          AppBarActionButton.search(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => SearchScreen(
                    searchType: SearchType.market,
                    accentColor: ctx.features.market,
                  ),
                ),
              );
            },
          ),
          AppBarActionButton.notification(),
          AppBarActionButton.profile(backgroundColor: Theme.of(context).scaffoldBackgroundColor),
        ],
      ),
      body: Column(
        children: [
          // 2개 탭 (판매 / 나눠)
          Container(
            color: isDark ? colorScheme.surface : context.features.marketContainer,
            child: MingrrMainTabBar(
              tabs: tabs,
              selectedIndex: selectedTab,
              onTabSelected: (index) {
                ref.read(_selectedTabProvider.notifier).state = index;
              },
            ),
          ),
          
          // 위치/거리 필터 바
          LocationDistanceBar(
            accentColor: context.features.market,
            currentDistance: distanceFilter,
            distanceOptions: LocationConstants.marketDistanceOptions,
            onDistanceChanged: (distance) {
              ref.read(_distanceFilterProvider.notifier).state = distance;
            },
          ),
          
          // 카테고리 필터
          MingrrCategoryChips(
            title: '카테고리',
            categories: categories.map((c) => c.label).toList(),
            selectedIndex: selectedCategory,
            onSelected: (index) {
              ref.read(_selectedCategoryProvider.notifier).state = index;
            },
            accentColor: context.features.market,
          ),
          
          // 상품/알바 목록
          Expanded(
            child: _buildContent(context, selectedTab, distanceFilter),
          ),
        ],
      ),
      floatingActionButton: MingrrFAB.write(
        onPressed: () => _showAddSheet(context, selectedTab),
        backgroundColor: context.features.market,
        tooltip: '상품/알바 등록',
      ),
    );
  }

  /// 탭별 컨텐츠 (위치 인증 상태 확인)
  Widget _buildContent(BuildContext context, int selectedTab, double distanceFilter) {
    // 위치 인증 상태 확인
    final userAsync = ref.watch(currentUserStreamProvider);
    final user = userAsync.valueOrNull;
    final isLocationVerified = user?.isLocationVerified ?? false;
    
    // 위치 미인증 시 빈 화면 표시
    if (!isLocationVerified) {
      return LocationRequiredEmptyState(
        type: LocationRequiredType.market,
        accentColor: context.features.market,
      );
    }
    
    // 탭별 컨텐츠
    if (selectedTab == 2) {
      return _buildJobList(context);
    } else {
      return _buildProductList(context, selectedTab == 0 ? ProductType.sell : ProductType.share);
    }
  }

  /// 상품 목록 (Firebase 연동 + 거리 필터링 + 페이지네이션)
  Widget _buildProductList(BuildContext context, ProductType type) {
    final distanceFilter = ref.watch(_distanceFilterProvider);
    final paginatedState = ref.watch(paginatedProductsProvider((type: type, radiusKm: distanceFilter)));
    
    // 초기 로딩 상태
    if (paginatedState.isInitialLoading) {
      return MingrrLoadingState(
        type: MingrrLoadingType.market,
        message: '상품을 불러오고 있어요',
        timeout: AppSizes.loadingTimeout,
        onRetry: () => ref.read(paginatedProductsProvider((type: type, radiusKm: distanceFilter)).notifier).loadInitial(),
      );
    }
    
    // 에러 상태
    if (paginatedState.hasError && paginatedState.items.isEmpty) {
      return MingrrErrorState(
        title: '데이터를 불러올 수 없어요',
        subtitle: '잠시 후 다시 시도해주세요',
        onRetry: () => ref.read(paginatedProductsProvider((type: type, radiusKm: distanceFilter)).notifier).loadInitial(),
      );
    }
    
    // 빈 상태
    if (paginatedState.isEmpty) {
      return MingrrEmptyState(
        icon: type == ProductType.sell ? Icons.sell : Icons.volunteer_activism,
        title: '아직 데이터가 없어요',
        subtitle: '거리를 늘리거나 다른 카테고리를 확인해보세요',
        accentColor: context.features.market,
        onRefresh: () async {
          await ref.read(paginatedProductsProvider((type: type, radiusKm: distanceFilter)).notifier).refresh();
        },
      );
    }
    
    // 데이터 있음
    return MingrrRefreshWrapper(
      color: context.features.market,
      onRefresh: () async {
        await ref.read(paginatedProductsProvider((type: type, radiusKm: distanceFilter)).notifier).refresh();
      },
      child: ListView.builder(
        controller: _productScrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSizes.paddingM),
        itemCount: paginatedState.items.length + (paginatedState.hasMore ? 1 : 0),
        itemBuilder: (ctx, index) {
          // 로딩 인디케이터
          if (index >= paginatedState.items.length) {
            return const Padding(
              padding: EdgeInsets.all(AppSizes.paddingL),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          return MingrrAnimatedListItem(
            index: index,
            child: _buildProductModelItem(context, paginatedState.items[index]),
          );
        },
      ),
    );
  }

  /// Firebase ProductWithDistance를 사용한 상품 아이템
  Widget _buildProductModelItem(BuildContext context, ProductWithDistance productWithDistance) {
    return ProductCard(
      product: productWithDistance.product,
      distanceString: productWithDistance.distanceString,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(
              productId: productWithDistance.product.id,
              product: productWithDistance.product,
            ),
          ),
        );
      },
    );
  }

  /// 통합 글쓰기 화면 이동
  void _showAddSheet(BuildContext context, int tabIndex) async {
    // 모든 탭에서 ProductWriteScreen 사용 (통합)
    final ProductType initialType;
    switch (tabIndex) {
      case 0:
        initialType = ProductType.sell;
        break;
      case 1:
        initialType = ProductType.share;
        break;
      case 2:
        initialType = ProductType.job;
        break;
      default:
        initialType = ProductType.sell;
    }
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductWriteScreen(initialType: initialType),
      ),
    );
    
    // 등록 성공 시 목록 새로고침
    if (result == true && context.mounted) {
      // 상태 관리가 자동 해제 모드이므로 자동으로 새로고침됨
    }
  }

  /// 알바 목록 (Firebase 연동 + 페이지네이션)
  Widget _buildJobList(BuildContext context) {
    final paginatedState = ref.watch(paginatedJobsProvider);
    
    // 초기 로딩 상태
    if (paginatedState.isInitialLoading) {
      return MingrrLoadingState(
        type: MingrrLoadingType.market,
        message: '알바를 불러오고 있어요',
        timeout: AppSizes.loadingTimeout,
        onRetry: () => ref.read(paginatedJobsProvider.notifier).loadInitial(),
      );
    }
    
    // 에러 상태
    if (paginatedState.hasError && paginatedState.items.isEmpty) {
      return MingrrErrorState(
        title: '일시적인 오류가 발생했어요',
        subtitle: '잠시 후 다시 시도해주세요',
        onRetry: () => ref.read(paginatedJobsProvider.notifier).loadInitial(),
      );
    }
    
    // 빈 상태
    if (paginatedState.isEmpty) {
      return MingrrEmptyState(
        icon: Icons.work_outline,
        title: '아직 데이터가 없어요',
        subtitle: '새로운 알바를 등록해보세요',
        accentColor: context.features.market,
        onRefresh: () async {
          await ref.read(paginatedJobsProvider.notifier).refresh();
        },
      );
    }
    
    // 데이터 있음
    return MingrrRefreshWrapper(
      color: context.features.market,
      onRefresh: () async {
        await ref.read(paginatedJobsProvider.notifier).refresh();
      },
      child: ListView.builder(
        controller: _jobScrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSizes.paddingM),
        itemCount: paginatedState.items.length + (paginatedState.hasMore ? 1 : 0),
        itemBuilder: (ctx, index) {
          // 로딩 인디케이터
          if (index >= paginatedState.items.length) {
            return const Padding(
              padding: EdgeInsets.all(AppSizes.paddingL),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          return MingrrAnimatedListItem(
            index: index,
            child: _buildJobModelItem(context, paginatedState.items[index]),
          );
        },
      ),
    );
  }

  /// Firebase JobWithDistance를 사용한 알바 아이템
  Widget _buildJobModelItem(BuildContext context, JobWithDistance jobWithDistance) {
    return JobCard(
      job: jobWithDistance.job,
      distanceString: jobWithDistance.distanceString,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => JobDetailScreen(jobId: jobWithDistance.job.id),
          ),
        );
      },
    );
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
  final List<Map<String, String>> _selectedPets = [];
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _selectedType = MarketWriteType.values[widget.initialType.clamp(0, 2)];
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }

  Future<void> _selectDate(bool isStart) async {
    final now = DateTime.now();
    final initialDate = isStart 
        ? (_startDate ?? now) 
        : (_endDate ?? _startDate ?? now);
    
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: isStart ? now : (_startDate ?? now),
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: context.features.market,
              surface: Colors.white,
              onSurface: Colors.black87,
              surfaceContainerHighest: Colors.white,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: ResponsiveUtils.heightPercent(context, 0.9),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXL)),
      ),
      child: Column(
        children: [
          const BottomSheetHandle(),
          // 헤더
          Padding(
            padding: const EdgeInsets.all(AppSizes.paddingM),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Text(
                    '글쓰기',
                    style: AppTextStyles.headlineSmall(context),
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
          const MingrrDivider(),
          // 본문
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 종류 선택 (판매/나눔/알바)
                  Text('종류', style: AppTextStyles.titleMedium(context)),
                  const SizedBox(height: AppSizes.gapS),
                  Row(
                    children: MarketWriteType.values.map((type) {
                      final isSelected = _selectedType == type;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedType = type),
                          child: Container(
                            margin: EdgeInsets.only(right: type != MarketWriteType.job ? 8 : 0),
                            padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingM),
                            decoration: BoxDecoration(
                              color: isSelected ? context.features.market : Colors.transparent,
                              borderRadius: BorderRadius.circular(AppSizes.radiusS),
                              border: Border.all(
                                color: isSelected ? context.features.market : Theme.of(context).colorScheme.outline,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  type.icon,
                                  size: 18,
                                  color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: AppSizes.gapSM),
                                Text(
                                  type.label,
                                  style: AppTextStyles.titleMedium(context).withWeight(FontWeight.w600).withColor(
                                    isSelected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
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
        Text('사진', style: AppTextStyles.titleMedium(context)),
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
                  border: Border.all(color: Theme.of(context).colorScheme.outline),
                  borderRadius: BorderRadius.circular(AppSizes.radiusM),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt, color: Theme.of(context).colorScheme.outlineVariant),
                    const SizedBox(height: AppSizes.gapXS),
                    Text('0/10', style: AppTextStyles.captionSmall(context)),
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
        Text('알바 유형', style: AppTextStyles.titleMedium(context)),
        const SizedBox(height: AppSizes.gapS),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['돌봄', '산책', '목욕', '훈련', '기타'].map((type) {
            final isSelected = _selectedJobCategory == type;
            return GestureDetector(
              onTap: () => setState(() => _selectedJobCategory = type),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL, vertical: AppSizes.paddingS),
                decoration: BoxDecoration(
                  color: isSelected ? context.features.market : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSizes.radiusL),
                  border: Border.all(
                    color: isSelected ? context.features.market : Theme.of(context).colorScheme.outline,
                  ),
                ),
                child: Text(
                  type,
                  style: AppTextStyles.bodyMedium(context).withColor(
                    isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
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
        Text('기간', style: AppTextStyles.titleMedium(context)),
        const SizedBox(height: AppSizes.gapS),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _selectDate(true),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM, vertical: AppSizes.paddingM),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _startDate != null 
                          ? context.features.market 
                          : Theme.of(context).colorScheme.outline,
                    ),
                    borderRadius: BorderRadius.circular(AppSizes.radiusS),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today, 
                        size: 18, 
                        color: _startDate != null 
                            ? context.features.market 
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppSizes.gapS),
                      Text(
                        _startDate != null ? _formatDate(_startDate!) : '시작일',
                        style: TextStyle(
                          color: _startDate != null 
                              ? Theme.of(context).colorScheme.onSurface 
                              : Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSizes.paddingS),
              child: Text('~'),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => _selectDate(false),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM, vertical: AppSizes.paddingM),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _endDate != null 
                          ? context.features.market 
                          : Theme.of(context).colorScheme.outline,
                    ),
                    borderRadius: BorderRadius.circular(AppSizes.radiusS),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today, 
                        size: 18, 
                        color: _endDate != null 
                            ? context.features.market 
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppSizes.gapS),
                      Text(
                        _endDate != null ? _formatDate(_endDate!) : '종료일',
                        style: TextStyle(
                          color: _endDate != null 
                              ? Theme.of(context).colorScheme.onSurface 
                              : Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.gapL),

        // 반려동물 추가
        Text('돌봄 대상 반려동물', style: AppTextStyles.titleMedium(context)),
        const SizedBox(height: AppSizes.gapS),
        // 추가된 반려동물 목록
        if (_selectedPets.isNotEmpty) ...[
          ...List.generate(_selectedPets.length, (index) {
            final pet = _selectedPets[index];
            return Container(
              margin: const EdgeInsets.only(bottom: AppSizes.paddingS),
              padding: const EdgeInsets.all(AppSizes.paddingM),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: AppOpacity.o30),
                borderRadius: BorderRadius.circular(AppSizes.radiusS),
              ),
              child: Row(
                children: [
                  Icon(Icons.pets, size: 20, color: context.features.market),
                  const SizedBox(width: AppSizes.gapS),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pet['name'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '${pet['breed']} · ${pet['weight']}kg',
                          style: AppTextStyles.caption(context),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _selectedPets.removeAt(index)),
                    child: Icon(Icons.close, size: 18, color: Theme.of(context).colorScheme.outlineVariant),
                  ),
                ],
              ),
            );
          }),
        ],
        // 반려동물 추가 버튼
        GestureDetector(
          onTap: _showAddPetDialog,
          child: Container(
            padding: const EdgeInsets.all(AppSizes.paddingM),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.outline, style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(AppSizes.radiusS),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, size: 20, color: context.features.market),
                const SizedBox(width: AppSizes.gapS),
                Text(
                  '반려동물 추가',
                  style: TextStyle(color: context.features.market, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSizes.gapL),

        // 급여
        Text('급여', style: AppTextStyles.titleMedium(context)),
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
                  padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingS),
                  decoration: BoxDecoration(
                    color: isSelected ? context.features.market.withValues(alpha: AppOpacity.o10) : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppSizes.radiusXS),
                    border: Border.all(
                      color: isSelected ? context.features.market : Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  child: Text(
                    type.label,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium(context)
                        .withWeight(isSelected ? FontWeight.w600 : FontWeight.normal)
                        .withColor(isSelected ? context.features.market : Theme.of(context).colorScheme.onSurfaceVariant),
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

  /// 등록된 반려동물에서 선택하는 바텀시트
  void _showAddPetDialog() {
    // 데모용 등록된 반려동물 목록 (실제로는 Provider에서 가져옴)
    final myPets = [
      {'id': 'pet_1', 'name': '뽀삐', 'breed': '골든 리트리버', 'weight': '28.5'},
      {'id': 'pet_2', 'name': '초코', 'breed': '말티즈', 'weight': '3.2'},
      {'id': 'pet_3', 'name': '콩이', 'breed': '포메라니안', 'weight': '4.5'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM),
        decoration: BoxDecoration(
          color: Theme.of(ctx).colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.bottomSheetRadius)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: BottomSheetHandle()),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingS),
              child: Text(
                '반려동물 선택',
                style: AppTextStyles.headlineSmall(context),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppSizes.gapS),
            Text(
              '프로필에 등록된 반려동물 중 선택해주세요',
              style: AppTextStyles.bodySmall(context),
            ),
            const SizedBox(height: AppSizes.gapL),
            // 등록된 반려동물 목록
            ...myPets.map((pet) {
              final isAlreadySelected = _selectedPets.any((d) => d['id'] == pet['id']);
              return GestureDetector(
                onTap: isAlreadySelected ? null : () {
                  setState(() {
                    _selectedPets.add(pet);
                  });
                  Navigator.pop(ctx);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: AppSizes.paddingS),
                  padding: const EdgeInsets.all(AppSizes.paddingM),
                  decoration: BoxDecoration(
                    color: isAlreadySelected 
                        ? Theme.of(context).colorScheme.outline.withValues(alpha: AppOpacity.o50) 
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppSizes.radiusS),
                    border: Border.all(
                      color: isAlreadySelected ? Theme.of(context).colorScheme.outline : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.outline,
                          borderRadius: BorderRadius.circular(AppSizes.radiusS),
                        ),
                        child: Icon(Icons.pets, color: Theme.of(context).colorScheme.outlineVariant),
                      ),
                      const SizedBox(width: AppSizes.gapM),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pet['name']!,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isAlreadySelected 
                                    ? Theme.of(context).colorScheme.outlineVariant 
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: AppSizes.gapXXS),
                            Text(
                              '${pet['breed']} · ${pet['weight']}kg',
                              style: AppTextStyles.bodySmall(context).withColor(
                                isAlreadySelected 
                                    ? Theme.of(context).colorScheme.outlineVariant 
                                    : Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isAlreadySelected)
                        Icon(Icons.check_circle, color: context.features.market, size: 20),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: AppSizes.gapS),
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
    MingrrSnackBar.success(context, message);
  }
}
