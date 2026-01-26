import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/feature_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/pet_constants.dart';
import '../../../../core/constants/location_constants.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/animal_registration_service.dart';
import '../../../../core/services/share_service.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/mingrr_image.dart';
import '../../../../core/widgets/dialogs/dialogs.dart';
import '../../../../core/widgets/loading/loading_widgets.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/widgets/sheets/image_picker_sheet.dart';
import '../../../../core/widgets/sheets/mingrr_bottom_sheet.dart';
import '../../../../core/widgets/badges/verification_badge.dart';
import '../../../../core/widgets/kkosunnae_widgets.dart';
import '../../../../core/widgets/location_bubble_widget.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/providers/location_verification_provider.dart';
import '../../../../core/services/geocoding_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../pet/presentation/providers/pet_provider.dart';
import '../../../../models/pet_model.dart';
import 'my_activity_screen.dart';
import 'liked_list_screen.dart';
import 'pet_edit_screen.dart';
import 'profile_edit_screen.dart';
import 'settings/notification_settings_screen.dart';
import '../providers/profile_provider.dart';
import 'settings/app_settings_screen.dart';
import 'settings/account_settings_screen.dart';
import 'settings/customer_service_screen.dart';
import 'settings/app_info_screen.dart';

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
      error: (_, __) => {
        BadgeType.identity: false,
        BadgeType.location: false,
        BadgeType.petRegistration: false,
      },
    );

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
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
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
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
              // 개발자 도구 버튼 (admin 전용)
              if (currentUser.valueOrNull?.email == 'admin@mingrr.com')
                IconButton(
                  icon: const Icon(Icons.developer_mode, color: Colors.orange),
                  onPressed: () => context.push('/dev-tools'),
                  tooltip: '개발자 도구',
                ),
              // 설정 버튼 (우상단 톱니바퀴)
              IconButton(
                icon: const Icon(Icons.settings_outlined),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
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
                      error: (_, __) => _buildProfileImage(context, null),
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
                          Icons.camera_alt,
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
                    const SizedBox(width: AppSizes.gapSM),
                    GestureDetector(
                      onTap: () => _showNicknameEditDialog(context, ref, user),
                      child: Container(
                        padding: const EdgeInsets.all(AppSizes.paddingXS),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                loading: () => const Text('로딩 중...'),
                error: (_, __) => const Text('사용자'),
              ),
              const SizedBox(height: AppSizes.gapSM),
              
              // 꼬순내지수 (개선된 디자인)
              currentUser.when(
                data: (user) => _buildKkosunnaeScore(context, user?.kkosunnaeScore ?? 50.0),
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
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
    final mismatchResult = mismatchAsync.valueOrNull;
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
      MingrrSnackBar.error(context, '로그인이 필요합니다');
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
                        Icons.add,
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
      error: (_, __) => const SizedBox(),
    );
  }

  /// 반려동물 카드 (V2: 건강수첩 버튼 포함)
  Widget _buildPetCard(BuildContext context, pet) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: AppSizes.gapM),
      child: MingrrCard(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(AppSizes.paddingS),
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
            MingrrPetAvatar(
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
                    Icon(Icons.medical_services, size: 16, color: context.features.health),
                    const SizedBox(width: AppSizes.gapSM),
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

  /// 반려동물 대표사진 URL 가져오기
  String? _getPetPrimaryPhotoUrl(PetModel pet) {
    return pet.displayImageUrl;
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
      error: (_, __) => _buildActivityStatsCard(
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
        'icon': Icons.history,
        'label': '내 활동',
        'badge': null,
        'screen': const MyActivityScreen(),
      },
      {
        'icon': Icons.favorite_border,
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
                    Icon(Icons.check_circle, color: context.features.success, size: 20),
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
                          borderRadius: BorderRadius.circular(AppSizes.radiusXS),
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
              : Icon(Icons.check_circle, color: context.features.success)
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
                  borderRadius: BorderRadius.circular(AppSizes.radiusXS),
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
      MingrrSnackBar.error(context, '로그인이 필요합니다');
      return;
    }

    final firestoreService = FirestoreService();

    try {
      switch (badgeType) {
        case BadgeType.identity:
          // 본인인증 - 실제로는 PASS 등 본인인증 서비스 연동 필요
          _showIdentityVerificationDialog(context, firestoreService, userId);
          break;
        case BadgeType.location:
          // 위치인증 - 현재 위치 기반 인증 (거리 검증 포함)
          await _showLocationVerificationDialog(context, ref, firestoreService, userId);
          break;
        case BadgeType.petRegistration:
          // 동물등록 인증 - 동물등록번호 입력
          await _showPetRegistrationDialog(context, firestoreService, userId);
          break;
      }
    } catch (e) {
      if (context.mounted) {
        MingrrSnackBar.error(context, '인증 처리 중 오류가 발생했습니다: $e');
      }
    }
  }

  /// 본인인증 다이얼로그
  void _showIdentityVerificationDialog(BuildContext context, FirestoreService firestoreService, String userId) {
    showConfirmSheet(
      context,
      type: ConfirmSheetType.identityVerify,
      onConfirm: () async {
        await firestoreService.verifyIdentity(userId);
        if (context.mounted) {
          MingrrSnackBar.success(context, '본인인증이 완료되었습니다! ');
        }
      },
    );
  }

  /// 위치 획득 헬퍼 함수 (타임아웃 포함)
  Future<Position?> _getPositionWithTimeout() async {
    try {
      // 마지막 알려진 위치 먼저 시도 (즉시 반환)
      final lastPosition = await Geolocator.getLastKnownPosition();
      if (lastPosition != null) {
        AppLogger.debug('ProfileScreen', '마지막 위치 사용: ${lastPosition.latitude}, ${lastPosition.longitude}');
        return lastPosition;
      }
    } catch (e) {
      AppLogger.warning('ProfileScreen', '마지막 위치 획득 실패: $e');
    }
    
    // 현재 위치 획득 시도
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
    );
  }

  /// 위치인증 다이얼로그 (GPS 기반 + 거리 검증)
  /// 로딩과 결과를 하나의 다이얼로그에서 처리하여 깜빡임 방지
  Future<void> _showLocationVerificationDialog(BuildContext context, WidgetRef ref, FirestoreService firestoreService, String userId) async {
    // 통합 다이얼로그 표시 (로딩 → 결과 전환)
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _LocationVerificationDialog(
        userId: userId,
        ref: ref,
      ),
    );
    
    if (result == true && context.mounted) {
      MingrrSnackBar.success(context, '위치인증이 완료되었습니다! 📍');
    }
  }
  
  /// 위치 서비스 비활성화 다이얼로그
  void _showLocationServiceDisabledDialog(BuildContext context) async {
    final goToSettings = await showAppDialog(
      context,
      type: DialogType.warning,
      title: '위치 서비스 꺼짐',
      message: '위치 인증을 위해 기기의 위치 서비스를 켜주세요.\n\n설정 > 위치에서 활성화할 수 있습니다.',
      showCancel: true,
      cancelText: '취소',
      confirmText: '설정으로 이동',
      icon: Icons.location_off,
    );
    if (goToSettings == true) {
      Geolocator.openLocationSettings();
    }
  }
  
  /// 위치 권한 영구 거부 다이얼로그
  void _showPermissionDeniedForeverDialog(BuildContext context) async {
    final goToSettings = await showAppDialog(
      context,
      type: DialogType.warning,
      title: '위치 권한 필요',
      message: '위치 인증을 위해 위치 권한이 필요합니다.\n\n앱 설정에서 위치 권한을 허용해주세요.',
      showCancel: true,
      cancelText: '취소',
      confirmText: '설정으로 이동',
      icon: Icons.location_disabled,
    );
    if (goToSettings == true) {
      Geolocator.openAppSettings();
    }
  }
  
  /// 위치 확인 타임아웃 다이얼로그
  void _showLocationTimeoutDialog(BuildContext context) {
    showAppDialog(
      context,
      type: DialogType.error,
      title: '위치 확인 실패',
      message: 'GPS 신호를 찾을 수 없습니다.\n\n실외로 이동 후 다시 시도해주세요.',
      icon: Icons.timer_off,
    );
  }
  
  /// 첫 위치 인증 다이얼로그
  Future<bool?> _showFirstTimeVerificationDialog(BuildContext context, String addressText) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return showInfoActionDialog(
      context,
      icon: Icons.location_on,
      iconColor: colorScheme.primary,
      title: '위치 인증',
      message: '현재 위치를 내 동네로 등록하시겠습니까?',
      infoBoxes: [
        InfoBoxItem(
          icon: Icons.my_location,
          content: addressText,
        ),
      ],
      confirmText: '인증하기',
    );
  }
  
  /// 재인증 다이얼로그 (500m 이내)
  Future<bool?> _showReVerificationDialog(BuildContext context, String addressText, double distance) {
    final color = context.features.success;
    
    return showInfoActionDialog(
      context,
      icon: Icons.check_circle,
      iconColor: color,
      title: '위치 인증 갱신',
      message: '현재 위치에서 인증을 갱신하시겠습니까?',
      infoBoxes: [
        InfoBoxItem(
          icon: Icons.my_location,
          content: addressText,
          subtitle: '저장된 위치에서 ${distance.round()}m',
          color: color,
        ),
      ],
      confirmText: '인증 갱신',
    );
  }
  
  /// 조금 더 가까이 다이얼로그 (500m~1km)
  Future<void> _showTooFarDialog(BuildContext context, double distance) {
    return showAppDialog(
      context,
      type: DialogType.info,
      title: '조금 더 가까이',
      message: '설정한 동네에서 ${distance.round()}m 떨어져 있어요.\n\n저장된 동네 근처(500m 이내)에서 인증할 수 있습니다.',
      icon: Icons.near_me,
    );
  }
  
  /// 동네 변경 제안 다이얼로그 (1km 이상)
  Future<bool?> _showLocationChangeDialog(BuildContext context, String newAddress, double distance, String? savedAddress) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return showInfoActionDialog(
      context,
      icon: Icons.swap_horiz,
      iconColor: colorScheme.primary,
      title: '동네 변경',
      message: '현재 위치가 저장된 동네와\n${LocationService.formatDistance(distance)} 떨어져 있어요.',
      infoBoxes: [
        if (savedAddress != null)
          InfoBoxItem(
            icon: Icons.location_on_outlined,
            label: '저장된 동네',
            content: savedAddress,
            isPrimary: false,
          ),
        InfoBoxItem(
          icon: Icons.my_location,
          label: '현재 위치',
          content: newAddress,
        ),
      ],
      confirmText: '동네 변경',
    );
  }

  /// 동물등록 인증 다이얼로그 (API 연동 + PetModel 매칭)
  Future<void> _showPetRegistrationDialog(BuildContext context, FirestoreService firestoreService, String userId) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _PetRegistrationVerificationDialog(
        userId: userId,
        firestoreService: firestoreService,
      ),
    );

    if (result == true && context.mounted) {
      MingrrSnackBar.success(context, '동물등록 인증이 완료되었습니다! 🐕');
    }
  }

  /// 설정 바텀시트
  void _showSettingsSheet(BuildContext context, WidgetRef ref) {
    showMingrrOptionsSheet(
      context: context,
      options: [
        MingrrOptionItem(
          icon: Icons.edit_outlined,
          label: '프로필 수정',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProfileEditScreen()),
          ),
        ),
        MingrrOptionItem(
          icon: Icons.notifications_outlined,
          label: '알림 설정',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NotificationSettingsScreen()),
          ),
        ),
        MingrrOptionItem(
          icon: Icons.settings_outlined,
          label: '앱 설정',
          subtitle: '다크모드, 캐시 삭제',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AppSettingsScreen()),
          ),
        ),
        MingrrOptionItem(
          icon: Icons.person_outline,
          label: '계정 관리',
          subtitle: '연동 계정, 비밀번호, 회원 탈퇴',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AccountSettingsScreen()),
          ),
        ),
        MingrrOptionItem(
          icon: Icons.headset_mic_outlined,
          label: '고객센터',
          subtitle: '문의, FAQ, 공지사항',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CustomerServiceScreen()),
          ),
        ),
        MingrrOptionItem(
          icon: Icons.info_outline,
          label: '앱 정보',
          subtitle: '버전, 이용약관, 라이선스',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AppInfoScreen()),
          ),
        ),
        MingrrOptionItem(
          icon: Icons.share_outlined,
          label: '앱 공유하기',
          subtitle: '친구에게 밍그르르 추천하기',
          onTap: () => ShareService.shareApp(context),
        ),
        MingrrOptionItem(
          icon: Icons.logout,
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

  String _calculateAge(DateTime? birthDate) {
    if (birthDate == null) return '나이 미상';
    
    final now = DateTime.now();
    final age = now.year - birthDate.year;
    final months = now.month - birthDate.month;
    
    if (age == 0) {
      return '${months}개월';
    } else if (months < 0) {
      return '${age - 1}살';
    }
    return '${age}살';
  }
  
  /// 꼬순내지수 디자인 (공통 위젯 사용)
  Widget _buildKkosunnaeScore(BuildContext context, double score) {
    return KkosunnaeScoreMedium(
      score: score,
      onTap: () => showKkosunnaeDetailSheet(context),
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
      return MingrrAvatar(
        imageUrl: imageUrl,
        size: 100,
        borderColor: Colors.white,
        borderWidth: 3,
        placeholderIcon: Icons.person,
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
        Icons.person,
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
          MingrrSnackBar.error(context, '이미지 변경 실패: $e');
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
      maxLength: 10,
      confirmText: '변경',
      validator: (value) {
        if (value.trim().isEmpty) return '닉네임을 입력해주세요';
        if (value.trim().length < 2) return '2자 이상 입력해주세요';
        return null;
      },
    );
    
    if (newNickname == null || newNickname.trim() == user.nickname) return;
    
    try {
      // 닉네임 중복 체크
      final firestoreService = FirestoreService();
      final isAvailable = await firestoreService.isNicknameAvailable(
        newNickname.trim(),
        excludeUserId: user.id,
      );
      
      if (!isAvailable) {
        if (context.mounted) {
          MingrrSnackBar.error(context, '이미 사용 중인 닉네임입니다');
        }
        return;
      }
      
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('users').doc(user.id).update({
        'nickname': newNickname.trim(),
      });
      
      if (context.mounted) {
        MingrrSnackBar.success(context, '닉네임이 변경되었습니다!');
      }
    } catch (e) {
      if (context.mounted) {
        MingrrSnackBar.error(context, '닉네임 변경 실패: $e');
      }
    }
  }
}

/// ============================================================
/// 위치 인증 통합 다이얼로그
/// 
/// 로딩 → 결과 화면을 하나의 다이얼로그에서 처리하여 깜빡임 방지
/// ============================================================
class _LocationVerificationDialog extends StatefulWidget {
  final String userId;
  final WidgetRef ref;

  const _LocationVerificationDialog({
    required this.userId,
    required this.ref,
  });

  @override
  State<_LocationVerificationDialog> createState() => _LocationVerificationDialogState();
}

class _LocationVerificationDialogState extends State<_LocationVerificationDialog> {
  // 상태
  bool _isLoading = true;
  String _statusMessage = 'GPS 신호를 찾고 있습니다...';
  String? _errorMessage;
  
  // 결과 데이터
  Position? _position;
  String? _addressText;
  GeoPoint? _savedLocation;
  double? _distance;
  bool _isFirstTime = true;
  
  @override
  void initState() {
    super.initState();
    _startLocationVerification();
  }
  
  Future<void> _startLocationVerification() async {
    try {
      // 1. 위치 서비스 확인
      setState(() => _statusMessage = '위치 서비스 확인 중...');
      final serviceEnabled = await Geolocator.isLocationServiceEnabled()
          .timeout(const Duration(seconds: 2), onTimeout: () => false);
      if (!serviceEnabled) {
        setState(() {
          _isLoading = false;
          _errorMessage = '위치 서비스가 꺼져 있습니다.\n설정에서 위치 서비스를 켜주세요.';
        });
        return;
      }
      
      // 2. 위치 권한 확인
      setState(() => _statusMessage = '위치 권한 확인 중...');
      LocationPermission permission = await Geolocator.checkPermission()
          .timeout(const Duration(seconds: 2), onTimeout: () => LocationPermission.denied);
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission()
            .timeout(const Duration(seconds: 10), onTimeout: () => LocationPermission.denied);
      }
      
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoading = false;
          _errorMessage = '위치 권한이 필요합니다.\n앱 설정에서 위치 권한을 허용해주세요.';
        });
        return;
      }
      
      // 3. 위치 획득
      setState(() => _statusMessage = '현재 위치 확인 중...');
      Position? position;
      try {
        // 마지막 위치 먼저 시도
        final lastPosition = await Geolocator.getLastKnownPosition();
        if (lastPosition != null) {
          position = lastPosition;
        } else {
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
          ).timeout(const Duration(seconds: 8));
        }
      } catch (e) {
        AppLogger.warning('ProfileScreen', '위치 획득 실패: $e');
        setState(() {
          _isLoading = false;
          _errorMessage = 'GPS 신호를 찾을 수 없습니다.\n실외로 이동 후 다시 시도해주세요.';
        });
        return;
      }
      
      if (position == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = '위치를 확인할 수 없습니다.';
        });
        return;
      }
      
      _position = position;
      
      // 4. 주소 변환
      setState(() => _statusMessage = '주소 변환 중...');
      String addressText = '위도: ${position.latitude.toStringAsFixed(4)}, 경도: ${position.longitude.toStringAsFixed(4)}';
      try {
        final addressResult = await GeocodingService.reverseGeocode(
          position.latitude,
          position.longitude,
        ).timeout(const Duration(seconds: 3));
        if (addressResult != null) {
          addressText = addressResult.shortAddress;
        }
      } catch (_) {}
      _addressText = addressText;
      
      // 5. 사용자 정보 확인
      final userAsync = widget.ref.read(currentUserStreamProvider);
      final user = userAsync.valueOrNull;
      _savedLocation = user?.homeLocation;
      _isFirstTime = _savedLocation == null;
      
      if (!_isFirstTime && _savedLocation != null) {
        final geoPoint = GeoPoint(position.latitude, position.longitude);
        _distance = LocationService.calculateDistanceFromGeoPoints(_savedLocation!, geoPoint);
      }
      
      // 로딩 완료
      setState(() => _isLoading = false);
      
    } catch (e) {
      AppLogger.error('ProfileScreen', '위치 인증 오류', e);
      setState(() {
        _isLoading = false;
        _errorMessage = '위치 확인 중 오류가 발생했습니다.';
      });
    }
  }
  
  Future<void> _doVerification() async {
    if (_position == null || _addressText == null) return;
    
    setState(() {
      _isLoading = true;
      _statusMessage = '인증 처리 중...';
    });
    
    try {
      if (_isFirstTime) {
        // 첫 인증
        await LocationVerificationService.verifyLocation(
          userId: widget.userId,
          currentPosition: _position!,
          address: _addressText!,
          isFirstTime: true,
        );
      } else if (_distance != null && _distance! <= LocationConstants.verificationRadiusMeters) {
        // 재인증 (500m 이내)
        await LocationVerificationService.verifyLocation(
          userId: widget.userId,
          currentPosition: _position!,
          address: _addressText!,
        );
      } else {
        // 동네 변경
        await LocationVerificationService.updateLocation(
          userId: widget.userId,
          currentPosition: _position!,
          address: _addressText!,
        );
      }
      
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      AppLogger.error('ProfileScreen', '인증 처리 오류', e);
      setState(() {
        _isLoading = false;
        _errorMessage = '인증 처리 중 오류가 발생했습니다.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = colorScheme.primary;
    
    return Dialog(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusL)),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingXXL),
        child: _isLoading 
            ? _buildLoadingContent(colorScheme, color)
            : _errorMessage != null
                ? _buildErrorContent(colorScheme)
                : _buildResultContent(colorScheme, color),
      ),
    );
  }
  
  Widget _buildLoadingContent(ColorScheme colorScheme, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color.withValues(alpha: AppOpacity.o10),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: MingrrLoadingIndicator(strokeWidth: 3, customColor: color),
            ),
          ),
        ),
        const SizedBox(height: AppSizes.gapLL),
        Text(
          '현재 위치 확인 중',
          style: AppTextStyles.headlineSmall(context),
        ),
        const SizedBox(height: AppSizes.gapS),
        Text(
          _statusMessage,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall(context),
        ),
      ],
    );
  }
  
  Widget _buildErrorContent(ColorScheme colorScheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: AppOpacity.o10),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.location_off, size: 28, color: Colors.red),
        ),
        const SizedBox(height: AppSizes.gapLL),
        Text(
          '위치 확인 실패',
          style: AppTextStyles.headlineSmall(context),
        ),
        const SizedBox(height: AppSizes.gapS),
        Text(
          _errorMessage!,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium(context).copyWith(color: colorScheme.onSurfaceVariant, height: 1.5),
        ),
        const SizedBox(height: AppSizes.gapLL),
        MingrrButton(
          text: '확인',
          onPressed: () => Navigator.pop(context, false),
          backgroundColor: colorScheme.primary,
          textColor: Colors.white,
          height: 48,
        ),
      ],
    );
  }
  
  Widget _buildResultContent(ColorScheme colorScheme, Color color) {
    // 거리에 따른 상태 결정
    final bool canVerify = _isFirstTime || 
        (_distance != null && _distance! <= LocationConstants.verificationRadiusMeters);
    final bool isTooFar = !_isFirstTime && 
        _distance != null && 
        _distance! > LocationConstants.verificationRadiusMeters &&
        _distance! <= LocationConstants.verificationNearbyMeters;
    final bool needsLocationChange = !_isFirstTime && 
        _distance != null && 
        _distance! > LocationConstants.verificationNearbyMeters;
    
    // 색상 결정
    final themeColor = canVerify 
        ? (_isFirstTime ? color : context.features.success)
        : (needsLocationChange ? color : Colors.orange);
    
    // 제목 결정
    String title;
    String message;
    String buttonText;
    IconData icon;
    
    if (canVerify) {
      if (_isFirstTime) {
        title = '위치 인증';
        message = '현재 위치를 내 동네로 등록하시겠습니까?';
        buttonText = '인증하기';
        icon = Icons.location_on;
      } else {
        title = '위치 인증 갱신';
        message = '현재 위치에서 인증을 갱신하시겠습니까?';
        buttonText = '인증 갱신';
        icon = Icons.check_circle;
      }
    } else if (isTooFar) {
      title = '조금 더 가까이';
      message = '설정한 동네에서 ${_distance!.round()}m 떨어져 있어요.\n저장된 동네 근처(500m 이내)에서 인증할 수 있습니다.';
      buttonText = '확인';
      icon = Icons.near_me;
    } else {
      title = '동네 변경';
      message = '현재 위치가 저장된 동네와\n${LocationService.formatDistance(_distance!)} 떨어져 있어요.';
      buttonText = '동네 변경';
      icon = Icons.swap_horiz;
    }
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 아이콘
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: themeColor.withValues(alpha: AppOpacity.o10),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 28, color: themeColor),
        ),
        const SizedBox(height: AppSizes.gapL),
        
        // 제목
        Text(
          title,
          style: AppTextStyles.headlineSmall(context),
        ),
        const SizedBox(height: AppSizes.gapS),
        
        // 메시지
        Text(
          message,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall(context).copyWith(height: 1.4),
        ),
        const SizedBox(height: AppSizes.gapL),
        
        // 주소 표시
        if (_addressText != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSizes.paddingM),
            decoration: BoxDecoration(
              color: themeColor.withValues(alpha: AppOpacity.o10),
              borderRadius: BorderRadius.circular(AppSizes.radiusS),
            ),
            child: Row(
              children: [
                Icon(Icons.my_location, color: themeColor, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _addressText!,
                        style: AppTextStyles.labelLarge(context),
                      ),
                      if (!_isFirstTime && _distance != null) ...[
                        const SizedBox(height: AppSizes.gapXXS),
                        Text(
                          '저장된 위치에서 ${_distance!.round()}m',
                          style: AppTextStyles.caption(context).copyWith(color: themeColor),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: AppSizes.gapLL),
        
        // 버튼
        if (isTooFar)
          // 조금 더 가까이: 확인 버튼만
          MingrrButton(
            text: buttonText,
            onPressed: () => Navigator.pop(context, false),
            backgroundColor: themeColor,
            textColor: Colors.white,
            height: 48,
          )
        else
          // 인증/동네변경: 취소/확인 버튼
          MingrrDialogButtons(
            cancelText: '취소',
            confirmText: buttonText,
            onCancel: () => Navigator.pop(context, false),
            onConfirm: _doVerification,
            confirmColor: themeColor,
          ),
      ],
    );
  }
}

