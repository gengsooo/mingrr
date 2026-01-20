import 'package:flutter/material.dart';
import '../constants/app_sizes.dart';

/// ============================================================
/// MINGRR 설정 메뉴 타일 컴포넌트
/// 
/// 설정 화면에서 통일된 메뉴 아이템 스타일을 제공합니다.
/// 
/// 사용처:
/// - account_settings_screen.dart
/// - app_settings_screen.dart
/// - customer_service_screen.dart
/// - app_info_screen.dart
/// 
/// 사용 예시:
/// ```dart
/// MingrrSettingsTile(
///   icon: Icons.email_outlined,
///   title: '이메일',
///   subtitle: 'user@example.com',
///   onTap: () => _editEmail(),
/// )
/// 
/// MingrrSettingsTile.destructive(
///   icon: Icons.logout,
///   title: '로그아웃',
///   onTap: () => _logout(),
/// )
/// ```
/// ============================================================

class MingrrSettingsTile extends StatelessWidget {
  /// 아이콘
  final IconData icon;
  
  /// 제목
  final String title;
  
  /// 부제목 (선택)
  final String? subtitle;
  
  /// 오른쪽 위젯 (선택, 기본: 화살표)
  final Widget? trailing;
  
  /// 클릭 콜백
  final VoidCallback? onTap;
  
  /// 아이콘 색상 (선택)
  final Color? iconColor;
  
  /// 아이콘 배경색 (선택)
  final Color? iconBackgroundColor;
  
  /// 위험 동작 여부 (로그아웃, 탈퇴 등 - 빨간색)
  final bool isDestructive;
  
  /// 화살표 표시 여부
  final bool showChevron;
  
  /// 비활성화 여부
  final bool isDisabled;

  const MingrrSettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor,
    this.iconBackgroundColor,
    this.isDestructive = false,
    this.showChevron = true,
    this.isDisabled = false,
  });

  /// 위험 동작용 타일 (로그아웃, 탈퇴 등)
  factory MingrrSettingsTile.destructive({
    Key? key,
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    bool showChevron = false,
  }) {
    return MingrrSettingsTile(
      key: key,
      icon: icon,
      title: title,
      subtitle: subtitle,
      onTap: onTap,
      isDestructive: true,
      showChevron: showChevron,
    );
  }

  /// 토글 스위치가 있는 타일
  factory MingrrSettingsTile.toggle({
    Key? key,
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    Color? iconColor,
  }) {
    return MingrrSettingsTile(
      key: key,
      icon: icon,
      title: title,
      subtitle: subtitle,
      iconColor: iconColor,
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
      ),
      showChevron: false,
    );
  }

  /// 라디오 선택 타일 (테마 모드 등)
  factory MingrrSettingsTile.radio({
    Key? key,
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return MingrrSettingsTile(
      key: key,
      icon: icon,
      title: title,
      onTap: onTap,
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: Colors.green, size: 22)
          : const Icon(Icons.circle_outlined, color: Colors.grey, size: 22),
      showChevron: false,
    );
  }

  /// 배지가 있는 타일 (프로필 메뉴 등)
  factory MingrrSettingsTile.badge({
    Key? key,
    required IconData icon,
    required String title,
    String? badgeText,
    Color? badgeColor,
    required VoidCallback onTap,
  }) {
    return MingrrSettingsTile(
      key: key,
      icon: icon,
      title: title,
      iconColor: Colors.grey,
      iconBackgroundColor: Colors.transparent,
      onTap: onTap,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badgeText != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingS, vertical: AppSizes.paddingXXS),
              decoration: BoxDecoration(
                color: badgeColor ?? Colors.orange,
                borderRadius: BorderRadius.circular(AppSizes.radiusS),
              ),
              child: Text(
                badgeText,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(width: AppSizes.gapXS),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
      showChevron: false,
    );
  }

  /// 연결 상태 표시 타일 (소셜 로그인 등)
  factory MingrrSettingsTile.connection({
    Key? key,
    required IconData icon,
    required String title,
    required bool isConnected,
    String? connectedText,
    String? disconnectedText,
    VoidCallback? onTap,
    Color? iconColor,
  }) {
    return MingrrSettingsTile(
      key: key,
      icon: icon,
      title: title,
      subtitle: isConnected 
          ? (connectedText ?? '연동됨') 
          : (disconnectedText ?? '연동되지 않음'),
      iconColor: iconColor,
      onTap: onTap,
      trailing: isConnected
          ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // 색상 결정
    final Color effectiveIconColor;
    final Color effectiveIconBgColor;
    final Color effectiveTitleColor;
    
    if (isDestructive) {
      effectiveIconColor = Colors.red;
      effectiveIconBgColor = Colors.red.withValues(alpha: 0.1);
      effectiveTitleColor = Colors.red;
    } else if (isDisabled) {
      effectiveIconColor = colorScheme.outlineVariant;
      effectiveIconBgColor = colorScheme.outlineVariant.withValues(alpha: 0.1);
      effectiveTitleColor = colorScheme.outlineVariant;
    } else {
      effectiveIconColor = iconColor ?? colorScheme.primary;
      effectiveIconBgColor = iconBackgroundColor ?? effectiveIconColor.withValues(alpha: 0.1);
      effectiveTitleColor = colorScheme.onSurface;
    }
    
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: effectiveIconBgColor,
          borderRadius: BorderRadius.circular(AppSizes.radiusS),
        ),
        child: Icon(
          icon,
          color: effectiveIconColor,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: effectiveTitleColor,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            )
          : null,
      trailing: trailing ?? (showChevron
          ? Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant)
          : null),
      onTap: isDisabled ? null : onTap,
    );
  }
}

/// 설정 섹션 헤더
class MingrrSettingsSection extends StatelessWidget {
  /// 섹션 제목
  final String title;
  
  /// 섹션 내 타일들
  final List<Widget> children;
  
  /// 상단 여백
  final double topPadding;

  const MingrrSettingsSection({
    super.key,
    required this.title,
    required this.children,
    this.topPadding = AppSizes.gapL,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: topPadding),
        Padding(
          padding: const EdgeInsets.only(bottom: AppSizes.gapS),
          child: Text(
            title,
            style: theme.textTheme.titleLarge,
          ),
        ),
        ...children,
      ],
    );
  }
}
