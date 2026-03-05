import 'package:flutter/material.dart';
import '../../constants/app_icons.dart';
import '../../constants/app_sizes.dart';
import '../../theme/app_text_styles.dart';
import '../common_widgets.dart';

/// ============================================================
/// 찜 버튼 공통 컴포넌트
/// 
/// 마켓플레이스(상품, 알바)에서 사용하는 통일된 찜 버튼
/// - 아이콘 + 카운트 표시
/// - 로딩 상태 지원
/// - 터치 영역 확보 (최소 48x48)
/// ============================================================
class WishlistButton extends StatelessWidget {
  final bool isWishlisted;
  final bool isLoading;
  final int count;
  final VoidCallback? onTap;
  final Color? activeColor;

  const WishlistButton({
    super.key,
    required this.isWishlisted,
    this.isLoading = false,
    this.count = 0,
    this.onTap,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = activeColor ?? Theme.of(context).colorScheme.primary;
    
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        height: 56,
        child: isLoading
            ? const Center(child: MingrrLoadingIndicator.small())
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isWishlisted ? AppIcons.bookmark : AppIcons.bookmarkOutlined,
                    color: isWishlisted 
                        ? color 
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                  const SizedBox(height: AppSizes.gapXXS),
                  Text(
                    '$count',
                    style: AppTextStyles.caption(context).copyWith(
                      color: isWishlisted 
                          ? color 
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
