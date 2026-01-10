import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
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
  groupLeave(Icons.exit_to_app, AppColors.community, '모임 탈퇴', '정말 이 모임에서 탈퇴하시겠습니까?\n탈퇴 후에는 다시 가입 신청이 필요합니다.', '탈퇴하기'),
  groupDelete(Icons.delete_outline, AppColors.community, '모임 삭제', '정말 이 모임을 삭제하시겠습니까?\n삭제된 모임은 복구할 수 없습니다.', '삭제하기'),
  groupJoin(Icons.group_add, AppColors.community, '모임 가입', '이 모임에 가입하시겠습니까?', '가입하기'),
  
  // 마켓플레이스 관련
  productDelete(Icons.delete_outline, AppColors.market, '상품 삭제', '정말 이 상품을 삭제하시겠습니까?\n삭제된 상품은 복구할 수 없습니다.', '삭제하기'),
  productTypeChange(Icons.swap_horiz, AppColors.market, '종류 변경', '종류를 변경하면 현재 입력된 정보가 초기화됩니다.\n계속하시겠습니까?', '변경'),
  
  // 데이팅 관련
  dateCancel(Icons.favorite_border, AppColors.dating, '데이트 신청 취소', '정말 데이트 신청을 취소하시겠습니까?', '취소하기'),
  breedingCancel(Icons.pets, AppColors.dating, '교배 신청 취소', '정말 교배 신청을 취소하시겠습니까?', '취소하기'),
  
  // 알바 관련
  jobDelete(Icons.delete_outline, AppColors.market, '알바 삭제', '정말 이 알바 글을 삭제하시겠습니까?\n삭제된 글은 복구할 수 없습니다.', '삭제하기'),
  jobCancel(Icons.cancel_outlined, AppColors.market, '알바 신청 취소', '정말 알바 신청을 취소하시겠습니까?', '취소하기'),
  
  // 채팅 관련
  chatLeave(Icons.exit_to_app, AppColors.chat, '채팅방 나가기', '정말 이 채팅방을 나가시겠습니까?\n대화 내용은 삭제됩니다.', '나가기'),
  
  // 반려동물 관련
  petDelete(Icons.pets, AppColors.primary, '반려동물 삭제', '정말 이 반려동물 정보를 삭제하시겠습니까?\n관련된 모든 데이터가 삭제됩니다.', '삭제하기'),
  photoDelete(Icons.photo_outlined, AppColors.primary, '사진 삭제', '이 사진을 삭제하시겠습니까?', '삭제하기'),
  
  // 건강수첩 관련
  healthRecordDelete(Icons.delete_outline, AppColors.health, '기록 삭제', '정말 이 기록을 삭제하시겠습니까?\n삭제된 기록은 복구할 수 없습니다.', '삭제하기'),
  medicationDelete(Icons.medication_outlined, AppColors.health, '약 삭제', '이 약을 삭제하시겠습니까?', '삭제하기'),
  walkRecordDelete(Icons.directions_walk, AppColors.walk, '산책 기록 삭제', '이 산책 기록을 삭제하시겠습니까?\n삭제된 기록은 복구할 수 없습니다.', '삭제하기'),
  
  // 계정 관련
  accountLogout(Icons.logout, AppColors.primary, '로그아웃', '정말 로그아웃 하시겠습니까?', '로그아웃'),
  accountDelete(Icons.person_remove, AppColors.error, '계정 삭제', '정말 계정을 삭제하시겠습니까?\n모든 데이터가 영구적으로 삭제됩니다.', '삭제하기'),
  
  // 일반
  generalDelete(Icons.delete_outline, AppColors.primary, '삭제', '정말 삭제하시겠습니까?\n삭제된 항목은 복구할 수 없습니다.', '삭제하기'),
  generalCancel(Icons.cancel_outlined, AppColors.primary, '취소', '정말 취소하시겠습니까?', '확인'),
  generalConfirm(Icons.check_circle_outline, AppColors.primary, '확인', '계속 진행하시겠습니까?', '확인');

  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final String confirmText;

  const ConfirmSheetType(this.icon, this.color, this.title, this.message, this.confirmText);
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
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 드래그 핸들
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSizes.gapL),
              
              // 아이콘
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: type.color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(type.icon, size: 32, color: type.color),
              ),
              const SizedBox(height: AppSizes.gapM),
              
              // 제목
              Text(
                title ?? type.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: type.color,
                ),
              ),
              const SizedBox(height: AppSizes.gapS),
              
              // 메시지
              Text(
                message ?? type.message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
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
                        side: const BorderSide(color: AppColors.divider),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        cancelText ?? '취소',
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.gapM),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: type.color,
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
            ],
          ),
        ),
      ),
    );
  }
}
