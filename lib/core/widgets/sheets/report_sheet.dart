import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants/app_icons.dart';
import '../../constants/app_sizes.dart';
import '../../theme/app_text_styles.dart';
import '../../services/firebase_service.dart';
import '../common_widgets.dart';
import 'mingrr_bottom_sheet.dart';
import '../../utils/responsive_utils.dart';
import '../../utils/error_handler.dart';

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
    final keyboardHeight = ResponsiveUtils.keyboardHeight(context);
    final bottomPadding = ResponsiveUtils.bottomSafeArea(context);
    
    return Container(
      constraints: BoxConstraints(
        maxHeight: ResponsiveUtils.maxSheetHeight(context),
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSizes.radiusL)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Center(child: BottomSheetHandle()),
          // 스크롤 가능한 콘텐츠 영역
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSizes.gapM),
                  Row(
                    children: [
                      Icon(AppIcons.report, color: Theme.of(context).colorScheme.error),
                      const SizedBox(width: AppSizes.gapS),
                      Text(
                        '${widget.targetName} 신고하기',
                        style: AppTextStyles.headlineMedium(context).withWeight(FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.gapS),
                  Text(
                    '신고 사유를 선택해주세요. 허위 신고 시 제재를 받을 수 있습니다.',
                    style: AppTextStyles.bodyMedium(context).withColor(Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppSizes.gapL),

                  // 신고 유형 선택
                  ...ReportType.values.map((type) {
                    final isSelected = _selectedType == type;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedType = type),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: AppSizes.paddingS),
                        padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL, vertical: AppSizes.paddingM),
                        decoration: BoxDecoration(
                          color: isSelected ? Theme.of(context).colorScheme.error.withValues(alpha: AppOpacity.o10) : Colors.transparent,
                          borderRadius: BorderRadius.circular(AppSizes.radiusS),
                          border: Border.all(
                            color: isSelected ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected ? AppIcons.checkCircle : AppIcons.circleOutlined,
                              size: 20,
                              color: isSelected ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.outlineVariant,
                            ),
                            const SizedBox(width: AppSizes.gapM),
                            Text(
                              type.label,
                              style: AppTextStyles.bodyLarge(context).withColor(
                                isSelected ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  // 상세 내용 (기타 선택 시)
                  if (_selectedType == ReportType.other) ...[
                    const SizedBox(height: AppSizes.gapM),
                    TextField(
                      controller: _detailController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: '신고 사유를 자세히 적어주세요',
                        hintStyle: AppTextStyles.bodySmall(context).copyWith(color: Theme.of(context).colorScheme.outlineVariant),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radiusS),
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radiusS),
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSizes.gapL),
                ],
              ),
            ),
          ),
          // 제출 버튼 (키보드 위에 고정)
          Container(
            padding: EdgeInsets.only(
              left: AppSizes.bottomSheetButtonPaddingH,
              right: AppSizes.bottomSheetButtonPaddingH,
              top: AppSizes.bottomSheetButtonPaddingV,
              bottom: keyboardHeight > 0 
                  ? keyboardHeight + AppSizes.bottomSheetButtonPaddingV 
                  : bottomPadding + AppSizes.bottomSheetButtonPaddingV,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: AppShadows.shadowL(Theme.of(context).brightness == Brightness.dark),
            ),
            child: MingrrButton(
              text: '신고하기',
              isLoading: _isSubmitting,
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
                        
                        if (!context.mounted) return;
                        MingrrSnackBar.success(context, '신고가 접수되었습니다. 검토 후 조치하겠습니다.');
                        Navigator.pop(context);
                        widget.onSubmit?.call();
                      } catch (e) {
                        if (!context.mounted) return;
                        ErrorHandler.showError(context, e, tag: 'Report', operation: '신고 제출');
                      } finally {
                        if (context.mounted) setState(() => _isSubmitting = false);
                      }
                    }
                  : null,
              backgroundColor: Theme.of(context).colorScheme.error,
              textColor: Colors.white,
              height: 52,
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
