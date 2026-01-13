import 'package:flutter/material.dart';
import '../constants/app_sizes.dart';

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
      child: child,
    ),
  );
}

/// 바텀시트 컨테이너 위젯
class MingrrBottomSheet extends StatelessWidget {
  final Widget child;
  final bool showHandle;
  final double? height;
  final EdgeInsets? padding;
  final double borderRadius;
  final bool useListTilePadding; // ListTile 사용 시 true (전체 패딩 없음)

  const MingrrBottomSheet({
    super.key,
    required this.child,
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
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
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
///         SizedBox(width: 12),
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
            color: Colors.black.withOpacity(0.05),
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
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor ?? theme.colorScheme.primary,
            foregroundColor: foregroundColor ?? Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}
