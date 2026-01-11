import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/pet_constants.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/svg_icons.dart';
import '../../../../core/widgets/warmth_score.dart';
import '../../../../core/widgets/report_sheet.dart';
import '../../../../core/widgets/guardian_profile_modal.dart';
import '../../../../core/widgets/pet_profile_modal.dart';
import '../../../../core/widgets/community_profile_modal.dart';
import '../../../../core/widgets/top_navigation.dart';
import '../../../../core/widgets/chat_options_modal.dart';
import '../../../../core/widgets/profile_icon.dart';
import '../../../../models/chat_model.dart';
import '../../../../models/dating_request_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../dating/presentation/providers/dating_request_provider.dart';
import '../providers/chat_provider.dart';
import 'chat_detail_screen.dart';

/// ============================================================
/// 채팅 목록 화면 (V4 - 강아지 전용 + 교배 배지)
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

    // 탭 정의 (아이콘 사용 - 선택 시 흰색으로 변경됨)
    // 순서: 데이팅 → 마켓 → 소모임
    final tabs = [
      TopNavTab(label: '데이팅', icon: Icons.favorite, color: AppColors.dating),
      TopNavTab(label: '마켓', icon: Icons.store, color: AppColors.market),
      TopNavTab(label: '소모임', icon: Icons.groups, color: AppColors.community),
    ];

    // 탭별 배경색
    final backgroundColor = switch (selectedTab) {
      ChatType.dating || ChatType.breeding => AppColors.datingLight,
      ChatType.community => AppColors.communityLight,
      ChatType.market => AppColors.marketLight,
    };

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('채팅'),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          const NotificationIconButton(),
          buildProfileAction(backgroundColor: AppColors.chatLight),
        ],
      ),
      body: Column(
        children: [
          // 3개 탭 (pill 형태)
          Container(
            color: Colors.white,
            child: PillTabBar(
              tabs: tabs,
              selectedIndex: _getTabIndex(selectedTab),
              onTabSelected: (index) {
                // 탭 인덱스를 ChatType으로 변환 (순서: 데이팅 → 마켓 → 소모임)
                final chatType = switch (index) {
                  0 => ChatType.dating,
                  1 => ChatType.market,
                  2 => ChatType.community,
                  _ => ChatType.dating,
                };
                ref.read(_selectedChatTabProvider.notifier).state = chatType;
              },
            ),
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
      case ChatType.community:
        return 2;
    }
  }

  /// 탭별 색상
  Color _getTabColor(ChatType type) {
    switch (type) {
      case ChatType.dating:
        return AppColors.dating;
      case ChatType.breeding:
        return AppColors.breeding;
      case ChatType.community:
        return AppColors.community;
      case ChatType.market:
        return AppColors.market;
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
                svgAsset: SvgAssets.emptyChat,
                title: '${type.label} 채팅이 없어요',
                subtitle: _getEmptyStateMessage(type),
              );
            }
            
            return ListView.builder(
              padding: const EdgeInsets.all(AppSizes.paddingM),
              itemCount: filteredRooms.length,
              itemBuilder: (context, index) {
                return _buildChatRoomItem(context, filteredRooms[index], type, currentUserId ?? '');
              },
            );
          },
          loading: () => const MingrrLoadingState(),
          error: (_, __) => MingrrEmptyState(
            svgAsset: SvgAssets.emptyChat,
            title: '${type.label} 채팅을 불러올 수 없어요',
            subtitle: '네트워크 연결을 확인해주세요',
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

        return ListView(
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
                    svgAsset: SvgAssets.emptyChat,
                    title: '데이팅 채팅이 없어요',
                    subtitle: _getEmptyStateMessage(ChatType.dating),
                  );
                }
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (filteredRooms.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.only(bottom: AppSizes.gapS),
                        child: Text(
                          '채팅',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                        ),
                      ),
                      ...filteredRooms.map((room) => _buildChatRoomItem(context, room, ChatType.dating, currentUserId ?? '')),
                    ],
                  ],
                );
              },
              loading: () => const MingrrLoadingState(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
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
            const Text(
              '받은 신청',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.dating,
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
    const accentColor = AppColors.dating;
    
    return MingrrCard(
      margin: const EdgeInsets.only(bottom: AppSizes.gapS),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // 프로필 이미지
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isBreeding ? Icons.pets : Icons.favorite,
                    color: accentColor,
                    size: 22,
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
                            style: const TextStyle(fontSize: 11, color: AppColors.textHint),
                          ),
                        ],
                      ),
                      if (request.message != null && request.message!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            request.message!,
                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
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
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.divider),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('거절', style: TextStyle(fontSize: 14)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: ElevatedButton(
                      onPressed: () => _showAcceptConfirmation(context, ref, request),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('수락', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
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
        padding: const EdgeInsets.all(AppSizes.paddingL),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Icon(
              isBreeding ? Icons.pets : Icons.favorite,
              size: 48,
              color: AppColors.dating,
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
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.divider),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('취소'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(receivedRequestsProvider.notifier).acceptRequest(request.id);
                      Navigator.pop(ctx);
                      MingrrSnackBar.success(context, '${request.senderPetName}의 ${request.typeLabel}을 수락했어요! 💕');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.dating,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('수락하기', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
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
        padding: const EdgeInsets.all(AppSizes.paddingL),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Icon(Icons.close, size: 48, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text(
              '${request.typeLabel} 거절',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              '${request.senderName}님의 신청을 거절할까요?',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.divider),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('취소'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(receivedRequestsProvider.notifier).rejectRequest(request.id);
                      Navigator.pop(ctx);
                      MingrrSnackBar.info(context, '신청을 거절했어요');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.textSecondary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('거절하기', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
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
  Widget _buildChatRoomItem(BuildContext context, ChatRoomModel room, ChatType type, String currentUserId) {
    final otherParticipant = room.getOtherParticipant(currentUserId);
    final unreadCount = room.unreadCounts[currentUserId] ?? 0;
    final hasUnread = unreadCount > 0;
    final isGroup = type == ChatType.community;
    final isBreeding = room.type == 'breeding';
    
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
              otherUserName: otherParticipant?.petName ?? otherParticipant?.nickname,
              otherUserImageUrl: otherParticipant?.petImageUrl ?? otherParticipant?.profileImageUrl,
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
                imageUrl: otherParticipant?.petImageUrl ?? otherParticipant?.profileImageUrl,
                placeholderIcon: isGroup ? Icons.groups : Icons.pets,
              ),
              // 채팅 타입 배지
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: _getTabColor(type),
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
                              otherParticipant?.petName ?? otherParticipant?.nickname ?? '알 수 없음',
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
                                color: AppColors.breeding,
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
                        color: hasUnread ? AppColors.chat : AppColors.textHint,
                      ),
                    ),
                  ],
                ),
                // 부가 정보
                if (otherParticipant?.nickname != null && otherParticipant?.petName != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    otherParticipant!.nickname,
                    style: const TextStyle(fontSize: 11, color: AppColors.textHint),
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
                          color: hasUnread ? AppColors.textPrimary : AppColors.textSecondary,
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
                          color: _getTabColor(type),
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
      case ChatType.community:
        return '소모임에 가입하면\n채팅이 시작됩니다';
      case ChatType.market:
        return '마켓에서 거래를 시작하면\n채팅이 생성됩니다';
    }
  }

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
      case ChatType.community:
        return [
          {'id': '5', 'name': '한강 산책 모임', 'owner': '', 'lastMessage': '이번 주 토요일 모임 확정입니다!', 'time': '3시간 전', 'unread': 5, 'memberCount': 28},
          {'id': '6', 'name': '강남 댕댕이 모임', 'owner': '', 'lastMessage': '다음 모임 장소 투표해주세요~', 'time': '5시간 전', 'unread': 12, 'memberCount': 45},
          {'id': '7', 'name': '수제 간식 클럽', 'owner': '', 'lastMessage': '오늘 만든 간식 레시피 공유합니다', 'time': '어제', 'unread': 0, 'memberCount': 32},
        ];
      case ChatType.market:
        return [
          {'id': '8', 'name': '콩이', 'owner': '박민수', 'lastMessage': '간식 아직 있나요?', 'time': '1시간 전', 'unread': 1, 'productName': '수제 간식 세트'},
          {'id': '9', 'name': '두부', 'owner': '정수진', 'lastMessage': '네, 직거래 가능해요', 'time': '3시간 전', 'unread': 0, 'productName': '강아지 옷 (M사이즈)'},
        ];
    }
  }

  /// 채팅 아이템
  Widget _buildChatItem(BuildContext context, Map<String, dynamic> chat, ChatType type) {
    final hasUnread = (chat['unread'] as int) > 0;
    final isGroup = type == ChatType.community;

    return MingrrCard(
      margin: const EdgeInsets.only(bottom: AppSizes.gapS),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatDetailScreen(
              chatRoomId: chat['id'] as String,
              otherUserName: chat['name'] as String,
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
                      color: AppColors.success,
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
                    color: _getTabColor(type),
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
                                color: AppColors.breeding,
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
                        color: hasUnread ? AppColors.chat : AppColors.textHint,
                      ),
                    ),
                  ],
                ),
                // 부가 정보
                if (_getSubtitle(chat, type).isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    _getSubtitle(chat, type),
                    style: const TextStyle(fontSize: 11, color: AppColors.textHint),
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
                          color: hasUnread ? AppColors.textPrimary : AppColors.textSecondary,
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
                          color: _getTabColor(type),
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
      case ChatType.community:
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
      case ChatType.community:
        return Icons.groups;
      case ChatType.market:
        return Icons.store;
    }
  }
}

