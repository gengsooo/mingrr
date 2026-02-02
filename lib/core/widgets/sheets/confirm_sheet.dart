import 'package:flutter/material.dart';
import '../../constants/app_icons.dart';
import '../../theme/feature_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../constants/app_sizes.dart';
import '../dialogs/dialog_buttons.dart';
import '../common_widgets.dart';

/// ============================================================
/// ConfirmSheet - 확인 바텀시트
/// 
/// 삭제, 탈퇴, 취소 등 중요 동작 확인에 사용
/// 화면 하단에서 올라오는 바텀시트 형태
/// 
/// 사용법:
/// ```dart
/// // 콜백 방식
/// showConfirmSheet(
///   context,
///   type: ConfirmSheetType.productDelete,
///   onConfirm: () => deleteProduct(),
/// );
/// 
/// // 결과 반환 방식
/// final confirmed = await showConfirmSheetWithResult(
///   context,
///   type: ConfirmSheetType.accountLogout,
/// );
/// if (confirmed == true) { ... }
/// ```
/// ============================================================

/// 확인 시트 타입
enum ConfirmSheetType {
  // 소모임 관련
  groupLeave(AppIcons.exit, '모임 탈퇴', '정말 이 모임에서 탈퇴하시겠습니까?\n탈퇴 후에는 다시 가입 신청이 필요합니다.', '탈퇴하기'),
  groupDelete(AppIcons.deleteOutlined, '모임 삭제', '정말 이 모임을 삭제하시겠습니까?\n삭제된 모임은 복구할 수 없습니다.', '삭제하기'),
  groupJoin(AppIcons.groupAdd, '모임 가입', '이 모임에 가입하시겠습니까?', '가입하기'),
  
  // 마켓플레이스 관련
  productDelete(AppIcons.deleteOutlined, '상품 삭제', '정말 이 상품을 삭제하시겠습니까?\n삭제된 상품은 복구할 수 없습니다.', '삭제하기'),
  productTypeChange(AppIcons.swap, '종류 변경', '종류를 변경하면 현재 입력된 정보가 초기화됩니다.\n계속하시겠습니까?', '변경'),
  
  // 데이팅 관련
  dateCancel(AppIcons.datingOutlined, '데이트 신청 취소', '정말 데이트 신청을 취소하시겠습니까?', '취소하기'),
  breedingCancel(AppIcons.breeding, '교배 신청 취소', '정말 교배 신청을 취소하시겠습니까?', '취소하기'),
  
  // 알바 관련
  jobDelete(AppIcons.deleteOutlined, '알바 삭제', '정말 이 알바 글을 삭제하시겠습니까?\n삭제된 글은 복구할 수 없습니다.', '삭제하기'),
  jobCancel(AppIcons.cancel, '알바 신청 취소', '정말 알바 신청을 취소하시겠습니까?', '취소하기'),
  
  // 채팅 관련
  chatLeave(AppIcons.exit, '채팅방 나가기', '정말 이 채팅방을 나가시겠습니까?\n대화 내용은 삭제됩니다.', '나가기'),
  
  // 반려동물 관련
  petDelete(AppIcons.pet, '반려동물 삭제', '정말 이 반려동물 정보를 삭제하시겠습니까?\n관련된 모든 데이터가 삭제됩니다.', '삭제하기'),
  photoDelete(AppIcons.photoOutlined, '사진 삭제', '이 사진을 삭제하시겠습니까?', '삭제하기'),
  
  // 건강수첩 관련
  healthRecordDelete(AppIcons.deleteOutlined, '기록 삭제', '정말 이 기록을 삭제하시겠습니까?\n삭제된 기록은 복구할 수 없습니다.', '삭제하기'),
  medicationDelete(AppIcons.medication, '약 삭제', '이 약을 삭제하시겠습니까?', '삭제하기'),
  walkRecordDelete(AppIcons.walk, '산책 기록 삭제', '이 산책 기록을 삭제하시겠습니까?\n삭제된 기록은 복구할 수 없습니다.', '삭제하기'),
  
  // 계정 관련
  accountLogout(AppIcons.logout, '로그아웃', '정말 로그아웃 하시겠습니까?', '로그아웃'),
  accountDelete(AppIcons.personRemove, '계정 삭제', '정말 계정을 삭제하시겠습니까?\n모든 데이터가 영구적으로 삭제됩니다.', '삭제하기'),
  
  // 일반
  generalDelete(AppIcons.deleteOutlined, '삭제', '정말 삭제하시겠습니까?\n삭제된 항목은 복구할 수 없습니다.', '삭제하기'),
  generalCancel(AppIcons.cancel, '취소', '정말 취소하시겠습니까?', '확인'),
  generalConfirm(AppIcons.successOutlined, '확인', '계속 진행하시겠습니까?', '확인'),
  
