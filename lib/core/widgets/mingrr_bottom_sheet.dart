import 'package:flutter/material.dart';
import '../constants/app_sizes.dart';
import '../theme/app_text_styles.dart';
import 'common_widgets.dart';

/// ============================================================
/// MINGRR 공통 바텀시트 & 하단 버튼 위젯 모음
/// ============================================================
/// 
/// 📌 사용 가이드 (언제 무엇을 사용해야 하는가?)
/// 
/// ┌─────────────────────────────────────────────────────────────┐
/// │ 1. MingrrBottomButtonBar - 상세 화면 하단 고정 버튼         │
/// │    용도: 상세 화면(pet_detail, product_detail 등)의         │
/// │          하단에 고정되는 버튼 영역                          │
/// │    사용처: bottomNavigationBar에 배치                       │
/// │    예시: 채팅하기, 신청하기, 좋아요 버튼 등                  │
/// ├─────────────────────────────────────────────────────────────┤
/// │ 2. MingrrSubmitButtonBar - 등록/수정 화면 제출 버튼         │
/// │    용도: 폼 제출이 필요한 화면의 하단 버튼                   │
/// │    사용처: bottomNavigationBar에 배치                       │
/// │    예시: 등록하기, 수정 완료, 저장하기 버튼                  │
/// ├─────────────────────────────────────────────────────────────┤
/// │ 3. showMingrrOptionsSheet - 더보기 옵션 메뉴                │
/// │    용도: 단순한 옵션 목록 (수정, 삭제, 신고 등)              │
/// │    사용처: AppBar의 더보기 버튼 클릭 시                      │
/// │    예시: 수정하기, 삭제하기, 신고하기 메뉴                   │
/// ├─────────────────────────────────────────────────────────────┤
/// │ 4. showModalBottomSheet 직접 사용 (공통 위젯 사용 X)        │
/// │    용도: 복잡한 UI가 필요한 바텀시트                         │
/// │    - 날짜/시간 선택기 (캘린더 UI)                           │
/// │    - 필터/정렬 (복잡한 로직)                                │
/// │    - 프로필 모달 (복잡한 UI)                                │
/// │    - 평가/신고 (별점, 입력 폼)                              │
/// │    - 위치 선택 (지도 연동)                                  │
/// │    ⚠️ 직접 사용 시 배경색 필수:                             │
/// │       color: Theme.of(context).colorScheme.surface          │
/// └─────────────────────────────────────────────────────────────┘
/// 
/// 📁 현재 사용 중인 파일 목록:
/// - MingrrBottomButtonBar: pet_detail, product_detail, job_detail,
///   community_detail, group_detail, guardian_profile_modal
/// - MingrrSubmitButtonBar: breeding_write, group_write, product_write,
///   pet_edit, profile_edit
/// - showMingrrOptionsSheet: pet_detail, community_detail
/// 
/// ============================================================

/// 바텀시트 표시 헬퍼 함수
Future<T?> showMingrrBottomSheet<T>({
  required BuildContext context,
  required Widget child,
  String? title,
  bool isScrollControlled = false,
  bool showHandle = true,
  bool useSafeArea = true,
  double? height,
  EdgeInsets? padding,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: isScrollControlled,
    useSafeArea: useSafeArea,
    builder: (ctx) => MingrrBottomSheet(
      showHandle: showHandle,
      height: height,
      padding: padding,
      title: title,
      child: child,
    ),
  );
}

/// 바텀시트 컨테이너 위젯
class MingrrBottomSheet extends StatelessWidget {
  final Widget child;
  final String? title;
  final bool showHandle;
  final double? height;
  final EdgeInsets? padding;
  final double borderRadius;
  final bool useListTilePadding; // ListTile 사용 시 true (전체 패딩 없음)

  const MingrrBottomSheet({
    super.key,
    required this.child,
    this.title,
    this.showHandle = true,
    this.height,
    this.padding,
    this.borderRadius = AppSizes.bottomSheetRadius,
    this.useListTilePadding = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    // ListTile 사용 시 좌우 패딩 없음, 하단 SafeArea만 적용
    final effectivePadding = padding ?? (useListTilePadding 
        ? EdgeInsets.only(bottom: bottomPadding)
        : const EdgeInsets.all(AppSizes.paddingL));
    
    return Container(
      height: height,
      padding: effectivePadding,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(borderRadius),
        ),
      ),
      child: Column(
        mainAxisSize: height != null ? MainAxisSize.max : MainAxisSize.min,
        children: [
          if (showHandle) _buildHandle(context),
          if (title != null) ...[
            Text(
              title!,
              style: AppTextStyles.headlineSmall(context),
            ),
            const SizedBox(height: AppSizes.gapM),
          ],
          if (height != null)
            Expanded(child: child)
          else
            child,
        ],
      ),
    );
  }

  /// 드래그 핸들 위젯 (통일된 패딩 적용)
  Widget _buildHandle(BuildContext context) {
    return const BottomSheetHandle();
  }
}

