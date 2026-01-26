import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/pet_constants.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/feature_colors.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/mingrr_image.dart';
import '../../../../core/widgets/navigation/top_navigation.dart';
import '../../../../models/community_post_model.dart';
import '../../../../models/group_model.dart';
import '../../../../models/marketplace_model.dart';
import '../../../../models/pet_model.dart';
import '../providers/liked_provider.dart';

/// ============================================================
/// 좋아요 목록 화면
/// 
/// 프로필 > 좋아요 목록
/// 탭 구성: 상품 / 반려동물 / 커뮤니티 / 소모임 (4탭)
/// ============================================================

class LikedListScreen extends ConsumerWidget {
  const LikedListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('좋아요 목록'),
      ),
      body: DefaultTabController(
        length: 4,
        child: Column(
          children: [
            const MingrrSubTabBar(
              tabs: ['상품', '반려동물', '커뮤니티', '소모임'],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _LikedProductsTab(),
                  _LikedPetsTab(),
                  _LikedCommunityTab(),
                  _LikedGroupsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 1. 상품 탭
// ============================================================

class _LikedProductsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(likedProductsProvider);
    
    return productsAsync.when(
      data: (products) {
        if (products.isEmpty) {
          return MingrrEmptyState(
            icon: Icons.bookmark_border,
            title: '찜한 상품이 없어요',
            subtitle: '마켓에서 마음에 드는 상품을 찜해보세요',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(AppSizes.paddingM),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return _LikedItemCard(
              onTap: () => context.push('/market/product/${product.id}'),
              imageUrl: product.imageUrls.isNotEmpty ? product.imageUrls.first : null,
              icon: Icons.shopping_bag,
              iconColor: context.features.market,
              title: product.title,
              subtitle: product.priceString,
              badge: product.status.label,
              badgeColor: product.status == ProductStatus.available 
                  ? context.features.market 
                  : Theme.of(context).colorScheme.outline,
            );
          },
        );
      },
      loading: () => const MingrrLoadingState(
        type: MingrrLoadingType.market,
        message: '찜한 상품을 불러오고 있어요',
      ),
      error: (_, __) => MingrrErrorState(
        onRetry: () => ref.invalidate(likedProductsProvider),
      ),
    );
  }
}

// ============================================================
// 2. 반려동물 탭
// ============================================================

class _LikedPetsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petsAsync = ref.watch(likedPetsProvider);
    
    return petsAsync.when(
      data: (pets) {
        if (pets.isEmpty) {
          return MingrrEmptyState(
            icon: Icons.pets,
            title: '좋아요한 친구가 없어요',
            subtitle: '데이팅에서 마음에 드는 친구를 찾아보세요',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(AppSizes.paddingM),
          itemCount: pets.length,
          itemBuilder: (context, index) {
            final pet = pets[index];
            return _LikedPetCard(
              pet: pet,
              onTap: () => context.push('/dating/detail/${pet.id}'),
              onUnlike: () async {
                final toggle = ref.read(petLikeToggleProvider);
                await toggle(pet.id, true);
              },
            );
          },
        );
      },
      loading: () => const MingrrLoadingState(
        type: MingrrLoadingType.dating,
        message: '좋아요한 친구를 불러오고 있어요',
      ),
      error: (_, __) => MingrrErrorState(
        onRetry: () => ref.invalidate(likedPetsProvider),
      ),
    );
  }
}

// ============================================================
// 3. 커뮤니티 탭
// ============================================================

class _LikedCommunityTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(likedCommunityPostsProvider);
    
    return postsAsync.when(
      data: (posts) {
        if (posts.isEmpty) {
          return MingrrEmptyState(
            icon: Icons.article_outlined,
            title: '좋아요한 글이 없어요',
            subtitle: '커뮤니티에서 마음에 드는 글에 좋아요를 눌러보세요',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(AppSizes.paddingM),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            return _LikedItemCard(
              onTap: () => context.push('/social/community/${post.id}'),
              icon: Icons.article,
              iconColor: context.features.social,
              title: post.title,
              subtitle: '${post.category.label} · 💬 ${post.commentCount} · ❤️ ${post.likeCount}',
            );
          },
        );
      },
      loading: () => const MingrrLoadingState(
        type: MingrrLoadingType.community,
        message: '좋아요한 글을 불러오고 있어요',
      ),
      error: (_, __) => MingrrErrorState(
        onRetry: () => ref.invalidate(likedCommunityPostsProvider),
      ),
    );
  }
}

// ============================================================
// 4. 소모임 탭
// ============================================================

