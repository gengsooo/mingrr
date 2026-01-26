import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_sizes.dart';
import '../../constants/location_constants.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/location_verification_helper.dart';

/// ============================================================
/// 위치 인증 필요 빈 화면 컴포넌트
/// 
/// 위치 인증이 필요한 기능(데이팅, 마켓, 소모임)에서
/// 사용자가 위치 인증을 하지 않았을 때 표시
/// 
/// 사용처:
/// - 데이팅 화면 (추천/근처검색/교배찾기)
/// - 마켓 화면 (판매/나눔)
/// - 소모임 화면
/// ============================================================
class LocationRequiredEmptyState extends ConsumerWidget {
  /// 기능별 타입 (데이팅, 마켓, 소모임)
  final LocationRequiredType type;
  
  /// 테마 색상
  final Color accentColor;

  const LocationRequiredEmptyState({
    super.key,
    required this.type,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 아이콘
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_off_outlined,
                size: 40,
                color: accentColor,
              ),
            ),
            const SizedBox(height: AppSizes.gapXL),
            
            // 제목
            Text(
              type.title,
              style: AppTextStyles.headlineSmall(context).copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.gapM),
            
            // 설명
            Text(
              type.description,
              style: AppTextStyles.bodyMedium(context).copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.gapXXL),
            
            // 위치 인증 버튼
            SizedBox(
              width: 200,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => LocationVerificationHelper.showVerificationDialog(context, ref),
                icon: const Icon(Icons.location_on, size: 20),
                label: const Text('위치 인증하기'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusL),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.gapL),
            
            // 부가 설명
            Text(
              type.hint,
              style: AppTextStyles.bodySmall(context).copyWith(
                color: colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

}
