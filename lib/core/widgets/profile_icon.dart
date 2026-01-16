import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_sizes.dart';

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
      child: imageUrl != null && imageUrl!.isNotEmpty
          ? ClipOval(
              child: Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildPlaceholder(context),
              ),
            )
          : _buildPlaceholder(context),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Icon(
      Icons.person,
      size: size * 0.55,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }
}

/// @deprecated appbar_actions.dart의 AppBarActionButton.profile() 사용 권장
@Deprecated('Use AppBarActionButton.profile() from appbar_actions.dart instead')
Widget buildProfileAction({
  String? imageUrl, 
  Color? backgroundColor,
  double rightPadding = AppSizes.paddingM,
}) {
  return Builder(
    builder: (context) => Padding(
      padding: EdgeInsets.only(right: rightPadding),
      child: GestureDetector(
        onTap: () => GoRouter.of(context).push('/profile'),
        child: ProfileButton(
          imageUrl: imageUrl,
          size: 36,
          backgroundColor: backgroundColor,
        ),
      ),
    ),
  );
}
