import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/feature_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/pet_constants.dart';
import '../../../../core/constants/location_constants.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/sheets/mingrr_bottom_sheet.dart';
import '../../../../core/widgets/navigation/appbar_actions.dart';
import '../../../../core/widgets/home_reminder_banner.dart';
import '../../../../core/providers/home_reminder_provider.dart';
import '../../../../models/pet_model.dart';
import '../../../../models/group_model.dart';
import '../../../pet/presentation/providers/pet_provider.dart';
import '../../../social/presentation/providers/group_provider.dart';
import '../../../../core/widgets/location_bubble_widget.dart';
import '../../../../core/providers/location_verification_provider.dart';
import '../../../../core/utils/responsive_utils.dart';

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
                  // 홈 리마인더 배너
                  _buildReminderBanners(context, ref),
                  
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
      elevation: AppSizes.elevationNone,
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
            style: AppTextStyles.displayMedium(context).withWeight(FontWeight.w700),
          ),
        ],
      ),
      actions: [
        AppBarActionButton.notification(),
        AppBarActionButton.profile(backgroundColor: theme.scaffoldBackgroundColor),
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
          Text(
            '등록된 반려동물이 없습니다',
            style: AppTextStyles.headlineSmall(context),
          ),
          const SizedBox(height: AppSizes.gapS),
          Text(
            '프로필에서 반려동물을 추가해보세요',
            style: AppTextStyles.bodySmall(context),
          ),
          const SizedBox(height: AppSizes.gapM),
          MingrrButton(
            text: '반려동물 추가하기',
            onPressed: () => context.push('/profile'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            textColor: Colors.white,
            height: 44,
            width: 160,
          ),
        ],
      ),
    );
  }

  /// 로딩 중 반려동물 카드
  Widget _buildLoadingPetsCard() {
    return MingrrCard(
      margin: EdgeInsets.zero,
      child: const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSizes.paddingL),
          child: MingrrLoadingIndicator.medium(type: MingrrLoadingType.primary),
        ),
      ),
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
              style: AppTextStyles.bodyLarge(context).withColor(colorScheme.onSurfaceVariant),
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
            Text(
              '내 반려동물',
              style: AppTextStyles.headlineSmall(context),
            ),
            Builder(
              builder: (context) => TextButton(
                onPressed: () => context.push('/profile'),
                child: Text('관리', style: AppTextStyles.bodySmall(context)),
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
                      const SizedBox(height: AppSizes.gapXS),
                      // 이름만 표시
                      Builder(
                        builder: (ctx) {
                          final cs = Theme.of(ctx).colorScheme;
                          return Text(
                            pet.name,
                            style: AppTextStyles.titleSmall(ctx)
                                .withWeight(isSelected ? FontWeight.w600 : FontWeight.w400)
                                .withColor(isSelected ? cs.primary : cs.onSurface),
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
              style: AppTextStyles.headlineSmall(context),
            ),
            Builder(
              builder: (ctx) => TextButton(
                onPressed: () => _showHealthCategorySettings(ctx, ref),
                child: Text('설정', style: AppTextStyles.bodySmall(ctx)),
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
              const MingrrDivider(),
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
                        style: AppTextStyles.titleMedium(ctx).withColor(cs.onSurfaceVariant),
                      ),
                      const SizedBox(width: AppSizes.gapXS),
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
    final availableCategories = HealthCategory.homeDisplayable;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final colorScheme = Theme.of(sheetContext).colorScheme;
        
        return Container(
          height: ResponsiveUtils.heightPercent(sheetContext, 0.6),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.bottomSheetRadius)),
          ),
          child: Column(
            children: [
              const BottomSheetHandle(),
              // 헤더
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL, vertical: 12),
                child: Text(
                  '메인화면 건강기록 설정',
                  style: AppTextStyles.headlineSmall(sheetContext),
                  textAlign: TextAlign.center,
                ),
              ),
              // 안내 문구
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL),
                child: Text(
                  '메인화면에 표시할 건강기록을 선택하세요 (최소 1개, 최대 5개)',
                  style: AppTextStyles.bodySmall(sheetContext),
                ),
              ),
              const SizedBox(height: AppSizes.gapL),
              // 카테고리 목록 (Consumer로 상태 변경 감지)
              Expanded(
                child: Consumer(
                  builder: (ctx, watchRef, _) {
                    final currentCategories = watchRef.watch(_homeHealthCategoriesProvider);
                    
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingS),
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
                              Icon(category.icon, size: 20, color: sheetContext.features.health),
                              const SizedBox(width: AppSizes.gapM),
                              Text(category.label),
                            ],
                          ),
                          subtitle: Text(
                            category.description,
                            style: AppTextStyles.caption(ctx),
                          ),
                          activeColor: sheetContext.features.health,
                        );
                      },
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
    final accentColor = features.health; // 건강수첩 색상으로 통일
    
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
            accentColor: accentColor,
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
                  accentColor,
                  accentColor.withValues(alpha: AppOpacity.o80),
                ],
              ),
              borderRadius: BorderRadius.circular(AppSizes.radiusL),
              boxShadow: AppShadows.shadowM(Theme.of(context).brightness == Brightness.dark),
            ),
            child: Row(
              children: [
                // 아이콘
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: AppOpacity.o20),
                    borderRadius: BorderRadius.circular(AppSizes.radiusM),
                  ),
                  child: const Center(
                    child: Icon(Icons.directions_walk, size: 32, color: Colors.white),
                  ),
                ),
                const SizedBox(width: AppSizes.gapM),
                // 텍스트
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '산책하러 가기',
                        style: AppTextStyles.headlineSmall(context).withWeight(FontWeight.w700).withColor(Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '반려동물과 함께 건강한 산책을!',
                        style: AppTextStyles.bodyMedium(context).withColor(Colors.white70),
                      ),
                    ],
                  ),
                ),
                // 화살표
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: AppOpacity.o20),
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
            color: color.withValues(alpha: AppOpacity.o15),
            borderRadius: BorderRadius.circular(AppSizes.radiusS),
          ),
          child: Icon(icon, size: 22, color: color),
        ),
        const SizedBox(height: AppSizes.gapS),
        Builder(
          builder: (ctx) {
            final cs = Theme.of(ctx).colorScheme;
            return Text(
              value,
              style: AppTextStyles.titleLarge(ctx).withWeight(FontWeight.w700),
            );
          },
        ),
        Builder(
          builder: (ctx) {
            final cs = Theme.of(ctx).colorScheme;
            return Text(
              label,
              style: AppTextStyles.captionSmall(ctx),
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

  /// 카테고리별 색상 (건강수첩과 동일하게 health 색상 통일)
  Color _getCategoryColor(BuildContext context, HealthCategory category) {
    return context.features.health;
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
                              style: AppTextStyles.titleMedium(context),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Builder(
                              builder: (ctx) => Text(
                                '${pet.breed ?? '품종 미상'} · ${_calculateAge(pet.birthDate)}',
                                style: AppTextStyles.caption(ctx),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: AppSizes.gapXS),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingS, vertical: AppSizes.paddingXXS),
                              decoration: BoxDecoration(
                                color: _getScoreColor(context, score).withValues(alpha: AppOpacity.o15),
                                borderRadius: BorderRadius.circular(AppSizes.radiusS),
                              ),
                              child: Text(
                                '궁합 $score%',
                                style: AppTextStyles.labelSmall(context).withWeight(FontWeight.w600).withColor(_getScoreColor(context, score)),
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

  /// 기본 반려동물 아이콘 (사각형 배경) - 공통 위젯 사용
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
            color: cs.primary.withValues(alpha: AppOpacity.o15),
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
              child: MingrrLoadingIndicator(),
            ),
          ),
          error: (_, __) => MingrrErrorState(
            onRetry: () => ref.invalidate(popularGroupsProvider),
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
              color: features.social.withValues(alpha: AppOpacity.o15),
              borderRadius: BorderRadius.circular(AppSizes.radiusM),
              image: group.imageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(group.imageUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: group.imageUrl == null
                ? Icon(Icons.groups, color: features.social, size: 26)
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
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: AppSizes.paddingXXS),
                      decoration: BoxDecoration(
                        color: features.social.withValues(alpha: AppOpacity.o10),
                        borderRadius: BorderRadius.circular(AppSizes.radiusXXS),
                      ),
                      child: Text(
                        group.category,
                        style: AppTextStyles.labelSmall(context).withWeight(FontWeight.w600).withColor(features.social),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.gapXS),
                Text(
                  group.name,
                  style: AppTextStyles.titleMedium(context),
                ),
                Row(
                  children: [
                    Icon(LocationConstants.distanceIcon, size: 12, color: colorScheme.outlineVariant),
                    const SizedBox(width: 2),
                    Text(
                      group.address ?? LocationConstants.noLocationText,
                      style: AppTextStyles.captionSmall(context),
                    ),
                    const SizedBox(width: AppSizes.gapS),
                    Icon(Icons.people, size: 12, color: colorScheme.outlineVariant),
                    const SizedBox(width: 2),
                    Text(
                      '${group.memberCount}명',
                      style: AppTextStyles.captionSmall(context),
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

  /// 홈 리마인더 배너 빌더 (스와이프 캐러셀)
  Widget _buildReminderBanners(BuildContext context, WidgetRef ref) {
    final banners = ref.watch(homeReminderBannersProvider);
    
    if (banners.isEmpty) return const SizedBox.shrink();
    
    // onTap 핸들러를 포함한 배너 데이터 생성
    final bannersWithHandlers = banners.map((banner) => HomeReminderBannerData(
      type: banner.type,
      count: banner.count,
      onTap: () => _handleBannerTap(context, banner.type),
    )).toList();
    
    return HomeReminderBannerCarousel(
      banners: bannersWithHandlers,
      maxVisible: 7,
    );
  }

  /// 배너 탭 핸들러
  void _handleBannerTap(BuildContext context, ReminderBannerType type) {
    switch (type) {
      case ReminderBannerType.rating:
        // TODO: 평가 대기 목록 화면으로 이동
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('평가 대기 목록 (구현 예정)')),
        );
        break;
      case ReminderBannerType.groupSchedule:
        context.push('/social');
        break;
      case ReminderBannerType.petLike:
        context.push('/profile/received-likes');
        break;
      case ReminderBannerType.receivedRating:
        context.push('/notifications');
        break;
      case ReminderBannerType.verification:
        context.push('/profile');
        break;
      case ReminderBannerType.groupJoinRequest:
        context.push('/social');
        break;
      case ReminderBannerType.healthRecord:
        context.push('/health');
        break;
    }
  }
}
