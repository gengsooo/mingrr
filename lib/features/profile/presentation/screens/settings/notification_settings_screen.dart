import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/app_sizes.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/feature_colors.dart';
import '../../../../../core/widgets/common_widgets.dart';
import '../../providers/notification_settings_provider.dart';

/// ============================================================
/// 알림 설정 화면
/// 
/// 프로필 > 알림 설정
/// 기능:
/// - 전체 알림 ON/OFF
/// - 카테고리별 알림 (데이팅/마켓/채팅/소모임/커뮤니티)
/// - 야간 방해금지
/// - 마케팅 알림
/// ============================================================

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(notificationSettingsProvider);
    final notifier = ref.watch(notificationSettingsNotifierProvider.notifier);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('알림 설정'),
      ),
      body: settingsAsync.when(
        data: (settings) => _buildContent(context, ref, settings, notifier),
        loading: () => const MingrrLoadingState(
          type: MingrrLoadingType.primary,
          message: '알림 설정을 불러오고 있어요',
        ),
        error: (_, __) => MingrrErrorState(
          onRetry: () => ref.invalidate(notificationSettingsProvider),
        ),
      ),
    );
  }
  
  Widget _buildContent(
    BuildContext context, 
    WidgetRef ref,
    NotificationSettings settings,
    NotificationSettingsNotifier notifier,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return ListView(
      padding: const EdgeInsets.all(AppSizes.paddingM),
      children: [
        // 전체 알림
        MingrrCard(
          margin: EdgeInsets.zero,
          child: _NotificationToggleTile(
            icon: Icons.notifications,
            iconColor: colorScheme.primary,
            title: '전체 알림',
            subtitle: '모든 알림을 받습니다',
            value: settings.allEnabled,
            onChanged: (value) => notifier.toggleSetting('allEnabled', value, settings),
          ),
        ),
        
        const SizedBox(height: AppSizes.gapL),
        
        // 카테고리별 알림
        _buildSectionTitle(context, '카테고리별 알림'),
        const SizedBox(height: AppSizes.gapS),
        MingrrCard(
          margin: EdgeInsets.zero,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _NotificationToggleTile(
                icon: Icons.favorite,
                iconColor: context.features.dating,
                title: '데이팅 알림',
                subtitle: '매칭, 좋아요, 데이팅 신청',
                value: settings.datingEnabled,
                enabled: settings.allEnabled,
                onChanged: (value) => notifier.toggleSetting('datingEnabled', value, settings),
                showDivider: true,
              ),
              _NotificationToggleTile(
                icon: Icons.shopping_bag,
                iconColor: context.features.market,
                title: '마켓 알림',
                subtitle: '상품 문의, 거래 상태 변경',
                value: settings.marketEnabled,
                enabled: settings.allEnabled,
                onChanged: (value) => notifier.toggleSetting('marketEnabled', value, settings),
                showDivider: true,
              ),
              _NotificationToggleTile(
                icon: Icons.chat_bubble,
                iconColor: context.features.chat,
                title: '채팅 알림',
                subtitle: '새 메시지',
                value: settings.chatEnabled,
                enabled: settings.allEnabled,
                onChanged: (value) => notifier.toggleSetting('chatEnabled', value, settings),
                showDivider: true,
              ),
              _NotificationToggleTile(
                icon: Icons.groups,
                iconColor: context.features.social,
                title: '소모임 알림',
                subtitle: '일정, 공지, 멤버 활동',
                value: settings.groupEnabled,
                enabled: settings.allEnabled,
                onChanged: (value) => notifier.toggleSetting('groupEnabled', value, settings),
                showDivider: true,
              ),
              _NotificationToggleTile(
                icon: Icons.article,
                iconColor: context.features.social,
                title: '커뮤니티 알림',
                subtitle: '댓글, 좋아요',
                value: settings.communityEnabled,
                enabled: settings.allEnabled,
                onChanged: (value) => notifier.toggleSetting('communityEnabled', value, settings),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: AppSizes.gapL),
        
        // 야간 방해금지
        _buildSectionTitle(context, '방해금지'),
        const SizedBox(height: AppSizes.gapS),
        MingrrCard(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              _NotificationToggleTile(
                icon: Icons.nightlight_round,
                iconColor: Colors.indigo,
                title: '야간 방해금지',
                subtitle: '${settings.nightModeStart} ~ ${settings.nightModeEnd}',
                value: settings.nightModeEnabled,
                onChanged: (value) => notifier.toggleSetting('nightModeEnabled', value, settings),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: AppSizes.gapL),
        
        // 마케팅 알림
        _buildSectionTitle(context, '마케팅'),
        const SizedBox(height: AppSizes.gapS),
        MingrrCard(
          margin: EdgeInsets.zero,
          child: _NotificationToggleTile(
            icon: Icons.campaign,
            iconColor: Colors.orange,
            title: '마케팅 알림',
            subtitle: '이벤트, 프로모션, 혜택 정보',
            value: settings.marketingEnabled,
            onChanged: (value) => notifier.toggleSetting('marketingEnabled', value, settings),
          ),
        ),
        
        const SizedBox(height: AppSizes.gapXL),
        
        // 안내 문구
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingS),
          child: Text(
            '알림 설정은 기기의 알림 설정에 따라 달라질 수 있습니다.\n기기 설정에서 앱 알림이 허용되어 있는지 확인해주세요.',
            style: AppTextStyles.caption(context).withColor(colorScheme.outline),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
  
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSizes.paddingXS),
      child: Text(
        title,
        style: AppTextStyles.labelLarge(context).withColor(
          Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// 알림 토글 타일
class _NotificationToggleTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;
  final bool showDivider;

  const _NotificationToggleTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    this.enabled = true,
    required this.onChanged,
    this.showDivider = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveOpacity = enabled ? 1.0 : 0.5;
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSizes.paddingM),
          child: Row(
            children: [
              // 아이콘
              Opacity(
                opacity: effectiveOpacity,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: AppOpacity.o10),
                    borderRadius: BorderRadius.circular(AppSizes.radiusS),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
              ),
              const SizedBox(width: AppSizes.gapM),
              
              // 텍스트
              Expanded(
                child: Opacity(
                  opacity: effectiveOpacity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.titleMedium(context).withWeight(FontWeight.w500),
                      ),
                      const SizedBox(height: AppSizes.gapXXS),
                      Text(
                        subtitle,
                        style: AppTextStyles.bodySmall(context).withColor(colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
              
              // 스위치
              Switch.adaptive(
                value: value && enabled,
                onChanged: enabled ? onChanged : null,
                activeColor: colorScheme.primary,
              ),
            ],
          ),
        ),
        if (showDivider)
          const MingrrDivider(indent: 68),
      ],
    );
  }
}
