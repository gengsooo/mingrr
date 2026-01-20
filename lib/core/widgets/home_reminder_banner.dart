import 'package:flutter/material.dart';
import '../constants/app_sizes.dart';

/// ============================================================
/// 홈 화면 리마인더 배너
/// 
/// 범용 배너 위젯으로 다양한 알림 유형을 지원합니다.
/// - 평가 리마인더
/// - 소모임 일정
/// - 반려동물 좋아요
/// - 받은 평가
/// - 인증 안내
/// - 소모임 가입 신청
/// - 건강 기록 리마인더
/// ============================================================

/// 배너 타입
enum ReminderBannerType {
  /// 평가 리마인더 - 평가하지 않은 활동
  rating,
  /// 소모임 일정 - 오늘 일정
  groupSchedule,
  /// 반려동물 좋아요 - 내 반려동물이 관심을 받음
  petLike,
  /// 받은 평가 - 새로운 평가
  receivedRating,
  /// 인증 안내 - 프로필 인증 유도
  verification,
  /// 소모임 가입 신청 - 승인 대기
  groupJoinRequest,
  /// 건강 기록 리마인더 - 예방접종 등
  healthRecord,
}

/// 배너 설정
class _BannerConfig {
  final IconData icon;
  final String title;
  final String Function(int count) subtitle;
  
  const _BannerConfig({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

/// 배너 타입별 설정
final Map<ReminderBannerType, _BannerConfig> _bannerConfigs = {
  ReminderBannerType.rating: _BannerConfig(
    icon: Icons.rate_review_outlined,
    title: '평가하지 않은 활동이 있어요',
    subtitle: (count) => '$count건의 평가가 기다리고 있어요',
  ),
  ReminderBannerType.groupSchedule: _BannerConfig(
    icon: Icons.event_outlined,
    title: '오늘 소모임 일정이 있어요',
    subtitle: (count) => '$count개의 일정을 확인해보세요',
  ),
  ReminderBannerType.petLike: _BannerConfig(
    icon: Icons.pets_outlined,
    title: '내 반려동물이 관심을 받았어요',
    subtitle: (count) => '$count명이 좋아요를 눌렀어요',
  ),
  ReminderBannerType.receivedRating: _BannerConfig(
    icon: Icons.star_outline,
    title: '새로운 평가를 받았어요',
    subtitle: (count) => '$count건의 새 평가가 있어요',
  ),
  ReminderBannerType.verification: _BannerConfig(
    icon: Icons.verified_outlined,
    title: '프로필 인증을 완료해보세요',
    subtitle: (count) => '$count개의 인증이 남았어요',
  ),
  ReminderBannerType.groupJoinRequest: _BannerConfig(
    icon: Icons.group_add_outlined,
    title: '가입 승인 대기 중인 신청이 있어요',
    subtitle: (count) => '$count건의 신청을 확인해보세요',
  ),
  ReminderBannerType.healthRecord: _BannerConfig(
    icon: Icons.medical_services_outlined,
    title: '건강 기록을 확인해보세요',
    subtitle: (count) => '$count개의 일정이 다가오고 있어요',
  ),
};

/// 홈 화면 리마인더 배너
class HomeReminderBanner extends StatelessWidget {
  final ReminderBannerType type;
  final int count;
  final VoidCallback onTap;
  final VoidCallback? onDismiss;

  const HomeReminderBanner({
    super.key,
    required this.type,
    required this.count,
    required this.onTap,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    
    final config = _bannerConfigs[type]!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSizes.gapM),
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL, vertical: AppSizes.paddingM),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // 아이콘
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                config.icon,
                size: 20,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: AppSizes.gapM),
            // 텍스트
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    config.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSizes.gapXXS),
                  Text(
                    config.subtitle(count),
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            // 화살표 또는 닫기 버튼
            if (onDismiss != null)
              GestureDetector(
                onTap: onDismiss,
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.paddingXS),
                  child: Icon(
                    Icons.close,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              Icon(
                Icons.chevron_right,
                size: 20,
                color: colorScheme.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }
}

/// 스와이프 가능한 홈 리마인더 배너 캐러셀
/// PageView + 점 인디케이터 방식
class HomeReminderBannerCarousel extends StatefulWidget {
  final List<HomeReminderBannerData> banners;
  final int maxVisible;

  const HomeReminderBannerCarousel({
    super.key,
    required this.banners,
    this.maxVisible = 7,
  });

  @override
  State<HomeReminderBannerCarousel> createState() => _HomeReminderBannerCarouselState();
}

class _HomeReminderBannerCarouselState extends State<HomeReminderBannerCarousel> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visibleBanners = widget.banners
        .where((b) => b.count > 0)
        .take(widget.maxVisible)
        .toList();
    
    if (visibleBanners.isEmpty) return const SizedBox.shrink();
    
    // 배너가 1개면 스와이프 없이 단일 배너 표시
    if (visibleBanners.length == 1) {
      final banner = visibleBanners.first;
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSizes.gapM),
        child: _BannerCard(
          type: banner.type,
          count: banner.count,
          onTap: banner.onTap,
        ),
      );
    }
    
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      children: [
        // 배너 PageView
        SizedBox(
          height: 80,
          child: PageView.builder(
            controller: _pageController,
            itemCount: visibleBanners.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemBuilder: (context, index) {
              final banner = visibleBanners[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingXXS),
                child: _BannerCard(
                  type: banner.type,
                  count: banner.count,
                  onTap: banner.onTap,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSizes.gapS),
        // 점 인디케이터
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            visibleBanners.length,
            (index) => Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: AppSizes.paddingXXS),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: index == _currentPage
                    ? colorScheme.primary
                    : colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSizes.gapM),
      ],
    );
  }
}

/// 배너 카드 (내부 위젯)
class _BannerCard extends StatelessWidget {
  final ReminderBannerType type;
  final int count;
  final VoidCallback onTap;

  const _BannerCard({
    required this.type,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final config = _bannerConfigs[type]!;
    final colorScheme = Theme.of(context).colorScheme;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL, vertical: AppSizes.paddingM),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // 아이콘
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                config.icon,
                size: 20,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: AppSizes.gapM),
            // 텍스트
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    config.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSizes.gapXXS),
                  Text(
                    config.subtitle(count),
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // 화살표
            Icon(
              Icons.chevron_right,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

/// 홈 화면 리마인더 배너 목록 (세로 나열 - 레거시)
/// @deprecated Use HomeReminderBannerCarousel instead
@Deprecated('Use HomeReminderBannerCarousel instead')
class HomeReminderBannerList extends StatelessWidget {
  final List<HomeReminderBannerData> banners;
  final int maxVisible;

  const HomeReminderBannerList({
    super.key,
    required this.banners,
    this.maxVisible = 2,
  });

  @override
  Widget build(BuildContext context) {
    final visibleBanners = banners
        .where((b) => b.count > 0)
        .take(maxVisible)
        .toList();
    
    if (visibleBanners.isEmpty) return const SizedBox.shrink();
    
    return Column(
      children: visibleBanners.map((banner) => HomeReminderBanner(
        type: banner.type,
        count: banner.count,
        onTap: banner.onTap,
        onDismiss: banner.onDismiss,
      )).toList(),
    );
  }
}

/// 배너 데이터
class HomeReminderBannerData {
  final ReminderBannerType type;
  final int count;
  final VoidCallback onTap;
  final VoidCallback? onDismiss;

  const HomeReminderBannerData({
    required this.type,
    required this.count,
    required this.onTap,
    this.onDismiss,
  });
}
