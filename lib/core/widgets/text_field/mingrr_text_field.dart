import 'dart:async';
import 'package:flutter/material.dart';
import '../../constants/app_icons.dart';
import '../../constants/app_sizes.dart';
import '../../theme/app_text_styles.dart';

// ===== 입력 필드 =====
/// 동글동글한 스타일의 텍스트 입력 필드
/// 
/// 실시간 검증 기능:
/// - `validateOnChange: true`로 설정하면 입력 시 즉시 검증
/// - `debounceMs`로 디바운스 시간 설정 (기본 300ms)
/// 
/// 사용 예시:
/// ```dart
/// MingrrTextField(
///   labelText: '이메일',
///   hintText: '이메일을 입력하세요',
///   validator: FormValidators.email(),
///   validateOnChange: true,
/// )
/// ```
class MingrrTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final int maxLines;
  final bool enabled;
  final FocusNode? focusNode;
  final bool validateOnChange;
  final int debounceMs;
  final String? initialValue;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;
  final int? maxLength;
  final bool showCounter;

  const MingrrTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
    this.enabled = true,
    this.focusNode,
    this.validateOnChange = false,
    this.debounceMs = 300,
    this.initialValue,
    this.textInputAction,
    this.onFieldSubmitted,
    this.maxLength,
    this.showCounter = false,
  });

  @override
  State<MingrrTextField> createState() => _MingrrTextFieldState();
}

class _MingrrTextFieldState extends State<MingrrTextField> {
  String? _errorText;
  Timer? _debounceTimer;
  late TextEditingController _controller;
  bool _hasInteracted = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant MingrrTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 외부 컨트롤러가 변경된 경우 업데이트
    if (widget.controller != oldWidget.controller) {
      if (widget.controller != null) {
        _controller = widget.controller!;
      }
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onChanged(String value) {
    widget.onChanged?.call(value);
    
    if (widget.validateOnChange && widget.validator != null) {
      _hasInteracted = true;
      _debounceTimer?.cancel();
      _debounceTimer = Timer(Duration(milliseconds: widget.debounceMs), () {
        if (mounted) {
          setState(() {
            _errorText = widget.validator!(value);
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasError = _errorText != null && _hasInteracted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.labelText != null) ...[
          Text(
            widget.labelText!,
            style: AppTextStyles.labelLarge(context),
          ),
          const SizedBox(height: AppSizes.gapS),
        ],
        TextFormField(
          controller: _controller,
          obscureText: widget.obscureText,
          keyboardType: widget.keyboardType,
          validator: widget.validator,
          onChanged: _onChanged,
          maxLines: widget.maxLines,
          enabled: widget.enabled,
          focusNode: widget.focusNode,
          textInputAction: widget.textInputAction,
          onFieldSubmitted: widget.onFieldSubmitted,
          maxLength: widget.maxLength,
          style: AppTextStyles.bodyMedium(context),
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: AppTextStyles.bodySmall(context).copyWith(
              color: colorScheme.outlineVariant,
            ),
            prefixIcon: widget.prefixIcon != null
                ? Icon(widget.prefixIcon, color: hasError ? colorScheme.error : colorScheme.outlineVariant)
                : null,
            suffixIcon: widget.suffixIcon ?? (hasError 
                ? Icon(AppIcons.error, color: colorScheme.error, size: 20)
                : null),
            errorText: _hasInteracted ? _errorText : null,
            counterText: widget.showCounter ? null : '',
          ),
        ),
      ],
    );
  }
}
