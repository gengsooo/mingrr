import 'package:flutter/material.dart';
import '../../constants/app_sizes.dart';
import '../../theme/app_text_styles.dart';

// ===== 공통 라벨 위젯 =====
/// 폼 필드 라벨 위젯
class MingrrLabel extends StatelessWidget {
  final String text;
  final bool isRequired;

  const MingrrLabel(this.text, {super.key, this.isRequired = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.paddingS),
      child: Text(
        isRequired ? '$text *' : text,
        style: AppTextStyles.labelLarge(context),
      ),
    );
  }
}
