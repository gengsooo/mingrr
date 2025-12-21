import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// ============================================================
/// 홈 화면
/// 앱의 메인 대시보드 - 주요 기능 바로가기 및 알림 표시
/// ============================================================
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ===== 앱바 =====
            SliverAppBar(
              floating: true,
              backgroundColor: AppColors.background,
              elevation: 0,
              title: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: AppColors.warmGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.pets,
                      size: 20,
                      color: AppColors.textPrimary,
                    ),
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
                // 설정 버튼
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () {
                    // TODO: 설정 화면으로 이동
                  },
                ),
              ],
            ),

            // ===== 컨텐츠 =====
            SliverPadding(
              padding: const EdgeInsets.all(AppSizes.paddingM),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // 환영 메시지
                  currentUser.when(
                    data: (user) => _buildWelcomeCard(user?.nickname ?? '친구'),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  
                  const SizedBox(height: AppSizes.gapXL),
                  
                  // 산책 중 상태 토글
                  _buildWalkingStatusCard(context),
                  
                  const SizedBox(height: AppSizes.gapXL),
                  
                  // 주요 기능 그리드
                  const MingrrSectionHeader(title: '주요 기능'),
                  const SizedBox(height: AppSizes.gapM),
                  _buildMainFeaturesGrid(context),
                  
                  const SizedBox(height: AppSizes.gapXL),
                  
                  // 근처 산책 중인 친구들
                  const MingrrSectionHeader(
                    title: '근처 산책 중인 친구들',
                    actionText: '더보기',
                  ),
                  const SizedBox(height: AppSizes.gapM),
                  _buildNearbyWalkersSection(),
                  
                  const SizedBox(height: AppSizes.gapXL),
                  
                  // AI 추천 친구
                  const MingrrSectionHeader(
                    title: 'AI 추천 친구',
                    actionText: '더보기',
                  ),
                  const SizedBox(height: AppSizes.gapM),
                  _buildAiRecommendSection(),
                  
                  const SizedBox(height: AppSizes.gapXL),
                  
                  // 오늘의 건강 체크
                  const MingrrSectionHeader(title: '오늘의 건강 체크'),
                  const SizedBox(height: AppSizes.gapM),
                  _buildHealthCheckCard(),
                  
                  const SizedBox(height: AppSizes.gapXXL),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 환영 메시지 카드
  Widget _buildWelcomeCard(String nickname) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingL),
      decoration: BoxDecoration(
        gradient: AppColors.warmGradient,
        borderRadius: BorderRadius.circular(AppSizes.radiusXL),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '안녕하세요, $nickname님! 👋',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSizes.gapS),
                const Text(
                  '오늘도 반려동물과 즐거운 하루 보내세요!',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.pets,
              size: 32,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  /// 산책 중 상태 토글 카드
  Widget _buildWalkingStatusCard(BuildContext context) {
    return MingrrCard(
      margin: EdgeInsets.zero,
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.walk.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppSizes.radiusM),
            ),
            child: const Icon(
              Icons.directions_walk,
              color: AppColors.walk,
              size: 28,
            ),
          ),
          const SizedBox(width: AppSizes.gapM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  '산책 중 상태',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '켜면 근처 친구들에게 알림이 갑니다',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: false, // TODO: 실제 상태 연동
            onChanged: (value) {
              // TODO: 산책 상태 토글
            },
            activeColor: AppColors.walk,
          ),
        ],
      ),
    );
  }

  /// 주요 기능 그리드
  Widget _buildMainFeaturesGrid(BuildContext context) {
    final features = [
      _FeatureItem(
        icon: Icons.favorite,
        label: '데이팅',
        color: AppColors.dating,
        onTap: () {
          // 바텀 네비게이션에서 처리
        },
      ),
      _FeatureItem(
        icon: Icons.directions_walk,
        label: '산책',
        color: AppColors.walk,
        onTap: () {},
      ),
      _FeatureItem(
        icon: Icons.store,
        label: '마켓',
        color: AppColors.market,
        onTap: () {},
      ),
      _FeatureItem(
        icon: Icons.medical_services,
        label: '건강수첩',
        color: AppColors.health,
        onTap: () {},
      ),
      _FeatureItem(
        icon: Icons.pets,
        label: '교배',
        color: AppColors.breeding,
        onTap: () {},
      ),
      _FeatureItem(
        icon: Icons.groups,
        label: '소모임',
        color: AppColors.community,
        onTap: () {},
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppSizes.gapM,
        mainAxisSpacing: AppSizes.gapM,
        childAspectRatio: 1,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final feature = features[index];
        return _buildFeatureCard(feature);
      },
    );
  }

  /// 기능 카드 위젯
  Widget _buildFeatureCard(_FeatureItem feature) {
    return MingrrCard(
      margin: EdgeInsets.zero,
      onTap: feature.onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: feature.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppSizes.radiusM),
            ),
            child: Icon(
              feature.icon,
              color: feature.color,
              size: 26,
            ),
          ),
          const SizedBox(height: AppSizes.gapS),
          Text(
            feature.label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  /// 근처 산책 중인 친구들 섹션
  Widget _buildNearbyWalkersSection() {
    // 데모 데이터
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        itemBuilder: (context, index) {
          return Container(
            width: 90,
            margin: EdgeInsets.only(
              right: AppSizes.gapM,
              left: index == 0 ? 0 : 0,
            ),
            child: Column(
              children: [
                Stack(
                  children: [
                    const MingrrAvatar(
                      size: 70,
                      isOnline: true,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.walk,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          '산책중',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.gapS),
                Text(
                  '멍멍이 ${index + 1}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${(index + 1) * 100}m',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// AI 추천 친구 섹션
  Widget _buildAiRecommendSection() {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        itemBuilder: (context, index) {
          return Container(
            width: 140,
            margin: EdgeInsets.only(
              right: AppSizes.gapM,
            ),
            child: MingrrCard(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.all(AppSizes.paddingM),
              child: Column(
                children: [
                  const MingrrAvatar(size: 60),
                  const SizedBox(height: AppSizes.gapS),
                  Text(
                    '귀요미 ${index + 1}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    '골든 리트리버 · 2살',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSizes.gapS),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.dating.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '궁합 ${85 + index * 3}%',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.dating,
                      ),
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

  /// 오늘의 건강 체크 카드
  Widget _buildHealthCheckCard() {
    return MingrrCard(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          Row(
            children: [
              _buildHealthItem(
                icon: Icons.monitor_weight,
                label: '체중',
                value: '5.2kg',
                color: AppColors.health,
              ),
              _buildHealthItem(
                icon: Icons.directions_walk,
                label: '산책',
                value: '0회',
                color: AppColors.walk,
              ),
              _buildHealthItem(
                icon: Icons.water_drop,
                label: '배변',
                value: '0회',
                color: AppColors.market,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.gapM),
          const Divider(),
          const SizedBox(height: AppSizes.gapS),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(
                Icons.add_circle_outline,
                size: 18,
                color: AppColors.primary,
              ),
              SizedBox(width: AppSizes.gapS),
              Text(
                '오늘의 기록 추가하기',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 건강 아이템 위젯
  Widget _buildHealthItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: AppSizes.gapS),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// 기능 아이템 데이터 클래스
class _FeatureItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  _FeatureItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}
