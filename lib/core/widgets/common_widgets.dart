import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import 'svg_icons.dart';

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
        ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.textPrimary),
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
              color: backgroundColor ?? AppColors.primary,
              width: 1.5,
            ),
            foregroundColor: textColor ?? AppColors.primary,
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
          backgroundColor: backgroundColor ?? AppColors.primary,
          foregroundColor: textColor ?? AppColors.textPrimary,
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
                ? const BorderSide(color: AppColors.divider)
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
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingM,
        vertical: AppSizes.paddingS,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(borderRadius ?? AppSizes.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                      color: borderColor ?? AppColors.primary,
                      width: 3,
                    )
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipOval(
              child: _buildAvatarContent(),
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
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildAvatarContent() {
    // URL이 없거나 빈 문자열인 경우 기본 아이콘
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildPlaceholder();
    }
    
    // default_avatar: 형식인 경우 기본 아바타 아이콘 표시
    if (imageUrl!.startsWith('default_avatar:')) {
      return _buildPlaceholder();
    }
    
    // 일반 URL인 경우 네트워크 이미지
    return CachedNetworkImage(
      imageUrl: imageUrl!,
      fit: BoxFit.cover,
      placeholder: (context, url) => _buildPlaceholder(),
      errorWidget: (context, url, error) => _buildPlaceholder(),
    );
  }
  
  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.primaryLight,
      child: Icon(
        placeholderIcon,
        size: size * 0.5,
        color: AppColors.primary,
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
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
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
          style: const TextStyle(
            fontSize: 15,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: AppColors.textHint)
                : null,
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}

// ===== 빈 상태 위젯 =====
/// 데이터가 없을 때 표시하는 위젯 (SVG 이미지 지원)
class MingrrEmptyState extends StatelessWidget {
  final IconData? icon;
  final String? svgAsset;
  final String title;
  final String? subtitle;
  final String? buttonText;
  final VoidCallback? onButtonPressed;

