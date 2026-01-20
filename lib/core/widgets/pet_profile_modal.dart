import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/bottom_sheet_stack_manager.dart';
import '../theme/feature_colors.dart';
import '../theme/app_theme.dart';
import '../constants/app_sizes.dart';
import '../utils/app_logger.dart';
import 'common_widgets.dart';
import 'kkosunnae_widgets.dart';
import 'guardian_profile_modal.dart';
import 'trait_badge.dart';
import 'profile_modal_components.dart';
import 'info_badge.dart';

/// ============================================================
/// 반려동물 프로필 모달
/// 
/// 데이팅 채팅에서 반려동물 프로필을 표시할 때 사용
/// ============================================================

/// 반려동물 프로필 모달 표시 함수
void showPetProfileModal(
  BuildContext context, {
  required String petId,
  required String petName,
  String? breed,
  int? age,
  String? gender,
  double? weight,
  String? introduction,
  List<String> traits = const [],
  List<String> photoUrls = const [],
  String? profileImageUrl,
  int likeCount = 0,
  bool isIdentityVerified = false,
  bool isPetVerified = false,
  bool isLocationVerified = false,
  GuardianInfo? guardianInfo,
}) {
  // 상위 컨텍스트의 ScaffoldMessenger 저장 (바텀시트 닫힌 후에도 스낵바 표시 가능)
  final rootScaffoldMessenger = ScaffoldMessenger.of(context);
  
  showStackedProfileModal(
    context: context,
    type: BottomSheetType.pet,
    id: petId,
    builder: (sheetContext) => PetProfileModal(
      rootScaffoldMessenger: rootScaffoldMessenger,
      petId: petId,
      petName: petName,
      breed: breed,
      age: age,
      gender: gender,
      weight: weight,
      introduction: introduction,
      traits: traits,
      photoUrls: photoUrls,
      profileImageUrl: profileImageUrl,
      likeCount: likeCount,
      isIdentityVerified: isIdentityVerified,
      isPetVerified: isPetVerified,
      isLocationVerified: isLocationVerified,
      guardianInfo: guardianInfo,
    ),
  );
}

/// 보호자 정보
class GuardianInfo {
  final String id;
  final String nickname;
  final double kkosunnaeScore;
  final String? profileImageUrl;
  final GuardianGender gender;
  final int? age;
  final bool isIdentityVerified;
  final bool isPetVerified;
  final bool isLocationVerified;
  final List<GuardianPetInfo> pets;

  const GuardianInfo({
    required this.id,
    required this.nickname,
    this.kkosunnaeScore = 50.0,
    this.profileImageUrl,
    this.gender = GuardianGender.unknown,
    this.age,
    this.isIdentityVerified = false,
    this.isPetVerified = false,
    this.isLocationVerified = false,
    this.pets = const [],
  });
}

/// 반려동물 프로필 모달 위젯
class PetProfileModal extends StatefulWidget {
  final ScaffoldMessengerState? rootScaffoldMessenger;
  final String petId;
  final String petName;
  final String? breed;
  final int? age;
  final String? gender;
  final double? weight;
  final String? introduction;
  final List<String> traits;
  final List<String> photoUrls;
  final String? profileImageUrl;
  final int likeCount;
  final bool isIdentityVerified;
  final bool isPetVerified;
  final bool isLocationVerified;
  final GuardianInfo? guardianInfo;

  const PetProfileModal({
    super.key,
    this.rootScaffoldMessenger,
    required this.petId,
    required this.petName,
    this.breed,
    this.age,
    this.gender,
    this.weight,
    this.introduction,
    this.traits = const [],
    this.photoUrls = const [],
    this.profileImageUrl,
    this.likeCount = 0,
    this.isIdentityVerified = false,
    this.isPetVerified = false,
    this.isLocationVerified = false,
    this.guardianInfo,
  });

  @override
  State<PetProfileModal> createState() => _PetProfileModalState();
}

class _PetProfileModalState extends State<PetProfileModal> {
  bool _isLiked = false;
  int _currentLikeCount = 0;

