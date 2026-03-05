import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../constants/app_icons.dart';
import '../../constants/app_sizes.dart';
import '../../constants/pet_constants.dart';
import '../../services/bottom_sheet_stack_manager.dart';
import '../../services/firebase_service.dart';
import '../../services/firestore_service.dart';
import '../kkosunnae_widgets.dart';
import '../badges/verification_badge.dart';
import '../common_widgets.dart';
import 'pet_profile_modal.dart';
import 'profile_modal_components.dart';
import '../badges/info_badge.dart';
import '../../../models/user_model.dart';
/// ============================================================
/// 보호자 프로필 모달 (공통 위젯)
/// 
/// 사용처:
/// - 데이팅 상세 > 보호자 정보 클릭
/// - 채팅 상세 > 보호자 아이콘 클릭
/// - 마켓 상세 > 판매자 아이콘 클릭
/// - 소모임 상세 > 멤버 아이콘 클릭
/// 
/// 표시 정보 (보안/안전 범위 내):
/// - 닉네임
/// - 꼬순내지수
/// - 인증 배지
/// - 등록된 반려동물 정보
/// - 활동 기록 (횟수만)
/// ============================================================

/// 보호자 성별
enum GuardianGender {
  male('남성'),
  female('여성'),
  unknown('미공개');

  final String label;
  const GuardianGender(this.label);

  /// 문자열에서 GuardianGender 변환
  static GuardianGender fromString(String? value) {
    switch (value) {
      case 'male': return GuardianGender.male;
      case 'female': return GuardianGender.female;
      default: return GuardianGender.unknown;
    }
  }

  /// UserGender에서 GuardianGender 변환
  static GuardianGender fromUserGender(UserGender? userGender) {
    if (userGender == null) return GuardianGender.unknown;
    switch (userGender) {
      case UserGender.male: return GuardianGender.male;
      case UserGender.female: return GuardianGender.female;
    }
  }
}

/// 보호자 프로필 모달 표시 함수
void showGuardianProfileModal(
  BuildContext context, {
  required String guardianId,
  required String guardianName,
  required double kkosunnaeScore,
  String? profileImageUrl,
  GuardianGender gender = GuardianGender.unknown,
  int? age,
  bool isIdentityVerified = false,
  bool isPetVerified = false,
  bool isLocationVerified = false,
  List<GuardianPetInfo> pets = const [],
  GuardianActivityInfo? activityInfo,
}) {
  showStackedProfileModal(
    context: context,
    type: BottomSheetType.guardian,
    id: guardianId,
    builder: (sheetContext) => GuardianProfileModal(
      guardianId: guardianId,
      guardianName: guardianName,
      kkosunnaeScore: kkosunnaeScore,
      profileImageUrl: profileImageUrl,
      gender: gender,
      age: age,
      isIdentityVerified: isIdentityVerified,
      isPetVerified: isPetVerified,
      isLocationVerified: isLocationVerified,
      pets: pets,
      activityInfo: activityInfo,
    ),
  );
}

/// 보호자 프로필 데이터 (Firestore에서 로드한 전체 데이터)
class GuardianProfileData {
  final UserModel user;
  final List<GuardianPetInfo> pets;
  final GuardianActivityInfo activityInfo;
  final GuardianGender gender;

  const GuardianProfileData({
    required this.user,
    required this.pets,
    required this.activityInfo,
    required this.gender,
  });
}

/// Firestore에서 보호자 프로필 데이터를 로드하고 모달을 표시하는 헬퍼 함수
///
/// 탭 즉시 로딩 모달을 표시하고, 데이터 로드 완료 후 콘텐츠로 전환합니다.
/// 에러 발생 시 fallbackName으로 기본 정보를 표시합니다.
void showGuardianProfileFromFirestore(
  BuildContext context, {
  required String userId,
  String? fallbackName,
  String? fallbackImageUrl,
  double fallbackScore = 50.0,
}) {
  showStackedProfileModal(
    context: context,
    type: BottomSheetType.guardian,
    id: userId,
    builder: (sheetContext) => _AsyncGuardianProfileModal(
      userId: userId,
      fallbackName: fallbackName ?? '사용자',
      fallbackImageUrl: fallbackImageUrl,
      fallbackScore: fallbackScore,
    ),
  );
}

