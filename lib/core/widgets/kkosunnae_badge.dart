import 'package:flutter/material.dart';
import '../constants/app_sizes.dart';
import '../services/kkosunnae_service.dart';
import 'mingrr_bottom_sheet.dart';

/// ============================================================
/// 꼬순내 배지 위젯
/// 90% 이상 사용자에게 표시되는 발바닥 모양 배지
/// ============================================================

/// 꼬순내 마스터 배지 (90% 이상)
class KkosunaeMasterBadge extends StatelessWidget {
  final double size;
  final bool showTooltip;

  const KkosunaeMasterBadge({
    super.key,
    this.size = 24,
    this.showTooltip = true,
  });

  @override
  Widget build(BuildContext context) {
    final badge = Container(
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
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: CustomPaint(
          size: Size(size * 0.6, size * 0.6),
          painter: _PawPrintPainter(color: Colors.white),
        ),
      ),
    );

    if (!showTooltip) return badge;

    return Tooltip(
      message: '꼬순내 마스터',
      child: badge,
    );
  }
}

/// 꼬순내 점수 표시 위젯 (당근마켓 매너온도 스타일)
class KkosunnaeScoreWidget extends StatelessWidget {
  final int score;
  final bool showLabel;
  final bool compact;
  final VoidCallback? onTap;

  const KkosunnaeScoreWidget({
    super.key,
    required this.score,
    this.showLabel = true,
    this.compact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(KkosunnaeService.getGradeColor(score));
    final grade = KkosunnaeService.getSimpleGrade(score);
    final showBadge = KkosunnaeService.shouldShowBadge(score);

    if (compact) {
      return _buildCompact(color, showBadge);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 발바닥 아이콘
            CustomPaint(
              size: const Size(20, 20),
              painter: _PawPrintPainter(color: color),
            ),
            const SizedBox(width: 8),
            // 점수
            Text(
              '$score%',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            if (showLabel) ...[
              const SizedBox(width: 4),
              Text(
                grade,
                style: TextStyle(
                  fontSize: 12,
                  color: color.withOpacity(0.8),
                ),
              ),
            ],
            if (showBadge) ...[
              const SizedBox(width: 6),
              const KkosunaeMasterBadge(size: 18, showTooltip: false),
            ],
            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 16, color: color),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompact(Color color, bool showBadge) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: const Size(14, 14),
          painter: _PawPrintPainter(color: color),
        ),
        const SizedBox(width: 4),
        Text(
          '$score',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        if (showBadge) ...[
          const SizedBox(width: 4),
          const KkosunaeMasterBadge(size: 14, showTooltip: false),
        ],
      ],
    );
  }
}

/// 꼬순내 점수 바 위젯 (프로필용)
class KkosunnaeScoreBar extends StatelessWidget {
  final int score;
  final bool showDetails;
  final VoidCallback? onTap;

