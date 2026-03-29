import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../../../../../core/constants/app_icons.dart';
import '../../../../../core/constants/app_sizes.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/providers/theme_provider.dart';
import '../../../../../core/widgets/common_widgets.dart';
import '../../../../../core/utils/error_handler.dart';

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
                    style: AppTextStyles.titleLarge(context),
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
                    style: AppTextStyles.titleLarge(context),
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
        ErrorHandler.showError(context, e, tag: 'AppSettings', operation: '캐시 삭제');
      }
    } finally {
      if (mounted) {
        setState(() => _isClearing = false);
      }
    }
  }
}
