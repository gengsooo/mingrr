import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../../models/marketplace_model.dart';
import 'common_widgets.dart';

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
          _buildImage(),
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
                      : '${product.address ?? '위치 미상'} · ${_formatTime(product.createdAt)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                ),
                const SizedBox(height: 6),
                Text(
                  product.priceString,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isShare ? AppColors.walk : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                _buildFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: AppColors.marketLight,
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
            const Center(
              child: Icon(Icons.image, size: 40, color: AppColors.market),
            ),
          if (product.status == ProductStatus.reserved)
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.textSecondary,
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
                  color: AppColors.textHint,
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

  Widget _buildFooter() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.market.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            product.categoryString,
            style: const TextStyle(fontSize: 10, color: AppColors.market),
          ),
        ),
        const Spacer(),
        Row(
          children: [
            const Icon(Icons.bookmark_border, size: 14, color: AppColors.textHint),
            const SizedBox(width: 2),
            Text('${product.likeCount}',
                style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
            const SizedBox(width: 8),
            const Icon(Icons.chat_bubble_outline, size: 14, color: AppColors.textHint),
            const SizedBox(width: 2),
            Text('${product.chatCount}',
                style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
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
  final VoidCallback? onTap;

  const JobCard({
    super.key,
    required this.job,
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
                  color: AppColors.market.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  job.typeString,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.market,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (job.status == JobStatus.recruiting)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '모집중',
                    style: TextStyle(fontSize: 10, color: AppColors.success),
                  ),
                ),
              const Spacer(),
              Text(
                _formatTime(job.createdAt),
                style: const TextStyle(fontSize: 11, color: AppColors.textHint),
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

          // 기간
          if (job.startDate != null || job.endDate != null)
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  _formatDateRange(job.startDate, job.endDate),
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          const SizedBox(height: 12),

          // 하단: 급여
          Row(
            children: [
              Text(
                job.priceString,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.market,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(Icons.chat_bubble_outline, size: 14, color: AppColors.textHint),
                  const SizedBox(width: 2),
                  Text('${job.chatCount}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
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

  String _formatDateRange(DateTime? start, DateTime? end) {
    if (start == null && end == null) return '기간 미정';
    final startStr = start != null ? '${start.month}/${start.day}' : '';
    final endStr = end != null ? '${end.month}/${end.day}' : '';
    if (start != null && end != null) return '$startStr ~ $endStr';
    if (start != null) return '$startStr ~';
    return '~ $endStr';
  }
}
