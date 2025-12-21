import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// ============================================================
/// 프로필 화면
/// 보호자 정보, 반려동물 정보, 설정 등
/// ============================================================
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ===== 프로필 헤더 =====
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildProfileHeader(currentUser),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings, color: AppColors.textPrimary),
                onPressed: () {
                  _showSettingsSheet(context, ref);
                },
              ),
            ],
          ),

          // ===== 컨텐츠 =====
          SliverPadding(
            padding: const EdgeInsets.all(AppSizes.paddingM),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 인증 배지
                _buildVerificationSection(),
                
                const SizedBox(height: AppSizes.gapXL),
                
                // 내 반려동물
                const MingrrSectionHeader(
                  title: '내 반려동물',
                  actionText: '추가',
                ),
                const SizedBox(height: AppSizes.gapM),
                _buildMyPets(context),
                
                const SizedBox(height: AppSizes.gapXL),
                
                // 활동 통계
                const MingrrSectionHeader(title: '활동 통계'),
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

  /// 인증 배지 섹션
  Widget _buildVerificationSection() {
    return MingrrCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '인증 배지',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSizes.gapM),
          Row(
            children: [
              _buildBadgeItem(
                icon: Icons.verified_user,
                label: '본인 인증',
                isVerified: true,
              ),
              const SizedBox(width: AppSizes.gapM),
              _buildBadgeItem(
                icon: Icons.pets,
                label: '동물등록',
                isVerified: false,
              ),
              const SizedBox(width: AppSizes.gapM),
              _buildBadgeItem(
                icon: Icons.health_and_safety,
                label: '건강 인증',
                isVerified: false,
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
    required bool isVerified,
  }) {
    return Expanded(
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
            Icon(
              icon,
              color: isVerified ? AppColors.success : AppColors.textHint,
              size: 28,
            ),
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
            Text(
              isVerified ? '완료' : '미인증',
              style: TextStyle(
                fontSize: 10,
                color: isVerified ? AppColors.success : AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 내 반려동물 목록
  Widget _buildMyPets(BuildContext context) {
    return SizedBox(
      height: 160,
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
                      decoration: BoxDecoration(
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

          return _buildPetCard(index);
        },
      ),
    );
  }

  /// 반려동물 카드
  Widget _buildPetCard(int index) {
    final pets = [
      {'name': '뽀삐', 'breed': '골든 리트리버', 'age': '2살'},
      {'name': '초코', 'breed': '푸들', 'age': '3살'},
    ];

    final pet = pets[index];

    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: AppSizes.gapM),
      child: MingrrCard(
        margin: EdgeInsets.zero,
        onTap: () {
          // TODO: 반려동물 상세/수정
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const MingrrAvatar(size: 60),
            const SizedBox(height: AppSizes.gapS),
            Text(
              pet['name']!,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${pet['breed']} · ${pet['age']}',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.gapS),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified, size: 12, color: AppColors.success),
                  SizedBox(width: 2),
                  Text(
                    '등록 완료',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.success,
                    ),
                  ),
                ],
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
