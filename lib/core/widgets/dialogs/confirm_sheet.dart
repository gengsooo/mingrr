import 'package:flutter/material.dart';
import '../../theme/feature_colors.dart';
import '../../constants/app_sizes.dart';

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
  groupLeave(Icons.exit_to_app, '모임 탈퇴', '정말 이 모임에서 탈퇴하시겠습니까?\n탈퇴 후에는 다시 가입 신청이 필요합니다.', '탈퇴하기'),
  groupDelete(Icons.delete_outline, '모임 삭제', '정말 이 모임을 삭제하시겠습니까?\n삭제된 모임은 복구할 수 없습니다.', '삭제하기'),
  groupJoin(Icons.group_add, '모임 가입', '이 모임에 가입하시겠습니까?', '가입하기'),
  
  // 마켓플레이스 관련
  productDelete(Icons.delete_outline, '상품 삭제', '정말 이 상품을 삭제하시겠습니까?\n삭제된 상품은 복구할 수 없습니다.', '삭제하기'),
  productTypeChange(Icons.swap_horiz, '종류 변경', '종류를 변경하면 현재 입력된 정보가 초기화됩니다.\n계속하시겠습니까?', '변경'),
  
  // 데이팅 관련
  dateCancel(Icons.favorite_border, '데이트 신청 취소', '정말 데이트 신청을 취소하시겠습니까?', '취소하기'),
  breedingCancel(Icons.pets, '교배 신청 취소', '정말 교배 신청을 취소하시겠습니까?', '취소하기'),
  
  // 알바 관련
  jobDelete(Icons.delete_outline, '알바 삭제', '정말 이 알바 글을 삭제하시겠습니까?\n삭제된 글은 복구할 수 없습니다.', '삭제하기'),
  jobCancel(Icons.cancel_outlined, '알바 신청 취소', '정말 알바 신청을 취소하시겠습니까?', '취소하기'),
  
  // 채팅 관련
  chatLeave(Icons.exit_to_app, '채팅방 나가기', '정말 이 채팅방을 나가시겠습니까?\n대화 내용은 삭제됩니다.', '나가기'),
  
  // 반려동물 관련
  petDelete(Icons.pets, '반려동물 삭제', '정말 이 반려동물 정보를 삭제하시겠습니까?\n관련된 모든 데이터가 삭제됩니다.', '삭제하기'),
  photoDelete(Icons.photo_outlined, '사진 삭제', '이 사진을 삭제하시겠습니까?', '삭제하기'),
  
  // 건강수첩 관련
  healthRecordDelete(Icons.delete_outline, '기록 삭제', '정말 이 기록을 삭제하시겠습니까?\n삭제된 기록은 복구할 수 없습니다.', '삭제하기'),
  medicationDelete(Icons.medication_outlined, '약 삭제', '이 약을 삭제하시겠습니까?', '삭제하기'),
  walkRecordDelete(Icons.directions_walk, '산책 기록 삭제', '이 산책 기록을 삭제하시겠습니까?\n삭제된 기록은 복구할 수 없습니다.', '삭제하기'),
  
  // 계정 관련
  accountLogout(Icons.logout, '로그아웃', '정말 로그아웃 하시겠습니까?', '로그아웃'),
  accountDelete(Icons.person_remove, '계정 삭제', '정말 계정을 삭제하시겠습니까?\n모든 데이터가 영구적으로 삭제됩니다.', '삭제하기'),
  
  // 일반
  generalDelete(Icons.delete_outline, '삭제', '정말 삭제하시겠습니까?\n삭제된 항목은 복구할 수 없습니다.', '삭제하기'),
  generalCancel(Icons.cancel_outlined, '취소', '정말 취소하시겠습니까?', '확인'),
  generalConfirm(Icons.check_circle_outline, '확인', '계속 진행하시겠습니까?', '확인');

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
        return Colors.red;
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
                    borderRadius: BorderRadius.circular(AppSizes.bottomSheetHandleHeight / 2),
                  ),
                ),
              ),
              
              // 아이콘
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: type.getColor(context).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(type.icon, size: 32, color: type.getColor(context)),
              ),
              const SizedBox(height: AppSizes.gapM),
              
              // 제목
              Text(
                title ?? type.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: type.getColor(context),
                ),
              ),
              const SizedBox(height: AppSizes.gapS),
              
              // 메시지
              Text(
                message ?? type.message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSizes.gapXL),
              
              // 버튼
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onCancel ?? () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: colorScheme.outline),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        cancelText ?? '취소',
                        style: TextStyle(
                          fontSize: 16,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.gapM),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: type.getColor(context),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        confirmText ?? type.confirmText,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.paddingL),
            ],
          ),
        ),
      ),
    );
  }
}
