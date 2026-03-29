import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/app_icons.dart';
import '../services/firebase_service.dart';
import '../services/kkosunnae_service.dart';
import '../constants/app_sizes.dart';
import '../theme/app_text_styles.dart';
import 'loading/loading_widgets.dart';
import 'sheets/mingrr_bottom_sheet.dart';
import '../utils/responsive_utils.dart';

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
/// - 아이콘: 반려동물 발바닥 (점수에 따라 색이 채워짐)
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
        const SizedBox(width: AppSizes.gapXS),
        Text(
          '${score.toInt()}점',
          style: AppTextStyles.labelMedium(context).copyWith(
            fontWeight: FontWeight.w600,
            color: _getScoreColor(score),
          ),
        ),
        if (showBadge) ...[
          const SizedBox(width: AppSizes.gapXS),
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
        boxShadow: AppShadows.shadowS(Theme.of(context).brightness == Brightness.dark),
      ),
      child: Center(
        child: Icon(
          AppIcons.pet,
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppSizes.paddingS),
        decoration: BoxDecoration(
          color: scoreColor.withValues(alpha: AppOpacity.o15),
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 발바닥 게이지 아이콘
            _buildPawIcon(score, 20),
            const SizedBox(width: AppSizes.gapS),
            // 꼬순내지수 라벨
            Text(
              '꼬순내지수',
              style: AppTextStyles.labelLarge(context).withColor(
                Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: AppSizes.gapXS),
            // 점수
            Text(
              '${score.toInt()}점',
              style: AppTextStyles.titleMedium(context).withWeight(FontWeight.w700).withColor(scoreColor),
            ),
            if (showBadge) ...[
              const SizedBox(width: AppSizes.gapXS),
              _KkosunaeMasterBadgeSmall(size: 14),
            ],
            const SizedBox(width: AppSizes.gapXS),
            // 클릭 가능 표시 아이콘
            Icon(
              AppIcons.help,
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
        padding: const EdgeInsets.all(AppSizes.paddingL),
        decoration: BoxDecoration(
          color: _getScoreColor(score).withValues(alpha: AppOpacity.o10),
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildPawIcon(score, 32),
                const SizedBox(width: AppSizes.gapS),
                Text(
                  '꼬순내지수',
                  style: AppTextStyles.titleMedium(context).withColor(_getScoreColor(score)),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.gapM),
            Text(
              '${score.toInt()}점',
              style: AppTextStyles.displayLarge(context).withColor(_getScoreColor(score)),
            ),
            const SizedBox(height: AppSizes.gapS),
            // 온도 바
            Container(
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSizes.radiusS),
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
                    left: (score / 100) * (ResponsiveUtils.screenWidth(context) - 100),
                    child: Container(
                      width: 4,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppSizes.radiusS),
                        boxShadow: AppShadows.shadowS(Theme.of(context).brightness == Brightness.dark),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.gapS),
            Text(
              _getScoreDescription(score),
              style: AppTextStyles.bodySmall(context).withColor(_getScoreColor(score)),
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
          AppIcons.pet,
          size: size,
          color: Colors.grey.withValues(alpha: AppOpacity.o30),
        ),
        // 채워지는 부분 (ClipRect로 퍼센트만큼만 표시)
        ClipRect(
          clipper: _PawClipper(fillPercent),
          child: Icon(
            AppIcons.pet,
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
Future<void> showKkosunnaeDetailSheet(BuildContext context, {String? userId}) {
  return showModalBottomSheet(
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

      // Firestore 캐시 갱신 (Write-through) - 본인 점수만 갱신
      // Security Rules 보호: 다른 사용자 문서는 write 불가
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      if (currentUid != null && targetUserId == currentUid) {
        FirebaseService().usersCollection.doc(targetUserId).update({
          'kkosunnaeScore': result.totalScore.toDouble(),
        }).catchError((_) {});
      }
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
        maxHeight: ResponsiveUtils.maxSheetHeight(context),
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSizes.radiusL)),
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: MingrrLoadingIndicator())
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
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSizes.paddingL, 4, 20, 12),
          child: Text(
            '꼬순내지수',
            style: AppTextStyles.headlineSmall(context),
            textAlign: TextAlign.center,
          ),
        ),
        // 본문
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: AppSizes.paddingL),
            child: Column(
              children: [
                // 헤더: 총점 + 등급명
                _buildScoreHeader(score, scoreColor),
                
                const SizedBox(height: AppSizes.gapL),
                
                // 점수 상세 섹션
                _buildScoreDetailSection(breakdown),
                
                const SizedBox(height: AppSizes.gapL),
                
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
      padding: const EdgeInsets.all(AppSizes.paddingXL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scoreColor.withValues(alpha: AppOpacity.o10),
            scoreColor.withValues(alpha: AppOpacity.o05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        border: Border.all(color: scoreColor.withValues(alpha: AppOpacity.o30)),
      ),
      child: Column(
        children: [
          // 점수 + 등급명
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPawIcon(score.toDouble(), 36),
              const SizedBox(width: AppSizes.gapM),
              Text(
                '${score.toInt()}점',
                style: AppTextStyles.displayMedium(context).withColor(scoreColor),
              ),
              const SizedBox(width: AppSizes.gapS),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingS, vertical: AppSizes.paddingXS),
                decoration: BoxDecoration(
                  color: scoreColor.withValues(alpha: AppOpacity.o20),
                  borderRadius: BorderRadius.circular(AppSizes.radiusS),
                ),
                child: Text(
                  '$gradeEmoji $gradeName',
                  style: AppTextStyles.titleSmall(context).withWeight(FontWeight.w600).withColor(scoreColor),
                ),
              ),
              if (showBadge) ...[
                const SizedBox(width: AppSizes.gapS),
                _KkosunaeMasterBadgeSmall(size: 18),
              ],
            ],
          ),
          const SizedBox(height: AppSizes.gapM),
          // 등급 설명
          Text(
            KkosunnaeService.getGradeDescription(score),
            style: AppTextStyles.titleSmall(context).withColor(scoreColor),
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
          Text(
            '등급 안내',
            style: AppTextStyles.titleLarge(context),
          ),
          const SizedBox(height: AppSizes.gapM),
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
          const SizedBox(height: AppSizes.gapS),
          Container(
            padding: const EdgeInsets.all(AppSizes.paddingS),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppSizes.radiusS),
            ),
            child: Row(
              children: [
                Icon(
                  AppIcons.info,
                  size: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSizes.gapS),
                Expanded(
                  child: Text(
                    '등급 구간은 전체 사용자 분포에 따라 주기적으로 조정돼요',
                    style: AppTextStyles.caption(context),
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
      margin: const EdgeInsets.only(bottom: AppSizes.paddingS),
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM, vertical: AppSizes.paddingS),
      decoration: BoxDecoration(
        color: isCurrentGrade ? color.withValues(alpha: AppOpacity.o15) : color.withValues(alpha: AppOpacity.o05),
        borderRadius: BorderRadius.circular(AppSizes.radiusS),
        border: Border.all(
          color: isCurrentGrade ? color : color.withValues(alpha: AppOpacity.o20),
          width: isCurrentGrade ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(AppIcons.pet, size: 16, color: color),
          const SizedBox(width: AppSizes.gapS),
          SizedBox(
            width: 65,
            child: Text(
              range,
              style: AppTextStyles.labelMedium(context).withWeight(FontWeight.w600).withColor(color),
            ),
          ),
          Expanded(
            child: Text(
              '$gradeName - $description',
              style: isCurrentGrade 
                  ? AppTextStyles.labelMedium(context)
                  : AppTextStyles.caption(context),
            ),
          ),
          if (showBadge) _KkosunaeMasterBadgeSmall(size: 14),
          if (isCurrentGrade) ...[
            const SizedBox(width: AppSizes.gapXS),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: AppSizes.paddingXXS),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(AppSizes.radiusS),
              ),
              child: Text(
                '현재',
                style: AppTextStyles.captionSmall(context).withWeight(FontWeight.w600).withColor(Colors.white),
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
          Text(
            '점수 상세',
            style: AppTextStyles.titleLarge(context),
          ),
          const SizedBox(height: AppSizes.gapM),
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
        : theme.colorScheme.onSurface.withValues(alpha: AppOpacity.o50);
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: AppTextStyles.titleSmall(context),
              ),
              Text(
                isNegative 
                    ? '-${detail.score.toStringAsFixed(1)}점'
                    : '${detail.score.toStringAsFixed(1)}/${detail.maxScore.toInt()}점',
                style: AppTextStyles.labelMedium(context).copyWith(
                  fontWeight: FontWeight.w600,
                  color: isNegative ? Colors.red : theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.gapS),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusS),
            child: LinearProgressIndicator(
              value: percentage.clamp(0.0, 1.0),
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(gaugeColor),
              minHeight: 8,
            ),
          ),
          if (tipText != null && tipText.isNotEmpty) ...[
            const SizedBox(height: AppSizes.gapXS),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  AppIcons.lightbulb,
                  size: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSizes.gapXS),
                Expanded(
                  child: Text(
                    tipText,
                    style: AppTextStyles.caption(context),
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
