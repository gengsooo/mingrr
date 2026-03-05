import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/theme/feature_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/pet_constants.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/nickname_service.dart';
import '../../../../core/services/share_service.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/dialogs/dialogs.dart';
import '../../../../core/widgets/sheets/image_picker_sheet.dart';
import '../../../../core/widgets/sheets/mingrr_bottom_sheet.dart';
import '../../../../core/widgets/badges/verification_badge.dart';
import '../../../../core/widgets/kkosunnae_widgets.dart';
import '../../../../core/widgets/location_bubble_widget.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/providers/location_verification_provider.dart';
import '../../../../core/utils/location_verification_helper.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../pet/presentation/providers/pet_provider.dart';
import '../../../../core/utils/error_handler.dart';
import 'my_activity_screen.dart';
import 'liked_list_screen.dart';
import 'rating_history_screen.dart';
import 'pet_edit_screen.dart';
import 'profile_edit_screen.dart';
import 'settings/notification_settings_screen.dart';
import '../providers/profile_provider.dart';
import 'settings/app_settings_screen.dart';
import 'settings/account_settings_screen.dart';
import 'settings/customer_service_screen.dart';
import 'settings/app_info_screen.dart';
import 'pet_registration_verification_dialog.dart';

/// ============================================================
/// 프로필 화면 (V2 리팩토링 - 반려동물 전용)
/// 
/// 변경사항:
/// - 반려동물 전용 앱으로 변경 (PetType 제거)
/// - 예방접종 인증 → 위치 인증으로 변경
/// - 인증/배지 관리 (본인인증, 위치인증, 동물등록)
/// - 건강수첩 접근
/// - Firebase 데이터 연동
/// ============================================================

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final verificationsAsync = ref.watch(userVerificationsProvider);
    
    // 백엔드 인증 상태를 BadgeType 맵으로 변환
    final verifications = verificationsAsync.when(
      data: (data) => {
        BadgeType.identity: data['identity'] ?? false,
        BadgeType.location: data['location'] ?? false,
        BadgeType.petRegistration: data['petRegistration'] ?? false,
      },
      loading: () => {
        BadgeType.identity: false,
        BadgeType.location: false,
        BadgeType.petRegistration: false,
      },
      error: (_, _) => {
        BadgeType.identity: false,
        BadgeType.location: false,
        BadgeType.petRegistration: false,
      },
    );

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ===== 프로필 헤더 =====
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            surfaceTintColor: Colors.transparent,
            elevation: AppSizes.elevationNone,
            scrolledUnderElevation: 0.5,
            title: const Text('프로필'),
            centerTitle: true,
            leading: MingrrLeadingButton.back(
              showShadow: false,
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/');
                }
              },
            ),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: _buildProfileHeader(context, ref, currentUser),
            ),
            actions: [
              // 개발자 도구 버튼 (debug 빌드 + admin 전용)
              if (kDebugMode && currentUser.valueOrNull?.email == 'admin@mingrr.com')
                IconButton(
                  icon: Icon(AppIcons.developerMode, color: Theme.of(context).colorScheme.tertiary),
                  onPressed: () => context.push('/dev-tools'),
                  tooltip: '개발자 도구',
                ),
              // 설정 버튼 (우상단 톱니바퀴)
              IconButton(
                icon: const Icon(AppIcons.settingsOutlined),
                onPressed: () => _showSettingsSheet(context, ref),
              ),
            ],
          ),

          // ===== 컨텐츠 =====
          SliverPadding(
            padding: const EdgeInsets.all(AppSizes.paddingM),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 인증 배지
                _buildVerificationSection(context, ref, verifications),
                
                const SizedBox(height: AppSizes.gapXL),
                
                // 내 반려동물 (건강수첩 포함)
                MingrrSectionHeader(
                  title: '내 반려동물',
                  actionText: '추가',
                  onActionTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PetEditScreen()),
                    );
                  },
                ),
                const SizedBox(height: AppSizes.gapM),
                _buildMyPets(context, ref),
                
                const SizedBox(height: AppSizes.gapXL),
                
                // 활동 통계
                const MingrrSectionHeader(title: '활동 기록'),
                const SizedBox(height: AppSizes.gapM),
                _buildActivityStats(context, ref),
                
                const SizedBox(height: AppSizes.gapXL),
                
                // 메뉴 목록
                _buildMenuList(context, ref),
                
                const SizedBox(height: AppSizes.gapXXL),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  /// 프로필 헤더 (보호자 사진 선택적 업로드 가능)
  Widget _buildProfileHeader(BuildContext context, WidgetRef ref, AsyncValue<dynamic> currentUser) {
    return Container(
      decoration: BoxDecoration(
        gradient: context.features.warmGradient,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: AppSizes.paddingXXL, bottom: 12), // 앱바 높이만큼 상단 패딩
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 프로필 이미지 (선택적 - 없으면 기본 아이콘)
              GestureDetector(
                onTap: () => _showProfileImagePicker(context, ref),
                child: Stack(
                  children: [
                    currentUser.when(
                      data: (user) => _buildProfileImage(context, user?.profileImageUrl),
                      loading: () => _buildProfileImage(context, null),
                      error: (_, _) => _buildProfileImage(context, null),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          AppIcons.camera,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.gapS),
              
              // 닉네임 + 수정 버튼
              currentUser.when(
                data: (user) => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      user?.nickname ?? '사용자',
                      style: AppTextStyles.headlineMedium(context).withWeight(FontWeight.w700),
                    ),
                    const SizedBox(width: AppSizes.gapS),
                    GestureDetector(
                      onTap: () => _showNicknameEditDialog(context, ref, user),
                      child: Container(
                        padding: const EdgeInsets.all(AppSizes.paddingXS),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          AppIcons.edit,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                loading: () => const Text('로딩 중...'),
                error: (_, _) => const Text('사용자'),
              ),
              const SizedBox(height: AppSizes.gapS),
              
              // 꼬순내지수 (개선된 디자인)
              currentUser.when(
                data: (user) => _buildKkosunnaeScore(context, ref, user?.kkosunnaeScore ?? 50.0),
                loading: () => const SizedBox(),
                error: (_, _) => const SizedBox(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 인증 배지 섹션 (통일된 인증 배지 위젯 사용 + 위치 불일치 말풍선)
  Widget _buildVerificationSection(
    BuildContext context,
    WidgetRef ref,
    Map<BadgeType, bool> verifications,
  ) {
    // 위치 불일치 상태 감지
    final mismatchAsync = ref.watch(locationMismatchProvider);
    final shouldShowBubble = mismatchAsync.valueOrNull?.shouldShowBubble ?? false;
    final userAsync = ref.watch(currentUserStreamProvider);
    final user = userAsync.valueOrNull;
    
    return Column(
      children: [
        // 위치 불일치 말풍선 (위치 인증 카드 위에 표시)
        if (shouldShowBubble)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.paddingS),
            child: LocationMismatchBanner(
              savedAddress: user?.homeAddress,
              onUpdateLocation: () => _handleLocationUpdate(context, ref),
              onDismiss: () => _handleLocationDismiss(ref),
            ),
          ),
        
        MingrrCard(
          margin: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '인증 배지',
                    style: AppTextStyles.titleLarge(context).withWeight(FontWeight.w600),
                  ),
                  GestureDetector(
                    onTap: () => _showVerificationSheet(context, ref, verifications),
                    child: Text(
                      '인증하기',
                      style: AppTextStyles.titleSmall(context).withColor(Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.gapM),
              Row(
                children: [
                  Expanded(
                    child: VerificationBadgeLarge(
                      type: VerificationBadgeType.identity,
                      isVerified: verifications[BadgeType.identity] ?? false,
                      onTap: () => _showVerificationSheet(context, ref, verifications),
                    ),
                  ),
                  const SizedBox(width: AppSizes.gapS),
                  Expanded(
                    child: VerificationBadgeLarge(
                      type: VerificationBadgeType.pet,
                      isVerified: verifications[BadgeType.petRegistration] ?? false,
                      onTap: () => _showVerificationSheet(context, ref, verifications),
                    ),
                  ),
                  const SizedBox(width: AppSizes.gapS),
                  Expanded(
                    child: VerificationBadgeLarge(
                      type: VerificationBadgeType.location,
                      isVerified: verifications[BadgeType.location] ?? false,
                      onTap: () => _showVerificationSheet(context, ref, verifications),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  /// 위치 업데이트 처리 (불일치 시 현재 위치로 변경) - 공통 함수 사용
  Future<void> _handleLocationUpdate(BuildContext context, WidgetRef ref) async {
    final authState = ref.read(authStateProvider);
    final userId = authState.valueOrNull?.uid;
    
    if (userId == null) {
      MingrrSnackBar.warning(context, '로그인이 필요합니다');
      return;
    }
    
    await LocationVerificationService.handleLocationUpdateWithUI(
      context: context,
      userId: userId,
    );
  }
  
  /// 위치 알림 무시 처리
  Future<void> _handleLocationDismiss(WidgetRef ref) async {
    final authState = ref.read(authStateProvider);
    final userId = authState.valueOrNull?.uid;
    
    if (userId == null) return;
    
    await LocationVerificationService.dismissReminder(userId);
  }

  /// 내 반려동물 목록 (V1: 건강수첩 버튼 포함)
  Widget _buildMyPets(BuildContext context, WidgetRef ref) {
    final petsAsync = ref.watch(userPetsProvider);
    
    return petsAsync.when(
      data: (pets) {
        return SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: pets.length + 1, // 반려동물들 + 추가 버튼
            itemBuilder: (context, index) {
              if (index == pets.length) {
                // 추가 버튼
                return Container(
              width: 120,
              margin: const EdgeInsets.only(right: AppSizes.gapM),
              child: MingrrCard(
                margin: EdgeInsets.zero,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PetEditScreen()),
                  );
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        AppIcons.add,
                        color: Theme.of(context).colorScheme.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: AppSizes.gapS),
                    Text(
                      '추가하기',
                      style: AppTextStyles.titleSmall(context).withColor(Theme.of(context).colorScheme.primary),
                    ),
                  ],
                ),
              ),
            );
          }

              final pet = pets[index];
              return _buildPetCard(context, pet);
            },
          ),
        );
      },
      loading: () => const MingrrLoadingState(type: MingrrLoadingType.primary, message: '반려동물 정보를 불러오고 있어요'),
      error: (_, _) => const SizedBox(),
    );
  }

  /// 반려동물 카드 (V2: 건강수첩 버튼 포함)
  Widget _buildPetCard(BuildContext context, pet) {
    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: AppSizes.gapS),
      child: MingrrCard(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(AppSizes.paddingXS),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PetEditScreen(petId: pet.id),
            ),
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 프로필 이미지 (프로필 이미지만 사용, 없으면 발바닥 아이콘)
            MingrrImage.petAvatar(
              size: 55,
              imageUrl: pet.profileImageUrl,
            ),
            const SizedBox(height: AppSizes.gapS),
            Text(
              pet.name,
              style: AppTextStyles.titleMedium(context).withWeight(FontWeight.w600),
            ),
            const SizedBox(height: AppSizes.gapS),
            // 건강수첩 버튼 (확대)
            GestureDetector(
              onTap: () => context.push('/health?petId=${pet.id}'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppSizes.paddingS),
                decoration: BoxDecoration(
                  color: context.features.health.withValues(alpha: AppOpacity.o10),
                  borderRadius: BorderRadius.circular(AppSizes.radiusM),
                  border: Border.all(color: context.features.health.withValues(alpha: AppOpacity.o30)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(AppIcons.health, size: 16, color: context.features.health),
                    const SizedBox(width: AppSizes.gapS),
                    Text(
                      '건강수첩',
                      style: AppTextStyles.labelLarge(context).withWeight(FontWeight.w600).withColor(context.features.health),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 활동 통계 (Firebase 연동)
  /// 순서: 산책 → 매칭 → 거래 → 커뮤니티 → 모임
  Widget _buildActivityStats(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(userActivityStatsProvider);
    
    return statsAsync.when(
      data: (stats) => _buildActivityStatsCard(
        context,
        walks: '${stats['walks'] ?? 0}회',
        matches: '${stats['matches'] ?? 0}',
        transactions: '${stats['transactions'] ?? 0}',
        posts: '${stats['posts'] ?? 0}',
        groups: '${stats['groups'] ?? 0}',
      ),
      loading: () => _buildActivityStatsCard(
        context,
        walks: '-',
        matches: '-',
        transactions: '-',
        posts: '-',
        groups: '-',
      ),
      error: (_, _) => _buildActivityStatsCard(
        context,
        walks: '0회',
        matches: '0',
        transactions: '0',
        posts: '0',
        groups: '0',
      ),
    );
  }
  
  /// 활동 통계 카드 빌더
  Widget _buildActivityStatsCard(
    BuildContext context, {
    required String walks,
    required String matches,
    required String transactions,
    required String posts,
    required String groups,
  }) {
    return MingrrCard(
      margin: EdgeInsets.zero,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(context, '산책', walks),
          _buildStatDivider(context),
          _buildStatItem(context, '매칭', matches),
          _buildStatDivider(context),
          _buildStatItem(context, '거래', transactions),
          _buildStatDivider(context),
          _buildStatItem(context, '커뮤니티', posts),
          _buildStatDivider(context),
          _buildStatItem(context, '모임', groups),
        ],
      ),
    );
  }

  /// 통계 아이템
  Widget _buildStatItem(BuildContext context, String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: AppTextStyles.titleLarge(context).withWeight(FontWeight.w700),
          ),
          const SizedBox(height: AppSizes.gapXXS),
          Text(
            label,
            style: AppTextStyles.caption(context).withColor(Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  /// 통계 구분선
  Widget _buildStatDivider(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }

  /// 메뉴 목록 (활동/콘텐츠 관련만)
  Widget _buildMenuList(BuildContext context, WidgetRef ref) {
    // 하단 메뉴: 활동/콘텐츠 관련 (자주 접근)
    // 받은 데이팅 신청은 채팅 > 데이팅 탭에서 관리하므로 제거
    final menus = [
      {
        'icon': AppIcons.history,
        'label': '내 활동',
        'badge': null,
        'screen': const MyActivityScreen(),
      },
      {
        'icon': AppIcons.starOutlined,
        'label': '평가 이력',
        'badge': null,
        'screen': const RatingHistoryScreen(),
      },
      {
        'icon': AppIcons.likeOutlined,
        'label': '좋아요 목록',
        'badge': null,
        'screen': const LikedListScreen(),
      },
    ];

    return MingrrCard(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      child: Column(
        children: menus.asMap().entries.map((entry) {
          final index = entry.key;
          final menu = entry.value;
          final isLast = index == menus.length - 1;

          return Column(
            children: [
              MingrrSettingsTile.badge(
                icon: menu['icon'] as IconData,
                title: menu['label'] as String,
                badgeText: menu['badge'] as String?,
                badgeColor: context.features.dating,
                onTap: () {
                  final screen = menu['screen'] as Widget?;
                  if (screen != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => screen),
                    );
                  } else {
                    MingrrSnackBar.info(context, '준비 중인 기능입니다');
                  }
                },
              ),
              if (!isLast)
                const Divider(height: 1, indent: 56),
            ],
          );
        }).toList(),
      ),
    );
  }

  /// 인증 바텀시트 (V1: 본인인증, 동물등록, 예방접종)
  void _showVerificationSheet(
    BuildContext context,
    WidgetRef ref,
    Map<BadgeType, bool> verifications,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSizes.bottomSheetRadius),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BottomSheetHandle(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingS),
              child: Text(
                '인증 관리',
                style: AppTextStyles.headlineMedium(context).withWeight(FontWeight.w700),
                textAlign: TextAlign.center,
              ),
            ),
            // 설명 문구 (데이트 신청 바텀시트와 동일한 스타일)
            Text(
              '인증을 완료하면 더 많은 친구들에게\n추천될 수 있어요!',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium(context).withColor(Theme.of(context).colorScheme.onSurfaceVariant).withHeight(1.4),
            ),
            const SizedBox(height: AppSizes.gapL),
            
            // 본인인증
            _buildVerificationTile(
              context: context,
              ref: ref,
              badgeType: BadgeType.identity,
              isVerified: verifications[BadgeType.identity] ?? false,
              description: '휴대폰 본인인증을 완료해주세요',
            ),
            
            // 동물등록 인증
            _buildVerificationTile(
              context: context,
              ref: ref,
              badgeType: BadgeType.petRegistration,
              isVerified: verifications[BadgeType.petRegistration] ?? false,
              description: '동물등록 인증을 완료해주세요',
            ),
            
            // 위치 인증 (당근마켓 스타일)
            _buildVerificationTile(
              context: context,
              ref: ref,
              badgeType: BadgeType.location,
              isVerified: verifications[BadgeType.location] ?? false,
              description: '현재 위치에서 동네 인증을 해주세요',
            ),
            
            SizedBox(height: ResponsiveUtils.bottomPaddingWith(context, 16)),
          ],
        ),
      ),
    );
  }

  /// 인증 타일
  Widget _buildVerificationTile({
    required BuildContext context,
    required WidgetRef ref,
    required BadgeType badgeType,
    required bool isVerified,
    required String description,
  }) {
    // 위치 인증은 완료 후에도 재인증 가능
    final bool canReVerify = badgeType == BadgeType.location && isVerified;
    
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isVerified
              ? context.features.success.withValues(alpha: AppOpacity.o10)
              : Theme.of(context).colorScheme.outline.withValues(alpha: AppOpacity.o50),
          borderRadius: BorderRadius.circular(AppSizes.radiusS),
        ),
        child: Center(
          child: Icon(badgeType.icon, size: 22, color: isVerified ? context.features.success : Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ),
      title: Text(
        badgeType.label,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        isVerified ? '인증 완료' : description,
        style: AppTextStyles.bodySmall(context).withColor(
          isVerified ? context.features.success : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: isVerified
          ? canReVerify
              // 위치 인증: 체크 아이콘 + 재인증 버튼
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(AppIcons.success, color: context.features.success, size: 20),
                    const SizedBox(width: AppSizes.gapS),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _processVerification(context, ref, badgeType);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                        padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM, vertical: AppSizes.paddingXS),
                        minimumSize: const Size(50, 28),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radiusS),
                        ),
                      ),
                      child: Text(
                        '재인증',
                        style: AppTextStyles.labelLarge(context),
                      ),
                    ),
                  ],
                )
              // 다른 인증: 체크 아이콘만
              : Icon(AppIcons.success, color: context.features.success)
          : TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _processVerification(context, ref, badgeType);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: context.features.success,
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM, vertical: AppSizes.paddingXS),
                minimumSize: const Size(60, 28),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusS),
                ),
              ),
              child: Text(
                '인증하기',
                style: AppTextStyles.labelLarge(context),
              ),
            ),
    );
  }

  /// 인증 처리 (백엔드 연동)
  Future<void> _processVerification(BuildContext context, WidgetRef ref, BadgeType badgeType) async {
    final authState = ref.read(authStateProvider);
    final userId = authState.valueOrNull?.uid;
    
    if (userId == null) {
      MingrrSnackBar.warning(context, '로그인이 필요합니다');
      return;
    }

    final firestoreService = FirestoreService();

    try {
      switch (badgeType) {
        case BadgeType.identity:
          // 본인인증 - 실제로는 PASS 등 본인인증 서비스 연동 필요
          _showIdentityVerificationDialog(context, ref, firestoreService, userId);
          break;
        case BadgeType.location:
          // 위치인증 - 현재 위치 기반 인증 (거리 검증 포함)
          await _showLocationVerificationDialog(context, ref, firestoreService, userId);
          break;
        case BadgeType.petRegistration:
          // 동물등록 인증 - 동물등록번호 입력
          await _showPetRegistrationDialog(context, ref, firestoreService, userId);
          break;
      }
    } catch (e) {
      if (context.mounted) {
        ErrorHandler.showError(context, e, tag: 'Profile', operation: '동물등록 인증');
      }
    }
  }

  /// 본인인증 다이얼로그
  void _showIdentityVerificationDialog(BuildContext context, WidgetRef ref, FirestoreService firestoreService, String userId) {
    showConfirmSheet(
      context,
      type: ConfirmSheetType.identityVerify,
      onConfirm: () async {
        await firestoreService.verifyIdentity(userId);
        
        // UI 갱신을 위해 Provider invalidate
        ref.invalidate(userVerificationsProvider);
        ref.invalidate(currentUserProvider);
        
        if (context.mounted) {
          MingrrSnackBar.success(context, '본인인증이 완료되었습니다! ');
        }
      },
    );
  }

  /// 위치인증 다이얼로그 (공통 헬퍼 사용)
  Future<void> _showLocationVerificationDialog(BuildContext context, WidgetRef ref, FirestoreService firestoreService, String userId) async {
    final result = await LocationVerificationHelper.showVerificationDialog(context, ref);
    
    if (result == true) {
      // UI 갱신을 위해 Provider invalidate
      ref.invalidate(userVerificationsProvider);
      ref.invalidate(currentUserProvider);
      
      if (context.mounted) {
        MingrrSnackBar.success(context, '위치인증이 완료되었습니다! 📍');
      }
    }
  }
  
  /// 동물등록 인증 다이얼로그 (API 연동 + PetModel 매칭)
  Future<void> _showPetRegistrationDialog(BuildContext context, WidgetRef ref, FirestoreService firestoreService, String userId) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PetRegistrationVerificationDialog(
        userId: userId,
        firestoreService: firestoreService,
      ),
    );

    if (result == true) {
      // UI 갱신을 위해 Provider invalidate
      ref.invalidate(userVerificationsProvider);
      ref.invalidate(currentUserProvider);
      ref.invalidate(userPetsProvider);
      
      if (context.mounted) {
        MingrrSnackBar.success(context, '동물등록 인증이 완료되었습니다! 🐕');
      }
    }
  }

  /// 설정 바텀시트
  void _showSettingsSheet(BuildContext context, WidgetRef ref) {
    showMingrrOptionsSheet(
      context: context,
      options: [
        MingrrOptionItem(
          icon: AppIcons.editOutlined,
          label: '프로필 수정',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProfileEditScreen()),
          ),
        ),
        MingrrOptionItem(
          icon: AppIcons.notification,
          label: '알림 설정',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NotificationSettingsScreen()),
          ),
        ),
        MingrrOptionItem(
          icon: AppIcons.settingsOutlined,
          label: '앱 설정',
          subtitle: '다크모드, 캐시 삭제',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AppSettingsScreen()),
          ),
        ),
        MingrrOptionItem(
          icon: AppIcons.profileOutlined,
          label: '계정 관리',
          subtitle: '연동 계정, 비밀번호, 회원 탈퇴',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AccountSettingsScreen()),
          ),
        ),
        MingrrOptionItem(
          icon: AppIcons.headset,
          label: '고객센터',
          subtitle: '문의, FAQ, 공지사항',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CustomerServiceScreen()),
          ),
        ),
        MingrrOptionItem(
          icon: AppIcons.info,
          label: '앱 정보',
          subtitle: '버전, 이용약관, 라이선스',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AppInfoScreen()),
          ),
        ),
        MingrrOptionItem(
          icon: AppIcons.share,
          label: '앱 공유하기',
          subtitle: '친구에게 밍그르르 추천하기',
          onTap: () => ShareService.shareApp(context),
        ),
        MingrrOptionItem(
          icon: AppIcons.logout,
          label: '로그아웃',
          isDestructive: true,
          onTap: () => showConfirmSheet(
            context,
            type: ConfirmSheetType.accountLogout,
            onConfirm: () async {
              await ref.read(authNotifierProvider.notifier).signOut();
            },
          ),
        ),
      ],
    );
  }

  /// 꼬순내지수 디자인 (공통 위젯 사용)
  Widget _buildKkosunnaeScore(BuildContext context, WidgetRef ref, double score) {
    return KkosunnaeScoreMedium(
      score: score,
      onTap: () async {
        await showKkosunnaeDetailSheet(context);
        ref.invalidate(currentUserProvider);
      },
    );
  }
  
  /// 프로필 이미지 위젯
  Widget _buildProfileImage(BuildContext context, String? imageUrl) {
    // 대표 아이콘인 경우
    if (imageUrl != null && imageUrl.startsWith('default_avatar:')) {
      final avatarId = imageUrl.replaceFirst('default_avatar:', '');
      final avatar = personDefaultAvatars.firstWhere(
        (a) => a.id == avatarId,
        orElse: () => personDefaultAvatars.first,
      );
      return Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: avatar.backgroundColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
        ),
        child: Icon(
          avatar.icon,
          size: 50,
          color: avatar.iconColor,
        ),
      );
    }
    
    // 실제 이미지 URL인 경우
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return MingrrImage.avatar(
        imageUrl: imageUrl,
        size: 100,
        borderColor: Colors.white,
        borderWidth: 3,
        icon: AppIcons.profile,
      );
    }
    
    // 기본 이미지
    return _buildDefaultProfileImage(context);
  }
  
  Widget _buildDefaultProfileImage(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: AppOpacity.o15),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: Icon(
        AppIcons.profile,
        size: 50,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
  
  /// 프로필 이미지 피커 표시
  Future<void> _showProfileImagePicker(BuildContext context, WidgetRef ref) async {
    final currentUser = ref.read(currentUserProvider).valueOrNull;
    final authUser = ref.read(authStateProvider).valueOrNull;
    
    if (authUser == null) return;
    
    final result = await showImagePickerSheet(
      context,
      title: '프로필 이미지 선택',
      avatarType: DefaultAvatarType.person,
      currentImageUrl: currentUser?.profileImageUrl,
    );
    
    if (result != null) {
      try {
        String? uploadedImageUrl;
        
        if (result.cleared) {
          uploadedImageUrl = null;
        } else if (result.hasDefaultAvatar) {
          uploadedImageUrl = 'default_avatar:${result.defaultAvatar!.id}';
        } else if (result.hasImage) {
          // 이미지 업로드
          final storageService = StorageService();
          if (kIsWeb) {
            final bytes = await result.imageFile!.readAsBytes();
            uploadedImageUrl = await storageService.uploadUserProfileImageBytes(authUser.uid, bytes);
          } else {
            final file = File(result.imageFile!.path);
            uploadedImageUrl = await storageService.uploadUserProfileImage(authUser.uid, file);
          }
        }
        
        // 데이터베이스 업데이트
        await FirebaseFirestore.instance
            .collection('users')
            .doc(authUser.uid)
            .update({
              'profileImageUrl': uploadedImageUrl,
              'updatedAt': FieldValue.serverTimestamp(),
            });
        
        // 상태 관리 새로고침
        ref.invalidate(currentUserProvider);
        
        if (context.mounted) {
          MingrrSnackBar.success(context, '프로필 이미지가 변경되었습니다!');
        }
      } catch (e) {
        if (context.mounted) {
          ErrorHandler.showError(context, e, tag: 'Profile', operation: '이미지 변경');
        }
      }
    }
  }
  
  /// 닉네임 수정 다이얼로그
  void _showNicknameEditDialog(BuildContext context, WidgetRef ref, dynamic user) async {
    if (user == null) return;
    
    final newNickname = await showInputDialog(
      context,
      title: '닉네임 변경',
      hintText: '새 닉네임을 입력해주세요',
      initialValue: user.nickname,
      maxLength: NicknameService.maxLength,
      confirmText: '변경',
      validator: (value) {
        return NicknameService.validate(value);
      },
    );
    
    if (newNickname == null || newNickname.trim() == user.nickname) return;
    
    try {
      // 닉네임 중복 체크 (NicknameService 사용)
      final isAvailable = await NicknameService.isAvailable(
        newNickname.trim(),
        excludeUserId: user.id,
      );
      
      if (!isAvailable) {
        if (context.mounted) {
          MingrrSnackBar.warning(context, '이미 사용 중인 닉네임입니다');
        }
        return;
      }
      
      // 닉네임 변경 (트랜잭션 처리)
      await NicknameService.change(
        userId: user.id,
        oldNickname: user.nickname ?? '',
        newNickname: newNickname.trim(),
      );
      
      // UI 갱신을 위해 Provider invalidate
      ref.invalidate(currentUserProvider);
      
      if (context.mounted) {
        MingrrSnackBar.success(context, '닉네임이 변경되었습니다!');
      }
    } catch (e) {
      if (context.mounted) {
        ErrorHandler.showError(context, e, tag: 'Profile', operation: '닉네임 변경');
      }
    }
  }
}

