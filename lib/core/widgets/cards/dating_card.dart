import 'package:flutter/material.dart';
import '../../constants/app_sizes.dart';
import '../../constants/app_icons.dart';
import '../../constants/location_constants.dart';
import '../../theme/feature_colors.dart';
import '../../theme/app_text_styles.dart';
import '../common_widgets.dart';
import '../badges/info_badge.dart';
import '../badges/trait_badge.dart';
import '../mingrr_image.dart';

/// ============================================================
/// 데이팅 카드 컴포넌트
/// 
/// 데이팅 화면에서 사용하는 공통 카드 위젯
/// 
/// 포함 컴포넌트:
/// - DatingRecommendCard: 추천친구 탭용 대형 카드
/// - DatingNearbyCard: 근처검색 탭용 그리드 카드
/// - DatingBreedingCard: 교배찾기 탭용 가로형 카드
/// ============================================================

/// ------------------------------------------------------------
/// 추천친구 카드 (대형, 전체 이미지 + 하단 오버레이)
/// 
/// 사용처: 데이팅 > 추천친구 탭
/// 
/// [name]: 반려동물 이름
/// [breed]: 품종
/// [ageString]: 나이 문자열 (예: "3살")
/// [isMale]: 성별 (true: 남아)
/// [matchScore]: 궁합 점수 (0-100)
/// [distanceString]: 거리 문자열 (예: "1.2km")
/// [traits]: 특성 태그 목록
/// [imageUrl]: 대표 이미지 URL
/// [onTap]: 탭 콜백
/// ------------------------------------------------------------
class DatingRecommendCard extends StatelessWidget {
  final String name;
  final String? breed;
  final String ageString;
  final bool isMale;
  final int matchScore;
  final String distanceString;
  final List<String> traits;
  final String? imageUrl;
  final VoidCallback? onTap;

  const DatingRecommendCard({
    super.key,
    required this.name,
    this.breed,
    required this.ageString,
    required this.isMale,
    required this.matchScore,
    required this.distanceString,
    this.traits = const [],
    this.imageUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSizes.gapM),
        height: 280,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusXL),
          boxShadow: AppShadows.shadowM(Theme.of(context).brightness == Brightness.dark),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSizes.radiusXL),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 배경 이미지
              _buildBackground(context),
              
              // 그라데이션 오버레이
              _buildGradientOverlay(),
              
              // 성별 배지 (좌상단)
              Positioned(
                top: 12,
                left: 12,
                child: PetGenderBadge(
                  isMale: isMale,
                  showLabel: true,
                  size: InfoBadgeSize.medium,
                ),
              ),
              
              // 궁합 점수 (우상단)
              Positioned(
                top: 12,
                right: 12,
                child: MatchScoreBadge(
                  score: matchScore,
                  style: MatchBadgeStyle.filled,
                  size: InfoBadgeSize.medium,
                ),
              ),
              
              // 정보 영역 (하단)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.paddingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 이름과 나이
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: AppTextStyles.headlineMedium(context).copyWith(color: Colors.white),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppSizes.gapS),
                          Text(
                            ageString,
                            style: AppTextStyles.headlineSmall(context).copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.gapXS),
                      
                      // 품종과 거리
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              breed ?? '품종 미상',
                              style: AppTextStyles.bodyMedium(context).copyWith(color: Colors.white70),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppSizes.gapS),
                          Icon(LocationConstants.distanceIcon, size: 12, color: Colors.white70),
                          const SizedBox(width: 2),
                          Text(
                            distanceString,
                            style: AppTextStyles.bodySmall(context).copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.gapS),
                      
                      // 특성 태그
                      if (traits.isNotEmpty)
                        TraitBadgeList(
                          traits: traits,
                          size: TraitBadgeSize.small,
                          maxCount: 3,
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
  }

  Widget _buildBackground(BuildContext context) {
    return MingrrImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      accentColor: context.features.dating,
      placeholderIcon: AppIcons.pet,
    );
  }

  Widget _buildGradientOverlay() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      height: 150,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: AppOpacity.o70),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),
    );
  }
}

/// ------------------------------------------------------------
/// 근처검색 카드 (그리드, 상단 이미지 + 하단 정보)
/// 
/// 사용처: 데이팅 > 근처검색 탭
/// 
/// [name]: 반려동물 이름
/// [breed]: 품종
/// [ageString]: 나이 문자열
/// [matchScore]: 궁합 점수
/// [distanceString]: 거리 문자열
/// [traits]: 특성 태그 목록
/// [imageUrl]: 대표 이미지 URL
/// [onTap]: 탭 콜백
/// ------------------------------------------------------------
class DatingNearbyCard extends StatelessWidget {
  final String name;
  final String? breed;
  final String ageString;
  final int? matchScore;
  final String distanceString;
  final List<String> traits;
  final String? imageUrl;
  final VoidCallback? onTap;

