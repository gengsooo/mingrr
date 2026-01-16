import 'package:flutter/material.dart';
import '../services/kkosunnae_service.dart';
import 'dialogs/dialogs.dart';

/// ============================================================
/// 꼬순내지수 (보호자 평점 시스템)
/// 
/// 당근마켓의 매너온도와 유사한 개념으로,
/// 반려동물 앱에 맞게 "꼬순내지수"라는 이름으로 구현
/// 
/// 하이브리드 방식:
/// - 원점수: 절대 평가 (0~100점) - 변하지 않음
/// - 등급: 상대 평가 (백분위 기반) - 주기적 조정
/// 
/// - 기본값: 50점
/// - 범위: 0 ~ 100점
/// - 아이콘: 강아지 발바닥 (점수에 따라 색이 채워짐)
/// ============================================================

/// 꼬순내지수 표시 위젯 (작은 크기 - 카드/리스트용)
class KkosunnaeScoreSmall extends StatelessWidget {
  final double score; // 0~100점

  const KkosunnaeScoreSmall({
    super.key,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    final showBadge = KkosunnaeService.shouldShowBadge(score.toInt());
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildPawIcon(score, 16),
        const SizedBox(width: 4),
        Text(
          '${score.toInt()}점',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _getScoreColor(score),
          ),
        ),
        if (showBadge) ...[
          const SizedBox(width: 4),
          _KkosunaeMasterBadgeSmall(size: 14),
        ],
      ],
    );
  }
}

/// 꼬순내 마스터 배지 (90점 이상) - 작은 크기
class _KkosunaeMasterBadgeSmall extends StatelessWidget {
  final double size;

  const _KkosunaeMasterBadgeSmall({this.size = 14});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withOpacity(0.4),
            blurRadius: 4,
            spreadRadius: 0.5,
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.pets,
          size: size * 0.6,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// 꼬순내지수 표시 위젯 (중간 크기 - 프로필/상세용)
class KkosunnaeScoreMedium extends StatelessWidget {
  final double score; // 0~100점
  final VoidCallback? onTap;
  final bool showDescription; // 구간별 설명 표시 여부

  const KkosunnaeScoreMedium({
    super.key,
    required this.score,
    this.onTap,
    this.showDescription = false,
  });

  @override
  Widget build(BuildContext context) {
    final scoreColor = _getScoreColor(score);
    final showBadge = KkosunnaeService.shouldShowBadge(score.toInt());
    
    return GestureDetector(
      onTap: onTap ?? () => showKkosunnaeScoreGuideModal(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: scoreColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 발바닥 게이지 아이콘
            _buildPawIcon(score, 20),
            const SizedBox(width: 6),
            // 꼬순내지수 라벨
            Text(
              '꼬순내지수',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 4),
            // 점수
            Text(
              '${score.toInt()}점',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: scoreColor,
              ),
            ),
            if (showBadge) ...[
              const SizedBox(width: 4),
              _KkosunaeMasterBadgeSmall(size: 14),
            ],
            const SizedBox(width: 4),
            // 클릭 가능 표시 아이콘
            Icon(
              Icons.help_outline,
              size: 14,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ],
        ),
      ),
    );
  }
}

/// 꼬순내지수 표시 위젯 (큰 크기 - 상세 페이지용)
class KkosunnaeScoreLarge extends StatelessWidget {
  final double score; // 0~100점
  final VoidCallback? onTap;

