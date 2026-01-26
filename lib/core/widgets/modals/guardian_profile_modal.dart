import 'package:flutter/material.dart';
import '../../constants/app_sizes.dart';
import '../../services/bottom_sheet_stack_manager.dart';
import '../sheets/mingrr_bottom_sheet.dart';
import '../kkosunnae_widgets.dart';
import '../badges/verification_badge.dart';
import 'pet_profile_modal.dart';
import '../rating_widgets.dart';
import 'profile_modal_components.dart';
import '../badges/info_badge.dart';
import '../common_widgets.dart';
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
  final int groupCount;

  const GuardianActivityInfo({
    this.walkCount = 0,
    this.datingCount = 0,
    this.marketCount = 0,
    this.groupCount = 0,
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
    return ProfileModalContainer(
      title: '보호자 정보',
      bottomButton: _buildRatingButton(context),
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

  /// 꼬순내지수 평가 버튼
  Widget _buildRatingButton(BuildContext context) {
    return MingrrBottomButtonBar(
      child: MingrrButton(
        text: '꼬순내지수 평가하기',
        icon: Icons.pets,
        onPressed: () {
          showRatingModal(
            context,
            targetUserId: guardianId,
            targetName: guardianName,
          );
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        textColor: Colors.white,
        height: 50,
      ),
    );
  }

  /// 보호자 기본 정보
  Widget _buildGuardianInfo(BuildContext context) {
    return ProfileModalHeader(
      avatar: ProfileModalAvatar(
        imageUrl: profileImageUrl,
        fallbackIcon: Icons.person,
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
          icon: Icons.pets_outlined,
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
        fallbackIcon: Icons.pets,
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
              ProfileModalActivityItem(icon: Icons.directions_walk, label: '산책', count: info.walkCount),
              ProfileModalActivityItem(icon: Icons.favorite, label: '데이팅', count: info.datingCount),
              ProfileModalActivityItem(icon: Icons.shopping_bag, label: '거래', count: info.marketCount),
              ProfileModalActivityItem(icon: Icons.groups, label: '소모임', count: info.groupCount),
            ],
          ),
        ],
      ),
    );
  }
}