class _LikedGroupsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(likedGroupsProvider);
    
    return groupsAsync.when(
      data: (groups) {
        if (groups.isEmpty) {
          return MingrrEmptyState(
            icon: Icons.groups_outlined,
            title: '좋아요한 소모임이 없어요',
            subtitle: '소모임에서 마음에 드는 모임에 좋아요를 눌러보세요',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(AppSizes.paddingM),
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final group = groups[index];
            return _LikedItemCard(
              onTap: () => context.push('/social/group/${group.id}'),
              imageUrl: group.imageUrl,
              icon: Icons.groups,
              iconColor: context.features.social,
              title: group.name,
              subtitle: '멤버 ${group.memberCount}명 · ❤️ ${group.likeCount}',
            );
          },
        );
      },
      loading: () => const MingrrLoadingState(
        type: MingrrLoadingType.community,
        message: '좋아요한 소모임을 불러오고 있어요',
      ),
      error: (_, __) => MingrrErrorState(
        onRetry: () => ref.invalidate(likedGroupsProvider),
      ),
    );
  }
}

// ============================================================
// 공통 컴포넌트
// ============================================================

/// 좋아요 아이템 카드 (공통)
class _LikedItemCard extends StatelessWidget {
  final VoidCallback? onTap;
  final String? imageUrl;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? badge;
  final Color? badgeColor;

  const _LikedItemCard({
    this.onTap,
    this.imageUrl,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.badge,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return MingrrCard(
      margin: const EdgeInsets.only(bottom: AppSizes.gapM),
      onTap: onTap,
      child: Row(
        children: [
          // 이미지 또는 아이콘
          if (imageUrl != null)
            MingrrThumbnail(
              imageUrl: imageUrl,
              width: 60,
              height: 60,
              borderRadius: AppSizes.radiusS,
              errorWidget: _buildIconContainer(context),
            )
          else
            _buildIconContainer(context),
          const SizedBox(width: AppSizes.gapM),
          
          // 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.titleMedium(context).withWeight(FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSizes.gapXXS),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall(context).withColor(colorScheme.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          // 배지 또는 화살표
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingS,
                vertical: AppSizes.paddingXXS,
              ),
              decoration: BoxDecoration(
                color: (badgeColor ?? iconColor).withValues(alpha: AppOpacity.o10),
                borderRadius: BorderRadius.circular(AppSizes.radiusXXS),
              ),
              child: Text(
                badge!,
                style: AppTextStyles.labelSmall(context).withColor(badgeColor ?? iconColor),
              ),
            )
          else
            Icon(Icons.chevron_right, color: colorScheme.outlineVariant),
        ],
      ),
    );
  }
  
  Widget _buildIconContainer(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: AppOpacity.o10),
        borderRadius: BorderRadius.circular(AppSizes.radiusS),
      ),
      child: Icon(icon, color: iconColor, size: 28),
    );
  }
}

/// 반려동물 좋아요 카드 (좋아요 해제 버튼 포함)
class _LikedPetCard extends StatelessWidget {
  final PetModel pet;
  final VoidCallback? onTap;
  final VoidCallback? onUnlike;

  const _LikedPetCard({
    required this.pet,
    this.onTap,
    this.onUnlike,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return MingrrCard(
      margin: const EdgeInsets.only(bottom: AppSizes.gapM),
      onTap: onTap,
      child: Row(
        children: [
          // 프로필 이미지
          MingrrThumbnail(
            imageUrl: pet.displayImageUrl,
            width: 70,
            height: 70,
            borderRadius: AppSizes.radiusS,
            errorWidget: _buildDefaultImage(context),
          ),
          const SizedBox(width: AppSizes.gapM),
          
          // 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      pet.name,
                      style: AppTextStyles.titleMedium(context).withWeight(FontWeight.w600),
                    ),
                    const SizedBox(width: AppSizes.gapXS),
                    Icon(
                      pet.gender == PetGender.male ? Icons.male : Icons.female,
                      size: 16,
                      color: pet.gender == PetGender.male ? Colors.blue : Colors.pink,
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.gapXXS),
                Text(
                  '${pet.breed ?? "믹스견"} · ${pet.ageString}',
                  style: AppTextStyles.bodySmall(context).withColor(colorScheme.onSurfaceVariant),
                ),
                if (pet.traits.isNotEmpty) ...[
                  const SizedBox(height: AppSizes.gapXS),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: pet.traits.take(3).map((trait) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.paddingXS,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: context.features.datingContainer,
                        borderRadius: BorderRadius.circular(AppSizes.radiusXXS),
                      ),
                      child: Text(
                        trait.label,
                        style: AppTextStyles.caption(context).withColor(context.features.dating),
                      ),
                    )).toList(),
                  ),
                ],
              ],
            ),
          ),
          
          // 좋아요 해제 버튼
          IconButton(
            onPressed: onUnlike,
            icon: Icon(Icons.favorite, color: context.features.dating),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDefaultImage(BuildContext context) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: context.features.datingContainer,
        borderRadius: BorderRadius.circular(AppSizes.radiusS),
      ),
      child: Icon(Icons.pets, color: context.features.dating, size: 32),
    );
  }
}

