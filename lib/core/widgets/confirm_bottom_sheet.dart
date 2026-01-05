import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

/// ============================================================
/// 공통 확인 바텀시트 모달
/// 삭제, 탈퇴, 취소 등 중요 동작 확인에 사용
/// 각 메뉴별 테마 색상을 적용하여 통일감 있는 디자인
/// 
/// 사용법:
/// ```dart
/// // 콜백 방식
/// showConfirmBottomSheet(
///   context,
///   type: ConfirmType.groupLeave,
///   onConfirm: () => doSomething(),
/// );
/// 
/// // 결과 반환 방식
/// final confirmed = await showConfirmBottomSheetWithResult(
///   context,
///   type: ConfirmType.productTypeChange,
/// );
/// ```
/// ============================================================

/// 확인 타입 - enum에 설정값을 직접 정의하여 단일 소스로 관리
enum ConfirmType {
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

  const ConfirmType(this.icon, this.color, this.title, this.message, this.confirmText);
}

class ConfirmBottomSheet extends StatelessWidget {
  final ConfirmType type;
  final String? title;
  final String? message;
  final String? confirmText;
  final String? cancelText;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;

  const ConfirmBottomSheet({
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
    return _ConfirmBottomSheetContent(
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
    );
  }
}

/// 공통 바텀시트 콘텐츠 위젯 (재사용)
class _ConfirmBottomSheetContent extends StatelessWidget {
  final ConfirmType type;
  final String? title;
  final String? message;
  final String? confirmText;
  final String? cancelText;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _ConfirmBottomSheetContent({
    required this.type,
    this.title,
    this.message,
    this.confirmText,
    this.cancelText,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingL),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXL)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 핸들
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
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: type.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(type.icon, size: 28, color: type.color),
          ),
          const SizedBox(height: AppSizes.gapM),
          
          // 제목
          Text(
            title ?? type.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSizes.gapXS),
          
          // 설명
          Text(
            message ?? type.message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSizes.gapXL),
          
          // 버튼
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.divider),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    cancelText ?? '취소',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
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
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    confirmText ?? type.confirmText,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}

/// 확인 바텀시트 표시 헬퍼 함수
Future<void> showConfirmBottomSheet(
  BuildContext context, {
  required ConfirmType type,
  String? title,
  String? message,
  String? confirmText,
  String? cancelText,
  required VoidCallback onConfirm,
  VoidCallback? onCancel,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => ConfirmBottomSheet(
      type: type,
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: cancelText,
      onConfirm: onConfirm,
      onCancel: onCancel,
    ),
  );
}

/// 결과를 반환하는 확인 바텀시트 (await 가능)
Future<bool?> showConfirmBottomSheetWithResult(
  BuildContext context, {
  required ConfirmType type,
  String? title,
  String? message,
  String? confirmText,
  String? cancelText,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => _ConfirmBottomSheetContent(
      type: type,
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: cancelText,
      onConfirm: () => Navigator.pop(ctx, true),
      onCancel: () => Navigator.pop(ctx, false),
    ),
  );
}
