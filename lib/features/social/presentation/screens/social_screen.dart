import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/feature_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/top_navigation.dart';
import '../../../../core/widgets/profile_icon.dart';
import '../../../../core/widgets/common_widgets.dart';
import 'feed_screen.dart';
import 'group_list_screen.dart';

/// ============================================================
/// 소셜 메인 화면
/// 
/// 탭 구조:
/// - 커뮤니티: SNS형 게시판 (피드)
/// - 소모임: 그룹 모임
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
    final accentColor = context.features.community;

    return Scaffold(
      backgroundColor: isDark ? colorScheme.surface : context.features.communityContainer,
      appBar: AppBar(
        title: const Text('소셜'),
        actions: [
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
                Tab(text: '커뮤니티'),
                Tab(text: '소모임'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          FeedScreen(),
          GroupListScreen(),
        ],
      ),
    );
  }
}
