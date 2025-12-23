import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/pet_constants.dart';
import '../../../../core/widgets/common_widgets.dart';

/// ============================================================
/// 홈 화면 (V3 리팩토링 - 강아지 전용)
/// 
/// 변경사항:
/// - 강아지 전용 앱으로 변경 (PetType 제거)
/// - 산책 기능 메인으로 이동 (건강기록 하위)
/// - 강아지 선택기 (여러 마리 지원)
/// - 건강기록 커스터마이징 (1~5개 선택 가능)
/// ============================================================

// ===== 데모용 Provider =====
/// 현재 선택된 강아지 인덱스
final _selectedDogIndexProvider = StateProvider<int>((ref) => 0);

/// 데모용 강아지 목록
final _demoDogsProvider = Provider<List<_DemoDog>>((ref) => [
  _DemoDog(id: '1', name: '뽀삐', breed: '골든 리트리버', isPrimary: true),
  _DemoDog(id: '2', name: '코코', breed: '푸들', isPrimary: false),
]);

/// 데모용 메인화면 건강 카테고리 (사용자 설정)
final _homeHealthCategoriesProvider = StateProvider<List<HealthCategory>>((ref) => [
  HealthCategory.weight,
  HealthCategory.walk,
  HealthCategory.play,
]);

/// 데모용 강아지 클래스
class _DemoDog {
  final String id;
  final String name;
  final String breed;
  final bool isPrimary;
  
