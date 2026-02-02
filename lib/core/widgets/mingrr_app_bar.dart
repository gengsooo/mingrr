import 'package:flutter/material.dart';
import '../constants/app_icons.dart';
import '../constants/app_sizes.dart';
import '../theme/app_theme.dart';

/// ============================================================
/// MINGRR 공통 AppBar 컴포넌트
/// 
/// 앱 전체에서 일관된 네비게이션 경험을 제공
/// 
/// ## 업계 표준 가이드라인
/// - **back (←)**: 일반 네비게이션, 이전 화면으로 돌아감
/// - **close (X)**: 모달/바텀시트/풀스크린 오버레이 닫기
/// 
/// ## Named Constructors
/// - `MingrrAppBar()` - 일반 화면 (뒤로가기 버튼)
/// - `MingrrAppBar.mainTab()` - 메인 탭 화면 (leading 없음)
/// - `MingrrAppBar.form()` - 작성/수정 화면 (닫기 버튼)
/// - `MingrrAppBar.dark()` - 풀스크린 다크 UI (이미지/동영상 뷰어)
/// - `MingrrAppBar.search()` - 검색 화면 (검색바 + 취소)
/// 
/// ## 사용 예시
/// ```dart
/// // 일반 화면 (뒤로가기)
/// MingrrAppBar(title: '설정')
/// 
/// // 메인 탭 (leading 없음)
/// MingrrAppBar.mainTab(title: '마켓', actions: [...])
/// 
/// // 작성 화면 (닫기)
/// MingrrAppBar.form(title: '글 작성', onClose: () => Navigator.pop(context))
/// 
/// // 풀스크린 다크 UI
/// MingrrAppBar.dark(title: '1 / 5')
/// 
/// // 검색 화면
/// MingrrAppBar.search(searchWidget: MingrrSearchBar(...), onCancel: ...)
/// ```
/// ============================================================

/// 네비게이션 버튼 타입
enum LeadingType {
  /// 뒤로가기 (←) - 일반 네비게이션
  back,
  /// 닫기 (X) - 모달/오버레이 종료
  close,
  /// 없음 - leading 버튼 숨김
  none,
}

