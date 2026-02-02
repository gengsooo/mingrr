import 'package:flutter/material.dart';
import '../../../../core/constants/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/feature_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/pet_constants.dart';
import '../../../../core/constants/location_constants.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/mingrr_image.dart';
import '../../../../core/widgets/sheets/mingrr_bottom_sheet.dart';
import '../../../../core/widgets/navigation/appbar_actions.dart';
import '../../../../core/widgets/home_reminder_banner.dart';
import '../../../../core/widgets/badges/svg_icons.dart';
import '../../../../core/widgets/badges/info_badge.dart';
import '../../../../core/providers/home_reminder_provider.dart';
import '../../../../models/pet_model.dart';
import '../../../../models/group_model.dart';
import '../../../pet/presentation/providers/pet_provider.dart';
import '../../../social/presentation/providers/group_provider.dart';
import '../../../dating/presentation/providers/dating_provider.dart';
import '../../../dating/presentation/screens/pet_detail_screen.dart';
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
    final recommendedPetsAsync = ref.watch(recommendedPetsProvider);

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
                  
                  // 위치 불일치 알림 (배너 아래)
                  _buildLocationMismatchBanner(context, ref),
                  
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
                  recommendedPetsAsync.when(
                    data: (recommendedPets) => _buildAiRecommendSection(context, recommendedPets),
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
          ClipOval(
            child: SvgPicture.asset(
              SvgAssets.mingrrLogo,
              width: 36,
              height: 36,
            ),
          ),
          const SizedBox(width: AppSizes.gapS),
          Text(
            AppStrings.appName,
            style: AppTextStyles.displaySmall(context),
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
          Icon(AppIcons.pet, size: 48, color: colorScheme.outlineVariant),
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
            width: 180,
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
        MingrrSectionHeader(
          title: '내 반려동물',
          actionText: '관리',
          onActionTap: () => context.push('/profile'),
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
                  width: 70,
                  margin: const EdgeInsets.only(right: AppSizes.gapS),
                  child: Column(
                    children: [
                      // 프로필 이미지 (프로필 이미지만 사용, 없으면 기본 아이콘)
                      Builder(
                        builder: (ctx) {
                          final cs = Theme.of(ctx).colorScheme;
                          return MingrrImage.petAvatar(
                            imageUrl: pet.profileImageUrl,
                            size: 60,
                            borderColor: isSelected ? cs.primary : null,
                            borderWidth: 3,
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
        MingrrSectionHeader(
          title: '${selectedPet.name}의 건강 기록',
          actionText: '설정',
          onActionTap: () => _showHealthCategorySettings(context, ref),
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
                      Icon(AppIcons.addCircle, size: 18, color: cs.onSurfaceVariant),
                      const SizedBox(width: AppSizes.gapS),
                      Text(
                        '건강수첩 열기',
                        style: AppTextStyles.titleMedium(ctx).withColor(cs.onSurfaceVariant),
                      ),
                      const SizedBox(width: AppSizes.gapXS),
                      Icon(AppIcons.chevronRight, size: 18, color: cs.onSurfaceVariant),
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

  /// 산책 시작하기 카드
  Widget _buildWalkStartCardWithLocationBanner(BuildContext context, WidgetRef ref) {
    final features = Theme.of(context).extension<FeatureColors>()!;
    final accentColor = features.health; // 건강수첩 색상으로 통일
    
    // 산책 카드
    return GestureDetector(
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
                    child: Icon(AppIcons.walk, size: 32, color: Colors.white),
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
                  child: Icon(
                    AppIcons.arrowForward,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
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

  /// 추천친구 섹션 (사각형 카드) - 실제 궁합 점수 사용
  Widget _buildAiRecommendSection(BuildContext context, List<RecommendedPet> recommendedPets) {
    // 최대 4마리만 표시
    final displayPets = recommendedPets.take(4).toList();
    
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
          final recommended = displayPets[index];
          final pet = recommended.pet;
          final score = recommended.matchScore; // 실제 궁합 점수 사용
          
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PetDetailScreen(
                  petId: pet.id,
                  cachedDistanceMeters: recommended.distanceMeters,
                  cachedMatchScore: recommended.matchScore,
                ),
              ),
            ),
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
                            MatchScoreBadge(
                              score: score,
                              style: MatchBadgeStyle.transparent,
                              size: InfoBadgeSize.small,
                              showIcon: false,
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
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSizes.radiusM)),
      child: MingrrImage.background(
        imageUrl: pet.displayImageUrl,
        height: height,
        placeholder: _buildDefaultPetIcon(height),
      ),
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
    return MingrrImage.petAvatar(
      imageUrl: pet.profileImageUrl ?? pet.displayImageUrl,
      size: size,
    );
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
          MingrrImage.thumbnail(
            imageUrl: group.imageUrl,
            width: 50,
            height: 50,
            radius: AppSizes.radiusM,
            errorWidget: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: features.social.withValues(alpha: AppOpacity.o15),
                borderRadius: BorderRadius.circular(AppSizes.radiusM),
              ),
              child: Icon(AppIcons.group, color: features.social, size: 26),
            ),
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
                    Icon(AppIcons.people, size: 12, color: colorScheme.outlineVariant),
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
          Icon(AppIcons.chevronRight, color: colorScheme.outlineVariant),
        ],
      ),
    );
  }


  /// 위치 불일치 알림 배너 (홈 배너 아래)
  Widget _buildLocationMismatchBanner(BuildContext context, WidgetRef ref) {
    final mismatchAsync = ref.watch(locationMismatchProvider);
    final shouldShowBubble = mismatchAsync.valueOrNull?.shouldShowBubble ?? false;
    final userAsync = ref.watch(currentUserStreamProvider);
    final user = userAsync.valueOrNull;
    
    if (!shouldShowBubble) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.gapM),
      child: LocationMismatchBanner(
        savedAddress: user?.homeAddress,
        onUpdateLocation: () => _handleLocationUpdateFromHome(context, ref),
        onDismiss: () => _handleLocationDismissFromHome(ref),
      ),
    );
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
        context.push('/profile/pending-ratings');
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
