import 'package:flutter/material.dart';
import '../constants/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/feature_colors.dart';
import '../theme/app_text_styles.dart';
import '../constants/app_sizes.dart';
import '../services/firestore_service.dart';
import 'common_widgets.dart';
import 'mingrr_image.dart';
import 'badges/svg_icons.dart';
import 'badges/info_badge.dart';
import 'forms/search_bar.dart';
import '../utils/format_utils.dart';
import '../../models/marketplace_model.dart';
import '../../models/group_model.dart';
import '../../models/community_post_model.dart';

/// ============================================================
/// 통합 검색 화면
/// 마켓, 소모임(group), 커뮤니티(게시판), 알바 검색 지원
/// ============================================================

enum SearchType {
  market,      // 마켓플레이스 상품
  group,       // 소모임
  community,   // 커뮤니티 게시판
  job,         // 알바
  breeding,    // 교배
}

class SearchScreen extends ConsumerStatefulWidget {
  final SearchType searchType;
  final Color accentColor;

  const SearchScreen({
    super.key,
    required this.searchType,
    required this.accentColor,
  });

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final _firestoreService = FirestoreService();
  
  List<dynamic> _results = [];
  bool _isLoading = false;
  String _lastQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: MingrrAppBar.search(
        searchWidget: _buildSearchField(),
        onCancel: () => Navigator.pop(context),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.only(left: AppSizes.paddingL),
      child: MingrrSearchBar(
        controller: _searchController,
        hintText: _getHintText(),
        accentColor: widget.accentColor,
        autofocus: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        onSearch: _onSearch,
      ),
    );
  }

  String _getHintText() {
    switch (widget.searchType) {
      case SearchType.breeding:
        return '교배 글 제목, 상세 내용으로 검색';
      case SearchType.group:
        return '모임명, 태그로 검색';
      case SearchType.community:
        return '게시글 내용, 태그로 검색';
      case SearchType.job:
        return '알바 제목, 설명으로 검색';
      case SearchType.market:
        return '상품명, 설명으로 검색';
    }
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const MingrrLoadingState(type: MingrrLoadingType.primary, message: '검색 중이에요');
    }

    if (_lastQuery.isEmpty) {
      return const MingrrEmptyState(
        icon: AppIcons.search,
        title: '검색어를 입력해주세요',
      );
    }

    if (_results.isEmpty) {
      return const MingrrEmptyState(
        icon: AppIcons.searchOff,
        title: '검색 결과가 없습니다',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSizes.paddingM),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final item = _results[index];
        switch (widget.searchType) {
          case SearchType.market:
            return _buildProductItem(item as ProductModel);
          case SearchType.group:
            return _buildGroupItem(item as GroupModel);
          case SearchType.community:
            return _buildCommunityPostItem(item as CommunityPostModel);
          case SearchType.breeding:
            return _buildBreedingItem(item);
          case SearchType.job:
            return _buildJobItem(item as JobModel);
        }
      },
    );
  }


  Widget _buildProductItem(ProductModel product) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.gapM),
      child: ListTile(
        leading: MingrrImage.thumbnail(
          imageUrl: product.imageUrls.isNotEmpty ? product.imageUrls.first : null,
          width: 60,
          height: 60,
          radius: AppSizes.radiusXS,
          errorWidget: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: context.features.marketContainer,
              borderRadius: BorderRadius.circular(AppSizes.radiusXS),
            ),
            child: Icon(AppIcons.image, color: context.features.market),
          ),
        ),
        title: Text(product.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          product.priceString,
          style: TextStyle(
            color: product.type == ProductType.share ? context.features.walk : Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Text(
          formatRelativeTime(product.createdAt),
          style: AppTextStyles.captionSmall(context),
        ),
        onTap: () {
          Navigator.pop(context);
          context.push('/market/product/${product.id}');
        },
      ),
    );
  }

  Widget _buildGroupItem(GroupModel group) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.gapM),
      child: ListTile(
        leading: MingrrImage.thumbnail(
          imageUrl: group.imageUrl,
          width: 60,
          height: 60,
          radius: AppSizes.radiusXS,
          errorWidget: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: context.features.socialContainer,
              borderRadius: BorderRadius.circular(AppSizes.radiusXS),
            ),
            child: Icon(AppIcons.group, color: context.features.social),
          ),
        ),
        title: Text(group.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Row(
          children: [
            Text(group.typeString, style: AppTextStyles.caption(context)),
            const SizedBox(width: AppSizes.gapS),
            Icon(AppIcons.profile, size: 12, color: Theme.of(context).colorScheme.outlineVariant),
            Text(' ${group.memberCount}', style: AppTextStyles.captionSmall(context)),
          ],
        ),
        trailing: LikeCountText(count: group.likeCount, size: InfoBadgeSize.small),
        onTap: () {
          Navigator.pop(context);
          context.push('/social/group/${group.id}');
        },
      ),
    );
  }

  Widget _buildJobItem(JobModel job) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.gapM),
      child: ListTile(
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: context.features.marketContainer,
            borderRadius: BorderRadius.circular(AppSizes.radiusXS),
          ),
          child: Icon(_getJobIcon(job.type), color: context.features.market),
        ),
        title: Text(job.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${formatPrice(job.price)}원/${job.priceUnit}',
          style: TextStyle(fontWeight: FontWeight.w600, color: context.features.market),
        ),
        trailing: Text(
          formatRelativeTime(job.createdAt),
          style: AppTextStyles.captionSmall(context),
        ),
        onTap: () {
          Navigator.pop(context);
          context.push('/market/job/${job.id}');
        },
      ),
    );
  }

  Widget _buildBreedingItem(dynamic breeding) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.gapM),
      child: ListTile(
        leading: MingrrImage.thumbnail(
          imageUrl: breeding.imageUrls != null && breeding.imageUrls.isNotEmpty ? breeding.imageUrls.first : null,
          width: 60,
          height: 60,
          radius: AppSizes.radiusXS,
          errorWidget: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: context.features.breedingContainer,
              borderRadius: BorderRadius.circular(AppSizes.radiusXS),
            ),
            child: Icon(AppIcons.breeding, color: context.features.breeding),
          ),
        ),
        title: Text(breeding.title ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${breeding.breed ?? '품종 미상'}',
          style: AppTextStyles.captionSmall(context),
        ),
        trailing: Icon(AppIcons.chevronRight, color: Theme.of(context).colorScheme.outlineVariant),
        onTap: () {
          Navigator.pop(context);
          context.push('/dating/detail/${breeding.petId}');
        },
      ),
    );
  }

  Widget _buildCommunityPostItem(CommunityPostModel post) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.gapM),
      child: ListTile(
        leading: MingrrImage.thumbnail(
          imageUrl: post.imageUrls.isNotEmpty ? post.imageUrls.first : null,
          width: 60,
          height: 60,
          radius: AppSizes.radiusXS,
          errorWidget: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: context.features.socialContainer,
              borderRadius: BorderRadius.circular(AppSizes.radiusXS),
            ),
            child: Icon(AppIcons.article, color: context.features.social),
          ),
        ),
        title: Text(
          post.content.length > 30 ? '${post.content.substring(0, 30)}...' : post.content,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: AppSizes.paddingXXS),
              decoration: BoxDecoration(
                color: context.features.social.withValues(alpha: AppOpacity.o10),
                borderRadius: BorderRadius.circular(AppSizes.radiusXXS),
              ),
              child: Text(
                post.category.label,
                style: AppTextStyles.labelMedium(context).copyWith(color: context.features.social),
              ),
            ),
            const SizedBox(width: AppSizes.gapS),
            LikeCountText(count: post.likeCount, size: InfoBadgeSize.small),
            const SizedBox(width: AppSizes.gapS),
            Icon(AppIcons.chatOutlined, size: 12, color: Theme.of(context).colorScheme.outlineVariant),
            Text(' ${post.commentCount}', style: AppTextStyles.captionSmall(context)),
          ],
        ),
        trailing: Text(
          formatRelativeTime(post.createdAt),
          style: AppTextStyles.captionSmall(context),
        ),
        onTap: () {
          Navigator.pop(context);
          context.push('/social/community/${post.id}');
        },
      ),
    );
  }

  IconData _getJobIcon(JobType type) {
    switch (type) {
      case JobType.care:
        return AppIcons.pet;
      case JobType.walk:
        return AppIcons.walk;
      case JobType.bath:
        return AppIcons.bath;
      case JobType.training:
        return AppIcons.training;
      case JobType.other:
        return AppIcons.work;
    }
  }

  Future<void> _onSearch(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return;

    setState(() {
      _isLoading = true;
      _lastQuery = trimmedQuery;
    });

    try {
      List<dynamic> results;
      switch (widget.searchType) {
        case SearchType.market:
          results = await _firestoreService.searchProducts(trimmedQuery);
          break;
        case SearchType.group:
          results = await _firestoreService.searchGroups(trimmedQuery);
          break;
        case SearchType.community:
          results = await _firestoreService.searchCommunityPosts(trimmedQuery);
          break;
        case SearchType.breeding:
          results = await _firestoreService.searchBreedingPosts(trimmedQuery);
          break;
        case SearchType.job:
          results = await _firestoreService.searchJobs(trimmedQuery);
          break;
      }

      setState(() => _results = results);
    } catch (e) {
      if (mounted) {
        MingrrSnackBar.error(context, '검색 중 오류가 발생했습니다: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
