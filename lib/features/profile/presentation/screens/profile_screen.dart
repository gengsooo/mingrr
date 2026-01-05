import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/pet_constants.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/alert_dialog.dart';
import '../../../../core/widgets/confirm_bottom_sheet.dart';
import '../../../../core/widgets/image_picker_sheet.dart';
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

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ===== 프로필 헤더 =====
          SliverAppBar(
            expandedHeight: 330,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/');
                }
              },
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _buildProfileHeader(context, ref, currentUser),
            ),
            actions: [
              // 설정 버튼 (우상단 톱니바퀴)
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: AppColors.textPrimary),
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
                const MingrrSectionHeader(
                  title: '내 반려동물',
                  actionText: '추가',
                ),
                const SizedBox(height: AppSizes.gapM),
                _buildMyPets(context, ref),
                
                const SizedBox(height: AppSizes.gapXL),
                
                // 활동 통계
                const MingrrSectionHeader(title: '활동 기록'),
                const SizedBox(height: AppSizes.gapM),
                _buildActivityStats(ref),
                
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
      decoration: const BoxDecoration(
        gradient: AppColors.warmGradient,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 프로필 이미지 (선택적 - 없으면 기본 아이콘)
              GestureDetector(
                onTap: () => _showProfileImagePicker(context, ref),
                child: Stack(
                  children: [
                    currentUser.when(
                      data: (user) => _buildProfileImage(user?.profileImageUrl),
                      loading: () => _buildProfileImage(null),
                      error: (_, __) => _buildProfileImage(null),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.gapM),
              
              // 닉네임 + 수정 버튼
              currentUser.when(
                data: (user) => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      user?.nickname ?? '사용자',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _showNicknameEditDialog(context, ref, user),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit,
                          size: 16,
                          color: AppColors.textSecondary,
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
              const SizedBox(height: AppSizes.gapS),
              
              // 프로필 수정 버튼
              OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfileEditScreen()),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.textPrimary),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                ),
                child: const Text('프로필 수정'),
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
                child: const Text(
                  '인증하기',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.primary,
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
                      decoration: const BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: AppSizes.gapS),
                    const Text(
                      '추가하기',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
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
      loading: () => const Center(child: CircularProgressIndicator()),
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
                  color: AppColors.health.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.health.withOpacity(0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.medical_services, size: 16, color: AppColors.health),
                    SizedBox(width: 6),
                    Text(
                      '건강수첩',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.health,
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
  Widget _buildActivityStats(WidgetRef ref) {
    final statsAsync = ref.watch(userActivityStatsProvider);
    
    return statsAsync.when(
      data: (stats) => MingrrCard(
        margin: EdgeInsets.zero,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('매칭', '${stats['matches'] ?? 0}'),
            _buildStatDivider(),
            _buildStatItem('산책', '${stats['walks'] ?? 0}회'),
            _buildStatDivider(),
            _buildStatItem('거래', '${stats['transactions'] ?? 0}'),
            _buildStatDivider(),
            _buildStatItem('모임', '${stats['groups'] ?? 0}'),
          ],
        ),
      ),
      loading: () => MingrrCard(
        margin: EdgeInsets.zero,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('매칭', '-'),
            _buildStatDivider(),
            _buildStatItem('산책', '-'),
            _buildStatDivider(),
            _buildStatItem('거래', '-'),
            _buildStatDivider(),
            _buildStatItem('모임', '-'),
          ],
        ),
      ),
      error: (_, __) => MingrrCard(
        margin: EdgeInsets.zero,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('매칭', '0'),
            _buildStatDivider(),
            _buildStatItem('산책', '0회'),
            _buildStatDivider(),
            _buildStatItem('거래', '0'),
            _buildStatDivider(),
            _buildStatItem('모임', '0'),
          ],
        ),
      ),
    );
  }

  /// 통계 아이템
  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  /// 통계 구분선
  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 30,
      color: AppColors.divider,
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
                  color: AppColors.textSecondary,
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
                          color: AppColors.dating,
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
                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.textHint,
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('준비 중인 기능입니다')),
                    );
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
        padding: const EdgeInsets.all(AppSizes.paddingL),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSizes.radiusXL),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSizes.gapL),
            const Text(
              '인증 관리',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
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
              ? AppColors.success.withOpacity(0.1)
              : AppColors.divider.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(badgeType.emoji, style: const TextStyle(fontSize: 22)),
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
          color: isVerified ? AppColors.success : AppColors.textSecondary,
        ),
      ),
      trailing: isVerified
          ? const Icon(Icons.check_circle, color: AppColors.success)
          : TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _processVerification(context, ref, badgeType);
              },
              child: const Text('인증하기'),
            ),
    );
  }

  /// 인증 처리 (백엔드 연동)
  Future<void> _processVerification(BuildContext context, WidgetRef ref, BadgeType badgeType) async {
    final authState = ref.read(authStateProvider);
    final userId = authState.valueOrNull?.uid;
    
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다'), backgroundColor: Colors.red),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('인증 처리 중 오류가 발생했습니다: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// 본인인증 다이얼로그
  Future<void> _showIdentityVerificationDialog(BuildContext context, FirestoreService firestoreService, String userId) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('본인인증'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('본인인증을 진행하시겠습니까?'),
            SizedBox(height: 12),
            Text(
              '※ 실제 서비스에서는 PASS, 카카오 인증 등의 본인인증 서비스가 연동됩니다.',
              style: TextStyle(fontSize: 12, color: AppColors.textHint),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('인증하기', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      await firestoreService.verifyIdentity(userId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('본인인증이 완료되었습니다! 🪪'), backgroundColor: AppColors.success),
      );
    }
  }

  /// 위치인증 다이얼로그
  Future<void> _showLocationVerificationDialog(BuildContext context, FirestoreService firestoreService, String userId) async {
    final locationController = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('위치인증'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('현재 위치를 인증해주세요.'),
            const SizedBox(height: 12),
            TextField(
              controller: locationController,
              decoration: const InputDecoration(
                hintText: '예: 서울특별시 강남구',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '※ 실제 서비스에서는 GPS 기반 자동 위치 인증이 적용됩니다.',
              style: TextStyle(fontSize: 12, color: AppColors.textHint),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, locationController.text),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('인증하기', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && context.mounted) {
      await firestoreService.verifyLocation(userId, result);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('위치인증이 완료되었습니다! 📍'), backgroundColor: AppColors.success),
      );
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
            const Text(
              '※ 동물등록번호는 동물보호관리시스템에서 확인할 수 있습니다.',
              style: TextStyle(fontSize: 12, color: AppColors.textHint),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, registrationController.text),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('인증하기', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && context.mounted) {
      await firestoreService.verifyPetRegistration(userId, result);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('동물등록 인증이 완료되었습니다! 🐕'), backgroundColor: AppColors.success),
      );
    }
  }

  /// 설정 바텀시트
  void _showSettingsSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSizes.paddingL),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSizes.radiusXL),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSizes.gapXL),
            
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('계정 설정'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('개인정보 설정'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('알림 설정'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.error),
              title: const Text(
                '로그아웃',
                style: TextStyle(color: AppColors.error),
              ),
              onTap: () {
                Navigator.pop(context);
                showConfirmBottomSheet(
                  context,
                  type: ConfirmType.accountLogout,
                  onConfirm: () async {
                    await ref.read(authNotifierProvider.notifier).signOut();
                  },
                );
              },
            ),
            
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
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
  Widget _buildProfileImage(String? imageUrl) {
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
            errorBuilder: (_, __, ___) => _buildDefaultProfileImage(),
          ),
        ),
      );
    }
    
    // 기본 이미지
    return _buildDefaultProfileImage();
  }
  
  Widget _buildDefaultProfileImage() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.15),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: const Icon(
        Icons.person,
        size: 50,
        color: AppColors.primary,
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('프로필 이미지가 변경되었습니다!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('이미지 변경 실패: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }
  
  /// 닉네임 수정 다이얼로그
  void _showNicknameEditDialog(BuildContext context, WidgetRef ref, dynamic user) {
    if (user == null) return;
    
    // 30일 제한 체크
    final lastChanged = user.nicknameChangedAt;
    if (lastChanged != null) {
      final daysSinceChange = DateTime.now().difference(lastChanged).inDays;
      if (daysSinceChange < 30) {
        final daysRemaining = 30 - daysSinceChange;
        showAppAlert(
          context,
          type: AlertType.warning,
          title: '닉네임 변경 제한',
          message: '닉네임은 30일에 한 번만 변경할 수 있습니다.\n\n$daysRemaining일 후에 다시 변경할 수 있습니다.',
        );
        return;
      }
    }
    
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
              // 헤더
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit, size: 20, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      '닉네임 변경',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // 입력 필드
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: '새 닉네임을 입력해주세요',
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                  counterText: '',
                ),
                maxLength: 10,
              ),
              const SizedBox(height: 12),
              
              // 경고 메시지
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: AppColors.warning),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '닉네임은 30일에 한 번만 변경할 수 있습니다.',
                        style: TextStyle(fontSize: 12, color: AppColors.warning),
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
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppColors.divider),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '취소',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
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
                            'nicknameChangedAt': Timestamp.now(),
                          });
                          
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('닉네임이 변경되었습니다!'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('닉네임 변경 실패: $e'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '변경',
                        style: TextStyle(
                          fontSize: 15,
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
