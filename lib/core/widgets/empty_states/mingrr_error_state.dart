import 'package:flutter/material.dart';
import '../../constants/app_icons.dart';
import '../../constants/app_sizes.dart';
import '../../theme/app_text_styles.dart';

// ===== 에러 상태 타입 열거형 =====
/// MingrrErrorState 위젯에서 사용하는 에러 종류
enum ErrorStateType {
  /// 기본 에러 (알 수 없는 오류)
  unknown,
  /// 네트워크 연결 에러
  network,
  /// 서버 에러 (500번대)
  server,
  /// 인증 에러 (로그인 필요)
  auth,
  /// 권한 에러
  permission,
  /// 데이터 없음
  empty,
  /// 찾을 수 없음 (404)
  notFound,
  /// 시간 초과
  timeout,
  /// 로딩 실패
  loadFailed,
}

// ===== 공통 에러 상태 위젯 =====
/// 에러 발생 시 표시하는 위젯
/// 
/// 사용 예시:
/// ```dart
/// // 기본 사용
/// MingrrErrorState(onRetry: () => ref.refresh(provider))
/// 
/// // 타입 지정
/// MingrrErrorState.network(onRetry: () => ref.refresh(provider))
/// 
/// // 커스텀 메시지
/// MingrrErrorState(
///   title: '커스텀 제목',
///   subtitle: '커스텀 부제목',
///   onRetry: () => ref.refresh(provider),
/// )
/// ```
class MingrrErrorState extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final String? buttonText;
  final VoidCallback? onRetry;
  final IconData? icon;
  final ErrorStateType errorType;

  const MingrrErrorState({
    super.key,
    this.title,
    this.subtitle,
    this.buttonText,
    this.onRetry,
    this.icon,
    this.errorType = ErrorStateType.unknown,
  });

  /// 네트워크 에러 상태
  const MingrrErrorState.network({
    super.key,
    this.onRetry,
    this.buttonText,
  }) : title = null,
       subtitle = null,
       icon = AppIcons.wifiOff,
       errorType = ErrorStateType.network;

  /// 서버 에러 상태
  const MingrrErrorState.server({
    super.key,
    this.onRetry,
    this.buttonText,
  }) : title = null,
       subtitle = null,
       icon = AppIcons.cloudOff,
       errorType = ErrorStateType.server;

  /// 인증 필요 상태
  const MingrrErrorState.auth({
    super.key,
    this.onRetry,
    this.buttonText,
  }) : title = null,
       subtitle = null,
       icon = AppIcons.lock,
       errorType = ErrorStateType.auth;

  /// 권한 필요 상태
  const MingrrErrorState.permission({
    super.key,
    this.onRetry,
    this.buttonText,
  }) : title = null,
       subtitle = null,
       icon = AppIcons.security,
       errorType = ErrorStateType.permission;

  /// 데이터 없음 상태
  const MingrrErrorState.empty({
    super.key,
    this.title,
    this.subtitle,
    this.onRetry,
    this.buttonText,
    this.icon,
  }) : errorType = ErrorStateType.empty;

  /// 찾을 수 없음 상태
  const MingrrErrorState.notFound({
    super.key,
    this.onRetry,
    this.buttonText,
  }) : title = null,
       subtitle = null,
       icon = AppIcons.searchOff,
       errorType = ErrorStateType.notFound;

  /// 시간 초과 상태
  const MingrrErrorState.timeout({
    super.key,
    this.onRetry,
    this.buttonText,
  }) : title = null,
       subtitle = null,
       icon = AppIcons.timerOff,
       errorType = ErrorStateType.timeout;

  /// 로딩 실패 상태
  const MingrrErrorState.loadFailed({
    super.key,
    this.onRetry,
    this.buttonText,
  }) : title = null,
       subtitle = null,
       icon = AppIcons.refresh,
       errorType = ErrorStateType.loadFailed;

  // 에러 타입별 기본 제목
  String _getDefaultTitle() {
    switch (errorType) {
      case ErrorStateType.network:
        return '인터넷 연결을 확인해주세요';
      case ErrorStateType.server:
        return '서버에 문제가 발생했어요';
      case ErrorStateType.auth:
        return '로그인이 필요해요';
      case ErrorStateType.permission:
        return '권한이 필요해요';
      case ErrorStateType.empty:
        return '데이터가 없어요';
      case ErrorStateType.notFound:
        return '요청한 정보를 찾을 수 없어요';
      case ErrorStateType.timeout:
        return '응답 시간이 초과되었어요';
      case ErrorStateType.loadFailed:
        return '불러오기에 실패했어요';
      case ErrorStateType.unknown:
        return '일시적인 오류가 발생했어요';
    }
  }

  // 에러 타입별 기본 부제목
  String _getDefaultSubtitle() {
    switch (errorType) {
      case ErrorStateType.network:
        return 'Wi-Fi 또는 모바일 데이터 연결 상태를 확인해주세요';
      case ErrorStateType.server:
        return '잠시 후 다시 시도해주세요';
      case ErrorStateType.auth:
        return '로그인 후 이용해주세요';
      case ErrorStateType.permission:
        return '설정에서 권한을 허용해주세요';
      case ErrorStateType.empty:
        return '아직 등록된 내용이 없습니다';
      case ErrorStateType.notFound:
        return '삭제되었거나 존재하지 않는 정보입니다';
      case ErrorStateType.timeout:
        return '네트워크 상태를 확인하고 다시 시도해주세요';
      case ErrorStateType.loadFailed:
        return '잠시 후 다시 시도해주세요';
      case ErrorStateType.unknown:
        return '잠시 후 다시 시도해주세요';
    }
  }

  // 에러 타입별 기본 버튼 텍스트
  String _getDefaultButtonText() {
    switch (errorType) {
      case ErrorStateType.auth:
        return '로그인하기';
      case ErrorStateType.permission:
        return '설정으로 이동';
      default:
        return '다시 시도';
    }
  }

  // 에러 타입별 기본 아이콘
  IconData _getDefaultIcon() {
    switch (errorType) {
      case ErrorStateType.network:
        return AppIcons.wifiOff;
      case ErrorStateType.server:
        return AppIcons.cloudOff;
      case ErrorStateType.auth:
        return AppIcons.lock;
      case ErrorStateType.permission:
        return AppIcons.security;
      case ErrorStateType.empty:
        return AppIcons.inbox;
      case ErrorStateType.notFound:
        return AppIcons.searchOff;
      case ErrorStateType.timeout:
        return AppIcons.timerOff;
      case ErrorStateType.loadFailed:
        return AppIcons.refresh;
      case ErrorStateType.unknown:
        return AppIcons.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveTitle = title ?? _getDefaultTitle();
    final effectiveSubtitle = subtitle ?? _getDefaultSubtitle();
    final effectiveButtonText = buttonText ?? _getDefaultButtonText();
    final effectiveIcon = icon ?? _getDefaultIcon();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              effectiveIcon,
              size: 64,
              color: colorScheme.outlineVariant,
            ),
            const SizedBox(height: AppSizes.gapL),
            Text(
              effectiveTitle,
              style: AppTextStyles.titleMedium(context).copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.gapS),
            Text(
              effectiveSubtitle,
              style: AppTextStyles.bodySmall(context).copyWith(
                color: colorScheme.outlineVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSizes.gapXL),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingL,
                    vertical: AppSizes.paddingM,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusS),
                  ),
                ),
                child: Text(effectiveButtonText),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
