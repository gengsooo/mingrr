import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/feature_colors.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/mingrr_image.dart';
import '../../../../core/widgets/navigation/top_navigation.dart';
import '../../../../models/community_post_model.dart';
import '../../../../models/marketplace_model.dart';
import '../providers/activity_provider.dart';

/// ============================================================
/// 내 활동 화면
/// 
/// 프로필 > 내 활동
/// 탭 구성: 산책 / 매칭 / 거래 / 커뮤니티 / 모임 (5탭)
/// ============================================================

class MyActivityScreen extends ConsumerWidget {
  const MyActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: const MingrrAppBar(title: '내 활동'),
      body: DefaultTabController(
        length: 5,
        child: Column(
          children: [
            const MingrrSubTabBar(
              tabs: ['산책', '매칭', '거래', '커뮤니티', '모임'],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _WalkHistoryTab(),
                  _MatchHistoryTab(),
                  _TransactionHistoryTab(),
                  _CommunityHistoryTab(),
                  _GroupHistoryTab(),
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
// 1. 산책 탭
// ============================================================

class _WalkHistoryTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walksAsync = ref.watch(userWalkRecordsProvider);
    
    return walksAsync.when(
      data: (walks) {
        if (walks.isEmpty) {
          return MingrrEmptyState(
            icon: AppIcons.walk,
            title: '산책 기록이 없어요',
            subtitle: '반려동물과 함께 산책을 시작해보세요',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(AppSizes.paddingM),
          itemCount: walks.length,
          itemBuilder: (context, index) {
            final walk = walks[index];
            return _ActivityCard(
              onTap: () => context.push('/health/walk/${walk.id}'),
              icon: AppIcons.walk,
              iconColor: context.features.walk,
              title: '${walk.durationMinutes}분 산책',
              subtitle: walk.distanceString,
              trailing: _formatDate(walk.startTime),
            );
          },
        );
      },
      loading: () => const MingrrLoadingState(
        type: MingrrLoadingType.walk,
        message: '산책 기록을 불러오고 있어요',
      ),
      error: (_, __) => MingrrErrorState(
        onRetry: () => ref.invalidate(userWalkRecordsProvider),
      ),
    );
  }
}

// ============================================================
// 2. 매칭 탭 (보낸 신청 + 받은 신청 + 성사된 매칭)
// ============================================================

class _MatchHistoryTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activitiesAsync = ref.watch(userMatchActivitiesProvider);
    
    return activitiesAsync.when(
      data: (activities) {
        if (activities.isEmpty) {
          return MingrrEmptyState(
            icon: AppIcons.likeOutlined,
            title: '매칭 내역이 없어요',
            subtitle: '데이팅에서 새로운 친구를 만나보세요',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(AppSizes.paddingM),
          itemCount: activities.length,
          itemBuilder: (context, index) {
            final activity = activities[index];
            return _MatchActivityCard(activity: activity);
          },
        );
      },
      loading: () => const MingrrLoadingState(
        type: MingrrLoadingType.dating,
        message: '매칭 내역을 불러오고 있어요',
      ),
      error: (_, __) => MingrrErrorState(
        onRetry: () => ref.invalidate(userMatchActivitiesProvider),
      ),
    );
  }
}

/// 매칭 활동 카드 (보낸 신청, 받은 신청, 성사된 매칭)
class _MatchActivityCard extends StatelessWidget {
  final MatchActivity activity;

  const _MatchActivityCard({required this.activity});

  @override
  Widget build(BuildContext context) {
    final (icon, label, color) = _getActivityStyle(context);
    final statusBadge = _getStatusBadge(context);
    
    return _ActivityCard(
      onTap: activity.chatRoomId != null 
          ? () => context.push('/chat/${activity.chatRoomId}')
          : null,
      imageUrl: activity.partnerPetImageUrl,
      icon: icon,
      iconColor: color,
      title: activity.partnerPetName,
      subtitle: '${activity.partnerPetBreed ?? '반려동물'} · $label',
      trailing: _formatDate(activity.createdAt),
      badge: statusBadge?.label,
      badgeColor: statusBadge?.color,
    );
  }

  (IconData, String, Color) _getActivityStyle(BuildContext context) {
    final typeLabel = activity.isBreeding ? '교배' : '데이팅';
    switch (activity.type) {
      case MatchActivityType.sent:
        return (activity.isBreeding ? AppIcons.breeding : AppIcons.send, '보낸 $typeLabel 신청', context.features.dating);
      case MatchActivityType.received:
        return (activity.isBreeding ? AppIcons.breeding : AppIcons.empty, '받은 $typeLabel 신청', context.features.dating);
      case MatchActivityType.matched:
        return (activity.isBreeding ? AppIcons.breeding : AppIcons.dating, '$typeLabel 매칭 성사', context.features.success);
    }
  }

  ({String label, Color color})? _getStatusBadge(BuildContext context) {
    if (activity.type == MatchActivityType.matched) return null;
    
    switch (activity.status) {
      case 'pending':
        return (label: '대기 중', color: context.features.warning);
      case 'accepted':
        return (label: '수락됨', color: context.features.success);
      case 'rejected':
        return (label: '거절됨', color: Theme.of(context).colorScheme.error);
      default:
        return null;
    }
  }
}

// ============================================================
// 3. 거래 탭
// ============================================================

class _TransactionHistoryTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(userTransactionsWithDetailsProvider);
    
    return transactionsAsync.when(
      data: (transactions) {
        if (transactions.isEmpty) {
          return MingrrEmptyState(
            icon: AppIcons.history,
            title: '거래 내역이 없어요',
            subtitle: '마켓에서 거래해보세요',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(AppSizes.paddingM),
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final tx = transactions[index];
            final isSell = tx.type == TransactionType.sell;
            return _ActivityCard(
              onTap: () => context.push('/market/product/${tx.product.id}'),
              imageUrl: tx.product.imageUrls.isNotEmpty ? tx.product.imageUrls.first : null,
              icon: isSell ? AppIcons.sell : AppIcons.shoppingBag,
              iconColor: context.features.market,
              title: tx.product.title,
              subtitle: '${tx.product.priceString} · ${isSell ? "판매" : "구매"}',
              trailing: _formatDate(tx.product.createdAt),
              badge: tx.product.status.label,
              badgeColor: tx.product.status == ProductStatus.completed 
                  ? context.features.success 
                  : context.features.market,
            );
          },
        );
      },
      loading: () => const MingrrLoadingState(
        type: MingrrLoadingType.market,
        message: '거래 내역을 불러오고 있어요',
      ),
      error: (_, __) => MingrrErrorState(
        onRetry: () => ref.invalidate(userTransactionsWithDetailsProvider),
      ),
    );
  }
}

// ============================================================
// 4. 커뮤니티 탭
// ============================================================

class _CommunityHistoryTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activitiesAsync = ref.watch(userCommunityActivitiesProvider);
    
