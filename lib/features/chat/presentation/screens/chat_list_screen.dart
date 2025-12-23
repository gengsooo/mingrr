import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/pet_constants.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/top_navigation.dart';

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
    final tabs = [
      TopNavTab(label: '데이팅', icon: Icons.favorite, color: AppColors.dating),
      TopNavTab(label: '소모임', icon: Icons.groups, color: AppColors.community),
      TopNavTab(label: '마켓', icon: Icons.store, color: AppColors.market),
    ];

    return Scaffold(
      backgroundColor: AppColors.chatLight,
      appBar: AppBar(
        title: const Text('채팅'),
        backgroundColor: Colors.white,
        elevation: 0,
        // 검색 아이콘 제거됨
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
                ref.read(_selectedChatTabProvider.notifier).state = ChatType.values[index];
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

  /// ChatType을 탭 인덱스로 변환
  int _getTabIndex(ChatType type) {
    switch (type) {
      case ChatType.dating:
      case ChatType.breeding: // 교배는 데이팅 탭에 포함
        return 0;
      case ChatType.community:
        return 1;
      case ChatType.market:
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

  /// 채팅 목록
  Widget _buildChatList(BuildContext context, ChatType type) {
    final chats = _getDemoChats(type);
    
    if (chats.isEmpty) {
      return _buildEmptyState(type);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSizes.paddingM),
      itemCount: chats.length,
      itemBuilder: (context, index) {
        return _buildChatItem(context, chats[index], type);
      },
    );
  }

  /// 빈 상태 표시
  Widget _buildEmptyState(ChatType type) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(type.emoji, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            '${type.label} 채팅이 없어요',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getEmptyStateMessage(type),
            style: const TextStyle(fontSize: 13, color: AppColors.textHint),
            textAlign: TextAlign.center,
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
            builder: (context) => ChatRoomScreen(
              chatId: chat['id'] as String,
              chatName: chat['name'] as String,
              chatType: type,
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

/// ============================================================
/// 채팅방 화면
/// ============================================================
class ChatRoomScreen extends StatefulWidget {
  final String chatId;
  final String chatName;
  final ChatType chatType;

  const ChatRoomScreen({
    super.key,
    required this.chatId,
    required this.chatName,
    required this.chatType,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  final List<Map<String, dynamic>> _messages = [
    {'text': '안녕하세요! 😊', 'isMe': false, 'time': '오후 2:30'},
    {'text': '안녕하세요! 반가워요~', 'isMe': true, 'time': '오후 2:31'},
    {'text': '우리 아이가 산책을 좋아하는데 같이 하실래요?', 'isMe': false, 'time': '오후 2:32'},
    {'text': '좋아요! 언제가 좋으세요?', 'isMe': true, 'time': '오후 2:33'},
    {'text': '이번 주 토요일 오후 어떠세요?', 'isMe': false, 'time': '오후 2:35'},
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.chatLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Row(
          children: [
            MingrrAvatar(
              size: 36,
              placeholderIcon: widget.chatType == ChatType.community ? Icons.groups : Icons.pets,
            ),
            const SizedBox(width: AppSizes.gapS),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.chatName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: _getTypeColor().withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          widget.chatType.label,
                          style: TextStyle(
                            fontSize: 10,
                            color: _getTypeColor(),
                            fontWeight: FontWeight.w500,
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
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showChatOptions(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppSizes.paddingM),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Color _getTypeColor() {
    switch (widget.chatType) {
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

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isMe = message['isMe'] as bool;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.gapM),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            const MingrrAvatar(size: 32),
            const SizedBox(width: AppSizes.gapS),
          ],
          Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.65,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingM,
                  vertical: AppSizes.paddingS,
                ),
                decoration: BoxDecoration(
                  color: isMe ? _getTypeColor() : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(AppSizes.radiusL),
                    topRight: const Radius.circular(AppSizes.radiusL),
                    bottomLeft: Radius.circular(isMe ? AppSizes.radiusL : AppSizes.radiusXS),
                    bottomRight: Radius.circular(isMe ? AppSizes.radiusXS : AppSizes.radiusL),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  message['text'] as String,
                  style: TextStyle(
                    fontSize: 14,
                    color: isMe ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                message['time'] as String,
                style: const TextStyle(fontSize: 10, color: AppColors.textHint),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.only(
        left: AppSizes.paddingM,
        right: AppSizes.paddingM,
        top: AppSizes.paddingS,
        bottom: MediaQuery.of(context).padding.bottom + AppSizes.paddingS,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            color: AppColors.textHint,
            onPressed: () => _showAttachmentOptions(),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              ),
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: '메시지를 입력하세요',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
                maxLines: null,
              ),
            ),
          ),
          const SizedBox(width: AppSizes.gapS),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _getTypeColor(),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, size: 20),
              color: Colors.white,
              onPressed: () => _sendMessage(),
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'text': text, 'isMe': true, 'time': '방금'});
    });

    _messageController.clear();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _showChatOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.notifications_off_outlined),
              title: const Text('알림 끄기'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.block_outlined),
              title: const Text('차단하기'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.report_outlined, color: AppColors.error),
              title: const Text('신고하기', style: TextStyle(color: AppColors.error)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: AppColors.error),
              title: const Text('채팅방 나가기', style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSizes.paddingL),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXL)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAttachmentOption(Icons.photo, '사진', AppColors.dating),
                _buildAttachmentOption(Icons.camera_alt, '카메라', AppColors.walk),
                _buildAttachmentOption(Icons.location_on, '위치', AppColors.market),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption(IconData icon, String label, Color color) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
