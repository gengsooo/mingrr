import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/common_widgets.dart';
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('활동 내역'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            // 탭바
            Container(
              color: Colors.white,
              child: const TabBar(
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                tabs: [
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
          return _buildEmptyState(
            icon: Icons.favorite,
            title: '매칭 내역이 없어요',
            subtitle: '데이팅에서 새로운 친구를 만나보세요!',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(AppSizes.paddingM),
          itemCount: matches.length,
          itemBuilder: (context, index) {
            final match = matches[index];
            return _buildActivityItem(
              icon: Icons.favorite,
              iconColor: AppColors.dating,
              title: '새로운 매칭!',
              subtitle: '${match.user1Id}님과 매칭되었어요',
              time: _formatTime(match.createdAt),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('데이터를 불러올 수 없습니다')),
    );
  }
  
  
  Widget _buildTransactionHistory(AsyncValue<dynamic> transactionsAsync) {
    return transactionsAsync.when(
      data: (transactions) {
        if (transactions.isEmpty) {
          return _buildEmptyState(
            icon: Icons.shopping_bag,
            title: '거래 내역이 없어요',
            subtitle: '마켓에서 거래해보세요!',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(AppSizes.paddingM),
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final product = transactions[index];
            return _buildActivityItem(
              icon: Icons.shopping_bag,
              iconColor: AppColors.market,
              title: product.title,
              subtitle: '${product.price.toStringAsFixed(0)}원',
              time: _formatTime(product.createdAt),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('데이터를 불러올 수 없습니다')),
    );
  }
  
  Widget _buildGroupHistory(AsyncValue<dynamic> groupsAsync) {
    return groupsAsync.when(
      data: (groups) {
        if (groups.isEmpty) {
          return _buildEmptyState(
            icon: Icons.groups,
            title: '모임 활동이 없어요',
            subtitle: '소모임에 참여해보세요!',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(AppSizes.paddingM),
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final group = groups[index];
            return _buildActivityItem(
              icon: Icons.groups,
              iconColor: AppColors.community,
              title: group.name,
              subtitle: '멤버 ${group.memberIds.length}명',
              time: _formatTime(group.createdAt),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('데이터를 불러올 수 없습니다')),
    );
  }
  
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActivityItem({
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
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textHint,
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
