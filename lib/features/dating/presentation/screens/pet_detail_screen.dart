import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/pet_constants.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/widgets/verification_badge.dart';
import '../../../../core/widgets/report_sheet.dart';
import '../../../../core/widgets/warmth_score.dart';
import '../../../../core/widgets/guardian_profile_modal.dart';
import '../../../../core/widgets/trait_badge.dart';
import '../../../../models/pet_model.dart';
import '../../../../models/user_model.dart';
import '../../../pet/presentation/providers/pet_provider.dart';

/// ============================================================
/// 반려동물 상세 화면
/// 
/// 데이팅(AI추천/근처검색) 및 교배찾기에서 사용
/// - 반려동물 정보 (성별, 나이, 특성 등)
/// - 보호자 정보
/// - 거리 정보
/// - 데이트 신청 / 교배 신청 버튼
/// ============================================================

class PetDetailScreen extends ConsumerStatefulWidget {
  final String petId;
  final bool isBreeding; // true: 교배찾기, false: 데이팅

  const PetDetailScreen({
    super.key,
    required this.petId,
    this.isBreeding = false,
  });

  @override
  ConsumerState<PetDetailScreen> createState() => _PetDetailScreenState();
}

class _PetDetailScreenState extends ConsumerState<PetDetailScreen> {
  bool isLiked = false;
  int likeCount = 42;
  final FirebaseService _firebase = FirebaseService();

