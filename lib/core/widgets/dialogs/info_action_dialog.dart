import 'package:flutter/material.dart';
import '../../constants/app_sizes.dart';
import '../common_widgets.dart';

/// ============================================================
/// MingrrInfoActionDialog - 정보 표시 + 확인 다이얼로그
/// 
/// 아이콘 + 제목 + 메시지 + 정보 박스(들) + 2버튼 구조의 공통 다이얼로그
/// 위치 인증, 동네 변경 등 정보를 보여주고 확인받는 경우에 사용
/// 
/// 사용법:
/// ```dart
/// final result = await showInfoActionDialog(
///   context,
///   icon: Icons.location_on,
///   iconColor: colorScheme.primary,
///   title: '위치 인증',
///   message: '현재 위치를 내 동네로 등록하시겠습니까?',
///   infoBoxes: [
///     InfoBoxItem(
///       icon: Icons.my_location,
///       content: '서울시 강남구 역삼동',
///     ),
///   ],
///   confirmText: '인증하기',
/// );
/// if (result == true) { /* 확인 처리 */ }
/// ```
/// ============================================================

/// 정보 박스 아이템
class InfoBoxItem {
  final IconData icon;
  final String? label;      // '현재 위치', '저장된 동네' 등
  final String content;     // 실제 주소
  final String? subtitle;   // '저장된 위치에서 300m' 등
  final Color? color;       // 아이콘/라벨 색상 (null이면 기본색)
  final bool isPrimary;     // true면 강조 색상 사용

  const InfoBoxItem({
    required this.icon,
    this.label,
    required this.content,
    this.subtitle,
    this.color,
    this.isPrimary = true,
  });
}

/// 정보 액션 다이얼로그 표시 함수
Future<bool?> showInfoActionDialog(
  BuildContext context, {
  required IconData icon,
  required Color iconColor,
  required String title,
  required String message,
  List<InfoBoxItem>? infoBoxes,
  String confirmText = '확인',
  String cancelText = '취소',
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => MingrrInfoActionDialog(
      icon: icon,
      iconColor: iconColor,
      title: title,
      message: message,
      infoBoxes: infoBoxes,
      confirmText: confirmText,
      cancelText: cancelText,
    ),
  );
}

/// MingrrInfoActionDialog 위젯
class MingrrInfoActionDialog extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final List<InfoBoxItem>? infoBoxes;
  final String confirmText;
  final String cancelText;

  const MingrrInfoActionDialog({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    this.infoBoxes,
    this.confirmText = '확인',
    this.cancelText = '취소',
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Dialog(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingXXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 아이콘
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: iconColor),
            ),
            const SizedBox(height: AppSizes.gapL),
            
            // 제목
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSizes.gapS),
            
            // 메시지
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            
            // 정보 박스들
            if (infoBoxes != null && infoBoxes!.isNotEmpty) ...[
              const SizedBox(height: AppSizes.gapL),
              ...infoBoxes!.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.paddingS),
                child: _buildInfoBox(context, item),
              )),
            ],
            
            const SizedBox(height: AppSizes.gapLL),
            
            // 버튼
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingM),
                      side: BorderSide(color: colorScheme.outline),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusS),
                      ),
                    ),
                    child: Text(
                      cancelText,
                      style: TextStyle(
                        fontSize: 15,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.gapM),
                Expanded(
                  child: MingrrButton(
                    text: confirmText,
                    onPressed: () => Navigator.pop(context, true),
                    backgroundColor: iconColor,
                    textColor: Colors.white,
                    height: 48,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBox(BuildContext context, InfoBoxItem item) {
    final colorScheme = Theme.of(context).colorScheme;
    final boxColor = item.color ?? (item.isPrimary ? iconColor : colorScheme.outline);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.paddingM),
      decoration: BoxDecoration(
        color: boxColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSizes.radiusS),
      ),
      child: Row(
        children: [
          Icon(item.icon, color: boxColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.label != null)
                  Text(
                    item.label!,
                    style: TextStyle(
                      fontSize: 11,
                      color: item.isPrimary ? boxColor : colorScheme.onSurfaceVariant,
                    ),
                  ),
                Text(
                  item.content,
                  style: TextStyle(
                    fontSize: item.label != null ? 13 : 14,
                    fontWeight: item.label != null ? FontWeight.w500 : FontWeight.normal,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (item.subtitle != null)
                  Text(
                    item.subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      color: boxColor,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
