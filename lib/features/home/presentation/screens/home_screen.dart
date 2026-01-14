import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/feature_colors.dart';
import '../../../../core/constants/pet_constants.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/mingrr_bottom_sheet.dart';
import '../../../../core/widgets/profile_icon.dart';
import '../../../../models/pet_model.dart';
import '../../../../models/group_model.dart';
import '../../../pet/presentation/providers/pet_provider.dart';
import '../../../social/presentation/providers/group_provider.dart';
import '../../../../core/widgets/location_bubble_widget.dart';
import '../../../../core/providers/location_verification_provider.dart';

/// ============================================================
/// 홈 화면 (V3 리팩토링 - 반려동물 전용)
/// 
/// 변경사항:
/// - 반려동물 전용 앱으로 변경 (PetType 제거)
/// - 산책 기능 메인으로 이동 (건강기록 하위)
/// - 반려동물 선택기 (여러 마리 지원)
/// - 건강기록 커스터마이징 (1~5개 선택 가능)
/// - Firebase 데이터 연동
/// ============================================================

/// 메인화면 건강 카테고리 (사용자 설정)
final _homeHealthCategoriesProvider = StateProvider<List<HealthCategory>>((ref) => [
  HealthCategory.weight,
  HealthCategory.walk,
  HealthCategory.grooming,
]);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petsAsync = ref.watch(userPetsProvider);
    final selectedIndex = ref.watch(selectedPetIndexProvider);
    final healthCategories = ref.watch(_homeHealthCategoriesProvider);
    final otherPetsAsync = ref.watch(otherPetsProvider);

    // 로딩 중에도 기본 레이아웃 유지 (깜빡임 방지)
    final pets = petsAsync.valueOrNull ?? [];
    final isLoading = petsAsync.isLoading;
    final selectedPet = pets.isNotEmpty && selectedIndex < pets.length 
        ? pets[selectedIndex] 
        : null;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ===== 앱바 =====
            _buildAppBar(context),

            // ===== 컨텐츠 =====
            SliverPadding(
              padding: const EdgeInsets.all(AppSizes.paddingM),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // 반려동물 선택기 (여러 마리 지원)
                  if (pets.isNotEmpty)
                    _buildPetSelector(context, ref, pets, selectedIndex),
                  if (pets.isEmpty && !isLoading)
                    _buildEmptyPetsCard(context),
                  if (isLoading && pets.isEmpty)
                    _buildLoadingPetsCard(),
                  const SizedBox(height: AppSizes.gapL),
                  
                  // 오늘의 건강 기록 (커스터마이징 가능)
                  if (selectedPet != null)
                    _buildHealthSection(context, ref, selectedPet, healthCategories),
                  const SizedBox(height: AppSizes.gapXL),
                  
                  // 추천친구
                  MingrrSectionHeader(
                    title: '추천친구',
                    actionText: '더보기',
                    onActionTap: () => context.go('/dating'),
                  ),
                  const SizedBox(height: AppSizes.gapM),
                  otherPetsAsync.when(
                    data: (otherPets) => _buildAiRecommendSection(context, otherPets),
                    loading: () => _buildLoadingAiSection(),
                    error: (_, __) => const SizedBox(),
                  ),
                  const SizedBox(height: AppSizes.gapXL),
                  
                  // 인기 소모임
                  MingrrSectionHeader(
                    title: '인기 소모임',
                    actionText: '더보기',
                    onActionTap: () => context.push('/social'),
                  ),
                  const SizedBox(height: AppSizes.gapM),
                  _buildPopularGroupsSection(context),
                  
                  const SizedBox(height: AppSizes.gapXXL),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 앱바
  Widget _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final features = Theme.of(context).extension<FeatureColors>()!;
    
    return SliverAppBar(
      floating: true,
      elevation: 0,
      backgroundColor: theme.scaffoldBackgroundColor,
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: features.warmGradient,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.pets, size: 20, color: colorScheme.onSurface),
          ),
          const SizedBox(width: AppSizes.gapS),
          Text(
            AppStrings.appName,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
      actions: [
        // 알림 버튼
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () => context.push('/notifications'),
        ),
        // 프로필 버튼
        Padding(
          padding: const EdgeInsets.only(right: AppSizes.paddingM),
          child: GestureDetector(
            onTap: () => context.push('/profile'),
            child: ProfileButton(size: 36, backgroundColor: theme.scaffoldBackgroundColor),
          ),
        ),
      ],
    );
  }

  /// 반려동물이 없을 때 표시할 카드
  Widget _buildEmptyPetsCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return MingrrCard(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          Icon(Icons.pets, size: 48, color: colorScheme.outlineVariant),
          const SizedBox(height: AppSizes.gapM),
          const Text(
            '등록된 반려동물이 없습니다',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSizes.gapS),
          Text(
            '프로필에서 반려동물을 추가해보세요',
            style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSizes.gapM),
          ElevatedButton(
            onPressed: () => context.push('/profile'),
            child: const Text('반려동물 추가하기'),
          ),
        ],
      ),
    );
  }

  /// 로딩 중 반려동물 카드 (Skeleton UI)
  Widget _buildLoadingPetsCard() {
    return Builder(
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        
        return MingrrCard(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.outline,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: AppSizes.gapM),
              Container(
                width: 150,
                height: 16,
                decoration: BoxDecoration(
                  color: colorScheme.outline,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: AppSizes.gapS),
              Container(
                width: 200,
                height: 12,
                decoration: BoxDecoration(
                  color: colorScheme.outline,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 로딩 중 AI 추천 섹션 (Skeleton UI)
  Widget _buildLoadingAiSection() {
    return Builder(
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.paddingL),
            child: Text(
              '아직 등록된 반려동물이 없습니다',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        );
      },
    );
  }

  /// 반려동물 선택기 (여러 마리 지원)
  Widget _buildPetSelector(
    BuildContext context,
    WidgetRef ref,
    List<PetModel> pets,
    int selectedIndex,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 섹션 헤더
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '내 반려동물',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Builder(
              builder: (context) => TextButton(
                onPressed: () => context.push('/profile'),
                child: Text('관리', style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.gapS),
        
        // 반려동물 카드 목록 (가로 스크롤)
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: pets.length,
            itemBuilder: (context, index) {
              final pet = pets[index];
              final isSelected = index == selectedIndex;
              
              return GestureDetector(
                onTap: () {
                  ref.read(selectedPetIndexProvider.notifier).state = index;
                },
                child: Container(
                  width: 85,
                  margin: const EdgeInsets.only(right: AppSizes.gapM),
                  child: Column(
                    children: [
                      // 프로필 이미지 (프로필 이미지만 사용, 없으면 기본 아이콘)
                      Builder(
                        builder: (ctx) {
                          final cs = Theme.of(ctx).colorScheme;
                          return Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: cs.primaryContainer,
                              shape: BoxShape.circle,
                              border: isSelected 
                                  ? Border.all(color: cs.primary, width: 3)
                                  : null,
                              image: _getPetProfileImageOnly(pet),
                            ),
                            child: _getPetProfileImageOnly(pet) == null
                                ? Icon(
                                    Icons.pets,
                                    size: 28,
                                    color: cs.primary,
                                  )
                                : null,
                          );
                        },
                      ),
                      const SizedBox(height: 6),
                      // 이름만 표시
                      Builder(
                        builder: (ctx) {
                          final cs = Theme.of(ctx).colorScheme;
                          return Text(
                            pet.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              color: isSelected 
                                  ? cs.primary 
                                  : cs.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// 건강 기록 섹션 (커스터마이징 가능)
  Widget _buildHealthSection(
    BuildContext context,
    WidgetRef ref,
    PetModel selectedPet,
    List<HealthCategory> categories,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 섹션 헤더
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${selectedPet.name}의 건강 기록',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Builder(
              builder: (ctx) => TextButton(
                onPressed: () => _showHealthCategorySettings(ctx, ref),
                child: Text('설정', style: TextStyle(fontSize: 13, color: Theme.of(ctx).colorScheme.onSurfaceVariant)),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.gapM),
        
        // 산책 시작하기 카드 (위치 불일치 배너 포함)
        _buildWalkStartCardWithLocationBanner(context, ref),
        const SizedBox(height: AppSizes.gapM),
        
        // 건강 기록 카드
        MingrrCard(
          margin: EdgeInsets.zero,
          onTap: () => context.push('/health'),
          child: Column(
            children: [
              // 선택된 카테고리들 표시
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: categories.map((category) {
                  return _buildHealthItem(
                    icon: category.icon,
                    label: category.label,
                    value: _getDemoValue(category),
                    color: _getCategoryColor(context, category),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSizes.gapM),
              const Divider(),
              const SizedBox(height: AppSizes.gapS),
              
              // 건강수첩으로 이동 버튼
              Builder(
                builder: (ctx) {
                  final cs = Theme.of(ctx).colorScheme;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle_outline, size: 18, color: cs.onSurfaceVariant),
                      const SizedBox(width: AppSizes.gapS),
                      Text(
                        '건강수첩 열기',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right, size: 18, color: cs.onSurfaceVariant),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 건강 카테고리 설정 바텀시트
  void _showHealthCategorySettings(BuildContext context, WidgetRef ref) {
    final currentCategories = ref.read(_homeHealthCategoriesProvider);
    final availableCategories = HealthCategory.homeDisplayable;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.bottomSheetRadius)),
          ),
          child: Column(
            children: [
              const BottomSheetHandle(),
            // 헤더
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: const Text(
                '메인화면 건강기록 설정',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ),
            // 안내 문구
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '메인화면에 표시할 건강기록을 선택하세요 (최소 1개, 최대 5개)',
                style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: 12),
            // 카테고리 목록
            Expanded(
              child: ListView.builder(
                itemCount: availableCategories.length,
                itemBuilder: (context, index) {
                  final category = availableCategories[index];
                  final isSelected = currentCategories.contains(category);
                  
                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (value) {
                      final updated = List<HealthCategory>.from(currentCategories);
                      if (value == true) {
                        if (updated.length < 5) {
                          updated.add(category);
                        } else {
                          MingrrSnackBar.warning(context, '최대 5개까지 선택 가능합니다');
                          return;
                        }
                      } else {
                        if (updated.length > 1) {
                          updated.remove(category);
                        } else {
                          MingrrSnackBar.warning(context, '최소 1개는 선택해야 합니다');
                          return;
                        }
                      }
                      ref.read(_homeHealthCategoriesProvider.notifier).state = updated;
                    },
                    title: Row(
                      children: [
                        Icon(category.icon, size: 20, color: context.features.health),
                        const SizedBox(width: 12),
                        Text(category.label),
                      ],
                    ),
                    subtitle: Text(
                      category.description,
                      style: const TextStyle(fontSize: 12),
                    ),
                    activeColor: colorScheme.primary,
                  );
                },
              ),
            ),
          ],
        ),
        );
      },
    );
  }

  /// 산책 시작하기 카드 (위치 불일치 배너 포함)
  Widget _buildWalkStartCardWithLocationBanner(BuildContext context, WidgetRef ref) {
    final features = Theme.of(context).extension<FeatureColors>()!;
    
    // 위치 불일치 상태 감지
    final mismatchAsync = ref.watch(locationMismatchProvider);
    final shouldShowBubble = mismatchAsync.valueOrNull?.shouldShowBubble ?? false;
    final userAsync = ref.watch(currentUserStreamProvider);
    final user = userAsync.valueOrNull;
    
    return Column(
      children: [
        // 위치 불일치 배너 (산책 카드 위에 표시)
        if (shouldShowBubble)
          LocationMismatchBanner(
            savedAddress: user?.homeAddress,
            accentColor: features.walk,
            onUpdateLocation: () => _handleLocationUpdateFromHome(context, ref),
            onDismiss: () => _handleLocationDismissFromHome(ref),
          ),
        
        // 산책 카드
        GestureDetector(
          onTap: () => context.push('/walk'),
          child: Container(
            padding: const EdgeInsets.all(AppSizes.paddingM),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  features.walk,
                  features.walk.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(AppSizes.radiusL),
              boxShadow: [
                BoxShadow(
                  color: features.walk.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // 아이콘
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Icon(Icons.pets, size: 32, color: Colors.white),
                  ),
                ),
                const SizedBox(width: AppSizes.gapM),
                // 텍스트
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '산책하러 가기',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '반려동물과 함께 건강한 산책을!',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                // 화살표
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  /// 홈 화면에서 위치 업데이트 처리 - 공통 함수 사용
  Future<void> _handleLocationUpdateFromHome(BuildContext context, WidgetRef ref) async {
    final userAsync = ref.read(currentUserStreamProvider);
    final user = userAsync.valueOrNull;
    
    if (user == null) {
      MingrrSnackBar.error(context, '로그인이 필요합니다');
      return;
    }
    
    await LocationVerificationService.handleLocationUpdateWithUI(
      context: context,
      userId: user.id,
    );
  }
  
  /// 홈 화면에서 위치 알림 무시 처리
  Future<void> _handleLocationDismissFromHome(WidgetRef ref) async {
    final userAsync = ref.read(currentUserStreamProvider);
    final user = userAsync.valueOrNull;
    
    if (user == null) return;
    
    await LocationVerificationService.dismissReminder(user.id);
  }

  /// 건강 아이템 위젯
  Widget _buildHealthItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(height: AppSizes.gapS),
        Builder(
          builder: (ctx) {
            final cs = Theme.of(ctx).colorScheme;
            return Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            );
          },
        ),
        Builder(
          builder: (ctx) {
            final cs = Theme.of(ctx).colorScheme;
            return Text(
              label,
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
            );
          },
        ),
      ],
    );
  }

  /// 데모용 값 반환
  String _getDemoValue(HealthCategory category) {
    switch (category) {
      case HealthCategory.weight:
        return '5.2kg';
      case HealthCategory.walk:
        return '1회';
      case HealthCategory.grooming:
        return '3일 전';
      case HealthCategory.medication:
        return '1회';
      default:
        return '-';
    }
  }

  /// 카테고리별 색상
  Color _getCategoryColor(BuildContext context, HealthCategory category) {
    final features = context.features;
    switch (category) {
      case HealthCategory.weight:
        return features.health;
      case HealthCategory.walk:
        return features.walk;
      case HealthCategory.grooming:
        return features.health;
      case HealthCategory.medication:
        return features.community;
      default:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  /// 추천친구 섹션 (사각형 카드)
  Widget _buildAiRecommendSection(BuildContext context, List<PetModel> otherPets) {
    // 최대 4마리만 표시
    final displayPets = otherPets.take(4).toList();
    
    if (displayPets.isEmpty) {
      return Builder(
        builder: (ctx) => Center(
          child: Text(
            '아직 등록된 반려동물이 없습니다',
            style: TextStyle(color: Theme.of(ctx).colorScheme.onSurfaceVariant),
          ),
        ),
      );
    }

    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: displayPets.length,
        itemBuilder: (context, index) {
          final pet = displayPets[index];
          final score = 95 - (index * 5); // 임시 궁합 점수
          
          return GestureDetector(
            onTap: () => context.push('/dating/detail/${pet.id}'),
            child: Container(
              width: 140,
              margin: const EdgeInsets.only(right: AppSizes.gapM),
              child: MingrrCard(
                margin: EdgeInsets.zero,
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 사각형 이미지 영역
                    _buildPetSquareImage(pet, 110),
                    // 정보 영역
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSizes.paddingS),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              pet.name,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Builder(
                              builder: (ctx) => Text(
                                '${pet.breed ?? '품종 미상'} · ${_calculateAge(pet.birthDate)}',
                                style: TextStyle(fontSize: 10, color: Theme.of(ctx).colorScheme.onSurfaceVariant),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getScoreColor(context, score).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '궁합 $score%',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: _getScoreColor(context, score),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 반려동물 사각형 이미지 (추가사진 > 기본 아이콘)
  Widget _buildPetSquareImage(PetModel pet, double height) {
    final imageUrl = pet.displayImageUrl;
    
    return Builder(
      builder: (ctx) {
        final features = Theme.of(ctx).extension<FeatureColors>()!;
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSizes.radiusM)),
          child: Container(
            height: height,
            color: features.datingContainer,
            child: imageUrl != null
                ? Image.network(
                    imageUrl,
                    width: double.infinity,
                    height: height,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildDefaultPetIcon(height),
                  )
                : _buildDefaultPetIcon(height),
          ),
        );
      },
    );
  }

  /// 기본 강아지 아이콘 (사각형 배경) - 공통 위젯 사용
  Widget _buildDefaultPetIcon(double height) {
    return DefaultPetImage(
      height: height,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSizes.radiusM)),
    );
  }

  /// 반려동물 프로필 이미지 (원형, 내 반려동물 선택기용)
  Widget _buildPetProfileImage(PetModel pet, double size) {
    final imageUrl = pet.profileImageUrl ?? pet.displayImageUrl;
    
    return Builder(
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: cs.primary.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: imageUrl != null
              ? ClipOval(
                  child: Image.network(
                    imageUrl,
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.pets,
                      size: size * 0.5,
                      color: cs.primary,
                    ),
                  ),
                )
              : Icon(
                  Icons.pets,
                  size: size * 0.5,
                  color: cs.primary,
                ),
        );
      },
    );
  }

  Color _getScoreColor(BuildContext context, int score) {
    final features = context.features;
    if (score >= 90) return features.success;
    if (score >= 75) return features.dating;
    if (score >= 60) return features.warning;
    return Theme.of(context).colorScheme.outlineVariant;
  }

  String _calculateAge(DateTime? birthDate) {
    if (birthDate == null) return '나이 미상';
    
    final now = DateTime.now();
    final age = now.year - birthDate.year;
    final months = now.month - birthDate.month;
    
    if (age == 0) {
      return '${months}개월';
    } else if (months < 0) {
      return '${age - 1}살';
    }
    return '${age}살';
  }

  /// 인기 소모임 섹션 (Firebase 연동)
  Widget _buildPopularGroupsSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final groupsAsync = ref.watch(popularGroupsProvider);
        
        return groupsAsync.when(
          data: (groups) {
            if (groups.isEmpty) {
              return Builder(
                builder: (ctx) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.paddingL),
                    child: Text(
                      '아직 등록된 소모임이 없습니다',
                      style: TextStyle(color: Theme.of(ctx).colorScheme.onSurfaceVariant),
                    ),
                  ),
                ),
              );
            }
            return Column(
              children: groups.map((group) => _buildGroupCard(context, group)).toList(),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSizes.paddingL),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (_, __) => const Center(
            child: Text('데이터를 불러올 수 없습니다'),
          ),
        );
      },
    );
  }
  
  /// Firebase GroupModel을 사용한 소모임 카드
  Widget _buildGroupCard(BuildContext context, GroupModel group) {
    final colorScheme = Theme.of(context).colorScheme;
    final features = Theme.of(context).extension<FeatureColors>()!;
    
    return MingrrCard(
      margin: const EdgeInsets.only(bottom: AppSizes.gapM),
      onTap: () => context.push('/social/group/${group.id}'),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: features.community.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppSizes.radiusM),
              image: group.imageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(group.imageUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: group.imageUrl == null
                ? Icon(Icons.groups, color: features.community, size: 26)
                : null,
          ),
          const SizedBox(width: AppSizes.gapM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: features.community.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        group.category,
                        style: TextStyle(
                          fontSize: 10,
                          color: features.community,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  group.name,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 12, color: colorScheme.outlineVariant),
                    const SizedBox(width: 2),
                    Text(
                      group.address ?? '위치 미상',
                      style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.people, size: 12, color: colorScheme.outlineVariant),
                    const SizedBox(width: 2),
                    Text(
                      '${group.memberCount}명',
                      style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: colorScheme.outlineVariant),
        ],
      ),
    );
  }

  /// 반려동물 프로필 이미지만 가져오기 (대표사진 제외)
  DecorationImage? _getPetProfileImageOnly(PetModel pet) {
    // 프로필 이미지만 사용 (대표사진 제외)
    if (pet.profileImageUrl != null && pet.profileImageUrl!.isNotEmpty) {
      // 기본 아바타인 경우 null 반환
      if (pet.profileImageUrl!.startsWith('default_avatar:')) {
        return null;
      }
      return DecorationImage(
        image: NetworkImage(pet.profileImageUrl!),
        fit: BoxFit.cover,
      );
    }
    return null;
  }
}
