import 'package:flutter/material.dart';
import '../constants/app_sizes.dart';
import '../theme/app_text_styles.dart';
import '../theme/feature_colors.dart';

/// ============================================================
/// MINGRR 기록 아이템 타일 컴포넌트
/// 
/// 건강수첩 등에서 기록 목록을 표시할 때 사용합니다.
/// 
/// 사용처:
/// - health_screen.dart (체중, 산책, 미용, 예방접종, 검진, 투약)
/// 
/// 사용 예시:
/// ```dart
/// MingrrRecordTile(
///   icon: Icons.monitor_weight_outlined,
///   iconColor: context.features.health,
///   title: '5.2kg',
///   subtitle: '1/15',
///   onTap: () => _showDetail(),
/// )
/// 
/// MingrrRecordTile.medication(
///   iconColor: Colors.blue,
///   title: '심장약',
///   subtitle: '1정 • 매일 1회',
///   isActive: true,
///   onTap: () => _showDetail(),
/// )
/// ```
/// ============================================================

class MingrrRecordTile extends StatelessWidget {
  /// 아이콘
  final IconData icon;
  
  /// 아이콘 색상
  final Color? iconColor;
  
  /// 제목
  final String title;
  
  /// 부제목
  final String subtitle;
  
  /// 오른쪽 위젯 (선택)
  final Widget? trailing;
  
  /// 클릭 콜백
  final VoidCallback onTap;
  
  /// 화살표 표시 여부
  final bool showChevron;

  const MingrrRecordTile({
    super.key,
    required this.icon,
    this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
    required this.onTap,
    this.showChevron = true,
  });

  /// 투약 기록용 타일 (상태 배지 포함)
  factory MingrrRecordTile.medication({
    Key? key,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return MingrrRecordTile(
      key: key,
      icon: Icons.medication,
      iconColor: iconColor,
      title: title,
      subtitle: subtitle,
      trailing: MingrrRecordStatusBadge(
        text: isActive ? '복용 중' : '완료',
        isActive: isActive,
      ),
      onTap: onTap,
      showChevron: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? context.features.health;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSizes.paddingS),
        padding: const EdgeInsets.all(AppSizes.paddingM),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusS),
          border: Border.all(color: Theme.of(context).colorScheme.outline),
        ),
        child: Row(
          children: [
            // 아이콘
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusXS),
              ),
              child: Icon(icon, size: 22, color: color),
            ),
            const SizedBox(width: AppSizes.gapM),
            
            // 제목 + 부제목
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.labelLarge(context),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            
            // Trailing
            if (trailing != null) trailing!,
            
            // 화살표
            if (showChevron)
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
          ],
        ),
      ),
    );
  }
}

/// 기록 상태 배지 (복용 중, 완료 등)
class MingrrRecordStatusBadge extends StatelessWidget {
  final String text;
  final bool isActive;
  final Color? activeColor;

  const MingrrRecordStatusBadge({
    super.key,
    required this.text,
    required this.isActive,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive 
        ? (activeColor ?? context.features.success)
        : Theme.of(context).colorScheme.outlineVariant;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingS, vertical: AppSizes.paddingXXS),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusS),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: color,
        ),
      ),
    );
  }
}