/// 보호자 프로필 메모리 캐시 (TTL 5분)
class _GuardianProfileCache {
  static final _GuardianProfileCache _instance = _GuardianProfileCache._();
  factory _GuardianProfileCache() => _instance;
  _GuardianProfileCache._();

  static const _ttl = Duration(minutes: 5);
  final Map<String, _CachedProfile> _cache = {};

  _CachedProfile? get(String userId) {
    final cached = _cache[userId];
    if (cached == null) return null;
    if (DateTime.now().difference(cached.timestamp) > _ttl) {
      _cache.remove(userId);
      return null;
    }
    return cached;
  }

  void set(String userId, _CachedProfile profile) {
    _cache[userId] = profile;
  }
}

class _CachedProfile {
  final UserModel user;
  final List<GuardianPetInfo> pets;
  final DateTime timestamp;

  _CachedProfile({
    required this.user,
    required this.pets,
  }) : timestamp = DateTime.now();
}

/// 비동기 로딩을 지원하는 보호자 프로필 모달
class _AsyncGuardianProfileModal extends StatefulWidget {
  final String userId;
  final String fallbackName;
  final String? fallbackImageUrl;
  final double fallbackScore;

  const _AsyncGuardianProfileModal({
    required this.userId,
    required this.fallbackName,
    this.fallbackImageUrl,
    required this.fallbackScore,
  });

  @override
  State<_AsyncGuardianProfileModal> createState() => _AsyncGuardianProfileModalState();
}

class _AsyncGuardianProfileModalState extends State<_AsyncGuardianProfileModal> {
  bool _isLoading = true;
  String _guardianName = '';
  double _kkosunnaeScore = 50.0;
  String? _profileImageUrl;
  GuardianGender _gender = GuardianGender.unknown;
  int? _age;
  bool _isIdentityVerified = false;
  bool _isPetVerified = false;
  bool _isLocationVerified = false;
  List<GuardianPetInfo> _pets = [];
  GuardianActivityInfo? _activityInfo;

  @override
  void initState() {
    super.initState();
    _guardianName = widget.fallbackName;
    _kkosunnaeScore = widget.fallbackScore;
    _profileImageUrl = widget.fallbackImageUrl;
    _loadData();
  }

  void _applyUserData(UserModel user, List<GuardianPetInfo> pets) {
    setState(() {
      _guardianName = user.nickname;
      _kkosunnaeScore = user.kkosunnaeScore;
      _profileImageUrl = user.profileImageUrl;
      _gender = GuardianGender.fromUserGender(user.gender);
      _age = user.age;
      _isIdentityVerified = user.isIdentityVerified;
      _isPetVerified = user.isVerified;
      _isLocationVerified = user.isLocationVerified;
      _pets = pets;
      _activityInfo = GuardianActivityInfo.fromUser(user);
      _isLoading = false;
    });
  }

