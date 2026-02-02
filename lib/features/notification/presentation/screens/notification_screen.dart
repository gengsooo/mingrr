import 'package:flutter/material.dart';
import '../../../../core/constants/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/feature_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/badges/svg_icons.dart';
import '../../../../core/widgets/navigation/top_navigation.dart';
import '../../../../core/widgets/refresh_wrapper.dart';
import '../../../../models/notification_model.dart';
import '../providers/notification_provider.dart';

/// ============================================================
/// 알림 화면
/// 
/// 기능:
/// - 알림 목록 표시 (카테고리별 필터링)
/// - 읽음/안읽음 표시
/// - 알림 클릭 시 해당 화면으로 이동
/// - 전체 읽음 처리
/// ============================================================
class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  static const _tabLabels = ['전체', '데이팅', '채팅', '마켓', '소모임'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabLabels.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(userNotificationsProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('알림'),
            if (unreadCount > 0) ...[
              const SizedBox(width: AppSizes.gapS),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingS, vertical: AppSizes.paddingXXS),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(AppSizes.radiusS),
                ),
                child: Text(
                  unreadCount > 99 ? '99+' : '$unreadCount',
                  style: AppTextStyles.labelLarge(context).withWeight(FontWeight.w600).withColor(Colors.white),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: () => _markAllAsRead(),
              child: const Text('전체 읽음'),
            ),
        ],
        bottom: MingrrSubTabBar(
          tabs: _tabLabels,
          controller: _tabController,
          isScrollable: false,
        ),
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return const MingrrEmptyState(
              icon: AppIcons.notificationsNone,
              title: '알림이 없어요',
              subtitle: '새로운 소식이 있으면 알려드릴게요',
            );
          }
          
          return TabBarView(
            controller: _tabController,
            children: [
              // 전체
              _buildNotificationList(ref, notifications),
              // 데이팅
              _buildNotificationList(
                ref,
                notifications.where((n) => 
                  n.type.category == 'dating' || n.type.category == 'breeding'
                ).toList(),
              ),
              // 채팅
              _buildNotificationList(
                ref,
                notifications.where((n) => n.type.category == 'chat').toList(),
              ),
              // 마켓
              _buildNotificationList(
                ref,
                notifications.where((n) => n.type.category == 'market').toList(),
              ),
              // 소모임
              _buildNotificationList(
                ref,
                notifications.where((n) => n.type.category == 'community').toList(),
              ),
            ],
          );
        },
        loading: () => const MingrrLoadingState(
          type: MingrrLoadingType.primary,
          message: '알림을 불러오고 있어요',
        ),
        error: (_, __) => MingrrErrorState(
          title: '일시적인 오류가 발생했어요',
          subtitle: '잠시 후 다시 시도해주세요',
          buttonText: '다시 시도',
          onRetry: () => ref.invalidate(userNotificationsProvider),
        ),
      ),
    );
  }


  Widget _buildNotificationList(WidgetRef ref, List<NotificationModel> notifications) {
    if (notifications.isEmpty) {
      return const MingrrEmptyState(
        icon: AppIcons.notificationsNone,
        title: '알림이 없어요',
        subtitle: '새로운 소식이 있으면 알려드릴게요',
      );
    }

    // 날짜별 그룹핑
    final grouped = <String, List<NotificationModel>>{};
    for (final notification in notifications) {
      final dateKey = _getDateKey(notification.createdAt);
      grouped.putIfAbsent(dateKey, () => []).add(notification);
    }

    return MingrrRefreshWrapper(
      color: Theme.of(context).colorScheme.primary,
      onRefresh: () async {
        ref.invalidate(userNotificationsProvider);
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingS),
        itemCount: grouped.length,
        itemBuilder: (context, index) {
          final dateKey = grouped.keys.elementAt(index);
          final items = grouped[dateKey]!;
          
          return MingrrAnimatedListItem(
            index: index,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 날짜 헤더
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingM,
                    vertical: AppSizes.paddingS,
                  ),
                  child: Text(
                    dateKey,
                    style: AppTextStyles.titleSmall(context).withWeight(FontWeight.w600).withColor(Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ),
                // 알림 아이템들
                ...items.map((n) => _buildNotificationItem(n)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    return InkWell(
      onTap: () => _onNotificationTap(notification),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.paddingM),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.white : Theme.of(context).colorScheme.primaryContainer,
          border: Border(
            bottom: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: AppOpacity.o50)),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 아이콘
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _getIconBackgroundColor(notification.type),
                borderRadius: BorderRadius.circular(AppSizes.radiusS),
              ),
              child: Icon(
                _getNotificationIcon(notification.type),
                color: _getIconColor(notification.type),
                size: 22,
              ),
            ),
            const SizedBox(width: AppSizes.gapM),
            // 내용
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: AppTextStyles.titleLarge(context).withWeight(notification.isRead ? FontWeight.w500 : FontWeight.w600),
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.gapM),
                  Text(
                    notification.body,
                    style: AppTextStyles.bodyMedium(context).withColor(Theme.of(context).colorScheme.onSurfaceVariant),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSizes.gapM),
                  Text(
                    _formatTime(notification.createdAt),
                    style: AppTextStyles.caption(context).withColor(Theme.of(context).colorScheme.outlineVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.datingRequest:
      case NotificationType.datingAccepted:
        return AppIcons.dating;
      case NotificationType.matchSuccess:
        return AppIcons.celebration;
      case NotificationType.petLike:
        return AppIcons.dating;
      case NotificationType.breedingRequest:
      case NotificationType.breedingAccepted:
        return AppIcons.breeding;
      case NotificationType.newMessage:
        return AppIcons.chatBubble;
      case NotificationType.productInquiry:
      case NotificationType.productSold:
        return AppIcons.market;
      case NotificationType.groupJoinRequest:
      case NotificationType.groupJoinAccepted:
      case NotificationType.groupNewSchedule:
        return AppIcons.group;
      case NotificationType.system:
        return AppIcons.info;
    }
  }

  Color _getIconColor(NotificationType type) {
    switch (type.category) {
      case 'dating':
      case 'breeding':
        return context.features.dating;
      case 'chat':
        return context.features.chat;
      case 'market':
        return context.features.market;
      case 'community':
        return context.features.social;
      default:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  Color _getIconBackgroundColor(NotificationType type) {
    switch (type.category) {
      case 'dating':
      case 'breeding':
        return context.features.datingContainer;
      case 'chat':
        return context.features.chat.withValues(alpha: AppOpacity.o20);
      case 'market':
        return context.features.marketContainer;
      case 'community':
        return context.features.socialContainer;
      default:
        return Theme.of(context).colorScheme.outline;
    }
  }

  String _getDateKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final notificationDate = DateTime(date.year, date.month, date.day);

    if (notificationDate == today) {
      return '오늘';
    } else if (notificationDate == yesterday) {
      return '어제';
    } else if (now.difference(date).inDays < 7) {
      return '이번 주';
    } else {
      return '${date.month}월 ${date.day}일';
    }
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) {
      return '방금 전';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}분 전';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}시간 전';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}일 전';
    } else {
      return '${date.month}/${date.day}';
    }
  }

  void _onNotificationTap(NotificationModel notification) async {
    // 읽음 처리
    if (!notification.isRead) {
      await ref.read(notificationServiceProvider).markAsRead(notification.id);
    }

    if (!mounted) return;

    // 해당 화면으로 이동
    final data = notification.data;
    if (data == null) return;

    final targetId = data['targetId'] as String?;
    final targetType = data['targetType'] as String?;

    if (targetId == null || targetType == null) return;

    switch (targetType) {
      case 'chat':
        context.push('/chat/$targetId');
        break;
      case 'pet':
        context.push('/dating/detail/$targetId');
        break;
      case 'product':
        context.push('/market/product/$targetId');
        break;
      case 'group':
        context.push('/community/group/$targetId');
        break;
      case 'like':
        // 받은 좋아요 화면으로 이동
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const _ReceivedLikesNavigator(),
          ),
        );
        break;
    }
  }

  void _markAllAsRead() async {
    await ref.read(notificationServiceProvider).markAllAsRead();
    if (mounted) {
      MingrrSnackBar.success(context, '모든 알림을 읽음 처리했습니다');
    }
  }
}

/// 받은 좋아요 화면으로 이동하기 위한 임시 위젯
class _ReceivedLikesNavigator extends StatelessWidget {
  const _ReceivedLikesNavigator();

  @override
  Widget build(BuildContext context) {
    // 실제 받은 좋아요 화면 import 후 사용
    return Scaffold(
      appBar: AppBar(title: const Text('받은 좋아요')),
      body: const Center(child: Text('받은 좋아요 화면')),
    );
  }
}