/// 공통 AppBar 위젯
/// 
/// 앱 전체에서 일관된 AppBar 스타일을 제공합니다.
/// 용도에 맞는 Named constructor를 사용하세요.
class MingrrAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// AppBar 제목
  final String? title;
  
  /// 제목 위젯 (title보다 우선)
  final Widget? titleWidget;
  
  /// leading 버튼 타입 (back/close/none)
  final LeadingType leadingType;
  
  /// leading 버튼 커스텀 콜백 (null이면 Navigator.pop)
  final VoidCallback? onLeadingPressed;
  
  /// 커스텀 leading 위젯 (leadingType보다 우선)
  final Widget? leading;
  
  /// 우측 액션 버튼들
  final List<Widget>? actions;
  
  /// 제목 중앙 정렬 여부
  final bool centerTitle;
  
  /// 배경색 (null이면 테마 기본값)
  final Color? backgroundColor;
  
  /// 아이콘 테마 (다크 모드용)
  final IconThemeData? iconTheme;
  
  /// 제목 스타일 (다크 모드용)
  final TextStyle? titleTextStyle;
  
  /// elevation
  final double elevation;
  
  /// scrolledUnderElevation
  final double? scrolledUnderElevation;
  
  /// bottom 위젯 (TabBar 등)
  final PreferredSizeWidget? bottom;
  
  /// flexibleSpace 위젯
  final Widget? flexibleSpace;
  
  /// titleSpacing
  final double? titleSpacing;
  
  /// automaticallyImplyLeading
  final bool automaticallyImplyLeading;

  /// 기본 생성자 - 일반 화면 (뒤로가기 버튼)
  const MingrrAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.leadingType = LeadingType.back,
    this.onLeadingPressed,
    this.leading,
    this.actions,
    this.centerTitle = true,
    this.backgroundColor,
    this.iconTheme,
    this.titleTextStyle,
    this.elevation = 0,
    this.scrolledUnderElevation,
    this.bottom,
    this.flexibleSpace,
    this.titleSpacing,
    this.automaticallyImplyLeading = true,
  });
  
  /// 메인 탭 화면용 (leading 없음)
  /// 
  /// 홈, 데이팅, 마켓, 소셜, 채팅 등 메인 탭에서 사용
  const MingrrAppBar.mainTab({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.centerTitle = true,
    this.backgroundColor,
    this.elevation = 0,
    this.scrolledUnderElevation,
    this.bottom,
  }) : leadingType = LeadingType.none,
       onLeadingPressed = null,
       leading = null,
       iconTheme = null,
       titleTextStyle = null,
       flexibleSpace = null,
       titleSpacing = null,
       automaticallyImplyLeading = false;
  
  /// 작성/수정 화면용 (닫기 버튼)
  /// 
  /// 글 작성, 상품 등록, 프로필 수정 등에서 사용
  const MingrrAppBar.form({
    super.key,
    required this.title,
    required VoidCallback onClose,
    this.actions,
    this.centerTitle = true,
    this.backgroundColor,
    this.elevation = 0,
  }) : titleWidget = null,
       leadingType = LeadingType.close,
       onLeadingPressed = onClose,
       leading = null,
       iconTheme = null,
       titleTextStyle = null,
       scrolledUnderElevation = null,
       bottom = null,
       flexibleSpace = null,
       titleSpacing = null,
       automaticallyImplyLeading = true;
  
  /// 풀스크린 다크 UI용 (이미지/동영상 뷰어)
  /// 
  /// 검정 배경에 흰색 아이콘/텍스트
  const MingrrAppBar.dark({
    super.key,
    this.title,
    this.titleWidget,
    this.leadingType = LeadingType.back,
    this.onLeadingPressed,
    this.actions,
    this.centerTitle = true,
  }) : leading = null,
       backgroundColor = Colors.black,
       iconTheme = const IconThemeData(color: Colors.white),
       titleTextStyle = const TextStyle(color: Colors.white),
       elevation = 0,
       scrolledUnderElevation = null,
       bottom = null,
       flexibleSpace = null,
       titleSpacing = null,
       automaticallyImplyLeading = true;
  
  /// 검색 화면용 (검색바 + 취소 버튼)
  /// 
  /// 검색 화면에서 사용, title 대신 searchWidget 사용
  /// onCancel은 취소 버튼 클릭 시 호출됨
  MingrrAppBar.search({
    super.key,
    required Widget searchWidget,
    required VoidCallback onCancel,
    this.backgroundColor,
    this.elevation = 0,
  }) : title = null,
       titleWidget = searchWidget,
       leadingType = LeadingType.none,
       onLeadingPressed = null,
       leading = null,
       actions = [
         Builder(
           builder: (context) => TextButton(
             onPressed: onCancel,
             child: Text(
               '취소',
               style: TextStyle(
                 color: Theme.of(context).colorScheme.onSurfaceVariant,
               ),
             ),
           ),
         ),
       ],
       centerTitle = false,
       iconTheme = null,
       titleTextStyle = null,
       scrolledUnderElevation = null,
       bottom = null,
       flexibleSpace = null,
       titleSpacing = 0,
       automaticallyImplyLeading = false;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: titleWidget ?? (title != null ? Text(title!) : null),
      centerTitle: centerTitle,
      backgroundColor: backgroundColor,
      iconTheme: iconTheme,
      titleTextStyle: titleTextStyle,
      elevation: elevation,
      scrolledUnderElevation: scrolledUnderElevation,
      leading: leading ?? _buildLeading(context),
      actions: actions,
      bottom: bottom,
      flexibleSpace: flexibleSpace,
      titleSpacing: titleSpacing,
      automaticallyImplyLeading: automaticallyImplyLeading,
    );
  }

  Widget? _buildLeading(BuildContext context) {
    if (leadingType == LeadingType.none) return null;
    
    return IconButton(
      icon: Icon(
        leadingType == LeadingType.close ? AppIcons.close : AppIcons.back,
        size: 20,
      ),
      onPressed: onLeadingPressed ?? () => Navigator.pop(context),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
    kToolbarHeight + (bottom?.preferredSize.height ?? 0),
  );
}

