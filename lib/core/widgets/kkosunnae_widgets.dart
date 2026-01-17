import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/kkosunnae_service.dart';
import '../constants/app_sizes.dart';
import 'mingrr_bottom_sheet.dart';

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
          colors: [Color(KkosunnaeService.colorBigBang), Color(KkosunnaeService.colorVolcano)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(KkosunnaeService.colorBigBang).withOpacity(0.4),
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
      onTap: onTap ?? () => showKkosunnaeDetailSheet(context),
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

// ============================================================
// 꼬순내지수 상세 바텀시트 (KkosunnaeDetailSheet)
// ============================================================

/// 꼬순내지수 상세 바텀시트 표시
void showKkosunnaeDetailSheet(BuildContext context, {String? userId}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => KkosunnaeDetailSheet(userId: userId),
  );
}

/// 꼬순내지수 상세 바텀시트 위젯
class KkosunnaeDetailSheet extends StatefulWidget {
  final String? userId;

  const KkosunnaeDetailSheet({super.key, this.userId});

  @override
  State<KkosunnaeDetailSheet> createState() => _KkosunnaeDetailSheetState();
}

class _KkosunnaeDetailSheetState extends State<KkosunnaeDetailSheet> {
  bool _isLoading = true;
  KkosunnaeResult? _result;
  String? _error;

  // 분야별 맞춤 팁 정의 (상세 설명 포함)
  static const Map<String, _ScoreTip> _scoreTips = {
    'reputation': _ScoreTip(
      hasScore: '거래, 만남 후 상대방에게 좋은 평가를 받으면 점수가 올라요',
      noScore: '아직 받은 평가가 없어요. 첫 활동을 시작해보세요!',
    ),
    'activity': _ScoreTip(
      hasScore: '데이팅, 마켓 거래, 소모임 참여 등 다양한 활동을 해보세요',
      noScore: '아직 활동 기록이 없어요. 마켓이나 소개팅을 시작해보세요!',
    ),
    'trust': _ScoreTip(
      hasScore: '본인 인증, 동물등록 인증, 위치 인증으로 점수를 올려보세요',
      noScore: '프로필 인증을 시작해보세요. 인증할수록 신뢰도가 올라가요!',
    ),
    'community': _ScoreTip(
      hasScore: '커뮤니티에 글을 쓰고, 댓글과 좋아요로 소통해보세요',
      noScore: '아직 커뮤니티 활동이 없어요. 첫 글을 작성해보세요!',
    ),
    'active': _ScoreTip(
      hasScore: '꾸준히 앱에 방문하고 프로필을 완성하면 점수가 올라가요',
      noScore: '앱을 자주 방문해보세요. 접속할수록 점수가 올라가요!',
    ),
    'penalty': _ScoreTip(
      hasScore: '노쇼, 비매너 등 감점이 있어요. 시간이 지나며 감점이 줄어요',
      noScore: '감점이 없어요. 계속 좋은 활동을 유지해주세요!',
    ),
  };

  @override
  void initState() {
    super.initState();
    _loadScore();
  }

