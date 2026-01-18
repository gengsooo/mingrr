import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants/app_sizes.dart';
import '../theme/feature_colors.dart';
import '../theme/app_theme.dart';
import 'mingrr_bottom_sheet.dart';
import 'svg_icons.dart';

// 공통 로딩 위젯 export
export 'loading_widgets.dart';

// 공통 FAB export
export 'mingrr_fab.dart';

// 공통 설정 타일 export
export 'mingrr_settings_tile.dart';

// 공통 기록 타일 export
export 'mingrr_record_tile.dart';

// 공통 이미지 컴포넌트 export
export 'mingrr_image_viewer.dart';
export 'mingrr_image_gallery.dart';
export 'mingrr_image_header.dart';

/// ============================================================
/// MINGRR 공통 위젯 모음
/// 앱 전체에서 재사용되는 UI 컴포넌트들
/// ============================================================

// ===== 동글동글한 버튼 =====
/// 앱의 메인 스타일 버튼 (노란색 배경)
class MingrrButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double height;

  const MingrrButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height = AppSizes.buttonHeightL,
  });

  @override
  Widget build(BuildContext context) {
    final buttonChild = isLoading
        ? SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onSurface),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: AppSizes.gapS),
              ],
              Text(text),
            ],
          );

    if (isOutlined) {
      return SizedBox(
        width: width ?? double.infinity,
        height: height,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: backgroundColor ?? Theme.of(context).colorScheme.primary,
              width: 1.5,
            ),
            foregroundColor: textColor ?? Theme.of(context).colorScheme.primary,
          ),
          child: buttonChild,
        ),
      );
    }

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.primary,
          foregroundColor: textColor ?? Theme.of(context).colorScheme.onSurface,
        ),
        child: buttonChild,
      ),
    );
  }
}

