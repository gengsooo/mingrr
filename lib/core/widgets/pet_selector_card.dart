import 'package:flutter/material.dart';
import '../theme/feature_colors.dart';
import '../constants/app_sizes.dart';
import '../../models/pet_model.dart';
import 'mingrr_bottom_sheet.dart';
import 'info_badge.dart' show LikeCountText, InfoBadgeSize, PedigreeBadge;

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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected 
              ? color.withOpacity(0.1) 
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Theme.of(context).colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // 프로필 이미지 (동그라미) - 프로필 이미지만 사용
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.2),
                image: _getProfileImage(),
              ),
              child: _getProfileImage() == null
                  ? Icon(Icons.pets, size: 22, color: accentColor ?? context.features.dating)
                  : null,
            ),
            const SizedBox(width: 12),
            
            // 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    pet.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${pet.breed} · ${pet.ageString}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            
            // 혈통서 유무 배지 (공통 컴포넌트)
            PedigreeBadge(hasPedigree: pet.hasPedigree, size: InfoBadgeSize.small, accentColor: color),
            const SizedBox(width: 8),
            // 좋아요 수 (공통 컴포넌트)
            LikeCountText(count: pet.likeCount, size: InfoBadgeSize.small),
          ],
        ),
      ),
    );
  }
  
  /// 프로필 이미지만 가져오기 (대표사진 제외)
  DecorationImage? _getProfileImage() {
    final url = pet.profileImageUrl;
    if (url != null && url.isNotEmpty && !url.startsWith('default_avatar:')) {
      return DecorationImage(
        image: NetworkImage(url),
        fit: BoxFit.cover,
      );
    }
    return null;
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
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      padding: const EdgeInsets.only(
        left: AppSizes.paddingL,
        right: AppSizes.paddingL,
        bottom: AppSizes.paddingL,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXL)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BottomSheetHandle(),
          
          // 제목
          Text(
            widget.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          if (widget.description != null) ...[
            const SizedBox(height: AppSizes.gapXS),
            Text(
              widget.description!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: AppSizes.gapL),
          
          // 반려동물 목록
          Flexible(
            child: widget.pets.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.pets, size: 48, color: Theme.of(context).colorScheme.outlineVariant),
                          const SizedBox(height: 12),
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
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
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
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _selectedPet != null
                  ? () {
                      widget.onSelect(_selectedPet!);
                      Navigator.pop(context);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                disabledBackgroundColor: Theme.of(context).colorScheme.outline,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                '선택하기',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
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
