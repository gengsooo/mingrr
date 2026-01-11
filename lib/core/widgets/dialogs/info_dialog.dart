import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

/// ============================================================
/// InfoDialog - 정보성 안내 팝업
/// 
/// 귀엽고 예쁜 디자인의 정보 안내용 다이얼로그
/// 강아지 크기 안내, 꼬순내지수 안내 등 정보성 데이터 표시에 사용
/// 
/// 사용법:
/// ```dart
/// // 1. 기본 사용 (리스트 아이템)
/// showInfoDialog(
///   context,
///   title: '강아지 크기 안내',
///   icon: Icons.pets,
///   accentColor: AppColors.dating,
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
///   accentColor: AppColors.primary,
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
  final color = accentColor ?? AppColors.primary;
  
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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 8,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              accentColor.withOpacity(0.08),
              Colors.white,
            ],
            stops: const [0.0, 0.3],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더 영역
            _buildHeader(),
            
            // 콘텐츠 영역
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (customContent != null)
                      customContent!
                    else if (items != null && items!.isNotEmpty)
                      _buildItemsList(),
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
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Column(
        children: [
          // 아이콘 (귀여운 원형 배경)
          if (icon != null)
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.15),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: accentColor, size: 28),
            ),
          
          if (icon != null) const SizedBox(height: 16),
          
          // 제목
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: accentColor,
            ),
            textAlign: TextAlign.center,
          ),
          
          // 부제목
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  /// 아이템 리스트
  Widget _buildItemsList() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: items!.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final isLast = index == items!.length - 1;
        
        return _buildInfoItem(item, isLast);
      }).toList(),
    );
  }

  /// 개별 정보 아이템
  Widget _buildInfoItem(InfoItem item, bool isLast) {
    final itemColor = item.color ?? accentColor;
    
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: itemColor.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 라벨 뱃지
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: itemColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (item.icon != null) ...[
                  Icon(item.icon, size: 14, color: itemColor),
                  const SizedBox(width: 4),
                ],
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: itemColor,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 12),
          
          // 값 + 설명
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.value != null)
                  Text(
                    item.value!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                if (item.description != null) ...[
                  if (item.value != null) const SizedBox(height: 2),
                  Text(
                    item.description!,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 푸터 텍스트
          if (footerText != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, size: 16, color: accentColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      footerText!,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // 확인 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                confirmText,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
