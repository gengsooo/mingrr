import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/chat_service.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../core/widgets/confirm_bottom_sheet.dart';
import '../../../../core/widgets/report_sheet.dart';
import '../../../../core/widgets/warmth_score.dart';
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
  String? _sellerNickname;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _product = widget.product;
      _isLoading = false;
      _loadSellerNickname();
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

  bool get _isOwner {
    final currentUserId = _firebaseService.currentUserId;
    return currentUserId != null && _product?.sellerId == currentUserId;
  }

  /// 찜하기 토글
  void _toggleWishlist() {
    setState(() => _isWishlisted = !_isWishlisted);
    
    // TODO: 백엔드 연동 - 찜 목록에 추가/제거
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isWishlisted ? '찜 목록에 추가했어요' : '찜 목록에서 제거했어요'),
        backgroundColor: AppColors.market,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(backgroundColor: Colors.white, elevation: 0),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_product == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(backgroundColor: Colors.white, elevation: 0),
        body: const Center(child: Text('상품을 찾을 수 없습니다')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
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
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.share, color: Colors.white, size: 20),
          ),
          onPressed: () {
            // TODO: 상품 공유 기능 구현 예정
          },
        ),
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.more_vert, color: Colors.white, size: 20),
          ),
          onPressed: () => _showMoreOptions(context),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: AppColors.marketLight,
          child: const Center(
            child: Icon(Icons.image, size: 80, color: AppColors.market),
          ),
        ),
      ),
    );
  }

  /// 판매자 정보
  Widget _buildSellerInfo(BuildContext context) {
    return GestureDetector(
      onTap: () => _showSellerProfile(context),
      child: Row(
        children: [
          // 아이콘 (강아지 앱이므로 사진 대신)
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.person, size: 24, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 12),
          // 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _sellerNickname ?? '판매자',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                const KkosunnaeScoreSmall(score: 50.0),
              ],
            ),
          ),
          // 화살표
          const Icon(Icons.chevron_right, color: AppColors.textHint),
        ],
      ),
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
        communityCount: 5,
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
            color: AppColors.market.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            _product?.categoryString ?? '기타',
            style: const TextStyle(fontSize: 12, color: AppColors.market),
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
          '${_product?.location ?? ''} · ${formatRelativeTime(_product?.createdAt ?? DateTime.now())} · 조회 ${_product?.viewCount ?? 0}',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        // 가격
        Text(
          _isShare ? '무료나눔' : '${formatPrice(_product?.price ?? 0)}원',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: _isShare ? AppColors.walk : AppColors.textPrimary,
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
        Text(
          _product?.description ?? '',
          style: const TextStyle(fontSize: 14, height: 1.6, color: AppColors.textPrimary),
        ),
      ],
    );
  }

  /// 거래 희망 지역 섹션
  Widget _buildLocationSection() {
    final location = _product?.location;
    if (location == null) return const SizedBox.shrink();
    
    final locationData = LocationData(
      latitude: location.latitude,
      longitude: location.longitude,
      fullAddress: _product?.address,
      shortAddress: _product?.address,
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
          accentColor: AppColors.market,
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
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                accentColor: AppColors.market,
                height: double.infinity,
              ),
            ),
            // 주소 정보
            SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: AppColors.market),
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
    return Container(
      padding: EdgeInsets.only(
        left: AppSizes.paddingL,
        right: AppSizes.paddingL,
        top: AppSizes.paddingM,
        bottom: MediaQuery.of(context).padding.bottom + AppSizes.paddingM,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
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
                    color: _isWishlisted ? AppColors.market : AppColors.textSecondary,
                    size: 24,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_product?.likeCount ?? 0}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
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
                color: _isShare ? AppColors.walk : AppColors.textPrimary,
              ),
            ),
          ),
          // 채팅하기 버튼
          SizedBox(
            width: 100,
            child: ElevatedButton(
              onPressed: _isOwner ? null : () => _startChat(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.market,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                '채팅하기',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 더보기 옵션 메뉴
  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 본인 글일 경우 수정/삭제 옵션 표시
            if (_isOwner) ...[
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: AppColors.market),
                title: const Text('수정하기'),
                onTap: () {
                  Navigator.pop(ctx);
                  _editProduct();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.error),
                title: const Text('삭제하기', style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDelete();
                },
              ),
              const Divider(),
            ],
            // 다른 사람 글일 경우 차단/신고 옵션
            if (!_isOwner) ...[
              ListTile(
                leading: const Icon(Icons.block_outlined),
                title: const Text('이 판매자 차단하기'),
                onTap: () => Navigator.pop(ctx),
              ),
              ListTile(
                leading: const Icon(Icons.report_outlined, color: AppColors.error),
                title: const Text('신고하기', style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(ctx);
                  showReportSheet(
                    context,
                    targetId: widget.productId,
                    targetName: '이 상품',
                    targetType: ReportTargetType.product,
                  );
                },
              ),
            ],
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
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
    
    showConfirmBottomSheet(
      context,
      type: ConfirmType.productDelete,
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('상품이 삭제되었습니다'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('삭제 실패: $e'),
            backgroundColor: AppColors.error,
          ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다')),
      );
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
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('채팅 시작 실패: $e')),
        );
      }
    }
  }
}
