import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import 'common_widgets.dart';
import 'warmth_score.dart';
import 'verification_badge.dart';
import 'pet_profile_modal.dart';
import 'rating_modal.dart';
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
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: true,
    enableDrag: true,
    builder: (context) => GuardianProfileModal(
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
}

/// 보호자 활동 정보
class GuardianActivityInfo {
  final int walkCount;
  final int datingCount;
  final int marketCount;
  final int communityCount;

  const GuardianActivityInfo({
    this.walkCount = 0,
    this.datingCount = 0,
    this.marketCount = 0,
    this.communityCount = 0,
  });
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
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 드래그 핸들
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // 헤더
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM, vertical: AppSizes.paddingS),
            child: Row(
              children: [
                const SizedBox(width: 40),
                const Expanded(
                  child: Text(
                    '보호자 정보',
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
          
          const Divider(height: 1),
          
          // 본문
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 보호자 기본 정보
                  _buildGuardianInfo(),
                  
                  const SizedBox(height: AppSizes.gapXL),
                  
                  // 인증 배지
                  _buildVerificationBadges(),
                  
                  const SizedBox(height: AppSizes.gapXL),
                  
                  // 등록된 반려동물 (항상 표시)
                  _buildPetsSection(context),
                  const SizedBox(height: AppSizes.gapXL),
                  
                  // 활동 기록 (항상 표시)
                  _buildActivitySection(),
                  
                  const SizedBox(height: AppSizes.gapL),
                ],
              ),
            ),
          ),
          
          // 하단 꼬순내지수 평가 버튼
          _buildRatingButton(context),
        ],
      ),
    );
  }

  /// 꼬순내지수 평가 버튼
  Widget _buildRatingButton(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: AppSizes.paddingM,
        right: AppSizes.paddingM,
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
      child: ElevatedButton(
        onPressed: () {
          showRatingModal(
            context,
            targetName: guardianName,
            onRatingSelected: (rating) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$guardianName님을 "${rating.label}"로 평가했어요!'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pets, size: 20),
            SizedBox(width: 8),
            Text(
              '꼬순내지수 평가하기',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  /// 보호자 기본 정보
  Widget _buildGuardianInfo() {
    // 성별/나이 텍스트 생성
    String genderAgeText = '';
    if (gender != GuardianGender.unknown) {
      genderAgeText = gender.label;
      if (age != null) {
        genderAgeText += ' · ${age}세';
      }
    } else if (age != null) {
      genderAgeText = '${age}세';
    }
    
    return Row(
      children: [
        // 아바타 (프로필 이미지 또는 기본 아이콘)
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: profileImageUrl != null && profileImageUrl!.isNotEmpty
              ? ClipOval(
                  child: Image.network(
                    profileImageUrl!,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.person,
                      size: 30,
                      color: AppColors.primary,
                    ),
                  ),
                )
              : const Icon(
                  Icons.person,
                  size: 30,
                  color: AppColors.primary,
                ),
        ),
        const SizedBox(width: AppSizes.gapM),
        
        // 닉네임 + 성별/나이 + 꼬순내지수
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    guardianName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (genderAgeText.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: gender == GuardianGender.male 
                            ? Colors.blue.withOpacity(0.1) 
                            : Colors.pink.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        genderAgeText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: gender == GuardianGender.male ? Colors.blue : Colors.pink,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              KkosunnaeScoreSmall(score: kkosunnaeScore),
            ],
          ),
        ),
      ],
    );
  }

  /// 인증 배지
  Widget _buildVerificationBadges() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '인증 배지',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSizes.gapS),
        Row(
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
      ],
    );
  }

  /// 등록된 반려동물 섹션
  Widget _buildPetsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '반려동물 (${pets.length})',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSizes.gapS),
        ...pets.map((pet) => _buildPetItem(context, pet)),
      ],
    );
  }

  /// 반려동물 아이템 (클릭 시 반려동물 프로필 모달)
  Widget _buildPetItem(BuildContext context, GuardianPetInfo pet) {
    // 상위 Navigator context 저장 (pop 후에도 사용 가능)
    final rootContext = Navigator.of(context, rootNavigator: true).context;
    
    return GestureDetector(
      onTap: () {
        // 보호자 모달 닫기
        Navigator.pop(context);
        
        // 약간의 딜레이 후 반려동물 모달 열기
        Future.delayed(const Duration(milliseconds: 150), () {
          showPetProfileModal(
            rootContext,
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
            ),
          );
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // 반려동물 프로필 이미지 (원형)
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
                image: pet.profileImageUrl != null && !pet.profileImageUrl!.startsWith('default_avatar:')
                    ? DecorationImage(
                        image: NetworkImage(pet.profileImageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: pet.profileImageUrl == null || pet.profileImageUrl!.startsWith('default_avatar:')
                  ? const Icon(Icons.pets, size: 24, color: AppColors.primary)
                  : null,
            ),
            const SizedBox(width: 12),
            
            // 반려동물 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pet.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [pet.breed, pet.ageString].whereType<String>().join(' · '),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            
            // 좋아요 수
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.favorite, size: 14, color: AppColors.error),
                const SizedBox(width: 4),
                Text(
                  '${pet.likeCount}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }

  /// 활동 기록 섹션
  Widget _buildActivitySection() {
    final info = activityInfo ?? const GuardianActivityInfo();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '활동 기록',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSizes.gapS),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildActivityItem('산책', info.walkCount, Icons.directions_walk),
              _buildActivityItem('데이팅', info.datingCount, Icons.favorite),
              _buildActivityItem('거래', info.marketCount, Icons.shopping_bag),
              _buildActivityItem('소모임', info.communityCount, Icons.groups),
            ],
          ),
        ),
      ],
    );
  }

  /// 활동 아이템
  Widget _buildActivityItem(String label, int count, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(height: 4),
        Text(
          '$count회',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
