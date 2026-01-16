import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/feature_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/pet_constants.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/animal_registration_service.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/dialogs/dialogs.dart';
import '../../../../core/widgets/image_picker_sheet.dart';
import '../../../../core/widgets/mingrr_bottom_sheet.dart';
import '../../../../core/widgets/verification_badge.dart';
import '../../../../core/widgets/kkosunnae_widgets.dart';
import '../../../../core/widgets/location_bubble_widget.dart';
import '../../../../core/providers/location_verification_provider.dart';
import '../../../../core/services/geocoding_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../pet/presentation/providers/pet_provider.dart';
import '../../../../models/pet_model.dart';
import 'activity_history_screen.dart';
import 'pet_edit_screen.dart';
import 'profile_edit_screen.dart';
import 'received_likes_screen.dart';
import 'transaction_history_screen.dart';
import 'wishlist_screen.dart';
import '../../../dating/presentation/providers/dating_provider.dart';
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
            elevation: 0,
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
          padding: const EdgeInsets.only(top: 48, bottom: 12), // 앱바 높이만큼 상단 패딩
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
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => _showNicknameEditDialog(context, ref, user),
                      child: Container(
                        padding: const EdgeInsets.all(4),
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
              const SizedBox(height: 6),
              
              // 꼬순내지수 (개선된 디자인)
              currentUser.when(
                data: (user) => _buildKkosunnaeScore(user?.kkosunnaeScore ?? 50.0),
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
            padding: const EdgeInsets.only(bottom: 8),
            child: LocationMismatchBanner(
              savedAddress: user?.homeAddress,
              accentColor: context.features.success,
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
                  const Text(
                    '인증 배지',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showVerificationSheet(context, ref, verifications),
                    child: Text(
                      '인증하기',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
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
            itemCount: pets.length + 1, // 강아지들 + 추가 버튼
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
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.primary,
                      ),
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
      loading: () => const MingrrLoadingState(),
      error: (_, __) => const SizedBox(),
    );
  }

  /// 강아지 카드 (V2: 건강수첩 버튼 포함)
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
            // 프로필 이미지 (프로필 이미지만 사용, 없으면 기본 아이콘)
            MingrrAvatar(
              size: 55,
              imageUrl: pet.profileImageUrl,
            ),
            const SizedBox(height: AppSizes.gapS),
            Text(
              pet.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSizes.gapS),
            // 건강수첩 버튼 (확대)
            GestureDetector(
              onTap: () => context.push('/health'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: context.features.health.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.features.health.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.medical_services, size: 16, color: context.features.health),
                    const SizedBox(width: 6),
                    Text(
                      '건강수첩',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.features.health,
                        fontWeight: FontWeight.w600,
                      ),
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
    return pet.primaryPhotoUrl;
  }

  /// 활동 통계 (Firebase 연동)
  Widget _buildActivityStats(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(userActivityStatsProvider);
    
    return statsAsync.when(
      data: (stats) => MingrrCard(
        margin: EdgeInsets.zero,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(context, '매칭', '${stats['matches'] ?? 0}'),
            _buildStatDivider(context),
            _buildStatItem(context, '산책', '${stats['walks'] ?? 0}회'),
            _buildStatDivider(context),
            _buildStatItem(context, '거래', '${stats['transactions'] ?? 0}'),
            _buildStatDivider(context),
            _buildStatItem(context, '모임', '${stats['groups'] ?? 0}'),
          ],
        ),
      ),
      loading: () => MingrrCard(
        margin: EdgeInsets.zero,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(context, '매칭', '-'),
            _buildStatDivider(context),
            _buildStatItem(context, '산책', '-'),
            _buildStatDivider(context),
            _buildStatItem(context, '거래', '-'),
            _buildStatDivider(context),
            _buildStatItem(context, '모임', '-'),
          ],
        ),
      ),
      error: (_, __) => MingrrCard(
        margin: EdgeInsets.zero,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(context, '매칭', '0'),
            _buildStatDivider(context),
            _buildStatItem(context, '산책', '0회'),
            _buildStatDivider(context),
            _buildStatItem(context, '거래', '0'),
            _buildStatDivider(context),
            _buildStatItem(context, '모임', '0'),
          ],
        ),
      ),
    );
  }

  /// 통계 아이템
  Widget _buildStatItem(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  /// 통계 구분선
  Widget _buildStatDivider(BuildContext context) {
    return Container(
      width: 1,
      height: 30,
      color: Theme.of(context).colorScheme.outline,
    );
  }

  /// 메뉴 목록
  Widget _buildMenuList(BuildContext context, WidgetRef ref) {
    final likesCount = ref.watch(receivedLikesCountProvider);
    
    final menus = [
      {
        'icon': Icons.favorite,
        'label': '받은 좋아요',
        'badge': likesCount > 0 ? '$likesCount' : null,
        'screen': const ReceivedLikesScreen(),
      },
      {
        'icon': Icons.history,
        'label': '활동 내역',
        'badge': null,
        'screen': const ActivityHistoryScreen(),
      },
      {
        'icon': Icons.bookmark,
        'label': '찜한 목록',
        'badge': null,
        'screen': const WishlistScreen(),
      },
      {
        'icon': Icons.receipt_long,
        'label': '거래 내역',
        'badge': null,
        'screen': const TransactionHistoryScreen(),
      },
      {
        'icon': Icons.notifications,
        'label': '알림 설정',
        'badge': null,
        'screen': null,
      },
      {
        'icon': Icons.help_outline,
        'label': '고객센터',
        'badge': null,
        'screen': null,
      },
      {
        'icon': Icons.info_outline,
        'label': '앱 정보',
        'badge': null,
        'screen': null,
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
              ListTile(
                leading: Icon(
                  menu['icon'] as IconData,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                title: Text(
                  menu['label'] as String,
                  style: const TextStyle(
                    fontSize: 15,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (menu['badge'] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: context.features.dating,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          menu['badge'] as String,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right,
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ],
                ),
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
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '인증 관리',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            // 설명 문구 (데이트 신청 바텀시트와 동일한 스타일)
            Text(
              '인증을 완료하면 더 많은 친구들에게\n추천될 수 있어요!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            
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
              description: '동물등록증을 업로드해주세요',
            ),
            
            // 위치 인증 (당근마켓 스타일)
            _buildVerificationTile(
              context: context,
              ref: ref,
              badgeType: BadgeType.location,
              isVerified: verifications[BadgeType.location] ?? false,
              description: '현재 위치에서 동네 인증을 해주세요',
            ),
            
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
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
              ? context.features.success.withOpacity(0.1)
              : Theme.of(context).colorScheme.outline.withOpacity(0.5),
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
        style: TextStyle(
          fontSize: 12,
          color: isVerified ? context.features.success : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: isVerified
          ? canReVerify
              // 위치 인증: 체크 아이콘 + 재인증 버튼
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: context.features.success, size: 20),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _processVerification(context, ref, badgeType);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: const Size(50, 28),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        '재인증',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                )
              // 다른 인증: 체크 아이콘만
              : Icon(Icons.check_circle, color: context.features.success)
          : ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _processVerification(context, ref, badgeType);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: context.features.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: const Size(70, 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                '인증하기',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
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
          await _showIdentityVerificationDialog(context, firestoreService, userId);
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
  Future<void> _showIdentityVerificationDialog(BuildContext context, FirestoreService firestoreService, String userId) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('본인인증'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('본인인증을 진행하시겠습니까?'),
            const SizedBox(height: 12),
            Text(
              '※ 실제 서비스에서는 PASS, 카카오 인증 등의 본인인증 서비스가 연동됩니다.',
              style: TextStyle(fontSize: 12, color: Theme.of(ctx).colorScheme.outlineVariant),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
            child: const Text('인증하기', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      await firestoreService.verifyIdentity(userId);
      MingrrSnackBar.success(context, '본인인증이 완료되었습니다! ');
    }
  }

  /// 위치 획득 헬퍼 함수 (타임아웃 포함)
  Future<Position?> _getPositionWithTimeout() async {
    try {
      // 마지막 알려진 위치 먼저 시도 (즉시 반환)
      final lastPosition = await Geolocator.getLastKnownPosition();
      if (lastPosition != null) {
        debugPrint('마지막 위치 사용: ${lastPosition.latitude}, ${lastPosition.longitude}');
        return lastPosition;
      }
    } catch (e) {
      debugPrint('마지막 위치 획득 실패: $e');
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
    final color = colorScheme.primary;
    
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 아이콘
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.location_on, size: 28, color: color),
              ),
              const SizedBox(height: 16),
              
              // 제목
              const Text(
                '위치 인증',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              
              // 메시지
              Text(
                '현재 위치를 내 동네로 등록하시겠습니까?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              
              // 주소 표시
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(AppSizes.radiusS),
                ),
                child: Row(
                  children: [
                    Icon(Icons.my_location, color: color, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        addressText,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: colorScheme.onSurface),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // 버튼
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: colorScheme.outline),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text('취소', style: TextStyle(fontSize: 15, color: colorScheme.onSurfaceVariant)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('인증하기', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// 재인증 다이얼로그 (500m 이내)
  Future<bool?> _showReVerificationDialog(BuildContext context, String addressText, double distance) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = context.features.success;
    
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 아이콘
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle, size: 28, color: color),
              ),
              const SizedBox(height: 16),
              
              // 제목
              const Text(
                '위치 인증 갱신',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              
              // 메시지
              Text(
                '현재 위치에서 인증을 갱신하시겠습니까?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              
              // 주소 표시
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(AppSizes.radiusS),
                ),
                child: Row(
                  children: [
                    Icon(Icons.my_location, color: color, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            addressText,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: colorScheme.onSurface),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '저장된 위치에서 ${distance.round()}m',
                            style: TextStyle(fontSize: 12, color: color),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // 버튼
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: colorScheme.outline),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text('취소', style: TextStyle(fontSize: 15, color: colorScheme.onSurfaceVariant)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('인증 갱신', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
    final color = colorScheme.primary;
    
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 아이콘
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.swap_horiz, size: 28, color: color),
              ),
              const SizedBox(height: 16),
              
              // 제목
              const Text(
                '동네 변경',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              
              // 메시지
              Text(
                '현재 위치가 저장된 동네와\n${LocationService.formatDistance(distance)} 떨어져 있어요.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              
              // 저장된 위치
              if (savedAddress != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.outline.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(AppSizes.radiusS),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_on_outlined, color: colorScheme.onSurfaceVariant, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('저장된 동네', style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                            Text(savedAddress, style: TextStyle(fontSize: 13, color: colorScheme.onSurface)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
              
              // 현재 위치
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(AppSizes.radiusS),
                ),
                child: Row(
                  children: [
                    Icon(Icons.my_location, color: color, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('현재 위치', style: TextStyle(fontSize: 11, color: color)),
                          Text(newAddress, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: colorScheme.onSurface)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // 버튼
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: colorScheme.outline),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text('취소', style: TextStyle(fontSize: 15, color: colorScheme.onSurfaceVariant)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('동네 변경', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
          onTap: () => MingrrSnackBar.info(context, '알림 설정 준비 중입니다'),
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
  Widget _buildKkosunnaeScore(double score) {
    return KkosunnaeScoreMedium(score: score);
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
      return Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
        ),
        child: ClipOval(
          child: Image.network(
            imageUrl,
            width: 100,
            height: 100,
            fit: BoxFit.cover,
            errorBuilder: (ctx, __, ___) => _buildDefaultProfileImage(ctx),
          ),
        ),
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
        color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
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
  void _showNicknameEditDialog(BuildContext context, WidgetRef ref, dynamic user) {
    if (user == null) return;
    
    final controller = TextEditingController(text: user.nickname);
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더 + X 버튼
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '닉네임 변경',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // 입력 필드
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: '새 닉네임을 입력해주세요',
                  hintStyle: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.outlineVariant),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  counterText: '',
                ),
                style: const TextStyle(fontSize: 14),
                maxLength: 10,
              ),
              const SizedBox(height: 16),
              
              // 버튼
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        side: BorderSide(color: Theme.of(context).colorScheme.outline),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        '취소',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final newNickname = controller.text.trim();
                        if (newNickname.isEmpty || newNickname == user.nickname) {
                          Navigator.pop(context);
                          return;
                        }
                        
                        try {
                          final firestore = FirebaseFirestore.instance;
                          await firestore.collection('users').doc(user.id).update({
                            'nickname': newNickname,
                          });
                          
                          if (context.mounted) {
                            Navigator.pop(context);
                            MingrrSnackBar.success(context, '닉네임이 변경되었습니다!');
                          }
                        } catch (e) {
                          if (context.mounted) {
                            MingrrSnackBar.error(context, '닉네임 변경 실패: $e');
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        '변경',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
        debugPrint('위치 획득 실패: $e');
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
      debugPrint('위치 인증 오류: $e');
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
      debugPrint('인증 처리 오류: $e');
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
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
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 3, color: color),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          '현재 위치 확인 중',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          _statusMessage,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
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
            color: Colors.red.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.location_off, size: 28, color: Colors.red),
        ),
        const SizedBox(height: 20),
        const Text(
          '위치 확인 실패',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          _errorMessage!,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant, height: 1.5),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context, false),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('확인', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
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
            color: themeColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 28, color: themeColor),
        ),
        const SizedBox(height: 16),
        
        // 제목
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        
        // 메시지
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant, height: 1.4),
        ),
        const SizedBox(height: 16),
        
        // 주소 표시
        if (_addressText != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: themeColor.withOpacity(0.08),
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
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: colorScheme.onSurface),
                      ),
                      if (!_isFirstTime && _distance != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          '저장된 위치에서 ${_distance!.round()}m',
                          style: TextStyle(fontSize: 12, color: themeColor),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 20),
        
        // 버튼
        if (isTooFar)
          // 조금 더 가까이: 확인 버튼만
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, false),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(buttonText, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          )
        else
          // 인증/동네변경: 취소/확인 버튼
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: colorScheme.outline),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('취소', style: TextStyle(fontSize: 15, color: colorScheme.onSurfaceVariant)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _doVerification,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(buttonText, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
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
      debugPrint('동물등록 인증 오류: $e');
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
      debugPrint('인증 저장 오류: $e');
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
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
            color: primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.pets, size: 28, color: primaryColor),
        ),
        const SizedBox(height: 16),
        
        // 제목
        const Text(
          '동물등록 인증',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          '동물등록번호와 소유자 성명을 입력해주세요.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 20),
        
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
        const SizedBox(height: 12),
        
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
          const SizedBox(height: 12),
          Text(
            _errorMessage!,
            style: const TextStyle(fontSize: 13, color: Colors.red),
          ),
        ],
        
        const SizedBox(height: 8),
        Text(
          '※ 동물등록번호는 동물보호관리시스템(animal.go.kr)에서 확인할 수 있습니다.',
          style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 20),
        
        // 버튼
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: colorScheme.outline),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('취소', style: TextStyle(fontSize: 15, color: colorScheme.onSurfaceVariant)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _startVerification,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('인증하기', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
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
            color: primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 3, color: primaryColor),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          '동물등록 인증 중',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          _statusMessage,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
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
            color: successColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.check_circle, size: 28, color: successColor),
        ),
        const SizedBox(height: 16),
        
        // 제목
        const Text(
          '인증 완료',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        
        // 동물 정보 카드
        if (_animalInfo != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: successColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(AppSizes.radiusS),
            ),
            child: Column(
              children: [
                // 이름
                Row(
                  children: [
                    Icon(Icons.pets, color: successColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      _animalInfo!.dogNm,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
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
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(AppSizes.radiusS),
            ),
            child: Row(
              children: [
                Icon(Icons.link, color: primaryColor, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '내 반려동물 "${_selectedPet!.name}"과 연결됨',
                    style: TextStyle(fontSize: 13, color: primaryColor),
                  ),
                ),
              ],
            ),
          ),
        ],
        
        const SizedBox(height: 20),
        
        // 완료 버튼
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _completeVerification,
            style: ElevatedButton.styleFrom(
              backgroundColor: successColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('완료', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
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
            color: Colors.red.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.error_outline, size: 28, color: Colors.red),
        ),
        const SizedBox(height: 20),
        const Text(
          '인증 실패',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          _errorMessage ?? '알 수 없는 오류가 발생했습니다.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant, height: 1.5),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: colorScheme.outline),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('닫기', style: TextStyle(fontSize: 15, color: colorScheme.onSurfaceVariant)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => setState(() {
                  _step = _VerificationStep.input;
                  _errorMessage = null;
                }),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('다시 시도', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
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
            color: primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.pets, size: 28, color: primaryColor),
        ),
        const SizedBox(height: 16),
        
        // 제목
        const Text(
          '반려동물 연결',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          '인증된 동물 정보를 연결할 반려동물을 선택해주세요.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        
        // 인증된 동물 정보
        if (_animalInfo != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(AppSizes.radiusS),
            ),
            child: Row(
              children: [
                Icon(Icons.verified, color: primaryColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _animalInfo!.dogNm,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${_animalInfo!.kindNm ?? ''} · ${_animalInfo!.sexNm ?? ''}',
                        style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        
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
        const SizedBox(height: 20),
        
        // 버튼
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: colorScheme.outline),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('취소', style: TextStyle(fontSize: 15, color: colorScheme.onSurfaceVariant)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  setState(() => _step = _VerificationStep.success);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('다음', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildPetOption(PetModel? pet, String title, String subtitle, ColorScheme colorScheme) {
    final isSelected = _selectedPet?.id == pet?.id;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedPet = pet),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary.withOpacity(0.1) : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppSizes.radiusS),
          border: Border.all(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            // 프로필 이미지 또는 아이콘
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: pet?.displayImageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(pet!.displayImageUrl!, fit: BoxFit.cover),
                    )
                  : Icon(
                      pet == null ? Icons.link_off : Icons.pets,
                      color: colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
            ),
            const SizedBox(width: 12),
            
            // 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
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
