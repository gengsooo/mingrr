import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// ============================================================
/// AppBar 공통 액션 버튼
/// 
/// 모든 화면에서 일관된 크기와 간격으로 사용:
/// - AppBarActionButton.search(): 검색 버튼
/// - AppBarActionButton.notification(): 알림 버튼
/// - AppBarActionButton.profile(): 프로필 버튼
/// 
/// 크기: 40x40 (터치 영역)
/// 간격: 없음 (버튼 간 0px)
/// 프로필만 우측 16px (화면 끝 여백)
/// ============================================================

class AppBarActionButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double size;
  final EdgeInsets padding;
  final _ActionType _type;

  const AppBarActionButton._({
    super.key,
    required this.child,
    this.onTap,
    this.size = 40,
    this.padding = EdgeInsets.zero,
    required _ActionType type,
  }) : _type = type;

  /// 검색 버튼
  factory AppBarActionButton.search({
    Key? key,
    required VoidCallback onTap,
  }) {
    return AppBarActionButton._(
      key: key,
      onTap: onTap,
      type: _ActionType.search,
      child: const Icon(Icons.search, size: 24),
    );
  }

  /// 알림 버튼
  factory AppBarActionButton.notification({
    Key? key,
    int badgeCount = 0,
  }) {
    return AppBarActionButton._(
      key: key,
      type: _ActionType.notification,
      child: _NotificationIcon(badgeCount: badgeCount),
    );
  }

  /// 프로필 버튼
  factory AppBarActionButton.profile({
    Key? key,
    String? imageUrl,
    Color? backgroundColor,
  }) {
    return AppBarActionButton._(
      key: key,
      type: _ActionType.profile,
      padding: const EdgeInsets.only(right: 16),
      child: _ProfileIcon(
        imageUrl: imageUrl,
        backgroundColor: backgroundColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: GestureDetector(
        onTap: () => _handleTap(context),
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: size,
          height: size,
          child: Center(child: child),
        ),
      ),
    );
  }

  void _handleTap(BuildContext context) {
    if (onTap != null) {
      onTap!();
      return;
    }
    
    switch (_type) {
      case _ActionType.search:
        break; // search는 항상 onTap 필수
      case _ActionType.notification:
        context.push('/notifications');
      case _ActionType.profile:
        context.push('/profile');
    }
  }
}

enum _ActionType { search, notification, profile }

/// 알림 아이콘 (배지 포함)
class _NotificationIcon extends StatelessWidget {
  final int badgeCount;

  const _NotificationIcon({this.badgeCount = 0});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.notifications_outlined, size: 24),
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
    );
  }
}

/// 프로필 아이콘
class _ProfileIcon extends StatelessWidget {
  final String? imageUrl;
  final Color? backgroundColor;

  const _ProfileIcon({
    this.imageUrl,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
          width: 1,
        ),
      ),
      child: imageUrl != null && imageUrl!.isNotEmpty
          ? ClipOval(
              child: Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildPlaceholder(context),
              ),
            )
          : _buildPlaceholder(context),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Icon(
      Icons.person,
      size: 18,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }
}