  const KkosunnaeScoreLarge({
    super.key,
    required this.score,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _getScoreColor(score).withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildPawIcon(score, 32),
                const SizedBox(width: 8),
                Text(
                  '꼬순내지수',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _getScoreColor(score),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${score.toInt()}점',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                color: _getScoreColor(score),
              ),
            ),
            const SizedBox(height: 8),
            // 온도 바
            Container(
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: const LinearGradient(
                  colors: [
                    Colors.blue,
                    Colors.green,
                    Colors.orange,
                    Colors.red,
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: (score / 100) * (MediaQuery.of(context).size.width - 100),
                    child: Container(
                      width: 4,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getScoreDescription(score),
              style: TextStyle(
                fontSize: 12,
                color: _getScoreColor(score),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 발바닥 아이콘 (퍼센트에 따라 색이 채워짐)
Widget _buildPawIcon(double score, double size) {
  final color = _getScoreColor(score);
  final fillPercent = score / 100;
  
  return SizedBox(
    width: size,
    height: size,
    child: Stack(
      children: [
        // 배경 (회색 발바닥)
        Icon(
          Icons.pets,
          size: size,
          color: Colors.grey.withOpacity(0.3),
        ),
        // 채워지는 부분 (ClipRect로 퍼센트만큼만 표시)
        ClipRect(
          clipper: _PawClipper(fillPercent),
          child: Icon(
            Icons.pets,
            size: size,
            color: color,
          ),
        ),
      ],
    ),
  );
}

/// 발바닥 아이콘 클리퍼 (아래에서 위로 채워짐)
class _PawClipper extends CustomClipper<Rect> {
  final double fillPercent;
  
  _PawClipper(this.fillPercent);
  
  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(
      0,
      size.height * (1 - fillPercent),
      size.width,
      size.height,
    );
  }
  
  @override
  bool shouldReclip(_PawClipper oldClipper) => fillPercent != oldClipper.fillPercent;
}

/// 점수에 따른 색상 반환 (KkosunnaeService 동적 구간 기반)
Color _getScoreColor(double score) {
  return Color(KkosunnaeService.getGradeColor(score.toInt()));
}

/// 점수에 따른 설명 반환 (KkosunnaeService 동적 구간 기반)
String _getScoreDescription(double score) {
  return KkosunnaeService.getGradeDescription(score.toInt());
}

/// 꼬순내지수 구간 안내 모달
void showKkosunnaeScoreGuideModal(BuildContext context) {
  showInfoDialog(
    context,
    title: '꼬순내지수란?',
    icon: Icons.pets,
    subtitle: '보호자 신뢰도 지표',
    accentColor: Theme.of(context).colorScheme.primary,
    customContent: _KkosunnaeScoreGuideContent(),
    footerText: '거래, 만남, 활동 후 상대방의 평가를 통해 점수가 변동돼요',
  );
}

/// 꼬순내지수 안내 커스텀 콘텐츠 (동적 구간 기반)
class _KkosunnaeScoreGuideContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final thresholds = KkosunnaeService.gradeThresholds;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildScoreGuideRow(
          context, 
          Color(KkosunnaeService.getGradeColor(thresholds.bigBang)), 
          thresholds.getBigBangRange(), 
          '빅뱅 - 우주 끝까지 퍼지는 향! ✨', 
          true, 
          isGold: true,
        ),
        _buildScoreGuideRow(
          context, 
          Color(KkosunnaeService.getGradeColor(thresholds.volcano)), 
          thresholds.getVolcanoRange(), 
          '화산 - 용암처럼 강렬한 냄새! 🌋', 
          false,
        ),
        _buildScoreGuideRow(
          context, 
          Color(KkosunnaeService.getGradeColor(thresholds.hot)), 
          thresholds.getHotRange(), 
          '뜨끈 - 따끈한 냄새! 🔥', 
          false,
        ),
        _buildScoreGuideRow(
          context, 
          Color(KkosunnaeService.getGradeColor(thresholds.solsol)), 
          thresholds.getSolsolRange(), 
          '솔솔 - 은은한 냄새~ 💨', 
          false,
        ),
        _buildScoreGuideRow(
          context, 
          Color(KkosunnaeService.getGradeColor(0)), 
          thresholds.getGrowingRange(), 
          '쑥쑥 - 냄새가 자라는 중! 🌱', 
          false,
        ),
        const SizedBox(height: 8),
        // 상대 평가 안내 문구
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '등급 구간은 전체 사용자 분포에 따라 주기적으로 조정돼요',
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScoreGuideRow(BuildContext context, Color color, String range, String description, bool hasBadge, {bool isGold = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isGold ? Colors.white : color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(isGold ? 0.5 : 0.2)),
        boxShadow: isGold ? [
          BoxShadow(color: color.withOpacity(0.2), blurRadius: 4, spreadRadius: 0.5),
        ] : null,
      ),
      child: Row(
        children: [
          Icon(Icons.pets, size: 16, color: color),
          const SizedBox(width: 8),
          SizedBox(
            width: 70,
            child: Text(
              range,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
            ),
          ),
          Expanded(
            child: Text(
              description,
              style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
          if (hasBadge) _KkosunaeMasterBadgeSmall(size: 14),
        ],
      ),
    );
  }
}
