import 'package:flutter/material.dart';
import '../../constants/app_icons.dart';
import '../../constants/app_sizes.dart';
import '../../theme/app_text_styles.dart';
import '../common_widgets.dart';

/// ============================================================
/// InfoDialog - 정보성 안내 팝업
/// 
/// 귀엽고 예쁜 디자인의 정보 안내용 다이얼로그
/// 반려동물 크기 안내, 꼬순내지수 안내 등 정보성 데이터 표시에 사용
/// 
/// 사용법:
/// ```dart
/// // 1. 기본 사용 (리스트 아이템)
/// showInfoDialog(
///   context,
///   title: '반려동물 크기 안내',
///   icon: Icons.pets,
///   accentColor: context.features.dating,
///   items: [
///     InfoItem(label: '초소형', value: '0~4kg', description: '치와와, 요크셔테리어 등'),
///     InfoItem(label: '소형', value: '4~10kg', description: '말티즈, 푸들 등'),
///   ],
/// );
/// 
/// // 2. 커스텀 콘텐츠 사용
/// showInfoDialog(
///   context,
///   title: '꼬순내지수란?',
///   icon: Icons.favorite,
///   accentColor: Theme.of(context).colorScheme.primary,
///   customContent: MyCustomWidget(),
/// );
/// ```
/// ============================================================

/// 정보 아이템 데이터 클래스
class InfoItem {
  final String label;
  final String? value;
  final String? description;
  final IconData? icon;
  final Color? color;
  final Widget? trailing;

  const InfoItem({
    required this.label,
    this.value,
    this.description,
    this.icon,
    this.color,
    this.trailing,
  });
}

/// 정보성 다이얼로그 표시 함수
void showInfoDialog(
  BuildContext context, {
  required String title,
  IconData? icon,
  String? subtitle,
  Color? accentColor,
  List<InfoItem>? items,
  Widget? customContent,
  String? footerText,
  String confirmText = '확인',
}) {
  final color = accentColor ?? Theme.of(context).colorScheme.primary;
  
  showDialog(
    context: context,
    builder: (context) => InfoDialog(
      title: title,
      icon: icon,
      subtitle: subtitle,
      accentColor: color,
      items: items,
      customContent: customContent,
      footerText: footerText,
      confirmText: confirmText,
    ),
  );
}

/// 정보성 다이얼로그 위젯
class InfoDialog extends StatelessWidget {
  final String title;
  final IconData? icon;
  final String? subtitle;
  final Color accentColor;
  final List<InfoItem>? items;
  final Widget? customContent;
  final String? footerText;
  final String confirmText;

  const InfoDialog({
    super.key,
    required this.title,
    this.icon,
    this.subtitle,
    required this.accentColor,
    this.items,
    this.customContent,
    this.footerText,
    this.confirmText = '확인',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusXL)),
      elevation: AppSizes.elevationM,
      backgroundColor: colorScheme.surface,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSizes.radiusXL),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              accentColor.withValues(alpha: isDark ? AppOpacity.o15 : AppOpacity.o10),
              isDark ? colorScheme.surface : Colors.white,
            ],
            stops: const [0.0, 0.3],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더 영역
            _buildHeader(context),
            
            // 콘텐츠 영역
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingXL),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (customContent != null)
                      customContent!
                    else if (items != null && items!.isNotEmpty)
                      _buildItemsList(context),
                  ],
                ),
              ),
            ),
            
            // 푸터 영역
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  /// 헤더 영역 (아이콘 + 제목)
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSizes.paddingL, 24, 20, 16),
      child: Column(
        children: [
          // 아이콘 (귀여운 원형 배경)
          if (icon != null)
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: AppOpacity.o15),
                shape: BoxShape.circle,
                boxShadow: AppShadows.shadowM(Theme.of(context).brightness == Brightness.dark),
              ),
              child: Icon(icon, color: accentColor, size: 28),
            ),
          
          if (icon != null) const SizedBox(height: AppSizes.gapL),
          
          // 제목
          Text(
            title,
            style: AppTextStyles.headlineMedium(context).withWeight(FontWeight.w700).withColor(accentColor),
            textAlign: TextAlign.center,
          ),
          
          // 부제목
          if (subtitle != null) ...[
            const SizedBox(height: AppSizes.gapSM),
            Text(
              subtitle!,
              style: AppTextStyles.bodyMedium(context).withColor(Theme.of(context).colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  /// 아이템 리스트
  Widget _buildItemsList(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: items!.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final isLast = index == items!.length - 1;
        
        return _buildInfoItem(context, item, isLast);
      }).toList(),
    );
  }

  /// 개별 정보 아이템
  Widget _buildInfoItem(BuildContext context, InfoItem item, bool isLast) {
    final itemColor = item.color ?? accentColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 10),
      padding: const EdgeInsets.all(AppSizes.paddingM),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHighest : Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusS),
        border: Border.all(
          color: itemColor.withValues(alpha: isDark ? AppOpacity.o30 : AppOpacity.o15),
          width: 1,
        ),
        boxShadow: isDark ? null : AppShadows.shadowS(false),
      ),
      child: Row(
        children: [
          // 라벨 뱃지
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingS, vertical: AppSizes.paddingXS),
            decoration: BoxDecoration(
              color: itemColor.withValues(alpha: AppOpacity.o10),
              borderRadius: BorderRadius.circular(AppSizes.radiusS),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (item.icon != null) ...[
                  Icon(item.icon, size: 14, color: itemColor),
                  const SizedBox(width: AppSizes.gapXS),
                ],
                Text(
                  item.label,
                  style: AppTextStyles.labelLarge(context).withWeight(FontWeight.w600).withColor(itemColor),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: AppSizes.gapM),
          
          // 값 + 설명
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.value != null)
                  Text(
                    item.value!,
                    style: AppTextStyles.titleMedium(context).withWeight(FontWeight.w600),
                  ),
                if (item.description != null) ...[
                  if (item.value != null) const SizedBox(height: AppSizes.gapXXS),
                  Text(
                    item.description!,
                    style: AppTextStyles.caption(context),
                  ),
                ],
              ],
            ),
          ),
          
          // 트레일링 위젯
          if (item.trailing != null) item.trailing!,
        ],
      ),
    );
  }

  /// 푸터 영역 (확인 버튼)
  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSizes.paddingL, 16, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 푸터 텍스트
          if (footerText != null) ...[
            Container(
              padding: const EdgeInsets.all(AppSizes.paddingM),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: AppOpacity.o05),
                borderRadius: BorderRadius.circular(AppSizes.radiusS),
              ),
              child: Row(
                children: [
                  Icon(AppIcons.lightbulb, size: 16, color: accentColor),
                  const SizedBox(width: AppSizes.gapS),
                  Expanded(
                    child: Text(
                      footerText!,
                      style: AppTextStyles.bodySmall(context).withColor(Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.gapL),
          ],
          
          // 확인 버튼
          MingrrButton(
            text: confirmText,
            onPressed: () => Navigator.pop(context),
            backgroundColor: accentColor,
            textColor: Colors.white,
            height: 48,
          ),
        ],
      ),
    );
  }
}
