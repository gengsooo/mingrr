import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/verification_badge.dart';
import '../../../../core/widgets/report_sheet.dart';
import '../../../../core/widgets/warmth_score.dart';
import '../../../../core/widgets/guardian_profile_modal.dart';

/// ============================================================
/// 강아지 상세 화면
/// 
/// 데이팅(AI추천/근처검색) 및 교배찾기에서 사용
/// - 강아지 정보 (성별, 나이, 특성 등)
/// - 보호자 정보
/// - 거리 정보
/// - 데이트 신청 / 교배 신청 버튼
/// ============================================================

class DogDetailScreen extends ConsumerStatefulWidget {
  final String dogId;
  final bool isBreeding; // true: 교배찾기, false: 데이팅

  const DogDetailScreen({
    super.key,
    required this.dogId,
    this.isBreeding = false,
  });

  @override
  ConsumerState<DogDetailScreen> createState() => _DogDetailScreenState();
}

class _DogDetailScreenState extends ConsumerState<DogDetailScreen> {
  bool isLiked = false;
  int likeCount = 42;

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    // TODO: 실제 데이터 연동 시 dogId로 데이터 조회
    final dogData = _getDemoData();

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // 이미지 헤더
          _buildImageHeader(context, dogData),
          
          // 본문 컨텐츠
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.paddingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 기본 정보
                  _buildBasicInfo(dogData),
                  const SizedBox(height: AppSizes.gapXL),
                  
                  // 특성 태그
                  _buildTraits(dogData),
                  const SizedBox(height: AppSizes.gapXL),
                  
                  // 소개글
                  _buildIntroduction(dogData),
                  const SizedBox(height: AppSizes.gapXL),
                  
                  // 보호자 정보
                  _buildOwnerInfo(context, dogData),
                  const SizedBox(height: AppSizes.gapXL),
                  
                  // 인증 배지
                  _buildVerificationBadges(dogData),
                  
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

  /// 데모 데이터
  Map<String, dynamic> _getDemoData() {
    return {
      'name': '뽀삐',
      'breed': '골든 리트리버',
      'age': 3,
      'gender': 'male',
      'weight': 28.5,
      'size': '대형',
      'distance': 1.2,
      'traits': ['활발함', '친화적', '사람 좋아함', '강아지 좋아함', '산책 좋아함'],
      'introduction': '안녕하세요! 저희 뽀삐는 3살 골든 리트리버 남아예요. 사람을 정말 좋아하고 다른 강아지들과도 잘 어울려요. 산책을 좋아해서 매일 2번씩 나가고 있어요. 좋은 친구 만나고 싶어요! 🐶',
      'owner': {
        'nickname': '뽀삐맘',
        'gender': '여성',
        'age': 28,
        'location': '서울 강남구',
        'bio': '반려동물과 함께하는 행복한 일상을 보내고 있습니다. 산책 친구를 찾고 있어요! 🐾',
      },
      'isIdentityVerified': true,
      'isPetVerified': true,
      'isLocationVerified': true,
      'hasPedigree': true,
      'matchScore': 95,
    };
  }