/// ============================================================
/// 동물등록 인증 통합 다이얼로그
/// 
/// 입력 → 로딩 → 결과(성공/실패) → PetModel 매칭
/// ============================================================
class _PetRegistrationVerificationDialog extends StatefulWidget {
  final String userId;
  final FirestoreService firestoreService;

  const _PetRegistrationVerificationDialog({
    required this.userId,
    required this.firestoreService,
  });

  @override
  State<_PetRegistrationVerificationDialog> createState() => _PetRegistrationVerificationDialogState();
}

enum _VerificationStep { input, loading, success, error, petSelection }

class _PetRegistrationVerificationDialogState extends State<_PetRegistrationVerificationDialog> {
  // 상태
  _VerificationStep _step = _VerificationStep.input;
  String _statusMessage = '';
  String? _errorMessage;
  
  // 입력 컨트롤러
  final _registrationController = TextEditingController();
  final _ownerNameController = TextEditingController();
  
  // 결과 데이터
  AnimalInfo? _animalInfo;
  List<PetModel> _userPets = [];
  PetModel? _selectedPet;
  
  @override
  void dispose() {
    _registrationController.dispose();
    _ownerNameController.dispose();
    super.dispose();
  }
  
  /// 인증 시작
  Future<void> _startVerification() async {
    final regNo = _registrationController.text.trim();
    final ownerName = _ownerNameController.text.trim();
    
    // 입력 검증
    if (regNo.isEmpty) {
      setState(() => _errorMessage = '동물등록번호를 입력해주세요.');
      return;
    }
    if (ownerName.isEmpty) {
      setState(() => _errorMessage = '소유자 성명을 입력해주세요.');
      return;
    }
    
    setState(() {
      _step = _VerificationStep.loading;
      _statusMessage = '동물등록 정보 확인 중...';
      _errorMessage = null;
    });
    
    try {
      // API 호출
      final result = await AnimalRegistrationService.verify(
        registrationNumber: regNo,
        ownerName: ownerName,
      );
      
      if (!mounted) return;
      
      if (result.isSuccess && result.animalInfo != null) {
        _animalInfo = result.animalInfo;
        
        // 사용자의 반려동물 목록 조회
        setState(() => _statusMessage = '반려동물 정보 확인 중...');
        _userPets = await widget.firestoreService.getUserPets(widget.userId);
        
        // 이미 등록된 동물등록번호인지 확인
        final existingPet = await widget.firestoreService.findPetByRegistrationNumber(
          widget.userId, 
          regNo,
        );
        
        if (existingPet != null) {
          // 이미 인증된 반려동물
          _selectedPet = existingPet;
          setState(() => _step = _VerificationStep.success);
        } else if (_userPets.isEmpty) {
          // 등록된 반려동물이 없음 → 바로 인증 완료
          setState(() => _step = _VerificationStep.success);
        } else {
          // 반려동물 선택 화면으로 이동
          setState(() => _step = _VerificationStep.petSelection);
        }
      } else {
        setState(() {
          _step = _VerificationStep.error;
          _errorMessage = result.errorMessage ?? '인증에 실패했습니다.';
        });
      }
    } catch (e) {
      AppLogger.error('ProfileScreen', '동물등록 인증 오류', e);
      setState(() {
        _step = _VerificationStep.error;
        _errorMessage = '인증 중 오류가 발생했습니다.';
      });
    }
  }
  
