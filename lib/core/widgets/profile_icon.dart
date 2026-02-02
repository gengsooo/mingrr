import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_icons.dart';
import '../constants/app_sizes.dart';
import 'mingrr_image.dart';

/// ============================================================
/// 공통 프로필 버튼 위젯
/// 모든 화면 우측 상단에 표시 (홈 화면과 동일한 디자인)
/// ============================================================

class ProfileButton extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final Color? backgroundColor;

  const ProfileButton({
    super.key,
    this.imageUrl,
    this.size = 32,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
        shape: BoxShape.circle,
        border: Border.all(color: Theme.of(context).colorScheme.outline, width: 1),
      ),
      child: MingrrImage.avatar(
        imageUrl: imageUrl,
        size: size,
        icon: AppIcons.profile,
      ),
    );
  }
}
