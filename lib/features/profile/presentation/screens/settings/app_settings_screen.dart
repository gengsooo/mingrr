import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../../../../../core/constants/app_sizes.dart';
import '../../../../../core/providers/theme_provider.dart';
import '../../../../../core/widgets/common_widgets.dart';

/// ============================================================
/// 앱 설정 화면
/// 
/// 기능:
/// - 다크모드 설정 (시스템/라이트/다크)
/// - 캐시 삭제
/// ============================================================

class AppSettingsScreen extends ConsumerStatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  ConsumerState<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends ConsumerState<AppSettingsScreen> {
  bool _isClearing = false;

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('앱 설정'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.paddingM),
        children: [
          // 다크모드 설정
          MingrrCard(
            margin: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    '화면 모드',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                ...AppThemeMode.values.map((mode) => _buildThemeModeOption(context, mode, themeMode)),
              ],
            ),
          ),
          
          const SizedBox(height: AppSizes.gapL),
          
          // 캐시 삭제
          MingrrCard(
            margin: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    '저장 공간',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.delete_outline, color: Colors.red),
                  ),
                  title: const Text('캐시 삭제'),
                  subtitle: Text(
                    '이미지 캐시를 삭제하여 저장 공간을 확보합니다',
                    style: theme.textTheme.bodySmall,
                  ),
                  trailing: _isClearing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
                  onTap: _isClearing ? null : _clearCache,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeModeOption(BuildContext context, AppThemeMode mode, AppThemeMode currentMode) {
    final isSelected = mode == currentMode;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.2) : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          mode.icon,
          color: isSelected ? Theme.of(context).colorScheme.primary : colorScheme.onSurfaceVariant,
        ),
      ),
      title: Text(
        mode.displayName,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? Theme.of(context).colorScheme.primary : colorScheme.onSurface,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
          : Icon(Icons.circle_outlined, color: colorScheme.onSurfaceVariant),
      onTap: () {
        ref.read(themeModeProvider.notifier).setThemeMode(mode);
      },
    );
  }

  Future<void> _clearCache() async {
    setState(() => _isClearing = true);
    
    try {
      await DefaultCacheManager().emptyCache();
      
      if (mounted) {
        MingrrSnackBar.success(context, '캐시가 삭제되었습니다');
      }
    } catch (e) {
      if (mounted) {
        MingrrSnackBar.error(context, '캐시 삭제 중 오류가 발생했습니다');
      }
    } finally {
      if (mounted) {
        setState(() => _isClearing = false);
      }
    }
  }
}
