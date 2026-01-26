import 'package:flutter/material.dart';
import '../../theme/feature_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../constants/app_sizes.dart';
import '../../../models/pet_model.dart';
import '../common_widgets.dart';
import 'mingrr_bottom_sheet.dart';
import '../cards/pet_selector_card.dart';
import '../../utils/responsive_utils.dart';

/// ============================================================
/// 공통 요청 바텀시트
/// 데이트 신청, 교배 신청, 소모임 가입 등에 사용
/// ============================================================

enum RequestSheetType {
  date,      // 데이트 신청
  breeding,  // 교배 신청
  groupJoin, // 소모임 가입
}

class RequestSheet extends StatefulWidget {
  final RequestSheetType type;
  final String? targetName;
  final void Function(String? message, {PetModel? selectedPet}) onConfirm;
  final VoidCallback? onCancel;
  final bool showMessageInput;
  final List<PetModel>? myPets; // 내 반려동물 목록 (데이트/교배 신청 시)

  const RequestSheet({
    super.key,
    required this.type,
    this.targetName,
    required this.onConfirm,
    this.onCancel,
    this.showMessageInput = true,
    this.myPets,
  });

  @override
  State<RequestSheet> createState() => _RequestSheetState();
}

class _RequestSheetState extends State<RequestSheet> {
  final _messageController = TextEditingController();
  PetModel? _selectedPet;

