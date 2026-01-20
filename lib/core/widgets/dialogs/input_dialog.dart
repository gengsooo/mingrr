import 'package:flutter/material.dart';
import '../../constants/app_sizes.dart';
import '../common_widgets.dart';

/// ============================================================
/// MingrrInputDialog - 텍스트 입력 다이얼로그
/// 
/// 텍스트 입력을 받는 공통 다이얼로그
/// 닉네임 변경, 메모 입력 등에 사용
/// 
/// 사용법:
/// ```dart
/// final result = await showInputDialog(
///   context,
///   title: '닉네임 변경',
///   hintText: '새 닉네임을 입력해주세요',
///   initialValue: user.nickname,
///   maxLength: 10,
///   validator: (value) => value.isEmpty ? '닉네임을 입력해주세요' : null,
/// );
/// if (result != null) { /* 저장 */ }
/// ```
/// ============================================================

/// 입력 다이얼로그 표시 함수
Future<String?> showInputDialog(
  BuildContext context, {
  required String title,
  String? subtitle,
  String? hintText,
  String? initialValue,
  int? maxLength,
  String confirmText = '확인',
  String cancelText = '취소',
  Color? confirmColor,
  String? Function(String)? validator,
  TextInputType keyboardType = TextInputType.text,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => MingrrInputDialog(
      title: title,
      subtitle: subtitle,
      hintText: hintText,
      initialValue: initialValue,
      maxLength: maxLength,
      confirmText: confirmText,
      cancelText: cancelText,
      confirmColor: confirmColor,
      validator: validator,
      keyboardType: keyboardType,
    ),
  );
}

/// MingrrInputDialog 위젯
class MingrrInputDialog extends StatefulWidget {
  final String title;
  final String? subtitle;
  final String? hintText;
  final String? initialValue;
  final int? maxLength;
  final String confirmText;
  final String cancelText;
  final Color? confirmColor;
  final String? Function(String)? validator;
  final TextInputType keyboardType;

  const MingrrInputDialog({
    super.key,
    required this.title,
    this.subtitle,
    this.hintText,
    this.initialValue,
    this.maxLength,
    this.confirmText = '확인',
    this.cancelText = '취소',
    this.confirmColor,
    this.validator,
    this.keyboardType = TextInputType.text,
  });

  @override
  State<MingrrInputDialog> createState() => _MingrrInputDialogState();
}

class _MingrrInputDialogState extends State<MingrrInputDialog> {
  late TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _validate() {
    if (widget.validator != null) {
      setState(() {
        _errorText = widget.validator!(_controller.text);
      });
    }
  }

  void _submit() {
    _validate();
    if (_errorText == null) {
      Navigator.pop(context, _controller.text);
    }
  }

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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(
                    Icons.close,
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
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            
            const SizedBox(height: AppSizes.gapM),
            
            // 입력 필드
            TextField(
              controller: _controller,
              keyboardType: widget.keyboardType,
              maxLength: widget.maxLength,
              onChanged: (_) => _validate(),
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: colorScheme.outlineVariant,
                ),
                errorText: _errorText,
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusM),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusM),
                  borderSide: BorderSide(color: confirmColor, width: 1.5),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusM),
                  borderSide: const BorderSide(color: Colors.red, width: 1),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusM),
                  borderSide: const BorderSide(color: Colors.red, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                counterText: '',
              ),
              style: const TextStyle(fontSize: 14),
            ),
            
            const SizedBox(height: AppSizes.gapM),
            
            // 버튼
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusM),
                      ),
                    ),
                    child: Text(widget.cancelText),
                  ),
                ),
                const SizedBox(width: AppSizes.gapM),
                Expanded(
                  child: MingrrButton(
                    text: widget.confirmText,
                    onPressed: _submit,
                    backgroundColor: confirmColor,
                    textColor: Colors.white,
                    height: 44,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
