import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/feature_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/chat_service.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/mingrr_bottom_sheet.dart';
import '../../../../core/widgets/dialogs/dialogs.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/widgets/report_sheet.dart';
import '../../../../core/widgets/profile_cards.dart';
import '../../../../core/widgets/guardian_profile_modal.dart';
import '../../../../core/widgets/map/map_widgets.dart';
import '../../../../core/models/location_model.dart';
import '../../../../models/marketplace_model.dart';
import '../../../../models/chat_model.dart';
import '../../../chat/presentation/screens/chat_detail_screen.dart';
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

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseService _firebaseService = FirebaseService();
  
  ProductModel? _product;
  bool _isLoading = true;
  bool _isDeleting = false;
  bool _isWishlisted = false;
  bool _isWishlistLoading = false;
  String? _sellerNickname;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _product = widget.product;
      _isLoading = false;
      _loadSellerNickname();
      _loadWishlistStatus();
    } else {
      _loadProduct();
    }
  }

  Future<void> _loadProduct() async {
    try {
      final product = await _firestoreService.getProduct(widget.productId);
      if (mounted) {
        setState(() {
          _product = product;
          _isLoading = false;
        });
        _loadSellerNickname();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ErrorHandler.handle(
          context,
          error: e,
          tag: 'ProductDetail',
          operation: '상품 정보 로드',
          themeColor: context.features.market,
          onRetry: _loadProduct,
        );
      }
    }
  }
  
  Future<void> _loadSellerNickname() async {
    if (_product?.sellerId == null) return;
    try {
      final user = await _firestoreService.getUser(_product!.sellerId);
      if (mounted && user != null) {
        setState(() => _sellerNickname = user.nickname);
      }
    } catch (e) {
      // 닉네임 로드 실패 시 무시
    }
  }

  /// 찜 상태 로드
  Future<void> _loadWishlistStatus() async {
    final userId = _firebaseService.currentUserId;
    if (userId == null || _product == null) return;
    
    try {
      final isLiked = await _firestoreService.isProductLiked(_product!.id, userId);
      if (mounted) {
        setState(() => _isWishlisted = isLiked);
      }
    } catch (e) {
      // 찜 상태 로드 실패 시 무시
    }
  }

  bool get _isOwner {
    final currentUserId = _firebaseService.currentUserId;
    return currentUserId != null && _product?.sellerId == currentUserId;
  }

  /// 찜하기 토글 (백엔드 연동)
  Future<void> _toggleWishlist() async {
    final userId = _firebaseService.currentUserId;
    if (userId == null) {
      MingrrSnackBar.warning(context, '로그인이 필요합니다');
      return;
    }
    if (_product == null || _isWishlistLoading) return;

    // 낙관적 업데이트
    final wasWishlisted = _isWishlisted;
    setState(() {
      _isWishlisted = !_isWishlisted;
      _isWishlistLoading = true;
    });

    try {
      final isNowLiked = await _firestoreService.toggleProductLike(_product!.id, userId);
      if (mounted) {
        setState(() {
          _isWishlisted = isNowLiked;
          _isWishlistLoading = false;
        });
        MingrrSnackBar.success(context, isNowLiked ? '찜 목록에 추가했어요' : '찜 목록에서 제거했어요');
      }
    } catch (e) {
      // 실패 시 롤백
      if (mounted) {
        setState(() {
          _isWishlisted = wasWishlisted;
          _isWishlistLoading = false;
        });
        MingrrSnackBar.error(context, '찜하기 실패: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const MingrrLoadingState(type: MingrrLoadingType.market, message: '상품 정보를 불러오고 있어요'),
      );
    }

    if (_product == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const MingrrEmptyState(
          icon: Icons.shopping_bag_outlined,
          title: '아직 데이터가 없어요',
          subtitle: '상품을 찾을 수 없습니다',
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.detailBackground,
      body: CustomScrollView(
        slivers: [
          // 이미지 헤더
          _buildImageHeader(context),
          
          // 본문 컨텐츠
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.paddingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 판매자 정보
                  _buildSellerInfo(context),
                  const Divider(height: 32),
                  
                  // 상품 정보
                  _buildProductInfo(),
                  const SizedBox(height: AppSizes.gapXL),
                  
                  // 상품 설명
                  _buildDescription(),
                  
                  // 거래 희망 지역
                  if (_product?.location != null) ...[
                    const SizedBox(height: AppSizes.gapXL),
                    _buildLocationSection(),
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
      bottomNavigationBar: _buildBottomButton(context),
    );
  }

  bool get _isShare => _product?.type == ProductType.share;

  /// 이미지 헤더
  Widget _buildImageHeader(BuildContext context) {
    return MingrrImageHeader(
      imageUrls: _product?.imageUrls ?? [],
      expandedHeight: 300,
      onShare: () {
        // TODO: 상품 공유 기능 구현 예정
      },
      onMore: () => _showMoreOptions(context),
      placeholder: Container(
        color: context.features.marketContainer,
        child: Center(
          child: Icon(Icons.image, size: 80, color: context.features.market),
        ),
      ),
    );
  }

  /// 판매자 정보
  Widget _buildSellerInfo(BuildContext context) {
    return GuardianProfileCard(
      name: _sellerNickname ?? '판매자',
      kkosunnaeScore: 50.0,
      accentColor: context.features.market,
      onTap: () => _showSellerProfile(context),
    );
  }

  /// 판매자 프로필 모달 표시
  void _showSellerProfile(BuildContext context) {
    showGuardianProfileModal(
      context,
      guardianId: _product?.sellerId ?? 'seller_1',
      guardianName: _sellerNickname ?? '판매자',
      kkosunnaeScore: 50.0,
      isIdentityVerified: true,
      isPetVerified: true,
      isLocationVerified: false,
      pets: [
        GuardianPetInfo(
          id: 'pet_1',
          name: '뽀삐',
          breed: '골든 리트리버',
          ageString: '3살',
          likeCount: 42,
        ),
      ],
      activityInfo: const GuardianActivityInfo(
        walkCount: 65,
        datingCount: 8,
        marketCount: 12,
        groupCount: 5,
      ),
    );
  }

  /// 상품 정보
  Widget _buildProductInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 카테고리
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: context.features.market.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_product?.category.icon ?? Icons.more_horiz, size: 12, color: context.features.market),
              const SizedBox(width: 4),
              Text(
                _product?.category.label ?? '기타',
                style: TextStyle(fontSize: 12, color: context.features.market),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // 제목
        Text(
          _product?.title ?? '',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        // 시간, 조회수
        Text(
          '${_product?.address ?? ''} · ${formatRelativeTime(_product?.createdAt ?? DateTime.now())} · 조회 ${_product?.viewCount ?? 0}',
          style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        // 가격
        Text(
          _isShare ? '무료나눔' : '${formatPrice(_product?.price ?? 0)}원',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: _isShare ? context.features.walk : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  /// 상품 설명
  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '상품 설명',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.sectionBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _product?.description ?? '',
            style: TextStyle(fontSize: 14, height: 1.6, color: Theme.of(context).colorScheme.onSurface),
          ),
        ),
      ],
    );
  }

  /// 거래 희망 지역 섹션
  Widget _buildLocationSection() {
    final location = _product?.location;
    if (location == null) return const SizedBox.shrink();
    
    // 주소가 없거나 GeoPoint 인스턴스 문자열인 경우 처리
    String? displayAddress = _product?.address;
    if (displayAddress == null || 
        displayAddress.isEmpty || 
        displayAddress.contains('Instance of') ||
        displayAddress.contains('GeoPoint')) {
      displayAddress = '위치 정보 없음';
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
        const Text(
          '거래 희망 지역',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
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
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // 헤더
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const SizedBox(width: 40),
                  const Expanded(
                    child: Text(
                      '거래 희망 지역',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
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
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.location_on, color: context.features.market),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        location.displayAddress,
                        style: const TextStyle(fontSize: 15),
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
  Widget _buildBottomButton(BuildContext context) {
    return MingrrBottomButtonBar(
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          // 찜하기 버튼
          GestureDetector(
            onTap: _toggleWishlist,
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isWishlisted ? Icons.bookmark : Icons.bookmark_border,
                    color: _isWishlisted ? context.features.market : Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_product?.likeCount ?? 0}',
                    style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 가격 표시
          Expanded(
            child: Text(
              _isShare ? '무료나눔' : '${formatPrice(_product?.price ?? 0)}원',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _isShare ? context.features.walk : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          // 채팅하기 버튼
          MingrrButton(
            text: '채팅하기',
            onPressed: _isOwner ? null : () => _startChat(),
            backgroundColor: context.features.market,
            textColor: Colors.white,
            width: 100,
            height: 48,
          ),
        ],
      ),
    );
  }

  /// 더보기 옵션 메뉴
  void _showMoreOptions(BuildContext context) {
    showDetailOptionsSheet(
      context: context,
      isOwner: _isOwner,
      onEdit: _editProduct,
      onDelete: _confirmDelete,
      onBlock: () => _blockSeller(context),
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
  Future<void> _blockSeller(BuildContext context) async {
    final currentUserId = _firebaseService.currentUserId;
    if (currentUserId == null) {
      MingrrSnackBar.warning(context, '로그인이 필요합니다');
      return;
    }

    final sellerId = _product?.sellerId;
    if (sellerId == null || sellerId == currentUserId) {
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
          if (mounted) {
            MingrrSnackBar.success(context, '판매자를 차단했습니다');
            Navigator.pop(context); // 상세 화면 닫기
          }
        } catch (e) {
          if (mounted) {
            MingrrSnackBar.error(context, '차단 실패: $e');
          }
        }
      },
    );
  }

  /// 상품 수정
  void _editProduct() async {
    if (_product == null) return;
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductWriteScreen(
          product: _product,
          initialType: _product!.type,
        ),
      ),
    );
    
    // 수정 성공 시 데이터 새로고침
    if (result == true) {
      _loadProduct();
    }
  }

  /// 삭제 확인 바텀시트
  void _confirmDelete() {
    if (_isDeleting) return; // 이미 삭제 중이면 무시
    
    showConfirmSheet(
      context,
      type: ConfirmSheetType.productDelete,
      onConfirm: _deleteProduct,
    );
  }

  /// 상품 삭제
  Future<void> _deleteProduct() async {
    if (_product == null) return;
    
    setState(() => _isDeleting = true);
    
    try {
      await _firestoreService.deleteProduct(_product!.id);
      
      if (mounted) {
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
  Future<void> _startChat() async {
    if (_product == null) return;
    
    final myUserId = _firebaseService.currentUserId;
    if (myUserId == null) {
      MingrrSnackBar.warning(context, '로그인이 필요합니다');
      return;
    }

    // 본인 상품이면 채팅 불가
    if (_product!.sellerId == myUserId) return;

    try {
      final chatService = ChatService();
      
      // 내 정보 가져오기
      final myUserDoc = await _firebaseService.usersCollection.doc(myUserId).get();
      final myUserData = myUserDoc.data();
      
      // 판매자 정보 가져오기
      final sellerDoc = await _firebaseService.usersCollection.doc(_product!.sellerId).get();
      final sellerData = sellerDoc.data();

      final myInfo = ChatParticipant(
        id: myUserId,
        nickname: myUserData?['nickname'] ?? '사용자',
        profileImageUrl: myUserData?['profileImageUrl'],
      );

      final sellerInfo = ChatParticipant(
        id: _product!.sellerId,
        nickname: sellerData?['nickname'] ?? '판매자',
        profileImageUrl: sellerData?['profileImageUrl'],
      );

      // 채팅방 생성 또는 기존 채팅방 찾기
      final chatRoom = await chatService.getOrCreateChatRoom(
        myUserId: myUserId,
        otherUserId: _product!.sellerId,
        type: 'market',
        myInfo: myInfo,
        otherInfo: sellerInfo,
        relatedId: _product!.id,
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatDetailScreen(
              chatRoomId: chatRoom.id,
              otherUserName: sellerInfo.nickname,
              otherUserImageUrl: sellerInfo.profileImageUrl,
              chatType: 'marketplace',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        MingrrSnackBar.error(context, '채팅 시작 실패: $e');
      }
    }
  }
}
