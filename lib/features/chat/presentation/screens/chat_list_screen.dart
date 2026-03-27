import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/feature_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/pet_constants.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/navigation/appbar_actions.dart';
import '../../../../core/widgets/filter_chip_bar.dart';
import '../../../../models/chat_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/chat_provider.dart';

/// ============================================================
/// 채팅 목록 화면 (V4 - 반려동물 전용 + 교배 배지)
/// 
/// 변경사항:
/// - 3개 탭 (데이팅/소모임/마켓) - pill 형태
/// - 채팅 컬러 (퍼플/라벤더) 적용
/// - 교배 채팅은 데이팅 탭 내에서 배지로 표시
/// ============================================================

/// 선택된 채팅 필터 (null = 전체)
final _selectedChatFilterProvider = StateProvider<String?>((ref) => null);

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFilter = ref.watch(_selectedChatFilterProvider);
    final accent = context.features.dating;
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: MingrrAppBar.mainTab(
        title: '채팅',
        actions: [
          AppBarActionButton.notification(),
        ],
      ),
      body: Column(
        children: [
          // 필터 칩 바 (전체 | 데이팅 | 마켓 | 소모임)
          _buildFilterChips(context, ref, selectedFilter, accent, colorScheme),
          
          // 채팅 목록
          Expanded(
            child: _buildFilteredChatList(context, ref, selectedFilter),
          ),
        ],
      ),
    );
  }

  /// 필터 칩 바
  Widget _buildFilterChips(BuildContext context, WidgetRef ref, String? selected, Color accent, ColorScheme colorScheme) {
    return MingrrFilterChipBar<String?>(
      items: const [
        (key: null, label: '전체'),
        (key: 'dating', label: '데이팅'),
        (key: 'market', label: '마켓'),
        (key: 'group', label: '소모임'),
      ],
      selected: selected,
      onSelected: (key) => ref.read(_selectedChatFilterProvider.notifier).state = key,
      accentColor: accent,
    );
  }

  /// 필터링된 채팅 목록
  Widget _buildFilteredChatList(BuildContext context, WidgetRef ref, String? filter) {
    final chatRoomsAsync = ref.watch(userChatRoomsProvider);
    final currentUserId = ref.watch(authStateProvider).valueOrNull?.uid;

    return chatRoomsAsync.when(
      data: (allChatRooms) {
        final filteredRooms = filter == null
            ? allChatRooms
            : allChatRooms.where((room) {
                if (filter == 'dating') return room.type == 'dating' || room.type == 'breeding';
                return room.type == filter;
              }).toList();

        if (filteredRooms.isEmpty) {
          return MingrrEmptyState(
            icon: AppIcons.chatOutlined,
            title: '아직 채팅이 없어요',
            subtitle: filter == null ? '채팅을 시작해보세요' : '해당 유형의 채팅이 없어요',
            accentColor: context.features.dating,
            onRefresh: () async => ref.invalidate(userChatRoomsProvider),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPaddingH),
          itemCount: filteredRooms.length,
          itemBuilder: (context, index) {
            final room = filteredRooms[index];
            final chatType = _getChatType(room.type);
            return MingrrAnimatedListItem(
              index: index,
              child: _buildChatRoomItem(context, ref, room, chatType, currentUserId ?? ''),
            );
          },
        );
      },
      loading: () => MingrrLoadingState(
        type: MingrrLoadingType.chat,
        message: '채팅 목록을 불러오고 있어요',
      ),
      error: (_, _) => MingrrErrorState(
        onRetry: () => ref.invalidate(userChatRoomsProvider),
      ),
    );
  }

  /// 문자열 타입을 ChatType으로 변환
  ChatType _getChatType(String type) {
    switch (type) {
      case 'dating': return ChatType.dating;
      case 'breeding': return ChatType.breeding;
      case 'market': return ChatType.market;
      case 'group': return ChatType.group;
      default: return ChatType.dating;
    }
  }

  /// Firebase ChatRoomModel을 사용한 채팅 아이템
  Widget _buildChatRoomItem(BuildContext context, WidgetRef ref, ChatRoomModel room, ChatType type, String currentUserId) {
    final otherParticipant = room.getOtherParticipant(currentUserId);
    final unreadCount = room.unreadCounts[currentUserId] ?? 0;
    final hasUnread = unreadCount > 0;
    final isBreeding = room.type == 'breeding';
    final isDating = room.type == 'dating' || room.type == 'breeding';
    final isMarket = room.type == 'marketplace' || room.type == 'market';
    final isGroup = room.type == 'community' || room.type == 'group';
    
    // 소모임인 경우 소모임 이름 조회
    String? groupName;
    if (isGroup && room.relatedId != null) {
      groupName = ref.watch(groupNameProvider(room.relatedId!)).valueOrNull;
    }
    
    // 타입별 표시 정보 결정
    // 데이팅/교배: 반려동물 이미지 + 반려동물명 (보호자명)
    // 마켓: 보호자 이미지 + 보호자명
    // 소모임: 모임 아이콘 + 모임명
    String displayName;
    String? displayImage;
    String? subtitle;
    IconData placeholderIcon;
    
    if (isDating) {
      // 데이팅/교배: 반려동물 중심
      displayName = otherParticipant?.petName ?? otherParticipant?.nickname ?? '알 수 없음';
      displayImage = otherParticipant?.petImageUrl ?? otherParticipant?.profileImageUrl;
      subtitle = otherParticipant?.nickname != null ? '보호자: ${otherParticipant!.nickname}' : null;
      placeholderIcon = AppIcons.pet;
    } else if (isMarket) {
      // 마켓: 보호자 중심
      displayName = otherParticipant?.nickname ?? '알 수 없음';
      displayImage = otherParticipant?.profileImageUrl;
      subtitle = null; // 마켓은 상품명 대신 마지막 메시지로 충분
      placeholderIcon = AppIcons.profile;
    } else {
      // 소모임: 모임명 표시 (소모임 이름 우선)
      displayName = groupName ?? '소모임';
      displayImage = null; // 소모임은 아이콘 사용
      subtitle = null;
      placeholderIcon = AppIcons.group;
    }
    
    // 시간 포맷팅
    String timeString = '';
    if (room.lastMessageAt != null) {
      final now = DateTime.now();
      final diff = now.difference(room.lastMessageAt!);
      if (diff.inMinutes < 1) {
        timeString = '방금';
      } else if (diff.inHours < 1) {
        timeString = '${diff.inMinutes}분 전';
      } else if (diff.inDays < 1) {
        timeString = '${diff.inHours}시간 전';
      } else {
        timeString = '${diff.inDays}일 전';
      }
    }

    return MingrrCard(
      margin: const EdgeInsets.only(bottom: AppSizes.gapS),
      onTap: () => context.push('/chat/${room.id}'),
      child: Row(
        children: [
          // 프로필 이미지
          Stack(
            children: [
              MingrrImage.avatar(
                size: 55,
                imageUrl: displayImage,
                icon: placeholderIcon,
              ),
              // 채팅 타입 배지
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: context.features.dating,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Icon(
                    _getChatTypeIcon(type),
                    size: 10,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: AppSizes.gapM),
          
          // 채팅 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              displayName,
                              style: AppTextStyles.titleLarge(context).withWeight(hasUnread ? FontWeight.w700 : FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // 교배 배지
                          if (isBreeding) ...[
                            const SizedBox(width: AppSizes.gapS),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: AppSizes.paddingXXS),
                              decoration: BoxDecoration(
                                color: context.features.breeding,
                                borderRadius: BorderRadius.circular(AppSizes.radiusS),
                              ),
                              child: Text(
                                '교배',
                                style: AppTextStyles.captionSmall(context),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Text(
                      timeString,
                      style: AppTextStyles.caption(context).withColor(hasUnread ? context.features.chat : Theme.of(context).colorScheme.outlineVariant),
                    ),
                  ],
                ),
                // 부가 정보 (데이팅/교배: 보호자명, 마켓/소모임: 없음)
                if (subtitle != null) ...[
                  const SizedBox(height: AppSizes.gapXXS),
                  Text(
                    subtitle,
                    style: AppTextStyles.captionSmall(context),
                  ),
                ],
                const SizedBox(height: AppSizes.gapXS),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        room.lastMessage ?? '',
                        style: AppTextStyles.bodyMedium(context)
                            .withWeight(hasUnread ? FontWeight.w500 : FontWeight.w400)
                            .withColor(hasUnread ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (hasUnread)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingS, vertical: AppSizes.paddingXXS),
                        decoration: BoxDecoration(
                          color: context.features.dating,
                          borderRadius: BorderRadius.circular(AppSizes.radiusS),
                        ),
                        child: Text(
                          '$unreadCount',
                          style: AppTextStyles.labelMedium(context).withWeight(FontWeight.w600).withColor(Colors.white),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 채팅 타입별 아이콘
  IconData _getChatTypeIcon(ChatType type) {
    switch (type) {
      case ChatType.dating:
        return AppIcons.dating;
      case ChatType.breeding:
        return AppIcons.pet;
      case ChatType.group:
        return AppIcons.group;
      case ChatType.market:
        return AppIcons.market;
    }
  }

}

