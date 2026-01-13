import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/feature_colors.dart';
import '../constants/app_sizes.dart';
import '../services/firebase_service.dart';
import 'common_widgets.dart';
import 'dialogs/dialogs.dart';
import 'mingrr_bottom_sheet.dart';

/// ============================================================
/// 꼬순내지수 (보호자 평점 시스템)
/// 
/// 당근마켓의 매너온도와 유사한 개념으로,
/// 반려동물 앱에 맞게 "꼬순내지수"라는 이름으로 구현
/// - 기본값: 50%
/// - 범위: 0 ~ 100%
/// - 아이콘: 강아지 발바닥 (퍼센트에 따라 색이 채워짐)
/// ============================================================

/// 꼬순내지수 표시 위젯 (작은 크기 - 카드/리스트용)
class KkosunnaeScoreSmall extends StatelessWidget {
  final double score; // 0~100%

  const KkosunnaeScoreSmall({
    super.key,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    final showBadge = score >= 90;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildPawIcon(score, 16),
        const SizedBox(width: 4),
        Text(
          '${score.toInt()}%',
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
  final double score; // 0~100%
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
    final isMaster = score >= 90; // 90% 이상이면 마스터
    
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
            // 퍼센트
            Text(
              '${score.toInt()}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: scoreColor,
              ),
            ),
            if (isMaster) ...[
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
  final double score; // 0~100%
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
              '${score.toInt()}%',
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

/// 꼬순내지수 평가 바텀시트
class KkosunnaeScoreRatingSheet extends StatefulWidget {
  final String targetUserId;
  final String targetUserName;
  final VoidCallback? onSubmit;

  const KkosunnaeScoreRatingSheet({
    super.key,
    required this.targetUserId,
    required this.targetUserName,
    this.onSubmit,
  });

  @override
  State<KkosunnaeScoreRatingSheet> createState() => _KkosunnaeScoreRatingSheetState();
}

class _KkosunnaeScoreRatingSheetState extends State<KkosunnaeScoreRatingSheet> {
  int _selectedRating = 0; // 1-5 별점
  final List<String> _selectedTags = [];
  bool _isSubmitting = false;
  final _firebase = FirebaseService();

  final List<String> _positiveTags = [
    '친절해요',
    '시간 약속을 잘 지켜요',
    '반려동물을 잘 돌봐요',
    '매너가 좋아요',
    '응답이 빨라요',
    '다시 만나고 싶어요',
  ];

  final List<String> _negativeTags = [
    '불친절해요',
    '시간 약속을 안 지켜요',
    '연락이 안 돼요',
    '매너가 아쉬워요',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: AppSizes.paddingL,
        right: AppSizes.paddingL,
        bottom: MediaQuery.of(context).padding.bottom + AppSizes.paddingL,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BottomSheetHandle(),
          // 헤더
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              '${widget.targetUserName}님과의 만남은 어땠나요?',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '평가는 상대방의 꼬순내지수에 반영됩니다.',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),

          // 별점
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () => setState(() => _selectedRating = index + 1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      index < _selectedRating ? Icons.star : Icons.star_border,
                      size: 40,
                      color: index < _selectedRating 
                          ? Colors.orange 
                          : Theme.of(context).colorScheme.outline,
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 24),

          // 긍정 태그
          if (_selectedRating >= 3) ...[
            const Text(
              '어떤 점이 좋았나요?',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _positiveTags.map((tag) {
                final isSelected = _selectedTags.contains(tag);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedTags.remove(tag);
                      } else {
                        _selectedTags.add(tag);
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? context.features.success.withOpacity(0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? context.features.success : Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        fontSize: 13,
                        color: isSelected ? context.features.success : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          // 부정 태그
          if (_selectedRating > 0 && _selectedRating < 3) ...[
            const Text(
              '어떤 점이 아쉬웠나요?',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _negativeTags.map((tag) {
                final isSelected = _selectedTags.contains(tag);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedTags.remove(tag);
                      } else {
                        _selectedTags.add(tag);
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.red.withOpacity(0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? Colors.red : Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        fontSize: 13,
                        color: isSelected ? Colors.red : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 24),

          // 제출 버튼
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: (_selectedRating > 0 && !_isSubmitting)
                  ? () async {
                      setState(() => _isSubmitting = true);
                      try {
                        final currentUser = FirebaseAuth.instance.currentUser;
                        if (currentUser == null) throw Exception('로그인이 필요합니다');
                        
                        // 평가 저장
                        await _firebase.ratingsCollection.add({
                          'raterId': currentUser.uid,
                          'targetUserId': widget.targetUserId,
                          'rating': _selectedRating,
                          'tags': _selectedTags,
                          'createdAt': FieldValue.serverTimestamp(),
                        });
                        
                        // 대상 사용자의 꼬순내지수 업데이트
                        final userDoc = await _firebase.usersCollection.doc(widget.targetUserId).get();
                        if (userDoc.exists) {
                          final currentScore = (userDoc.data()?['kkosunnaeScore'] ?? 50.0).toDouble();
                          final ratingCount = (userDoc.data()?['ratingCount'] ?? 0) + 1;
                          // 새 점수 계산: 기존 점수와 새 평가의 가중 평균
                          final ratingScore = (_selectedRating / 5) * 100; // 1-5를 0-100으로 변환
                          final newScore = ((currentScore * (ratingCount - 1)) + ratingScore) / ratingCount;
                          
                          await _firebase.usersCollection.doc(widget.targetUserId).update({
                            'kkosunnaeScore': newScore.clamp(0, 100),
                            'ratingCount': ratingCount,
                          });
                        }
                        
                        if (mounted) {
                          Navigator.pop(context);
                          widget.onSubmit?.call();
                          MingrrSnackBar.success(context, '평가가 완료되었습니다!');
                        }
                      } catch (e) {
                        if (mounted) {
                          MingrrSnackBar.error(context, '평가 실패: $e');
                        }
                      } finally {
                        if (mounted) setState(() => _isSubmitting = false);
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                disabledBackgroundColor: Theme.of(context).colorScheme.outline,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                '평가 완료',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
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

/// 점수에 따른 색상 반환 (0~100%)
/// 0~49%: 초록 (시작)
/// 50~79%: 파랑 (보통)
/// 80~89%: 빨강 (좋음)
/// 90~97%: 주황 (매우 좋음) - 마스터 배지
/// 98~100%: 골드 (최고) - 마스터 배지 + 특별 효과
Color _getScoreColor(double score) {
  if (score < 50) return Colors.green;
  if (score < 80) return Colors.blue;
  if (score < 90) return Colors.redAccent;  // 80~89: 빨강
  if (score < 98) return Colors.orange;     // 90~97: 주황
  return const Color(0xFFFFD700); // 골드
}

/// 점수에 따른 설명 반환 (0~100%)
String _getScoreDescription(double score) {
  if (score < 50) return '아직 활동이 적어요';
  if (score < 80) return '좋은 보호자예요';
  if (score < 90) return '믿을 수 있는 보호자예요';
  if (score < 98) return '훌륭한 보호자예요!';
  return '최고의 보호자예요! 🐾';
}

/// 꼬순내지수 평가 바텀시트 표시 함수
void showKkosunnaeScoreRatingSheet(
  BuildContext context, {
  required String targetUserId,
  required String targetUserName,
  VoidCallback? onSubmit,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => KkosunnaeScoreRatingSheet(
      targetUserId: targetUserId,
      targetUserName: targetUserName,
      onSubmit: onSubmit,
    ),
  );
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

/// 꼬순내지수 안내 커스텀 콘텐츠
class _KkosunnaeScoreGuideContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildScoreGuideRow(context, Colors.green, '0 ~ 49%', '아직 활동이 적어요', false),
        _buildScoreGuideRow(context, Colors.blue, '50 ~ 79%', '좋은 보호자예요', false),
        _buildScoreGuideRow(context, Colors.redAccent, '80 ~ 89%', '믿을 수 있는 보호자예요', false),
        _buildScoreGuideRow(context, Colors.orange, '90 ~ 97%', '훌륭한 보호자예요!', true),
        _buildScoreGuideRow(context, const Color(0xFFFFD700), '98 ~ 100%', '최고의 보호자예요! 🐾', true, isGold: true),
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
            width: 65,
            child: Text(
              range,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
            ),
          ),
          Expanded(
            child: Text(
              description,
              style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
          if (hasBadge) _KkosunaeMasterBadgeSmall(size: 14),
        ],
      ),
    );
  }
}
