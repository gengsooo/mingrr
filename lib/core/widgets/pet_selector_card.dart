import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../../models/pet_model.dart';

/// ============================================================
/// 반려동물 선택 카드 컴포넌트
/// 데이트 신청, 교배 신청, 교배 글쓰기에서 공통으로 사용
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
    final color = accentColor ?? AppColors.dating;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // 프로필 이미지 (동그라미)
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.2),
                image: pet.primaryPhotoUrl != null
                    ? DecorationImage(
                        image: NetworkImage(pet.primaryPhotoUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: pet.primaryPhotoUrl == null
                  ? const Center(child: Text('🐶', style: TextStyle(fontSize: 20)))
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
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            
            // 좋아요 수
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.favorite,
                  size: 16,
                  color: color,
                ),
                const SizedBox(width: 4),
                Text(
                  '${pet.likeCount}',
                  style: TextStyle(
                    fontSize: 13,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
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
    final color = widget.accentColor ?? AppColors.dating;
    
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      padding: const EdgeInsets.all(AppSizes.paddingL),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXL)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 핸들
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSizes.gapL),
          
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
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: AppSizes.gapL),
          
          // 반려동물 목록
          Flexible(
            child: widget.pets.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.pets, size: 48, color: AppColors.textHint),
                          SizedBox(height: 12),
                          Text(
                            '등록된 반려동물이 없습니다',
                            style: TextStyle(color: AppColors.textSecondary),
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
          const SizedBox(height: AppSizes.gapL),
          
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
                disabledBackgroundColor: AppColors.divider,
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
