import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/feature_colors.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../profile/presentation/screens/liked_list_screen.dart';
import '../../../profile/presentation/screens/my_activity_screen.dart';
import '../../../profile/presentation/screens/settings/notification_settings_screen.dart';
import '../../../profile/presentation/screens/settings/app_settings_screen.dart';
import '../../../profile/presentation/screens/settings/account_settings_screen.dart';
import '../../../profile/presentation/screens/settings/customer_service_screen.dart';
import '../../../profile/presentation/screens/settings/app_info_screen.dart';

/// ============================================================
/// 전체(더보기) 화면
/// 
/// 하단 탭 5번째 메뉴. 토스/카카오 "전체" 탭 스타일.
/// 프로필 카드 + 서비스 그리드 + 내 활동 + 설정 구성.
/// ============================================================
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final verificationsAsync = ref.watch(userVerificationsProvider);
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // 앱바
            MingrrSliverAppBar.mainTab(
              titleWidget: Text(
                '전체',
                style: AppTextStyles.headlineMedium(context),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPaddingH),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ===== 프로필 카드 =====
                  _buildProfileCard(context, ref, currentUser, verificationsAsync),
                  const SizedBox(height: AppSizes.sectionGap),

                  // ===== 서비스 그리드 =====
                  _buildServiceGrid(context),
                  const SizedBox(height: AppSizes.sectionGap),

                  // ===== 내 활동 섹션 =====
                  _buildActivitySection(context),
                  const SizedBox(height: AppSizes.sectionGap),

                  // ===== 설정 섹션 =====
                  _buildSettingsSection(context, ref),
                  const SizedBox(height: AppSizes.gapXXL),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 프로필 카드 (탭하면 프로필 상세로 이동)
  Widget _buildProfileCard(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<dynamic> currentUser,
    AsyncValue<Map<String, bool>> verificationsAsync,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => context.push('/profile'),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.cardInnerPadding),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
        ),
        child: Row(
          children: [
            // 아바타
            currentUser.when(
              data: (user) => MingrrImage.avatar(
                size: 56,
                imageUrl: user?.profileImageUrl,
              ),
              loading: () => const MingrrImage.avatar(size: 56),
              error: (_, _) => const MingrrImage.avatar(size: 56),
            ),
            const SizedBox(width: AppSizes.gapL),

            // 닉네임 + 인증 배지
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  currentUser.when(
                    data: (user) => Text(
                      user?.nickname ?? '사용자',
                      style: AppTextStyles.headlineSmall(context),
                    ),
                    loading: () => Text('로딩 중...', style: AppTextStyles.headlineSmall(context)),
                    error: (_, _) => Text('사용자', style: AppTextStyles.headlineSmall(context)),
                  ),
                  const SizedBox(height: AppSizes.gapXS),
                  // 인증 배지 요약
                  verificationsAsync.when(
                    data: (v) => _buildVerificationSummary(context, v),
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),

            // 화살표
            Icon(
              AppIcons.chevronRight,
              color: colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  /// 인증 배지 요약 (작은 아이콘 3개)
  Widget _buildVerificationSummary(BuildContext context, Map<String, bool> verifications) {
    final identity = verifications['identity'] ?? false;
    final location = verifications['location'] ?? false;
    final pet = verifications['petRegistration'] ?? false;
    final accent = context.features.dating;

    return Row(
      children: [
        _miniVerificationBadge(context, AppIcons.verified, '본인', identity, accent),
        const SizedBox(width: AppSizes.gapS),
        _miniVerificationBadge(context, AppIcons.location, '위치', location, accent),
        const SizedBox(width: AppSizes.gapS),
        _miniVerificationBadge(context, AppIcons.pet, '동물', pet, accent),
      ],
    );
  }

  Widget _miniVerificationBadge(
    BuildContext context, IconData icon, String label, bool isVerified, Color accent,
  ) {
    final color = isVerified ? accent : Theme.of(context).colorScheme.outlineVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 2),
        Text(
          label,
          style: AppTextStyles.captionSmall(context).copyWith(color: color),
        ),
      ],
    );
  }

  /// 서비스 그리드 (2x2)
  Widget _buildServiceGrid(BuildContext context) {
    final accent = context.features.dating;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('서비스', style: AppTextStyles.titleLarge(context).withWeight(FontWeight.w600)),
        const SizedBox(height: AppSizes.gapM),
        Row(
          children: [
            Expanded(
              child: _buildServiceItem(
                context,
                icon: AppIcons.walk,
                label: '산책',
                color: accent,
                onTap: () => context.push('/walk'),
              ),
            ),
            const SizedBox(width: AppSizes.listItemGap),
            Expanded(
              child: _buildServiceItem(
                context,
                icon: AppIcons.communityOutlined,
                label: '커뮤니티',
                color: accent,
                onTap: () => context.push('/community'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.listItemGap),
        Row(
          children: [
            Expanded(
              child: _buildServiceItem(
                context,
                icon: AppIcons.group,
                label: '소모임',
                color: accent,
                onTap: () => context.push('/groups'),
              ),
            ),
            const SizedBox(width: AppSizes.listItemGap),
            Expanded(
              child: _buildServiceItem(
                context,
                icon: AppIcons.health,
                label: '건강수첩',
                color: accent,
                onTap: () => context.push('/health'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildServiceItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingL, horizontal: AppSizes.paddingM),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: AppOpacity.o10),
                borderRadius: BorderRadius.circular(AppSizes.radiusM),
              ),
              child: Icon(icon, size: 22, color: color),
            ),
            const SizedBox(width: AppSizes.gapM),
            Text(
              label,
              style: AppTextStyles.titleMedium(context).withWeight(FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  /// 내 활동 섹션
  Widget _buildActivitySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('내 활동', style: AppTextStyles.titleLarge(context).withWeight(FontWeight.w600)),
        const SizedBox(height: AppSizes.gapM),
        _buildMenuCard(context, [
          _MenuItem(AppIcons.likeOutlined, '좋아요 목록', () => _pushScreen(context, 'liked')),
          _MenuItem(AppIcons.history, '내 활동', () => _pushScreen(context, 'activity')),
          _MenuItem(AppIcons.starOutlined, '평가 내역', () => context.push('/profile/rating-history')),
        ]),
      ],
    );
  }

  /// 설정 섹션
  Widget _buildSettingsSection(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('설정', style: AppTextStyles.titleLarge(context).withWeight(FontWeight.w600)),
        const SizedBox(height: AppSizes.gapM),
        _buildMenuCard(context, [
          _MenuItem(AppIcons.notification, '알림 설정', () => _pushScreen(context, 'notification_settings')),
          _MenuItem(AppIcons.settingsOutlined, '앱 설정', () => _pushScreen(context, 'app_settings')),
          _MenuItem(AppIcons.profile, '계정 관리', () => _pushScreen(context, 'account_settings')),
          _MenuItem(AppIcons.help, '고객센터', () => _pushScreen(context, 'customer_service')),
          _MenuItem(AppIcons.info, '앱 정보', () => _pushScreen(context, 'app_info')),
        ]),
      ],
    );
  }

  /// 메뉴 카드 (리스트 그룹)
  Widget _buildMenuCard(BuildContext context, List<_MenuItem> items) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isLast = index == items.length - 1;

          return Column(
            children: [
              MingrrSettingsTile(
                icon: item.icon,
                title: item.label,
                onTap: item.onTap,
              ),
              if (!isLast)
                Divider(height: 1, indent: 56, color: colorScheme.outline.withValues(alpha: AppOpacity.o20)),
            ],
          );
        }).toList(),
      ),
    );
  }

  /// 설정 하위 화면으로 이동 (기존 프로필 설정 화면 재사용)
  void _pushScreen(BuildContext context, String type) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => _getScreen(type)),
    );
  }

  /// 화면 반환 (기존 프로필 하위 화면 재사용)
  Widget _getScreen(String type) {
    switch (type) {
      case 'liked':
        return const LikedListScreen();
      case 'activity':
        return const MyActivityScreen();
      case 'notification_settings':
        return const NotificationSettingsScreen();
      case 'app_settings':
        return const AppSettingsScreen();
      case 'account_settings':
        return const AccountSettingsScreen();
      case 'customer_service':
        return const CustomerServiceScreen();
      case 'app_info':
        return const AppInfoScreen();
      default:
        return Scaffold(
          appBar: MingrrAppBar(title: '준비중'),
          body: const Center(child: Text('준비 중인 기능입니다')),
        );
    }
  }
}

/// 메뉴 아이템 데이터
class _MenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuItem(this.icon, this.label, this.onTap);
}