/// 공통 Leading 버튼 위젯
/// 
/// AppBar 외부에서 독립적으로 사용할 수 있는 네비게이션 버튼입니다.
/// 예: CustomScrollView의 Stack 위에 배치, 이미지 위 오버레이 등
/// 
/// [MingrrBackButton]을 대체합니다.
class MingrrLeadingButton extends StatelessWidget {
  /// 버튼 타입 (back/close)
  final LeadingType type;
  
  /// 버튼 클릭 콜백 (null이면 Navigator.pop)
  final VoidCallback? onPressed;
  
  /// 배경색 (null이면 surface)
  final Color? backgroundColor;
  
  /// 아이콘 색상 (null이면 onSurface)
  final Color? iconColor;
  
  /// 그림자 표시 여부
  final bool showShadow;
  
  /// 버튼 크기
  final double size;

  const MingrrLeadingButton({
    super.key,
    this.type = LeadingType.back,
    this.onPressed,
    this.backgroundColor,
    this.iconColor,
    this.showShadow = true,
    this.size = 40,
  });
  
  /// 뒤로가기 버튼 (←)
  const MingrrLeadingButton.back({
    super.key,
    this.onPressed,
    this.backgroundColor,
    this.iconColor,
    this.showShadow = true,
    this.size = 40,
  }) : type = LeadingType.back;
  
  /// 닫기 버튼 (X)
  const MingrrLeadingButton.close({
    super.key,
    this.onPressed,
    this.backgroundColor,
    this.iconColor,
    this.showShadow = true,
    this.size = 40,
  }) : type = LeadingType.close;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fgColor = iconColor ?? Theme.of(context).colorScheme.onSurface;
    
    // showShadow가 false면 배경도 투명 (AppBar 내부에서 사용 시)
    // showShadow가 true면 배경색 + 그림자 (이미지 위 오버레이 등)
    final bgColor = showShadow 
        ? (backgroundColor ?? Theme.of(context).colorScheme.surface)
        : (backgroundColor ?? Colors.transparent);
    
    // 배경이 투명하면 Container 없이 IconButton만 반환
    if (bgColor == Colors.transparent) {
      return IconButton(
        padding: EdgeInsets.zero,
        constraints: BoxConstraints(minWidth: size, minHeight: size),
        icon: Icon(
          type == LeadingType.close ? AppIcons.close : AppIcons.back,
          size: 20,
          color: fgColor,
        ),
        onPressed: onPressed ?? () => Navigator.pop(context),
      );
    }
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        boxShadow: showShadow ? AppShadows.shadowS(isDark) : null,
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(
          type == LeadingType.close ? AppIcons.close : AppIcons.back,
          size: 20,
          color: fgColor,
        ),
        onPressed: onPressed ?? () => Navigator.pop(context),
      ),
    );
  }
}

/// 이미지 헤더용 Leading 버튼 (반투명 배경)
/// 
/// [MingrrImageHeader] 등 이미지 위에 오버레이되는 버튼에 사용합니다.
class MingrrLeadingButtonOverlay extends StatelessWidget {
  /// 버튼 타입 (back/close)
  final LeadingType type;
  
  /// 버튼 클릭 콜백 (null이면 Navigator.pop)
  final VoidCallback? onPressed;

  const MingrrLeadingButtonOverlay({
    super.key,
    this.type = LeadingType.back,
    this.onPressed,
  });
  
  /// 뒤로가기 버튼 (←)
  const MingrrLeadingButtonOverlay.back({
    super.key,
    this.onPressed,
  }) : type = LeadingType.back;
  
  /// 닫기 버튼 (X)
  const MingrrLeadingButtonOverlay.close({
    super.key,
    this.onPressed,
  }) : type = LeadingType.close;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Container(
        padding: const EdgeInsets.all(AppSizes.paddingS),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: AppOpacity.o30),
          shape: BoxShape.circle,
        ),
        child: Icon(
          type == LeadingType.close ? AppIcons.close : AppIcons.back,
          color: Colors.white,
          size: 20, // MingrrLeadingButton과 동일한 크기로 통일
        ),
      ),
      onPressed: onPressed ?? () => Navigator.pop(context),
    );
  }
}
