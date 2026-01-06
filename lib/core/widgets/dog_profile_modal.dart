import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import 'common_widgets.dart';
import 'warmth_score.dart';
import 'verification_badge.dart';
import 'guardian_profile_modal.dart';
import 'trait_badge.dart';

/// ============================================================
/// 강아지 프로필 모달
/// 
/// 데이팅 채팅에서 강아지 프로필을 표시할 때 사용
/// ============================================================

/// 강아지 프로필 모달 표시 함수
void showDogProfileModal(
  BuildContext context, {
  required String dogId,
  required String dogName,
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
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: true,
    enableDrag: true,
    builder: (context) => DogProfileModal(
      dogId: dogId,
      dogName: dogName,
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
  final GuardianGender gender;
  final int? age;
  final bool isIdentityVerified;
  final bool isPetVerified;
  final bool isLocationVerified;

  const GuardianInfo({
    required this.id,
    required this.nickname,
    this.kkosunnaeScore = 50.0,
    this.gender = GuardianGender.unknown,
    this.age,
    this.isIdentityVerified = false,
    this.isPetVerified = false,
    this.isLocationVerified = false,
  });
}

/// 강아지 프로필 모달 위젯
class DogProfileModal extends StatefulWidget {
  final String dogId;
  final String dogName;
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

  const DogProfileModal({
    super.key,
    required this.dogId,
    required this.dogName,
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
  State<DogProfileModal> createState() => _DogProfileModalState();
}

class _DogProfileModalState extends State<DogProfileModal> {
  late bool isLiked;
  late int currentLikeCount;

  @override
  void initState() {
    super.initState();
    isLiked = false;
    currentLikeCount = widget.likeCount;
  }

  Future<void> _toggleLike() async {
    setState(() {
      isLiked = !isLiked;
      currentLikeCount = isLiked ? currentLikeCount + 1 : currentLikeCount - 1;
    });
    
    try {
      // Firebase에 좋아요 수 업데이트
      final petRef = FirebaseFirestore.instance.collection('pets').doc(widget.dogId);
      await petRef.update({
        'likeCount': FieldValue.increment(isLiked ? 1 : -1),
      });
    } catch (e) {
      // 오류 발생 시 원래 상태로 복구
      setState(() {
        isLiked = !isLiked;
        currentLikeCount = isLiked ? currentLikeCount + 1 : currentLikeCount - 1;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('좋아요 처리 중 오류가 발생했습니다')),
        );
      }
      return;
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isLiked ? '${widget.dogName}에게 좋아요를 보냈어요! ❤️' : '좋아요를 취소했어요'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 핸들
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // 헤더
          Padding(
            padding: const EdgeInsets.all(AppSizes.paddingM),
            child: Row(
              children: [
                const SizedBox(width: 40),
                const Expanded(
                  child: Text(
                    '반려동물 정보',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    Navigator.pop(context);
                    if (widget.guardianInfo != null) {
                      Future.delayed(const Duration(milliseconds: 300), () {
                        showGuardianProfileModal(
                          context,
                          guardianId: widget.guardianInfo!.id,
                          guardianName: widget.guardianInfo!.nickname,
                          kkosunnaeScore: widget.guardianInfo!.kkosunnaeScore,
                          gender: widget.guardianInfo!.gender,
                          age: widget.guardianInfo!.age,
                          isIdentityVerified: widget.guardianInfo!.isIdentityVerified,
                          isPetVerified: widget.guardianInfo!.isPetVerified,
                          isLocationVerified: widget.guardianInfo!.isLocationVerified,
                        );
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // 본문
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.paddingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 강아지 기본 정보
                  _buildDogInfo(),
                  const SizedBox(height: AppSizes.gapL),
                  
                  // 사진 갤러리
                  if (widget.photoUrls.isNotEmpty) ...[
                    _buildPhotoGallery(),
                    const SizedBox(height: AppSizes.gapL),
                  ],
                  
                  // 성격&특성 (노란색 계통)
                  if (widget.traits.isNotEmpty) ...[
                    TraitSection(traits: widget.traits),
                    const SizedBox(height: AppSizes.gapL),
                  ],
                  
                  // 소개
                  if (widget.introduction != null && widget.introduction!.isNotEmpty) ...[
                    _buildIntroduction(),
                    const SizedBox(height: AppSizes.gapL),
                  ],
                  
                  // 보호자 정보
                  if (widget.guardianInfo != null) ...[
                    _buildGuardianSection(context),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 사진 갤러리
  Widget _buildPhotoGallery() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '사진',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            Text(
              '${widget.photoUrls.length}장',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.gapS),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.photoUrls.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _showFullScreenImage(context, index),
                child: Container(
                  width: 80,
                  height: 80,
                  margin: EdgeInsets.only(right: index < widget.photoUrls.length - 1 ? 8 : 0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Image.network(
                      widget.photoUrls[index],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.dating.withOpacity(0.1),
                        child: const Icon(Icons.pets, color: AppColors.dating),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// 전체 화면 이미지 보기
  void _showFullScreenImage(BuildContext context, int initialIndex) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            PageView.builder(
              controller: PageController(initialPage: initialIndex),
              itemCount: widget.photoUrls.length,
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  child: Center(
                    child: Image.network(
                      widget.photoUrls[index],
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.image_not_supported,
                        color: Colors.white54,
                        size: 60,
                      ),
                    ),
                  ),
                );
              },
            ),
            // 닫기 버튼
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 8,
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            // 페이지 인디케이터
            if (widget.photoUrls.length > 1)
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 20,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.photoUrls.length,
                    (index) => Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 강아지 기본 정보
  Widget _buildDogInfo() {
    final isMale = widget.gender == 'male' || widget.gender == '남아';
    final genderText = isMale ? '남아' : '여아';
    
    return Row(
      children: [
        // 프로필 이미지 (프로필 이미지만 사용, default_avatar 제외)
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            shape: BoxShape.circle,
          ),
          child: _hasValidProfileImage()
              ? ClipOval(
                  child: Image.network(
                    widget.profileImageUrl!,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.pets,
                      size: 40,
                      color: AppColors.primary,
                    ),
                  ),
                )
              : const Icon(
                  Icons.pets,
                  size: 40,
                  color: AppColors.primary,
                ),
        ),
        const SizedBox(width: AppSizes.gapM),
        
        // 정보
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    widget.dogName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 성별 아이콘
                  Icon(
                    isMale ? Icons.male : Icons.female,
                    size: 20,
                    color: isMale ? Colors.blue : Colors.pink,
                  ),
                  const Spacer(),
                  // 좋아요 (클릭 가능)
                  GestureDetector(
                    onTap: _toggleLike,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            size: 24,
                            color: AppColors.dating,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$currentLikeCount',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.dating,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                [
                  if (widget.breed != null) widget.breed,
                  if (widget.age != null) '${widget.age}살',
                  genderText,
                  if (widget.weight != null) '${widget.weight}kg',
                ].join(' · '),
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 소개
  Widget _buildIntroduction() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '소개',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSizes.gapS),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            widget.introduction!,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  /// 보호자 정보 섹션
  Widget _buildGuardianSection(BuildContext context) {
    final guardian = widget.guardianInfo!;
    
    // 성별/나이 텍스트
    String genderAgeText = '';
    if (guardian.gender != GuardianGender.unknown) {
      genderAgeText = guardian.gender.label;
      if (guardian.age != null) {
        genderAgeText += ' · ${guardian.age}세';
      }
    } else if (guardian.age != null) {
      genderAgeText = '${guardian.age}세';
    }
    
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
            Navigator.pop(context);
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
            );
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
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
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person, size: 22, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                guardian.nickname,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (genderAgeText.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: guardian.gender == GuardianGender.male
                                        ? Colors.blue.withOpacity(0.1)
                                        : Colors.pink.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    genderAgeText,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: guardian.gender == GuardianGender.male
                                          ? Colors.blue
                                          : Colors.pink,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          KkosunnaeScoreSmall(score: guardian.kkosunnaeScore),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.textHint),
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
          color: isVerified ? AppColors.success : AppColors.textHint,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isVerified ? AppColors.textPrimary : AppColors.textHint,
          ),
        ),
        if (!isVerified)
          const Icon(Icons.close, size: 10, color: AppColors.textHint),
      ],
    );
  }
  
  /// 유효한 프로필 이미지가 있는지 확인
  bool _hasValidProfileImage() {
    return widget.profileImageUrl != null && 
           widget.profileImageUrl!.isNotEmpty && 
           !widget.profileImageUrl!.startsWith('default_avatar:');
  }
}
