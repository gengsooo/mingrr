import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/common_widgets.dart';

/// ============================================================
/// 채팅 목록 화면
/// 데이팅 매칭, 거래, 모임 등 모든 채팅 관리
/// ============================================================
class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('채팅'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(AppSizes.paddingM),
        itemCount: 10,
        itemBuilder: (context, index) {
          return _buildChatItem(context, index);
        },
      ),
    );
  }

  /// 채팅 아이템
  Widget _buildChatItem(BuildContext context, int index) {
    final chats = [
      {
        'name': '뽀삐',
        'owner': '김철수',
        'lastMessage': '안녕하세요! 산책 같이 하실래요?',
        'time': '방금',
        'unread': 2,
        'type': 'dating',
      },
      {
        'name': '초코',
        'owner': '이영희',
        'lastMessage': '네, 내일 오후에 만나요!',
        'time': '10분 전',
        'unread': 0,
        'type': 'dating',
      },
      {
        'name': '콩이',
        'owner': '박민수',
        'lastMessage': '간식 아직 있나요?',
        'time': '1시간 전',
        'unread': 1,
        'type': 'market',
      },
      {
        'name': '몽이',
        'owner': '최지현',
        'lastMessage': '교배 관련해서 문의드려요',
        'time': '2시간 전',
        'unread': 0,
        'type': 'breeding',
      },
      {
        'name': '한강 산책 모임',
        'owner': '',
        'lastMessage': '이번 주 토요일 모임 확정입니다!',
        'time': '3시간 전',
        'unread': 5,
        'type': 'group',
      },
    ];

    final chat = chats[index % chats.length];
    final hasUnread = (chat['unread'] as int) > 0;

    return MingrrCard(
      margin: const EdgeInsets.only(bottom: AppSizes.gapS),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatRoomScreen(
              chatName: chat['name'] as String,
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
                placeholderIcon: chat['type'] == 'group'
                    ? Icons.groups
                    : Icons.pets,
              ),
              // 채팅 타입 배지
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: _getChatTypeColor(chat['type'] as String),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Icon(
                    _getChatTypeIcon(chat['type'] as String),
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
                          fontWeight: hasUnread
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      chat['time'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        color: hasUnread
                            ? AppColors.primary
                            : AppColors.textHint,
                      ),
                    ),
                  ],
                ),
                if ((chat['owner'] as String).isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    chat['owner'] as String,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textHint,
                    ),
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
                          color: hasUnread
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          fontWeight: hasUnread
                              ? FontWeight.w500
                              : FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (hasUnread)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${chat['unread']}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textPrimary,
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

  /// 채팅 타입별 색상
  Color _getChatTypeColor(String type) {
    switch (type) {
      case 'dating':
        return AppColors.dating;
      case 'market':
        return AppColors.market;
      case 'breeding':
        return AppColors.breeding;
      case 'group':
        return AppColors.community;
      default:
        return AppColors.primary;
    }
  }

  /// 채팅 타입별 아이콘
  IconData _getChatTypeIcon(String type) {
    switch (type) {
      case 'dating':
        return Icons.favorite;
      case 'market':
        return Icons.store;
      case 'breeding':
        return Icons.pets;
      case 'group':
        return Icons.groups;
      default:
        return Icons.chat;
    }
  }
}

/// ============================================================
/// 채팅방 화면
/// 1:1 및 그룹 채팅
/// ============================================================
class ChatRoomScreen extends StatefulWidget {
  final String chatName;

  const ChatRoomScreen({
    super.key,
    required this.chatName,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  // 데모 메시지
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            const MingrrAvatar(size: 36),
            const SizedBox(width: AppSizes.gapS),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.chatName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Text(
                  '활동 중',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // TODO: 채팅방 설정
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 메시지 목록
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppSizes.paddingM),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),
          
          // 입력 영역
          _buildInputArea(),
        ],
      ),
    );
  }

  /// 메시지 버블
  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isMe = message['isMe'] as bool;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.gapM),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            const MingrrAvatar(size: 32),
            const SizedBox(width: AppSizes.gapS),
          ],
          
          Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
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
                  color: isMe ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(AppSizes.radiusL),
                    topRight: const Radius.circular(AppSizes.radiusL),
                    bottomLeft: Radius.circular(
                      isMe ? AppSizes.radiusL : AppSizes.radiusXS,
                    ),
                    bottomRight: Radius.circular(
                      isMe ? AppSizes.radiusXS : AppSizes.radiusL,
                    ),
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
                    color: isMe ? AppColors.textPrimary : AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                message['time'] as String,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 입력 영역
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
          // 추가 버튼
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            color: AppColors.textHint,
            onPressed: () {
              _showAttachmentOptions();
            },
          ),
          
          // 텍스트 입력
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
          
          // 전송 버튼
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, size: 20),
              color: AppColors.textPrimary,
              onPressed: () {
                _sendMessage();
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 메시지 전송
  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({
        'text': text,
        'isMe': true,
        'time': '방금',
      });
    });

    _messageController.clear();

    // 스크롤 맨 아래로
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  /// 첨부 옵션 표시
  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSizes.paddingL),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSizes.radiusXL),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAttachmentOption(
                  icon: Icons.photo,
                  label: '사진',
                  color: AppColors.dating,
                ),
                _buildAttachmentOption(
                  icon: Icons.camera_alt,
                  label: '카메라',
                  color: AppColors.walk,
                ),
                _buildAttachmentOption(
                  icon: Icons.location_on,
                  label: '위치',
                  color: AppColors.market,
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  /// 첨부 옵션 아이템
  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        // TODO: 해당 기능 구현
      },
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
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
