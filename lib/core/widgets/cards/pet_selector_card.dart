import 'package:flutter/material.dart';
import '../../constants/app_icons.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/feature_colors.dart';
import '../../constants/app_sizes.dart';
import '../../../models/pet_model.dart';
import '../common_widgets.dart';
import '../sheets/mingrr_bottom_sheet.dart';
import '../badges/info_badge.dart' show LikeCountText, InfoBadgeSize, PedigreeBadge;
import '../../utils/responsive_utils.dart';

/// ============================================================
/// 반려동물 선택 카드 컴포넌트
/// 데이트 신청, 교배 신청, 교배 등록에서 공통으로 사용
/// ============================================================

class PetSelectorCard extends StatelessWidget {
  final PetModel pet;
  final bool isSelected;
  final VoidCallback? onTap;
  final Color? accentColor;

  const PetSelectorCard({
    super.key,
    required this.pet,
    this.isSelected = false,
    this.onTap,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? context.features.dating;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM, vertical: AppSizes.paddingS),
        decoration: BoxDecoration(
          color: isSelected 
              ? color.withValues(alpha: AppOpacity.o10) 
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppSizes.radiusS),
          border: Border.all(
            color: isSelected ? color : Theme.of(context).colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // 프로필 이미지 (동그라미) - 프로필 이미지만 사용
            MingrrImage.petAvatar(
              imageUrl: pet.profileImageUrl,
              size: 48,
            ),
            const SizedBox(width: AppSizes.gapM),
            
            // 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    pet.name,
                    style: AppTextStyles.titleLarge(context).withWeight(FontWeight.w600),
                  ),
                  const SizedBox(height: AppSizes.gapXXS),
                  Text(
                    '${pet.breed} · ${pet.ageString}',
                    style: AppTextStyles.bodyMedium(context).withColor(Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            
            // 혈통서 유무 배지 (공통 컴포넌트)
            PedigreeBadge(hasPedigree: pet.hasPedigree, size: InfoBadgeSize.small, accentColor: color),
            const SizedBox(width: AppSizes.gapS),
            // 좋아요 수 (공통 컴포넌트)
            LikeCountText(count: pet.likeCount, size: InfoBadgeSize.small),
          ],
        ),
      ),
    );
  }
}

/// 반려동물 선택 바텀시트
class PetSelectorSheet extends StatefulWidget {
  final List<PetModel> pets;
  final PetModel? selectedPet;
  final String title;
  final String? description;
  final Color? accentColor;
  final void Function(PetModel pet) onSelect;

  const PetSelectorSheet({
    super.key,
    required this.pets,
    this.selectedPet,
    required this.title,
    this.description,
    this.accentColor,
    required this.onSelect,
  });

  @override
  State<PetSelectorSheet> createState() => _PetSelectorSheetState();
}

class _PetSelectorSheetState extends State<PetSelectorSheet> {
  PetModel? _selectedPet;

  @override
  void initState() {
    super.initState();
    _selectedPet = widget.selectedPet;
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.accentColor ?? context.features.dating;
    
    return Container(
      constraints: BoxConstraints(
        maxHeight: ResponsiveUtils.heightPercent(context, 0.7),
      ),
      padding: const EdgeInsets.only(
        left: AppSizes.paddingL,
        right: AppSizes.paddingL,
        bottom: AppSizes.paddingL,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSizes.radiusL)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BottomSheetHandle(),
          
          // 제목
          Text(
            widget.title,
            style: AppTextStyles.headlineSmall(context),
          ),
          if (widget.description != null) ...[
            const SizedBox(height: AppSizes.gapXS),
            Text(
              widget.description!,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall(context),
            ),
          ],
          const SizedBox(height: AppSizes.gapL),
          
          // 반려동물 목록
          Flexible(
            child: widget.pets.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSizes.paddingXL),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(AppIcons.pet, size: 48, color: Theme.of(context).colorScheme.outlineVariant),
                          const SizedBox(height: AppSizes.gapM),
                          Text(
                            '등록된 반려동물이 없습니다',
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: widget.pets.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppSizes.gapS),
                    itemBuilder: (context, index) {
                      final pet = widget.pets[index];
                      return PetSelectorCard(
                        pet: pet,
                        isSelected: _selectedPet?.id == pet.id,
                        accentColor: color,
                        onTap: () {
                          setState(() => _selectedPet = pet);
                        },
                      );
                    },
                  ),
          ),
          const SizedBox(height: AppSizes.gapM),
          
          // 선택 버튼
          MingrrButton(
            text: '선택하기',
            onPressed: _selectedPet != null
                ? () {
                    widget.onSelect(_selectedPet!);
                    Navigator.pop(context);
                  }
                : null,
            backgroundColor: color,
            textColor: Colors.white,
            height: 52,
          ),
          SizedBox(height: ResponsiveUtils.bottomSafeArea(context)),
        ],
      ),
    );
  }
}

/// 반려동물 선택 바텀시트 표시 헬퍼 함수
void showPetSelectorSheet(
  BuildContext context, {
  required List<PetModel> pets,
  PetModel? selectedPet,
  required String title,
  String? description,
  Color? accentColor,
  required void Function(PetModel pet) onSelect,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => PetSelectorSheet(
      pets: pets,
      selectedPet: selectedPet,
      title: title,
      description: description,
      accentColor: accentColor,
      onSelect: onSelect,
    ),
  );
}