  const _DemoDog({
    required this.id,
    required this.name,
    required this.breed,
    required this.isPrimary,
  });
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dogs = ref.watch(_demoDogsProvider);
    final selectedIndex = ref.watch(_selectedDogIndexProvider);
    final selectedDog = dogs[selectedIndex];
    final healthCategories = ref.watch(_homeHealthCategoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
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
                  // 강아지 선택기 (여러 마리 지원)
                  _buildDogSelector(context, ref, dogs, selectedIndex),
                  const SizedBox(height: AppSizes.gapL),
                  
                  // 오늘의 건강 기록 (커스터마이징 가능)
                  _buildHealthSection(context, ref, selectedDog, healthCategories),
                  const SizedBox(height: AppSizes.gapXL),
                  
                  // AI 추천 친구
                  const MingrrSectionHeader(
                    title: 'AI 추천 친구',
                    actionText: '더보기',
                  ),
                  const SizedBox(height: AppSizes.gapM),
                  _buildAiRecommendSection(context),
                  const SizedBox(height: AppSizes.gapXL),
                  
                  // 인기 소모임
                  const MingrrSectionHeader(
                    title: '인기 소모임',
                    actionText: '더보기',
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
    return SliverAppBar(
      floating: true,
      backgroundColor: AppColors.background,
      elevation: 0,
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              gradient: AppColors.warmGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.pets, size: 20, color: AppColors.textPrimary),
          ),
          const SizedBox(width: AppSizes.gapS),
          const Text(
            AppStrings.appName,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
      actions: [
        // 알림 버튼
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {
            // TODO: 알림 화면으로 이동
          },
        ),
        // 프로필 버튼
        GestureDetector(
          onTap: () => context.push('/profile'),
          child: Container(
            margin: const EdgeInsets.only(right: AppSizes.paddingM),
            child: const MingrrAvatar(size: 36, placeholderIcon: Icons.person),
          ),
        ),
      ],
    );
  }

  /// 강아지 선택기 (여러 마리 지원)
  Widget _buildDogSelector(
    BuildContext context,
    WidgetRef ref,
    List<_DemoDog> dogs,
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
              '내 강아지',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            TextButton(
              onPressed: () => context.push('/profile'),
              child: const Text('관리', style: TextStyle(fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.gapS),
        
        // 강아지 카드 목록 (가로 스크롤)
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: dogs.length,
            itemBuilder: (context, index) {
              final dog = dogs[index];
              final isSelected = index == selectedIndex;
              
              return GestureDetector(
                onTap: () {
                  ref.read(_selectedDogIndexProvider.notifier).state = index;
                },
                child: Container(
                  width: 85,
                  margin: const EdgeInsets.only(right: AppSizes.gapM),
                  child: Column(
                    children: [
                      // 프로필 이미지
                      Stack(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? AppColors.primary 
                                  : AppColors.primaryLight,
                              shape: BoxShape.circle,
                              border: isSelected 
                                  ? Border.all(color: AppColors.primary, width: 3)
                                  : null,
                            ),
                            child: const Center(
                              child: Text(
                                '🐶',
                                style: TextStyle(fontSize: 28),
                              ),
                            ),
                          ),
                          // 대표 강아지 표시
                          if (dog.isPrimary)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: AppColors.warning,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.star,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // 이름
                      Text(
                        dog.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected 
                              ? AppColors.primary 
                              : AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // 품종
                      Text(
                        dog.breed,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
    _DemoDog selectedDog,
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
              '${selectedDog.name}의 건강 기록',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            TextButton(
              onPressed: () => _showHealthCategorySettings(context, ref),
              child: const Text('설정', style: TextStyle(fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.gapM),
        
        // 산책 시작하기 카드
        _buildWalkStartCard(context),
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
                    emoji: category.emoji,
                    label: category.label,
                    value: _getDemoValue(category),
                    color: _getCategoryColor(category),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSizes.gapM),
              const Divider(),
              const SizedBox(height: AppSizes.gapS),
              
              // 건강수첩으로 이동 버튼
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle_outline, size: 18, color: AppColors.primary),
                  SizedBox(width: AppSizes.gapS),
                  Text(
                    '건강수첩 열기',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.chevron_right, size: 18, color: AppColors.primary),
                ],
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
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // 핸들
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // 헤더
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      '메인화면 건강기록 설정',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('완료'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // 안내 문구
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '메인화면에 표시할 건강기록을 선택하세요 (최소 1개, 최대 5개)',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ),
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
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('최대 5개까지 선택 가능합니다')),
                          );
                          return;
                        }
                      } else {
                        if (updated.length > 1) {
                          updated.remove(category);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('최소 1개는 선택해야 합니다')),
                          );
                          return;
                        }
                      }
                      ref.read(_homeHealthCategoriesProvider.notifier).state = updated;
                    },
                    title: Row(
                      children: [
                        Text(category.emoji, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 12),
                        Text(category.label),
                      ],
                    ),
                    subtitle: Text(
                      category.description,
                      style: const TextStyle(fontSize: 12),
                    ),
                    activeColor: AppColors.primary,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 산책 시작하기 카드
  Widget _buildWalkStartCard(BuildContext context) {
    return MingrrCard(
      margin: EdgeInsets.zero,
      child: Row(
        children: [
          // 아이콘
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.walk.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(Icons.directions_walk, size: 28, color: AppColors.walk),
            ),
          ),
          const SizedBox(width: AppSizes.gapM),
          // 텍스트
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '산책 시작하기',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '산책을 시작하면 경로와 시간이 기록돼요',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // 토글 스위치
          GestureDetector(
            onTap: () => context.push('/walk'),
            child: Container(
              width: 52,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 3,
                    top: 3,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 건강 아이템 위젯
  Widget _buildHealthItem({
    required String emoji,
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
          child: Center(child: Text(emoji, style: const TextStyle(fontSize: 20))),
        ),
        const SizedBox(height: AppSizes.gapS),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
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
      case HealthCategory.play:
        return '15분';
      case HealthCategory.medication:
        return '1회';
      default:
        return '-';
    }
  }

  /// 카테고리별 색상
  Color _getCategoryColor(HealthCategory category) {
    switch (category) {
      case HealthCategory.weight:
        return AppColors.health;
      case HealthCategory.walk:
        return AppColors.walk;
      case HealthCategory.play:
        return AppColors.dating;
      case HealthCategory.medication:
        return AppColors.community;
      default:
        return AppColors.textSecondary;
    }
  }

  /// AI 추천 친구 섹션
  Widget _buildAiRecommendSection(BuildContext context) {
    final demoData = [
      {'name': '뽀삐', 'breed': '골든 리트리버', 'age': '2살', 'score': 95},
      {'name': '코코', 'breed': '푸들', 'age': '3살', 'score': 88},
      {'name': '몽실', 'breed': '말티즈', 'age': '1살', 'score': 82},
      {'name': '초롱', 'breed': '비숑', 'age': '4살', 'score': 78},
    ];

    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: demoData.length,
        itemBuilder: (context, index) {
          final pet = demoData[index];
          final score = pet['score'] as int;
          
          return GestureDetector(
            onTap: () {
              // TODO: 상세 프로필로 이동
            },
            child: Container(
              width: 140,
              margin: const EdgeInsets.only(right: AppSizes.gapM),
              child: MingrrCard(
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.all(AppSizes.paddingM),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      children: [
                        const MingrrAvatar(size: 60),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.verified, size: 14, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.gapS),
                    Text(
                      pet['name'] as String,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${pet['breed']} · ${pet['age']}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppSizes.gapS),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getScoreColor(score).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '궁합 $score%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _getScoreColor(score),
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

  Color _getScoreColor(int score) {
    if (score >= 90) return AppColors.success;
    if (score >= 75) return AppColors.dating;
    if (score >= 60) return AppColors.warning;
    return AppColors.textHint;
  }

  /// 인기 소모임 섹션
  Widget _buildPopularGroupsSection(BuildContext context) {
    final groups = [
      {'name': '한강 산책 모임', 'members': 28, 'category': '산책', 'district': '영등포구 여의동'},
      {'name': '강남 댕댕이 모임', 'members': 45, 'category': '친목', 'district': '강남구 역삼동'},
      {'name': '수제 간식 나눔', 'members': 32, 'category': '나눔', 'district': '마포구 상암동'},
    ];

    return Column(
      children: groups.map((group) {
        return MingrrCard(
          margin: const EdgeInsets.only(bottom: AppSizes.gapM),
          onTap: () {
            // TODO: 소모임 상세로 이동
          },
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.community.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppSizes.radiusM),
                ),
                child: const Icon(Icons.groups, color: AppColors.community, size: 26),
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
                            color: AppColors.community.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            group['category'] as String,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.community,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      group['name'] as String,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 12, color: AppColors.textHint),
                        const SizedBox(width: 2),
                        Text(
                          group['district'] as String,
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.people, size: 12, color: AppColors.textHint),
                        const SizedBox(width: 2),
                        Text(
                          '${group['members']}명',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textHint),
            ],
          ),
        );
      }).toList(),
    );
  }
}
