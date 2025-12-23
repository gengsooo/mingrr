import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/top_navigation.dart';

/// ============================================================
/// 데이팅 화면
/// 
/// 디자인:
/// - 2개 탭 (AI추천 / 근처 검색) - pill 형태
/// - 위치/거리 필터 바 (근처 검색 탭에서만)
/// - 틴더 스타일 카드 스와이프
/// ============================================================

/// 선택된 탭 (0: AI추천, 1: 근처 검색)
final _selectedTabProvider = StateProvider<int>((ref) => 0);

/// 거리 필터 (근처 검색용)
final _distanceFilterProvider = StateProvider<double>((ref) => 3.0);

class DatingScreen extends ConsumerWidget {
  const DatingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTab = ref.watch(_selectedTabProvider);
    final distanceFilter = ref.watch(_distanceFilterProvider);

    // 탭 정의 (AI추천 / 근처 검색)
    final tabs = [
      TopNavTab(label: 'AI추천', icon: Icons.auto_awesome, color: AppColors.dating),
      TopNavTab(label: '근처 검색', icon: Icons.location_on, color: AppColors.dating),
    ];

    return Scaffold(
      backgroundColor: AppColors.datingLight,
      appBar: AppBar(
        title: const Text('데이팅'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 2개 탭 (AI추천 / 근처 검색)
          Container(
            color: Colors.white,
            child: PillTabBar(
              tabs: tabs,
              selectedIndex: selectedTab,
              onTabSelected: (index) {
                ref.read(_selectedTabProvider.notifier).state = index;
              },
            ),
          ),
          
          // 위치/거리 필터 바 (근처 검색 탭에서만 표시)
          if (selectedTab == 1)
            LocationDistanceBar(
              accentColor: AppColors.dating,
              currentDistance: distanceFilter,
              onDistanceChanged: (distance) {
                ref.read(_distanceFilterProvider.notifier).state = distance;
              },
            ),
          
          // 카드 스와이프 영역
          Expanded(
            child: selectedTab == 0
                ? _buildSwipeCards(context)  // AI추천: 스와이프 카드
                : _buildNearbyGrid(context, distanceFilter),  // 근처 검색: 그리드
          ),
          
          // 하단 액션 버튼 (AI추천 탭에서만)
          if (selectedTab == 0) _buildActionButtons(context),
          
          const SizedBox(height: AppSizes.gapL),
        ],
      ),
    );
  }

  /// 근처 검색 그리드 뷰
  Widget _buildNearbyGrid(BuildContext context, double distanceFilter) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSizes.paddingM),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSizes.gapM,
        mainAxisSpacing: AppSizes.gapM,
        childAspectRatio: 0.75,
      ),
      itemCount: 10,
      itemBuilder: (context, index) {
        return _buildNearbyCard(context, index);
      },
    );
  }

  /// 근처 검색 카드
  Widget _buildNearbyCard(BuildContext context, int index) {
    final distance = (index + 1) * 0.5;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 이미지 영역
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.datingLight,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSizes.radiusL),
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const Center(
                    child: Icon(Icons.pets, size: 50, color: AppColors.dating),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${distance}km',
                        style: const TextStyle(fontSize: 10, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 정보 영역
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.paddingS),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '멍멍이 ${index + 1}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    '푸들 · 3살',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.dating.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '궁합 ${80 + index * 2}%',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.dating,
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

  /// 스와이프 카드 영역
  Widget _buildSwipeCards(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 뒤쪽 카드 (미리보기)
        Positioned(
          top: 20,
          child: Transform.scale(
            scale: 0.9,
            child: _buildDatingCard(context, 1, isBackground: true),
          ),
        ),
        
        // 앞쪽 카드 (스와이프 가능)
        Dismissible(
          key: const Key('card_0'),
          direction: DismissDirection.horizontal,
          onDismissed: (direction) {
            // 스와이프 처리
          },
          background: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 40),
            child: const Icon(Icons.close, color: AppColors.error, size: 50),
          ),
          secondaryBackground: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 40),
            child: const Icon(Icons.favorite, color: AppColors.dating, size: 50),
          ),
          child: _buildDatingCard(context, 0),
        ),
      ],
    );
  }

  /// 데이팅 카드
  Widget _buildDatingCard(BuildContext context, int index, {bool isBackground = false}) {
    return Container(
      width: MediaQuery.of(context).size.width - 40,
      height: MediaQuery.of(context).size.height * 0.50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusXL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isBackground ? 0.05 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.radiusXL),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 배경 이미지 (플레이스홀더)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryLight,
                    AppColors.primary.withOpacity(0.3),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: const Center(
                child: Icon(Icons.pets, size: 100, color: AppColors.primary),
              ),
            ),
            
            // 그라데이션 오버레이
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 180,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            
            // 정보 영역
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.paddingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 이름과 나이
                    Row(
                      children: [
                        Text(
                          '뽀삐 ${index + 1}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: AppSizes.gapS),
                        const Text(
                          '2살',
                          style: TextStyle(fontSize: 18, color: Colors.white70),
                        ),
                        const Spacer(),
                        // 인증 배지
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified, size: 14, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                '인증됨',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    
                    // 품종
                    const Text(
                      '골든 리트리버 · 수컷',
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                    const SizedBox(height: 4),
                    
                    // 거리
                    const Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: Colors.white70),
                        SizedBox(width: 4),
                        Text(
                          '1.2km 거리',
                          style: TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.gapM),
                    
                    // 성격 태그
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _buildPersonalityTag('활발한'),
                        _buildPersonalityTag('친화적인'),
                        _buildPersonalityTag('장난스러운'),
                      ],
                    ),
                    const SizedBox(height: AppSizes.gapM),
                    
                    // AI 궁합 점수
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.dating.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome, size: 16, color: Colors.white),
                          SizedBox(width: 6),
                          Text(
                            'AI 궁합 92%',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 성격 태그
  Widget _buildPersonalityTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, color: Colors.white),
      ),
    );
  }

  /// 하단 액션 버튼
  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingXL),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 패스 버튼
          _buildActionButton(
            icon: Icons.close,
            color: AppColors.error,
            size: 60,
            onTap: () {},
          ),
          // 좋아요 버튼
          _buildActionButton(
            icon: Icons.favorite,
            color: AppColors.dating,
            size: 60,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  /// 액션 버튼
  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required double size,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: size * 0.5),
      ),
    );
  }
}