  // 차단 관련
  userBlock(AppIcons.block, '사용자 차단', '이 사용자를 차단하시겠습니까?\n차단하면 서로의 게시물과 프로필을 볼 수 없습니다.', '차단하기'),
  sellerBlock(AppIcons.block, '판매자 차단', '이 판매자를 차단하시겠습니까?\n차단하면 서로의 게시물과 프로필을 볼 수 없습니다.', '차단하기'),
  
  // 데이팅 거절
  dateReject(AppIcons.close, '신청 거절', '이 데이팅 신청을 거절하시겠습니까?', '거절하기'),
  
  // 인증 관련
  identityVerify(AppIcons.verified, '본인인증', '본인인증을 진행하시겠습니까?\n※ 실제 서비스에서는 PASS, 카카오 인증 등의 본인인증 서비스가 연동됩니다.', '인증하기');

  final IconData icon;
  final String title;
  final String message;
  final String confirmText;

  const ConfirmSheetType(this.icon, this.title, this.message, this.confirmText);
  
  /// 빌드 시점에 context에서 색상 가져오기
  Color getColor(BuildContext context) {
    final features = context.features;
    switch (this) {
      case ConfirmSheetType.groupLeave:
      case ConfirmSheetType.groupDelete:
      case ConfirmSheetType.groupJoin:
        return features.social;
      case ConfirmSheetType.productDelete:
      case ConfirmSheetType.productTypeChange:
      case ConfirmSheetType.jobDelete:
      case ConfirmSheetType.jobCancel:
        return features.market;
      case ConfirmSheetType.dateCancel:
      case ConfirmSheetType.breedingCancel:
        return features.dating;
      case ConfirmSheetType.chatLeave:
        return features.chat;
      case ConfirmSheetType.healthRecordDelete:
      case ConfirmSheetType.medicationDelete:
        return features.health;
      case ConfirmSheetType.walkRecordDelete:
        return features.walk;
      case ConfirmSheetType.accountDelete:
      case ConfirmSheetType.userBlock:
      case ConfirmSheetType.sellerBlock:
        return Colors.red;
      case ConfirmSheetType.dateReject:
        return features.dating;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }
}

/// 확인 시트 표시 (콜백 방식)
void showConfirmSheet(
  BuildContext context, {
  required ConfirmSheetType type,
  String? title,
  String? message,
  String? confirmText,
  String? cancelText,
  required VoidCallback onConfirm,
  VoidCallback? onCancel,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => ConfirmSheet(
      type: type,
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: cancelText,
      onConfirm: () {
        Navigator.pop(context);
        onConfirm();
      },
      onCancel: () {
        Navigator.pop(context);
        onCancel?.call();
      },
    ),
  );
}

/// 확인 시트 표시 (결과 반환 방식)
Future<bool?> showConfirmSheetWithResult(
  BuildContext context, {
  required ConfirmSheetType type,
  String? title,
  String? message,
  String? confirmText,
  String? cancelText,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => ConfirmSheet(
      type: type,
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: cancelText,
      onConfirm: () => Navigator.pop(context, true),
      onCancel: () => Navigator.pop(context, false),
    ),
  );
}

/// ConfirmSheet 위젯
class ConfirmSheet extends StatelessWidget {
  final ConfirmSheetType type;
  final String? title;
  final String? message;
  final String? confirmText;
  final String? cancelText;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;

  const ConfirmSheet({
    super.key,
    required this.type,
    this.title,
    this.message,
    this.confirmText,
    this.cancelText,
    required this.onConfirm,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.bottomSheetRadius)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 드래그 핸들 (통일된 패딩)
              Padding(
                padding: const EdgeInsets.only(
                  top: AppSizes.bottomSheetHandleTop,
                  bottom: AppSizes.bottomSheetHandleBottom,
                ),
                child: Container(
                  width: AppSizes.bottomSheetHandleWidth,
                  height: AppSizes.bottomSheetHandleHeight,
                  decoration: BoxDecoration(
                    color: colorScheme.outline,
                    borderRadius: BorderRadius.circular(AppSizes.bottomSheetHandleRadius),
                  ),
                ),
              ),
              
              // 아이콘
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: type.getColor(context).withValues(alpha: AppOpacity.o10),
                  shape: BoxShape.circle,
                ),
                child: Icon(type.icon, size: 32, color: type.getColor(context)),
              ),
              const SizedBox(height: AppSizes.gapM),
              
              // 제목
              Text(
                title ?? type.title,
                style: AppTextStyles.headlineSmall(context).copyWith(
                  color: type.getColor(context),
                ),
              ),
              const SizedBox(height: AppSizes.gapS),
              
              // 메시지
              Text(
                message ?? type.message,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium(context).copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSizes.gapXL),
              
              // 버튼
              MingrrDialogButtons(
                cancelText: cancelText ?? '취소',
                confirmText: confirmText ?? type.confirmText,
                onCancel: onCancel ?? () => Navigator.pop(context),
                onConfirm: onConfirm,
                confirmColor: type.getColor(context),
                height: 52,
              ),
              const SizedBox(height: AppSizes.paddingL),
            ],
          ),
        ),
      ),
    );
  }
}
