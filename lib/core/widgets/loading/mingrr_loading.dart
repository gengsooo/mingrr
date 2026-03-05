import 'package:flutter/material.dart';
import '../../constants/app_sizes.dart';
import '../../theme/app_text_styles.dart';
import 'loading_widgets.dart' show MingrrLoadingIndicator;

// ===== 로딩 인디케이터 =====
/// 앱 스타일에 맞는 로딩 표시
class MingrrLoading extends StatelessWidget {
  final String? message;
  final double size;

  const MingrrLoading({
    super.key,
    this.message,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          MingrrLoadingIndicator(
            size: size,
            strokeWidth: 3,
            customColor: Theme.of(context).colorScheme.primary,
          ),
          if (message != null) ...[
            const SizedBox(height: AppSizes.gapM),
            Text(
              message!,
              style: AppTextStyles.bodyLarge(context).withColor(Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}
