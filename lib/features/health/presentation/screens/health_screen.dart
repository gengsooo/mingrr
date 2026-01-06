import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/pet_constants.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../models/pet_model.dart';
import '../../../../models/health_model.dart';
import '../../../pet/presentation/providers/pet_provider.dart';
import '../providers/health_provider.dart';
import 'walk_record_detail_screen.dart';
import 'health_record_detail_screens.dart';
import 'medication_screen.dart';
import 'health_record_add_screens.dart';

/// ============================================================
/// 건강수첩 화면 (Firebase 연동 버전)
/// ============================================================

class HealthScreen extends ConsumerWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petsAsync = ref.watch(userPetsProvider);
    final selectedPetId = ref.watch(selectedPetIdProvider);
    final selectedTab = ref.watch(selectedHealthTabProvider);

    final categories = _getCategories();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('건강수첩'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: petsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
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
            ? FloatingActionButton(
                onPressed: () {
                  final selectedPet = pets.firstWhere(
                    (p) => p.id == selectedPetId,
                    orElse: () => pets.first,
                  );
                  _showAddRecordSheet(context, ref, categories[selectedTab], selectedPet);
                },
                backgroundColor: AppColors.health,
                child: const Icon(Icons.add, color: Colors.white),
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
          const Text('🐶', style: TextStyle(fontSize: 60)),
          const SizedBox(height: 16),
          const Text(
            '등록된 반려동물이 없습니다',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          const Text(
            '반려동물을 먼저 등록해주세요',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.health,
              foregroundColor: Colors.white,
            ),
            child: const Text('돌아가기'),
          ),
        ],
      ),
    );
  }

  /// 반려동물 선택기 (동그란 프로필 + 이름만)
  Widget _buildPetSelector(BuildContext context, WidgetRef ref, List<PetModel> pets, PetModel selectedPet) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: pets.map((pet) {
            final isSelected = pet.id == selectedPet.id;
            
            return GestureDetector(
              onTap: () => ref.read(selectedPetIdProvider.notifier).state = pet.id,
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 동그란 프로필 이미지
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.health.withOpacity(0.1),
                        border: Border.all(
                          color: isSelected ? AppColors.health : AppColors.divider,
                          width: isSelected ? 3 : 1,
                        ),
                        boxShadow: isSelected ? [
                          BoxShadow(
                            color: AppColors.health.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ] : null,
                        image: (pet.profileImageUrl != null && pet.profileImageUrl!.isNotEmpty)
                            ? DecorationImage(
                                image: NetworkImage(pet.profileImageUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: (pet.profileImageUrl == null || pet.profileImageUrl!.isEmpty)
                          ? const Center(
                              child: Text('🐶', style: TextStyle(fontSize: 24)),
                            )
                          : null,
                    ),
                    const SizedBox(height: 6),
                    // 이름
                    Text(
                      pet.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? AppColors.health : AppColors.textPrimary,
                      ),
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
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = index == selectedTab;
          
          return GestureDetector(
            onTap: () => ref.read(selectedHealthTabProvider.notifier).state = index,
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.health : Colors.transparent,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isSelected ? AppColors.health : AppColors.divider,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(category.emoji, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(
                    category.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabContent(BuildContext context, WidgetRef ref, HealthCategory category, PetModel pet) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 요약 카드
          _buildSummaryCard(context, ref, category, pet),
          const SizedBox(height: 20),
          
          // 최근 기록
          const Text(
            '최근 기록',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
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
                  color: AppColors.health.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(category.emoji, style: const TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${pet.name}의 ${category.label}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      category.description,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          _buildCategorySummary(ref, category, pet),
        ],
      ),
    );
  }

  Widget _buildCategorySummary(WidgetRef ref, HealthCategory category, PetModel pet) {
    switch (category) {
      case HealthCategory.weight:
        return _buildWeightSummary(ref, pet);
      case HealthCategory.walk:
        return _buildWalkSummary(ref, pet);
      default:
        return _buildDefaultSummary(category);
    }
  }

  Widget _buildWeightSummary(WidgetRef ref, PetModel pet) {
    final recordsAsync = ref.watch(weightRecordsProvider(pet.id));
    
    return recordsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('오류: $e'),
      data: (records) {
        if (records.isEmpty) {
          return const Center(
            child: Text('기록이 없습니다', style: TextStyle(color: AppColors.textSecondary)),
          );
        }
        
        final latest = records.first;
        final previous = records.length > 1 ? records[1] : null;
        final change = previous != null ? latest.weight - previous.weight : 0.0;
        
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSummaryItem('현재', '${latest.weight.toStringAsFixed(1)}kg', AppColors.health),
            _buildSummaryItem(
              '변화',
              '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}kg',
              change > 0 ? AppColors.warning : AppColors.success,
            ),
            _buildSummaryItem('기록 수', '${records.length}회', AppColors.textSecondary),
          ],
        );
      },
    );
  }

  Widget _buildWalkSummary(WidgetRef ref, PetModel pet) {
    final recordsAsync = ref.watch(walkRecordsProvider(pet.id));
    
    return recordsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('오류: $e'),
      data: (records) {
        if (records.isEmpty) {
          return const Center(
            child: Text('기록이 없습니다', style: TextStyle(color: AppColors.textSecondary)),
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
            _buildSummaryItem('이번 주', '${thisWeekRecords.length}회', AppColors.health),
            _buildSummaryItem('총 거리', '${(totalDistance / 1000).toStringAsFixed(1)}km', AppColors.walk),
            _buildSummaryItem('총 시간', '${totalMinutes}분', AppColors.success),
          ],
        );
      },
    );
  }

  Widget _buildDefaultSummary(HealthCategory category) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildSummaryItem('총 기록', '-', AppColors.health),
        _buildSummaryItem('최근', '-', AppColors.textSecondary),
        _buildSummaryItem('다음', '-', AppColors.success),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
        return _buildEmptyRecords();
    }
  }

  Widget _buildWeightRecords(BuildContext context, WidgetRef ref, PetModel pet) {
    final recordsAsync = ref.watch(weightRecordsProvider(pet.id));
    
    return recordsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('오류: $e'),
      data: (records) {
        if (records.isEmpty) return _buildEmptyRecords();
        
        return Column(
          children: records.take(5).map((record) {
            return _buildRecordItem(
              context,
              emoji: '⚖️',
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
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('오류: $e'),
      data: (records) {
        if (records.isEmpty) return _buildEmptyRecords();
        
        return Column(
          children: records.take(5).map((record) {
            return _buildRecordItem(
              context,
              emoji: '🚶',
              title: '${record.durationMinutes}분, ${record.distanceString}',
              subtitle: _formatDateTime(record.startTime),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WalkRecordDetailScreen(
                      record: WalkRecord(
                        id: record.id,
                        date: record.startTime,
                        startTime: record.startTime,
                        endTime: record.endTime ?? record.startTime,
                        duration: record.durationMinutes,
                        distance: record.distance,
                        calories: record.calories?.toInt() ?? 0,
                        avgSpeed: record.durationMinutes > 0 ? record.distance / (record.durationMinutes * 60) : 0,
                        maxSpeed: 0,
                        steps: 0,
                        restTime: 0,
                        weather: '맑음',
                        temperature: 20,
                        petNames: [pet.name],
                        routePoints: [],
                        memo: record.notes,
                        photos: record.photoUrls,
                      ),
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
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('오류: $e'),
      data: (records) {
        if (records.isEmpty) return _buildEmptyRecords();
        
        return Column(
          children: records.take(5).map((record) {
            return _buildRecordItem(
              context,
              emoji: '✨',
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
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('오류: $e'),
      data: (records) {
        if (records.isEmpty) return _buildEmptyRecords();
        
        return Column(
          children: records.take(5).map((record) {
            return _buildRecordItem(
              context,
              emoji: '💉',
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
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('오류: $e'),
      data: (records) {
        if (records.isEmpty) return _buildEmptyRecords();
        
        return Column(
          children: records.take(5).map((record) {
            return _buildRecordItem(
              context,
              emoji: '🏥',
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
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('오류: $e'),
      data: (records) {
        if (records.isEmpty) return _buildEmptyRecords();
        
        return Column(
          children: records.take(5).map((record) {
            final isActive = record.endDate == null || record.endDate!.isAfter(DateTime.now());
            return _buildRecordItem(
              context,
              emoji: '💊',
              title: record.medicationName,
              subtitle: '${record.dosage ?? ""} • ${record.intervalString}',
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.success.withOpacity(0.1) : AppColors.textHint.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isActive ? '복용 중' : '완료',
                  style: TextStyle(
                    fontSize: 10,
                    color: isActive ? AppColors.success : AppColors.textHint,
                  ),
                ),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MedicationScreen()),
                );
              },
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildEmptyRecords() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: const Center(
        child: Column(
          children: [
            Text('📝', style: TextStyle(fontSize: 40)),
            SizedBox(height: 12),
            Text(
              '아직 기록이 없습니다',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            SizedBox(height: 4),
            Text(
              '+ 버튼을 눌러 첫 기록을 추가해보세요',
              style: TextStyle(fontSize: 12, color: AppColors.textHint),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordItem(
    BuildContext context, {
    required String emoji,
    required String title,
    required String subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.health.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing,
            const Icon(Icons.chevron_right, color: AppColors.textHint),
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('산책은 산책 화면에서 시작해주세요')));
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
      case HealthCategory.teethCare:
      case HealthCategory.skinCare:
        AddSpecialRecordScreen.show(context, pet.id, pet.name);
        break;
    }
  }
}