  /// 인증 완료 처리
  Future<void> _completeVerification() async {
    if (_animalInfo == null) return;
    
    setState(() {
      _step = _VerificationStep.loading;
      _statusMessage = '인증 정보 저장 중...';
    });
    
    try {
      final regNo = _animalInfo!.dogRegNo;
      final animalData = _animalInfo!.toMap();
      
      // 1. 사용자 인증 정보 저장
      await widget.firestoreService.verifyPetRegistration(
        widget.userId,
        regNo,
        animalData: animalData,
        matchedPetId: _selectedPet?.id,
      );
      
      // 2. 선택된 반려동물에 인증 정보 연결
      if (_selectedPet != null) {
        await widget.firestoreService.linkPetRegistration(
          _selectedPet!.id,
          regNo,
          animalData,
        );
      }
      
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      AppLogger.error('ProfileScreen', '인증 저장 오류', e);
      setState(() {
        _step = _VerificationStep.error;
        _errorMessage = '인증 정보 저장 중 오류가 발생했습니다.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;
    
    return Dialog(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusL)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingXXL),
          child: _buildContent(colorScheme, primaryColor),
        ),
      ),
    );
  }
  
  Widget _buildContent(ColorScheme colorScheme, Color primaryColor) {
    switch (_step) {
      case _VerificationStep.input:
        return _buildInputContent(colorScheme, primaryColor);
      case _VerificationStep.loading:
        return _buildLoadingContent(colorScheme, primaryColor);
      case _VerificationStep.success:
        return _buildSuccessContent(colorScheme, primaryColor);
      case _VerificationStep.error:
        return _buildErrorContent(colorScheme);
      case _VerificationStep.petSelection:
        return _buildPetSelectionContent(colorScheme, primaryColor);
    }
  }
  
  /// 입력 화면
  Widget _buildInputContent(ColorScheme colorScheme, Color primaryColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 아이콘
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: AppOpacity.o10),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.pets, size: 28, color: primaryColor),
        ),
        const SizedBox(height: AppSizes.gapL),
        
        // 제목
        Text(
          '동물등록 인증',
          style: AppTextStyles.headlineSmall(context),
        ),
        const SizedBox(height: AppSizes.gapS),
        Text(
          '동물등록번호와 소유자 성명을 입력해주세요.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall(context),
        ),
        const SizedBox(height: AppSizes.gapLL),
        
        // 동물등록번호 입력
        TextField(
          controller: _registrationController,
          decoration: InputDecoration(
            labelText: '동물등록번호',
            hintText: '15자리 숫자',
            prefixIcon: const Icon(Icons.tag),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.radiusS)),
            counterText: '',
          ),
          keyboardType: TextInputType.number,
          maxLength: 15,
        ),
        const SizedBox(height: AppSizes.gapM),
        
        // 소유자 성명 입력
        TextField(
          controller: _ownerNameController,
          decoration: InputDecoration(
            labelText: '소유자 성명',
            hintText: '실명을 입력해주세요',
            prefixIcon: const Icon(Icons.person_outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.radiusS)),
          ),
          keyboardType: TextInputType.name,
        ),
        
        // 에러 메시지
        if (_errorMessage != null) ...[
          const SizedBox(height: AppSizes.gapM),
          Text(
            _errorMessage!,
            style: AppTextStyles.bodyMedium(context),
          ),
        ],
        
        const SizedBox(height: AppSizes.gapS),
        Text(
          '※ 동물등록번호는 동물보호관리시스템(animal.go.kr)에서 확인할 수 있습니다.',
          style: AppTextStyles.caption(context),
        ),
        const SizedBox(height: AppSizes.gapLL),
        
        // 버튼
        MingrrDialogButtons(
          cancelText: '취소',
          confirmText: '인증하기',
          onCancel: () => Navigator.pop(context, false),
          onConfirm: _startVerification,
          confirmColor: primaryColor,
        ),
      ],
    );
  }
  
  /// 로딩 화면
  Widget _buildLoadingContent(ColorScheme colorScheme, Color primaryColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: AppOpacity.o10),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: MingrrLoadingIndicator(strokeWidth: 3, customColor: primaryColor),
            ),
          ),
        ),
        const SizedBox(height: AppSizes.gapLL),
        Text(
          '동물등록 인증 중',
          style: AppTextStyles.headlineSmall(context),
        ),
        const SizedBox(height: AppSizes.gapS),
        Text(
          _statusMessage,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall(context),
        ),
      ],
    );
  }
  
  /// 성공 화면
  Widget _buildSuccessContent(ColorScheme colorScheme, Color primaryColor) {
    final successColor = context.features.success;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 아이콘
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: successColor.withValues(alpha: AppOpacity.o10),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.check_circle, size: 28, color: successColor),
        ),
        const SizedBox(height: AppSizes.gapL),
        
        // 제목
        Text(
          '인증 완료',
          style: AppTextStyles.headlineSmall(context),
        ),
        const SizedBox(height: AppSizes.gapL),
        
        // 동물 정보 카드
        if (_animalInfo != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSizes.paddingL),
            decoration: BoxDecoration(
              color: successColor.withValues(alpha: AppOpacity.o10),
              borderRadius: BorderRadius.circular(AppSizes.radiusS),
            ),
            child: Column(
              children: [
                // 이름
                Row(
                  children: [
                    Icon(Icons.pets, color: successColor, size: 20),
                    const SizedBox(width: AppSizes.gapS),
                    Text(
                      _animalInfo!.dogNm,
                      style: AppTextStyles.titleLarge(context),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.gapM),
                
                // 상세 정보
                _buildInfoRow('품종', _animalInfo!.kindNm ?? '정보 없음'),
                _buildInfoRow('성별', _animalInfo!.sexNm ?? '정보 없음'),
                _buildInfoRow('중성화', _animalInfo!.isNeutered ? 'O' : 'X'),
                _buildInfoRow('생년월일', _animalInfo!.birthDateFormatted),
                _buildInfoRow('등록번호', _animalInfo!.dogRegNo),
              ],
            ),
          ),
        
        // 매칭된 반려동물 정보
        if (_selectedPet != null) ...[
          const SizedBox(height: AppSizes.gapM),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSizes.paddingM),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: AppOpacity.o10),
              borderRadius: BorderRadius.circular(AppSizes.radiusS),
            ),
            child: Row(
              children: [
                Icon(Icons.link, color: primaryColor, size: 18),
                const SizedBox(width: AppSizes.gapS),
                Expanded(
                  child: Text(
                    '내 반려동물 "${_selectedPet!.name}"과 연결됨',
                    style: AppTextStyles.bodySmall(context).copyWith(color: primaryColor),
                  ),
                ),
              ],
            ),
          ),
        ],
        
        const SizedBox(height: AppSizes.gapLL),
        
        // 완료 버튼
        MingrrButton(
          text: '완료',
          onPressed: _completeVerification,
          backgroundColor: successColor,
          textColor: Colors.white,
          height: 48,
        ),
      ],
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingXXS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySmall(context)),
          Text(value, style: AppTextStyles.titleSmall(context)),
        ],
      ),
    );
  }
  
  /// 에러 화면
  Widget _buildErrorContent(ColorScheme colorScheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: AppOpacity.o10),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.error_outline, size: 28, color: Colors.red),
        ),
        const SizedBox(height: AppSizes.gapLL),
        Text(
          '인증 실패',
          style: AppTextStyles.headlineSmall(context),
        ),
        const SizedBox(height: AppSizes.gapS),
        Text(
          _errorMessage ?? '알 수 없는 오류가 발생했습니다.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall(context).copyWith(height: 1.5),
        ),
        const SizedBox(height: AppSizes.gapLL),
        MingrrDialogButtons(
          cancelText: '닫기',
          confirmText: '다시 시도',
          onCancel: () => Navigator.pop(context, false),
          onConfirm: () => setState(() {
            _step = _VerificationStep.input;
            _errorMessage = null;
          }),
          confirmColor: colorScheme.primary,
        ),
      ],
    );
  }
  
  /// 반려동물 선택 화면
  Widget _buildPetSelectionContent(ColorScheme colorScheme, Color primaryColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 아이콘
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: AppOpacity.o10),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.pets, size: 28, color: primaryColor),
        ),
        const SizedBox(height: AppSizes.gapL),
        
        // 제목
        Text(
          '반려동물 연결',
          style: AppTextStyles.headlineSmall(context),
        ),
        const SizedBox(height: AppSizes.gapS),
        Text(
          '인증된 동물 정보를 연결할 반려동물을 선택해주세요.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall(context),
        ),
        const SizedBox(height: AppSizes.gapL),
        
        // 인증된 동물 정보
        if (_animalInfo != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSizes.paddingM),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: AppOpacity.o10),
              borderRadius: BorderRadius.circular(AppSizes.radiusS),
            ),
            child: Row(
              children: [
                Icon(Icons.verified, color: primaryColor, size: 20),
                const SizedBox(width: AppSizes.gapS),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _animalInfo!.dogNm,
                        style: AppTextStyles.labelLarge(context).copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${_animalInfo!.kindNm ?? ''} · ${_animalInfo!.sexNm ?? ''}',
                        style: AppTextStyles.caption(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: AppSizes.gapL),
        
        // 반려동물 목록
        Container(
          constraints: const BoxConstraints(maxHeight: 200),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _userPets.length + 1, // +1 for "연결 안함" 옵션
            itemBuilder: (context, index) {
              if (index == _userPets.length) {
                // 연결 안함 옵션
                return _buildPetOption(
                  null,
                  '연결 안함',
                  '나중에 연결할게요',
                  colorScheme,
                );
              }
              
              final pet = _userPets[index];
              return _buildPetOption(
                pet,
                pet.name,
                '${pet.breed ?? '품종 미입력'} · ${pet.genderString}',
                colorScheme,
              );
            },
          ),
        ),
        const SizedBox(height: AppSizes.gapLL),
        
        // 버튼
        MingrrDialogButtons(
          cancelText: '취소',
          confirmText: '다음',
          onCancel: () => Navigator.pop(context, false),
          onConfirm: () {
            setState(() => _step = _VerificationStep.success);
          },
          confirmColor: primaryColor,
        ),
      ],
    );
  }
  
  Widget _buildPetOption(PetModel? pet, String title, String subtitle, ColorScheme colorScheme) {
    final isSelected = _selectedPet?.id == pet?.id;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedPet = pet),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSizes.paddingS),
        padding: const EdgeInsets.all(AppSizes.paddingM),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary.withValues(alpha: AppOpacity.o10) : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppSizes.radiusS),
          border: Border.all(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            // 프로필 이미지 또는 아이콘
            MingrrThumbnail(
              imageUrl: pet?.displayImageUrl,
              width: 40,
              height: 40,
              borderRadius: AppSizes.radiusXS,
              errorWidget: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppSizes.radiusXS),
                ),
                child: Icon(
                  pet == null ? Icons.link_off : Icons.pets,
                  color: colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: AppSizes.gapM),
            
            // 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.labelLarge(context).copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption(context),
                  ),
                ],
              ),
            ),
            
            // 체크 아이콘
            if (isSelected)
              Icon(Icons.check_circle, color: colorScheme.primary, size: 20),
          ],
        ),
      ),
    );
  }
}