    return activitiesAsync.when(
      data: (activities) {
        if (activities.isEmpty) {
          return MingrrEmptyState(
            icon: AppIcons.communityOutlined,
            title: '커뮤니티 활동이 없어요',
            subtitle: '커뮤니티에서 글을 작성해보세요',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(AppSizes.paddingM),
          itemCount: activities.length,
          itemBuilder: (context, index) {
            final activity = activities[index];
            final isPost = activity.type == CommunityActivityType.post;
            
            return _ActivityCard(
              onTap: () => context.push('/social/community/${isPost ? activity.id : activity.postId}'),
              icon: isPost ? AppIcons.community : AppIcons.chatOutlined,
              iconColor: context.features.social,
              title: isPost ? activity.title : '댓글: ${activity.title}',
              subtitle: isPost 
                  ? '${activity.category?.label ?? ""} · 💬 ${activity.commentCount} · ❤️ ${activity.likeCount}'
                  : '원글: ${activity.postTitle ?? "삭제된 글"}',
              trailing: _formatDate(activity.createdAt),
            );
          },
        );
      },
      loading: () => const MingrrLoadingState(
        type: MingrrLoadingType.community,
        message: '커뮤니티 활동을 불러오고 있어요',
      ),
      error: (_, __) => MingrrErrorState(
        onRetry: () => ref.invalidate(userCommunityActivitiesProvider),
      ),
    );
  }
}

// ============================================================
// 5. 모임 탭
// ============================================================

