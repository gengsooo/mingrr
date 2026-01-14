import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/feature_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/pet_constants.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/dialogs/dialogs.dart';
import '../../../../core/widgets/image_picker_sheet.dart';
import '../../../../core/widgets/mingrr_bottom_sheet.dart';
import '../../../../core/widgets/verification_badge.dart';
import '../../../../core/widgets/warmth_score.dart';
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

  /// 인증 배지 섹션 (통일된 인증 배지 위젯 사용)
  Widget _buildVerificationSection(
    BuildContext context,
    WidgetRef ref,
    Map<BadgeType, bool> verifications,
  ) {
    return MingrrCard(
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
    );
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
            const SizedBox(height: 12),
            
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
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isVerified
              ? context.features.success.withOpacity(0.1)
              : Theme.of(context).colorScheme.outline.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
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
          ? Icon(Icons.check_circle, color: context.features.success)
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
          // 위치인증 - 현재 위치 기반 인증
          await _showLocationVerificationDialog(context, firestoreService, userId);
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

  /// 위치인증 다이얼로그 (GPS 기반)
  Future<void> _showLocationVerificationDialog(BuildContext context, FirestoreService firestoreService, String userId) async {
    // 로딩 다이얼로그 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('현재 위치를 확인하고 있습니다...'),
          ],
        ),
      ),
    );

    try {
      // 위치 권한 확인
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (context.mounted) Navigator.pop(context);
          if (context.mounted) {
            MingrrSnackBar.error(context, '위치 권한이 필요합니다');
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (context.mounted) Navigator.pop(context);
        if (context.mounted) {
          MingrrSnackBar.error(context, '설정에서 위치 권한을 허용해주세요');
        }
        return;
      }

      // 현재 위치 가져오기
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (context.mounted) Navigator.pop(context); // 로딩 다이얼로그 닫기

      // 위치 확인 다이얼로그 표시
      final geoPoint = GeoPoint(position.latitude, position.longitude);
      final addressText = '위도: ${position.latitude.toStringAsFixed(4)}, 경도: ${position.longitude.toStringAsFixed(4)}';

      if (!context.mounted) return;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.location_on, color: Theme.of(ctx).colorScheme.primary),
              const SizedBox(width: 8),
              const Text('위치 인증'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('현재 위치를 내 동네로 인증하시겠습니까?'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.my_location, color: Theme.of(context).colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        addressText,
                        style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '※ 인증된 위치는 내 동네로 설정되며, 주변 사용자에게 표시됩니다.',
                style: TextStyle(fontSize: 12, color: Theme.of(ctx).colorScheme.outlineVariant),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
              child: const Text('인증하기', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (confirmed == true && context.mounted) {
        await firestoreService.verifyLocation(userId, addressText, geoPoint: geoPoint);
        if (context.mounted) {
          MingrrSnackBar.success(context, '위치인증이 완료되었습니다! 📍');
        }
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) {
        MingrrSnackBar.error(context, '위치 확인 실패: $e');
      }
    }
  }

  /// 동물등록 인증 다이얼로그
  Future<void> _showPetRegistrationDialog(BuildContext context, FirestoreService firestoreService, String userId) async {
    final registrationController = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('동물등록 인증'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('동물등록번호를 입력해주세요.'),
            const SizedBox(height: 12),
            TextField(
              controller: registrationController,
              decoration: const InputDecoration(
                hintText: '15자리 동물등록번호',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.pets),
              ),
              keyboardType: TextInputType.number,
              maxLength: 15,
            ),
            const SizedBox(height: 8),
            Text(
              '※ 동물등록번호는 동물보호관리시스템에서 확인할 수 있습니다.',
              style: TextStyle(fontSize: 12, color: Theme.of(ctx).colorScheme.outlineVariant),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, registrationController.text),
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
            child: const Text('인증하기', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && context.mounted) {
      await firestoreService.verifyPetRegistration(userId, result);
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