/// 바텀시트 드래그 핸들 위젯 (공통 사용)
/// 
/// 모든 바텀시트에서 통일된 드래그 핸들을 사용하기 위한 위젯
/// 사용법: const BottomSheetHandle()
class BottomSheetHandle extends StatelessWidget {
  const BottomSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSizes.bottomSheetHandleTop,
        bottom: AppSizes.bottomSheetHandleBottom,
      ),
      child: Container(
        width: AppSizes.bottomSheetHandleWidth,
        height: AppSizes.bottomSheetHandleHeight,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.outline,
          borderRadius: BorderRadius.circular(AppSizes.bottomSheetHandleHeight / 2),
        ),
      ),
    );
  }
}

/// ============================================================
/// MingrrOptionsSheet - 더보기 옵션 메뉴 바텀시트
/// ============================================================
/// 
/// 📌 용도: AppBar의 더보기(⋮) 버튼 클릭 시 표시되는 옵션 목록
/// 
/// ✅ 사용 예시:
/// ```dart
/// showMingrrOptionsSheet(
///   context: context,
///   options: [
///     MingrrOptionItem(
///       icon: Icons.edit,
///       label: '수정하기',
///       onTap: () => _onEdit(),
///     ),
///     MingrrOptionItem(
///       icon: Icons.delete,
///       label: '삭제하기',
///       isDestructive: true,  // 빨간색으로 표시
///       onTap: () => _onDelete(),
///     ),
///   ],
/// );
/// ```
/// 
/// 📁 현재 사용처: pet_detail_screen, community_detail_screen
/// ============================================================
class MingrrOptionsSheet extends StatelessWidget {
  final List<MingrrOptionItem> options;
  final String? title;