class _GroupHistoryTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(userGroupsWithSchedulesProvider);
    
    return groupsAsync.when(
      data: (groups) {
        if (groups.isEmpty) {
          return MingrrEmptyState(
            icon: AppIcons.group,
            title: '소모임 활동이 없어요',
            subtitle: '소모임에 참여해보세요',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(AppSizes.paddingM),
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final groupWithSchedules = groups[index];
            final group = groupWithSchedules.group;
            final nextSchedule = groupWithSchedules.nextSchedule;
            
            return _GroupActivityCard(
              onTap: () => context.push('/social/group/${group.id}'),
              imageUrl: group.imageUrl,
              title: group.name,
              memberCount: group.memberCount,
              nextSchedule: nextSchedule,
            );
          },
        );
      },
      loading: () => const MingrrLoadingState(
        type: MingrrLoadingType.community,
        message: '소모임 활동을 불러오고 있어요',
      ),
      error: (_, __) => MingrrErrorState(
        onRetry: () => ref.invalidate(userGroupsWithSchedulesProvider),
      ),
    );
  }
}

// ============================================================
// 공통 컴포넌트
// ============================================================

/// 활동 카드 (공통)
class _ActivityCard extends StatelessWidget {
  final VoidCallback? onTap;
  final String? imageUrl;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String trailing;
  final String? badge;
  final Color? badgeColor;

  const _ActivityCard({
    this.onTap,
    this.imageUrl,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.trailing,
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
            MingrrImage.thumbnail(
              imageUrl: imageUrl,
              width: 56,
              height: 56,
              radius: AppSizes.radiusS,
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTextStyles.titleMedium(context).withWeight(FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: AppSizes.gapS),
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
                      ),
                    ],
                  ],
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
          const SizedBox(width: AppSizes.gapS),
          
          // 날짜
          Text(
            trailing,
            style: AppTextStyles.caption(context).withColor(colorScheme.outline),
          ),
        ],
      ),
    );
  }
  
  Widget _buildIconContainer(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: AppOpacity.o10),
        borderRadius: BorderRadius.circular(AppSizes.radiusS),
      ),
      child: Icon(icon, color: iconColor, size: 28),
    );
  }
}

/// 모임 활동 카드 (일정 포함)
class _GroupActivityCard extends StatelessWidget {
  final VoidCallback? onTap;
  final String? imageUrl;
  final String title;
  final int memberCount;
  final dynamic nextSchedule;

  const _GroupActivityCard({
    this.onTap,
    this.imageUrl,
    required this.title,
    required this.memberCount,
    this.nextSchedule,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return MingrrCard(
      margin: const EdgeInsets.only(bottom: AppSizes.gapM),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 이미지
              MingrrImage.thumbnail(
                imageUrl: imageUrl,
                width: 56,
                height: 56,
                radius: AppSizes.radiusS,
                errorWidget: _buildDefaultImage(context),
              ),
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
                      '멤버 $memberCount명',
                      style: AppTextStyles.bodySmall(context).withColor(colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              
              Icon(AppIcons.chevronRight, color: colorScheme.outlineVariant),
            ],
          ),
          
          // 다음 일정
          if (nextSchedule != null) ...[
            const SizedBox(height: AppSizes.gapM),
            Container(
              padding: const EdgeInsets.all(AppSizes.paddingS),
              decoration: BoxDecoration(
                color: context.features.socialContainer,
                borderRadius: BorderRadius.circular(AppSizes.radiusS),
              ),
              child: Row(
                children: [
                  Icon(AppIcons.event, size: 16, color: context.features.social),
                  const SizedBox(width: AppSizes.gapS),
                  Expanded(
                    child: Text(
                      '다음 일정: ${_formatScheduleDate(nextSchedule.startTime)} · ${nextSchedule.title}',
                      style: AppTextStyles.bodySmall(context).withColor(context.features.social),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildDefaultImage(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: context.features.socialContainer,
        borderRadius: BorderRadius.circular(AppSizes.radiusS),
      ),
      child: Icon(AppIcons.group, color: context.features.social, size: 28),
    );
  }
  
  String _formatScheduleDate(DateTime date) {
    return '${date.month}/${date.day} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

// ============================================================
// 유틸리티
// ============================================================

String _formatDate(DateTime date) {
  final now = DateTime.now();
  final diff = now.difference(date);
  
  if (diff.inDays == 0) return '오늘';
  if (diff.inDays == 1) return '어제';
  if (diff.inDays < 7) return '${diff.inDays}일 전';
  return '${date.month}/${date.day}';
}