  Future<void> _loadScore() async {
    try {
      final targetUserId = widget.userId ?? FirebaseAuth.instance.currentUser?.uid;
      if (targetUserId == null) {
        setState(() {
          _error = '로그인이 필요합니다';
          _isLoading = false;
        });
        return;
      }

      final result = await KkosunnaeService.calculateScore(targetUserId);
      setState(() {
        _result = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = '점수를 불러올 수 없습니다';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_result == null) return const SizedBox.shrink();

    final score = _result!.totalScore;
    final breakdown = _result!.breakdown;
    final scoreColor = Color(KkosunnaeService.getGradeColor(score));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const BottomSheetHandle(),
        // 헤더
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
          child: Text(
            '꼬순내지수',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ),
        // 본문
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
            child: Column(
              children: [
                // 헤더: 총점 + 등급명
                _buildScoreHeader(score, scoreColor),
                
                const SizedBox(height: 16),
                
                // 점수 상세 섹션
                _buildScoreDetailSection(breakdown),
                
                const SizedBox(height: 20),
                
                // 등급 안내 섹션
                _buildGradeGuideSection(score),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScoreHeader(int score, Color scoreColor) {
    final showBadge = KkosunnaeService.shouldShowBadge(score);
    final gradeName = KkosunnaeService.getSimpleGrade(score);
    final gradeEmoji = KkosunnaeService.getGradeEmoji(score);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scoreColor.withOpacity(0.1),
            scoreColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scoreColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          // 점수 + 등급명
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPawIcon(score.toDouble(), 36),
              const SizedBox(width: 10),
              Text(
                '$score점',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: scoreColor,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: scoreColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$gradeEmoji $gradeName',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: scoreColor,
                  ),
                ),
              ),
              if (showBadge) ...[
                const SizedBox(width: 6),
                _KkosunaeMasterBadgeSmall(size: 18),
              ],
            ],
          ),
          const SizedBox(height: 10),
          // 등급 설명
          Text(
            KkosunnaeService.getGradeDescription(score),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: scoreColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGradeGuideSection(int currentScore) {
    final thresholds = KkosunnaeService.gradeThresholds;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '등급 안내',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          _buildGradeRow(
            thresholds.getBigBangRange(),
            '빅뱅',
            '우주 끝까지 퍼지는 향! ✨',
            Color(KkosunnaeService.getGradeColor(thresholds.bigBang)),
            currentScore >= thresholds.bigBang,
            showBadge: true,
          ),
          _buildGradeRow(
            thresholds.getVolcanoRange(),
            '화산',
            '용암처럼 강렬한 냄새! 🌋',
            Color(KkosunnaeService.getGradeColor(thresholds.volcano)),
            currentScore >= thresholds.volcano && currentScore < thresholds.bigBang,
          ),
          _buildGradeRow(
            thresholds.getHotRange(),
            '뜨끈',
            '따끈한 냄새! 🔥',
            Color(KkosunnaeService.getGradeColor(thresholds.hot)),
            currentScore >= thresholds.hot && currentScore < thresholds.volcano,
          ),
          _buildGradeRow(
            thresholds.getSolsolRange(),
            '솔솔',
            '은은한 냄새~ 💨',
            Color(KkosunnaeService.getGradeColor(thresholds.solsol)),
            currentScore >= thresholds.solsol && currentScore < thresholds.hot,
          ),
          _buildGradeRow(
            thresholds.getGrowingRange(),
            '쑥쑥',
            '냄새가 자라는 중! 🌱',
            Color(KkosunnaeService.getGradeColor(0)),
            currentScore < thresholds.solsol,
          ),
          const SizedBox(height: 8),
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
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradeRow(
    String range,
    String gradeName,
    String description,
    Color color,
    bool isCurrentGrade, {
    bool showBadge = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isCurrentGrade ? color.withOpacity(0.15) : color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentGrade ? color : color.withOpacity(0.2),
          width: isCurrentGrade ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.pets, size: 16, color: color),
          const SizedBox(width: 8),
          SizedBox(
            width: 65,
            child: Text(
              range,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '$gradeName - $description',
              style: TextStyle(
                fontSize: 11,
                fontWeight: isCurrentGrade ? FontWeight.w500 : FontWeight.normal,
                color: isCurrentGrade 
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          if (showBadge) _KkosunaeMasterBadgeSmall(size: 14),
          if (isCurrentGrade) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '현재',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScoreDetailSection(KkosunnaeBreakdown breakdown) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '점수 상세',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          _buildScoreBar('평판 점수', breakdown.reputation, 'reputation'),
          _buildScoreBar('활동 점수', breakdown.activity, 'activity'),
          _buildScoreBar('신뢰도 점수', breakdown.trust, 'trust'),
          _buildScoreBar('커뮤니티 점수', breakdown.community, 'community'),
          _buildScoreBar('앱 활성도 점수', breakdown.active, 'active'),
          _buildScoreBar('감점', breakdown.penalty, 'penalty', isNegative: true),
        ],
      ),
    );
  }

  Widget _buildScoreBar(
    String label,
    ScoreDetail detail,
    String tipKey, {
    bool isNegative = false,
  }) {
    final percentage = detail.maxScore > 0 ? detail.score / detail.maxScore : 0.0;
    final tip = _scoreTips[tipKey];
    final tipText = detail.score > 0 ? tip?.hasScore : tip?.noScore;
    final theme = Theme.of(context);
    
    // 다크모드 고려한 게이지 색상 (중립적 색상)
    final gaugeColor = isNegative 
        ? Colors.red 
        : theme.colorScheme.onSurface.withOpacity(0.6);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              Text(
                isNegative 
                    ? '-${detail.score.toStringAsFixed(1)}점'
                    : '${detail.score.toStringAsFixed(1)}/${detail.maxScore.toInt()}점',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isNegative ? Colors.red : theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage.clamp(0.0, 1.0),
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(gaugeColor),
              minHeight: 8,
            ),
          ),
          if (tipText != null && tipText.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    tipText,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// 분야별 팁 데이터 클래스
class _ScoreTip {
  final String hasScore;
  final String noScore;
  
  const _ScoreTip({required this.hasScore, required this.noScore});
}