  Future<void> _loadData() async {
    try {
      // 캐시 우선 조회
      final cached = _GuardianProfileCache().get(widget.userId);
      if (cached != null && mounted) {
        _applyUserData(cached.user, cached.pets);
        return;
      }

      final user = await FirestoreService().getUser(widget.userId);
      if (!mounted || user == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final petsSnapshot = await FirebaseService().petsCollection
          .where('ownerId', isEqualTo: widget.userId)
          .get();

      final pets = petsSnapshot.docs
          .map((doc) => GuardianPetInfo.fromFirestoreDoc(doc))
          .toList();

      // 캐시 저장
      _GuardianProfileCache().set(widget.userId, _CachedProfile(
        user: user,
        pets: pets,
      ));

      if (!mounted) return;
      _applyUserData(user, pets);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return ProfileModalContainer(
        title: '보호자 정보',
        body: SizedBox(
          height: 200,
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      );
    }

    return GuardianProfileModal(
      guardianId: widget.userId,
      guardianName: _guardianName,
      kkosunnaeScore: _kkosunnaeScore,
      profileImageUrl: _profileImageUrl,
      gender: _gender,
      age: _age,
      isIdentityVerified: _isIdentityVerified,
      isPetVerified: _isPetVerified,
      isLocationVerified: _isLocationVerified,
      pets: _pets,
      activityInfo: _activityInfo,
    );
  }
}

/// 보호자의 반려동물 정보
class GuardianPetInfo {
  final String id;
  final String name;
  final String? breed;
  final String? ageString;
  final String? profileImageUrl;
  final List<String> photoUrls;
  final List<String> traits;
  final String? introduction;
  final int likeCount;

  const GuardianPetInfo({
    required this.id,
    required this.name,
    this.breed,
    this.ageString,
    this.profileImageUrl,
    this.photoUrls = const [],
    this.traits = const [],
    this.introduction,
    this.likeCount = 0,
  });

  /// Firestore 문서에서 GuardianPetInfo 생성
  factory GuardianPetInfo.fromFirestoreDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GuardianPetInfo(
      id: doc.id,
      name: data['name'] ?? '반려동물',
      breed: data['breed'],
      ageString: data['age'] != null ? '${data['age']}살' : null,
      introduction: data['introduction'],
      traits: (data['traits'] as List?)?.map((t) => PetTrait.labelFromName(t.toString())).toList() ?? [],
      photoUrls: List<String>.from(data['photoUrls'] ?? []),
      profileImageUrl: data['profileImageUrl'],
      likeCount: data['likeCount'] ?? 0,
    );
  }
}

/// 보호자 활동 정보
class GuardianActivityInfo {
  final int matchCount;      // 데이팅 매칭 성사
  final int transactionCount; // 거래 완료
  final int communityCount;   // 커뮤니티 게시글
  final int groupCount;       // 소모임 참여

  const GuardianActivityInfo({
    this.matchCount = 0,
    this.transactionCount = 0,
    this.communityCount = 0,
    this.groupCount = 0,
  });

  /// UserModel에서 활동 정보 생성
  factory GuardianActivityInfo.fromUser(UserModel user) {
    return GuardianActivityInfo(
      matchCount: user.matchCount,
      transactionCount: user.transactionCount,
      communityCount: user.postCount,
      groupCount: user.groupCount,
    );
  }

  /// Firestore raw Map에서 활동 정보 생성
  factory GuardianActivityInfo.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const GuardianActivityInfo();
    return GuardianActivityInfo(
      matchCount: (data['matchCount'] as num?)?.toInt() ?? 0,
      transactionCount: (data['transactionCount'] as num?)?.toInt() ?? 0,
      communityCount: (data['postCount'] as num?)?.toInt() ?? 0,
      groupCount: (data['groupCount'] as num?)?.toInt() ?? 0,
    );
  }
}

/// 보호자 프로필 모달 위젯
class GuardianProfileModal extends StatelessWidget {
  final String guardianId;
  final String guardianName;
  final double kkosunnaeScore;
  final String? profileImageUrl;
  final GuardianGender gender;
  final int? age;
  final bool isIdentityVerified;
  final bool isPetVerified;
  final bool isLocationVerified;
  final List<GuardianPetInfo> pets;
  final GuardianActivityInfo? activityInfo;

  const GuardianProfileModal({
    super.key,
    required this.guardianId,
    required this.guardianName,
    required this.kkosunnaeScore,
    this.profileImageUrl,
    this.gender = GuardianGender.unknown,
    this.age,
    this.isIdentityVerified = false,
    this.isPetVerified = false,
    this.isLocationVerified = false,
    this.pets = const [],
    this.activityInfo,
  });

