import 'package:flutter/material.dart';
import '../constants/app_sizes.dart';
import '../services/bottom_sheet_stack_manager.dart';
import '../theme/app_theme.dart';
import 'mingrr_bottom_sheet.dart';

/// ============================================================
/// 프로필 모달 공통 컴포넌트
/// 
/// 반려동물/보호자/소모임 프로필 모달에서 공통으로 사용하는 빌딩 블록
/// 
/// 사용처:
/// - pet_profile_modal.dart
/// - guardian_profile_modal.dart
/// - group_profile_modal.dart
/// ============================================================

// ===== 1. 프로필 모달 컨테이너 =====

/// 프로필 모달 기본 컨테이너
/// 
/// 모든 프로필 모달의 기본 레이아웃을 제공
/// - BottomSheetHandle
/// - 헤더 (타이틀)
/// - 본문 (스크롤 가능)
/// - 하단 버튼 (선택적)
class ProfileModalContainer extends StatelessWidget {
  final String title;
  final Widget body;
  final Widget? bottomButton;
  final double maxHeightRatio;

  const ProfileModalContainer({
    super.key,
    required this.title,
    required this.body,
    this.bottomButton,
    this.maxHeightRatio = 0.75,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * maxHeightRatio,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BottomSheetHandle(),
          // 헤더
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
            child: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ),
          // 본문
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: body,
            ),
          ),
          // 하단 버튼
          if (bottomButton != null) bottomButton!,
        ],
      ),
    );
  }
}

// ===== 2. 프로필 헤더 =====

/// 프로필 헤더 (아바타 + 이름 + 부가정보)
/// 
/// 모든 프로필 모달 상단에 표시되는 기본 정보 영역
class ProfileModalHeader extends StatelessWidget {
  final Widget avatar;
  final String name;
  final Widget? badge;
  final Widget? subtitle;
  final Widget? trailing;

  const ProfileModalHeader({
    super.key,
    required this.avatar,
    required this.name,
    this.badge,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        avatar,
        const SizedBox(width: AppSizes.gapM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (badge != null) ...[
                    const SizedBox(width: 8),
                    badge!,
                  ],
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                subtitle!,
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ===== 3. 프로필 섹션 =====

/// 프로필 섹션 (타이틀 + 컨텐츠)
/// 
/// 사진, 인증배지, 태그, 소개 등 각 섹션에 사용
class ProfileModalSection extends StatelessWidget {
  final String title;
  final String? count;
  final Widget content;
  final EdgeInsets? padding;

  const ProfileModalSection({
    super.key,
    required this.title,
    this.count,
    required this.content,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            if (count != null)
              Text(
                count!,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSizes.gapS),
        if (padding != null)
          Padding(padding: padding!, child: content)
        else
          content,
      ],
    );
  }
}

// ===== 4. 가로 스크롤 리스트 =====

/// 가로 스크롤 아이템 리스트
/// 
/// 사진 갤러리, 반려동물 목록, 멤버 목록 등에 사용
class ProfileModalHorizontalList<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final double height;
  final double? itemWidth;
  final double itemSpacing;

  const ProfileModalHorizontalList({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.height = 80,
    this.itemWidth,
    this.itemSpacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Container(
            width: itemWidth,
            margin: EdgeInsets.only(
              right: index < items.length - 1 ? itemSpacing : 0,
            ),
            child: itemBuilder(context, item, index),
          );
        },
      ),
    );
  }
}

// ===== 5. 소개 박스 =====

/// 소개/설명 박스
/// 
/// 반려동물 소개, 소모임 설명 등에 사용
class ProfileModalDescriptionBox extends StatelessWidget {
  final String text;
  final Color? backgroundColor;

