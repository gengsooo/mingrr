import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/feature_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/services/dating_service.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/dialogs/confirm_sheet.dart';
import '../../../../models/dating_model.dart';
import '../../../../models/pet_model.dart';
import '../../../dating/presentation/providers/dating_provider.dart';
import '../../../pet/presentation/providers/pet_provider.dart';

/// 받은 데이팅 신청 화면
class ReceivedDatingRequestsScreen extends ConsumerStatefulWidget {
  const ReceivedDatingRequestsScreen({super.key});

  @override
  ConsumerState<ReceivedDatingRequestsScreen> createState() => _ReceivedDatingRequestsScreenState();
}

class _ReceivedDatingRequestsScreenState extends ConsumerState<ReceivedDatingRequestsScreen> {
  final DatingService _datingService = DatingService();
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(receivedDatingRequestsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('받은 데이팅 신청'),
      ),
      body: requestsAsync.when(
        data: (requests) {
          if (requests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: Theme.of(context).colorScheme.outlineVariant),
                  const SizedBox(height: AppSizes.gapL),
                  Text(
                    '아직 받은 신청이 없어요',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSizes.gapS),
                  Text(
                    '데이팅에서 활동해보세요!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                ],
              ),
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(AppSizes.paddingM),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return _buildRequestItem(context, request);
            },
          );
        },
        loading: () => const MingrrLoadingState(
          type: MingrrLoadingType.dating,
          message: '받은 신청을 불러오고 있어요',
        ),
        error: (_, __) => MingrrErrorState(
          onRetry: () => ref.invalidate(receivedDatingRequestsProvider),
        ),
      ),
    );
  }
  
  Widget _buildRequestItem(BuildContext context, DatingRequestModel request) {
    final petAsync = ref.watch(petByIdProvider(request.fromPetId));
    
    return MingrrCard(
      margin: const EdgeInsets.only(bottom: AppSizes.gapM),
      child: petAsync.when(
        data: (pet) => _buildRequestContent(context, request, pet),
        loading: () => _buildLoadingContent(),
        error: (_, __) => _buildRequestContent(context, request, null),
      ),
    );
  }
  
  Widget _buildLoadingContent() {
    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.outline,
            borderRadius: BorderRadius.circular(AppSizes.radiusS),
          ),
        ),
        const SizedBox(width: AppSizes.gapM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 100, height: 16, color: Theme.of(context).colorScheme.outline),
              const SizedBox(height: AppSizes.gapS),
              Container(width: 150, height: 12, color: Theme.of(context).colorScheme.outline),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildRequestContent(BuildContext context, DatingRequestModel request, PetModel? pet) {
    return Row(
      children: [
        // 프로필 이미지
        GestureDetector(
          onTap: () => context.push('/dating/detail/${request.fromPetId}'),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusS),
            child: pet?.displayImageUrl != null
                ? Image.network(
                    pet!.displayImageUrl!,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildDefaultPetImage(),
                  )
                : _buildDefaultPetImage(),
          ),
        ),
        const SizedBox(width: AppSizes.gapM),
        // 정보
        Expanded(
          child: GestureDetector(
            onTap: () => context.push('/dating/detail/${request.fromPetId}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pet?.name ?? '반려동물',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (pet != null) ...[
                  const SizedBox(height: AppSizes.gapXXS),
                  Text(
                    '${pet.breed ?? '믹스견'} · ${pet.ageString}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                ],
                const SizedBox(height: AppSizes.gapXS),
                Text(
                  request.message ?? '데이팅 신청을 보냈어요!',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
        // 수락/거절 버튼
        if (request.status == DatingRequestStatus.pending)
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.close, color: Theme.of(context).colorScheme.outlineVariant),
                onPressed: _isProcessing ? null : () => _rejectRequest(request),
              ),
              IconButton(
                icon: Icon(Icons.favorite, color: context.features.dating),
                onPressed: _isProcessing ? null : () => _acceptRequest(request),
              ),
            ],
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM, vertical: AppSizes.paddingXS),
            decoration: BoxDecoration(
              color: request.status == DatingRequestStatus.accepted 
                  ? context.features.success.withValues(alpha: 0.1)
                  : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusS),
            ),
            child: Text(
              request.status == DatingRequestStatus.accepted ? '수락됨' : '거절됨',
              style: TextStyle(
                fontSize: 12,
                color: request.status == DatingRequestStatus.accepted 
                    ? context.features.success 
                    : Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ),
      ],
    );
  }
  
  Widget _buildDefaultPetImage() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: context.features.datingContainer,
        borderRadius: BorderRadius.circular(AppSizes.radiusS),
      ),
      child: Icon(Icons.pets, color: context.features.dating, size: 30),
    );
  }
  
  /// 데이팅 신청 수락
  Future<void> _acceptRequest(DatingRequestModel request) async {
    setState(() => _isProcessing = true);
    
    try {
      final match = await _datingService.acceptDatingRequest(request.id);
      
      if (mounted) {
        if (match?.chatRoomId != null) {
          MingrrSnackBar.withAction(
            context,
            message: '매칭 성공! 채팅을 시작해보세요 🎉',
            actionLabel: '채팅하기',
            onAction: () => context.push('/chat/${match!.chatRoomId}'),
            backgroundColor: context.features.success,
          );
        } else {
          MingrrSnackBar.success(context, '매칭 성공! 채팅을 시작해보세요 🎉');
        }
      }
    } catch (e) {
      if (mounted) {
        MingrrSnackBar.error(context, '오류가 발생했습니다: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
  
  /// 데이팅 신청 거절
  Future<void> _rejectRequest(DatingRequestModel request) async {
    showConfirmSheet(
      context,
      type: ConfirmSheetType.dateReject,
      onConfirm: () async {
        setState(() => _isProcessing = true);
        
        try {
          await _datingService.rejectDatingRequest(request.id);
          
          if (mounted) {
            MingrrSnackBar.info(context, '신청을 거절했습니다');
          }
        } catch (e) {
          if (mounted) {
            MingrrSnackBar.error(context, '오류가 발생했습니다: $e');
          }
        } finally {
          if (mounted) {
            setState(() => _isProcessing = false);
          }
        }
      },
    );
  }
}
