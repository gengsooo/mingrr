import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

/// ============================================================
/// 공통 프로필 버튼 위젯
/// 모든 화면 우측 상단에 표시 (홈 화면과 동일한 디자인)
/// ============================================================

class ProfileButton extends StatelessWidget {
  final String? imageUrl;
  final double size;

  const ProfileButton({
    super.key,
    this.imageUrl,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/profile'),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.background,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.divider, width: 1),
        ),
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? ClipOval(
                child: Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildPlaceholder(),
                ),
              )
            : _buildPlaceholder(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Icon(
      Icons.person,
      size: size * 0.55,
      color: AppColors.textHint,
    );
  }
}

/// AppBar actions에 추가할 프로필 버튼
Widget buildProfileAction({String? imageUrl}) {
  return Builder(
    builder: (context) => Padding(
      padding: const EdgeInsets.only(right: AppSizes.paddingS),
      child: ProfileButton(imageUrl: imageUrl),
    ),
  );
}
