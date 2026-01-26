import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/theme/feature_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/pet_constants.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/dating_service.dart';
import '../../../../core/services/share_service.dart';
import '../../../../core/services/transaction_service.dart';
import '../../../../core/widgets/sheets/report_sheet.dart';
import '../../../../core/widgets/sheets/request_sheet.dart';
import '../../../../core/widgets/kkosunnae_widgets.dart';
import '../../../../core/widgets/modals/guardian_profile_modal.dart';
import '../../../../core/widgets/modals/pet_profile_modal.dart';
import '../../../../core/widgets/badges/trait_badge.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/mingrr_image.dart';
import '../../../../core/widgets/sheets/mingrr_bottom_sheet.dart';
import '../../../../core/widgets/sheets/confirm_sheet.dart';
import '../../../../core/widgets/compatibility_widgets.dart';
import '../../../../core/widgets/badges/info_badge.dart' show LikeButton, InfoBadgeSize, EmptyInfoBadge, PedigreeBadge, MatchScoreBadge, MatchBadgeStyle;
import '../../../../core/widgets/mingrr_image_header.dart' show ImageHeaderDistanceBadge, LikeBadge;
import '../../../../core/widgets/badges/svg_icons.dart';
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
  final double? cachedDistanceMeters; // 리스트에서 전달받은 거리 (캐시)
  final int? cachedMatchScore; // 리스트에서 전달받은 궁합 점수 (캐시)

  const PetDetailScreen({
    super.key,
    required this.petId,
    this.isBreeding = false,
    this.cachedDistanceMeters,
    this.cachedMatchScore,
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
  final FirestoreService _firestoreService = FirestoreService();
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
      AppLogger.error('PetDetail', '좋아요 상태 로드 오류', e);
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

    final wasLiked = _isLiked;

    // 낙관적 업데이트
    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });

    try {
      // 트랜잭션으로 Race Condition 방지
      final isNowLiked = await TransactionService.togglePetLike(
        petId: widget.petId,
        userId: currentUser.uid,
      );
      
      // 실제 결과와 UI 동기화
      if (mounted && isNowLiked != _isLiked) {
        setState(() {
          _isLiked = isNowLiked;
          _likeCount += isNowLiked ? 1 : -1;
        });
      }
      
      if (mounted && isNowLiked && !wasLiked) {
        MingrrSnackBar.success(context, '좋아요를 보냈어요! 💕');
      }
    } catch (e) {
      // 실패 시 롤백
      setState(() {
        _isLiked = wasLiked;
        _likeCount += wasLiked ? 1 : -1;
      });
      AppLogger.error('PetDetail', '좋아요 토글 오류', e);
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
            body: const MingrrEmptyState(
              icon: Icons.pets,
              title: '아직 데이터가 없어요',
              subtitle: '반려동물 정보를 찾을 수 없습니다',
            ),
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
        body: MingrrErrorState(
          onRetry: () => ref.invalidate(petByIdProvider(widget.petId)),
        ),
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
                  
                  // 교배찾기 상세 내용 (교배찾기에서만 표시)
                  if (widget.isBreeding) ...[
                    _buildBreedingDescription(pet),
                    const SizedBox(height: AppSizes.gapXL),
                  ],
                  
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
    
    // 캐시된 값 우선 사용, 없으면 provider에서 조회
    final petWithDistance = ref.watch(datingPetsProvider).valueOrNull
        ?.where((p) => p.pet.id == widget.petId).firstOrNull;
    
    // 거리: 캐시 → provider → 0
    final distance = widget.cachedDistanceMeters ?? petWithDistance?.distanceMeters ?? 0;
    final distanceKm = distance > 0 ? distance / 1000 : 0.0;
    
    // 궁합: 캐시 → provider → null
    final matchScore = widget.cachedMatchScore ?? petWithDistance?.matchScore;
    final hasMatchScore = matchScore != null && !widget.isBreeding;
    
    return MingrrImageHeader(
      imageUrls: photos,
      expandedHeight: 350,
      onShare: () => ShareService.sharePet(context, pet),
      onMore: () => _showMoreOptions(context),
      // 이미지 없을 때 빈 상태 UI
      emptyStateWidget: _buildEmptyImageState(context),
      topLeftOverlay: GenderBadge(isMale: isMale),
      // 궁합 정보: 있으면 점수 표시, 없으면 안내 배지
      topRightOverlay: hasMatchScore
          ? MatchScoreBadge(
              score: matchScore,
              style: MatchBadgeStyle.filled,
              size: InfoBadgeSize.large,
              showInfoIcon: true,
              onTap: () => showCompatibilityGuideModal(context),
            )
          : !widget.isBreeding
              ? const EmptyInfoBadge(
                  icon: Icons.auto_awesome_outlined,
                  text: '궁합 정보 없음',
                )
              : null,
      // 거리 정보 (ImageHeaderDistanceBadge가 0일 때 자동으로 "위치정보 없음" 표시)
      bottomLeftOverlay: ImageHeaderDistanceBadge(distanceKm: distanceKm),
      bottomRightOverlay: LikeBadge(
        count: _likeCount,
        isLiked: _isLiked,
        onTap: _toggleLike,
      ),
    );
  }

  /// 이미지 없을 때 빈 상태 UI
  Widget _buildEmptyImageState(BuildContext context) {
    return Container(
      color: context.features.datingContainer,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          DefaultPetIcon(size: 80),
          const SizedBox(height: AppSizes.gapM),
          Text(
            '사진이 없어요',
            style: AppTextStyles.bodyLarge(context).withColor(Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  /// 기본 정보
  Widget _buildBasicInfo(PetModel pet) {
    final age = _calculateAge(pet.birthDate);
    final sizeStr = _getSizeString(pet.size);
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 반려동물 프로필 이미지 (클릭 시 모달 열기)
        GestureDetector(
          onTap: () => _openPetProfileModal(pet),
          child: MingrrPetAvatar(
            imageUrl: pet.displayImageUrl,
            size: 56,
            borderColor: context.features.dating.withValues(alpha: AppOpacity.o30),
            borderWidth: 2,
          ),
        ),
        const SizedBox(width: 16),
        // 이름 및 정보
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    pet.name,
                    style: AppTextStyles.headlineLarge(context),
                  ),
                  // 교배찾기에서 혈통서 유무 배지 표시
                  if (widget.isBreeding) ...[
                    const SizedBox(width: AppSizes.gapS),
                    PedigreeBadge(hasPedigree: pet.hasPedigree),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${pet.breed ?? '품종 미상'} · ${age}살 · ${pet.weight ?? 0}kg ($sizeStr)',
                style: AppTextStyles.bodyLarge(context).copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 반려동물 프로필 모달 열기
  Future<void> _openPetProfileModal(PetModel pet) async {
    final age = _calculateAge(pet.birthDate);
    final traits = pet.traits.map((t) => t.label).toList();
    
    // 보호자 정보 조회
    final owner = await _getUserById(pet.ownerId);
    final genderEnum = owner?.gender;
    final guardianGender = genderEnum == UserGender.male ? GuardianGender.male : GuardianGender.female;
    final guardianAge = _calculateUserAge(owner?.birthDate);
    
    if (!mounted) return;
    
    showPetProfileModal(
      context,
      petId: pet.id,
      petName: pet.name,
      breed: pet.breed,
      age: age,
      gender: pet.gender == PetGender.male ? 'male' : 'female',
      weight: pet.weight,
      introduction: pet.bio,
      traits: traits,
      photoUrls: pet.photoUrls,
      profileImageUrl: pet.displayImageUrl,
      likeCount: _likeCount,
      guardianInfo: GuardianInfo(
        id: pet.ownerId,
        nickname: owner?.nickname ?? '보호자',
        kkosunnaeScore: owner?.kkosunnaeScore ?? 50.0,
        profileImageUrl: owner?.profileImageUrl,
        gender: guardianGender,
        age: guardianAge,
        isIdentityVerified: owner?.isIdentityVerified ?? false,
        isPetVerified: owner?.isVerified ?? false,
        isLocationVerified: owner?.isLocationVerified ?? false,
        pets: [
          GuardianPetInfo(
            id: pet.id,
            name: pet.name,
            breed: pet.breed ?? '품종 미상',
            ageString: '${age}살',
            likeCount: _likeCount,
            profileImageUrl: pet.profileImageUrl,
            photoUrls: pet.photoUrls,
            traits: traits,
            introduction: pet.bio,
          ),
        ],
      ),
    );
  }

  /// 특성 태그 (분홍색 계통 통일 디자인)
  Widget _buildTraits(PetModel pet) {
    final traits = pet.traits.map((t) => t.label).toList();
    return TraitSection(traits: traits);
  }

  /// 교배찾기 상세 내용
  Widget _buildBreedingDescription(PetModel pet) {
    return FutureBuilder<String?>(
      future: _getBreedingDescription(pet.id),
      builder: (context, snapshot) {
        final description = snapshot.data;
        if (description == null || description.isEmpty) {
          return const SizedBox.shrink();
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '교배 상세 내용',
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
                description,
                style: AppTextStyles.bodyMedium(context).copyWith(height: 1.6),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 교배찾기 글에서 description 가져오기
  Future<String?> _getBreedingDescription(String petId) async {
    try {
      final query = await _firebase.breedingPostsCollection
          .where('petId', isEqualTo: petId)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) {
        return query.docs.first.data()['description'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 소개글
  Widget _buildIntroduction(PetModel pet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '소개',
          style: AppTextStyles.headlineSmall(context),
        ),
        const SizedBox(height: AppSizes.gapM),
        Container(
          padding: const EdgeInsets.all(AppSizes.paddingL),
          decoration: BoxDecoration(
            color: context.sectionBackground,
            borderRadius: BorderRadius.circular(AppSizes.radiusS),
          ),
          child: Text(
            pet.bio ?? '소개글이 없습니다.',
            style: AppTextStyles.bodyMedium(context).copyWith(height: 1.6),
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
            Text(
              '보호자 정보',
              style: AppTextStyles.headlineSmall(context),
            ),
            const SizedBox(height: AppSizes.gapM),
            GestureDetector(
              onTap: () => _showGuardianProfile(context, pet, owner),
              child: Container(
                padding: const EdgeInsets.all(AppSizes.paddingL),
                decoration: BoxDecoration(
                  color: context.sectionBackground,
                  borderRadius: BorderRadius.circular(AppSizes.radiusS),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // 아이콘
                        MingrrAvatar(
                          imageUrl: owner?.profileImageUrl,
                          size: 50,
                          placeholderIcon: Icons.person,
                        ),
                        const SizedBox(width: AppSizes.gapM),
                        // 닉네임 + 꼬순내지수 (성별/나이 제거 - 개인정보 보호)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nickname,
                                style: AppTextStyles.titleMedium(context),
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
                    const SizedBox(height: AppSizes.gapM),
                    const MingrrDivider(),
                    const SizedBox(height: AppSizes.gapM),
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
          style: AppTextStyles.caption(context).withColor(
            isVerified ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.outlineVariant,
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
          // 좋아요 버튼 (공통 컴포넌트)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingS),
            child: LikeButton(
              count: _likeCount,
              isLiked: _isLiked,
              onTap: _toggleLike,
              size: InfoBadgeSize.large,
            ),
          ),
          const SizedBox(width: AppSizes.gapM),
          // 신청 버튼
          Expanded(
            child: MingrrButton(
              text: widget.isBreeding ? '교배 신청하기' : '데이트 신청하기',
              onPressed: () => _showRequestConfirmation(context),
              backgroundColor: context.features.dating,
              textColor: Colors.white,
              height: 56,
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
      await _datingService.sendDatingRequest(
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
    showDetailOptionsSheet(
      context: context,
      isOwner: false, // 상대방 반려동물 상세 화면
      onBlock: () => _blockUser(context),
      onReport: () {
        showReportSheet(
          context,
          targetId: widget.petId,
          targetName: '이 사용자',
          targetType: ReportTargetType.user,
        );
      },
    );
  }

  /// 사용자 차단
  Future<void> _blockUser(BuildContext context) async {
    final currentUserId = _firebase.currentUserId;
    if (currentUserId == null) {
      MingrrSnackBar.warning(context, '로그인이 필요합니다');
      return;
    }

    // 반려동물 주인 ID 조회
    final pet = ref.read(petByIdProvider(widget.petId)).valueOrNull;
    if (pet == null) return;

    final targetUserId = pet.ownerId;
    if (targetUserId == currentUserId) {
      MingrrSnackBar.warning(context, '본인은 차단할 수 없습니다');
      return;
    }

    // 차단 확인 시트
    showConfirmSheet(
      context,
      type: ConfirmSheetType.userBlock,
      onConfirm: () async {
        try {
          await _firestoreService.blockUser(currentUserId, targetUserId);
          if (mounted) {
            MingrrSnackBar.success(context, '사용자를 차단했습니다');
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
}