  const MingrrOptionsSheet({
    super.key,
    required this.options,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    // MingrrBottomSheet를 사용하지 않음 (showMingrrBottomSheet에서 이미 감싸므로)
    return Flexible(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: AppTextStyles.headlineSmall(context),
            ),
            const SizedBox(height: AppSizes.gapM),
          ],
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: options.map((option) {
                  final effectiveColor = option.color ?? (option.isDestructive ? Colors.red : null);
                  return ListTile(
                    leading: Icon(option.icon, color: effectiveColor),
                    title: Text(
                      option.label,
                      style: TextStyle(color: effectiveColor),
                    ),
                    subtitle: option.subtitle != null 
                        ? Text(option.subtitle!, style: Theme.of(context).textTheme.bodySmall)
                        : null,
                    onTap: () {
                      Navigator.pop(context);
                      option.onTap?.call();
                    },
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 옵션 아이템 데이터 클래스
class MingrrOptionItem {
  final IconData icon;
  final String label;
  final String? subtitle; // 부가 설명
  final VoidCallback? onTap;
  final bool isDestructive;
  final Color? color; // 커스텀 색상 (isDestructive보다 우선)

  const MingrrOptionItem({
    required this.icon,
    required this.label,
    this.subtitle,
    this.onTap,
    this.isDestructive = false,
    this.color,
  });
}

/// 옵션 바텀시트 표시 헬퍼 함수
Future<void> showMingrrOptionsSheet({
  required BuildContext context,
  required List<MingrrOptionItem> options,
  String? title,
}) {
  return showMingrrBottomSheet(
    context: context,
    isScrollControlled: true,
    padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
    child: MingrrOptionsSheet(
      options: options,
      title: title,
    ),
  );
}

/// ============================================================
/// showDetailOptionsSheet - 상세 화면 더보기 옵션 헬퍼
/// ============================================================
/// 
/// 📌 용도: 상세 화면의 더보기(⋮) 버튼 클릭 시 표시되는 옵션
/// 
/// ✅ 특징:
/// - 본인 글: 수정/삭제 옵션 표시
/// - 타인 글: 차단/신고 옵션 표시
/// - 추가 옵션 지원 (공유 등)
/// 
/// ✅ 사용 예시:
/// ```dart
/// showDetailOptionsSheet(
///   context: context,
///   isOwner: _isOwner,
///   onEdit: () => _editProduct(),
///   onDelete: () => _confirmDelete(),
///   onBlock: () => _blockUser(),
///   onReport: () => showReportSheet(...),
/// );
/// ```
/// 
/// 📁 사용처: pet_detail, product_detail, job_detail, 
///           community_detail, group_detail
/// ============================================================
Future<void> showDetailOptionsSheet({
  required BuildContext context,
  required bool isOwner,
  VoidCallback? onEdit,
  VoidCallback? onDelete,
  VoidCallback? onBlock,
  VoidCallback? onReport,
  VoidCallback? onShare,
  String? blockLabel,
  String? reportLabel,
  List<MingrrOptionItem>? additionalOptions,
}) {
  final options = <MingrrOptionItem>[];
  
  // 공유 옵션 (항상 표시)
  if (onShare != null) {
    options.add(MingrrOptionItem(
      icon: Icons.share_outlined,
      label: '공유하기',
      onTap: onShare,
    ));
  }
  
  if (isOwner) {
    // 본인 글: 수정/삭제
    if (onEdit != null) {
      options.add(MingrrOptionItem(
        icon: Icons.edit_outlined,
        label: '수정하기',
        onTap: onEdit,
      ));
    }
    if (onDelete != null) {
      options.add(MingrrOptionItem(
        icon: Icons.delete_outline,
        label: '삭제하기',
        isDestructive: true,
        onTap: onDelete,
      ));
    }
  } else {
    // 타인 글: 차단/신고
    if (onBlock != null) {
      options.add(MingrrOptionItem(
        icon: Icons.block_outlined,
        label: blockLabel ?? '차단하기',
        onTap: onBlock,
      ));
    }
    if (onReport != null) {
      options.add(MingrrOptionItem(
        icon: Icons.report_outlined,
        label: reportLabel ?? '신고하기',
        isDestructive: true,
        onTap: onReport,
      ));
    }
  }
  
  // 추가 옵션
  if (additionalOptions != null) {
    options.addAll(additionalOptions);
  }
  
  return showMingrrOptionsSheet(context: context, options: options);
}

/// ============================================================
/// MingrrBottomButtonBar - 상세 화면 하단 고정 버튼 영역
/// ============================================================
/// 
/// 📌 용도: 상세 화면(pet_detail, product_detail 등)의 하단 고정 버튼
/// 
/// ✅ 특징:
/// - 자동 다크모드 대응 (colorScheme.surface)
/// - SafeArea 패딩 자동 적용 (홈 버튼 영역 고려)
/// - 상단 그림자 효과
/// 
/// ✅ 사용 예시:
/// ```dart
/// Scaffold(
///   body: ...,
///   bottomNavigationBar: MingrrBottomButtonBar(
///     child: Row(
///       children: [
///         Expanded(child: ElevatedButton(...)),  // 채팅하기
///         const SizedBox(width: AppSizes.gapM),
///         ElevatedButton(...),  // 좋아요
///       ],
///     ),
///   ),
/// )
/// ```
/// 
/// 📁 현재 사용처: pet_detail, product_detail, job_detail,
///                community_detail, group_detail, guardian_profile_modal
/// ============================================================
class MingrrBottomButtonBar extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final bool showShadow;

  const MingrrBottomButtonBar({
    super.key,
    required this.child,
    this.padding,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return Container(
      padding: padding ?? EdgeInsets.only(
        left: AppSizes.paddingL,
        right: AppSizes.paddingL,
        top: AppSizes.paddingM,
        bottom: bottomPadding + AppSizes.paddingM,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: showShadow ? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ] : null,
      ),
      child: child,
    );
  }
}

/// ============================================================
/// MingrrSubmitButtonBar - 등록/수정 화면 제출 버튼
/// ============================================================
/// 
/// 📌 용도: 폼 제출이 필요한 화면(등록, 수정)의 하단 버튼
/// 
/// ✅ 특징:
/// - MingrrBottomButtonBar 기반 (다크모드, SafeArea 자동 적용)
/// - 로딩 상태 지원 (isLoading)
/// - 버튼 색상 커스터마이징 가능
/// 
/// ✅ 사용 예시:
/// ```dart
/// Scaffold(
///   body: Form(...),
///   bottomNavigationBar: MingrrSubmitButtonBar(
///     label: '등록하기',  // 또는 '수정 완료', '저장하기'
///     isLoading: _isLoading,
///     onPressed: _isValid ? _onSubmit : null,  // null이면 비활성화
///     backgroundColor: context.features.market,  // 선택: 기능별 색상
///   ),
/// )
/// ```
/// 
/// 📁 현재 사용처: breeding_write, group_write, product_write,
///                pet_edit, profile_edit
/// ============================================================
class MingrrSubmitButtonBar extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const MingrrSubmitButtonBar({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return MingrrBottomButtonBar(
      child: MingrrButton(
        text: label,
        onPressed: onPressed,
        isLoading: isLoading,
        backgroundColor: backgroundColor ?? theme.colorScheme.primary,
        textColor: foregroundColor ?? Colors.white,
        height: 52,
      ),
    );
  }
}

/// ============================================================
/// MingrrInputBottomSheet - 텍스트 입력이 있는 바텀시트
/// ============================================================
/// 
/// 📌 용도: TextField가 포함된 바텀시트 (키보드 가림 문제 해결)
/// 
/// ✅ 특징:
/// - 키보드가 올라와도 저장 버튼이 키보드 위에 표시
/// - 스크롤 가능한 콘텐츠 영역
/// - 자동 다크모드 대응
/// 
/// ✅ 사용 예시:
/// ```dart
/// MingrrInputBottomSheet.show(
///   context: context,
///   title: '체중 기록',
///   buttonLabel: '저장',
///   buttonColor: context.features.health,
///   onSave: () => _saveRecord(),
///   child: Column(children: [...]),
/// );
/// ```
/// 
/// 📁 사용처: health_record_add_screens, report_sheet, request_sheet
/// ============================================================
class MingrrInputBottomSheet extends StatelessWidget {
  final String title;
  final Widget child;
  final String? buttonLabel;
  final VoidCallback? onSave;
  final Color? buttonColor;
  final bool isLoading;
  final Widget? customButton; // 커스텀 버튼 (취소/확인 등)
  final Widget? headerIcon; // 헤더 아이콘 (신고, 신청 등)
  final String? subtitle; // 부제목/설명

  const MingrrInputBottomSheet({
    super.key,
    required this.title,
    required this.child,
    this.onSave,
    this.buttonLabel = '저장',
    this.buttonColor,
    this.isLoading = false,
    this.customButton,
    this.headerIcon,
    this.subtitle,
  });

  /// 바텀시트 표시 헬퍼 함수 (기본 버튼)
  static void show({
    required BuildContext context,
    required String title,
    required Widget child,
    required VoidCallback onSave,
    String buttonLabel = '저장',
    Color? buttonColor,
    bool isLoading = false,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MingrrInputBottomSheet(
        title: title,
        buttonLabel: buttonLabel,
        buttonColor: buttonColor,
        onSave: onSave,
        isLoading: isLoading,
        child: child,
      ),
    );
  }

  /// 바텀시트 표시 헬퍼 함수 (커스텀 버튼)
  static void showWithCustomButton({
    required BuildContext context,
    required String title,
    required Widget child,
    required Widget customButton,
    Widget? headerIcon,
    String? subtitle,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MingrrInputBottomSheet(
        title: title,
        customButton: customButton,
        headerIcon: headerIcon,
        subtitle: subtitle,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final effectiveButtonColor = buttonColor ?? Theme.of(context).colorScheme.primary;
    
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSizes.bottomSheetRadius)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BottomSheetHandle(),
          // 헤더 (아이콘 + 제목 + 부제목)
          _buildHeader(context),
          // 컨텐츠 (스크롤 가능)
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppSizes.bottomSheetButtonPaddingH,
                AppSizes.paddingM,
                AppSizes.bottomSheetButtonPaddingH,
                AppSizes.bottomSheetButtonPaddingH,
              ),
              child: child,
            ),
          ),
          // 하단 버튼 영역 (키보드 위에 고정)
          _buildButtonArea(context, keyboardHeight, bottomPadding, effectiveButtonColor),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSizes.bottomSheetButtonPaddingH,
        AppSizes.paddingS,
        AppSizes.bottomSheetButtonPaddingH,
        subtitle != null ? AppSizes.paddingXS : AppSizes.paddingS,
      ),
      child: Column(
        children: [
          // 아이콘 (선택)
          if (headerIcon != null) ...[
            headerIcon!,
            const SizedBox(height: AppSizes.gapM),
          ],
          // 제목
          Text(
            title,
            style: AppTextStyles.headlineSmall(context),
            textAlign: TextAlign.center,
          ),
          // 부제목 (선택)
          if (subtitle != null) ...[
            const SizedBox(height: AppSizes.gapXS),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: AppTextStyles.secondary(context).copyWith(height: 1.4),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildButtonArea(BuildContext context, double keyboardHeight, double bottomPadding, Color effectiveButtonColor) {
    return Container(
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: customButton ?? _buildDefaultButton(context, effectiveButtonColor),
    );
  }

  Widget _buildDefaultButton(BuildContext context, Color effectiveButtonColor) {
    return MingrrButton(
      text: buttonLabel ?? '저장',
      onPressed: onSave,
      isLoading: isLoading,
      backgroundColor: effectiveButtonColor,
      textColor: Colors.white,
      height: 50,
    );
  }
}
