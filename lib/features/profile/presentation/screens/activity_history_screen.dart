import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/feature_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/svg_icons.dart';
import '../../../dating/presentation/providers/dating_provider.dart';
import '../providers/profile_provider.dart';

/// 활동 내역 화면
class ActivityHistoryScreen extends ConsumerWidget {
  const ActivityHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(userMatchesProvider);
    final transactionsAsync = ref.watch(userTransactionsProvider);
    final groupsAsync = ref.watch(userGroupsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('활동 내역'),
      ),
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            // 탭바
            Container(
              color: Theme.of(context).colorScheme.surface,
              child: TabBar(
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
                indicatorColor: Theme.of(context).colorScheme.primary,
                tabs: const [
                  Tab(text: '매칭'),
                  Tab(text: '거래'),
                  Tab(text: '모임'),
                ],
              ),
            ),
            // 탭 컨텐츠
            Expanded(
              child: TabBarView(
                children: [
                  _buildMatchingHistory(matchesAsync),
                  _buildTransactionHistory(transactionsAsync),
                  _buildGroupHistory(groupsAsync),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMatchingHistory(AsyncValue<dynamic> matchesAsync) {
    return matchesAsync.when(
      data: (matches) {
        if (matches.isEmpty) {
          return MingrrEmptyState(
            icon: Icons.favorite_border,
            title: '매칭 내역이 없어요',
            subtitle: '데이팅에서 새로운 친구를 만나보세요',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(AppSizes.paddingM),
          itemCount: matches.length,
          itemBuilder: (context, index) {
            final match = matches[index];
            return _buildActivityItem(
              context,
              icon: Icons.favorite,
              iconColor: context.features.dating,
              title: '새로운 매칭!',
              subtitle: '${match.user1Id}님과 매칭되었어요',
              time: _formatTime(match.createdAt),
            );
          },
        );
      },
      loading: () => const MingrrLoadingState(),
      error: (_, __) => const MingrrErrorState(title: '일시적인 오류가 발생했어요', subtitle: '잠시 후 다시 시도해주세요'),
    );
  }
  
  
  Widget _buildTransactionHistory(AsyncValue<dynamic> transactionsAsync) {
    return transactionsAsync.when(
      data: (transactions) {
        if (transactions.isEmpty) {
          return MingrrEmptyState(
            icon: Icons.receipt_long_outlined,
            title: '거래 내역이 없어요',
            subtitle: '마켓에서 거래해보세요',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(AppSizes.paddingM),
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final product = transactions[index];
            return _buildActivityItem(
              context,
              icon: Icons.shopping_bag,
              iconColor: context.features.market,
              title: product.title,
              subtitle: '${product.price.toStringAsFixed(0)}원',
              time: _formatTime(product.createdAt),
            );
          },
        );
      },
      loading: () => const MingrrLoadingState(),
      error: (_, __) => const MingrrErrorState(title: '일시적인 오류가 발생했어요', subtitle: '잠시 후 다시 시도해주세요'),
    );
  }
  
  Widget _buildGroupHistory(AsyncValue<dynamic> groupsAsync) {
    return groupsAsync.when(
      data: (groups) {
        if (groups.isEmpty) {
          return MingrrEmptyState(
            icon: Icons.groups_outlined,
            title: '소모임 활동이 없어요',
            subtitle: '소모임에 참여해보세요',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(AppSizes.paddingM),
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final group = groups[index];
            return _buildActivityItem(
              context,
              icon: Icons.groups,
              iconColor: context.features.social,
              title: group.name,
              subtitle: '멤버 ${group.memberIds.length}명',
              time: _formatTime(group.createdAt),
            );
          },
        );
      },
      loading: () => const MingrrLoadingState(),
      error: (_, __) => const MingrrErrorState(title: '일시적인 오류가 발생했어요', subtitle: '잠시 후 다시 시도해주세요'),
    );
  }
  
  
  Widget _buildActivityItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String time,
  }) {
    return MingrrCard(
      margin: const EdgeInsets.only(bottom: AppSizes.gapM),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
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
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    return '${dateTime.month}/${dateTime.day}';
  }
}
