import 'package:flutter/material.dart';
import '../../constants/app_icons.dart';
import '../../constants/app_sizes.dart';
import '../../theme/feature_colors.dart';

// ===== 기본 반려동물 이미지 플레이스홀더 =====
/// 추가사진이 없을 때 표시하는 기본 반려동물 아이콘
/// 모든 화면에서 통일된 스타일로 사용 (🐶 이모지)
class DefaultPetImage extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const DefaultPetImage({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.features.dating.withValues(alpha: AppOpacity.o15),
        borderRadius: borderRadius,
      ),
      child: Center(
        child: Icon(
          AppIcons.pet,
          size: (height ?? 100) * 0.4,
          color: context.features.dating.withValues(alpha: AppOpacity.o50),
        ),
      ),
    );
  }
}
