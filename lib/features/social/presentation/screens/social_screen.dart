import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/theme/feature_colors.dart';
import '../../../../core/widgets/navigation/appbar_actions.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/navigation/top_navigation.dart';
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
final _selectedTabProvider = StateProvider<int>((ref) => 0);

class SocialScreen extends ConsumerStatefulWidget {
  /// 초기 탭 인덱스 (0: 커뮤니티, 1: 소모임)
  final int initialTab;
  
  const SocialScreen({super.key, this.initialTab = 0});

  @override
  ConsumerState<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends ConsumerState<SocialScreen> {
  @override
  void initState() {
    super.initState();
    // 초기 탭 설정 (항상 initialTab으로 설정하여 이전 상태 무시)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(_selectedTabProvider.notifier).state = widget.initialTab;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = context.features.social;
    final selectedTab = ref.watch(_selectedTabProvider);

    final tabs = [
      MingrrTabItem(label: '커뮤니티', icon: AppIcons.communityOutlined, color: accentColor),
      MingrrTabItem(label: '소모임', icon: AppIcons.group, color: accentColor),
    ];

    return Scaffold(
      backgroundColor: isDark ? colorScheme.surface : context.features.socialContainer,
      appBar: MingrrAppBar.mainTab(
        title: '소셜',
        actions: [
          AppBarActionButton.search(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SearchScreen(
                    searchType: selectedTab == 0 ? SearchType.community : SearchType.group,
                    accentColor: accentColor,
                  ),
                ),
              );
            },
          ),
          AppBarActionButton.notification(),
        ],
      ),
      body: Column(
        children: [
          MingrrMainTabBar(
            tabs: tabs,
            selectedIndex: selectedTab,
            onTabSelected: (index) {
              ref.read(_selectedTabProvider.notifier).state = index;
            },
          ),
          Expanded(
            child: IndexedStack(
              index: selectedTab,
              children: const [
                CommunityScreen(),
                GroupListScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
