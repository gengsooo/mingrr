import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/theme/feature_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/pet_constants.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/mingrr_image.dart';
import '../../../../core/widgets/badges/svg_icons.dart';
import '../../../../models/pet_model.dart';
import '../../../pet/presentation/providers/pet_provider.dart';
import '../providers/health_provider.dart';
import 'walk_record_detail_screen.dart';
import 'health_record_add_screens.dart';

/// ============================================================
/// 건강수첩 화면 (Firebase 연동 버전)
/// ============================================================

class HealthScreen extends ConsumerStatefulWidget {
  final String? initialPetId; // 초기 선택할 반려동물 ID

  const HealthScreen({super.key, this.initialPetId});

  @override
  ConsumerState<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends ConsumerState<HealthScreen> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    // 초기 petId가 있으면 provider 업데이트
    if (widget.initialPetId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(selectedPetIdProvider.notifier).state = widget.initialPetId;
        _initialized = true;
      });
    } else {
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final petsAsync = ref.watch(userPetsProvider);
    final selectedPetId = ref.watch(selectedPetIdProvider);
    final selectedTab = ref.watch(selectedHealthTabProvider);

    final categories = _getCategories();

    return Scaffold(
      appBar: AppBar(
        title: const Text('건강수첩'),
        leading: IconButton(
          icon: const Icon(AppIcons.back, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: petsAsync.when(
        loading: () => const MingrrLoadingState(type: MingrrLoadingType.health, message: '건강 정보를 불러오고 있어요'),
        error: (_, __) => MingrrErrorState(
          onRetry: () => ref.invalidate(userPetsProvider),
        ),
        data: (pets) {
          if (pets.isEmpty) {
            return _buildNoPetsView(context);
          }

          final selectedPet = pets.firstWhere(
            (p) => p.id == selectedPetId,
            orElse: () => pets.first,
          );

          return Column(
            children: [
              // 반려동물 선택기
              _buildPetSelector(context, ref, pets, selectedPet),
              
              // 카테고리 탭
              _buildCategoryTabs(context, ref, categories, selectedTab),
              
              // 탭 컨텐츠
              Expanded(
                child: _buildTabContent(context, ref, categories[selectedTab], selectedPet),
              ),
            ],
          );
        },
      ),
      floatingActionButton: petsAsync.maybeWhen(
        data: (pets) => pets.isNotEmpty
            ? MingrrFAB.add(
                onPressed: () {
                  final selectedPet = pets.firstWhere(
                    (p) => p.id == selectedPetId,
                    orElse: () => pets.first,
                  );
                  _showAddRecordSheet(context, ref, categories[selectedTab], selectedPet);
                },
                backgroundColor: context.features.health,
                tooltip: '건강 기록 추가',
              )
            : null,
        orElse: () => null,
      ),
    );
  }

  List<HealthCategory> _getCategories() {
    return [
      HealthCategory.weight,
      HealthCategory.walk,
      HealthCategory.grooming,  // 양치/치석은 그루밍 하위로 이동
      HealthCategory.medication,
      HealthCategory.vaccination,
      HealthCategory.checkup,
      HealthCategory.special,
    ];
  }

  Widget _buildNoPetsView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const DefaultPetIcon(size: 60),
          const SizedBox(height: AppSizes.gapL),
          Text(
            '등록된 반려동물이 없습니다',
            style: AppTextStyles.headlineSmall(context),
          ),
          const SizedBox(height: AppSizes.gapS),
          Text(
            '반려동물을 먼저 등록해주세요',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSizes.gapXL),
          MingrrButton(
            text: '돌아가기',
            onPressed: () => Navigator.pop(context),
            backgroundColor: context.features.health,
            textColor: Colors.white,
            height: 44,
            width: 120,
          ),
        ],
      ),
    );
  }

  /// 반려동물 선택기 (동그란 프로필 + 이름만)
  Widget _buildPetSelector(BuildContext context, WidgetRef ref, List<PetModel> pets, PetModel selectedPet) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingM, horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: pets.map((pet) {
            final isSelected = pet.id == selectedPet.id;
            
            return GestureDetector(
              onTap: () => ref.read(selectedPetIdProvider.notifier).state = pet.id,
              child: Container(
                margin: const EdgeInsets.only(right: AppSizes.paddingL),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 동그란 프로필 이미지
                    MingrrImage.petAvatar(
                      imageUrl: pet.profileImageUrl,
                      size: 56,
                      borderColor: isSelected ? context.features.health : Theme.of(context).colorScheme.outline,
                      borderWidth: isSelected ? 3 : 1,
                    ),
                    const SizedBox(height: AppSizes.gapSM),
                    // 이름
                    Text(
                      pet.name,
                      style: AppTextStyles.bodySmall(context)
                          .withWeight(isSelected ? FontWeight.w600 : FontWeight.w400)
                          .withColor(isSelected ? context.features.health : Theme.of(context).colorScheme.onSurface),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCategoryTabs(BuildContext context, WidgetRef ref, List<HealthCategory> categories, int selectedTab) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSizes.paddingS),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL),
        child: Row(
          children: List.generate(categories.length, (index) {
            final category = categories[index];
            final isSelected = index == selectedTab;
            
            return GestureDetector(
              onTap: () => ref.read(selectedHealthTabProvider.notifier).state = index,
              child: Container(
                margin: const EdgeInsets.only(right: AppSizes.paddingS),
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL, vertical: AppSizes.paddingS),
                decoration: BoxDecoration(
                  color: isSelected ? context.features.health : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSizes.radiusXL),
                  border: Border.all(
                    color: isSelected ? context.features.health : Theme.of(context).colorScheme.outline,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(category.icon, size: 18, color: isSelected ? Colors.white : context.features.health),
                    const SizedBox(width: AppSizes.gapSM),
                    Text(
                      category.label,
                      style: AppTextStyles.bodyMedium(context)
                          .withWeight(isSelected ? FontWeight.w600 : FontWeight.w400)
                          .withColor(isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildTabContent(BuildContext context, WidgetRef ref, HealthCategory category, PetModel pet) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 요약 카드
          _buildSummaryCard(context, ref, category, pet),
          const SizedBox(height: AppSizes.gapLL),
          
          // 최근 기록
          Text(
            '최근 기록',
            style: AppTextStyles.headlineSmall(context),
          ),
          const SizedBox(height: AppSizes.gapM),
          _buildRecentRecords(context, ref, category, pet),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, WidgetRef ref, HealthCategory category, PetModel pet) {
    return MingrrCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: context.features.health.withValues(alpha: AppOpacity.o15),
                  borderRadius: BorderRadius.circular(AppSizes.radiusS),
                ),
                child: Icon(category.icon, size: 24, color: context.features.health),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${pet.name}의 ${category.label}',
                      style: AppTextStyles.headlineSmall(context),
                    ),
                    Text(
                      category.description,
                      style: AppTextStyles.caption(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.gapL),
          const MingrrDivider(),
          const SizedBox(height: AppSizes.gapM),
          _buildCategorySummary(context, ref, category, pet),
        ],
      ),
    );
  }

  Widget _buildCategorySummary(BuildContext context, WidgetRef ref, HealthCategory category, PetModel pet) {
    switch (category) {
      case HealthCategory.weight:
        return _buildWeightSummary(context, ref, pet);
      case HealthCategory.walk:
        return _buildWalkSummary(context, ref, pet);
      default:
        return _buildDefaultSummary(context, category);
    }
  }

  Widget _buildWeightSummary(BuildContext context, WidgetRef ref, PetModel pet) {
    final recordsAsync = ref.watch(weightRecordsProvider(pet.id));
    
    return recordsAsync.when(
      loading: () => const MingrrLoadingState(type: MingrrLoadingType.health, message: '건강 정보를 불러오고 있어요'),
      error: (_, __) => MingrrErrorState(
        onRetry: () => ref.invalidate(weightRecordsProvider(pet.id)),
      ),
      data: (records) {
        if (records.isEmpty) {
          return Center(
            child: Text('기록이 없습니다', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          );
        }
        
        final latest = records.first;
        final previous = records.length > 1 ? records[1] : null;
        final change = previous != null ? latest.weight - previous.weight : 0.0;
        
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSummaryItem(context, '현재', '${latest.weight.toStringAsFixed(1)}kg', context.features.health),
            _buildSummaryItem(
              context,
              '변화',
              '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}kg',
              change > 0 ? Colors.orange : context.features.success,
            ),
            _buildSummaryItem(context, '기록 수', '${records.length}회', Theme.of(context).colorScheme.onSurfaceVariant),
          ],
        );
      },
    );
  }

  Widget _buildWalkSummary(BuildContext context, WidgetRef ref, PetModel pet) {
    final recordsAsync = ref.watch(walkRecordsProvider(pet.id));
    
    return recordsAsync.when(
      loading: () => const MingrrLoadingState(type: MingrrLoadingType.health, message: '건강 정보를 불러오고 있어요'),
      error: (_, __) => MingrrErrorState(
        onRetry: () => ref.invalidate(walkRecordsProvider(pet.id)),
      ),
      data: (records) {
        if (records.isEmpty) {
          return Center(
            child: Text('기록이 없습니다', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          );
        }
        
        // 이번 주 산책 통계
        final now = DateTime.now();
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final thisWeekRecords = records.where((r) => r.startTime.isAfter(weekStart)).toList();
        
        final totalDistance = thisWeekRecords.fold<double>(0, (sum, r) => sum + r.distance);
        final totalMinutes = thisWeekRecords.fold<int>(0, (sum, r) => sum + r.durationMinutes);
        
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSummaryItem(context, '이번 주', '${thisWeekRecords.length}회', context.features.health),
            _buildSummaryItem(context, '총 거리', '${(totalDistance / 1000).toStringAsFixed(1)}km', context.features.walk),
            _buildSummaryItem(context, '총 시간', '${totalMinutes}분', context.features.success),
          ],
        );
      },
    );
  }

  Widget _buildDefaultSummary(BuildContext context, HealthCategory category) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildSummaryItem(context, '총 기록', '-', context.features.health),
        _buildSummaryItem(context, '최근', '-', Theme.of(context).colorScheme.onSurfaceVariant),
        _buildSummaryItem(context, '다음', '-', context.features.success),
      ],
    );
  }

  Widget _buildSummaryItem(BuildContext context, String label, String value, Color color, {Color? labelColor}) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.headlineSmall(context).copyWith(color: color),
        ),
        const SizedBox(height: AppSizes.gapXS),
        Text(
          label,
          style: AppTextStyles.caption(context).copyWith(color: labelColor ?? color.withValues(alpha: AppOpacity.o70)),
        ),
      ],
    );
  }

  Widget _buildRecentRecords(BuildContext context, WidgetRef ref, HealthCategory category, PetModel pet) {
    switch (category) {
      case HealthCategory.weight:
        return _buildWeightRecords(context, ref, pet);
      case HealthCategory.walk:
        return _buildWalkRecords(context, ref, pet);
      case HealthCategory.grooming:
        return _buildGroomingRecords(context, ref, pet);
      case HealthCategory.vaccination:
        return _buildVaccinationRecords(context, ref, pet);
      case HealthCategory.checkup:
        return _buildCheckupRecords(context, ref, pet);
      case HealthCategory.medication:
        return _buildMedicationRecords(context, ref, pet);
      default:
        return _buildEmptyRecords(context);
    }
  }

  Widget _buildWeightRecords(BuildContext context, WidgetRef ref, PetModel pet) {
    final recordsAsync = ref.watch(weightRecordsProvider(pet.id));
    
    return recordsAsync.when(
      loading: () => const MingrrLoadingState(type: MingrrLoadingType.health, message: '건강 정보를 불러오고 있어요'),
      error: (_, __) => MingrrErrorState(
        onRetry: () => ref.invalidate(weightRecordsProvider(pet.id)),
      ),
      data: (records) {
        if (records.isEmpty) return _buildEmptyRecords(context);
        
        return Column(
          children: records.take(5).map((record) {
            return MingrrRecordTile(
              icon: AppIcons.weight,
              iconColor: context.features.health,
              title: '${record.weight.toStringAsFixed(1)}kg',
              subtitle: _formatDate(record.recordDate),
              onTap: () {
                // TODO: 상세 화면으로 이동
              },
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildWalkRecords(BuildContext context, WidgetRef ref, PetModel pet) {
    final recordsAsync = ref.watch(walkRecordsProvider(pet.id));
    
    return recordsAsync.when(
      loading: () => const MingrrLoadingState(type: MingrrLoadingType.health, message: '건강 정보를 불러오고 있어요'),
      error: (_, __) => MingrrErrorState(
        onRetry: () => ref.invalidate(walkRecordsProvider(pet.id)),
      ),
      data: (records) {
        if (records.isEmpty) return _buildEmptyRecords(context);
        
        return Column(
          children: records.take(5).map((record) {
            return MingrrRecordTile(
              icon: AppIcons.walk,
              iconColor: context.features.walk,
              title: '${record.durationMinutes}분, ${record.distanceString}',
              subtitle: _formatDateTime(record.startTime),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WalkRecordDetailScreen(
                      record: record,
                      petNames: [pet.name],
                    ),
                  ),
                );
              },
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildGroomingRecords(BuildContext context, WidgetRef ref, PetModel pet) {
    final recordsAsync = ref.watch(groomingRecordsProvider(pet.id));
    
    return recordsAsync.when(
      loading: () => const MingrrLoadingState(type: MingrrLoadingType.health, message: '건강 정보를 불러오고 있어요'),
      error: (_, __) => MingrrErrorState(
        onRetry: () => ref.invalidate(groomingRecordsProvider(pet.id)),
      ),
      data: (records) {
        if (records.isEmpty) return _buildEmptyRecords(context);
        
        return Column(
          children: records.take(5).map((record) {
            return MingrrRecordTile(
              icon: AppIcons.grooming,
              iconColor: context.features.health,
              title: record.groomingType.label,
              subtitle: '${_formatDate(record.recordDate)} • ${record.location ?? ""}',
              onTap: () {},
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildVaccinationRecords(BuildContext context, WidgetRef ref, PetModel pet) {
    final recordsAsync = ref.watch(vaccinationRecordsProvider(pet.id));
    
    return recordsAsync.when(
      loading: () => const MingrrLoadingState(type: MingrrLoadingType.health, message: '건강 정보를 불러오고 있어요'),
      error: (_, __) => MingrrErrorState(
        onRetry: () => ref.invalidate(vaccinationRecordsProvider(pet.id)),
      ),
      data: (records) {
        if (records.isEmpty) return _buildEmptyRecords(context);
        
        return Column(
          children: records.take(5).map((record) {
            return MingrrRecordTile(
              icon: AppIcons.vaccination,
              iconColor: context.features.health,
              title: record.vaccineName,
              subtitle: '${_formatDate(record.vaccinationDate)} • ${record.hospitalName ?? ""}',
              onTap: () {},
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildCheckupRecords(BuildContext context, WidgetRef ref, PetModel pet) {
    final recordsAsync = ref.watch(checkupRecordsProvider(pet.id));
    
    return recordsAsync.when(
      loading: () => const MingrrLoadingState(type: MingrrLoadingType.health, message: '건강 정보를 불러오고 있어요'),
      error: (_, __) => MingrrErrorState(
        onRetry: () => ref.invalidate(checkupRecordsProvider(pet.id)),
      ),
      data: (records) {
        if (records.isEmpty) return _buildEmptyRecords(context);
        
        return Column(
          children: records.take(5).map((record) {
            return MingrrRecordTile(
              icon: AppIcons.checkup,
              iconColor: context.features.health,
              title: record.diagnosis ?? '정기 검진',
              subtitle: '${_formatDate(record.checkupDate)} • ${record.hospitalName ?? ""}',
              onTap: () {},
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildMedicationRecords(BuildContext context, WidgetRef ref, PetModel pet) {
    final recordsAsync = ref.watch(medicationRecordsProvider(pet.id));
    
    return recordsAsync.when(
      loading: () => const MingrrLoadingState(type: MingrrLoadingType.health, message: '건강 정보를 불러오고 있어요'),
      error: (_, __) => MingrrErrorState(
        onRetry: () => ref.invalidate(medicationRecordsProvider(pet.id)),
      ),
      data: (records) {
        if (records.isEmpty) return _buildEmptyRecords(context);
        
        return Column(
          children: records.take(5).map((record) {
            final isActive = record.endDate == null || record.endDate!.isAfter(DateTime.now());
            
            // 저장된 medicationName에서 아이콘 ID와 이름 분리
            final parsed = _parseMedicationName(record.medicationName);
            final iconType = parsed.iconType;
            final displayName = parsed.name;
            final iconColor = Color(iconType.colorValue);
            
            return MingrrRecordTile.medication(
              iconColor: iconColor,
              title: displayName,
              subtitle: '${record.dosage ?? ""} • ${record.intervalString}',
              isActive: isActive,
              onTap: () {
                // TODO: 약 상세 화면 구현 시 연결
                MingrrSnackBar.info(context, '약 상세 화면은 준비 중입니다');
              },
            );
          }).toList(),
        );
      },
    );
  }
  
  /// medicationName에서 아이콘 타입과 이름 분리
  /// 형식: "icon_id|약이름" 또는 레거시 "pill_blue|약이름"
  ({MedicationIconType iconType, String name}) _parseMedicationName(String medicationName) {
    // 새 형식: "icon_id|약이름"
    if (medicationName.contains('|')) {
      final parts = medicationName.split('|');
      final iconId = parts[0];
      final name = parts.length > 1 ? parts[1] : medicationName;
      // 새 형식(blue, pink 등) 또는 레거시 형식(pill_blue 등) 모두 처리
      final iconType = MedicationIconType.values.any((e) => e.id == iconId)
          ? MedicationIconType.fromId(iconId)
          : MedicationIconType.fromLegacyId(iconId);
      return (iconType: iconType, name: name);
    }
    
    // 레거시 형식: "💊 약이름" 또는 그냥 "약이름"
    // 이모지 제거하고 이름만 추출
    final name = medicationName.replaceAll(RegExp(r'[💊💉🩹🧴🩺🏥❤️⭐💧🧂]\s*'), '').trim();
    return (iconType: MedicationIconType.blue, name: name.isEmpty ? medicationName : name);
  }
  
  Widget _buildEmptyRecords(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingXL),
      child: Center(
        child: Column(
          children: [
            Icon(AppIcons.special, size: 40, color: Theme.of(context).colorScheme.outlineVariant),
            const SizedBox(height: AppSizes.gapM),
            Text(
              '아직 기록이 없습니다',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSizes.gapXS),
            Text(
              '+ 버튼을 눌러 첫 기록을 추가해보세요',
              style: AppTextStyles.caption(context),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.month}/${date.day} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showAddRecordSheet(BuildContext context, WidgetRef ref, HealthCategory category, PetModel pet) {
    switch (category) {
      case HealthCategory.weight:
        AddWeightRecordScreen.show(context, pet.id, pet.name);
        break;
      case HealthCategory.walk:
        MingrrSnackBar.info(context, '산책은 산책 화면에서 시작해주세요');
        break;
      case HealthCategory.grooming:
        AddGroomingRecordScreen.show(context, pet.id, pet.name);
        break;
      case HealthCategory.medication:
        AddMedicationRecordScreen.show(context, pet.id, pet.name);
        break;
      case HealthCategory.vaccination:
        AddVaccinationRecordScreen.show(context, pet.id, pet.name);
        break;
      case HealthCategory.checkup:
        AddCheckupRecordScreen.show(context, pet.id, pet.name);
        break;
      case HealthCategory.special:
        AddSpecialRecordScreen.show(context, pet.id, pet.name);
        break;
    }
  }
}
