import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/pet_constants.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// ============================================================
/// 프로필 화면 (V2 리팩토링 - 강아지 전용)
/// 
/// 변경사항:
/// - 강아지 전용 앱으로 변경 (PetType 제거)
/// - 예방접종 인증 → 위치 인증으로 변경
/// - 인증/배지 관리 (본인인증, 위치인증, 동물등록)
/// - 건강수첩 접근
/// ============================================================

// 데모용 인증 상태
final _demoVerificationProvider = StateProvider<Map<BadgeType, bool>>((ref) => {
  BadgeType.identity: true,
  BadgeType.location: false,
  BadgeType.petRegistration: false,
});

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final verifications = ref.watch(_demoVerificationProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ===== 프로필 헤더 =====
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _buildProfileHeader(currentUser),
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
                _buildActivityStats(),
                
                const SizedBox(height: AppSizes.gapXL),
                
                // 메뉴 목록
                _buildMenuList(context),
                
                const SizedBox(height: AppSizes.gapXXL),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  /// 프로필 헤더
  Widget _buildProfileHeader(AsyncValue<dynamic> currentUser) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.warmGradient,
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            // 프로필 이미지
            Stack(
              children: [
                const MingrrAvatar(
                  size: 100,
                  showBorder: true,
                  borderColor: Colors.white,
                  placeholderIcon: Icons.person,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.gapM),
            
            // 닉네임
            currentUser.when(
              data: (user) => Text(
                user?.nickname ?? '사용자',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              loading: () => const Text('로딩 중...'),
              error: (_, __) => const Text('사용자'),
            ),
            const SizedBox(height: 4),
            
            // 한줄 소개
            const Text(
              '반려동물과 함께하는 행복한 일상 🐾',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSizes.gapM),
            
            // 프로필 수정 버튼
            OutlinedButton(
              onPressed: () {
                // TODO: 프로필 수정 화면
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
    );
  }

  /// 인증 배지 섹션 (V1: 본인인증, 동물등록, 예방접종)
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
              _buildBadgeItem(
                icon: Icons.badge_outlined,
                label: BadgeType.identity.label,
                emoji: BadgeType.identity.emoji,
                isVerified: verifications[BadgeType.identity] ?? false,
                onTap: () => _showVerificationSheet(context, ref, verifications),
              ),
              const SizedBox(width: AppSizes.gapM),
              _buildBadgeItem(
                icon: Icons.pets,
                label: BadgeType.petRegistration.label,
                emoji: BadgeType.petRegistration.emoji,
                isVerified: verifications[BadgeType.petRegistration] ?? false,
                onTap: () => _showVerificationSheet(context, ref, verifications),
              ),
              const SizedBox(width: AppSizes.gapM),
              _buildBadgeItem(
                icon: Icons.location_on,
                label: BadgeType.location.label,
                emoji: BadgeType.location.emoji,
                isVerified: verifications[BadgeType.location] ?? false,
                onTap: () => _showVerificationSheet(context, ref, verifications),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 배지 아이템
  Widget _buildBadgeItem({
    required IconData icon,
    required String label,
    required String emoji,
    required bool isVerified,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingM),
          decoration: BoxDecoration(
            color: isVerified
                ? AppColors.success.withOpacity(0.1)
                : AppColors.divider.withOpacity(0.5),
            borderRadius: BorderRadius.circular(AppSizes.radiusM),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isVerified ? AppColors.success : AppColors.textHint,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isVerified ? AppColors.success : AppColors.textHint,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isVerified ? '완료' : '미인증',
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 내 반려동물 목록 (V1: 건강수첩 버튼 포함)
  Widget _buildMyPets(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3, // 2마리 + 추가 버튼
        itemBuilder: (context, index) {
          if (index == 2) {
            // 추가 버튼
            return Container(
              width: 120,
              margin: const EdgeInsets.only(right: AppSizes.gapM),
              child: MingrrCard(
                margin: EdgeInsets.zero,
                onTap: () {
                  // TODO: 반려동물 추가
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

          return _buildPetCard(context, index);
        },
      ),
    );
  }

  /// 강아지 카드 (V2: 건강수첩 버튼 포함)
  Widget _buildPetCard(BuildContext context, int index) {
    final dogs = [
      {'name': '뽀삐', 'breed': '골든 리트리버', 'age': '2살'},
      {'name': '코코', 'breed': '푸들', 'age': '3살'},
    ];

    final dog = dogs[index];

    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: AppSizes.gapM),
      child: MingrrCard(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(AppSizes.paddingS),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 프로필 이미지
            GestureDetector(
              onTap: () {
                // TODO: 반려동물 상세/수정
              },
              child: Stack(
                children: [
                  const MingrrAvatar(size: 55),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.verified, size: 12, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.gapS),
            Text(
              dog['name'] as String,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${dog['breed']} · ${dog['age']}',
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.gapS),
            // 건강수첩 버튼
            GestureDetector(
              onTap: () => context.push('/health'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.health.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.medical_services, size: 12, color: AppColors.health),
                    SizedBox(width: 4),
                    Text(
                      '건강수첩',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.health,
                        fontWeight: FontWeight.w500,
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

  /// 활동 통계
  Widget _buildActivityStats() {
    return MingrrCard(
      margin: EdgeInsets.zero,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('매칭', '12'),
          _buildStatDivider(),
          _buildStatItem('산책', '28회'),
          _buildStatDivider(),
          _buildStatItem('거래', '5'),
          _buildStatDivider(),
          _buildStatItem('모임', '3'),
        ],
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
  Widget _buildMenuList(BuildContext context) {
    final menus = [
      {'icon': Icons.favorite, 'label': '받은 좋아요', 'badge': '3'},
      {'icon': Icons.history, 'label': '활동 내역', 'badge': null},
      {'icon': Icons.bookmark, 'label': '찜한 목록', 'badge': null},
      {'icon': Icons.receipt_long, 'label': '거래 내역', 'badge': null},
      {'icon': Icons.notifications, 'label': '알림 설정', 'badge': null},
      {'icon': Icons.help_outline, 'label': '고객센터', 'badge': null},
      {'icon': Icons.info_outline, 'label': '앱 정보', 'badge': null},
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
                  // TODO: 각 메뉴 화면으로 이동
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
              onPressed: () {
                Navigator.pop(context);
                // 데모: 인증 완료 처리
                final current = ref.read(_demoVerificationProvider);
                ref.read(_demoVerificationProvider.notifier).state = {
                  ...current,
                  badgeType: true,
                };
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${badgeType.label} 인증이 완료되었습니다! ${badgeType.emoji}'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              child: const Text('인증하기'),
            ),
    );
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
                ref.read(authNotifierProvider.notifier).signOut();
              },
            ),
            
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}
