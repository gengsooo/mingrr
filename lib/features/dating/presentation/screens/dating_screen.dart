import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/common_widgets.dart';

/// ============================================================
/// 데이팅 화면
/// AI 추천 및 위치 기반 반려동물 매칭
/// 틴더 스타일의 카드 스와이프 UI
/// ============================================================
class DatingScreen extends ConsumerStatefulWidget {
  const DatingScreen({super.key});

  @override
  ConsumerState<DatingScreen> createState() => _DatingScreenState();
}

class _DatingScreenState extends ConsumerState<DatingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('데이팅'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'AI 추천'),
            Tab(text: '근처 친구'),
          ],
          indicatorColor: AppColors.dating,
          labelColor: AppColors.dating,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAiRecommendTab(),
          _buildNearbyTab(),
        ],
      ),
    );
  }

  /// AI 추천 탭
  Widget _buildAiRecommendTab() {
    return Column(
      children: [
        // 상단 필터 영역
        _buildFilterBar(),
        
        // 카드 스와이프 영역
        Expanded(
          child: _buildSwipeCards(),
        ),
        
        // 하단 액션 버튼
        _buildActionButtons(),
        
        const SizedBox(height: AppSizes.gapL),
      ],
    );
  }

  /// 근처 친구 탭
  Widget _buildNearbyTab() {
    return Column(
      children: [
        // 거리 필터
        Padding(
          padding: const EdgeInsets.all(AppSizes.paddingM),
          child: Row(
            children: [
              const Icon(Icons.location_on, color: AppColors.dating, size: 20),
              const SizedBox(width: AppSizes.gapS),
              const Text(
                '반경 5km 이내',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  // TODO: 거리 설정 바텀시트
                },
                child: const Text('변경'),
              ),
            ],
          ),
        ),
        
        // 그리드 뷰
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(AppSizes.paddingM),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppSizes.gapM,
              mainAxisSpacing: AppSizes.gapM,
              childAspectRatio: 0.75,
            ),
            itemCount: 10,
            itemBuilder: (context, index) {
              return _buildPetCard(index);
            },
          ),
        ),
      ],
    );
  }

  /// 필터 바
  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingM,
        vertical: AppSizes.paddingS,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('전체', true),
            _buildFilterChip('강아지', false),
            _buildFilterChip('고양이', false),
            _buildFilterChip('소형견', false),
            _buildFilterChip('중형견', false),
            _buildFilterChip('대형견', false),
          ],
        ),
      ),
    );
  }

  /// 필터 칩
  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: AppSizes.gapS),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (value) {
          // TODO: 필터 적용
        },
        selectedColor: AppColors.dating.withOpacity(0.2),
        checkmarkColor: AppColors.dating,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.dating : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }

  /// 스와이프 카드 영역
  Widget _buildSwipeCards() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 뒤쪽 카드 (미리보기)
        Positioned(
          top: 20,
          child: Transform.scale(
            scale: 0.9,
            child: _buildDatingCard(1, isBackground: true),
          ),
        ),
        
        // 앞쪽 카드 (스와이프 가능)
        Dismissible(
          key: const Key('card_0'),
          direction: DismissDirection.horizontal,
          onDismissed: (direction) {
            if (direction == DismissDirection.endToStart) {
              // 왼쪽 스와이프 - 패스
            } else {
              // 오른쪽 스와이프 - 좋아요
            }
          },
          background: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 40),
            child: const Icon(
              Icons.close,
              color: AppColors.error,
              size: 50,
            ),
          ),
          secondaryBackground: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 40),
            child: const Icon(
              Icons.favorite,
              color: AppColors.dating,
              size: 50,
            ),
          ),
          child: _buildDatingCard(0),
        ),
      ],
    );
  }

  /// 데이팅 카드
  Widget _buildDatingCard(int index, {bool isBackground = false}) {
    return Container(
      width: MediaQuery.of(context).size.width - 40,
      height: MediaQuery.of(context).size.height * 0.55,
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
                child: Icon(
                  Icons.pets,
                  size: 100,
                  color: AppColors.primary,
                ),
              ),
            ),
            
            // 그라데이션 오버레이
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 200,
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
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: AppSizes.gapS),
                        const Text(
                          '2살',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.white70,
                          ),
                        ),
                        const Spacer(),
                        // 인증 배지
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.verified,
                                size: 14,
                                color: Colors.white,
                              ),
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
                    const SizedBox(height: AppSizes.gapS),
                    
                    // 품종
                    const Text(
                      '골든 리트리버 · 수컷',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: AppSizes.gapS),
                    
                    // 거리
                    Row(
                      children: const [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.white70,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '1.2km 거리',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.dating.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: 16,
                            color: Colors.white,
                          ),
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
        style: const TextStyle(
          fontSize: 11,
          color: Colors.white,
        ),
      ),
    );
  }

  /// 하단 액션 버튼
  Widget _buildActionButtons() {
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
            onTap: () {
              // TODO: 패스 처리
            },
          ),
          
          // 슈퍼 라이크 버튼 (수익화 - 숨김 처리)
          // _buildActionButton(
          //   icon: Icons.star,
          //   color: AppColors.info,
          //   size: 50,
          //   onTap: () {},
          // ),
          
          // 좋아요 버튼
          _buildActionButton(
            icon: Icons.favorite,
            color: AppColors.dating,
            size: 60,
            onTap: () {
              // TODO: 좋아요 처리
            },
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
        child: Icon(
          icon,
          color: color,
          size: size * 0.5,
        ),
      ),
    );
  }

  /// 반려동물 카드 (그리드용)
  Widget _buildPetCard(int index) {
    return MingrrCard(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      onTap: () {
        // TODO: 상세 페이지로 이동
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 이미지 영역
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSizes.radiusL),
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const Center(
                    child: Icon(
                      Icons.pets,
                      size: 50,
                      color: AppColors.primary,
                    ),
                  ),
                  // 거리 표시
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${(index + 1) * 0.5}km',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                        ),
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
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    '푸들 · 3살',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
