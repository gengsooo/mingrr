import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/feature_colors.dart';
import '../../../../core/constants/pet_constants.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/mingrr_bottom_sheet.dart';
import '../../../../core/widgets/svg_icons.dart';
import '../../../../core/widgets/top_navigation.dart';
import '../../../../core/widgets/appbar_actions.dart';
import '../../../../core/widgets/guardian_profile_modal.dart';
import '../../../../core/widgets/refresh_wrapper.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../models/chat_model.dart';
import '../../../../models/dating_request_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../dating/presentation/providers/dating_request_provider.dart';
import '../providers/chat_provider.dart';
import 'chat_detail_screen.dart';

/// ============================================================
/// 채팅 목록 화면 (V4 - 반려동물 전용 + 교배 배지)
/// 
/// 변경사항:
/// - 3개 탭 (데이팅/소모임/마켓) - pill 형태
/// - 채팅 컬러 (퍼플/라벤더) 적용
/// - 교배 채팅은 데이팅 탭 내에서 배지로 표시
/// ============================================================

/// 선택된 채팅 탭
final _selectedChatTabProvider = StateProvider<ChatType>((ref) => ChatType.dating);

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTab = ref.watch(_selectedChatTabProvider);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final features = theme.extension<FeatureColors>()!;
    final isDark = theme.brightness == Brightness.dark;
    
    // 탭 정의 (아이콘 사용 - 선택 시 흰색으로 변경됨)
    // 순서: 데이팅 → 마켓 → 소모임
    final tabs = [
      MingrrTabItem(label: '데이팅', icon: Icons.favorite, color: features.dating),
      MingrrTabItem(label: '마켓', icon: Icons.store, color: features.market),
      MingrrTabItem(label: '소모임', icon: Icons.groups, color: features.social),
    ];

    // 탭별 배경색 (채팅 목록은 각 탭의 테마색 유지)
    final backgroundColor = switch (selectedTab) {
      ChatType.dating || ChatType.breeding => features.datingContainer,
      ChatType.group => features.socialContainer,
      ChatType.market => features.marketContainer,
    };
    
    return Scaffold(
      backgroundColor: isDark ? colorScheme.surface : backgroundColor,
      appBar: AppBar(
        title: const Text('채팅'),
        actions: [
          AppBarActionButton.notification(),
          AppBarActionButton.profile(backgroundColor: Theme.of(context).scaffoldBackgroundColor),
        ],
      ),
      body: Column(
        children: [
          // 3개 탭 (pill 형태)
          MingrrMainTabBar(
            tabs: tabs,
            selectedIndex: _getTabIndex(selectedTab),
            onTabSelected: (index) {
              // 탭 인덱스를 ChatType으로 변환 (순서: 데이팅 → 마켓 → 소모임)
              final chatType = switch (index) {
                0 => ChatType.dating,
                1 => ChatType.market,
                2 => ChatType.group,
                _ => ChatType.dating,
              };
              ref.read(_selectedChatTabProvider.notifier).state = chatType;
            },
          ),
          
          // 채팅 목록
          Expanded(
            child: _buildChatList(context, selectedTab),
          ),
        ],
      ),
    );
  }

  /// ChatType을 탭 인덱스로 변환 (순서: 데이팅 → 마켓 → 소모임)
  int _getTabIndex(ChatType type) {
    switch (type) {
      case ChatType.dating:
      case ChatType.breeding: // 교배는 데이팅 탭에 포함
        return 0;
      case ChatType.market:
        return 1;
      case ChatType.group:
        return 2;
    }
  }

  /// 탭별 색상
  Color _getTabColor(BuildContext context, ChatType type) {
    final features = context.features;
    switch (type) {
      case ChatType.dating:
        return features.dating;
      case ChatType.breeding:
        return features.breeding;
      case ChatType.group:
        return features.social;
      case ChatType.market:
        return features.market;
    }
  }

  /// 채팅 목록 (Firebase 연동)
  Widget _buildChatList(BuildContext context, ChatType type) {
    // 데이팅 탭인 경우 신청 목록도 함께 표시
    if (type == ChatType.dating) {
      return _buildDatingTabContent(context);
    }
    
    return Consumer(
      builder: (context, ref, child) {
        final chatRoomsAsync = ref.watch(userChatRoomsProvider);
        final currentUserId = ref.watch(authStateProvider).valueOrNull?.uid;
        
        return chatRoomsAsync.when(
          data: (allChatRooms) {
            // 타입별 필터링
            final filteredRooms = allChatRooms.where((room) {
              return room.type == type.name;
            }).toList();
            
            if (filteredRooms.isEmpty) {
              return MingrrEmptyState(
                icon: Icons.chat_bubble_outline,
                title: '아직 데이터가 없어요',
                subtitle: _getEmptyStateMessage(type),
                accentColor: _getTabColor(context, type),
                onRefresh: () async {
                  ref.invalidate(userChatRoomsProvider);
                },
              );
            }
            
            return MingrrRefreshWrapper(
              color: _getTabColor(context, type),
              onRefresh: () async {
                ref.invalidate(userChatRoomsProvider);
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(AppSizes.paddingM),
                itemCount: filteredRooms.length,
                itemBuilder: (context, index) {
                  return _buildChatRoomItem(context, ref, filteredRooms[index], type, currentUserId ?? '');
                },
              ),
            );
          },
          loading: () => MingrrLoadingState(
            type: MingrrLoadingType.chat,
            message: '채팅 목록을 불러오고 있어요',
          ),
          error: (_, __) => const MingrrErrorState(
            title: '일시적인 오류가 발생했어요',
            subtitle: '잠시 후 다시 시도해주세요',
          ),
        );
      },
    );
  }

  /// 데이팅 탭 콘텐츠 (신청 목록 + 채팅 목록)
  Widget _buildDatingTabContent(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final receivedRequests = ref.watch(receivedRequestsProvider);
        final pendingRequests = receivedRequests.where((r) => r.status == DatingRequestStatus.pending).toList();
        final chatRoomsAsync = ref.watch(userChatRoomsProvider);
        final currentUserId = ref.watch(authStateProvider).valueOrNull?.uid;

        return MingrrRefreshWrapper(
          color: context.features.dating,
          onRefresh: () async {
            ref.invalidate(userChatRoomsProvider);
            ref.invalidate(receivedRequestsProvider);
          },
          child: ListView(
            padding: const EdgeInsets.all(AppSizes.paddingM),
            children: [
              // 대기 중인 신청이 있으면 표시
              if (pendingRequests.isNotEmpty) ...[
                _buildRequestsSection(context, ref, pendingRequests),
                const SizedBox(height: AppSizes.gapL),
              ],
              
              // 채팅 목록
              chatRoomsAsync.when(
              data: (allChatRooms) {
                final filteredRooms = allChatRooms.where((room) {
                  return room.type == 'dating' || room.type == 'breeding';
                }).toList();
                
                if (filteredRooms.isEmpty && pendingRequests.isEmpty) {
                  return MingrrEmptyState(
                    icon: Icons.chat_bubble_outline,
                    title: '아직 데이터가 없어요',
                    subtitle: _getEmptyStateMessage(ChatType.dating),
                    accentColor: context.features.dating,
                    onRefresh: () async {
                      ref.invalidate(userChatRoomsProvider);
                      ref.invalidate(receivedRequestsProvider);
                    },
                  );
                }
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (filteredRooms.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSizes.gapS),
                        child: Text(
                          '채팅',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      ),
                      ...filteredRooms.map((room) => _buildChatRoomItem(context, ref, room, ChatType.dating, currentUserId ?? '')),
                    ],
                  ],
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSizes.paddingXL),
                  child: MingrrLoadingIndicator.medium(type: MingrrLoadingType.chat),
                ),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),
            ],
          ),
        );
      },
    );
  }

  /// 신청 목록 섹션
  Widget _buildRequestsSection(BuildContext context, WidgetRef ref, List<DatingRequestModel> requests) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '받은 신청',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: context.features.dating,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${requests.length}',
                style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.gapS),
        ...requests.map((request) => _buildRequestItem(context, ref, request)),
      ],
    );
  }

  /// 신청 아이템
  Widget _buildRequestItem(BuildContext context, WidgetRef ref, DatingRequestModel request) {
    final isBreeding = request.type == DatingRequestType.breeding;
    // 데이트/교배 모두 동일한 색상 사용
    final accentColor = context.features.dating;
    
    return MingrrCard(
      margin: const EdgeInsets.only(bottom: AppSizes.gapS),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // 프로필 이미지 (클릭 시 보호자 정보 바텀시트)
                GestureDetector(
                  onTap: () => _showSenderGuardianProfile(context, request),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                      image: request.senderPetImageUrl != null
                          ? DecorationImage(
                              image: NetworkImage(request.senderPetImageUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: request.senderPetImageUrl == null
                        ? Icon(
                            isBreeding ? Icons.pets : Icons.favorite,
                            color: accentColor,
                            size: 22,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                // 정보
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isBreeding ? '교배' : '데이트',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: accentColor),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${request.senderPetName} · ${request.senderName}',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatRequestTime(request.createdAt),
                            style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.outlineVariant),
                          ),
                        ],
                      ),
                      if (request.message != null && request.message!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Theme.of(context).colorScheme.surfaceContainerHighest
                                : Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            request.message!,
                            style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 수락/거절 버튼
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: OutlinedButton(
                      onPressed: () => _showRejectConfirmation(context, ref, request),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                        side: BorderSide(color: Theme.of(context).colorScheme.outline),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('거절', style: TextStyle(fontSize: 14)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MingrrButton(
                    text: '수락',
                    onPressed: () => _showAcceptConfirmation(context, ref, request),
                    backgroundColor: accentColor,
                    textColor: Colors.white,
                    height: 36,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 신청 시간 포맷
  String _formatRequestTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return '방금';
    if (diff.inHours < 1) return '${diff.inMinutes}분 전';
    if (diff.inDays < 1) return '${diff.inHours}시간 전';
    return '${diff.inDays}일 전';
  }

  /// 수락 확인 다이얼로그
  void _showAcceptConfirmation(BuildContext context, WidgetRef ref, DatingRequestModel request) {
    final isBreeding = request.type == DatingRequestType.breeding;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL),
        decoration: BoxDecoration(
          color: Theme.of(ctx).colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.bottomSheetRadius)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BottomSheetHandle(),
            const SizedBox(height: 16),
            Icon(
              isBreeding ? Icons.pets : Icons.favorite,
              size: 48,
              color: context.features.dating,
            ),
            const SizedBox(height: 16),
            Text(
              '${request.typeLabel} 수락',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              '${request.senderName}님의 ${request.senderPetName}와\n${isBreeding ? '교배' : '데이트'}를 시작할까요?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Theme.of(context).colorScheme.outline),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('취소'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MingrrButton(
                    text: '수락하기',
                    onPressed: () {
                      ref.read(receivedRequestsProvider.notifier).acceptRequest(request.id);
                      Navigator.pop(ctx);
                      MingrrSnackBar.success(context, '${request.senderPetName}의 ${request.typeLabel}을 수락했어요! 💕');
                    },
                    backgroundColor: context.features.dating,
                    textColor: Colors.white,
                    height: 48,
                  ),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(ctx).padding.bottom),
          ],
        ),
      ),
    );
  }

  /// 거절 확인 다이얼로그
  void _showRejectConfirmation(BuildContext context, WidgetRef ref, DatingRequestModel request) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL),
        decoration: BoxDecoration(
          color: Theme.of(ctx).colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.bottomSheetRadius)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BottomSheetHandle(),
            const SizedBox(height: 16),
            Icon(Icons.close, size: 48, color: Theme.of(context).colorScheme.outlineVariant),
            const SizedBox(height: 16),
            Text(
              '${request.typeLabel} 거절',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              '${request.senderName}님의 신청을 거절할까요?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Theme.of(context).colorScheme.outline),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('취소'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MingrrButton(
                    text: '거절하기',
                    onPressed: () {
                      ref.read(receivedRequestsProvider.notifier).rejectRequest(request.id);
                      Navigator.pop(ctx);
                      MingrrSnackBar.info(context, '신청을 거절했어요');
                    },
                    backgroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                    textColor: Colors.white,
                    height: 48,
                  ),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(ctx).padding.bottom),
          ],
        ),
      ),
    );
  }
  
  /// Firebase ChatRoomModel을 사용한 채팅 아이템
  Widget _buildChatRoomItem(BuildContext context, WidgetRef ref, ChatRoomModel room, ChatType type, String currentUserId) {
    final otherParticipant = room.getOtherParticipant(currentUserId);
    final unreadCount = room.unreadCounts[currentUserId] ?? 0;
    final hasUnread = unreadCount > 0;
    final isBreeding = room.type == 'breeding';
    final isDating = room.type == 'dating' || room.type == 'breeding';
    final isMarket = room.type == 'marketplace' || room.type == 'market';
    final isCommunity = room.type == 'community';
    
    // 소모임인 경우 소모임 이름 조회
    String? communityName;
    if (isCommunity && room.relatedId != null) {
      communityName = ref.watch(communityNameProvider(room.relatedId!)).valueOrNull;
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
      placeholderIcon = Icons.pets;
    } else if (isMarket) {
      // 마켓: 보호자 중심
      displayName = otherParticipant?.nickname ?? '알 수 없음';
      displayImage = otherParticipant?.profileImageUrl;
      subtitle = null; // 마켓은 상품명 대신 마지막 메시지로 충분
      placeholderIcon = Icons.person;
    } else {
      // 소모임: 모임명 표시 (소모임 이름 우선)
      displayName = communityName ?? '소모임';
      displayImage = null; // 소모임은 아이콘 사용
      subtitle = null;
      placeholderIcon = Icons.groups;
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
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatDetailScreen(
              chatRoomId: room.id,
              otherUserName: displayName,
              otherUserImageUrl: displayImage,
              chatType: room.type,
            ),
          ),
        );
      },
      child: Row(
        children: [
          // 프로필 이미지
          Stack(
            children: [
              MingrrAvatar(
                size: 55,
                imageUrl: displayImage,
                placeholderIcon: placeholderIcon,
              ),
              // 채팅 타입 배지
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: _getTabColor(context, type),
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
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // 교배 배지
                          if (isBreeding) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: context.features.breeding,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                '교배',
                                style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Text(
                      timeString,
                      style: TextStyle(
                        fontSize: 11,
                        color: hasUnread ? context.features.chat : Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                  ],
                ),
                // 부가 정보 (데이팅/교배: 보호자명, 마켓/소모임: 없음)
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.outlineVariant),
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        room.lastMessage ?? '',
                        style: TextStyle(
                          fontSize: 13,
                          color: hasUnread ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: hasUnread ? FontWeight.w500 : FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (hasUnread)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getTabColor(context, type),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
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


  String _getEmptyStateMessage(ChatType type) {
    switch (type) {
      case ChatType.dating:
        return '새로운 친구를 찾아보세요!';
      case ChatType.breeding:
        return '교배 신청이 수락되면\n채팅이 시작됩니다';
      case ChatType.group:
        return '소모임에 가입하면\n채팅이 시작됩니다';
      case ChatType.market:
        return '마켓에서 거래를 시작하면\n채팅이 생성됩니다';
    }
  }

  // ignore: unused_element - 데모/테스트용 데이터
  /// 데모 채팅 데이터
  List<Map<String, dynamic>> _getDemoChats(ChatType type) {
    switch (type) {
      case ChatType.dating:
        return [
          {'id': '1', 'name': '뽀삐', 'owner': '김철수', 'lastMessage': '안녕하세요! 산책 같이 하실래요?', 'time': '방금', 'unread': 2, 'isOnline': true, 'isBreeding': false},
          {'id': '2', 'name': '초코', 'owner': '이영희', 'lastMessage': '네, 내일 오후에 만나요!', 'time': '10분 전', 'unread': 0, 'isOnline': true, 'isBreeding': false},
          {'id': '3', 'name': '몽이', 'owner': '최지현', 'lastMessage': '교배 관련해서 문의드려요', 'time': '2시간 전', 'unread': 0, 'isOnline': false, 'isBreeding': true},
          {'id': '4', 'name': '코코', 'owner': '박민수', 'lastMessage': '우리 아이 사진 보내드릴게요~', 'time': '어제', 'unread': 0, 'isOnline': false, 'isBreeding': false},
        ];
      case ChatType.breeding:
        return [
          {'id': '3', 'name': '몽이', 'owner': '최지현', 'lastMessage': '교배 관련해서 문의드려요', 'time': '2시간 전', 'unread': 0, 'isOnline': false, 'isBreeding': true},
        ];
      case ChatType.group:
        return [
          {'id': '5', 'name': '한강 산책 모임', 'owner': '', 'lastMessage': '이번 주 토요일 모임 확정입니다!', 'time': '3시간 전', 'unread': 5, 'memberCount': 28},
          {'id': '6', 'name': '강남 댕댕이 모임', 'owner': '', 'lastMessage': '다음 모임 장소 투표해주세요~', 'time': '5시간 전', 'unread': 12, 'memberCount': 45},
          {'id': '7', 'name': '수제 간식 클럽', 'owner': '', 'lastMessage': '오늘 만든 간식 레시피 공유합니다', 'time': '어제', 'unread': 0, 'memberCount': 32},
        ];
      case ChatType.market:
        return [
          {'id': '8', 'name': '콩이', 'owner': '박민수', 'lastMessage': '간식 아직 있나요?', 'time': '1시간 전', 'unread': 1, 'productName': '수제 간식 세트'},
          {'id': '9', 'name': '두부', 'owner': '정수진', 'lastMessage': '네, 직거래 가능해요', 'time': '3시간 전', 'unread': 0, 'productName': '반려동물 옷 (M사이즈)'},
        ];
    }
  }

  // ignore: unused_element - 데모/테스트용 위젯
  /// 채팅 아이템
  Widget _buildChatItem(BuildContext context, Map<String, dynamic> chat, ChatType type) {
    final hasUnread = (chat['unread'] as int) > 0;
    final isGroup = type == ChatType.group;

    return MingrrCard(
      margin: const EdgeInsets.only(bottom: AppSizes.gapS),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatDetailScreen(
              chatRoomId: chat['id'] as String,
              otherUserName: chat['name'] as String,
              chatType: type == ChatType.dating ? 'dating' : type == ChatType.group ? 'community' : 'marketplace',
            ),
          ),
        );
      },
      child: Row(
        children: [
          // 프로필 이미지
          Stack(
            children: [
              MingrrAvatar(
                size: 55,
                placeholderIcon: isGroup ? Icons.groups : Icons.pets,
              ),
              // 온라인 상태 (데이팅만)
              if (type == ChatType.dating && chat['isOnline'] == true)
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: context.features.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              // 채팅 타입 배지
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: _getTabColor(context, type),
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
                              chat['name'] as String,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // 교배 배지
                          if (chat['isBreeding'] == true) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: context.features.breeding,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                '교배',
                                style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Text(
                      chat['time'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        color: hasUnread ? context.features.chat : Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                  ],
                ),
                // 부가 정보
                if (_getSubtitle(chat, type).isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    _getSubtitle(chat, type),
                    style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.outlineVariant),
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        chat['lastMessage'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          color: hasUnread ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: hasUnread ? FontWeight.w500 : FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (hasUnread)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getTabColor(context, type),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${chat['unread']}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
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

  /// 부가 정보 텍스트
  String _getSubtitle(Map<String, dynamic> chat, ChatType type) {
    switch (type) {
      case ChatType.dating:
      case ChatType.breeding:
        return chat['owner'] as String? ?? '';
      case ChatType.group:
        final memberCount = chat['memberCount'] as int?;
        return memberCount != null ? '멤버 $memberCount명' : '';
      case ChatType.market:
        return chat['productName'] as String? ?? '';
    }
  }

  /// 채팅 타입별 아이콘
  IconData _getChatTypeIcon(ChatType type) {
    switch (type) {
      case ChatType.dating:
        return Icons.favorite;
      case ChatType.breeding:
        return Icons.pets;
      case ChatType.group:
        return Icons.groups;
      case ChatType.market:
        return Icons.store;
    }
  }

  /// 신청자 보호자 프로필 바텀시트 표시
  Future<void> _showSenderGuardianProfile(BuildContext context, DatingRequestModel request) async {
    final firebaseService = FirebaseService();
    
    try {
      // Firebase에서 보호자 상세 정보 조회
      final userDoc = await firebaseService.firestore
          .collection('users')
          .doc(request.senderId)
          .get();
      
      final userData = userDoc.data();
      final kkosunnaeScore = (userData?['kkosunnaeScore'] as num?)?.toDouble() ?? 50.0;
      final isIdentityVerified = userData?['isIdentityVerified'] as bool? ?? false;
      final isPetVerified = userData?['isPetVerified'] as bool? ?? false;
      final isLocationVerified = userData?['isLocationVerified'] as bool? ?? false;
      final genderStr = userData?['gender'] as String?;
      final age = userData?['age'] as int?;
      
      // 성별 변환
      GuardianGender gender = GuardianGender.unknown;
      if (genderStr == 'male') gender = GuardianGender.male;
      if (genderStr == 'female') gender = GuardianGender.female;
      
      // 반려동물 정보 조회
      List<GuardianPetInfo> pets = [];
      final petsSnapshot = await firebaseService.firestore
          .collection('pets')
          .where('ownerId', isEqualTo: request.senderId)
          .get();
      
      for (final petDoc in petsSnapshot.docs) {
        final petData = petDoc.data();
        pets.add(GuardianPetInfo(
          id: petDoc.id,
          name: petData['name'] ?? '반려동물',
          breed: petData['breed'],
          ageString: petData['age'] != null ? '${petData['age']}살' : null,
          introduction: petData['introduction'],
          traits: List<String>.from(petData['traits'] ?? []),
          photoUrls: List<String>.from(petData['photoUrls'] ?? []),
          profileImageUrl: petData['profileImageUrl'],
          likeCount: petData['likeCount'] ?? 0,
        ));
      }
      
      if (!context.mounted) return;
      
      showGuardianProfileModal(
        context,
        guardianId: request.senderId,
        guardianName: request.senderName,
        kkosunnaeScore: kkosunnaeScore,
        profileImageUrl: userData?['profileImageUrl'],
        gender: gender,
        age: age,
        isIdentityVerified: isIdentityVerified,
        isPetVerified: isPetVerified,
        isLocationVerified: isLocationVerified,
        pets: pets,
      );
    } catch (e) {
      // 에러 시 기본 정보로 표시
      if (!context.mounted) return;
      showGuardianProfileModal(
        context,
        guardianId: request.senderId,
        guardianName: request.senderName,
        kkosunnaeScore: 50.0,
        pets: [
          GuardianPetInfo(
            id: request.senderPetId,
            name: request.senderPetName,
            profileImageUrl: request.senderPetImageUrl,
          ),
        ],
      );
    }
  }
}