  /// 이미지 헤더 (사진 슬라이더)
  Widget _buildImageHeader(BuildContext context, Map<String, dynamic> data) {
    final isMale = data['gender'] == 'male';
    final photos = data['photos'] as List<String>? ?? ['🐶', '🐕', '🦮'];
    final likeCount = data['likeCount'] as int? ?? 42;
    
    return SliverAppBar(
      expandedHeight: 350,
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
            child: const Icon(Icons.more_vert, color: Colors.white, size: 20),
          ),
          onPressed: () => _showMoreOptions(context),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: _DogPhotoSlider(
          photos: photos,
          isMale: isMale,
          distance: data['distance'] as double,
          matchScore: !widget.isBreeding ? data['matchScore'] as int? : null,
          likeCount: likeCount,
          isBreeding: widget.isBreeding,
        ),
      ),
    );
  }

  /// 기본 정보
  Widget _buildBasicInfo(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          data['name'],
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          '${data['breed']} · ${data['age']}살 · ${data['weight']}kg (${data['size']})',
          style: const TextStyle(fontSize: 15, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  /// 특성 태그
  Widget _buildTraits(Map<String, dynamic> data) {
    final traits = data['traits'] as List<String>;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '성격 & 특성',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: traits.map((trait) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                trait,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// 소개글
  Widget _buildIntroduction(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '소개',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            data['introduction'],
            style: const TextStyle(fontSize: 14, height: 1.6, color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }

  /// 보호자 정보
  Widget _buildOwnerInfo(BuildContext context, Map<String, dynamic> data) {
    final owner = data['owner'] as Map<String, dynamic>;
    final kkosunnaeScore = (owner['kkosunnaeScore'] as num?)?.toDouble() ?? 50.0;
    final gender = owner['gender'] as String? ?? '여성';
    final age = owner['age'] as int? ?? 30;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '보호자 정보',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => _showGuardianProfile(context, owner),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // 아이콘 (강아지 앱이므로 사진 대신 아이콘)
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, size: 24, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                // 닉네임 + 성별/나이 + 꼬순내지수
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            owner['nickname'],
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: gender == '남성' 
                                  ? Colors.blue.withOpacity(0.1) 
                                  : Colors.pink.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$gender · ${age}세',
                              style: TextStyle(
                                fontSize: 11,
                                color: gender == '남성' ? Colors.blue : Colors.pink,
                              ),
                            ),
                          ),
                        ],
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
          ),
        ),
      ],
    );
  }

  /// 보호자 프로필 모달 표시
  void _showGuardianProfile(BuildContext context, Map<String, dynamic> owner) {
    final genderStr = owner['gender'] as String? ?? '여성';
    final gender = genderStr == '남성' ? GuardianGender.male : GuardianGender.female;
    final age = owner['age'] as int? ?? 30;
    
    showGuardianProfileModal(
      context,
      guardianId: owner['id'] ?? 'demo_user',
      guardianName: owner['nickname'] ?? '보호자',
      kkosunnaeScore: (owner['kkosunnaeScore'] as num?)?.toDouble() ?? 50.0,
      gender: gender,
      age: age,
      isIdentityVerified: owner['isIdentityVerified'] ?? false,
      isPetVerified: owner['isPetVerified'] ?? false,
      isLocationVerified: owner['isLocationVerified'] ?? false,
      dogs: [
        GuardianDogInfo(
          id: 'dog_1',
          name: '멍멍이',
          breed: '골든 리트리버',
          ageString: '3살',
          likeCount: 42,
        ),
      ],
      activityInfo: const GuardianActivityInfo(
        walkCount: 128,
        datingCount: 15,
        marketCount: 8,
        communityCount: 23,
      ),
    );
  }

  /// 인증 배지
  Widget _buildVerificationBadges(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '인증 현황',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        VerificationBadgeRow(
          isIdentityVerified: data['isIdentityVerified'] == true,
          isPetVerified: data['isPetVerified'] == true,
          isLocationVerified: data['isLocationVerified'] == true,
          useMediumSize: true,
        ),
      ],
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
        children: [
          // 좋아요 버튼
          ElevatedButton(
            onPressed: () {
              setState(() {
                isLiked = !isLiked;
                likeCount = isLiked ? likeCount + 1 : likeCount - 1;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isLiked ? '좋아요를 보냈어요! ❤️' : '좋아요를 취소했어요'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isLiked ? AppColors.dating : Colors.white,
              foregroundColor: isLiked ? Colors.white : AppColors.dating,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              minimumSize: const Size(0, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: AppColors.dating,
                  width: 2,
                ),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  size: 24,
                ),
                const SizedBox(width: 6),
                Text(
                  '$likeCount',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // 신청 버튼
          Expanded(
            child: SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: () => _showRequestConfirmation(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.dating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  widget.isBreeding ? '교배 신청하기' : '데이트 신청하기',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 신청 확인 다이얼로그
  void _showRequestConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              widget.isBreeding ? Icons.pets : Icons.favorite,
              color: AppColors.dating,
            ),
            const SizedBox(width: 8),
            Text(
              widget.isBreeding ? '교배 신청' : '데이트 신청',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: Text(
          widget.isBreeding
              ? '상대방에게 교배 신청을 보낼까요?\n수락되면 채팅이 시작됩니다.'
              : '상대방에게 데이트 신청을 보낼까요?\n수락되면 채팅이 시작됩니다.',
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(widget.isBreeding ? '교배 신청을 보냈어요! 🐶' : '데이트 신청을 보냈어요! 💕'),
                  backgroundColor: AppColors.dating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dating,
            ),
            child: const Text('신청하기', style: TextStyle(color: Colors.white)),
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
              title: const Text('차단하기'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.report_outlined, color: AppColors.error),
              title: const Text('신고하기', style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.pop(context);
                showReportSheet(
                  context,
                  targetId: widget.dogId,
                  targetName: '이 사용자',
                  targetType: ReportTargetType.user,
                );
              },
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}

/// 강아지 사진 슬라이더 위젯
class _DogPhotoSlider extends StatefulWidget {
  final List<String> photos;
  final bool isMale;
  final double distance;
  final int? matchScore;
  final int likeCount;
  final bool isBreeding;

  const _DogPhotoSlider({
    required this.photos,
    required this.isMale,
    required this.distance,
    this.matchScore,
    required this.likeCount,
    required this.isBreeding,
  });

  @override
  State<_DogPhotoSlider> createState() => _DogPhotoSliderState();
}

class _DogPhotoSliderState extends State<_DogPhotoSlider> {
  int _currentIndex = 0;
  bool _isLiked = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 사진 슬라이더
        PageView.builder(
          itemCount: widget.photos.length,
          onPageChanged: (index) => setState(() => _currentIndex = index),
          itemBuilder: (context, index) {
            final photo = widget.photos[index];
            // 데모용: 이모지면 그라데이션 배경, 아니면 이미지
            if (photo.length <= 2) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.dating.withOpacity(0.3),
                      AppColors.dating.withOpacity(0.1),
                    ],
                  ),
                ),
                child: Center(
                  child: Text(photo, style: const TextStyle(fontSize: 120)),
                ),
              );
            }
            return Image.network(photo, fit: BoxFit.cover);
          },
        ),
        
        // 하단 그라데이션
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 100,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.5),
                ],
              ),
            ),
          ),
        ),
        
        // 사진 인디케이터
        if (widget.photos.length > 1)
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.photos.length, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _currentIndex == index ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentIndex == index 
                        ? Colors.white 
                        : Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
        
        // 성별 배지
        Positioned(
          top: 100,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: widget.isMale ? Colors.blue : Colors.pink,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.isMale ? '♂' : '♀',
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
                const SizedBox(width: 4),
                Text(
                  widget.isMale ? '수컷' : '암컷',
                  style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
        
        // 거리 배지
        Positioned(
          top: 100,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_on, size: 14, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  '${widget.distance}km',
                  style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
        
        // 좋아요 버튼 + 카운트
        Positioned(
          bottom: 16,
          left: 16,
          child: GestureDetector(
            onTap: () => setState(() => _isLiked = !_isLiked),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _isLiked ? AppColors.error : Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isLiked ? Icons.favorite : Icons.favorite_border,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.likeCount + (_isLiked ? 1 : 0)}',
                    style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // AI 매칭 점수 (데이팅일 때만)
        if (widget.matchScore != null)
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: widget.matchScore! >= 90 
                    ? AppColors.success 
                    : AppColors.dating,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_awesome, size: 14, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    '궁합 ${widget.matchScore}%',
                    style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
