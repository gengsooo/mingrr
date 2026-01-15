import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/feature_colors.dart';
import '../constants/app_sizes.dart';
import '../services/firestore_service.dart';
import 'common_widgets.dart';
import 'svg_icons.dart';
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
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        titleSpacing: 0,
        title: _buildSearchField(),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 40,
      margin: const EdgeInsets.only(left: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: _getHintText(),
          hintStyle: TextStyle(color: Theme.of(context).colorScheme.outlineVariant, fontSize: 13),
          prefixIcon: Icon(Icons.search, color: widget.accentColor, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
        onSubmitted: _onSearch,
        textInputAction: TextInputAction.search,
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
      return const MingrrLoadingState();
    }

    if (_lastQuery.isEmpty) {
      return const MingrrEmptyState(
        icon: Icons.search,
        title: '검색어를 입력해주세요',
      );
    }

    if (_results.isEmpty) {
      return const MingrrEmptyState(
        icon: Icons.search_off,
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
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: context.features.marketContainer,
            borderRadius: BorderRadius.circular(8),
            image: product.imageUrls.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(product.imageUrls.first),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: product.imageUrls.isEmpty
              ? Icon(Icons.image, color: context.features.market)
              : null,
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
          style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outlineVariant),
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
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: context.features.socialContainer,
            borderRadius: BorderRadius.circular(8),
            image: group.imageUrl != null
                ? DecorationImage(
                    image: NetworkImage(group.imageUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: group.imageUrl == null
              ? Icon(Icons.groups, color: context.features.social)
              : null,
        ),
        title: Text(group.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Row(
          children: [
            Text(group.typeString, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 8),
            Icon(Icons.person, size: 12, color: Theme.of(context).colorScheme.outlineVariant),
            Text(' ${group.memberCount}', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outlineVariant)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite, size: 14, color: context.features.breeding),
            const SizedBox(width: 2),
            Text('${group.likeCount}', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outlineVariant)),
          ],
        ),
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
            borderRadius: BorderRadius.circular(8),
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
          style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outlineVariant),
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
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: context.features.breedingContainer,
            borderRadius: BorderRadius.circular(8),
            image: breeding.imageUrls != null && breeding.imageUrls.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(breeding.imageUrls.first),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: (breeding.imageUrls == null || breeding.imageUrls.isEmpty)
              ? Icon(Icons.pets, color: context.features.breeding)
              : null,
        ),
        title: Text(breeding.title ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${breeding.breed ?? '품종 미상'}',
          style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outlineVariant),
        ),
        trailing: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.outlineVariant),
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
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: context.features.socialContainer,
            borderRadius: BorderRadius.circular(8),
            image: post.imageUrls.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(post.imageUrls.first),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: post.imageUrls.isEmpty
              ? Icon(Icons.article, color: context.features.social)
              : null,
        ),
        title: Text(
          post.content.length > 30 ? '${post.content.substring(0, 30)}...' : post.content,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: context.features.social.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                post.category.label,
                style: TextStyle(fontSize: 10, color: context.features.social),
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.favorite, size: 12, color: Theme.of(context).colorScheme.outlineVariant),
            Text(' ${post.likeCount}', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.outlineVariant)),
            const SizedBox(width: 8),
            Icon(Icons.chat_bubble_outline, size: 12, color: Theme.of(context).colorScheme.outlineVariant),
            Text(' ${post.commentCount}', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.outlineVariant)),
          ],
        ),
        trailing: Text(
          formatRelativeTime(post.createdAt),
          style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outlineVariant),
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
        return Icons.pets;
      case JobType.walk:
        return Icons.directions_walk;
      case JobType.bath:
        return Icons.bathtub;
      case JobType.training:
        return Icons.school;
      case JobType.other:
        return Icons.work;
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
