import 'package:flutter/material.dart';
import '../../constants/app_sizes.dart';

// ===== 공통 메모 입력 필드 =====
/// 메모 입력 위젯 (바텀시트, 폼 등에서 사용)
class MingrrMemoField extends StatelessWidget {
  final TextEditingController controller;
  final String? hint;
  final int maxLines;

  const MingrrMemoField({
    super.key,
    required this.controller,
    this.hint,
    this.maxLines = 3,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint ?? '메모를 입력하세요',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.radiusS)),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
    );
  }
}
