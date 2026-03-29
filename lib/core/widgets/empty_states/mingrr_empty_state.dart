import 'package:flutter/material.dart';
import '../../constants/app_sizes.dart';
import '../../theme/app_text_styles.dart';

// ===== 빈 상태 위젯 =====
/// 데이터가 없을 때 표시하는 위젯
/// 
/// 디자인 기준: 데이팅-추천친구 빈 상태
/// - 아이콘: 48px, outlineVariant 색상
/// - 제목: 기본 크기, onSurfaceVariant, w500
/// - 부제목: 12px, outlineVariant
/// - 간격: 아이콘-제목 16px, 제목-부제목 8px, 부제목-버튼 16px
/// - 버튼: 180px 너비, accentColor 배경
/// - onRefresh: pull-to-refresh 지원 (선택)
/// 
/// 접근성: 스크린 리더가 제목과 부제목을 읽어줌
class MingrrEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  final Color? accentColor;
  final Future<void> Function()? onRefresh;

  const MingrrEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.buttonText,
    this.onButtonPressed,
    this.accentColor,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    final content = Semantics(
      label: '$title${subtitle != null ? ', $subtitle' : ''}',
      child: CustomScrollView(
      physics: onRefresh != null 
          ? const AlwaysScrollableScrollPhysics() 
          : const NeverScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 아이콘
                Icon(icon, size: 48, color: colorScheme.outlineVariant),
                const SizedBox(height: AppSizes.gapL),
                // 제목
                Text(
                  title,
                  style: AppTextStyles.bodyLarge(context).withWeight(FontWeight.w500).withColor(colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                // 부제목
                if (subtitle != null) ...[
                  const SizedBox(height: AppSizes.gapS),
                  Text(
                    subtitle!,
                    style: AppTextStyles.bodySmall(context).withColor(colorScheme.outlineVariant),
                    textAlign: TextAlign.center,
                  ),
                ],
                // 버튼
                if (buttonText != null && onButtonPressed != null) ...[
                  const SizedBox(height: AppSizes.gapL),
                  SizedBox(
                    width: 180,
                    child: ElevatedButton(
                      onPressed: onButtonPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor ?? colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(buttonText!),
                    ),
                  ),
                ],
                // 새로고침 힌트
                if (onRefresh != null) ...[
                  const SizedBox(height: AppSizes.gapXL),
                  Text(
                    '아래로 당겨서 새로고침',
                    style: AppTextStyles.caption(context).withColor(colorScheme.outlineVariant),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    ),
    );
    
    if (onRefresh != null) {
      return RefreshIndicator(
        onRefresh: onRefresh!,
        color: accentColor ?? colorScheme.primary,
        child: content,
      );
    }
    
    return content;
  }
}

// ===== 섹션 내 빈 상태 위젯 =====
/// 섹션 내에서 데이터가 없을 때 표시하는 작은 빈 상태 위젯
/// 
/// 사용처:
/// - 프로필 모달 > 사진 갤러리 (사진 없음)
/// - 프로필 모달 > 성격&특성 (특성 없음)
/// - 프로필 모달 > 소개 (소개 없음)
class MingrrEmptySection extends StatelessWidget {
  final IconData icon;
  final String message;
  final double height;

  const MingrrEmptySection({
    super.key,
    required this.icon,
    required this.message,
    this.height = 80,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: AppOpacity.o30),
        borderRadius: BorderRadius.circular(AppSizes.radiusS),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: AppOpacity.o20),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: colorScheme.outlineVariant,
            ),
            const SizedBox(height: AppSizes.gapXS),
            Text(
              message,
              style: AppTextStyles.bodySmall(context).withColor(colorScheme.outlineVariant),
            ),
          ],
        ),
      ),
    );
  }
}
