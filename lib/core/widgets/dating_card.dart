import 'package:flutter/material.dart';
import '../constants/app_sizes.dart';
import '../theme/feature_colors.dart';
import 'common_widgets.dart';
import 'info_badge.dart';
import 'trait_badge.dart';
import 'svg_icons.dart';

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
    final features = context.features;
    final isHighMatch = matchScore >= 90;
    final matchColor = isHighMatch ? features.success : features.dating;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSizes.gapM),
        height: 280,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusXL),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
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
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: matchColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome, size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        '궁합 $matchScore%',
                        style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
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
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            ageString,
                            style: const TextStyle(fontSize: 16, color: Colors.white70),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      
                      // 품종과 거리
                      Row(
                        children: [
                          Text(
                            breed ?? '품종 미상',
                            style: const TextStyle(fontSize: 13, color: Colors.white70),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.location_on, size: 12, color: Colors.white70),
                          const SizedBox(width: 2),
                          Text(
                            distanceString,
                            style: const TextStyle(fontSize: 12, color: Colors.white70),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
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
    if (imageUrl != null) {
      return Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholder(context),
      );
    }
    return _buildPlaceholder(context);
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.features.datingContainer,
            context.features.dating.withOpacity(0.2),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: DefaultPetIcon(size: 80),
      ),
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
              Colors.black.withOpacity(0.7),
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
    return Container(
      decoration: BoxDecoration(
        color: context.features.datingContainer,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusL),
        ),
        image: imageUrl != null
            ? DecorationImage(
                image: NetworkImage(imageUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl == null)
            Center(
              child: DefaultPetIcon(size: 50),
            ),
          // 거리 배지 (우상단)
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
                distanceString,
                style: const TextStyle(fontSize: 10, color: Colors.white),
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
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          // 품종 · 나이
          Text(
            '${breed ?? '품종 미상'} · $ageString',
            style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
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
/// [hasPedigree]: 혈통서 보유 여부
/// [isVaccinationVerified]: 예방접종 인증 여부
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
  final bool hasPedigree;
  final bool isVaccinationVerified;
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
    this.hasPedigree = false,
    this.isVaccinationVerified = false,
    this.imageUrl,
    this.onTap,
    this.onBreedingRequest,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final features = context.features;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSizes.gapM),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IntrinsicHeight(
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
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.location_on, size: 12, color: colorScheme.onSurfaceVariant),
                                  const SizedBox(width: 2),
                                  Text(
                                    distanceString,
                                    style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${breed ?? '품종 미상'} · $ageString',
                            style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                      // 중간: 교배 조건 태그 (혈통서는 항상 표시)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSizes.gapS),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            PedigreeBadge(hasPedigree: hasPedigree, size: InfoBadgeSize.small),
                            if (isVaccinationVerified)
                              _buildConditionTag(context, '예방접종', Icons.health_and_safety),
                          ],
                        ),
                      ),
                      // 하단: 교배 신청 버튼
                      const SizedBox(height: AppSizes.gapS),
                      MingrrButton(
                        text: '교배 신청',
                        onPressed: onBreedingRequest,
                        backgroundColor: features.dating,
                        textColor: Colors.white,
                        height: 34,
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

  Widget _buildImageSection(BuildContext context) {
    return Container(
      width: 120,
      decoration: BoxDecoration(
        color: context.features.datingContainer,
        borderRadius: const BorderRadius.horizontal(
          left: Radius.circular(AppSizes.radiusL),
        ),
        image: imageUrl != null
            ? DecorationImage(
                image: NetworkImage(imageUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: Stack(
        children: [
          if (imageUrl == null)
            Center(
              child: DefaultPetIcon(size: 50),
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
    );
  }

  Widget _buildConditionTag(BuildContext context, String text, IconData icon) {
    final color = context.features.dating;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: color),
          ),
        ],
      ),
    );
  }

}