  const ProfileModalDescriptionBox({
    super.key,
    required this.text,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor ?? context.sectionBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          height: 1.5,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}

// ===== 6. 상세 정보 행 =====

/// 상세 정보 행 (아이콘 + 라벨 + 값)
/// 
/// 활동 지역, 개설일, 가입 상태 등에 사용
class ProfileModalDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;

  const ProfileModalDetailRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: iconColor ?? Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ===== 7. 상세 정보 컨테이너 =====

/// 상세 정보 컨테이너
/// 
/// 여러 DetailRow를 감싸는 배경 박스
class ProfileModalDetailsBox extends StatelessWidget {
  final List<Widget> children;
  final Color? backgroundColor;

  const ProfileModalDetailsBox({
    super.key,
    required this.children,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor ?? context.sectionBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

// ===== 8. 프로필 아바타 =====

/// 프로필 아바타 (원형)
/// 
/// 보호자/반려동물/소모임 아이콘 표시
class ProfileModalAvatar extends StatelessWidget {
  final double size;
  final String? imageUrl;
  final IconData fallbackIcon;
  final Color? backgroundColor;
  final Color? iconColor;

  const ProfileModalAvatar({
    super.key,
    this.size = 60,
    this.imageUrl,
    required this.fallbackIcon,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? 
        Theme.of(context).colorScheme.primary.withValues(alpha: 0.1);
    final fgColor = iconColor ?? Theme.of(context).colorScheme.primary;
    
    final hasValidImage = imageUrl != null && 
        imageUrl!.isNotEmpty && 
        !imageUrl!.startsWith('default_avatar:');

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: hasValidImage
          ? ClipOval(
              child: Image.network(
                imageUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(
                  fallbackIcon,
                  size: size * 0.5,
                  color: fgColor,
                ),
              ),
            )
          : Icon(
              fallbackIcon,
              size: size * 0.5,
              color: fgColor,
            ),
    );
  }
}

// ===== 9. 아이템 카드 =====

/// 가로 스크롤 리스트용 아이템 카드
/// 
/// 반려동물/멤버 아이템에 사용
class ProfileModalItemCard extends StatelessWidget {
  final Widget avatar;
  final String title;
  final Widget? subtitleWidget;
  final Widget? badge;
  final VoidCallback? onTap;
  final double width;

  const ProfileModalItemCard({
    super.key,
    required this.avatar,
    required this.title,
    this.subtitleWidget,
    this.badge,
    this.onTap,
    this.width = 100,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.sectionBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                avatar,
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
                if (subtitleWidget != null) ...[
                  const SizedBox(height: 4),
                  subtitleWidget!,
                ],
              ],
            ),
            if (badge != null)
              Positioned(
                top: 0,
                left: 0,
                child: badge!,
              ),
          ],
        ),
      ),
    );
  }
}

// ===== 10. 활동 기록 아이템 =====

/// 활동 기록 아이템
/// 
/// 산책, 데이팅, 거래, 소모임 횟수 표시
class ProfileModalActivityItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color? iconColor;

  const ProfileModalActivityItem({
    super.key,
    required this.icon,
    required this.label,
    required this.count,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: iconColor ?? Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 4),
        Text(
          '$count회',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ===== 11. 스택 모달 헬퍼 =====

/// 스택 방식 프로필 모달 표시 헬퍼
/// 
/// BottomSheetStackManager를 사용하여 순환 감지 및 스택 관리
Future<T?> showStackedProfileModal<T>({
  required BuildContext context,
  required String type,
  required String id,
  required Widget Function(BuildContext) builder,
}) {
  final stackManager = BottomSheetStackManager();
  final sheetId = BottomSheetStackManager.createSheetId(type, id);
  
  // 순환 감지: 같은 바텀시트가 이미 열려있으면 해당 바텀시트까지 닫기
  if (stackManager.hasCycle(sheetId)) {
    final closeCount = stackManager.popUntilAndGetCount(sheetId);
    for (int i = 0; i < closeCount; i++) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
  }
  
  // 스택에 등록
  stackManager.push(sheetId);
  
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: true,
    enableDrag: true,
    builder: builder,
  ).then((result) {
    // 바텀시트가 닫힐 때 스택에서 제거
    stackManager.pop(sheetId);
    return result;
  });
}
