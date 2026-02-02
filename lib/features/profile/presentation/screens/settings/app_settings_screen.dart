import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../../../../../core/constants/app_icons.dart';
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

    return Scaffold(
      appBar: const MingrrAppBar(title: '앱 설정'),
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
                  padding: const EdgeInsets.only(bottom: AppSizes.paddingM),
                  child: Text(
                    '화면 모드',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                ...AppThemeMode.values.map((mode) => MingrrSettingsTile.radio(
                  icon: mode.icon,
                  title: mode.displayName,
                  isSelected: mode == themeMode,
                  onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(mode),
                )),
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
                  padding: const EdgeInsets.only(bottom: AppSizes.paddingM),
                  child: Text(
                    '저장 공간',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                MingrrSettingsTile.destructive(
                  icon: AppIcons.delete,
                  title: '캐시 삭제',
                  subtitle: '이미지 캐시를 삭제하여 저장 공간을 확보합니다',
                  onTap: _isClearing ? null : _clearCache,
                ),
              ],
            ),
          ),
        ],
      ),
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
