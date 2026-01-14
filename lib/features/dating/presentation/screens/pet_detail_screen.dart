import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/feature_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/pet_constants.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/dating_service.dart';
import '../../../../core/widgets/report_sheet.dart';
import '../../../../core/widgets/request_sheet.dart';
import '../../../../core/widgets/warmth_score.dart';
import '../../../../core/widgets/guardian_profile_modal.dart';
import '../../../../core/widgets/trait_badge.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/mingrr_bottom_sheet.dart';
import '../../../../models/pet_model.dart';
import '../../../../models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../pet/presentation/providers/pet_provider.dart';
import '../providers/dating_provider.dart';

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
  bool _isLiked = false;
  int _likeCount = 0;
  bool _isSending = false;
  // ignore: unused_field - 향후 로딩 상태 표시용
  bool _likeLoaded = false;
  final FirebaseService _firebase = FirebaseService();
  final DatingService _datingService = DatingService();

  @override
  void initState() {
    super.initState();
    _loadLikeStatus();
  }

  /// Firebase에서 좋아요 상태 로드
  Future<void> _loadLikeStatus() async {
    try {
      final currentUser = _firebase.currentUser;
      if (currentUser == null) return;

      // 반려동물의 좋아요 수 조회
      final petDoc = await _firebase.petsCollection.doc(widget.petId).get();
      if (petDoc.exists) {
        final data = petDoc.data();
        setState(() {
          _likeCount = data?['likeCount'] ?? 0;
        });
      }

      // 내가 좋아요 했는지 확인
      final likeDoc = await _firebase.firestore
          .collection('likes')
          .doc('${currentUser.uid}_${widget.petId}')
          .get();
      
      setState(() {
        _isLiked = likeDoc.exists;
        _likeLoaded = true;
      });
    } catch (e) {
      debugPrint('좋아요 상태 로드 오류: $e');
      setState(() => _likeLoaded = true);
    }
  }

  /// 좋아요 토글
  Future<void> _toggleLike() async {
    final currentUser = _firebase.currentUser;
    if (currentUser == null) {
      MingrrSnackBar.warning(context, '로그인이 필요합니다');
      return;
    }

    final likeDocId = '${currentUser.uid}_${widget.petId}';
    final wasLiked = _isLiked;

    // 낙관적 업데이트
    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });

    try {
      if (wasLiked) {
        // 좋아요 취소
        await _firebase.firestore.collection('likes').doc(likeDocId).delete();
        await _firebase.petsCollection.doc(widget.petId).update({
          'likeCount': FieldValue.increment(-1),
        });
      } else {
        // 좋아요 추가
        await _firebase.firestore.collection('likes').doc(likeDocId).set({
          'userId': currentUser.uid,
          'petId': widget.petId,
          'createdAt': FieldValue.serverTimestamp(),
        });
        await _firebase.petsCollection.doc(widget.petId).update({
          'likeCount': FieldValue.increment(1),
        });
        
        if (mounted) {
          MingrrSnackBar.success(context, '좋아요를 보냈어요! 💕');
        }
      }
    } catch (e) {
      // 실패 시 롤백
      setState(() {
        _isLiked = wasLiked;
        _likeCount += wasLiked ? 1 : -1;
      });
      debugPrint('좋아요 토글 오류: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Firebase에서 실제 데이터 조회
    final petAsync = ref.watch(petByIdProvider(widget.petId));
    // 내 반려동물 목록 미리 로드 (신청 시 사용)
    ref.watch(userPetsProvider);

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
      loading: () => Scaffold(
        body: MingrrFullScreenLoading(
          message: '반려동물 정보 불러오는 중',
          type: MingrrLoadingType.dating,
        ),
      ),
      error: (_, __) => Scaffold(
        appBar: AppBar(title: const Text('반려동물 정보')),
        body: const Center(child: Text('데이터를 불러올 수 없습니다')),
      ),
    );
  }

  Widget _buildContent(BuildContext context, PetModel pet) {
    return Scaffold(
      backgroundColor: context.detailBackground,
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

  /// 대표사진 URL 가져오기 (추가사진 > null)
  String? _getPrimaryPhotoUrl(PetModel pet) {
    return pet.displayImageUrl;
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
    final photos = pet.photoUrls;
    
    // 실제 거리 및 궁합 점수 계산
    final petWithDistance = ref.watch(datingPetsProvider).valueOrNull
        ?.where((p) => p.pet.id == widget.petId).firstOrNull;
    
    final distance = petWithDistance?.distanceMeters ?? 0;
    final distanceKm = distance > 0 ? distance / 1000 : 0.0;
    final matchScore = petWithDistance?.matchScore;
    
    return SliverAppBar(
      expandedHeight: 350,
      pinned: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
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
            child: const Icon(Icons.more_vert, color: Colors.white, size: 20),
          ),
          onPressed: () => _showMoreOptions(context),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: _PetPhotoSlider(
          photos: photos,
          isMale: isMale,
          distance: distanceKm,
          matchScore: !widget.isBreeding ? matchScore : null,
          likeCount: _likeCount,
          isLiked: _isLiked,
          isBreeding: widget.isBreeding,
          profileImageUrl: _getPrimaryPhotoUrl(pet),
          onLikeTap: _toggleLike,
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
          style: TextStyle(fontSize: 15, color: Theme.of(context).colorScheme.onSurfaceVariant),
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
            color: context.sectionBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            pet.bio ?? '소개글이 없습니다.',
            style: TextStyle(fontSize: 14, height: 1.6, color: Theme.of(context).colorScheme.onSurface),
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
                  color: context.sectionBackground,
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
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: owner?.profileImageUrl != null
                              ? ClipOval(
                                  child: Image.network(
                                    owner!.profileImageUrl!,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Icon(
                                      Icons.person, size: 24, color: Theme.of(context).colorScheme.primary),
                                  ),
                                )
                              : Icon(Icons.person, size: 24, color: Theme.of(context).colorScheme.primary),
                        ),
                        const SizedBox(width: 12),
                        // 닉네임 + 꼬순내지수 (성별/나이 제거 - 개인정보 보호)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nickname,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              KkosunnaeScoreSmall(score: kkosunnaeScore),
                            ],
                          ),
                        ),
                        // 화살표
                        Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.outlineVariant),
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
          color: isVerified ? context.features.success : Theme.of(context).colorScheme.outlineVariant,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isVerified ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        if (!isVerified)
          Icon(Icons.close, size: 12, color: Theme.of(context).colorScheme.outlineVariant),
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
      pets: [
        GuardianPetInfo(
          id: pet.id,
          name: pet.name,
          breed: pet.breed ?? '품종 미상',
          ageString: '${_calculateAge(pet.birthDate)}살',
          likeCount: _likeCount,
          profileImageUrl: pet.profileImageUrl, // 프로필 이미지만 사용
          photoUrls: pet.photoUrls,
          traits: pet.traits.map((t) => t.label).toList(),
          introduction: pet.bio,
        ),
      ],
      activityInfo: const GuardianActivityInfo(
        walkCount: 0,
        datingCount: 0,
        marketCount: 0,
        groupCount: 0,
      ),
    );
  }

  /// 하단 고정 버튼
  Widget _buildBottomButton(BuildContext context) {
    return MingrrBottomButtonBar(
      child: Row(
        children: [
          // 좋아요 버튼 (아이콘 + 숫자만)
          GestureDetector(
            onTap: _toggleLike,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              child: Row(
                children: [
                  Icon(
                    _isLiked ? Icons.favorite : Icons.favorite_border,
                    size: 28,
                    color: _isLiked ? Colors.red : context.features.dating,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$_likeCount',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _isLiked ? Colors.red : context.features.dating,
                    ),
                  ),
                ],
              ),
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
                  backgroundColor: context.features.dating,
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

  /// 신청 확인 바텀시트 (공통 디자인)
  void _showRequestConfirmation(BuildContext context) {
    // 내 반려동물 목록 가져오기
    final myPets = ref.read(userPetsProvider).valueOrNull ?? [];
    
    if (myPets.isEmpty) {
      MingrrSnackBar.warning(context, '먼저 반려동물을 등록해주세요');
      return;
    }
    
    if (widget.isBreeding) {
      showBreedingRequestSheet(
        context,
        myPets: myPets,
        onConfirm: (message, {selectedPet}) async {
          await _sendBreedingRequest(context, message, selectedPet);
        },
      );
    } else {
      showDateRequestSheet(
        context,
        myPets: myPets,
        onConfirm: (message, {selectedPet}) async {
          await _sendDatingRequest(context, message, selectedPet);
        },
      );
    }
  }
  
  /// 데이팅 신청 보내기
  Future<void> _sendDatingRequest(BuildContext context, String? message, PetModel? selectedPet) async {
    if (_isSending) return;
    
    final currentUser = ref.read(authStateProvider).valueOrNull;
    if (currentUser == null) return;
    
    // 내 반려동물 선택 (선택된 것 또는 첫번째)
    final myPets = ref.read(userPetsProvider).valueOrNull ?? [];
    final myPet = selectedPet ?? myPets.firstOrNull;
    if (myPet == null) return;
    
    // 상대 반려동물 정보
    final targetPet = ref.read(petByIdProvider(widget.petId)).valueOrNull;
    if (targetPet == null) return;
    
    setState(() => _isSending = true);
    Navigator.pop(context); // 바텀시트 닫기
    
    try {
      await _datingService.sendLike(
        fromUserId: currentUser.uid,
        fromPetId: myPet.id,
        toUserId: targetPet.ownerId,
        toPetId: targetPet.id,
        message: message,
      );
      
      // 좋아요 수 증가 (이미 좋아요 안 했으면)
      if (!_isLiked) {
        await _toggleLike();
      }
      
      if (mounted) {
        MingrrSnackBar.success(context, '${myPet.name}(으)로 데이트 신청을 보냈어요! 💕');
      }
    } catch (e) {
      if (mounted) {
        MingrrSnackBar.error(context, '신청 실패: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }
  
  /// 교배 신청 보내기
  Future<void> _sendBreedingRequest(BuildContext context, String? message, PetModel? selectedPet) async {
    if (_isSending) return;
    
    final currentUser = ref.read(authStateProvider).valueOrNull;
    if (currentUser == null) return;
    
    final myPets = ref.read(userPetsProvider).valueOrNull ?? [];
    final myPet = selectedPet ?? myPets.firstOrNull;
    if (myPet == null) return;
    
    final targetPet = ref.read(petByIdProvider(widget.petId)).valueOrNull;
    if (targetPet == null) return;
    
    setState(() => _isSending = true);
    Navigator.pop(context);
    
    try {
      await _datingService.sendBreedingRequest(
        fromUserId: currentUser.uid,
        fromPetId: myPet.id,
        toUserId: targetPet.ownerId,
        toPetId: targetPet.id,
        message: message,
      );
      
      if (mounted) {
        MingrrSnackBar.success(context, '${myPet.name}(으)로 교배 신청을 보냈어요! 🐶');
      }
    } catch (e) {
      if (mounted) {
        MingrrSnackBar.error(context, '신청 실패: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  /// 더보기 옵션 메뉴
  void _showMoreOptions(BuildContext context) {
    showMingrrOptionsSheet(
      context: context,
      options: [
        MingrrOptionItem(
          icon: Icons.block_outlined,
          label: '차단하기',
          onTap: () {},
        ),
        MingrrOptionItem(
          icon: Icons.report_outlined,
          label: '신고하기',
          isDestructive: true,
          onTap: () {
            showReportSheet(
              context,
              targetId: widget.petId,
              targetName: '이 사용자',
              targetType: ReportTargetType.user,
            );
          },
        ),
      ],
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
  final bool isLiked;
  final bool isBreeding;
  final String? profileImageUrl;
  final VoidCallback? onLikeTap;

  const _PetPhotoSlider({
    required this.photos,
    required this.isMale,
    required this.distance,
    this.matchScore,
    required this.likeCount,
    required this.isLiked,
    required this.isBreeding,
    this.profileImageUrl,
    this.onLikeTap,
  });

  @override
  State<_PetPhotoSlider> createState() => _PetPhotoSliderState();
}

class _PetPhotoSliderState extends State<_PetPhotoSlider> {
  int _currentIndex = 0;

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
        
        // 성별 배지 (투명도 없는 배경색, 흰색 텍스트)
        Positioned(
          top: MediaQuery.of(context).padding.top + 60,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: widget.isMale 
                  ? const Color(0xFF2196F3)  // 파란색 (투명도 없음)
                  : const Color(0xFFE91E63), // 핑크색 (투명도 없음)
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
                  widget.isMale ? '남아' : '여아',
                  style: const TextStyle(
                    fontSize: 12, 
                    color: Colors.white, 
                    fontWeight: FontWeight.w500,
                  ),
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
                  widget.distance > 0 && widget.distance.isFinite 
                    ? '${widget.distance.toStringAsFixed(1)}km'
                    : '위치정보 없음',
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
            onTap: widget.onLikeTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: widget.isLiked ? Colors.red : Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.isLiked ? Icons.favorite : Icons.favorite_border,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.likeCount}',
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
                    ? context.features.success 
                    : context.features.dating,
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
    return const DefaultPetImage(height: 350);
  }
}
