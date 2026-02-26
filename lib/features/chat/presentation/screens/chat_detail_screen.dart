import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/feature_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/services/chat_service.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/rating_service.dart';
import '../../../../core/widgets/dialogs/dialogs.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/sheets/mingrr_bottom_sheet.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/services/image_service.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/pet_constants.dart';
import '../../../../core/widgets/rating_widgets.dart';
import '../../../../core/widgets/modals/guardian_profile_modal.dart';
import '../../../../core/widgets/modals/pet_profile_modal.dart';
import '../../../../core/widgets/modals/group_profile_modal.dart';
import '../../../../models/chat_model.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../models/group_model.dart';
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
  final String? chatType; // 채팅 타입 (깜빡거림 방지용 초기값)

  const ChatDetailScreen({
    super.key,
    required this.chatRoomId,
    this.otherUserName,
    this.otherUserImageUrl,
    this.chatType,
  });

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final _messageController = TextEditingController();
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _chatService = ChatService();
  final _firebaseService = FirebaseService();
  final _firestoreService = FirestoreService();
  final _ratingService = RatingService();
  final _imagePicker = ImagePicker();
  
  bool _isSending = false;
  bool _isSearching = false;
  bool _isUploadingImage = false;
  bool _isShowingProfile = false;
  String _searchQuery = '';
  ChatRoomModel? _chatRoom;
  TransactionStatusModel? _transaction;
  String? _groupName; // 소모임 이름 (소모임 채팅용)

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
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadChatRoom() async {
    final room = await _chatService.getChatRoom(widget.chatRoomId);
    if (mounted) {
      setState(() => _chatRoom = room);
      // 소모임 채팅인 경우 소모임 이름 로드
      if ((room?.type == 'community' || room?.type == 'group') && room?.relatedId != null) {
        _loadGroupName(room!.relatedId!);
      }
    }
  }
  
  Future<void> _loadGroupName(String groupId) async {
    try {
      final groupDoc = await _firebaseService.firestore
          .collection('groups')
          .doc(groupId)
          .get();
      if (mounted && groupDoc.exists) {
        setState(() => _groupName = groupDoc.data()?['name']);
      }
    } catch (e) {
      AppLogger.error('ChatDetail', 'Failed to load group name', e);
    }
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
    
    // 메시지가 변경될 때마다 읽음 처리 (채팅방 내에서 새 메시지 수신 시)
    ref.listen(chatMessagesProvider(widget.chatRoomId), (previous, next) {
      if (next.hasValue && myUserId.isNotEmpty) {
        _chatService.markAsRead(widget.chatRoomId, myUserId);
      }
    });

    // 채팅 타입 (위젯 파라미터 우선, 없으면 _chatRoom에서, 그것도 없으면 기본값)
    final chatType = widget.chatType ?? _chatRoom?.type ?? 'dating';
    final isDating = chatType == 'dating' || chatType == 'breeding';
    final isMarket = chatType == 'marketplace' || chatType == 'market';
    final isGroup = chatType == 'community' || chatType == 'group';
    
    // 상대방 정보
    String otherName = widget.otherUserName ?? '채팅';
    String? otherImage = widget.otherUserImageUrl;
    ChatParticipant? otherParticipant;
    
    if (_chatRoom != null) {
      otherParticipant = _chatRoom!.getOtherParticipant(myUserId);
      if (otherParticipant != null) {
        // 타입별 표시 규칙
        // 데이팅/교배: 반려동물명 · 보호자명, 반려동물 이미지
        // 마켓: 보호자명, 보호자 이미지
        // 소모임: 모임명
        if (isDating) {
          final petName = otherParticipant.petName;
          final guardianName = otherParticipant.nickname;
          if (petName != null && petName.isNotEmpty) {
            otherName = '$petName · $guardianName';
          } else {
            otherName = guardianName;
          }
          otherImage = otherParticipant.petImageUrl ?? otherParticipant.profileImageUrl;
        } else if (isMarket) {
          otherName = otherParticipant.nickname;
          otherImage = otherParticipant.profileImageUrl;
        } else if (isGroup) {
          // 소모임: 소모임명 표시 (로드된 경우), 아니면 위젯 파라미터 사용
          otherName = _groupName ?? widget.otherUserName ?? '소모임';
          otherImage = null; // 소모임은 아이콘 사용
        } else {
          otherName = otherParticipant.nickname;
          otherImage = otherParticipant.profileImageUrl;
        }
      }
    }
    final themeColor = _getThemeColor(chatType);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        elevation: AppSizes.elevationNone,
        scrolledUnderElevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: isDark ? null : AppShadows.shadowS(false),
          ),
        ),
        leading: const MingrrLeadingButton.back(showShadow: false),
        titleSpacing: 0,
        title: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _showProfileByType(context, chatType, otherParticipant),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingS, horizontal: 4),
            child: Row(
              children: [
                // 프로필 아바타 + 채팅 타입 배지
                Stack(
                  children: [
                    _buildClickableProfileAvatar(otherImage, otherName, 40, themeColor),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: themeColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Icon(
                          _getChatTypeIcon(chatType),
                          size: 8,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: AppSizes.gapM),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          otherName,
                          style: AppTextStyles.headlineSmall(context),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSizes.gapXS),
                      Icon(AppIcons.chevronRight, size: 18, color: Theme.of(context).colorScheme.outlineVariant),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          // 검색 버튼
          IconButton(
            icon: Icon(
              _isSearching ? AppIcons.close : AppIcons.search,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _searchQuery = '';
                }
              });
            },
          ),
          IconButton(
            icon: Icon(AppIcons.moreVert, color: Theme.of(context).colorScheme.onSurfaceVariant),
            onPressed: () => _showOptionsSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // 검색 바
          if (_isSearching)
            Container(
              color: Theme.of(context).colorScheme.surface,
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL, vertical: AppSizes.paddingS),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: '메시지 검색...',
                  hintStyle: AppTextStyles.bodySmall(context).copyWith(color: Theme.of(context).colorScheme.outlineVariant),
                  prefixIcon: Icon(AppIcons.search, color: Theme.of(context).colorScheme.outlineVariant),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusXL),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL, vertical: AppSizes.paddingS),
                ),
                onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
              ),
            ),
          // 메시지 목록
          Expanded(
            child: Container(
              color: Theme.of(context).colorScheme.surface,
              child: messagesAsync.when(
                loading: () => MingrrLoadingState(
                  type: MingrrLoadingType.chat,
                  message: '메시지를 불러오고 있어요',
                  timeout: AppSizes.loadingTimeout,
                  onRetry: () => ref.invalidate(chatMessagesProvider(widget.chatRoomId)),
                ),
                error: (_, __) => MingrrErrorState(
                  onRetry: () => ref.invalidate(chatMessagesProvider(widget.chatRoomId)),
                ),
                data: (messages) {
                  // 검색 필터링
                  final filteredMessages = _searchQuery.isEmpty
                      ? messages
                      : messages.where((m) => 
                          m.content.toLowerCase().contains(_searchQuery)
                        ).toList();
                  
                  if (messages.isEmpty) {
                    return MingrrEmptyState(
                      icon: AppIcons.chatOutlined,
                      title: '대화를 시작해보세요!',
                      subtitle: '반려동물 친구를 만들어보세요',
                    );
                  }
                  
                  if (_searchQuery.isNotEmpty && filteredMessages.isEmpty) {
                    return MingrrEmptyState(
                      icon: AppIcons.searchOff,
                      title: '검색 결과가 없습니다',
                      subtitle: '"$_searchQuery"에 대한 메시지를 찾을 수 없습니다',
                    );
                  }
                  
                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL, vertical: AppSizes.paddingM),
                    itemCount: filteredMessages.length,
                    itemBuilder: (context, index) {
                      final message = filteredMessages[index];
                      final isMe = message.senderId == myUserId;
                      final showDate = _shouldShowDate(filteredMessages, index);
                      final showTime = _shouldShowTime(filteredMessages, index);
                      
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
          ),
          // 입력창 (검색 중이 아닐 때만)
          if (!_isSearching) _buildInputBar(themeColor),
        ],
      ),
    );
  }

  /// 채팅 타입별 프로필 바텀시트 분기
  Future<void> _showProfileByType(BuildContext context, String chatType, ChatParticipant? participant) async {
    // 더블클릭 방지
    if (_isShowingProfile) return;
    if (participant == null) return;
    
    _isShowingProfile = true;
    
    // 디버깅: chatType 확인
    AppLogger.debug('ChatDetail', '_showProfileByType - chatType: "$chatType", participant.id: ${participant.id}');
    
    try {
      // chatType을 소문자로 정규화
      final normalizedType = chatType.toLowerCase().trim();
      AppLogger.debug('ChatDetail', 'normalizedType: "$normalizedType"');
      
      if (normalizedType == 'dating' || normalizedType == 'breeding') {
        AppLogger.debug('ChatDetail', '-> _showPetProfile 호출');
        // 데이팅/교배: 반려동물 프로필 모달
        await _showPetProfile(context, participant);
      } else if (normalizedType == 'marketplace' || normalizedType == 'market') {
        AppLogger.debug('ChatDetail', '-> _showGuardianProfile 호출 (마켓)');
        // 마켓: 보호자 프로필 모달
        _showGuardianProfile(context, participant);
      } else if (normalizedType == 'community' || normalizedType == 'group') {
        AppLogger.debug('ChatDetail', '-> _showGroupProfile 호출');
        // 소모임: 소모임 정보 모달
        await _showGroupProfile(context);
      } else {
        AppLogger.debug('ChatDetail', '-> _showGuardianProfile 호출 (기본)');
        // 기본: 보호자 프로필 모달
        _showGuardianProfile(context, participant);
      }
    } finally {
      _isShowingProfile = false;
    }
  }

  /// 반려동물 프로필 모달 표시 (데이팅/교배용)
  /// 추천친구-상세와 동일한 내용을 표시하기 위해 보호자 정보도 함께 조회
  Future<void> _showPetProfile(BuildContext context, ChatParticipant participant) async {
    try {
      AppLogger.debug('ChatDetail', '_showPetProfile 시작 - participant.id: ${participant.id}');
      
      // 반려동물 정보 조회
      final petsSnapshot = await _firebaseService.firestore
          .collection('pets')
          .where('ownerId', isEqualTo: participant.id)
          .get();
      
      AppLogger.debug('ChatDetail', '반려동물 조회 결과: ${petsSnapshot.docs.length}개');
      
      if (petsSnapshot.docs.isEmpty) {
        AppLogger.debug('ChatDetail', '반려동물 없음 - 스낵바 표시');
        if (!mounted) return;
        MingrrSnackBar.info(context, '반려동물 정보가 없어요!');
        return;
      }
      
      // 보호자 정보 조회
      final userDoc = await _firebaseService.firestore
          .collection('users')
          .doc(participant.id)
          .get();
      final userData = userDoc.data();
      final kkosunnaeScore = (userData?['kkosunnaeScore'] as num?)?.toDouble() ?? 50.0;
      final isIdentityVerified = userData?['isIdentityVerified'] as bool? ?? false;
      final isPetVerified = userData?['isPetVerified'] as bool? ?? false;
      final isLocationVerified = userData?['isLocationVerified'] as bool? ?? false;
      final guardianGender = GuardianGender.fromString(userData?['gender'] as String?);
      final userAge = userData?['age'] as int?;
      
      // 모든 반려동물 정보 수집 (보호자 정보 바텀시트에서 사용)
      List<GuardianPetInfo> allPets = [];
      for (final doc in petsSnapshot.docs) {
        allPets.add(GuardianPetInfo.fromFirestoreDoc(doc));
      }
      
      // petName과 일치하는 반려동물 또는 첫 번째 반려동물
      final matchingDocs = petsSnapshot.docs.where(
        (doc) => doc.data()['name'] == participant.petName,
      ).toList();
      final petDoc = matchingDocs.isNotEmpty ? matchingDocs.first : petsSnapshot.docs.first;
      final petData = petDoc.data();
      
      if (!mounted) return;
      
      // 추천친구-상세와 동일한 내용을 표시하기 위해 guardianInfo 전달
      showPetProfileModal(
        context,
        petId: petDoc.id,
        petName: petData['name'] ?? '반려동물',
        breed: petData['breed'],
        age: petData['age'],
        gender: petData['gender'],
        weight: (petData['weight'] as num?)?.toDouble(),
        introduction: petData['introduction'],
        traits: (petData['traits'] as List?)?.map((t) => PetTrait.labelFromName(t.toString())).toList() ?? [],
        photoUrls: List<String>.from(petData['photoUrls'] ?? []),
        profileImageUrl: petData['profileImageUrl'],
        likeCount: petData['likeCount'] ?? 0,
        isIdentityVerified: isIdentityVerified,
        isPetVerified: isPetVerified,
        isLocationVerified: isLocationVerified,
        guardianInfo: GuardianInfo(
          id: participant.id,
          nickname: participant.nickname,
          kkosunnaeScore: kkosunnaeScore,
          gender: guardianGender,
          age: userAge,
          isIdentityVerified: isIdentityVerified,
          isPetVerified: isPetVerified,
          isLocationVerified: isLocationVerified,
          pets: allPets,
          activityInfo: GuardianActivityInfo.fromMap(userData),
        ),
      );
    } catch (e) {
      AppLogger.error('ChatDetail', '_showPetProfile 에러', e);
      if (!mounted) return;
      ErrorHandler.showError(context, e, tag: 'ChatDetail', operation: '반려동물 정보 로드');
    }
  }

  /// 소모임 프로필 모달 표시
  Future<void> _showGroupProfile(BuildContext context) async {
    AppLogger.debug('ChatDetail', '_showGroupProfile 시작');
    AppLogger.debug('ChatDetail', '_chatRoom: ${_chatRoom != null ? "있음" : "null"}');
    AppLogger.debug('ChatDetail', '_chatRoom?.relatedId: ${_chatRoom?.relatedId}');
    
    if (_chatRoom == null) {
      AppLogger.debug('ChatDetail', '_chatRoom이 null - 스낵바 표시');
      if (!mounted) return;
      MingrrSnackBar.info(context, '채팅방 정보를 불러오는 중입니다');
      return;
    }
    
    if (_chatRoom!.relatedId == null) {
      AppLogger.debug('ChatDetail', 'relatedId가 null - 스낵바 표시');
      if (!mounted) return;
      MingrrSnackBar.info(context, '소모임 정보가 연결되지 않았습니다');
      return;
    }
    
    try {
      // 소모임 정보 조회
      final groupDoc = await _firebaseService.firestore
          .collection('groups')
          .doc(_chatRoom!.relatedId)
          .get();
      
      if (!groupDoc.exists) {
        AppLogger.warning('ChatDetail', '소모임 문서가 존재하지 않음');
        if (!mounted) return;
        MingrrSnackBar.info(context, '소모임 정보를 불러오는데 실패했습니다!');
        return;
      }
      
      final groupData = groupDoc.data()!;
      final memberIds = List<String>.from(groupData['memberIds'] ?? []);
      final creatorId = groupData['creatorId'] as String?;
      
      // 멤버 정보 조회 (최대 10명)
      List<GroupMember> members = [];
      for (final memberId in memberIds.take(10)) {
        final memberDoc = await _firebaseService.firestore
            .collection('users')
            .doc(memberId)
            .get();
        if (memberDoc.exists) {
          final memberData = memberDoc.data()!;
          members.add(GroupMember(
            id: memberId,
            nickname: memberData['nickname'] ?? '사용자',
            kkosunnaeScore: (memberData['kkosunnaeScore'] as num?)?.toDouble() ?? 50.0,
            isCreator: memberId == creatorId,
          ));
        }
      }
      
      // 모임장을 맨 앞으로 정렬
      members.sort((a, b) {
        if (a.isCreator) return -1;
        if (b.isCreator) return 1;
        return 0;
      });
      
      if (!mounted) return;
      
      showGroupProfileModal(
        context,
        groupId: groupDoc.id,
        groupName: groupData['name'] ?? '소모임',
        description: groupData['description'],
        memberCount: memberIds.length,
        category: GroupTypeLabel.labelFromString(groupData['type']),
        location: groupData['address'],
        createdAt: groupData['createdAt'] != null 
            ? _formatDate(groupData['createdAt'].toDate())
            : null,
        tags: List<String>.from(groupData['tags'] ?? []),
        isJoined: true,
        members: members,
      );
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showError(context, e, tag: 'ChatDetail', operation: '소모임 정보 로드');
    }
  }

  /// 보호자 프로필 모달 표시 (Firebase에서 상세 정보 조회)
  void _showGuardianProfile(BuildContext context, ChatParticipant? participant) {
    if (participant == null) return;
    showGuardianProfileFromFirestore(
      context,
      userId: participant.id,
      fallbackName: participant.nickname,
      fallbackImageUrl: participant.profileImageUrl,
    );
  }

  /// 클릭 가능한 프로필 아바타
  Widget _buildClickableProfileAvatar(String? imageUrl, String name, double size, Color themeColor) {
    final hasValidImage = imageUrl != null && 
                          imageUrl.isNotEmpty && 
                          !imageUrl.startsWith('default_avatar:');
    
    return MingrrImage.petAvatar(
      imageUrl: hasValidImage ? imageUrl : null,
      size: size,
      borderColor: themeColor.withValues(alpha: AppOpacity.o30),
      borderWidth: 1,
    );
  }

  /// 아바타 플레이스홀더
  Widget _buildAvatarPlaceholder(String name, double size, Color color) {
    return Center(
      child: Icon(
        AppIcons.pet,
        size: size * 0.5,
        color: color,
      ),
    );
  }

  /// 채팅 타입별 아이콘
  IconData _getChatTypeIcon(String type) {
    switch (type) {
      case 'dating':
        return AppIcons.dating;
      case 'breeding':
        return AppIcons.pet;
      case 'marketplace':
      case 'market':
        return AppIcons.market;
      case 'community':
      case 'group':
        return AppIcons.group;
      default:
        return AppIcons.chat;
    }
  }

  Widget _buildDateDivider(DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingL),
      child: Row(
        children: [
          Expanded(child: Divider(color: Theme.of(context).colorScheme.outline)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM),
            child: Text(
              _formatDate(date),
              style: AppTextStyles.caption(context),
            ),
          ),
          Expanded(child: Divider(color: Theme.of(context).colorScheme.outline)),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message, bool isMe, bool showTime, Color themeColor) {
    // 시스템 메시지
    if (message.type == MessageType.system) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingS),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL, vertical: AppSizes.paddingS),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(AppSizes.radiusM),
            ),
            child: Text(message.content, style: AppTextStyles.caption(context)),
          ),
        ),
      );
    }

    final bubbleColor = isMe ? themeColor : Theme.of(context).colorScheme.surfaceContainerHighest;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.paddingXS),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 내 메시지: 읽음 표시 + 시간
          if (isMe && showTime) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 읽음 표시
                if (message.isRead)
                  Text(
                    '읽음',
                    style: AppTextStyles.caption(context),
                  ),
                _buildTimeText(message.sentAt),
              ],
            ),
            const SizedBox(width: AppSizes.gapSM),
          ],
          
          // 메시지 버블 + 꼬리
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: ResponsiveUtils.widthPercent(context, 0.7)),
              padding: message.type == MessageType.image 
                  ? const EdgeInsets.all(AppSizes.paddingXS) 
                  : const EdgeInsets.symmetric(horizontal: 14, vertical: AppSizes.paddingS),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.circular(AppSizes.radiusL),
                boxShadow: AppShadows.shadowS(Theme.of(context).brightness == Brightness.dark),
              ),
              child: _buildMessageContent(message, isMe, themeColor),
            ),
          ),
          
          if (!isMe && showTime) const SizedBox(width: AppSizes.gapSM),
          if (!isMe && showTime) _buildTimeText(message.sentAt),
        ],
      ),
    );
  }

  Widget _buildMessageContent(MessageModel message, bool isMe, Color themeColor) {
    switch (message.type) {
      case MessageType.image:
        return GestureDetector(
          onTap: () => _showFullScreenImage(context, message.imageUrl!),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusS),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 200, maxHeight: 250),
              child: MingrrImage(
                imageUrl: message.imageUrl,
                fit: BoxFit.cover,
                shape: ImageShape.rounded,
                borderRadius: AppSizes.radiusS,
              ),
            ),
          ),
        );
      case MessageType.location:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.location, color: isMe ? Colors.white : Theme.of(context).colorScheme.onSurface, size: 18),
            const SizedBox(width: AppSizes.gapSM),
            Flexible(
              child: Text(
                message.content,
                style: TextStyle(color: isMe ? Colors.white : Theme.of(context).colorScheme.onSurface),
              ),
            ),
          ],
        );
      default:
        return Text(
          message.content,
          style: AppTextStyles.titleLarge(context).withColor(
            isMe ? Colors.white : Theme.of(context).colorScheme.onSurface,
          ),
        );
    }
  }

  /// 전체 화면 이미지 보기 (핀치 줌, 저장 기능)
  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showImageViewer(context, imageUrl: imageUrl, showSaveButton: true);
  }

  Widget _buildTimeText(DateTime time) {
    return Text(
      '${time.hour}:${time.minute.toString().padLeft(2, '0')}',
      style: AppTextStyles.captionSmall(context),
    );
  }

  Widget _buildInputBar(Color themeColor) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: AppShadows.shadowL(Theme.of(context).brightness == Brightness.dark),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM, vertical: AppSizes.paddingS),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 이미지 첨부 버튼 (업로드 중이면 프로그레스 표시)
              Container(
                width: 40,
                height: 40,
                margin: const EdgeInsets.only(bottom: AppSizes.paddingXXS),
                decoration: BoxDecoration(
                  color: themeColor.withValues(alpha: AppOpacity.o10),
                  shape: BoxShape.circle,
                ),
                child: _isUploadingImage
                    ? Stack(
                        alignment: Alignment.center,
                        children: [
                          MingrrLoadingIndicator(
                            size: 24,
                            strokeWidth: 2,
                            customColor: themeColor,
                          ),
                          Icon(AppIcons.image, color: themeColor, size: 12),
                        ],
                      )
                    : IconButton(
                        icon: Icon(AppIcons.addPhoto, color: themeColor, size: 20),
                        onPressed: _pickAndSendImage,
                        padding: EdgeInsets.zero,
                      ),
              ),
              const SizedBox(width: AppSizes.gapS),
              // 텍스트 입력
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(minHeight: 44),
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL, vertical: 4),
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: '메시지를 입력하세요',
                      hintStyle: AppTextStyles.bodySmall(context).copyWith(color: Theme.of(context).colorScheme.outlineVariant),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: AppSizes.paddingS),
                    ),
                    style: AppTextStyles.bodyMedium(context),
                    maxLines: 4,
                    minLines: 1,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendTextMessage(),
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.gapS),
              // 전송 버튼
              Container(
                width: 44,
                height: 44,
                margin: const EdgeInsets.only(bottom: AppSizes.paddingXXS),
                child: Material(
                  color: themeColor,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: _isSending ? null : _sendTextMessage,
                    customBorder: const CircleBorder(),
                    child: Center(
                      child: _isSending
                          ? const MingrrLoadingIndicator(
                              size: 20,
                              strokeWidth: 2,
                              customColor: Colors.white,
                            )
                          : const Icon(AppIcons.send, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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

    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery, 
      imageQuality: ImageLimits.imageQuality,
      maxWidth: ImageLimits.maxResolution.toDouble(),
      maxHeight: ImageLimits.maxResolution.toDouble(),
    );
    if (picked == null) return;

    // 파일 크기 검사
    final file = File(picked.path);
    final fileSize = await file.length();
    if (fileSize > ImageLimits.maxFileSizeBytes) {
      if (mounted) {
        final sizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(1);
        MingrrSnackBar.warning(
          context, 
          '이미지 크기가 너무 큽니다 (${sizeMB}MB). 최대 ${ImageLimits.maxFileSizeMB}MB까지 전송 가능합니다',
        );
      }
      return;
    }

    setState(() {
      _isSending = true;
      _isUploadingImage = true;
    });

    try {
      // 이미지 업로드
      final imageUrl = await _firebaseService.uploadImage(
        file,
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
      if (mounted) {
        setState(() {
          _isSending = false;
          _isUploadingImage = false;
        });
      }
    }
  }

  void _showOptionsSheet(BuildContext context) {
    final myUserId = ref.read(authStateProvider).valueOrNull?.uid ?? '';
    final chatType = _chatRoom?.type ?? 'dating';
    final canRate = _transaction != null && 
        _transaction!.status == 'completed' &&
        ((myUserId == _transaction!.sellerId && !_transaction!.sellerRated) ||
         (myUserId == _transaction!.buyerId && !_transaction!.buyerRated));

    final options = <MingrrOptionItem>[];
    
    // 거래/만남 완료 버튼 (소모임은 완료 개념 없음)
    final hasCompleteAction = chatType == 'marketplace' || 
                               chatType == 'dating' || 
                               chatType == 'breeding';
    if (hasCompleteAction && (_transaction == null || _transaction!.status == 'pending')) {
      options.add(MingrrOptionItem(
        icon: AppIcons.successOutlined,
        label: chatType == 'marketplace' ? '거래 완료하기' : '만남 완료하기',
        color: context.features.success,
        onTap: _showCompleteDialog,
      ));
    }
    
    // 평가하기 버튼
    if (canRate) {
      options.add(MingrrOptionItem(
        icon: AppIcons.starOutlined,
        label: '평가하기',
        color: Colors.amber,
        onTap: _showRatingSheet,
      ));
    }
    
    options.addAll([
      MingrrOptionItem(
        icon: AppIcons.notificationsNone,
        label: '알림 끄기',
        onTap: () => MingrrSnackBar.success(context, '알림이 꺼졌습니다'),
      ),
      MingrrOptionItem(
        icon: AppIcons.block,
        label: '차단하기',
        color: Colors.orange,
        onTap: () => _blockUser(context),
      ),
      MingrrOptionItem(
        icon: AppIcons.report,
        label: '신고하기',
        color: Colors.orange,
        onTap: _showReportDialog,
      ),
      MingrrOptionItem(
        icon: AppIcons.exit,
        label: '채팅방 나가기',
        isDestructive: true,
        onTap: () => _leaveChatRoom(context),
      ),
    ]);
    
    showMingrrOptionsSheet(context: context, options: options);
  }

  /// 상대방 차단
  Future<void> _blockUser(BuildContext context) async {
    final myUserId = ref.read(authStateProvider).valueOrNull?.uid;
    if (myUserId == null) {
      MingrrSnackBar.warning(context, '로그인이 필요합니다');
      return;
    }

    final otherParticipant = _chatRoom?.getOtherParticipant(myUserId);
    if (otherParticipant == null) return;

    showConfirmSheet(
      context,
      type: ConfirmSheetType.userBlock,
      onConfirm: () async {
        try {
          await _firestoreService.blockUser(myUserId, otherParticipant.id);
          if (mounted) {
            MingrrSnackBar.success(context, '${otherParticipant.nickname}님을 차단했습니다');
            Navigator.pop(context); // 채팅 상세 화면 닫기
          }
        } catch (e) {
          if (mounted) {
            ErrorHandler.showError(context, e, tag: 'ChatDetail', operation: '사용자 차단');
          }
        }
      },
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
        final ratingType = RatingType.fromActivityType(chatType);
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
        ErrorHandler.showError(context, e, tag: 'ChatDetail', operation: '데이터 처리');
      }
    }
  }

  void _showRatingSheet() {
    final myUserId = ref.read(authStateProvider).valueOrNull?.uid ?? '';
    final otherParticipant = _chatRoom?.getOtherParticipant(myUserId);
    final chatType = _chatRoom?.type ?? 'dating';

    if (otherParticipant == null) return;

    showRatingModal(
      context,
      targetUserId: otherParticipant.id,
      targetName: otherParticipant.petName ?? otherParticipant.nickname,
      targetImageUrl: otherParticipant.petImageUrl ?? otherParticipant.profileImageUrl,
      ratingType: RatingType.fromActivityType(chatType),
      relatedId: widget.chatRoomId,
      onComplete: () async {
        // 평가 완료 표시
        if (_transaction != null) {
          final isSeller = myUserId == _transaction!.sellerId;
          await _ratingService.markAsRated(_transaction!.id, isSeller);
          await _loadTransaction();
        }
      },
    );
  }


  void _showReportDialog() async {
    final myUserId = ref.read(authStateProvider).valueOrNull?.uid ?? '';
    final otherParticipant = _chatRoom?.getOtherParticipant(myUserId);

    if (otherParticipant == null) return;

    final reason = await showSelectionDialog(
      context,
      title: '신고하기',
      subtitle: '신고 사유를 선택해주세요',
      options: ['욕설/비방', '사기/허위정보', '노쇼', '부적절한 행동', '기타'],
      confirmText: '신고',
      confirmColor: Colors.red,
      icon: AppIcons.report,
    );

    if (reason != null && mounted) {
      await _ratingService.reportUser(
        myUserId,
        otherParticipant.id,
        reason,
      );
      if (mounted) {
        MingrrSnackBar.success(context, '신고가 접수되었습니다');
      }
    }
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
        return context.features.dating;
      case 'marketplace':
      case 'market':
        return context.features.market;
      case 'community':
      case 'group':
        return context.features.social;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }
}
