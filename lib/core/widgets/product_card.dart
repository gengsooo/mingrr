import 'package:flutter/material.dart';
import '../theme/feature_colors.dart';
import '../theme/app_text_styles.dart';
import '../constants/app_sizes.dart';
import '../constants/location_constants.dart';
import '../../models/marketplace_model.dart';
import 'common_widgets.dart';
import 'distance_badge.dart';

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
                  style: AppTextStyles.cardTitle(context),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSizes.gapXS),
                Text(
                  distanceString != null 
                      ? '$distanceString · ${_formatTime(product.createdAt)}'
                      : '${product.address ?? LocationConstants.noLocationText} · ${_formatTime(product.createdAt)}',
                  style: AppTextStyles.cardMeta(context),
                ),
                const SizedBox(height: AppSizes.gapSM),
                Text(
                  product.priceString,
                  style: AppTextStyles.cardPrice(context).copyWith(
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
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: context.features.marketContainer,
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        image: product.imageUrls.isNotEmpty
            ? DecorationImage(
                image: NetworkImage(product.imageUrls.first),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: Stack(
        children: [
          if (product.imageUrls.isEmpty)
            Center(
              child: Icon(Icons.image, size: 40, color: context.features.market),
            ),
          if (product.status == ProductStatus.reserved)
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: AppSizes.paddingXXS),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  borderRadius: BorderRadius.circular(AppSizes.radiusXXS),
                ),
                child: Text(
                  '예약중',
                  style: AppTextStyles.badgeSmall(context),
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
                  borderRadius: BorderRadius.circular(AppSizes.radiusXXS),
                ),
                child: Text(
                  '거래완료',
                  style: AppTextStyles.badgeSmall(context),
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
            color: context.features.market.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSizes.radiusXXS),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(product.category.icon, size: 10, color: context.features.market),
              const SizedBox(width: 3),
              Text(
                product.category.label,
                style: AppTextStyles.badgeSmall(context).copyWith(color: context.features.market),
              ),
            ],
          ),
        ),
        const Spacer(),
        Row(
          children: [
            Icon(Icons.bookmark_border, size: 14, color: Theme.of(context).colorScheme.outlineVariant),
            const SizedBox(width: 2),
            Text('${product.likeCount}',
                style: AppTextStyles.cardMeta(context)),
            const SizedBox(width: AppSizes.gapS),
            Icon(Icons.chat_bubble_outline, size: 14, color: Theme.of(context).colorScheme.outlineVariant),
            const SizedBox(width: 2),
            Text('${product.chatCount}',
                style: AppTextStyles.cardMeta(context)),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단: 타입 뱃지 + 상태
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingS, vertical: AppSizes.paddingXS),
                decoration: BoxDecoration(
                  color: context.features.market.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusXXS),
                ),
                child: Text(
                  job.typeString,
                  style: AppTextStyles.tagSmall(context).copyWith(color: context.features.market),
                ),
              ),
              const SizedBox(width: AppSizes.gapS),
              if (job.status == JobStatus.recruiting)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: AppSizes.paddingXXS),
                  decoration: BoxDecoration(
                    color: context.features.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusXXS),
                  ),
                  child: Text(
                    '모집중',
                    style: AppTextStyles.badgeSmall(context).copyWith(color: context.features.success),
                  ),
                ),
              const Spacer(),
              Text(
                _formatTime(job.createdAt),
                style: AppTextStyles.cardMeta(context),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.gapM),

          // 제목
          Text(
            job.title,
            style: AppTextStyles.cardTitle(context),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSizes.gapS),

          // 기간 + 시간
          if (job.startDate != null || job.endDate != null)
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: AppSizes.gapXS),
                Expanded(
                  child: Text(
                    job.fullPeriodString,
                    style: AppTextStyles.listSubtitle(context),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          const SizedBox(height: AppSizes.gapM),

          // 하단: 급여 + 거리
          Row(
            children: [
              Text(
                job.priceString,
                style: AppTextStyles.cardPrice(context).copyWith(color: context.features.market),
              ),
              const Spacer(),
              if (distanceString != null) ...[
                DistanceBadge.small(
                  distanceString: distanceString!,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                const SizedBox(width: AppSizes.gapS),
              ],
              Row(
                children: [
                  Icon(Icons.chat_bubble_outline, size: 14, color: Theme.of(context).colorScheme.outlineVariant),
                  const SizedBox(width: 2),
                  Text('${job.chatCount}',
                      style: AppTextStyles.cardMeta(context)),
                ],
              ),
            ],
          ),
        ],
      ),
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
