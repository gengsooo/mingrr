import 'package:flutter/material.dart';
import '../constants/app_sizes.dart';
import '../theme/app_theme.dart';
import 'common_widgets.dart';
import 'mingrr_bottom_sheet.dart';
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
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BottomSheetHandle(),
          // 헤더
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 4, 20, 4),
            child: Text(
              '보호자 정보',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ),
          
          // 본문
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 보호자 기본 정보
                  _buildGuardianInfo(context),
                  
                  const SizedBox(height: AppSizes.gapXL),
                  
                  // 인증 배지
                  _buildVerificationBadges(context),
                  
                  const SizedBox(height: AppSizes.gapXL),
                  
                  // 등록된 반려동물 (항상 표시)
                  _buildPetsSection(context),
                  const SizedBox(height: AppSizes.gapXL),
                  
                  // 활동 기록 (항상 표시)
                  _buildActivitySection(context),
                  
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
    return MingrrBottomButtonBar(
      child: ElevatedButton(
        onPressed: () {
          showRatingModal(
            context,
            targetName: guardianName,
            onRatingSelected: (rating) {
              MingrrSnackBar.success(context, '$guardianName님을 "${rating.label}"로 평가했어요!');
            },
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
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
  Widget _buildGuardianInfo(BuildContext context) {
    // 보호자 성별/나이는 개인정보 보호를 위해 표시하지 않음
    
    return Row(
      children: [
        // 아바타 (프로필 이미지 또는 기본 아이콘)
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: profileImageUrl != null && profileImageUrl!.isNotEmpty
              ? ClipOval(
                  child: Image.network(
                    profileImageUrl!,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.person,
                      size: 30,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                )
              : Icon(
                  Icons.person,
                  size: 30,
                  color: Theme.of(context).colorScheme.primary,
                ),
        ),
        const SizedBox(width: AppSizes.gapM),
        
        // 닉네임 + 꼬순내지수 (성별/나이 제거)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                guardianName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
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
  Widget _buildVerificationBadges(BuildContext context) {
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
          color: context.sectionBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // 반려동물 프로필 이미지 (원형)
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
                image: pet.profileImageUrl != null && !pet.profileImageUrl!.startsWith('default_avatar:')
                    ? DecorationImage(
                        image: NetworkImage(pet.profileImageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: pet.profileImageUrl == null || pet.profileImageUrl!.startsWith('default_avatar:')
                  ? Icon(Icons.pets, size: 24, color: Theme.of(context).colorScheme.primary)
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
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            
            // 좋아요 수
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.favorite, size: 14, color: Colors.red),
                const SizedBox(width: 4),
                Text(
                  '${pet.likeCount}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 18, color: Theme.of(context).colorScheme.outlineVariant),
          ],
        ),
      ),
    );
  }

  /// 활동 기록 섹션
  Widget _buildActivitySection(BuildContext context) {
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
            color: context.sectionBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildActivityItem(context, '산책', info.walkCount, Icons.directions_walk),
              _buildActivityItem(context, '데이팅', info.datingCount, Icons.favorite),
              _buildActivityItem(context, '거래', info.marketCount, Icons.shopping_bag),
              _buildActivityItem(context, '소모임', info.communityCount, Icons.groups),
            ],
          ),
        ),
      ],
    );
  }

  /// 활동 아이템
  Widget _buildActivityItem(BuildContext context, String label, int count, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
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
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