  const MingrrEmptyState({
    super.key,
    this.icon,
    this.svgAsset,
    required this.title,
    this.subtitle,
    this.buttonText,
    this.onButtonPressed,
  }) : assert(icon != null || svgAsset != null, 'icon 또는 svgAsset 중 하나는 필수입니다');

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (svgAsset != null)
              MingrrSvgIcon(
                assetPath: svgAsset!,
                width: 120,
                height: 120,
              )
            else
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 48,
                  color: AppColors.primary,
                ),
              ),
            const SizedBox(height: AppSizes.gapXL),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSizes.gapS),
              Text(
                subtitle!,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (buttonText != null && onButtonPressed != null) ...[
              const SizedBox(height: AppSizes.gapXL),
              MingrrButton(
                text: buttonText!,
                onPressed: onButtonPressed,
                width: 200,
              ),
            ],
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
            child: const CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: AppSizes.gapM),
            Text(
              message!,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
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

  // 인증 배지
  factory MingrrBadge.verified() {
    return const MingrrBadge(
      text: '인증됨',
      backgroundColor: AppColors.success,
      textColor: Colors.white,
      icon: Icons.verified,
    );
  }

  // 산책 중 배지
  factory MingrrBadge.walking() {
    return const MingrrBadge(
      text: '산책 중',
      backgroundColor: AppColors.walk,
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
        color: backgroundColor ?? AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: isSmall ? 12 : 14,
              color: textColor ?? AppColors.textPrimary,
            ),
            SizedBox(width: isSmall ? 2 : 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: isSmall ? 10 : 12,
              fontWeight: FontWeight.w600,
              color: textColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ===== 알림 아이콘 버튼 =====
/// AppBar에서 사용하는 알림 아이콘 (배지 포함)
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
                  color: AppColors.error,
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
        color: AppColors.dating.withOpacity(0.15),
        borderRadius: borderRadius,
      ),
      child: Center(
        child: Icon(
          Icons.pets,
          size: (height ?? 100) * 0.4,
          color: AppColors.dating.withOpacity(0.5),
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
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(
          isClose ? Icons.close : Icons.arrow_back_ios_new,
          size: 20,
          color: iconColor ?? AppColors.textPrimary,
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
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          if (actionText != null)
            GestureDetector(
              onTap: onActionTap,
              child: Text(
                actionText!,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ===== 공통 날짜 선택기 =====
/// 날짜 선택 위젯 (단일 날짜, 시작일/종료일, 생년월일 모두 지원)
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
  });

  /// 시작일/종료일 모드인지 확인
  bool get isRangeMode => onEndDateSelect != null;

  @override
  Widget build(BuildContext context) {
    if (isRangeMode) {
      return _buildRangeSelector(context);
    }
    return _buildSingleSelector(context);
  }

  /// 단일 날짜 선택기
  Widget _buildSingleSelector(BuildContext context) {
    final color = accentColor ?? AppColors.primary;
    final displayDate = date ?? DateTime.now();
    
    return GestureDetector(
      onTap: () => _selectDate(context, isStart: true),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: color, size: 20),
            const SizedBox(width: 12),
            Text(
              label ?? _formatDate(displayDate),
              style: TextStyle(
                color: date != null ? AppColors.textPrimary : AppColors.textHint,
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: AppColors.textHint, size: 20),
          ],
        ),
      ),
    );
  }

  /// 시작일/종료일 선택기
  Widget _buildRangeSelector(BuildContext context) {
    final color = accentColor ?? AppColors.primary;
    
    return Row(
      children: [
        Expanded(
          child: _buildDateButton(
            context,
            date: date,
            label: startLabel,
            color: color,
            onTap: () => _selectDate(context, isStart: true),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text('~'),
        ),
        Expanded(
          child: _buildDateButton(
            context,
            date: endDate,
            label: endLabel,
            color: color,
            onTap: () => _selectDate(context, isStart: false),
          ),
        ),
      ],
    );
  }

  Widget _buildDateButton(
    BuildContext context, {
    required DateTime? date,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 16, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  date != null ? _formatDateShort(date) : label,
                  style: TextStyle(
                    color: date != null ? AppColors.textPrimary : AppColors.textHint,
                    fontSize: 14,
                  ),
                ),
              ),
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
    final color = accentColor ?? AppColors.primary;
    
    // 날짜 범위 설정
    DateTime effectiveFirstDate;
    DateTime effectiveLastDate;
    DateTime initialDate;
    
    if (isBirthDate) {
      effectiveFirstDate = DateTime(birthDateMinYear);
      effectiveLastDate = DateTime.now();
      initialDate = date ?? DateTime.now().subtract(const Duration(days: 365));
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

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: effectiveFirstDate,
      lastDate: effectiveLastDate,
      locale: const Locale('ko', 'KR'),
      helpText: helpText ?? (isBirthDate ? '생년월일 선택' : null),
      cancelText: '취소',
      confirmText: '선택',
      fieldLabelText: '날짜 입력',
      fieldHintText: 'YYYY/MM/DD',
      errorFormatText: '올바른 날짜 형식이 아닙니다',
      errorInvalidText: '선택할 수 없는 날짜입니다',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: color,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
            dialogBackgroundColor: Colors.white,
            datePickerTheme: DatePickerThemeData(
              backgroundColor: Colors.white,
              headerBackgroundColor: color,
              headerForegroundColor: Colors.white,
              headerHeadlineStyle: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              dayStyle: const TextStyle(fontSize: 14),
              weekdayStyle: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
              todayBackgroundColor: WidgetStateProperty.all(color.withOpacity(0.1)),
              todayForegroundColor: WidgetStateProperty.all(color),
              todayBorder: BorderSide(color: color, width: 1),
              dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return color;
                }
                return null;
              }),
              dayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                if (states.contains(WidgetState.disabled)) {
                  return AppColors.textHint;
                }
                return AppColors.textPrimary;
              }),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              dayOverlayColor: WidgetStateProperty.all(color.withOpacity(0.1)),
              rangeSelectionBackgroundColor: color.withOpacity(0.2),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: color,
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          child: child!,
        );
      },
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

  String _formatDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
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
        fillColor: AppColors.background,
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
            color: color ?? AppColors.primary,
            strokeWidth: 3,
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
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
              color: AppColors.textHint,
            ),
            const SizedBox(height: 16),
            Text(
              title ?? '오류가 발생했습니다',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textHint,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
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
    _show(context, message, AppColors.success);
  }

  /// 에러 메시지 표시 (빨간색)
  static void error(BuildContext context, String message) {
    _show(context, message, AppColors.error);
  }

  /// 정보 메시지 표시 (기본 색상)
  static void info(BuildContext context, String message) {
    _show(context, message, AppColors.textSecondary);
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
        backgroundColor: backgroundColor ?? AppColors.textSecondary,
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