// ===== 소셜 로그인 버튼 =====
/// 카카오, 네이버, 구글 등 소셜 로그인용 버튼
class SocialLoginButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color textColor;
  final String? iconPath;
  final IconData? icon;

  const SocialLoginButton({
    super.key,
    required this.text,
    this.onPressed,
    required this.backgroundColor,
    required this.textColor,
    this.iconPath,
    this.icon,
  });

  // 카카오 로그인 버튼
  factory SocialLoginButton.kakao({
    required VoidCallback? onPressed,
  }) {
    return SocialLoginButton(
      text: '카카오로 시작하기',
      onPressed: onPressed,
      backgroundColor: const Color(0xFFFEE500),
      textColor: const Color(0xFF191919),
      icon: Icons.chat_bubble,
    );
  }

  // 네이버 로그인 버튼
  factory SocialLoginButton.naver({
    required VoidCallback? onPressed,
  }) {
    return SocialLoginButton(
      text: '네이버로 시작하기',
      onPressed: onPressed,
      backgroundColor: const Color(0xFF03C75A),
      textColor: Colors.white,
      icon: Icons.north_east,
    );
  }

  // 구글 로그인 버튼
  factory SocialLoginButton.google({
    required VoidCallback? onPressed,
  }) {
    return SocialLoginButton(
      text: '구글로 시작하기',
      onPressed: onPressed,
      backgroundColor: Colors.white,
      textColor: const Color(0xFF757575),
      icon: Icons.g_mobiledata,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppSizes.buttonHeightL,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusL),
            side: backgroundColor == Colors.white
                ? BorderSide(color: Theme.of(context).colorScheme.outline)
                : BorderSide.none,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 24),
              const SizedBox(width: AppSizes.gapM),
            ],
            Text(
              text,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===== 동글동글한 카드 =====
/// 앱 전체에서 사용되는 기본 카드 스타일
class MingrrCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final double? borderRadius;

  const MingrrCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingM,
        vertical: AppSizes.paddingS,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? (isDark ? const Color(0xFF1E1E1E) : Colors.white),
        borderRadius: BorderRadius.circular(borderRadius ?? AppSizes.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius ?? AppSizes.radiusL),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(AppSizes.paddingM),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ===== 프로필 아바타 =====
/// 사용자/반려동물 프로필 이미지 표시
class MingrrAvatar extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final IconData placeholderIcon;
  final VoidCallback? onTap;
  final bool showBorder;
  final Color? borderColor;
  final bool isOnline;

  const MingrrAvatar({
    super.key,
    this.imageUrl,
    this.size = AppSizes.avatarM,
    this.placeholderIcon = Icons.pets,
    this.onTap,
    this.showBorder = false,
    this.borderColor,
    this.isOnline = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: showBorder
                  ? Border.all(
                      color: borderColor ?? Theme.of(context).colorScheme.primary,
                      width: 3,
                    )
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipOval(
              child: _buildAvatarContent(context),
            ),
          ),
          // 온라인 상태 표시
          if (isOnline)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: size * 0.25,
                height: size * 0.25,
                decoration: BoxDecoration(
                  color: context.features.success,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildAvatarContent(BuildContext context) {
    // URL이 없거나 빈 문자열인 경우 기본 아이콘
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildPlaceholder(context);
    }
    
    // default_avatar: 형식인 경우 기본 아바타 아이콘 표시
    if (imageUrl!.startsWith('default_avatar:')) {
      return _buildPlaceholder(context);
    }
    
    // 일반 URL인 경우 네트워크 이미지
    return CachedNetworkImage(
      imageUrl: imageUrl!,
      fit: BoxFit.cover,
      placeholder: (ctx, url) => _buildPlaceholder(ctx),
      errorWidget: (ctx, url, error) => _buildPlaceholder(ctx),
    );
  }
  
  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Icon(
        placeholderIcon,
        size: size * 0.5,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

// ===== 입력 필드 =====
/// 동글동글한 스타일의 텍스트 입력 필드
class MingrrTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final int maxLines;
  final bool enabled;
  final FocusNode? focusNode;

  const MingrrTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
    this.enabled = true,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 타이틀 (labelText가 있을 때만 표시)
        if (labelText != null) ...[
          Text(
            labelText!,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSizes.gapS),
        ],
        // 입력 필드
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          onChanged: onChanged,
          maxLines: maxLines,
          enabled: enabled,
          focusNode: focusNode,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: Theme.of(context).colorScheme.outlineVariant)
                : null,
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}

// ===== 빈 상태 위젯 =====
/// 데이터가 없을 때 표시하는 위젯
/// 
/// 디자인 기준: 데이팅-추천친구 빈 상태
/// - 아이콘: 48px, outlineVariant 색상
/// - 제목: 기본 크기, onSurfaceVariant, w500
/// - 부제목: 12px, outlineVariant
/// - 간격: 아이콘-제목 16px, 제목-부제목 8px, 부제목-버튼 16px
/// - 버튼: 180px 너비, accentColor 배경
class MingrrEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  final Color? accentColor;

  const MingrrEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.buttonText,
    this.onButtonPressed,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 아이콘
          Icon(icon, size: 48, color: colorScheme.outlineVariant),
          const SizedBox(height: 16),
          // 제목
          Text(
            title,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          // 부제목
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.outlineVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          // 버튼
          if (buttonText != null && onButtonPressed != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: 180,
              child: ElevatedButton(
                onPressed: onButtonPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor ?? colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: Text(buttonText!),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ===== 섹션 내 빈 상태 위젯 =====
/// 섹션 내에서 데이터가 없을 때 표시하는 작은 빈 상태 위젯
/// 
/// 사용처:
/// - 프로필 모달 > 사진 갤러리 (사진 없음)
/// - 프로필 모달 > 성격&특성 (특성 없음)
/// - 프로필 모달 > 소개 (소개 없음)
class MingrrEmptySection extends StatelessWidget {
  final IconData icon;
  final String message;
  final double height;

  const MingrrEmptySection({
    super.key,
    required this.icon,
    required this.message,
    this.height = 80,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: colorScheme.outlineVariant,
            ),
            const SizedBox(height: 4),
            Text(
              message,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.outlineVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===== 로딩 인디케이터 =====
/// 앱 스타일에 맞는 로딩 표시
class MingrrLoading extends StatelessWidget {
  final String? message;
  final double size;

  const MingrrLoading({
    super.key,
    this.message,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: AppSizes.gapM),
            Text(
              message!,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ===== 배지 =====
/// 인증 배지, 상태 배지 등
class MingrrBadge extends StatelessWidget {
  final String text;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final bool isSmall;

  const MingrrBadge({
    super.key,
    required this.text,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.isSmall = false,
  });

  // 인증 배지 - 빌드 시점에 context에서 색상 가져옴
  static Widget verified(BuildContext context) {
    return MingrrBadge(
      text: '인증됨',
      backgroundColor: context.features.success,
      textColor: Colors.white,
      icon: Icons.verified,
    );
  }

  // 산책 중 배지 - 빌드 시점에 context에서 색상 가져옴
  static Widget walking(BuildContext context) {
    return MingrrBadge(
      text: '산책 중',
      backgroundColor: context.features.walk,
      textColor: Colors.white,
      icon: Icons.directions_walk,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? AppSizes.paddingS : AppSizes.paddingM,
        vertical: isSmall ? AppSizes.paddingXS : AppSizes.paddingS,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: isSmall ? 12 : 14,
              color: textColor ?? Theme.of(context).colorScheme.onSurface,
            ),
            SizedBox(width: isSmall ? 2 : 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: isSmall ? 10 : 12,
              fontWeight: FontWeight.w600,
              color: textColor ?? Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

// ===== 알림 아이콘 버튼 (Deprecated) =====
/// @deprecated appbar_actions.dart의 AppBarActionButton.notification() 사용 권장
@Deprecated('Use AppBarActionButton.notification() from appbar_actions.dart instead')
class NotificationIconButton extends StatelessWidget {
  final int badgeCount;
  final VoidCallback? onPressed;

  const NotificationIconButton({
    super.key,
    this.badgeCount = 0,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.notifications_outlined),
          if (badgeCount > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  badgeCount > 99 ? '99+' : '$badgeCount',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      visualDensity: VisualDensity.compact,
      onPressed: onPressed ?? () {
        // TODO: 알림 화면으로 이동
      },
    );
  }
}

// ===== 기본 반려동물 이미지 플레이스홀더 =====
/// 추가사진이 없을 때 표시하는 기본 강아지 아이콘
/// 모든 화면에서 통일된 스타일로 사용 (🐶 이모지)
class DefaultPetImage extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const DefaultPetImage({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.features.dating.withValues(alpha: 0.15),
        borderRadius: borderRadius,
      ),
      child: Center(
        child: Icon(
          Icons.pets,
          size: (height ?? 100) * 0.4,
          color: context.features.dating.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

// ===== 섹션 헤더 =====
/// 공통 뒤로가기 버튼
/// 화면 상단에 사용되는 통일된 뒤로가기 버튼
class MingrrBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? iconColor;
  final bool isClose; // true면 X 아이콘, false면 화살표 아이콘

  const MingrrBackButton({
    super.key,
    this.onPressed,
    this.backgroundColor,
    this.iconColor,
    this.isClose = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).colorScheme.surface,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
            blurRadius: 8,
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(
          isClose ? Icons.close : Icons.arrow_back_ios_new,
          size: 20,
          color: iconColor ?? Theme.of(context).colorScheme.onSurface,
        ),
        onPressed: onPressed ?? () => Navigator.pop(context),
      ),
    );
  }
}

/// 리스트 섹션의 제목 표시
class MingrrSectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onActionTap;

  const MingrrSectionHeader({
    super.key,
    required this.title,
    this.actionText,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingM,
        vertical: AppSizes.paddingS,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          if (actionText != null)
            GestureDetector(
              onTap: onActionTap,
              child: Text(
                actionText!,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ===== 공통 날짜 선택기 =====
/// 날짜 선택 위젯 (단일 날짜, 시작일/종료일, 생년월일, 시간 선택 모두 지원)
class MingrrDateSelector extends StatelessWidget {
  /// 시작일 또는 단일 날짜
  final DateTime? date;
  /// 날짜 선택 콜백
  final Function(DateTime) onSelect;
  /// 테마 색상
  final Color? accentColor;
  /// 선택 가능한 최소 날짜
  final DateTime? firstDate;
  /// 선택 가능한 최대 날짜
  final DateTime? lastDate;
  /// 날짜 선택기 상단 텍스트
  final String? helpText;
  /// 표시 라벨 (null이면 자동 포맷)
  final String? label;
  
  // === 시작일/종료일 모드 ===
  /// 종료일 (null이면 단일 날짜 모드)
  final DateTime? endDate;
  /// 종료일 선택 콜백
  final Function(DateTime?)? onEndDateSelect;
  /// 시작일 라벨
  final String startLabel;
  /// 종료일 라벨
  final String endLabel;
  
  // === 생년월일 모드 ===
  /// 생년월일 모드 (과거 날짜만 선택 가능)
  final bool isBirthDate;
  /// 생년월일 최소 연도
  final int birthDateMinYear;
  
  // === 시간 선택 모드 ===
  /// 시간 선택 활성화 여부
  final bool enableTimeSelection;
  /// 시작 시간
  final TimeOfDay? startTime;
  /// 종료 시간
  final TimeOfDay? endTime;
  /// 시간 선택 콜백
  final Function(TimeOfDay?, TimeOfDay?)? onTimeSelect;
  /// 시간 미정 여부
  final bool isTimeFlexible;
  /// 시간 미정 변경 콜백
  final Function(bool)? onTimeFlexibleChanged;

  const MingrrDateSelector({
    super.key,
    this.date,
    required this.onSelect,
    this.accentColor,
    this.firstDate,
    this.lastDate,
    this.helpText,
    this.label,
    this.endDate,
    this.onEndDateSelect,
    this.startLabel = '시작일',
    this.endLabel = '종료일',
    this.isBirthDate = false,
    this.birthDateMinYear = 1950,
    this.enableTimeSelection = false,
    this.startTime,
    this.endTime,
    this.onTimeSelect,
    this.isTimeFlexible = false,
    this.onTimeFlexibleChanged,
  });

  /// 시작일/종료일 모드인지 확인
  bool get isRangeMode => onEndDateSelect != null;

  @override
  Widget build(BuildContext context) {
    // 시간 선택이 활성화된 범위 모드는 통합 바텀시트 사용
    if (isRangeMode && enableTimeSelection) {
      return _buildDateTimeRangeSelector(context);
    }
    if (isRangeMode) {
      return _buildRangeSelector(context);
    }
    return _buildSingleSelector(context);
  }
  
  /// 날짜+시간 통합 선택기 (알바 등록용)
  Widget _buildDateTimeRangeSelector(BuildContext context) {
    final color = accentColor ?? Theme.of(context).colorScheme.primary;
    final hasDate = date != null;
    
    return GestureDetector(
      onTap: () => _showDateTimeRangePicker(context),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.paddingM),
        decoration: BoxDecoration(
          color: hasDate ? color.withValues(alpha: 0.08) : context.inputBackground,
          border: Border.all(
            color: hasDate ? color.withValues(alpha: 0.3) : Theme.of(context).colorScheme.outline,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: hasDate ? color.withValues(alpha: 0.15) : Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                hasDate ? Icons.date_range : Icons.date_range_outlined,
                size: 22,
                color: hasDate ? color : Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasDate) ...[
                    Text(
                      _formatDateRangeDisplay(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatTimeDisplay(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ] else ...[
                    Text(
                      '기간 및 시간 선택',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '탭하여 근무 기간과 시간을 선택하세요',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (hasDate)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  '변경',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              )
            else
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.outlineVariant,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
  
  String _formatDateRangeDisplay() {
    if (date == null) return '';
    final start = '${date!.month}/${date!.day}';
    if (endDate != null) {
      final end = '${endDate!.month}/${endDate!.day}';
      return '$start ~ $end';
    }
    return start;
  }
  
  String _formatTimeDisplay() {
    if (isTimeFlexible) return '시간 미정';
    final startStr = startTime != null 
        ? '${startTime!.hour.toString().padLeft(2, '0')}:${startTime!.minute.toString().padLeft(2, '0')}' 
        : '시간 미정';
    final endStr = endTime != null 
        ? '${endTime!.hour.toString().padLeft(2, '0')}:${endTime!.minute.toString().padLeft(2, '0')}' 
        : '시간 미정';
    if (startTime != null || endTime != null || isTimeFlexible) {
      return '$startStr ~ $endStr';
    }
    return '시간 미선택';
  }
  
  Future<void> _showDateTimeRangePicker(BuildContext context) async {
    final color = accentColor ?? Theme.of(context).colorScheme.primary;
    
    final result = await showModalBottomSheet<_DateTimeRangeResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DateTimeRangePickerSheet(
        initialStartDate: date,
        initialEndDate: endDate,
        initialStartTime: startTime,
        initialEndTime: endTime,
        initialIsTimeFlexible: isTimeFlexible,
        accentColor: color,
        title: helpText ?? '기간 선택',
      ),
    );
    
    if (result != null) {
      onSelect(result.startDate);
      onEndDateSelect?.call(result.endDate);
      onTimeSelect?.call(result.startTime, result.endTime);
      onTimeFlexibleChanged?.call(result.isTimeFlexible);
    }
  }

  /// 단일 날짜 선택기 (LocationDisplayCard와 동일한 스타일)
  Widget _buildSingleSelector(BuildContext context) {
    final color = accentColor ?? Theme.of(context).colorScheme.primary;
    final hasDate = date != null;
    
    return GestureDetector(
      onTap: () => _selectDate(context, isStart: true),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.paddingM),
        decoration: BoxDecoration(
          color: hasDate ? color.withValues(alpha: 0.08) : context.inputBackground,
          border: Border.all(
            color: hasDate ? color.withValues(alpha: 0.3) : Theme.of(context).colorScheme.outline,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // 아이콘
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: hasDate ? color.withValues(alpha: 0.15) : Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                hasDate ? Icons.calendar_month : Icons.calendar_month_outlined,
                size: 22,
                color: hasDate ? color : Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            const SizedBox(width: 12),
            
            // 날짜 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasDate) ...[
                    Text(
                      _formatDate(date!),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    if (isBirthDate) ...[
                      const SizedBox(height: 2),
                      Text(
                        '만 ${_calculateAge(date!)}세',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ] else ...[
                    Text(
                      label ?? (isBirthDate ? '생년월일 선택' : '날짜 선택'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '탭하여 선택',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // 액션 버튼
            if (hasDate)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  '변경',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              )
            else
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.outlineVariant,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
  
  /// 나이 계산
  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month || 
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  /// 시작일/종료일 선택기 (통일된 디자인)
  Widget _buildRangeSelector(BuildContext context) {
    final color = accentColor ?? Theme.of(context).colorScheme.primary;
    final hasStartDate = date != null;
    final hasEndDate = endDate != null;
    
    return GestureDetector(
      onTap: () => _selectDate(context, isStart: true),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.paddingM),
        decoration: BoxDecoration(
          color: (hasStartDate || hasEndDate) ? color.withValues(alpha: 0.08) : context.inputBackground,
          border: Border.all(
            color: (hasStartDate || hasEndDate) ? color.withValues(alpha: 0.3) : Theme.of(context).colorScheme.outline,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // 아이콘
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (hasStartDate || hasEndDate) 
                    ? color.withValues(alpha: 0.15)
                    : Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                (hasStartDate || hasEndDate) ? Icons.date_range : Icons.date_range_outlined,
                size: 22,
                color: (hasStartDate || hasEndDate) ? color : Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            const SizedBox(width: 12),
            
            // 날짜 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasStartDate || hasEndDate) ...[
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _selectDate(context, isStart: true),
                            child: Text(
                              hasStartDate ? _formatDateShort(date!) : startLabel,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: hasStartDate ? FontWeight.w600 : FontWeight.w400,
                                color: hasStartDate ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.outlineVariant,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text('~', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _selectDate(context, isStart: false),
                            child: Text(
                              hasEndDate ? _formatDateShort(endDate!) : endLabel,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: hasEndDate ? FontWeight.w600 : FontWeight.w400,
                                color: hasEndDate ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.outlineVariant,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Text(
                      '기간 선택',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '탭하여 시작일/종료일 선택',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // 액션 버튼
            if (hasStartDate || hasEndDate)
              GestureDetector(
                onTap: () => _selectDate(context, isStart: true),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    '변경',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
            else
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.outlineVariant,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  
  /// 짧은 날짜 형식 (시작일/종료일용)
  String _formatDateShort(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _selectDate(BuildContext context, {required bool isStart}) async {
    final color = accentColor ?? Theme.of(context).colorScheme.primary;
    
    // 날짜 범위 설정
    DateTime effectiveFirstDate;
    DateTime effectiveLastDate;
    DateTime initialDate;
    
    if (isBirthDate) {
      // 동적 년도 범위: 현재년도 - 100 ~ 현재년도
      final now = DateTime.now();
      effectiveFirstDate = DateTime(now.year - 100);
      effectiveLastDate = now;
      initialDate = date ?? DateTime(now.year - 30);
    } else if (isRangeMode) {
      if (isStart) {
        effectiveFirstDate = firstDate ?? DateTime.now();
        effectiveLastDate = lastDate ?? DateTime.now().add(const Duration(days: 365));
        initialDate = date ?? DateTime.now();
      } else {
        effectiveFirstDate = date ?? DateTime.now();
        effectiveLastDate = lastDate ?? DateTime.now().add(const Duration(days: 365));
        initialDate = endDate ?? (date ?? DateTime.now());
      }
    } else {
      effectiveFirstDate = firstDate ?? DateTime.now().subtract(const Duration(days: 365 * 2));
      effectiveLastDate = lastDate ?? DateTime.now().add(const Duration(days: 365));
      initialDate = date ?? DateTime.now();
    }
    
    // initialDate가 범위 내에 있는지 확인
    if (initialDate.isBefore(effectiveFirstDate)) {
      initialDate = effectiveFirstDate;
    }
    if (initialDate.isAfter(effectiveLastDate)) {
      initialDate = effectiveLastDate;
    }

    // 커스텀 날짜 선택 바텀시트 사용
    final picked = await _showCustomDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: effectiveFirstDate,
      lastDate: effectiveLastDate,
      color: color,
      title: helpText ?? (isBirthDate ? '생년월일 선택' : (isRangeMode ? (isStart ? '시작일 선택' : '종료일 선택') : '날짜 선택')),
      enableYearMonthPicker: isBirthDate,
    );

    if (picked != null) {
      if (isRangeMode && !isStart) {
        onEndDateSelect!(picked);
      } else {
        onSelect(picked);
        // 시작일이 변경되면 종료일이 시작일보다 이전인 경우 초기화
        if (isRangeMode && endDate != null && endDate!.isBefore(picked)) {
          onEndDateSelect!(null);
        }
      }
    }
  }
  
  /// 커스텀 날짜 선택 바텀시트 (yyyy.mm.dd 자동 포맷팅 지원)
  Future<DateTime?> _showCustomDatePicker({
    required BuildContext context,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
    required Color color,
    required String title,
    bool enableYearMonthPicker = false,
  }) async {
    return showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CustomDatePickerSheet(
        initialDate: initialDate,
        firstDate: firstDate,
        lastDate: lastDate,
        accentColor: color,
        title: title,
        enableYearMonthPicker: enableYearMonthPicker,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }
}

/// 커스텀 날짜 선택 바텀시트 (yyyy.mm.dd 자동 포맷팅 지원)
class _CustomDatePickerSheet extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final Color accentColor;
  final String title;
  final bool enableYearMonthPicker;

  const _CustomDatePickerSheet({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.accentColor,
    required this.title,
    this.enableYearMonthPicker = false,
  });

  @override
  State<_CustomDatePickerSheet> createState() => _CustomDatePickerSheetState();
}

class _CustomDatePickerSheetState extends State<_CustomDatePickerSheet> {
  late DateTime _selectedDate;
  late DateTime _displayedMonth;
  final _dateController = TextEditingController();
  String? _errorText;
  bool _isInputMode = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _displayedMonth = DateTime(widget.initialDate.year, widget.initialDate.month);
    _updateDateText();
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  void _updateDateText() {
    _dateController.text = '${_selectedDate.year}.${_selectedDate.month.toString().padLeft(2, '0')}.${_selectedDate.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // 입력 모드일 때 키보드 높이를 고려하여 높이 조정
    final sheetHeight = _isInputMode && keyboardHeight > 0
        ? screenHeight * 0.9
        : screenHeight * 0.65;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: sheetHeight,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.bottomSheetRadius)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          _isInputMode ? _buildInputMode() : _buildCalendarMode(),
          _buildBottomButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const BottomSheetHandle(),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: Row(
            children: [
              const SizedBox(width: 40),
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              // 입력 모드 토글 버튼
              IconButton(
                icon: Icon(
                  _isInputMode ? Icons.calendar_month : Icons.edit,
                  color: widget.accentColor,
                ),
                onPressed: () => setState(() {
                  _isInputMode = !_isInputMode;
                  if (!_isInputMode) {
                    _errorText = null;
                  }
                }),
                tooltip: _isInputMode ? '캘린더로 선택' : '직접 입력',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputMode() {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    
    return Expanded(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: keyboardHeight > 0 ? keyboardHeight + 20 : 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '날짜 직접 입력',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              '숫자만 입력하면 자동으로 형식이 적용됩니다',
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _dateController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'YYYY.MM.DD',
                hintStyle: TextStyle(color: Theme.of(context).colorScheme.outlineVariant),
                errorText: _errorText,
                prefixIcon: Icon(Icons.calendar_today, color: widget.accentColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: widget.accentColor, width: 1.5),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red),
                ),
              ),
              onChanged: _onDateTextChanged,
            ),
            const SizedBox(height: 24),
            // 선택된 날짜 미리보기
            if (_errorText == null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: widget.accentColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: widget.accentColor.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: widget.accentColor, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      '${_selectedDate.year}년 ${_selectedDate.month}월 ${_selectedDate.day}일',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _onDateTextChanged(String value) {
    // 숫자만 추출
    final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
    
    // 자동 포맷팅 적용
    String formatted = '';
    for (int i = 0; i < digitsOnly.length && i < 8; i++) {
      if (i == 4 || i == 6) {
        formatted += '.';
      }
      formatted += digitsOnly[i];
    }
    
    // 커서 위치 계산
    final cursorOffset = formatted.length;
    
    // 텍스트 업데이트 (무한 루프 방지)
    if (_dateController.text != formatted) {
      _dateController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: cursorOffset),
      );
    }
    
    // 날짜 유효성 검사
    if (digitsOnly.length == 8) {
      final year = int.tryParse(digitsOnly.substring(0, 4));
      final month = int.tryParse(digitsOnly.substring(4, 6));
      final day = int.tryParse(digitsOnly.substring(6, 8));
      
      if (year != null && month != null && day != null &&
          month >= 1 && month <= 12 && day >= 1 && day <= 31) {
        try {
          final parsedDate = DateTime(year, month, day);
          // 범위 검사
          if (parsedDate.isBefore(widget.firstDate)) {
            setState(() => _errorText = '선택 가능한 가장 이른 날짜: ${_formatDateShort(widget.firstDate)}');
          } else if (parsedDate.isAfter(widget.lastDate)) {
            setState(() => _errorText = '선택 가능한 가장 늦은 날짜: ${_formatDateShort(widget.lastDate)}');
          } else {
            setState(() {
              _selectedDate = parsedDate;
              _displayedMonth = DateTime(parsedDate.year, parsedDate.month);
              _errorText = null;
            });
          }
        } catch (e) {
          setState(() => _errorText = '올바른 날짜 형식이 아닙니다');
        }
      } else {
        setState(() => _errorText = '올바른 날짜 형식이 아닙니다');
      }
    } else {
      setState(() => _errorText = null);
    }
  }

  String _formatDateShort(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  Widget _buildCalendarMode() {
    return Expanded(
      child: Column(
        children: [
          // 월 네비게이션
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.chevron_left, color: widget.accentColor),
                  onPressed: () {
                    setState(() {
                      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1);
                    });
                  },
                ),
                // 년도/월 선택 (enableYearMonthPicker가 true일 때 클릭 가능)
                GestureDetector(
                  onTap: widget.enableYearMonthPicker ? _showYearMonthPicker : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: widget.enableYearMonthPicker ? BoxDecoration(
                      color: widget.accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ) : null,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_displayedMonth.year}년 ${_displayedMonth.month}월',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        if (widget.enableYearMonthPicker) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_drop_down, color: widget.accentColor, size: 20),
                        ],
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.chevron_right, color: widget.accentColor),
                  onPressed: () {
                    setState(() {
                      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1);
                    });
                  },
                ),
              ],
            ),
          ),
          
          // 요일 헤더
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: ['일', '월', '화', '수', '목', '금', '토'].map((day) {
                final isWeekend = day == '일' || day == '토';
                return Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isWeekend ? Colors.red : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // 캘린더 그리드
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildCalendarGrid(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final daysInMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0).day;
    final firstWeekday = DateTime(_displayedMonth.year, _displayedMonth.month, 1).weekday % 7;
    
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1,
      ),
      itemCount: 42,
      itemBuilder: (context, index) {
        final dayOffset = index - firstWeekday;
        if (dayOffset < 0 || dayOffset >= daysInMonth) {
          return const SizedBox();
        }
        
        final date = DateTime(_displayedMonth.year, _displayedMonth.month, dayOffset + 1);
        final isBeforeFirst = date.isBefore(widget.firstDate);
        final isAfterLast = date.isAfter(widget.lastDate);
        final isDisabled = isBeforeFirst || isAfterLast;
        final isSelected = _isSameDay(date, _selectedDate);
        final isToday = _isSameDay(date, DateTime.now());
        
        return GestureDetector(
          onTap: isDisabled ? null : () {
            setState(() {
              _selectedDate = date;
              _updateDateText();
            });
          },
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isSelected ? widget.accentColor : null,
              shape: BoxShape.circle,
              border: isToday && !isSelected
                  ? Border.all(color: widget.accentColor, width: 1)
                  : null,
            ),
            child: Center(
              child: Text(
                '${dayOffset + 1}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected 
                      ? Colors.white
                      : isDisabled
                          ? Theme.of(context).colorScheme.outlineVariant
                          : (index % 7 == 0 ? Colors.red : Theme.of(context).colorScheme.onSurface),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// 년도/월 빠른 선택 모달
  void _showYearMonthPicker() {
    // 동적 년도 범위 계산
    final minYear = widget.firstDate.year;
    final maxYear = widget.lastDate.year;
    final years = List.generate(maxYear - minYear + 1, (i) => minYear + i);
    
    int selectedYear = _displayedMonth.year;
    int selectedMonth = _displayedMonth.month;
    
    // 현재 선택된 년도의 인덱스
    int yearIndex = years.indexOf(selectedYear);
    if (yearIndex < 0) yearIndex = years.length - 1;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          // 선택한 년도에 따라 월 범위 제한
          int minMonth = 1;
          int maxMonth = 12;
          if (selectedYear == widget.firstDate.year) {
            minMonth = widget.firstDate.month;
          }
          if (selectedYear == widget.lastDate.year) {
            maxMonth = widget.lastDate.month;
          }
          // 선택된 월이 범위를 벗어나면 조정
          if (selectedMonth < minMonth) selectedMonth = minMonth;
          if (selectedMonth > maxMonth) selectedMonth = maxMonth;
          
          return Container(
            height: 350,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.bottomSheetRadius)),
            ),
            child: Column(
              children: [
                // 헤더
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                  child: Row(
                    children: [
                      const Text('년도/월 선택', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Picker
                Expanded(
                  child: Row(
                    children: [
                      // 년도 Picker
                      Expanded(
                        child: CupertinoPicker(
                          scrollController: FixedExtentScrollController(initialItem: yearIndex),
                          itemExtent: 40,
                          onSelectedItemChanged: (index) {
                            setModalState(() {
                              selectedYear = years[index];
                            });
                          },
                          children: years.map((year) => Center(
                            child: Text('$year년', style: const TextStyle(fontSize: 18)),
                          )).toList(),
                        ),
                      ),
                      // 월 Picker
                      Expanded(
                        child: CupertinoPicker(
                          key: ValueKey('month_picker_$selectedYear'),
                          scrollController: FixedExtentScrollController(initialItem: selectedMonth - minMonth),
                          itemExtent: 40,
                          onSelectedItemChanged: (index) {
                            setModalState(() {
                              selectedMonth = minMonth + index;
                            });
                          },
                          children: List.generate(maxMonth - minMonth + 1, (i) => Center(
                            child: Text('${minMonth + i}월', style: const TextStyle(fontSize: 18)),
                          )),
                        ),
                      ),
                    ],
                  ),
                ),
                // 확인 버튼
                Container(
                  padding: EdgeInsets.only(left: 20, right: 20, top: 16, bottom: MediaQuery.of(context).padding.bottom + 16),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {
                        _displayedMonth = DateTime(selectedYear, selectedMonth);
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.accentColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('확인', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
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
      child: ElevatedButton(
        onPressed: _errorText == null ? () => Navigator.pop(context, _selectedDate) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.accentColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Theme.of(context).colorScheme.outline,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          '선택',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

// ===== 공통 메모 입력 필드 =====
/// 메모 입력 위젯 (바텀시트, 폼 등에서 사용)
class MingrrMemoField extends StatelessWidget {
  final TextEditingController controller;
  final String? hint;
  final int maxLines;

  const MingrrMemoField({
    super.key,
    required this.controller,
    this.hint,
    this.maxLines = 3,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint ?? '메모를 입력하세요',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
    );
  }
}

// ===== 공통 라벨 위젯 =====
/// 폼 필드 라벨 위젯
class MingrrLabel extends StatelessWidget {
  final String text;
  final bool isRequired;

  const MingrrLabel(this.text, {super.key, this.isRequired = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        isRequired ? '$text *' : text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }
}

// ===== 공통 로딩 상태 위젯 =====
/// 데이터 로딩 중 표시하는 위젯
class MingrrLoadingState extends StatelessWidget {
  final String? message;
  final Color? color;

  const MingrrLoadingState({
    super.key,
    this.message,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: color ?? Theme.of(context).colorScheme.primary,
            strokeWidth: 3,
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ===== 공통 에러 상태 위젯 =====
/// 에러 발생 시 표시하는 위젯
class MingrrErrorState extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final String? buttonText;
  final VoidCallback? onRetry;
  final IconData? icon;

  const MingrrErrorState({
    super.key,
    this.title,
    this.subtitle,
    this.buttonText,
    this.onRetry,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon ?? Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              title ?? '일시적인 오류가 발생했어요',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text(buttonText ?? '다시 시도'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ===== 공통 SnackBar 헬퍼 =====
/// SnackBar를 쉽게 표시하기 위한 헬퍼 클래스
class MingrrSnackBar {
  MingrrSnackBar._();

  /// 성공 메시지 표시 (녹색)
  static void success(BuildContext context, String message) {
    _show(context, message, context.features.success);
  }

  /// 에러 메시지 표시 (빨간색)
  static void error(BuildContext context, String message) {
    _show(context, message, Colors.red);
  }

  /// 정보 메시지 표시 (기본 색상)
  static void info(BuildContext context, String message) {
    _show(context, message, Theme.of(context).colorScheme.onSurfaceVariant);
  }

  /// 경고 메시지 표시 (주황색)
  static void warning(BuildContext context, String message) {
    _show(context, message, Colors.orange);
  }

  /// 커스텀 SnackBar 표시
  static void _show(BuildContext context, String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 액션이 있는 SnackBar 표시
  static void withAction(
    BuildContext context, {
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
    Color? backgroundColor,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.onSurfaceVariant,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: actionLabel,
          textColor: Colors.white,
          onPressed: onAction,
        ),
      ),
    );
  }
}

// ===== 날짜+시간 통합 선택 결과 =====
class _DateTimeRangeResult {
  final DateTime startDate;
  final DateTime? endDate;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final bool isTimeFlexible;

  const _DateTimeRangeResult({
    required this.startDate,
    this.endDate,
    this.startTime,
    this.endTime,
    this.isTimeFlexible = false,
  });
}

// ===== 날짜+시간 통합 선택 바텀시트 =====
enum _DateTimeSelectionStep { startDate, endDate, startTime, endTime, complete }

class _DateTimeRangePickerSheet extends StatefulWidget {
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final TimeOfDay? initialStartTime;
  final TimeOfDay? initialEndTime;
  final bool initialIsTimeFlexible;
  final Color accentColor;
  final String title;

  const _DateTimeRangePickerSheet({
    this.initialStartDate,
    this.initialEndDate,
    this.initialStartTime,
    this.initialEndTime,
    this.initialIsTimeFlexible = false,
    required this.accentColor,
    required this.title,
  });

  @override
  State<_DateTimeRangePickerSheet> createState() => _DateTimeRangePickerSheetState();
}

class _DateTimeRangePickerSheetState extends State<_DateTimeRangePickerSheet> {
  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isStartTimeFlexible = false;
  bool _isEndTimeFlexible = false;
  late _DateTimeSelectionStep _currentStep;
  late DateTime _displayedMonth;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
    _startTime = widget.initialStartTime;
    _endTime = widget.initialEndTime;
    // 기존 isTimeFlexible이 true면 둘 다 미정
    _isStartTimeFlexible = widget.initialIsTimeFlexible;
    _isEndTimeFlexible = widget.initialIsTimeFlexible;
    _displayedMonth = widget.initialStartDate ?? DateTime.now();
    
    // 초기 단계 설정
    _currentStep = _DateTimeSelectionStep.startDate;
  }
  
  // 완료 여부 확인
  bool get _isComplete {
    if (_startDate == null || _endDate == null) return false;
    final startTimeOk = _isStartTimeFlexible || _startTime != null;
    final endTimeOk = _isEndTimeFlexible || _endTime != null;
    return startTimeOk && endTimeOk;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.bottomSheetRadius)),
      ),
      child: Column(
        children: [
          _buildPickerHeader(),
          _buildStepIndicatorRow(),
          Expanded(child: _buildPickerContent()),
          // 완료 단계에서만 하단 확인 버튼 표시
          if (_currentStep == _DateTimeSelectionStep.complete && _isComplete)
            _buildFinalConfirmButton(),
        ],
      ),
    );
  }

  Widget _buildPickerHeader() {
    return Column(
      children: [
        const BottomSheetHandle(),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: Text(
            widget.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildStepIndicatorRow() {
    final isDateStep = _currentStep == _DateTimeSelectionStep.startDate || _currentStep == _DateTimeSelectionStep.endDate;
    final isTimeStep = _currentStep == _DateTimeSelectionStep.startTime || _currentStep == _DateTimeSelectionStep.endTime;
    final hasDateCompleted = _startDate != null && _endDate != null;
    final startTimeOk = _isStartTimeFlexible || _startTime != null;
    final endTimeOk = _isEndTimeFlexible || _endTime != null;
    final hasTimeCompleted = startTimeOk && endTimeOk;
    
    // 날짜 표시 텍스트
    String dateValue;
    if (_startDate != null && _endDate != null) {
      dateValue = '${_startDate!.month}/${_startDate!.day} ~ ${_endDate!.month}/${_endDate!.day}';
    } else if (_startDate != null) {
      dateValue = '${_startDate!.month}/${_startDate!.day} ~';
    } else {
      dateValue = '선택';
    }
    
    // 시간 표시 텍스트
    String timeValue;
    final startTimeText = _isStartTimeFlexible ? '미정' : (_startTime != null ? _fmtTime(_startTime!) : null);
    final endTimeText = _isEndTimeFlexible ? '미정' : (_endTime != null ? _fmtTime(_endTime!) : null);
    if (startTimeText != null && endTimeText != null) {
      timeValue = '$startTimeText ~ $endTimeText';
    } else if (startTimeText != null) {
      timeValue = '$startTimeText ~';
    } else {
      timeValue = '선택';
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          _buildPickerStepChip(
            label: '날짜 선택',
            value: dateValue,
            isActive: isDateStep,
            isCompleted: hasDateCompleted,
            onTap: () => setState(() => _currentStep = _DateTimeSelectionStep.startDate),
          ),
          const SizedBox(width: 12),
          _buildPickerStepChip(
            label: '시간 선택',
            value: timeValue,
            isActive: isTimeStep || _currentStep == _DateTimeSelectionStep.complete,
            isCompleted: hasTimeCompleted,
            onTap: hasDateCompleted ? () => setState(() {
              // 시간 선택 탭 클릭 시 기본값 설정
              if (!_isStartTimeFlexible && _startTime == null) {
                _startTime = const TimeOfDay(hour: 9, minute: 0);
              }
              _currentStep = _DateTimeSelectionStep.startTime;
            }) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildPickerStepChip({required String label, String? value, required bool isActive, required bool isCompleted, VoidCallback? onTap}) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(
            color: isActive 
                ? widget.accentColor.withValues(alpha: 0.1) 
                : (isCompleted 
                    ? widget.accentColor.withValues(alpha: 0.05) 
                    : colorScheme.surfaceContainerHighest),
            border: Border.all(
              color: isActive 
                  ? widget.accentColor 
                  : (isCompleted 
                      ? widget.accentColor.withValues(alpha: 0.3) 
                      : colorScheme.outline), 
              width: isActive ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Text(label, style: TextStyle(fontSize: 10, color: isActive ? widget.accentColor : colorScheme.onSurfaceVariant)),
              const SizedBox(height: 2),
              Text(value ?? '선택', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: value != null ? colorScheme.onSurface : colorScheme.outlineVariant), overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPickerContent() {
    switch (_currentStep) {
      case _DateTimeSelectionStep.startDate:
      case _DateTimeSelectionStep.endDate:
        return _buildPickerCalendar();
      case _DateTimeSelectionStep.startTime:
      case _DateTimeSelectionStep.endTime:
        return _buildPickerTimeSelector();
      case _DateTimeSelectionStep.complete:
        return _buildPickerSummary();
    }
  }

  Widget _buildPickerCalendar() {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, now.day);
    final lastDay = DateTime(now.year + 1, now.month, now.day);
    final isStartDateStep = _currentStep == _DateTimeSelectionStep.startDate;
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(icon: Icon(Icons.chevron_left, color: widget.accentColor), onPressed: () => setState(() => _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1))),
              Text('${_displayedMonth.year}년 ${_displayedMonth.month}월', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              IconButton(icon: Icon(Icons.chevron_right, color: widget.accentColor), onPressed: () => setState(() => _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1))),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: ['일', '월', '화', '수', '목', '금', '토'].map((day) {
              return Expanded(child: Center(child: Text(day, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: day == '일' || day == '토' ? Colors.red : Theme.of(context).colorScheme.onSurfaceVariant))));
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: _buildPickerCalendarGrid(firstDay, lastDay))),
        // 날짜 선택 하단 이전/다음 버튼
        _buildDateNavigationButtons(isStartDateStep),
      ],
    );
  }

  Widget _buildPickerCalendarGrid(DateTime firstDay, DateTime lastDay) {
    final daysInMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0).day;
    final firstWeekday = DateTime(_displayedMonth.year, _displayedMonth.month, 1).weekday % 7;
    
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, childAspectRatio: 1),
      itemCount: 42,
      itemBuilder: (context, index) {
        final dayOffset = index - firstWeekday;
        if (dayOffset < 0 || dayOffset >= daysInMonth) return const SizedBox();
        
        final date = DateTime(_displayedMonth.year, _displayedMonth.month, dayOffset + 1);
        final isBeforeToday = date.isBefore(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day));
        final isDisabled = isBeforeToday || date.isAfter(lastDay);
        final isBeforeStartDate = _currentStep == _DateTimeSelectionStep.endDate && _startDate != null && date.isBefore(_startDate!);
        final isStartDate = _startDate != null && _sameDay(date, _startDate!);
        final isEndDate = _endDate != null && _sameDay(date, _endDate!);
        final isInRange = _startDate != null && _endDate != null && date.isAfter(_startDate!) && date.isBefore(_endDate!);
        final isToday = _sameDay(date, DateTime.now());
        
        return GestureDetector(
          onTap: (isDisabled || isBeforeStartDate) ? null : () => _onPickerDateSelected(date),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isStartDate || isEndDate ? widget.accentColor : (isInRange ? widget.accentColor.withValues(alpha: 0.15) : null),
              shape: BoxShape.circle,
              border: isToday && !isStartDate && !isEndDate ? Border.all(color: widget.accentColor, width: 1) : null,
            ),
            child: Center(child: Text('${dayOffset + 1}', style: TextStyle(fontSize: 14, fontWeight: isStartDate || isEndDate ? FontWeight.w600 : FontWeight.w400, color: isStartDate || isEndDate ? Colors.white : (isDisabled || isBeforeStartDate) ? Theme.of(context).colorScheme.outlineVariant : (index % 7 == 0 ? Colors.red : Theme.of(context).colorScheme.onSurface)))),
          ),
        );
      },
    );
  }

  void _onPickerDateSelected(DateTime date) {
    setState(() {
      if (_currentStep == _DateTimeSelectionStep.startDate) {
        _startDate = date;
        if (_endDate != null && date.isAfter(_endDate!)) _endDate = null;
        // 자동 전환 제거 - 버튼으로만 전환
      } else if (_currentStep == _DateTimeSelectionStep.endDate) {
        _endDate = date;
        // 자동 전환 제거 - 버튼으로만 전환
      }
    });
  }

  Widget _buildPickerTimeSelector() {
    final isStartTime = _currentStep == _DateTimeSelectionStep.startTime;
    final isFlexible = isStartTime ? _isStartTimeFlexible : _isEndTimeFlexible;
    final currentTime = isStartTime 
        ? (_startTime ?? const TimeOfDay(hour: 9, minute: 0)) 
        : (_endTime ?? const TimeOfDay(hour: 18, minute: 0));
    
    return Column(
      children: [
        // 시간 미정 옵션 (시작/종료 각각)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: GestureDetector(
            onTap: () => setState(() {
              if (isStartTime) {
                _isStartTimeFlexible = !_isStartTimeFlexible;
                if (_isStartTimeFlexible) {
                  _startTime = null;
                } else {
                  // 미정 해제 시 기본값 설정
                  _startTime ??= const TimeOfDay(hour: 9, minute: 0);
                }
              } else {
                _isEndTimeFlexible = !_isEndTimeFlexible;
                if (_isEndTimeFlexible) {
                  _endTime = null;
                } else {
                  // 미정 해제 시 기본값 설정
                  _endTime ??= const TimeOfDay(hour: 18, minute: 0);
                }
              }
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: isFlexible 
                    ? widget.accentColor.withValues(alpha: 0.1) 
                    : Colors.white,
                border: Border.all(color: isFlexible ? widget.accentColor : Theme.of(context).colorScheme.outline),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(isFlexible ? Icons.check_circle : Icons.circle_outlined, size: 20, color: isFlexible ? widget.accentColor : Theme.of(context).colorScheme.outlineVariant),
                  const SizedBox(width: 8),
                  Text(isStartTime ? '시작 시간 미정' : '종료 시간 미정', style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ),
        ),
        // 시간 선택 Picker (미정이 아닐 때만)
        if (!isFlexible) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              '${currentTime.hour.toString().padLeft(2, '0')}:${currentTime.minute.toString().padLeft(2, '0')}',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w600, color: widget.accentColor),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: CupertinoPicker(
                    key: ValueKey('hour_picker_$isStartTime'),
                    scrollController: FixedExtentScrollController(initialItem: currentTime.hour),
                    itemExtent: 40,
                    onSelectedItemChanged: (i) => _updatePickerTime(isStartTime, i, currentTime.minute),
                    children: List.generate(24, (i) => Center(child: Text('${i.toString().padLeft(2, '0')}시', style: const TextStyle(fontSize: 18)))),
                  ),
                ),
                Expanded(
                  child: CupertinoPicker(
                    key: ValueKey('minute_picker_$isStartTime'),
                    scrollController: FixedExtentScrollController(initialItem: currentTime.minute ~/ 10),
                    itemExtent: 40,
                    onSelectedItemChanged: (i) => _updatePickerTime(isStartTime, currentTime.hour, i * 10),
                    children: List.generate(6, (i) => Center(child: Text('${(i * 10).toString().padLeft(2, '0')}분', style: const TextStyle(fontSize: 18)))),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (isFlexible) const Spacer(),
        // 시간 선택 하단 이전/다음 버튼
        _buildTimeNavigationButtons(isStartTime),
      ],
    );
  }

  void _updatePickerTime(bool isStartTime, int hour, int minute) {
    setState(() { if (isStartTime) _startTime = TimeOfDay(hour: hour, minute: minute); else _endTime = TimeOfDay(hour: hour, minute: minute); });
  }

  Widget _buildPickerSummary() {
    // 시간 표시 텍스트 생성
    final startTimeText = _isStartTimeFlexible ? '미정' : (_startTime != null ? _fmtTime(_startTime!) : '미정');
    final endTimeText = _isEndTimeFlexible ? '미정' : (_endTime != null ? _fmtTime(_endTime!) : '미정');
    final timeValue = '$startTimeText ~ $endTimeText';
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('선택 완료', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          _buildPickerSummaryItem(icon: Icons.calendar_today, label: '기간', value: '${_fmtDateFull(_startDate!)} ~ ${_fmtDateFull(_endDate!)}'),
          const SizedBox(height: 12),
          _buildPickerSummaryItem(icon: Icons.access_time, label: '시간', value: timeValue),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(8)),
            child: Row(children: [Icon(Icons.info_outline, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant), const SizedBox(width: 8), Expanded(child: Text('상단 탭을 눌러 날짜나 시간을 수정할 수 있습니다', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)))]),
          ),
        ],
      ),
    );
  }

  Widget _buildPickerSummaryItem({required IconData icon, required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: widget.accentColor.withValues(alpha: 0.05), border: Border.all(color: widget.accentColor.withValues(alpha: 0.2)), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: widget.accentColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 20, color: widget.accentColor)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)), const SizedBox(height: 2), Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))])),
        ],
      ),
    );
  }

  // 날짜 선택 이전/다음 버튼
  Widget _buildDateNavigationButtons(bool isStartDateStep) {
    final canGoPrev = !isStartDateStep; // 종료일 선택 시에만 이전 가능
    final canGoNext = isStartDateStep ? _startDate != null : _endDate != null;
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Row(
        children: [
          // 이전 버튼
          Expanded(
            child: OutlinedButton(
              onPressed: canGoPrev ? () => setState(() => _currentStep = _DateTimeSelectionStep.startDate) : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: widget.accentColor,
                side: BorderSide(color: canGoPrev ? widget.accentColor : Theme.of(context).colorScheme.outline),
                minimumSize: const Size(0, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('이전: 시작일', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: canGoPrev ? widget.accentColor : Theme.of(context).colorScheme.outlineVariant)),
            ),
          ),
          const SizedBox(width: 12),
          // 다음 버튼
          Expanded(
            child: ElevatedButton(
              onPressed: canGoNext 
                  ? () => setState(() {
                      if (isStartDateStep) {
                        _currentStep = _DateTimeSelectionStep.endDate;
                      } else {
                        // 시간 선택 진입 시 기본값 설정 (미정이 아닐 때)
                        if (!_isStartTimeFlexible && _startTime == null) {
                          _startTime = const TimeOfDay(hour: 9, minute: 0);
                        }
                        _currentStep = _DateTimeSelectionStep.startTime;
                      }
                    })
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.accentColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Theme.of(context).colorScheme.outline,
                minimumSize: const Size(0, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                isStartDateStep ? '다음: 종료일' : '다음: 시간 선택',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 시간 선택 이전/다음 버튼
  Widget _buildTimeNavigationButtons(bool isStartTime) {
    // 이전 버튼: 항상 활성화 (시작 시간이면 날짜로, 종료 시간이면 시작 시간으로)
    const canGoPrev = true;
    // 다음 버튼: 시간이 선택되었거나 미정이면 활성화
    final canGoNext = isStartTime 
        ? (_isStartTimeFlexible || _startTime != null) 
        : (_isEndTimeFlexible || _endTime != null);
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Row(
        children: [
          // 이전 버튼
          Expanded(
            child: OutlinedButton(
              onPressed: canGoPrev 
                  ? () => setState(() {
                      if (isStartTime) {
                        _currentStep = _DateTimeSelectionStep.endDate;
                      } else {
                        _currentStep = _DateTimeSelectionStep.startTime;
                      }
                    })
                  : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: widget.accentColor,
                side: BorderSide(color: canGoPrev ? widget.accentColor : Theme.of(context).colorScheme.outline),
                minimumSize: const Size(0, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                isStartTime ? '이전: 종료일' : '이전: 시작 시간',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: canGoPrev ? widget.accentColor : Theme.of(context).colorScheme.outlineVariant),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 다음 버튼
          Expanded(
            child: ElevatedButton(
              onPressed: canGoNext 
                  ? () => setState(() {
                      if (isStartTime) {
                        // 시작 시간이 미정이 아니면 기본값 설정
                        if (!_isStartTimeFlexible) {
                          _startTime ??= const TimeOfDay(hour: 9, minute: 0);
                        }
                        // 종료 시간 진입 시 기본값 설정 (미정이 아닐 때)
                        if (!_isEndTimeFlexible && _endTime == null) {
                          _endTime = const TimeOfDay(hour: 18, minute: 0);
                        }
                        _currentStep = _DateTimeSelectionStep.endTime;
                      } else {
                        // 종료 시간이 미정이 아니면 기본값 설정
                        if (!_isEndTimeFlexible) {
                          _endTime ??= const TimeOfDay(hour: 18, minute: 0);
                        }
                        _currentStep = _DateTimeSelectionStep.complete;
                      }
                    })
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.accentColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Theme.of(context).colorScheme.outline,
                minimumSize: const Size(0, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                isStartTime ? '다음: 종료 시간' : '완료',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 완료 단계 하단 확인 버튼
  Widget _buildFinalConfirmButton() {
    return Container(
      padding: EdgeInsets.only(left: 20, right: 20, top: 16, bottom: MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2))]),
      child: ElevatedButton(
        onPressed: _onPickerConfirm,
        style: ElevatedButton.styleFrom(backgroundColor: widget.accentColor, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        child: const Text('확인', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }

  void _onPickerConfirm() {
    if (_startDate == null || _endDate == null) return;
    // 시작/종료 시간이 각각 미정이거나 선택되어야 함
    final startTimeOk = _isStartTimeFlexible || _startTime != null;
    final endTimeOk = _isEndTimeFlexible || _endTime != null;
    if (!startTimeOk || !endTimeOk) return;
    
    // isTimeFlexible은 둘 다 미정일 때만 true
    final isTimeFlexible = _isStartTimeFlexible && _isEndTimeFlexible;
    Navigator.pop(context, _DateTimeRangeResult(
      startDate: _startDate!, 
      endDate: _endDate, 
      startTime: _startTime, 
      endTime: _endTime, 
      isTimeFlexible: isTimeFlexible,
    ));
  }

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
  String _fmtTime(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  String _fmtDateFull(DateTime d) => '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
}
