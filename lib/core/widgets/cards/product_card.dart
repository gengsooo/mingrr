import 'package:flutter/material.dart';
import '../../constants/app_icons.dart';
import '../../theme/feature_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../constants/app_sizes.dart';
import '../../constants/location_constants.dart';
import '../../../models/marketplace_model.dart';
import '../common_widgets.dart';

/// ============================================================
/// 상품 카드 컴포넌트
/// 마켓플레이스에서 상품 목록 표시에 사용
/// ============================================================

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onTap;
  final String? distanceString;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.distanceString,
  });

  @override
  Widget build(BuildContext context) {
    final isShare = product.type == ProductType.share;

    return MingrrCard(
      margin: const EdgeInsets.only(bottom: AppSizes.gapM),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 이미지
          _buildImage(context),
          const SizedBox(width: AppSizes.gapM),

          // 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title,
                  style: AppTextStyles.titleMedium(context),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSizes.gapXS),
                Text(
                  distanceString != null 
                      ? '$distanceString · ${_formatTime(product.createdAt)}'
                      : '${product.address ?? LocationConstants.noLocationText} · ${_formatTime(product.createdAt)}',
                  style: AppTextStyles.captionSmall(context),
                ),
                const SizedBox(height: AppSizes.gapS),
                Text(
                  product.priceString,
                  style: AppTextStyles.titleLarge(context).copyWith(
                    color: isShare ? context.features.walk : null,
                  ),
                ),
                const SizedBox(height: AppSizes.gapS),
                _buildFooter(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    return MingrrImage.background(
      imageUrl: product.imageUrls.isNotEmpty ? product.imageUrls.first : null,
      width: 100,
      height: 100,
      radius: AppSizes.radiusM,
      accentColor: context.features.market,
      child: Stack(
        children: [
          if (product.status == ProductStatus.reserved)
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: AppSizes.paddingXXS),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  borderRadius: BorderRadius.circular(AppSizes.radiusS),
                ),
                child: Text(
                  '예약중',
                  style: AppTextStyles.captionSmall(context),
                ),
              ),
            ),
          if (product.status == ProductStatus.completed)
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: AppSizes.paddingXXS),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(AppSizes.radiusS),
                ),
                child: Text(
                  '거래완료',
                  style: AppTextStyles.captionSmall(context),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: AppSizes.paddingXXS),
          decoration: BoxDecoration(
            color: context.features.market.withValues(alpha: AppOpacity.o10),
            borderRadius: BorderRadius.circular(AppSizes.radiusS),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(product.category.icon, size: 10, color: context.features.market),
              const SizedBox(width: 3),
              Text(
                product.category.label,
                style: AppTextStyles.captionSmall(context).copyWith(color: context.features.market),
              ),
            ],
          ),
        ),
        const Spacer(),
        Row(
          children: [
            Icon(AppIcons.bookmarkOutlined, size: 14, color: Theme.of(context).colorScheme.outlineVariant),
            const SizedBox(width: 2),
            Text('${product.likeCount}',
                style: AppTextStyles.captionSmall(context)),
            const SizedBox(width: AppSizes.gapS),
            Icon(AppIcons.chatBubbleOutlined, size: 14, color: Theme.of(context).colorScheme.outlineVariant),
            const SizedBox(width: 2),
            Text('${product.chatCount}',
                style: AppTextStyles.captionSmall(context)),
          ],
        ),
      ],
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inMinutes < 1) return '방금';
    if (diff.inHours < 1) return '${diff.inMinutes}분 전';
    if (diff.inDays < 1) return '${diff.inHours}시간 전';
    return '${diff.inDays}일 전';
  }
}

/// 알바 카드 컴포넌트
/// ProductCard와 동일한 가로형 레이아웃
class JobCard extends StatelessWidget {
  final JobModel job;
  final String? distanceString;
  final VoidCallback? onTap;

