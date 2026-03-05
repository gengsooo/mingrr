import 'package:flutter/material.dart';
import '../../constants/app_icons.dart';
import '../../constants/app_sizes.dart';
import '../../theme/app_text_styles.dart';
import 'dialog_buttons.dart';

/// ============================================================
/// MingrrSelectionDialog - 선택 다이얼로그
/// 
/// 라디오 버튼으로 옵션을 선택하는 공통 다이얼로그
/// 신고, 카테고리 선택 등에 사용
/// 
/// 사용법:
/// ```dart
/// final reason = await showSelectionDialog(
///   context,
///   title: '신고하기',
///   subtitle: '신고 사유를 선택해주세요',
///   options: ['욕설/비방', '사기/허위정보', '노쇼', '부적절한 행동', '기타'],
///   confirmText: '신고',
///   confirmColor: Colors.red,
/// );
/// if (reason != null) { /* 선택된 옵션 처리 */ }
/// ```
/// ============================================================

/// 선택 다이얼로그 표시 함수
Future<String?> showSelectionDialog(
  BuildContext context, {
  required String title,
  String? subtitle,
  required List<String> options,
  String confirmText = '확인',
  String cancelText = '취소',
  Color? confirmColor,
  IconData? icon,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => MingrrSelectionDialog(
      title: title,
      subtitle: subtitle,
      options: options,
      confirmText: confirmText,
      cancelText: cancelText,
      confirmColor: confirmColor,
      icon: icon,
    ),
  );
}

/// MingrrSelectionDialog 위젯
class MingrrSelectionDialog extends StatefulWidget {
  final String title;
  final String? subtitle;
  final List<String> options;
  final String confirmText;
  final String cancelText;
  final Color? confirmColor;
  final IconData? icon;

  const MingrrSelectionDialog({
    super.key,
    required this.title,
    this.subtitle,
    required this.options,
    this.confirmText = '확인',
    this.cancelText = '취소',
    this.confirmColor,
    this.icon,
  });

  @override
  State<MingrrSelectionDialog> createState() => _MingrrSelectionDialogState();
}

class _MingrrSelectionDialogState extends State<MingrrSelectionDialog> {
  String? _selectedOption;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final confirmColor = widget.confirmColor ?? colorScheme.primary;
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: confirmColor, size: 24),
                  const SizedBox(width: AppSizes.gapS),
                ],
                Expanded(
                  child: Text(
                    widget.title,
                    style: AppTextStyles.headlineMedium(context).withWeight(FontWeight.w600),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(
                    AppIcons.close,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            
            // 서브타이틀
            if (widget.subtitle != null) ...[
              const SizedBox(height: AppSizes.gapS),
              Text(
                widget.subtitle!,
                style: AppTextStyles.bodyLarge(context).withColor(colorScheme.onSurfaceVariant),
              ),
            ],
            
            const SizedBox(height: AppSizes.gapM),
            
            // 옵션 리스트
            RadioGroup<String>(
              groupValue: _selectedOption,
              onChanged: (value) => setState(() => _selectedOption = value),
              child: Column(
                children: widget.options.map((option) => RadioListTile<String>(
                  title: Text(option),
                  value: option,
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  activeColor: confirmColor,
                )).toList(),
              ),
            ),
            
            const SizedBox(height: AppSizes.gapM),
            
            // 버튼
            MingrrDialogButtons(
              cancelText: widget.cancelText,
              confirmText: widget.confirmText,
              onCancel: () => Navigator.pop(context),
              onConfirm: _selectedOption == null 
                  ? null 
                  : () => Navigator.pop(context, _selectedOption),
              confirmColor: confirmColor,
              height: 44,
            ),
          ],
        ),
      ),
    );
  }
}
