import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/theme/feature_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/location_constants.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../providers/marketplace_provider.dart';
import '../../../../core/services/chat_service.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/sheets/mingrr_bottom_sheet.dart';
import '../../../../core/widgets/dialogs/dialogs.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/widgets/sheets/report_sheet.dart';
import '../../../../core/widgets/cards/profile_cards.dart';
import '../../../../core/widgets/modals/guardian_profile_modal.dart';
import '../../../../core/widgets/map/map_widgets.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/models/location_model.dart';
import '../../../../models/marketplace_model.dart';
import '../../../../models/chat_model.dart';
import '../../../../core/providers/refresh_notifier.dart';
import '../../../../core/mixins/distance_calculator_mixin.dart';
import '../../../../core/services/share_service.dart';
import '../../../../core/widgets/buttons/wishlist_button.dart';
import 'package:go_router/go_router.dart';
import 'product_write_screen.dart';

/// ============================================================
/// 상품 상세 화면
/// 
/// 마켓플레이스에서 상품 클릭 시 표시
/// - 상품 이미지
/// - 상품 정보 (제목, 가격, 설명)
/// - 판매자 정보
/// - 채팅하기 버튼
/// - 신고 기능
/// - 본인 글일 경우 수정/삭제 기능
/// ============================================================

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;
  final ProductModel? product; // 직접 전달받은 상품 데이터

  const ProductDetailScreen({
    super.key,
    required this.productId,
    this.product,
  });

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen>
    with DistanceCalculatorMixin {
  FirebaseService get _firebaseService => FirebaseService();
  
  /// Provider 기반 FirestoreService 접근
  /// build 시점 이후에만 사용 가능
  FirestoreService get _firestoreService => ref.read(firestoreServiceProvider);
  
  bool _isDeleting = false;
  bool _isWishlistLoading = false;
  String? _sellerNickname;

  /// 거리 문자열 계산 (Mixin 활용)
  String _getDistanceString(ProductModel? product) {
    return getDistanceFromLocation(product?.location, product?.address);
  }

  @override
  void initState() {
    super.initState();
    // 판매자 닉네임 로드는 별도로 처리
  }
  
  Future<void> _loadSellerNickname(String? sellerId) async {
    if (sellerId == null || _sellerNickname != null) return;
    try {
      final user = await _firestoreService.getUser(sellerId);
      if (mounted && user != null) {
        setState(() => _sellerNickname = user.nickname);
      }
    } catch (e) {
      // 닉네임 로드 실패 시 무시
    }
  }

  bool _isOwner(ProductModel? product) {
    final currentUserId = _firebaseService.currentUserId;
    return currentUserId != null && product?.sellerId == currentUserId;
  }

  /// 찜하기 토글 (Provider 기반)
  Future<void> _toggleWishlist(ProductModel product) async {
    final userId = _firebaseService.currentUserId;
    if (userId == null) {
      MingrrSnackBar.warning(context, '로그인이 필요합니다');
      return;
    }
    if (_isWishlistLoading) return;

    setState(() => _isWishlistLoading = true);

    try {
      final isNowLiked = await ref.read(marketplaceNotifierProvider.notifier).toggleProductLike(product.id);
      if (mounted) {
        setState(() => _isWishlistLoading = false);
        MingrrSnackBar.success(context, isNowLiked ? '찜 목록에 추가했어요' : '찜 목록에서 제거했어요');
        // Provider 새로고침으로 최신 데이터 반영
        ref.invalidate(productDetailProvider(widget.productId));
        ref.invalidate(isProductLikedProvider(widget.productId));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isWishlistLoading = false);
        ErrorHandler.showError(context, e, tag: 'ProductDetail', operation: '찜하기');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Provider로 상품 데이터 조회
    final productAsync = ref.watch(productDetailProvider(widget.productId));
    final isLikedAsync = ref.watch(isProductLikedProvider(widget.productId));
    
    return productAsync.when(
      data: (product) {
        if (product == null) {
          return Scaffold(
            appBar: const MingrrAppBar(title: '상품'),
            body: const MingrrEmptyState(
              icon: AppIcons.market,
              title: '상품을 찾을 수 없어요',
              subtitle: '삭제되었거나 존재하지 않는 상품이에요',
            ),
          );
        }
        // 판매자 닉네임 로드
        _loadSellerNickname(product.sellerId);
        final isLiked = isLikedAsync.valueOrNull ?? false;
        return _buildContent(context, product, isLiked);
      },
      loading: () => Scaffold(
        appBar: const MingrrAppBar(title: '상품'),
        body: const MingrrLoadingState(type: MingrrLoadingType.market, message: '상품 정보를 불러오고 있어요'),
      ),
      error: (e, _) => Scaffold(
        appBar: const MingrrAppBar(title: '상품'),
        body: MingrrErrorState(
          onRetry: () => ref.invalidate(productDetailProvider(widget.productId)),
        ),
      ),
    );
  }
  
  /// 상품 상세 컨텐츠 빌드
  Widget _buildContent(BuildContext context, ProductModel product, bool isLiked) {
    return Scaffold(
      backgroundColor: context.detailBackground,
      body: CustomScrollView(
        slivers: [
          // 이미지 헤더
          _buildImageHeader(context, product),
          
          // 본문 컨텐츠
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.paddingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 판매자 정보
                  _buildSellerInfo(context, product),
                  const MingrrDivider.section(),
                  
                  // 상품 정보
                  _buildProductInfo(product),
                  const SizedBox(height: AppSizes.gapXL),
                  
                  // 상품 설명
                  _buildDescription(product),
                  
                  // 거래 희망 지역
                  if (product.location != null) ...[
                    const SizedBox(height: AppSizes.gapXL),
                    _buildLocationSection(product),
                  ],
                  
                  // 하단 여백 (버튼 공간)
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      // 하단 고정 버튼
      bottomNavigationBar: _buildBottomButton(context, product, isLiked),
    );
  }

  bool _isShare(ProductModel product) => product.type == ProductType.share;

  /// 이미지 헤더
  Widget _buildImageHeader(BuildContext context, ProductModel product) {
    return MingrrImageHeader(
      imageUrls: product.imageUrls,
      expandedHeight: 300,
      onShare: () => ShareService.shareProduct(context, product),
      onMore: () => _showMoreOptions(context, product),
      placeholder: MingrrImage(
        accentColor: context.features.market,
        placeholderIcon: AppIcons.image,
      ),
    );
  }

  /// 판매자 정보
  Widget _buildSellerInfo(BuildContext context, ProductModel product) {
    return GuardianProfileCard(
      name: _sellerNickname ?? '판매자',
      kkosunnaeScore: 50.0,
      accentColor: context.features.market,
      onTap: () => _showSellerProfile(context, product),
    );
  }

  /// 판매자 프로필 모달 표시
  void _showSellerProfile(BuildContext context, ProductModel product) {
    showGuardianProfileFromFirestore(
      context,
      userId: product.sellerId,
      fallbackName: _sellerNickname ?? '판매자',
    );
  }

  /// 상품 정보
  Widget _buildProductInfo(ProductModel product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 카테고리
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingS, vertical: AppSizes.paddingXS),
          decoration: BoxDecoration(
            color: context.features.market.withValues(alpha: AppOpacity.o10),
            borderRadius: BorderRadius.circular(AppSizes.radiusS),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(product.category.icon, size: 12, color: context.features.market),
              const SizedBox(width: AppSizes.gapXS),
              Text(
                product.category.label,
                style: AppTextStyles.labelLarge(context).copyWith(color: context.features.market),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.gapM),
        // 제목
        Text(
          product.title,
          style: AppTextStyles.headlineMedium(context),
        ),
        const SizedBox(height: AppSizes.gapS),
        // 시간, 조회수, 거리
        Text(
          '${_getDistanceString(product)} · ${formatRelativeTime(product.createdAt)} · 조회 ${product.viewCount}',
          style: AppTextStyles.bodySmall(context),
        ),
        const SizedBox(height: AppSizes.gapL),
        // 가격
        Text(
          _isShare(product) ? '무료나눔' : '${formatPrice(product.price)}원',
          style: AppTextStyles.displayMedium(context).withWeight(FontWeight.w700).withColor(
            _isShare(product) ? context.features.walk : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  /// 상품 설명
  Widget _buildDescription(ProductModel product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '상품 설명',
          style: AppTextStyles.headlineSmall(context),
        ),
        const SizedBox(height: AppSizes.gapM),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSizes.paddingL),
          decoration: BoxDecoration(
            color: context.sectionBackground,
            borderRadius: BorderRadius.circular(AppSizes.radiusS),
          ),
          child: Text(
            product.description,
            style: AppTextStyles.bodyMedium(context).copyWith(height: 1.6),
          ),
        ),
      ],
    );
  }

  /// 거래 희망 지역 섹션
  Widget _buildLocationSection(ProductModel product) {
    final location = product.location;
    if (location == null) return const SizedBox.shrink();
    
    // 주소가 없거나 GeoPoint 인스턴스 문자열인 경우 처리
    String? displayAddress = product.address;
    if (displayAddress == null || 
        displayAddress.isEmpty || 
        displayAddress.contains('Instance of') ||
        displayAddress.contains('GeoPoint')) {
      displayAddress = LocationConstants.noLocationText;
    }
    
    final locationData = LocationData(
      latitude: location.latitude,
      longitude: location.longitude,
      fullAddress: displayAddress,
      shortAddress: displayAddress,
    );
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '거래 희망 지역',
          style: AppTextStyles.headlineSmall(context),
        ),
        const SizedBox(height: AppSizes.gapM),
        LocationDisplayCard(
          location: locationData,
          accentColor: context.features.market,
          editable: false,
          showMiniMap: true,
          miniMapHeight: 150,
          onTap: () => _showFullMap(locationData),
        ),
      ],
    );
  }
  
  /// 전체 지도 보기
  void _showFullMap(LocationData location) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: ResponsiveUtils.heightPercent(context, 0.7),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSizes.radiusL)),
        ),
        child: Column(
          children: [
            // 헤더
            Container(
              padding: const EdgeInsets.all(AppSizes.paddingL),
              child: Row(
                children: [
                  const SizedBox(width: 40),
                  Expanded(
                    child: Text(
                      '거래 희망 지역',
                      style: AppTextStyles.headlineSmall(context),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    icon: Icon(AppIcons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // 지도
            Expanded(
              child: MapViewWidget(
                centerLocation: location,
                accentColor: context.features.market,
                height: double.infinity,
              ),
            ),
            // 주소 정보
            SafeArea(
              child: Container(
                padding: const EdgeInsets.all(AppSizes.paddingL),
                child: Row(
                  children: [
                    Icon(AppIcons.location, color: context.features.market),
                    const SizedBox(width: AppSizes.gapS),
                    Expanded(
                      child: Text(
                        location.displayAddress,
                        style: AppTextStyles.titleMedium(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 하단 고정 버튼
  Widget _buildBottomButton(BuildContext context, ProductModel product, bool isLiked) {
    return MingrrBottomButtonBar(
      child: Row(
        children: [
          // 찜하기 버튼 (공통 컴포넌트)
          WishlistButton(
            isWishlisted: isLiked,
            isLoading: _isWishlistLoading,
            count: product.likeCount,
            onTap: () => _toggleWishlist(product),
            activeColor: context.features.market,
          ),
          const SizedBox(width: AppSizes.gapM),
          // 가격 표시
          Expanded(
            child: Text(
              _isShare(product) ? '무료나눔' : '${formatPrice(product.price)}원',
              style: AppTextStyles.headlineMedium(context).withWeight(FontWeight.w700).withColor(
                _isShare(product) ? context.features.walk : Theme.of(context).colorScheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: AppSizes.gapM),
          // 채팅하기 버튼
          Expanded(
            child: MingrrButton(
              text: '채팅하기',
              onPressed: _isOwner(product) ? null : () => _startChat(product),
              backgroundColor: context.features.market,
              textColor: Colors.white,
              height: 48,
            ),
          ),
        ],
      ),
    );
  }

  /// 더보기 옵션 메뉴
  void _showMoreOptions(BuildContext context, ProductModel product) {
    showDetailOptionsSheet(
      context: context,
      isOwner: _isOwner(product),
      onEdit: () => _editProduct(product),
      onDelete: () => _confirmDelete(product),
      onBlock: () => _blockSeller(context, product),
      blockLabel: '이 판매자 차단하기',
      onReport: () => showReportSheet(
        context,
        targetId: widget.productId,
        targetName: '이 상품',
        targetType: ReportTargetType.product,
      ),
    );
  }

  /// 판매자 차단
  Future<void> _blockSeller(BuildContext context, ProductModel product) async {
    final currentUserId = _firebaseService.currentUserId;
    if (currentUserId == null) {
      MingrrSnackBar.warning(context, '로그인이 필요합니다');
      return;
    }

    final sellerId = product.sellerId;
    if (sellerId == currentUserId) {
      MingrrSnackBar.warning(context, '본인은 차단할 수 없습니다');
      return;
    }

    // 차단 확인 시트
    showConfirmSheet(
      context,
      type: ConfirmSheetType.sellerBlock,
      onConfirm: () async {
        try {
          await _firestoreService.blockUser(currentUserId, sellerId);
          if (!context.mounted) return;
          MingrrSnackBar.success(context, '판매자를 차단했습니다');
          Navigator.pop(context); // 상세 화면 닫기
        } catch (e) {
          if (!context.mounted) return;
          ErrorHandler.showError(context, e, tag: 'ProductDetail', operation: '판매자 차단');
        }
      },
    );
  }

  /// 상품 수정
  void _editProduct(ProductModel product) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductWriteScreen(
          product: product,
          initialType: product.type,
        ),
      ),
    );
    
    // 수정 성공 시 데이터 새로고침
    if (result == true) {
      ref.invalidate(productDetailProvider(widget.productId));
    }
  }

  /// 삭제 확인 바텀시트
  void _confirmDelete(ProductModel product) {
    if (_isDeleting) return; // 이미 삭제 중이면 무시
    
    showConfirmSheet(
      context,
      type: ConfirmSheetType.productDelete,
      onConfirm: () => _deleteProduct(product),
    );
  }

  /// 상품 삭제
  Future<void> _deleteProduct(ProductModel product) async {
    setState(() => _isDeleting = true);
    
    try {
      await _firestoreService.deleteProduct(product.id);
      
      if (mounted) {
        // 리스트 새로고침 트리거
        ref.read(marketRefreshProvider.notifier).state++;
        Navigator.pop(context, true); // 삭제 성공 알림
        MingrrSnackBar.success(context, '상품이 삭제되었습니다');
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.handle(
          context,
          error: e,
          tag: 'ProductDetail',
          operation: '상품 삭제',
          themeColor: context.features.market,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  /// 판매자와 채팅 시작
  Future<void> _startChat(ProductModel product) async {
    final myUserId = _firebaseService.currentUserId;
    if (myUserId == null) {
      MingrrSnackBar.warning(context, '로그인이 필요합니다');
      return;
    }

    // 본인 상품이면 채팅 불가
    if (product.sellerId == myUserId) return;

    try {
      final chatService = ChatService();
      
      // 내 정보 가져오기
      final myUserDoc = await _firebaseService.usersCollection.doc(myUserId).get();
      final myUserData = myUserDoc.data();
      
      // 판매자 정보 가져오기
      final sellerDoc = await _firebaseService.usersCollection.doc(product.sellerId).get();
      final sellerData = sellerDoc.data();

      final myInfo = ChatParticipant(
        id: myUserId,
        nickname: myUserData?['nickname'] ?? '사용자',
        profileImageUrl: myUserData?['profileImageUrl'],
      );

      final sellerInfo = ChatParticipant(
        id: product.sellerId,
        nickname: sellerData?['nickname'] ?? '판매자',
        profileImageUrl: sellerData?['profileImageUrl'],
      );

      // 채팅방 생성 또는 기존 채팅방 찾기
      final chatRoom = await chatService.getOrCreateChatRoom(
        myUserId: myUserId,
        otherUserId: product.sellerId,
        type: 'market',
        myInfo: myInfo,
        otherInfo: sellerInfo,
        relatedId: product.id,
      );

      if (mounted) {
        // go_router를 사용하여 채팅 탭으로 이동 (하단 메뉴 동기화)
        context.go('/chat/${chatRoom.id}');
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e, tag: 'ProductDetail', operation: '채팅 시작');
      }
    }
  }
}
