import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../services/firestore_service.dart';
import 'svg_icons.dart';
import '../utils/format_utils.dart';
import '../../models/marketplace_model.dart';
import '../../models/community_model.dart';

/// ============================================================
/// 통합 검색 화면
/// 마켓, 소모임, 알바 검색 지원
/// ============================================================

enum SearchType { market, community, job }

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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: _buildSearchField(),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소', style: TextStyle(color: AppColors.textSecondary)),
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
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: _getHintText(),
          hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
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
      case SearchType.market:
        return '상품명, 설명으로 검색';
      case SearchType.community:
        return '모임명, 태그로 검색';
      case SearchType.job:
        return '알바 제목, 설명으로 검색';
    }
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_lastQuery.isEmpty) {
      return _buildEmptyState('검색어를 입력해주세요', Icons.search);
    }

    if (_results.isEmpty) {
      return _buildEmptyState('검색 결과가 없습니다', Icons.search_off);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSizes.paddingM),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final item = _results[index];
        switch (widget.searchType) {
          case SearchType.market:
            return _buildProductItem(item as ProductModel);
          case SearchType.community:
            return _buildGroupItem(item as GroupModel);
          case SearchType.job:
            return _buildJobItem(item as JobModel);
        }
      },
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const MingrrSvgIcon(
            assetPath: SvgAssets.emptySearch,
            width: 120,
            height: 120,
          ),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: AppColors.textSecondary)),
        ],
      ),
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
            color: AppColors.marketLight,
            borderRadius: BorderRadius.circular(8),
            image: product.imageUrls.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(product.imageUrls.first),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: product.imageUrls.isEmpty
              ? const Icon(Icons.image, color: AppColors.market)
              : null,
        ),
        title: Text(product.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          product.priceString,
          style: TextStyle(
            color: product.type == ProductType.share ? AppColors.walk : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Text(
          formatRelativeTime(product.createdAt),
          style: const TextStyle(fontSize: 12, color: AppColors.textHint),
        ),
        onTap: () {
          // TODO: 상품 상세 화면으로 이동
          Navigator.pop(context, product);
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
            color: AppColors.communityLight,
            borderRadius: BorderRadius.circular(8),
            image: group.imageUrl != null
                ? DecorationImage(
                    image: NetworkImage(group.imageUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: group.imageUrl == null
              ? const Icon(Icons.groups, color: AppColors.community)
              : null,
        ),
        title: Text(group.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Row(
          children: [
            Text(group.typeString, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 8),
            const Icon(Icons.person, size: 12, color: AppColors.textHint),
            Text(' ${group.memberCount}', style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.favorite, size: 14, color: AppColors.dating),
            const SizedBox(width: 2),
            Text('${group.likeCount}', style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
          ],
        ),
        onTap: () {
          Navigator.pop(context, group);
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
            color: AppColors.marketLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(_getJobIcon(job.type), color: AppColors.market),
        ),
        title: Text(job.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${formatPrice(job.price)}원/${job.priceUnit}',
          style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.market),
        ),
        trailing: Text(
          formatRelativeTime(job.createdAt),
          style: const TextStyle(fontSize: 12, color: AppColors.textHint),
        ),
        onTap: () {
          Navigator.pop(context, job);
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
        case SearchType.community:
          results = await _firestoreService.searchGroups(trimmedQuery);
          break;
        case SearchType.job:
          results = await _firestoreService.searchJobs(trimmedQuery);
          break;
      }

      setState(() => _results = results);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('검색 중 오류가 발생했습니다: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
