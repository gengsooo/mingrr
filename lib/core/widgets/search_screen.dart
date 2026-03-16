import 'dart:async';
import 'package:flutter/material.dart';
import '../constants/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/feature_colors.dart';
import '../theme/app_text_styles.dart';
import '../constants/app_sizes.dart';
import '../providers/firebase_providers.dart';
import 'common_widgets.dart';
import 'forms/search_bar.dart';
import '../utils/format_utils.dart';
import '../../models/marketplace_model.dart';
import '../../models/group_model.dart';
import '../../models/community_post_model.dart';
import '../../models/breeding_model.dart';
import '../utils/error_handler.dart';

/// ============================================================
/// 통합 검색 화면
/// 마켓, 소모임(group), 커뮤니티(게시판), 알바, 교배 검색 지원
/// 
/// 주요 기능:
/// - debounce 실시간 검색 (300ms, 최소 2글자)
/// - Enter 키 즉시 검색
/// - 통일된 SearchResultTile UI
/// - 결과 카운트 표시
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
  
  List<dynamic> _results = [];
  bool _isLoading = false;
  String _lastQuery = '';
  Timer? _debounceTimer;
  int _searchVersion = 0;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.removeListener(_onTextChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {}); // clear 버튼 표시/숨김 갱신
    
    final query = _searchController.text.trim();
    
    // 빈 검색어 시 결과 초기화
    if (query.isEmpty) {
      _debounceTimer?.cancel();
      setState(() {
        _lastQuery = '';
        _results = [];
        _isLoading = false;
      });
      return;
    }
    
    // 최소 2글자 이상일 때만 debounce 검색 실행
    if (query.length >= 2) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 300), () {
        _executeSearch(query);
      });
    }
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
    final hasText = _searchController.text.isNotEmpty;
    
    return Padding(
      padding: const EdgeInsets.only(left: AppSizes.paddingL),
      child: MingrrSearchBar(
        controller: _searchController,
        hintText: _getHintText(),
        accentColor: widget.accentColor,
        autofocus: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        onSearch: (query) => _executeSearch(query.trim()),
        suffix: hasText
            ? GestureDetector(
                onTap: () {
                  _searchController.clear();
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: AppSizes.paddingS),
                  child: Icon(
                    AppIcons.close,
                    size: 18,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            : null,
      ),
    );
  }

  String _getHintText() {
    switch (widget.searchType) {
      case SearchType.breeding:
        return '교배 글 제목, 상세 내용으로 검색';
      case SearchType.group:
        return '모임명, 설명, 태그로 검색';
      case SearchType.community:
        return '게시글 제목, 내용, 태그로 검색';
      case SearchType.job:
        return '알바 제목, 설명으로 검색';
      case SearchType.market:
        return '상품, 알바 제목으로 검색';
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
        subtitle: '2글자 이상 입력하면 자동으로 검색됩니다',
      );
    }

    if (_results.isEmpty) {
      return MingrrEmptyState(
        icon: AppIcons.searchOff,
        title: '검색 결과가 없습니다',
        subtitle: '\'$_lastQuery\'에 대한 결과를 찾을 수 없어요',
      );
    }

    return Column(
      children: [
        // 검색 결과 카운트
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL, vertical: AppSizes.paddingS),
          child: Row(
            children: [
              Text(
                '검색 결과',
                style: AppTextStyles.bodySmall(context).withColor(Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(width: AppSizes.gapXS),
              Text(
                '${_results.length}건',
                style: AppTextStyles.bodySmall(context).withWeight(FontWeight.w600).withColor(widget.accentColor),
              ),
            ],
          ),
        ),
        // 검색 결과 목록
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM),
            itemCount: _results.length,
            itemBuilder: (context, index) => _buildResultItem(_results[index]),
          ),
        ),
      ],
    );
  }

  /// 검색 결과 아이템 - 타입별 분기
  Widget _buildResultItem(dynamic item) {
    if (item is ProductModel) return _buildProductTile(item);
    if (item is JobModel) return _buildJobTile(item);
    if (item is GroupModel) return _buildGroupTile(item);
    if (item is CommunityPostModel) return _buildCommunityTile(item);
    if (item is BreedingPostModel) return _buildBreedingTile(item);
    return const SizedBox.shrink();
  }

  /// 상품 검색 결과 타일
  Widget _buildProductTile(ProductModel product) {
    final isShare = product.type == ProductType.share;
    return _SearchResultTile(
      imageUrl: product.imageUrls.isNotEmpty ? product.imageUrls.first : null,
      accentColor: context.features.market,
      badgeText: isShare ? '나눔' : '판매',
      badgeColor: isShare ? context.features.walk : context.features.market,
      title: product.title,
      info: product.priceString,
      infoColor: isShare ? context.features.walk : null,
      time: formatRelativeTime(product.createdAt),
      onTap: () {
        Navigator.pop(context);
        context.push('/market/product/${product.id}');
      },
    );
  }

  /// 알바 검색 결과 타일
  Widget _buildJobTile(JobModel job) {
    return _SearchResultTile(
      imageUrl: job.imageUrls.isNotEmpty ? job.imageUrls.first : null,
      accentColor: context.features.market,
      badgeText: '알바',
      badgeColor: context.features.market,
      title: job.title,
      info: job.priceString,
      infoColor: context.features.market,
      time: formatRelativeTime(job.createdAt),
      onTap: () {
        Navigator.pop(context);
        context.push('/market/job/${job.id}');
      },
    );
  }

  /// 소모임 검색 결과 타일
  Widget _buildGroupTile(GroupModel group) {
    return _SearchResultTile(
      imageUrl: group.imageUrl,
      accentColor: context.features.social,
      title: group.name,
      info: '${group.typeString} · 멤버 ${group.memberCount}명',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppIcons.likeOutlined, size: 12, color: Theme.of(context).colorScheme.outlineVariant),
          const SizedBox(width: 2),
          Text('${group.likeCount}', style: AppTextStyles.captionSmall(context)),
        ],
      ),
      onTap: () {
        Navigator.pop(context);
        context.push('/social/group/${group.id}');
      },
    );
  }

  /// 커뮤니티 검색 결과 타일
  Widget _buildCommunityTile(CommunityPostModel post) {
    final displayTitle = post.title.isNotEmpty
        ? post.title
        : (post.content.length > 30 ? '${post.content.substring(0, 30)}...' : post.content);
    
    return _SearchResultTile(
      imageUrl: post.imageUrls.isNotEmpty ? post.imageUrls.first : null,
      accentColor: context.features.social,
      badgeText: post.category.label,
      badgeColor: context.features.social,
      title: displayTitle,
      info: '좋아요 ${post.likeCount} · 댓글 ${post.commentCount}',
      time: formatRelativeTime(post.createdAt),
      onTap: () {
        Navigator.pop(context);
        context.push('/social/community/${post.id}');
      },
    );
  }

  /// 교배 검색 결과 타일
  Widget _buildBreedingTile(BreedingPostModel breeding) {
    return _SearchResultTile(
      accentColor: context.features.dating,
      badgeText: breeding.status.label,
      badgeColor: context.features.dating,
      title: breeding.title,
      info: breeding.address ?? '위치 미설정',
      time: formatRelativeTime(breeding.createdAt),
      onTap: () {
        Navigator.pop(context);
        context.push('/dating/detail/${breeding.petId}');
      },
    );
  }

  /// 검색 실행 (debounce 또는 Enter)
  Future<void> _executeSearch(String query) async {
    if (query.isEmpty) return;

    final currentVersion = ++_searchVersion;
    
    setState(() {
      _isLoading = true;
      _lastQuery = query;
    });

    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      List<dynamic> results;
      switch (widget.searchType) {
        case SearchType.market:
          results = await firestoreService.searchMarketAll(query);
        case SearchType.group:
          results = await firestoreService.searchGroups(query);
        case SearchType.community:
          results = await firestoreService.searchCommunityPosts(query);
        case SearchType.breeding:
          results = await firestoreService.searchBreedingPosts(query);
        case SearchType.job:
          results = await firestoreService.searchJobs(query);
      }

      // 이전 검색 요청이면 무시 (최신 요청만 반영)
      if (currentVersion != _searchVersion) return;

      if (mounted) setState(() => _results = results);
    } catch (e) {
      if (currentVersion != _searchVersion) return;
      if (mounted) {
        ErrorHandler.showError(context, e, tag: 'Search', operation: '검색');
      }
    } finally {
      if (currentVersion == _searchVersion && mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

/// ============================================================
/// 검색 결과 통합 타일 컴포넌트
/// 
/// 모든 검색 결과(상품, 알바, 소모임, 커뮤니티, 교배)에 일관된 UI를 제공합니다.
/// - 좌측: 썸네일 이미지 (60x60) + 선택적 배지
/// - 중앙: 제목 + 핵심 정보
/// - 우측: 시간 또는 커스텀 trailing
/// ============================================================
class _SearchResultTile extends StatelessWidget {
  final String? imageUrl;
  final Color accentColor;
  final String? badgeText;
  final Color? badgeColor;
  final String title;
  final String info;
  final Color? infoColor;
  final String? time;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SearchResultTile({
    this.imageUrl,
    required this.accentColor,
    this.badgeText,
    this.badgeColor,
    required this.title,
    required this.info,
    this.infoColor,
    this.time,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.paddingS),
      child: Material(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          child: Container(
            padding: const EdgeInsets.all(AppSizes.paddingM),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSizes.radiusM),
              border: Border.all(color: colorScheme.outline.withValues(alpha: AppOpacity.o30)),
            ),
            child: Row(
              children: [
                _buildThumbnail(context),
                const SizedBox(width: AppSizes.gapM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (badgeText != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: AppSizes.paddingXXS),
                          decoration: BoxDecoration(
                            color: (badgeColor ?? accentColor).withValues(alpha: AppOpacity.o10),
                            borderRadius: BorderRadius.circular(AppSizes.radiusS),
                          ),
                          child: Text(
                            badgeText!,
                            style: AppTextStyles.labelSmall(context).withWeight(FontWeight.w600).withColor(badgeColor ?? accentColor),
                          ),
                        ),
                        const SizedBox(height: AppSizes.gapXXS),
                      ],
                      Text(
                        title,
                        style: AppTextStyles.titleMedium(context).withWeight(FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSizes.gapXXS),
                      Text(
                        info,
                        style: AppTextStyles.bodySmall(context).withColor(
                          infoColor ?? colorScheme.onSurfaceVariant,
                        ).withWeight(infoColor != null ? FontWeight.w600 : FontWeight.w400),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (trailing != null)
                  trailing!
                else if (time != null)
                  Text(time!, style: AppTextStyles.captionSmall(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(BuildContext context) {
    return MingrrImage.thumbnail(
      imageUrl: imageUrl,
      width: 60,
      height: 60,
      radius: AppSizes.radiusS,
      accentColor: accentColor,
    );
  }
}