  const DatingNearbyCard({
    super.key,
    required this.name,
    this.breed,
    required this.ageString,
    this.matchScore,
    required this.distanceString,
    this.traits = const [],
    this.imageUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
          boxShadow: AppShadows.shadowS(Theme.of(context).brightness == Brightness.dark),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 이미지 영역
            Expanded(
              flex: 3,
              child: _buildImageSection(context),
            ),
            // 정보 영역
            Expanded(
              flex: 3,
              child: _buildInfoSection(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppSizes.radiusL),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 이미지 또는 플레이스홀더
          MingrrImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            accentColor: context.features.dating,
            placeholderIcon: AppIcons.pet,
          ),
          // 거리 배지 (우상단)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingS, vertical: AppSizes.paddingXS),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(AppSizes.radiusS),
              ),
              child: Text(
                distanceString,
                style: AppTextStyles.captionSmall(context).copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.paddingS),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 이름
          Text(
            name,
            style: AppTextStyles.titleMedium(context),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSizes.gapXXS),
          // 품종 · 나이
          Text(
            '${breed ?? '품종 미상'} · $ageString',
            style: AppTextStyles.captionSmall(context),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          // 특성 태그
          if (traits.isNotEmpty)
            TraitBadgeList(
              traits: traits,
              size: TraitBadgeSize.small,
              maxCount: 2,
            ),
        ],
      ),
    );
  }
}

/// ------------------------------------------------------------
/// 교배찾기 카드 (가로형, 좌측 이미지 + 우측 정보)
/// 
/// 사용처: 데이팅 > 교배찾기 탭
/// 
/// [name]: 반려동물 이름
/// [breed]: 품종
/// [ageString]: 나이 문자열
/// [isMale]: 성별
/// [distanceString]: 거리 문자열
/// [description]: 교배 글 상세 내용
/// [hasPedigree]: 혈통서 보유 여부
/// [imageUrl]: 대표 이미지 URL
/// [onTap]: 탭 콜백
/// [onBreedingRequest]: 교배 신청 버튼 콜백
/// ------------------------------------------------------------
class DatingBreedingCard extends StatelessWidget {
  final String name;
  final String? breed;
  final String ageString;
  final bool isMale;
  final String distanceString;
  final String? description;
  final bool hasPedigree;
  final String? imageUrl;
  final VoidCallback? onTap;
  final VoidCallback? onBreedingRequest;

  const DatingBreedingCard({
    super.key,
    required this.name,
    this.breed,
    required this.ageString,
    required this.isMale,
    required this.distanceString,
    this.description,
    this.hasPedigree = false,
    this.imageUrl,
    this.onTap,
    this.onBreedingRequest,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSizes.gapM),
        height: 130, // 고정 높이 (버튼 제거 후 조정)
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
          boxShadow: AppShadows.shadowS(Theme.of(context).brightness == Brightness.dark),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 이미지 영역
            _buildImageSection(context),
              // 정보 영역
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.paddingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 상단: 이름, 거리, 품종/나이
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: AppTextStyles.headlineSmall(context),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(LocationConstants.distanceIcon, size: 12, color: colorScheme.onSurfaceVariant),
                                  const SizedBox(width: 2),
                                  Text(
                                    distanceString,
                                    style: AppTextStyles.captionSmall(context),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSizes.gapSM),
                          Text(
                            '${breed ?? '품종 미상'} · $ageString',
                            style: AppTextStyles.bodySmall(context),
                          ),
                          // 상세 내용 (최대 2줄)
                          if (description != null && description!.isNotEmpty) ...[
                            const SizedBox(height: AppSizes.gapS),
                            Text(
                              description!,
                              style: AppTextStyles.bodySmall(context).copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                      // 하단: 교배 조건 태그 (혈통서만 표시)
                      PedigreeBadge(hasPedigree: hasPedigree, size: InfoBadgeSize.small),
                    ],
                  ),
                ),
              ),
            ],
        ),
      ),
    );
  }

  Widget _buildImageSection(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.horizontal(
        left: Radius.circular(AppSizes.radiusL),
      ),
      child: SizedBox(
        width: 120,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 이미지 또는 플레이스홀더 (데이팅 테마 사용으로 통일)
            MingrrImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              accentColor: context.features.dating,
              placeholderIcon: AppIcons.pet,
            ),
            // 성별 배지 (좌상단)
            Positioned(
              top: 8,
              left: 8,
              child: PetGenderBadge(
                isMale: isMale,
                showLabel: true,
                size: InfoBadgeSize.small,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