  @override
  void initState() {
    super.initState();
    _currentLikeCount = widget.likeCount;
    _loadLikeStatus();
  }

  /// Firebase에서 좋아요 상태 로드
  Future<void> _loadLikeStatus() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        return;
      }

      // 반려동물의 좋아요 수 조회
      final petDoc = await FirebaseFirestore.instance
          .collection('pets')
          .doc(widget.petId)
          .get();
      if (petDoc.exists) {
        final data = petDoc.data();
        setState(() {
          _currentLikeCount = data?['likeCount'] ?? widget.likeCount;
        });
      }

      // 내가 좋아요 했는지 확인
      final likeDoc = await FirebaseFirestore.instance
          .collection('likes')
          .doc('${currentUser.uid}_${widget.petId}')
          .get();
      
      setState(() {
        _isLiked = likeDoc.exists;
      });
    } catch (e) {
      AppLogger.error('PetProfileModal', '좋아요 상태 로드 오류', e);
    }
  }

  /// 좋아요 토글
  Future<void> _toggleLike() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      MingrrSnackBar.warning(context, '로그인이 필요합니다');
      return;
    }

    final likeDocId = '${currentUser.uid}_${widget.petId}';
    final wasLiked = _isLiked;

    // 낙관적 업데이트
    setState(() {
      _isLiked = !_isLiked;
      _currentLikeCount += _isLiked ? 1 : -1;
    });

    try {
      if (wasLiked) {
        // 좋아요 취소
        await FirebaseFirestore.instance.collection('likes').doc(likeDocId).delete();
        await FirebaseFirestore.instance.collection('pets').doc(widget.petId).update({
          'likeCount': FieldValue.increment(-1),
        });
      } else {
        // 좋아요 추가
        await FirebaseFirestore.instance.collection('likes').doc(likeDocId).set({
          'userId': currentUser.uid,
          'petId': widget.petId,
          'createdAt': FieldValue.serverTimestamp(),
        });
        await FirebaseFirestore.instance.collection('pets').doc(widget.petId).update({
          'likeCount': FieldValue.increment(1),
        });
      }
      
      // 스낵바 표시 (rootScaffoldMessenger 사용하여 바텀시트에서도 표시)
      final messenger = widget.rootScaffoldMessenger ?? ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(_isLiked ? '${widget.petName}에게 좋아요를 보냈어요! ❤️' : '좋아요를 취소했어요'),
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      // 실패 시 롤백
      setState(() {
        _isLiked = wasLiked;
        _currentLikeCount += wasLiked ? 1 : -1;
      });
      final messenger = widget.rootScaffoldMessenger ?? ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        const SnackBar(content: Text('좋아요 처리 중 오류가 발생했습니다')),
      );
      AppLogger.error('PetProfileModal', '좋아요 토글 오류', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProfileModalContainer(
      title: '반려동물 정보',
      maxHeightRatio: 0.8,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 반려동물 기본 정보
          _buildPetInfo(),
          const SizedBox(height: AppSizes.gapL),
          
          // 사진 갤러리 (항상 표시)
          _buildPhotoGallery(),
          const SizedBox(height: AppSizes.gapL),
          
          // 성격&특성
          if (widget.traits.isNotEmpty) ...[
            TraitSection(traits: widget.traits),
            const SizedBox(height: AppSizes.gapL),
          ],
          
          // 소개 (항상 표시, 빈 상태 포함)
          _buildIntroduction(),
          const SizedBox(height: AppSizes.gapL),
          
          // 보호자 정보
          if (widget.guardianInfo != null) ...[
            _buildGuardianSection(context),
          ],
        ],
      ),
    );
  }

  /// 사진 갤러리 (MingrrImageGallery 활용)
  Widget _buildPhotoGallery() {
    // 사진이 없을 때 빈 상태 표시
    if (widget.photoUrls.isEmpty) {
      return ProfileModalSection(
        title: '사진',
        content: const MingrrEmptySection(
          icon: Icons.photo_library_outlined,
          message: '등록된 사진이 없어요',
        ),
      );
    }
    
    return ProfileModalSection(
      title: '사진',
      count: '${widget.photoUrls.length}장',
      content: MingrrImageGallery(
        imageUrls: widget.photoUrls,
        height: 80,
        itemWidth: 80,
        borderRadius: 12,
        enableViewer: true,
      ),
    );
  }

  /// 반려동물 기본 정보
  Widget _buildPetInfo() {
    final isMale = widget.gender == 'male' || widget.gender == '남아';
    
    return ProfileModalHeader(
      avatar: ProfileModalAvatar(
        imageUrl: widget.profileImageUrl,
        fallbackIcon: Icons.pets,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      name: widget.petName,
      badge: _buildGenderBadge(isMale),
      subtitle: Text(
        [
          if (widget.breed != null) widget.breed,
          if (widget.age != null) '${widget.age}살',
          if (widget.weight != null) '${widget.weight}kg',
        ].join(' · '),
        style: TextStyle(
          fontSize: 14,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: _buildLikeButton(),
    );
  }

  /// 성별 배지
  Widget _buildGenderBadge(bool isMale) {
    final genderText = isMale ? '남아' : '여아';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isMale ? Colors.blue.withValues(alpha: 0.15) : Colors.pink.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isMale ? Icons.male : Icons.female,
            size: 14,
            color: isMale ? Colors.blue : Colors.pink,
          ),
          const SizedBox(width: 3),
          Text(
            genderText,
            style: TextStyle(
              fontSize: 12,
              color: isMale ? Colors.blue : Colors.pink,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 좋아요 버튼
  Widget _buildLikeButton() {
    return LikeButton(
      count: _currentLikeCount,
      isLiked: _isLiked,
      onTap: _toggleLike,
      size: InfoBadgeSize.large,
    );
  }

  /// 소개
  Widget _buildIntroduction() {
    // 소개가 없을 때 빈 상태 표시
    if (widget.introduction == null || widget.introduction!.isEmpty) {
      return ProfileModalSection(
        title: '소개',
        content: const MingrrEmptySection(
          icon: Icons.description_outlined,
          message: '등록된 소개가 없어요',
          height: 60,
        ),
      );
    }
    
    return ProfileModalSection(
      title: '소개',
      content: ProfileModalDescriptionBox(text: widget.introduction!),
    );
  }

  /// 보호자 정보 섹션
  Widget _buildGuardianSection(BuildContext context) {
    final guardian = widget.guardianInfo!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '보호자 정보',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSizes.gapS),
        GestureDetector(
          onTap: () {
            showGuardianProfileModal(
              context,
              guardianId: guardian.id,
              guardianName: guardian.nickname,
              kkosunnaeScore: guardian.kkosunnaeScore,
              gender: guardian.gender,
              age: guardian.age,
              isIdentityVerified: guardian.isIdentityVerified,
              isPetVerified: guardian.isPetVerified,
              isLocationVerified: guardian.isLocationVerified,
              pets: guardian.pets,
            );
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.sectionBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.person, size: 22, color: Theme.of(context).colorScheme.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            guardian.nickname,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          KkosunnaeScoreSmall(score: guardian.kkosunnaeScore),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.outlineVariant),
                  ],
                ),
                // 인증 배지 (소형)
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSmallVerificationBadge(
                      icon: Icons.verified_user_outlined,
                      label: '본인인증',
                      isVerified: guardian.isIdentityVerified,
                    ),
                    _buildSmallVerificationBadge(
                      icon: Icons.pets_outlined,
                      label: '동물등록',
                      isVerified: guardian.isPetVerified,
                    ),
                    _buildSmallVerificationBadge(
                      icon: Icons.location_on_outlined,
                      label: '위치인증',
                      isVerified: guardian.isLocationVerified,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
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
          size: 18,
          color: isVerified ? context.features.success : Theme.of(context).colorScheme.outlineVariant,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isVerified ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        if (!isVerified)
          Icon(Icons.close, size: 10, color: Theme.of(context).colorScheme.outlineVariant),
      ],
    );
  }
}