  /// 제출 가능 여부 (데이트/교배 신청 시 반려동물 선택 필수)
  bool get _canSubmit {
    if (widget.type != RequestSheetType.groupJoin) {
      // 반려동물이 없으면 신청 불가
      if (widget.myPets == null || widget.myPets!.isEmpty) {
        return false;
      }
      // 반려동물이 있으면 선택 필수
      return _selectedPet != null;
    }
    return true;
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = _getConfig();
    final showInput = widget.showMessageInput && widget.type != RequestSheetType.groupJoin;
    final keyboardHeight = ResponsiveUtils.keyboardHeight(context);
    final bottomPadding = ResponsiveUtils.bottomSafeArea(context);
    
    return Container(
      constraints: BoxConstraints(
        maxHeight: ResponsiveUtils.maxSheetHeight(context),
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXL)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BottomSheetHandle(),
          // 스크롤 가능한 콘텐츠 영역
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL),
              child: Column(
                children: [
                  // 아이콘
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: config.color.withValues(alpha: AppOpacity.o10),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(config.icon, size: 28, color: config.color),
                  ),
                  const SizedBox(height: AppSizes.gapM),
                  
                  // 제목
                  Text(
                    config.title,
                    style: AppTextStyles.headlineSmall(context),
                  ),
                  const SizedBox(height: AppSizes.gapXS),
                  
                  // 설명
                  Text(
                    config.description,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall(context).copyWith(height: 1.4),
                  ),
                  
                  // 반려동물 선택 (데이트/교배 신청 시)
                  if (widget.type != RequestSheetType.groupJoin) ...[
                    const SizedBox(height: AppSizes.gapM),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '신청할 반려동물 선택',
                        style: AppTextStyles.titleMedium(context),
                      ),
                    ),
                    const SizedBox(height: AppSizes.gapS),
                    if (widget.myPets == null || widget.myPets!.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(AppSizes.paddingL),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(AppSizes.radiusS),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Theme.of(context).colorScheme.outlineVariant, size: 20),
                            const SizedBox(width: AppSizes.gapS),
                            Expanded(
                              child: Text(
                                '등록된 반려동물이 없습니다.\n프로필에서 반려동물을 먼저 등록해주세요.',
                                style: AppTextStyles.bodySmall(context),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 180),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: widget.myPets!.length,
                          separatorBuilder: (_, __) => const SizedBox(height: AppSizes.gapS),
                          itemBuilder: (context, index) {
                            final pet = widget.myPets![index];
                            return PetSelectorCard(
                              pet: pet,
                              isSelected: _selectedPet?.id == pet.id,
                              accentColor: config.color,
                              onTap: () => setState(() => _selectedPet = pet),
                            );
                          },
                        ),
                      ),
                  ],
                  
                  // 메시지 입력 (데이트/교배 신청만)
                  if (showInput) ...[
                    const SizedBox(height: AppSizes.gapM),
                    TextField(
                      controller: _messageController,
                      maxLength: 20,
                      decoration: InputDecoration(
                        hintText: '한줄 메시지를 남겨보세요 (선택)',
                        hintStyle: AppTextStyles.bodySmall(context).copyWith(color: Theme.of(context).colorScheme.outlineVariant),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                        contentPadding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM, vertical: AppSizes.paddingM),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radiusS),
                          borderSide: BorderSide.none,
                        ),
                        counterText: '',
                      ),
                      style: AppTextStyles.bodyMedium(context),
                    ),
                  ],
                  const SizedBox(height: AppSizes.gapS),
                ],
              ),
            ),
          ),
          // 버튼 (키보드 위에 고정)
          Container(
            padding: EdgeInsets.only(
              left: AppSizes.bottomSheetButtonPaddingH,
              right: AppSizes.bottomSheetButtonPaddingH,
              top: AppSizes.bottomSheetButtonPaddingV,
              bottom: keyboardHeight > 0 
                  ? keyboardHeight + AppSizes.bottomSheetButtonPaddingV 
                  : bottomPadding + AppSizes.bottomSheetButtonPaddingV,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: AppShadows.shadowL(Theme.of(context).brightness == Brightness.dark),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onCancel?.call();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingM),
                      side: BorderSide(color: Theme.of(context).colorScheme.outline),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusS),
                      ),
                    ),
                    child: Text('취소', style: AppTextStyles.labelLarge(context)),
                  ),
                ),
                const SizedBox(width: AppSizes.gapM),
                Expanded(
                  child: MingrrButton(
                    text: config.confirmText,
                    onPressed: _canSubmit ? () {
                      final message = _messageController.text.trim();
                      Navigator.pop(context);
                      widget.onConfirm(message.isEmpty ? null : message, selectedPet: _selectedPet);
                    } : null,
                    backgroundColor: config.color,
                    textColor: Colors.white,
                    height: 44,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _RequestConfig _getConfig() {
    switch (widget.type) {
      case RequestSheetType.date:
        return _RequestConfig(
          icon: Icons.favorite,
          color: context.features.dating,
          title: '데이트 신청',
          description: '${widget.targetName ?? '상대방'}에게 데이트 신청을 보낼까요?\n수락되면 채팅이 시작됩니다.',
          confirmText: '신청하기',
        );
      case RequestSheetType.breeding:
        return _RequestConfig(
          icon: Icons.pets,
          color: context.features.dating,
          title: '교배 신청',
          description: '${widget.targetName ?? '상대방'}에게 교배 신청을 보낼까요?\n수락되면 채팅이 시작됩니다.',
          confirmText: '신청하기',
        );
      case RequestSheetType.groupJoin:
        return _RequestConfig(
          icon: Icons.groups,
          color: context.features.social,
          title: '소모임 가입',
          description: '${widget.targetName ?? '이 모임'}에 가입 신청을 보낼까요?\n승인되면 모임에 참여할 수 있습니다.',
          confirmText: '가입하기',
        );
    }
  }
}

class _RequestConfig {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final String confirmText;

  _RequestConfig({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.confirmText,
  });
}

/// 데이트 신청 바텀시트 표시
void showDateRequestSheet(
  BuildContext context, {
  String? targetName,
  List<PetModel>? myPets,
  required void Function(String? message, {PetModel? selectedPet}) onConfirm,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: ResponsiveUtils.keyboardHeight(ctx)),
      child: RequestSheet(
        type: RequestSheetType.date,
        targetName: targetName,
        myPets: myPets,
        onConfirm: onConfirm,
      ),
    ),
  );
}

/// 교배 신청 바텀시트 표시
void showBreedingRequestSheet(
  BuildContext context, {
  String? targetName,
  List<PetModel>? myPets,
  required void Function(String? message, {PetModel? selectedPet}) onConfirm,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: ResponsiveUtils.keyboardHeight(ctx)),
      child: RequestSheet(
        type: RequestSheetType.breeding,
        targetName: targetName,
        myPets: myPets,
        onConfirm: onConfirm,
      ),
    ),
  );
}

/// 소모임 가입 바텀시트 표시
void showGroupJoinSheet(
  BuildContext context, {
  String? groupName,
  required VoidCallback onConfirm,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => RequestSheet(
      type: RequestSheetType.groupJoin,
      targetName: groupName,
      onConfirm: (_, {selectedPet}) => onConfirm(),
    ),
  );
}
