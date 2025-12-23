import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/report_sheet.dart';
import '../../../../core/widgets/warmth_score.dart';
import '../../../../core/widgets/guardian_profile_modal.dart';

/// ============================================================
/// 상품 상세 화면
/// 
/// 마켓플레이스에서 상품 클릭 시 표시
/// - 상품 이미지
/// - 상품 정보 (제목, 가격, 설명)
/// - 판매자 정보
/// - 채팅하기 버튼
/// - 신고 기능
/// ============================================================

class ProductDetailScreen extends StatelessWidget {
  final String productId;
  final bool isShare; // true: 나눔, false: 판매

  const ProductDetailScreen({
    super.key,
    required this.productId,
    this.isShare = false,
  });

  @override
  Widget build(BuildContext context) {
    final productData = _getDemoData();

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // 이미지 헤더
          _buildImageHeader(context, productData),
          
          // 본문 컨텐츠
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.paddingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 판매자 정보
                  _buildSellerInfo(context, productData),
                  const Divider(height: 32),
                  
                  // 상품 정보
                  _buildProductInfo(productData),
                  const SizedBox(height: AppSizes.gapXL),
                  
                  // 상품 설명
                  _buildDescription(productData),
                  
                  // 하단 여백 (버튼 공간)
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      // 하단 고정 버튼
      bottomNavigationBar: _buildBottomButton(context, productData),
    );
  }

  /// 데모 데이터
  Map<String, dynamic> _getDemoData() {
    return {
      'title': isShare ? '안 먹는 간식 나눔해요' : '강아지 옷 팔아요',
      'price': isShare ? 0 : 15000,
      'description': '우리 아이가 안 먹어서 나눔합니다.\n유통기한 넉넉하고 개봉만 했어요.\n직거래 원해요!',
      'category': isShare ? '사료/간식' : '의류',
      'location': '서울 강남구',
      'createdAt': '3시간 전',
      'viewCount': 42,
      'likeCount': 5,
      'chatCount': 3,
      'seller': {
        'nickname': '뽀삐맘',
        'warmthScore': 38.5,
        'location': '서울 강남구',
      },
      'status': 'available', // available, reserved, sold
    };
  }

  /// 이미지 헤더
  Widget _buildImageHeader(BuildContext context, Map<String, dynamic> data) {
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
          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
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
            // TODO: 공유 기능
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
  Widget _buildSellerInfo(BuildContext context, Map<String, dynamic> data) {
    final seller = data['seller'] as Map<String, dynamic>;
    final kkosunnaeScore = (seller['kkosunnaeScore'] as num?)?.toDouble() ?? 50.0;
    
    return GestureDetector(
      onTap: () => _showSellerProfile(context, seller),
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
                  seller['nickname'],
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                KkosunnaeScoreSmall(score: kkosunnaeScore),
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
  void _showSellerProfile(BuildContext context, Map<String, dynamic> seller) {
    showGuardianProfileModal(
      context,
      guardianId: seller['id'] ?? 'seller_1',
      guardianName: seller['nickname'] ?? '판매자',
      kkosunnaeScore: (seller['kkosunnaeScore'] as num?)?.toDouble() ?? 50.0,
      isIdentityVerified: true,
      isPetVerified: true,
      isLocationVerified: false,
      dogs: [
        GuardianDogInfo(
          id: 'dog_1',
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
  Widget _buildProductInfo(Map<String, dynamic> data) {
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
            data['category'],
            style: const TextStyle(fontSize: 12, color: AppColors.market),
          ),
        ),
        const SizedBox(height: 12),
        // 제목
        Text(
          data['title'],
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        // 시간, 조회수
        Text(
          '${data['location']} · ${data['createdAt']} · 조회 ${data['viewCount']}',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        // 가격
        Text(
          isShare ? '무료나눔' : '${_formatPrice(data['price'])}원',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: isShare ? AppColors.walk : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  /// 상품 설명
  Widget _buildDescription(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '상품 설명',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Text(
          data['description'],
          style: const TextStyle(fontSize: 14, height: 1.6, color: AppColors.textPrimary),
        ),
      ],
    );
  }

  /// 하단 고정 버튼
  Widget _buildBottomButton(BuildContext context, Map<String, dynamic> data) {
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
          // 좋아요 버튼
          GestureDetector(
            onTap: () {
              // TODO: 좋아요 토글
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.favorite_border, color: AppColors.textSecondary, size: 24),
                  const SizedBox(height: 2),
                  Text(
                    '${data['likeCount']}',
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
              isShare ? '무료나눔' : '${_formatPrice(data['price'])}원',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isShare ? AppColors.walk : AppColors.textPrimary,
              ),
            ),
          ),
          // 채팅하기 버튼
          SizedBox(
            width: 100,
            child: ElevatedButton(
              onPressed: () {
                // TODO: 채팅 화면으로 이동
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('채팅이 시작되었습니다!'),
                    backgroundColor: AppColors.market,
                  ),
                );
              },
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
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.block_outlined),
              title: const Text('이 판매자 차단하기'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.report_outlined, color: AppColors.error),
              title: const Text('신고하기', style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.pop(context);
                showReportSheet(
                  context,
                  targetId: productId,
                  targetName: '이 상품',
                  targetType: ReportTargetType.product,
                );
              },
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  /// 가격 포맷팅
  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}