  @override
  Widget build(BuildContext context) {
    // Firebase에서 실제 데이터 조회
    final petAsync = ref.watch(petByIdProvider(widget.petId));

    return petAsync.when(
      data: (pet) {
        if (pet == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('반려동물 정보')),
            body: const Center(child: Text('반려동물 정보를 찾을 수 없습니다')),
          );
        }
        return _buildContent(context, pet);
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Scaffold(
        appBar: AppBar(title: const Text('반려동물 정보')),
        body: const Center(child: Text('데이터를 불러올 수 없습니다')),
      ),
    );
  }

  Widget _buildContent(BuildContext context, PetModel pet) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // 이미지 헤더
          _buildImageHeader(context, pet),
          
          // 본문 컨텐츠
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.paddingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 기본 정보
                  _buildBasicInfo(pet),
                  const SizedBox(height: AppSizes.gapXL),
                  
                  // 특성 태그
                  _buildTraits(pet),
                  const SizedBox(height: AppSizes.gapXL),
                  
                  // 소개글
                  _buildIntroduction(pet),
                  const SizedBox(height: AppSizes.gapXL),
                  
                  // 보호자 정보 (인증 정보 포함)
                  _buildOwnerInfoWithVerification(context, pet),
                  
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

  /// 대표사진 URL 가져오기
  String? _getPrimaryPhotoUrl(PetModel pet) {
    if (pet.photoUrls.isNotEmpty && pet.primaryPhotoIndex < pet.photoUrls.length) {
      return pet.photoUrls[pet.primaryPhotoIndex];
    }
    return pet.profileImageUrl;
  }

  /// 나이 계산
  int _calculateAge(DateTime? birthDate) {
    if (birthDate == null) return 0;
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month || 
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age > 0 ? age : 0;
  }

  /// 크기 문자열
  String _getSizeString(PetSize? size) {
    switch (size) {
      case PetSize.small: return '소형';
      case PetSize.medium: return '중형';
      case PetSize.large: return '대형';
      default: return '미상';
    }
  }

  /// 이미지 헤더 (사진 슬라이더)
  Widget _buildImageHeader(BuildContext context, PetModel pet) {
    final isMale = pet.gender == PetGender.male;
    // photoUrls가 비어있으면 profileImageUrl을 사용
    List<String> photos = pet.photoUrls.isNotEmpty ? pet.photoUrls : <String>[];
    if (photos.isEmpty && pet.profileImageUrl != null && pet.profileImageUrl!.isNotEmpty) {
      photos = [pet.profileImageUrl!];
    }
    
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
        background: _PetPhotoSlider(
          photos: photos,
          isMale: isMale,
          distance: 1.2, // TODO: 실제 거리 계산
          matchScore: !widget.isBreeding ? 85 : null, // TODO: 실제 궁합 점수
          likeCount: likeCount,
          isBreeding: widget.isBreeding,
          profileImageUrl: _getPrimaryPhotoUrl(pet),
        ),
      ),
    );
  }

  /// 기본 정보
  Widget _buildBasicInfo(PetModel pet) {
    final age = _calculateAge(pet.birthDate);
    final sizeStr = _getSizeString(pet.size);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          pet.name,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          '${pet.breed ?? '품종 미상'} · ${age}살 · ${pet.weight ?? 0}kg ($sizeStr)',
          style: const TextStyle(fontSize: 15, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  /// 특성 태그 (분홍색 계통 통일 디자인)
  Widget _buildTraits(PetModel pet) {
    final traits = pet.traits.map((t) => t.label).toList();
    return TraitSection(traits: traits);
  }

  /// 소개글
  Widget _buildIntroduction(PetModel pet) {
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
            pet.bio ?? '소개글이 없습니다.',
            style: const TextStyle(fontSize: 14, height: 1.6, color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }

  /// Firebase에서 사용자 정보 조회
  Future<UserModel?> _getUserById(String userId) async {
    try {
      final doc = await _firebase.usersCollection.doc(userId).get();
      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromFirestore(doc.data()!, id: doc.id);
    } catch (e) {
      return null;
    }
  }

  /// 보호자 정보 (인증 정보 포함)
  Widget _buildOwnerInfoWithVerification(BuildContext context, PetModel pet) {
    return FutureBuilder<UserModel?>(
      future: _getUserById(pet.ownerId),
      builder: (context, snapshot) {
        final owner = snapshot.data;
        final nickname = owner?.nickname ?? '보호자';
        final genderEnum = owner?.gender;
        final gender = genderEnum == UserGender.male ? '남성' : '여성';
        final age = _calculateUserAge(owner?.birthDate);
        final kkosunnaeScore = owner?.kkosunnaeScore ?? 50.0;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '보호자 정보',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _showGuardianProfile(context, pet, owner),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // 아이콘
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: owner?.profileImageUrl != null
                              ? ClipOval(
                                  child: Image.network(
                                    owner!.profileImageUrl!,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.person, size: 24, color: AppColors.primary),
                                  ),
                                )
                              : const Icon(Icons.person, size: 24, color: AppColors.primary),
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
                                    nickname,
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
                    // 인증 배지 (소형)
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildSmallVerificationBadge(
                          icon: Icons.verified_user_outlined,
                          label: '본인인증',
                          isVerified: owner?.isIdentityVerified ?? false,
                        ),
                        _buildSmallVerificationBadge(
                          icon: Icons.pets_outlined,
                          label: '동물등록',
                          isVerified: owner?.isVerified ?? false,
                        ),
                        _buildSmallVerificationBadge(
                          icon: Icons.location_on_outlined,
                          label: '위치인증',
                          isVerified: owner?.isLocationVerified ?? false,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 소형 인증 배지
  Widget _buildSmallVerificationBadge({
    required IconData icon,
    required String label,
    required bool isVerified,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: isVerified ? AppColors.success : AppColors.textHint,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isVerified ? AppColors.textPrimary : AppColors.textHint,
          ),
        ),
        if (!isVerified)
          const Icon(Icons.close, size: 12, color: AppColors.textHint),
      ],
    );
  }

  /// 사용자 나이 계산
  int _calculateUserAge(DateTime? birthDate) {
    if (birthDate == null) return 30;
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month || 
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age > 0 ? age : 30;
  }

  /// 보호자 프로필 모달 표시
  void _showGuardianProfile(BuildContext context, PetModel pet, UserModel? owner) {
    final genderEnum = owner?.gender;
    final gender = genderEnum == UserGender.male ? GuardianGender.male : GuardianGender.female;
    final age = _calculateUserAge(owner?.birthDate);
    
    showGuardianProfileModal(
      context,
      guardianId: pet.ownerId,
      guardianName: owner?.nickname ?? '보호자',
      kkosunnaeScore: owner?.kkosunnaeScore ?? 50.0,
      profileImageUrl: owner?.profileImageUrl,
      gender: gender,
      age: age,
      isIdentityVerified: owner?.isIdentityVerified ?? false,
      isPetVerified: owner?.isVerified ?? false,
      isLocationVerified: owner?.isLocationVerified ?? false,
      dogs: [
        GuardianDogInfo(
          id: pet.id,
          name: pet.name,
          breed: pet.breed ?? '품종 미상',
          ageString: '${_calculateAge(pet.birthDate)}살',
          likeCount: likeCount,
          profileImageUrl: _getPrimaryPhotoUrl(pet),
          photoUrls: pet.photoUrls,
          traits: pet.traits.map((t) => t.label).toList(),
          introduction: pet.bio,
        ),
      ],
      activityInfo: const GuardianActivityInfo(
        walkCount: 0,
        datingCount: 0,
        marketCount: 0,
        communityCount: 0,
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
                  width: isLiked ? 0 : 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(isLiked ? Icons.favorite : Icons.favorite_border),
                const SizedBox(width: 4),
                Text('$likeCount'),
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
                  targetId: widget.petId,
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

/// 반려동물 사진 슬라이더 위젯
class _PetPhotoSlider extends StatefulWidget {
  final List<String> photos;
  final bool isMale;
  final double distance;
  final int? matchScore;
  final int likeCount;
  final bool isBreeding;
  final String? profileImageUrl;

  const _PetPhotoSlider({
    required this.photos,
    required this.isMale,
    required this.distance,
    this.matchScore,
    required this.likeCount,
    required this.isBreeding,
    this.profileImageUrl,
  });

  @override
  State<_PetPhotoSlider> createState() => _PetPhotoSliderState();
}

class _PetPhotoSliderState extends State<_PetPhotoSlider> {
  int _currentIndex = 0;
  bool _isLiked = false;

  @override
  Widget build(BuildContext context) {
    // 사진이 없으면 기본 이미지 표시
    if (widget.photos.isEmpty) {
      return _buildDefaultImage();
    }
    
    return Stack(
      fit: StackFit.expand,
      children: [
        // 사진 슬라이더
        PageView.builder(
          itemCount: widget.photos.length,
          onPageChanged: (index) => setState(() => _currentIndex = index),
          itemBuilder: (context, index) {
            return Image.network(
              widget.photos[index],
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildDefaultImage(),
            );
          },
        ),
        
        // 페이지 인디케이터
        if (widget.photos.length > 1)
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.photos.length,
                (index) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentIndex == index
                        ? Colors.white
                        : Colors.white.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          ),
        
        // 성별 배지
        Positioned(
          top: MediaQuery.of(context).padding.top + 60,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: widget.isMale ? Colors.blue : Colors.pink,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.isMale ? Icons.male : Icons.female,
                  size: 14,
                  color: Colors.white,
                ),
                const SizedBox(width: 2),
                Text(
                  widget.isMale ? '수컷' : '암컷',
                  style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
        
        // 거리 배지
        Positioned(
          top: MediaQuery.of(context).padding.top + 60,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_on, size: 14, color: Colors.white),
                const SizedBox(width: 2),
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

  Widget _buildDefaultImage() {
    return Container(
      color: AppColors.datingLight,
      child: Center(
        child: widget.profileImageUrl != null
            ? Image.network(
                widget.profileImageUrl!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.pets,
                  size: 100,
                  color: AppColors.dating,
                ),
              )
            : const Icon(
                Icons.pets,
                size: 100,
                color: AppColors.dating,
              ),
      ),
    );
  }
}