  const JobCard({
    super.key,
    required this.job,
    this.distanceString,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MingrrCard(
      margin: const EdgeInsets.only(bottom: AppSizes.gapM),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 좌측: 이미지 영역 (100x100)
          _buildImage(context),
          const SizedBox(width: AppSizes.gapM),

          // 우측: 정보 영역
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1줄: 제목
                Text(
                  job.title,
                  style: AppTextStyles.titleMedium(context),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSizes.gapXS),

                // 2줄: 거리 · 시간
                Text(
                  distanceString != null
                      ? '$distanceString · ${_formatTime(job.createdAt)}'
                      : '${job.address ?? '위치 미설정'} · ${_formatTime(job.createdAt)}',
                  style: AppTextStyles.captionSmall(context),
                ),
                const SizedBox(height: AppSizes.gapS),

                // 3줄: 기간 (없으면 '기간 정보 없음')
                Row(
                  children: [
                    Icon(AppIcons.calendar, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(width: AppSizes.gapXS),
                    Expanded(
                      child: Text(
                        (job.startDate != null || job.endDate != null)
                            ? job.periodString
                            : '기간 정보 없음',
                        style: AppTextStyles.bodyLarge(context),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.gapS),

                // 4줄: 가격 + 카테고리 + 채팅
                _buildFooter(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 좌측 이미지 영역 (썸네일 이미지 + 상태 배지)
  Widget _buildImage(BuildContext context) {
    return MingrrImage.background(
      imageUrl: job.imageUrls.isNotEmpty ? job.imageUrls.first : null,
      width: 100,
      height: 100,
      radius: AppSizes.radiusM,
      accentColor: context.features.market,
      child: Stack(
        children: [
          // 좌상단: 모집중 배지
          if (job.status == JobStatus.recruiting)
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: AppSizes.paddingXXS),
                decoration: BoxDecoration(
                  color: context.features.success,
                  borderRadius: BorderRadius.circular(AppSizes.radiusS),
                ),
                child: Text(
                  '모집중',
                  style: AppTextStyles.captionSmall(context).copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          // 예약됨 상태
          if (job.status == JobStatus.reserved)
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: AppSizes.paddingXXS),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  borderRadius: BorderRadius.circular(AppSizes.radiusS),
                ),
                child: Text(
                  '예약중',
                  style: AppTextStyles.captionSmall(context).copyWith(color: Colors.white),
                ),
              ),
            ),
          // 완료 상태
          if (job.status == JobStatus.completed)
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: AppSizes.paddingXXS),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(AppSizes.radiusS),
                ),
                child: Text(
                  '완료',
                  style: AppTextStyles.captionSmall(context).copyWith(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 하단: 카테고리 배지 + 가격 + 채팅수
  Widget _buildFooter(BuildContext context) {
    return Row(
      children: [
        // 카테고리 배지 (아이콘 포함)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: AppSizes.paddingXXS),
          decoration: BoxDecoration(
            color: context.features.market.withValues(alpha: AppOpacity.o10),
            borderRadius: BorderRadius.circular(AppSizes.radiusS),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(job.type.icon, size: 10, color: context.features.market),
              const SizedBox(width: 3),
              Text(
                job.typeString,
                style: AppTextStyles.captionSmall(context).copyWith(color: context.features.market),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSizes.gapS),
        // 가격
        Text(
          job.priceString,
          style: AppTextStyles.titleLarge(context).copyWith(color: context.features.market),
        ),
        const Spacer(),
        // 채팅수
        Row(
          children: [
            Icon(AppIcons.chatBubbleOutlined, size: 14, color: Theme.of(context).colorScheme.outlineVariant),
            const SizedBox(width: 2),
            Text('${job.chatCount}', style: AppTextStyles.captionSmall(context)),
          ],
        ),
      ],
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inMinutes < 1) return '방금';
    if (diff.inHours < 1) return '${diff.inMinutes}분 전';
    if (diff.inDays < 1) return '${diff.inHours}시간 전';
    return '${diff.inDays}일 전';
  }
}

