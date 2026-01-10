import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/svg_icons.dart';
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
  
  final _tabs = const [
    Tab(text: '전체'),
    Tab(text: '데이팅'),
    Tab(text: '채팅'),
    Tab(text: '마켓'),
    Tab(text: '소모임'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            const Text('알림'),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  unreadCount > 99 ? '99+' : '$unreadCount',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: () => _markAllAsRead(),
              child: const Text('전체 읽음'),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textHint,
          indicatorColor: AppColors.primary,
          isScrollable: true,
          tabs: _tabs,
        ),
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return _buildEmptyState();
          }
          
          return TabBarView(
            controller: _tabController,
            children: [
              // 전체
              _buildNotificationList(notifications),
              // 데이팅
              _buildNotificationList(
                notifications.where((n) => 
                  n.type.category == 'dating' || n.type.category == 'breeding'
                ).toList(),
              ),
              // 채팅
              _buildNotificationList(
                notifications.where((n) => n.type.category == 'chat').toList(),
              ),
              // 마켓
              _buildNotificationList(
                notifications.where((n) => n.type.category == 'market').toList(),
              ),
              // 소모임
              _buildNotificationList(
                notifications.where((n) => n.type.category == 'community').toList(),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.textHint),
              const SizedBox(height: 16),
              const Text('알림을 불러올 수 없습니다'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.invalidate(userNotificationsProvider),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const MingrrSvgIcon(
            assetPath: SvgAssets.emptyNotification,
            width: 120,
            height: 120,
          ),
          const SizedBox(height: 16),
          const Text(
            '알림이 없습니다',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '새로운 소식이 있으면 알려드릴게요!',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList(List<NotificationModel> notifications) {
    if (notifications.isEmpty) {
      return _buildEmptyState();
    }

    // 날짜별 그룹핑
    final grouped = <String, List<NotificationModel>>{};
    for (final notification in notifications) {
      final dateKey = _getDateKey(notification.createdAt);
      grouped.putIfAbsent(dateKey, () => []).add(notification);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingS),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final dateKey = grouped.keys.elementAt(index);
        final items = grouped[dateKey]!;
        
        return Column(
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
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            // 알림 아이템들
            ...items.map((n) => _buildNotificationItem(n)),
          ],
        );
      },
    );
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    return InkWell(
      onTap: () => _onNotificationTap(notification),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.paddingM),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.white : AppColors.primaryPale,
          border: Border(
            bottom: BorderSide(color: AppColors.divider.withOpacity(0.5)),
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
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getNotificationIcon(notification.type),
                color: _getIconColor(notification.type),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
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
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: notification.isRead 
                                ? FontWeight.w500 
                                : FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(notification.createdAt),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textHint,
                    ),
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
      case NotificationType.likeReceived:
      case NotificationType.likeAccepted:
        return Icons.favorite;
      case NotificationType.matchSuccess:
        return Icons.celebration;
      case NotificationType.breedingRequest:
      case NotificationType.breedingAccepted:
        return Icons.pets;
      case NotificationType.newMessage:
        return Icons.chat_bubble;
      case NotificationType.productInquiry:
      case NotificationType.productSold:
        return Icons.store;
      case NotificationType.groupJoinRequest:
      case NotificationType.groupJoinAccepted:
      case NotificationType.groupNewSchedule:
        return Icons.groups;
      case NotificationType.system:
        return Icons.info;
    }
  }

  Color _getIconColor(NotificationType type) {
    switch (type.category) {
      case 'dating':
      case 'breeding':
        return AppColors.dating;
      case 'chat':
        return AppColors.chat;
      case 'market':
        return AppColors.market;
      case 'community':
        return AppColors.community;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _getIconBackgroundColor(NotificationType type) {
    switch (type.category) {
      case 'dating':
      case 'breeding':
        return AppColors.datingLight;
      case 'chat':
        return AppColors.chatLight;
      case 'market':
        return AppColors.marketLight;
      case 'community':
        return AppColors.communityLight;
      default:
        return AppColors.divider;
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('모든 알림을 읽음 처리했습니다'),
          backgroundColor: AppColors.success,
        ),
      );
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
