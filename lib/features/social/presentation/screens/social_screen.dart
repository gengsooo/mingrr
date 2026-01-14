import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/feature_colors.dart';
import '../../../../core/widgets/profile_icon.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/search_screen.dart';
import 'community_screen.dart';
import 'group_list_screen.dart';

/// ============================================================
/// 소셜(Social) 메인 화면
/// 
/// 명칭 규칙:
/// - 소셜(Social): 메인 메뉴명, 상위 폴더
/// - 커뮤니티(Community): 게시판 기능 (community_*)
/// - 소모임(Group): 그룹 모임 기능 (group_*)
/// 
/// 탭 구조:
/// - 커뮤니티: 게시판 (CommunityScreen)
/// - 소모임: 그룹 모임 목록 (GroupListScreen)
/// ============================================================

/// 현재 선택된 탭 인덱스
final socialTabIndexProvider = StateProvider<int>((ref) => 0);

class SocialScreen extends ConsumerStatefulWidget {
  const SocialScreen({super.key});

  @override
  ConsumerState<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends ConsumerState<SocialScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ref.read(socialTabIndexProvider.notifier).state = _tabController.index;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = context.features.social;

    return Scaffold(
      backgroundColor: isDark ? colorScheme.surface : context.features.socialContainer,
      appBar: AppBar(
        title: const Text('소셜'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              final currentTab = _tabController.index;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SearchScreen(
                    searchType: currentTab == 0 ? SearchType.community : SearchType.group,
                    accentColor: accentColor,
                  ),
                ),
              );
            },
          ),
          const NotificationIconButton(),
          buildProfileAction(backgroundColor: Theme.of(context).scaffoldBackgroundColor),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outline.withOpacity(0.2),
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: accentColor,
              indicatorWeight: 3,
              labelColor: accentColor,
              unselectedLabelColor: colorScheme.onSurfaceVariant,
              labelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.article_outlined, size: 18),
                      SizedBox(width: 6),
                      Text('커뮤니티'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.groups_outlined, size: 18),
                      SizedBox(width: 6),
                      Text('소모임'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          CommunityScreen(),
          GroupListScreen(),
        ],
      ),
    );
  }
}
