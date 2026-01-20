import 'package:flutter/material.dart';
import '../theme/feature_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/pet_constants.dart';
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
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  distanceString != null 
                      ? '$distanceString · ${_formatTime(product.createdAt)}'
                      : '${product.address ?? LocationConstants.noLocationText} · ${_formatTime(product.createdAt)}',
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outlineVariant),
                ),
                const SizedBox(height: 6),
                Text(
                  product.priceString,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isShare ? context.features.walk : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
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
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '예약중',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          if (product.status == ProductStatus.completed)
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '거래완료',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
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
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: context.features.market.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(product.category.icon, size: 10, color: context.features.market),
              const SizedBox(width: 3),
              Text(
                product.category.label,
                style: TextStyle(fontSize: 10, color: context.features.market),
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
                style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.outlineVariant)),
            const SizedBox(width: 8),
            Icon(Icons.chat_bubble_outline, size: 14, color: Theme.of(context).colorScheme.outlineVariant),
            const SizedBox(width: 2),
            Text('${product.chatCount}',
                style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.outlineVariant)),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: context.features.market.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  job.typeString,
                  style: TextStyle(
                    fontSize: 11,
                    color: context.features.market,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (job.status == JobStatus.recruiting)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: context.features.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '모집중',
                    style: TextStyle(fontSize: 10, color: context.features.success),
                  ),
                ),
              const Spacer(),
              Text(
                _formatTime(job.createdAt),
                style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.outlineVariant),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 제목
          Text(
            job.title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),

          // 기간 + 시간
          if (job.startDate != null || job.endDate != null)
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    job.fullPeriodString,
                    style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 12),

          // 하단: 급여 + 거리
          Row(
            children: [
              Text(
                job.priceString,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: context.features.market,
                ),
              ),
              const Spacer(),
              if (distanceString != null) ...[
                DistanceBadge.small(
                  distanceString: distanceString!,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                const SizedBox(width: 8),
              ],
              Row(
                children: [
                  Icon(Icons.chat_bubble_outline, size: 14, color: Theme.of(context).colorScheme.outlineVariant),
                  const SizedBox(width: 2),
                  Text('${job.chatCount}',
                      style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.outlineVariant)),
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