  @override
  Widget build(BuildContext context) {
    return ProfileModalContainer(
      title: '보호자 정보',
      // 평가 버튼 제거 - 활동 기반 평가만 허용 (채팅 상세에서 평가)
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 보호자 기본 정보
          _buildGuardianInfo(context),
          const SizedBox(height: AppSizes.gapXL),
          
          // 인증 배지
          _buildVerificationBadges(context),
          const SizedBox(height: AppSizes.gapXL),
          
          // 등록된 반려동물
          _buildPetsSection(context),
          const SizedBox(height: AppSizes.gapXL),
          
          // 활동 기록
          _buildActivitySection(context),
          const SizedBox(height: AppSizes.gapL),
        ],
      ),
    );
  }

  /// 보호자 기본 정보
  Widget _buildGuardianInfo(BuildContext context) {
    return ProfileModalHeader(
      avatar: ProfileModalAvatar(
        imageUrl: profileImageUrl,
        fallbackIcon: AppIcons.profile,
      ),
      name: guardianName,
      subtitle: KkosunnaeScoreSmall(score: kkosunnaeScore),
    );
  }

  /// 인증 배지
  Widget _buildVerificationBadges(BuildContext context) {
    return ProfileModalSection(
      title: '인증 배지',
      content: Row(
        children: [
          VerificationBadgeMedium(
            type: VerificationBadgeType.identity,
            isVerified: isIdentityVerified,
          ),
          const SizedBox(width: AppSizes.gapS),
          VerificationBadgeMedium(
            type: VerificationBadgeType.pet,
            isVerified: isPetVerified,
          ),
          const SizedBox(width: AppSizes.gapS),
          VerificationBadgeMedium(
            type: VerificationBadgeType.location,
            isVerified: isLocationVerified,
          ),
        ],
      ),
    );
  }

  /// 등록된 반려동물 섹션
  Widget _buildPetsSection(BuildContext context) {
    // 반려동물이 없을 때 빈 상태 표시
    if (pets.isEmpty) {
      return ProfileModalSection(
        title: '반려동물',
        content: const MingrrEmptySection(
          icon: AppIcons.petOutlined,
          message: '등록된 반려동물이 없어요',
        ),
      );
    }
    
    return ProfileModalSection(
      title: '반려동물',
      content: ProfileModalHorizontalList<GuardianPetInfo>(
        items: pets,
        height: 120,
        itemSpacing: 12,
        itemBuilder: (context, pet, index) => _buildPetItem(context, pet),
      ),
    );
  }

  /// 반려동물 아이템
  Widget _buildPetItem(BuildContext context, GuardianPetInfo pet) {
    return ProfileModalItemCard(
      width: 100,
      avatar: ProfileModalAvatar(
        size: 50,
        imageUrl: pet.profileImageUrl,
        fallbackIcon: AppIcons.pet,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      title: pet.name,
      subtitleWidget: LikeCountText(count: pet.likeCount, size: InfoBadgeSize.small),
      onTap: () => _openPetProfile(context, pet),
    );
  }

  /// 반려동물 프로필 모달 열기
  void _openPetProfile(BuildContext context, GuardianPetInfo pet) {
    showPetProfileModal(
      context,
      petId: pet.id,
      petName: pet.name,
      breed: pet.breed,
      age: pet.ageString != null ? int.tryParse(pet.ageString!.replaceAll(RegExp(r'[^0-9]'), '')) : null,
      gender: 'male',
      introduction: pet.introduction ?? '안녕하세요! 저는 ${pet.name}예요.',
      traits: pet.traits,
      photoUrls: pet.photoUrls,
      profileImageUrl: pet.profileImageUrl,
      likeCount: pet.likeCount,
      guardianInfo: GuardianInfo(
        id: guardianId,
        nickname: guardianName,
        kkosunnaeScore: kkosunnaeScore,
        gender: gender,
        age: age,
        isIdentityVerified: isIdentityVerified,
        isPetVerified: isPetVerified,
        isLocationVerified: isLocationVerified,
        pets: pets,
        activityInfo: activityInfo,
      ),
    );
  }

  /// 활동 기록 섹션
  Widget _buildActivitySection(BuildContext context) {
    final info = activityInfo ?? const GuardianActivityInfo();
    return ProfileModalSection(
      title: '활동 기록',
      content: ProfileModalDetailsBox(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ProfileModalActivityItem(icon: AppIcons.like, label: '데이팅', count: info.matchCount),
              ProfileModalActivityItem(icon: AppIcons.shoppingBag, label: '거래', count: info.transactionCount),
              ProfileModalActivityItem(icon: AppIcons.article, label: '커뮤니티', count: info.communityCount),
              ProfileModalActivityItem(icon: AppIcons.group, label: '소모임', count: info.groupCount, unit: '개'),
            ],
          ),
        ],
      ),
    );
  }
}
