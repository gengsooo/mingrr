import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/app_sizes.dart';
import '../services/firebase_service.dart';
import 'common_widgets.dart';
import 'mingrr_bottom_sheet.dart';

/// ============================================================
/// 신고 기능 위젯
/// 
/// 채팅, 데이팅, 마켓, 소모임 등에서 공통으로 사용
/// ============================================================

/// 신고 유형
enum ReportType {
  spam('스팸/광고'),
  inappropriate('부적절한 콘텐츠'),
  harassment('괴롭힘/욕설'),
  scam('사기/허위정보'),
  impersonation('사칭'),
  other('기타');

  final String label;
  const ReportType(this.label);
}

/// 신고 대상 유형
enum ReportTargetType {
  user('사용자'),
  chat('채팅'),
  post('게시글'),
  product('상품'),
  group('소모임'),
  feed('커뮤니티 게시글');

  final String label;
  const ReportTargetType(this.label);
}

/// 하위 호환성을 위한 별칭
extension ReportTargetTypeCompat on ReportTargetType {
  static ReportTargetType get community => ReportTargetType.group;
}

/// 신고 바텀시트
class ReportSheet extends StatefulWidget {
  final String targetId;
  final String targetName;
  final ReportTargetType targetType;
  final VoidCallback? onSubmit;

  const ReportSheet({
    super.key,
    required this.targetId,
    required this.targetName,
    required this.targetType,
    this.onSubmit,
  });

  @override
  State<ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<ReportSheet> {
  ReportType? _selectedType;
  final TextEditingController _detailController = TextEditingController();
  bool _isSubmitting = false;
  final _firebase = FirebaseService();

  @override
  void dispose() {
    _detailController.dispose();
    super.dispose();
  }

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
          const Center(child: BottomSheetHandle()),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.report_outlined, color: Colors.red),
              const SizedBox(width: 8),
              Text(
                '${widget.targetName} 신고하기',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '신고 사유를 선택해주세요. 허위 신고 시 제재를 받을 수 있습니다.',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),

          // 신고 유형 선택
          ...ReportType.values.map((type) {
            final isSelected = _selectedType == type;
            return GestureDetector(
              onTap: () => setState(() => _selectedType = type),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.red.withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? Colors.red : Theme.of(context).colorScheme.outline,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                      size: 20,
                      color: isSelected ? Colors.red : Theme.of(context).colorScheme.outlineVariant,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      type.label,
                      style: TextStyle(
                        fontSize: 14,
                        color: isSelected ? Colors.red : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          // 상세 내용 (기타 선택 시)
          if (_selectedType == ReportType.other) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _detailController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: '신고 사유를 자세히 적어주세요',
                hintStyle: TextStyle(color: Theme.of(context).colorScheme.outlineVariant, fontSize: 13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red),
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // 제출 버튼
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: (_selectedType != null && !_isSubmitting)
                  ? () async {
                      setState(() => _isSubmitting = true);
                      try {
                        final currentUser = FirebaseAuth.instance.currentUser;
                        if (currentUser == null) throw Exception('로그인이 필요합니다');
                        
                        await _firebase.reportsCollection.add({
                          'reporterId': currentUser.uid,
                          'targetId': widget.targetId,
                          'targetType': widget.targetType.name,
                          'reportType': _selectedType!.name,
                          'detail': _detailController.text.trim(),
                          'status': 'pending',
                          'createdAt': FieldValue.serverTimestamp(),
                        });
                        
                        if (mounted) {
                          Navigator.pop(context);
                          widget.onSubmit?.call();
                          MingrrSnackBar.success(context, '신고가 접수되었습니다. 검토 후 조치하겠습니다.');
                        }
                      } catch (e) {
                        if (mounted) {
                          MingrrSnackBar.error(context, '신고 실패: $e');
                        }
                      } finally {
                        if (mounted) setState(() => _isSubmitting = false);
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                disabledBackgroundColor: Theme.of(context).colorScheme.outline,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                '신고하기',
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

/// 신고 바텀시트 표시 함수
void showReportSheet(
  BuildContext context, {
  required String targetId,
  required String targetName,
  required ReportTargetType targetType,
  VoidCallback? onSubmit,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => ReportSheet(
      targetId: targetId,
      targetName: targetName,
      targetType: targetType,
      onSubmit: onSubmit,
    ),
  );
}