  const KkosunnaeScoreBar({
    super.key,
    required this.score,
    this.showDetails = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(KkosunnaeService.getGradeColor(score));
    final grade = KkosunnaeService.getSimpleGrade(score);
    final showBadge = KkosunnaeService.shouldShowBadge(score);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              children: [
                CustomPaint(
                  size: const Size(24, 24),
                  painter: _PawPrintPainter(color: color),
                ),
                const SizedBox(width: 8),
                Text(
                  '꼬순내 지수',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                if (showBadge) ...[
                  const KkosunaeMasterBadge(size: 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  '$score%',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                if (onTap != null)
                  Icon(Icons.chevron_right, size: 20, color: Theme.of(context).colorScheme.outlineVariant),
              ],
            ),
            const SizedBox(height: 12),
            // 프로그레스 바
            Stack(
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: score / 100,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color.withOpacity(0.7), color],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
            if (showDetails) ...[
              const SizedBox(height: 8),
              Text(
                grade,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 꼬순내 점수 인라인 표시 (카드용)
class KkosunnaeScoreInline extends StatelessWidget {
  final int score;
  final double iconSize;
  final double fontSize;

  const KkosunnaeScoreInline({
    super.key,
    required this.score,
    this.iconSize = 14,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(KkosunnaeService.getGradeColor(score));
    final showBadge = KkosunnaeService.shouldShowBadge(score);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: Size(iconSize, iconSize),
          painter: _PawPrintPainter(color: color),
        ),
        const SizedBox(width: 3),
        Text(
          '$score%',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        if (showBadge) ...[
          const SizedBox(width: 3),
          KkosunaeMasterBadge(size: iconSize, showTooltip: false),
        ],
      ],
    );
  }
}

/// 발바닥 모양 커스텀 페인터
class _PawPrintPainter extends CustomPainter {
  final Color color;

  _PawPrintPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // 메인 패드 (큰 타원)
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.65),
        width: w * 0.6,
        height: h * 0.5,
      ),
      paint,
    );

    // 발가락 패드 4개
    // 왼쪽 위
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.2, h * 0.25),
        width: w * 0.25,
        height: h * 0.25,
      ),
      paint,
    );

    // 왼쪽 중앙
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.35, h * 0.12),
        width: w * 0.22,
        height: h * 0.22,
      ),
      paint,
    );

    // 오른쪽 중앙
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.65, h * 0.12),
        width: w * 0.22,
        height: h * 0.22,
      ),
      paint,
    );

    // 오른쪽 위
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.8, h * 0.25),
        width: w * 0.25,
        height: h * 0.25,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 꼬순내 상세 정보 바텀시트
class KkosunnaeDetailSheet extends StatelessWidget {
  final int score;
  final String grade;
  final KkosunnaeBreakdown? breakdown;

  const KkosunnaeDetailSheet({
    super.key,
    required this.score,
    required this.grade,
    this.breakdown,
  });

  static Future<void> show(BuildContext context, {
    required int score,
    required String grade,
    KkosunnaeBreakdown? breakdown,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => KkosunnaeDetailSheet(
        score: score,
        grade: grade,
        breakdown: breakdown,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(KkosunnaeService.getGradeColor(score));

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BottomSheetHandle(),
            const SizedBox(height: 12),
            
            // 점수 표시
            CustomPaint(
              size: const Size(48, 48),
              painter: _PawPrintPainter(color: color),
            ),
            const SizedBox(height: 12),
            Text(
              '$score%',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              grade,
              style: TextStyle(
                fontSize: 16,
                color: color,
              ),
            ),
            const SizedBox(height: 24),

            // 점수 바
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Stack(
                children: [
                  Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: score / 100,
                    child: Container(
                      height: 12,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color.withOpacity(0.7), color],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('0', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outlineVariant)),
                  Text('100', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outlineVariant)),
                ],
              ),
            ),
            
            if (breakdown != null) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              
              // 상세 내역
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _buildDetailRow(context, '평판 점수', breakdown!.reputation),
                    _buildDetailRow(context, '활동 점수', breakdown!.activity),
                    _buildDetailRow(context, '신뢰도 점수', breakdown!.trust),
                    _buildDetailRow(context, '앱 활성도', breakdown!.active),
                    if (breakdown!.penalty.score > 0)
                      _buildDetailRow(context, '감점', breakdown!.penalty, isPenalty: true),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            
            // 설명
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '꼬순내 지수는 활동, 평가, 인증 등을 종합하여 계산됩니다. '
                  '좋은 매너로 활동하면 점수가 올라가요!',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, ScoreDetail detail, {bool isPenalty = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Text(
            isPenalty 
                ? '-${detail.score.toStringAsFixed(0)}점' 
                : '+${detail.score.toStringAsFixed(0)}점',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isPenalty ? Colors.red : Theme.of(context).colorScheme.onSurface,
            ),
          ),
          Text(
            ' / ${detail.maxScore.toStringAsFixed(0)}점',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        ],
      ),
    );
  }
}
