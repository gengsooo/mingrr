import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/chat_service.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/rating_service.dart';
import '../../../../core/widgets/dialogs/dialogs.dart';
import '../../../../core/widgets/svg_icons.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/widgets/kkosunnae_badge.dart';
import '../../../../core/widgets/rating_sheet.dart';
import '../../../../models/chat_model.dart';
import '../../../../models/rating_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/chat_provider.dart';

/// ============================================================
/// 채팅 상세 화면
/// 1:1 채팅 메시지 주고받기
/// ============================================================

class ChatDetailScreen extends ConsumerStatefulWidget {
  final String chatRoomId;
  final String? otherUserName;
  final String? otherUserImageUrl;

  const ChatDetailScreen({
    super.key,
    required this.chatRoomId,
    this.otherUserName,
    this.otherUserImageUrl,
  });

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _chatService = ChatService();
  final _firebaseService = FirebaseService();
  final _ratingService = RatingService();
  final _imagePicker = ImagePicker();
  
  bool _isSending = false;
  ChatRoomModel? _chatRoom;
  TransactionStatusModel? _transaction;

  @override
  void initState() {
    super.initState();
    _loadChatRoom();
    _markAsRead();
    _loadTransaction();
  }
  
  Future<void> _loadTransaction() async {
    final transaction = await _ratingService.getTransactionByChatRoom(widget.chatRoomId);
    if (mounted) setState(() => _transaction = transaction);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadChatRoom() async {
    final room = await _chatService.getChatRoom(widget.chatRoomId);
    if (mounted) setState(() => _chatRoom = room);
  }

  Future<void> _markAsRead() async {
    final userId = ref.read(authStateProvider).valueOrNull?.uid;
    if (userId != null) {
      await _chatService.markAsRead(widget.chatRoomId, userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatMessagesProvider(widget.chatRoomId));
    final currentUser = ref.watch(authStateProvider).valueOrNull;
    final myUserId = currentUser?.uid ?? '';

    // 상대방 정보
    String otherName = widget.otherUserName ?? '채팅';
    String? otherImage = widget.otherUserImageUrl;
    
    if (_chatRoom != null) {
      final otherParticipant = _chatRoom!.getOtherParticipant(myUserId);
      if (otherParticipant != null) {
        otherName = otherParticipant.petName ?? otherParticipant.nickname;
        otherImage = otherParticipant.petImageUrl ?? otherParticipant.profileImageUrl;
      }
    }

    // 채팅 타입별 색상
    final themeColor = _getThemeColor(_chatRoom?.type ?? 'dating');

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            _buildProfileAvatar(otherImage, otherName, 36),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(otherName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  if (_chatRoom != null)
                    Text(_chatService.getChatTypeLabel(_chatRoom!.type), style: TextStyle(fontSize: 12, color: themeColor)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
            onPressed: () => _showOptionsSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // 메시지 목록
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('오류: $e')),
              data: (messages) {
                if (messages.isEmpty) {
                  return _buildEmptyState();
                }
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == myUserId;
                    final showDate = _shouldShowDate(messages, index);
                    final showTime = _shouldShowTime(messages, index);
                    
                    return Column(
                      children: [
                        if (showDate) _buildDateDivider(message.sentAt),
                        _buildMessageBubble(message, isMe, showTime, themeColor),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          // 입력창
          _buildInputBar(themeColor),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MingrrSvgIcon(
            assetPath: SvgAssets.emptyMessage,
            width: 120,
            height: 120,
          ),
          const SizedBox(height: 16),
          Text('대화를 시작해보세요!', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildDateDivider(DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey[300])),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              _formatDate(date),
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey[300])),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message, bool isMe, bool showTime, Color themeColor) {
    // 시스템 메시지
    if (message.type == MessageType.system) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(message.content, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isMe && showTime) _buildTimeText(message.sentAt),
          if (isMe && showTime) const SizedBox(width: 6),
          
          // 메시지 버블
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
              padding: message.type == MessageType.image 
                  ? const EdgeInsets.all(4) 
                  : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? themeColor : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _buildMessageContent(message, isMe),
            ),
          ),
          
          if (!isMe && showTime) const SizedBox(width: 6),
          if (!isMe && showTime) _buildTimeText(message.sentAt),
        ],
      ),
    );
  }

  Widget _buildMessageContent(MessageModel message, bool isMe) {
    switch (message.type) {
      case MessageType.image:
        return ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.network(
            message.imageUrl!,
            width: 200,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Container(
                width: 200,
                height: 150,
                color: Colors.grey[200],
                child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            },
          ),
        );
      case MessageType.location:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_on, color: isMe ? Colors.white : AppColors.textPrimary, size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                message.content,
                style: TextStyle(color: isMe ? Colors.white : AppColors.textPrimary),
              ),
            ),
          ],
        );
      default:
        return Text(
          message.content,
          style: TextStyle(
            color: isMe ? Colors.white : AppColors.textPrimary,
            fontSize: 15,
          ),
        );
    }
  }

  Widget _buildTimeText(DateTime time) {
    return Text(
      '${time.hour}:${time.minute.toString().padLeft(2, '0')}',
      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
    );
  }

  Widget _buildInputBar(Color themeColor) {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
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
          // 이미지 첨부
          IconButton(
            icon: Icon(Icons.add_photo_alternate_outlined, color: Colors.grey[600]),
            onPressed: _pickAndSendImage,
          ),
          // 텍스트 입력
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: '메시지를 입력하세요',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendTextMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 전송 버튼
          GestureDetector(
            onTap: _isSending ? null : _sendTextMessage,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: themeColor,
                shape: BoxShape.circle,
              ),
              child: _isSending
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendTextMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _isSending) return;

    final userId = ref.read(authStateProvider).valueOrNull?.uid;
    if (userId == null) return;

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      await _chatService.sendTextMessage(
        chatRoomId: widget.chatRoomId,
        senderId: userId,
        content: content,
      );
    } catch (e) {
      if (mounted) {
        ErrorHandler.showSnackBar(context, message: '메시지 전송에 실패했습니다');
        _messageController.text = content;
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _pickAndSendImage() async {
    final userId = ref.read(authStateProvider).valueOrNull?.uid;
    if (userId == null) return;

    final picked = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked == null) return;

    setState(() => _isSending = true);

    try {
      // 이미지 업로드
      final imageUrl = await _firebaseService.uploadImage(
        File(picked.path),
        'chats/${widget.chatRoomId}/${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      // 이미지 메시지 전송
      await _chatService.sendImageMessage(
        chatRoomId: widget.chatRoomId,
        senderId: userId,
        imageUrl: imageUrl,
      );
    } catch (e) {
      if (mounted) {
        ErrorHandler.showSnackBar(context, message: '이미지 전송에 실패했습니다');
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _showOptionsSheet(BuildContext context) {
    final myUserId = ref.read(authStateProvider).valueOrNull?.uid ?? '';
    final chatType = _chatRoom?.type ?? 'dating';
    final canRate = _transaction != null && 
        _transaction!.status == 'completed' &&
        ((myUserId == _transaction!.sellerId && !_transaction!.sellerRated) ||
         (myUserId == _transaction!.buyerId && !_transaction!.buyerRated));

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // 거래/만남 완료 버튼
            if (_transaction == null || _transaction!.status == 'pending')
              ListTile(
                leading: Icon(Icons.check_circle_outline, color: AppColors.success),
                title: Text(
                  chatType == 'marketplace' ? '거래 완료하기' : '만남 완료하기',
                  style: TextStyle(color: AppColors.success),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showCompleteDialog();
                },
              ),
            // 평가하기 버튼
            if (canRate)
              ListTile(
                leading: const Icon(Icons.star_outline, color: Colors.amber),
                title: const Text('평가하기', style: TextStyle(color: Colors.amber)),
                onTap: () {
                  Navigator.pop(context);
                  _showRatingSheet();
                },
              ),
            ListTile(
              leading: const Icon(Icons.notifications_off_outlined),
              title: const Text('알림 끄기'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('알림이 꺼졌습니다')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.report_outlined, color: Colors.orange),
              title: const Text('신고하기', style: TextStyle(color: Colors.orange)),
              onTap: () {
                Navigator.pop(context);
                _showReportDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.red),
              title: const Text('채팅방 나가기', style: TextStyle(color: Colors.red)),
              onTap: () => _leaveChatRoom(context),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showCompleteDialog() {
    final myUserId = ref.read(authStateProvider).valueOrNull?.uid ?? '';
    final chatType = _chatRoom?.type ?? 'dating';
    final otherParticipant = _chatRoom?.getOtherParticipant(myUserId);

    TransactionCompleteDialog.show(
      context,
      title: chatType == 'marketplace' ? '거래 완료' : '만남 완료',
      message: '${otherParticipant?.nickname ?? '상대방'}님과의 ${chatType == 'marketplace' ? '거래' : '만남'}이 어떻게 되었나요?',
      onComplete: () async {
        await _handleActivityComplete(ActivityResult.completed);
      },
      onNoShow: () async {
        await _handleActivityComplete(ActivityResult.noShow);
      },
      onCancel: () async {
        await _handleActivityComplete(ActivityResult.cancelled);
      },
    );
  }

  Future<void> _handleActivityComplete(ActivityResult result) async {
    final myUserId = ref.read(authStateProvider).valueOrNull?.uid ?? '';
    final otherParticipant = _chatRoom?.getOtherParticipant(myUserId);
    final chatType = _chatRoom?.type ?? 'dating';

    try {
      // 거래 상태 생성 또는 업데이트
      String transactionId;
      if (_transaction == null) {
        transactionId = await _ratingService.createTransaction(
          chatRoomId: widget.chatRoomId,
          type: chatType,
          relatedId: _chatRoom?.relatedId,
          sellerId: myUserId,
          buyerId: otherParticipant?.id ?? '',
        );
      } else {
        transactionId = _transaction!.id;
      }

      // 상태 업데이트
      await _ratingService.completeTransaction(transactionId, result.name);

      // 완료된 경우 활동 통계 증가
      if (result == ActivityResult.completed) {
        final ratingType = _getRatingType(chatType);
        await _ratingService.incrementActivityCount(myUserId, ratingType);
        if (otherParticipant != null) {
          await _ratingService.incrementActivityCount(otherParticipant.id, ratingType);
        }
      }

      // 거래 상태 다시 로드
      await _loadTransaction();

      // 평가 시트 표시
      if (mounted) {
        _showRatingSheet();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류가 발생했습니다: $e')),
        );
      }
    }
  }

  void _showRatingSheet() {
    final myUserId = ref.read(authStateProvider).valueOrNull?.uid ?? '';
    final otherParticipant = _chatRoom?.getOtherParticipant(myUserId);
    final chatType = _chatRoom?.type ?? 'dating';

    if (otherParticipant == null) return;

    RatingSheet.show(
      context,
      targetUserId: otherParticipant.id,
      targetUserName: otherParticipant.petName ?? otherParticipant.nickname,
      targetUserImageUrl: otherParticipant.petImageUrl ?? otherParticipant.profileImageUrl,
      ratingType: _getRatingType(chatType),
      relatedId: widget.chatRoomId,
      onSubmit: (score, tags, comment, result) async {
        await _ratingService.createRating(
          raterId: myUserId,
          targetId: otherParticipant.id,
          type: _getRatingType(chatType),
          relatedId: widget.chatRoomId,
          result: result,
          score: score,
          tags: tags,
          comment: comment,
        );

        // 평가 완료 표시
        if (_transaction != null) {
          final isSeller = myUserId == _transaction!.sellerId;
          await _ratingService.markAsRated(_transaction!.id, isSeller);
          await _loadTransaction();
        }
      },
    );
  }

  RatingType _getRatingType(String chatType) {
    switch (chatType) {
      case 'marketplace':
        return RatingType.marketplace;
      case 'breeding':
        return RatingType.breeding;
      case 'community':
        return RatingType.community;
      default:
        return RatingType.dating;
    }
  }

  void _showReportDialog() {
    final myUserId = ref.read(authStateProvider).valueOrNull?.uid ?? '';
    final otherParticipant = _chatRoom?.getOtherParticipant(myUserId);

    if (otherParticipant == null) return;

    showDialog(
      context: context,
      builder: (context) {
        String? selectedReason;
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('신고하기'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('신고 사유를 선택해주세요'),
                const SizedBox(height: 16),
                ...['욕설/비방', '사기/허위정보', '노쇼', '부적절한 행동', '기타'].map((reason) => 
                  RadioListTile<String>(
                    title: Text(reason),
                    value: reason,
                    groupValue: selectedReason,
                    onChanged: (value) => setState(() => selectedReason = value),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: selectedReason == null ? null : () async {
                  Navigator.pop(context);
                  await _ratingService.reportUser(
                    myUserId,
                    otherParticipant.id,
                    selectedReason!,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('신고가 접수되었습니다')),
                    );
                  }
                },
                child: const Text('신고', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _leaveChatRoom(BuildContext context) async {
    Navigator.pop(context); // 바텀시트 닫기
    
    showConfirmSheet(
      context,
      type: ConfirmSheetType.chatLeave,
      onConfirm: () async {
        final userId = ref.read(authStateProvider).valueOrNull?.uid;
        if (userId != null) {
          await _chatService.leaveChatRoom(widget.chatRoomId, userId);
          if (mounted) Navigator.pop(context);
        }
      },
    );
  }

  bool _shouldShowDate(List<MessageModel> messages, int index) {
    if (index == messages.length - 1) return true;
    final current = messages[index].sentAt;
    final previous = messages[index + 1].sentAt;
    return current.day != previous.day || current.month != previous.month || current.year != previous.year;
  }

  bool _shouldShowTime(List<MessageModel> messages, int index) {
    if (index == 0) return true;
    final current = messages[index];
    final next = messages[index - 1];
    if (current.senderId != next.senderId) return true;
    return current.sentAt.difference(next.sentAt).inMinutes.abs() > 1;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return '오늘';
    }
    if (date.year == now.year && date.month == now.month && date.day == now.day - 1) {
      return '어제';
    }
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }

  Color _getThemeColor(String type) {
    switch (type) {
      case 'dating':
      case 'breeding':
        return AppColors.dating;
      case 'market':
        return AppColors.market;
      case 'community':
        return AppColors.community;
      default:
        return AppColors.primary;
    }
  }

  Widget _buildProfileAvatar(String? imageUrl, String name, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: imageUrl != null && imageUrl.isNotEmpty
          ? ClipOval(
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(fontSize: size * 0.4, fontWeight: FontWeight.w600, color: AppColors.primary),
                  ),
                ),
              ),
            )
          : Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(fontSize: size * 0.4, fontWeight: FontWeight.w600, color: AppColors.primary),
              ),
            ),
    );
  }
}
