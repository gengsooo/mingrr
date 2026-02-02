import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../../core/constants/app_icons.dart';
import '../../../../../core/constants/app_sizes.dart';
import '../../../../../core/constants/legal_texts.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/common_widgets.dart';
import '../../../../../core/widgets/sheets/mingrr_bottom_sheet.dart';

/// ============================================================
/// 앱 정보 화면
/// 
/// 기능:
/// - 버전 정보
/// - 이용약관
/// - 개인정보처리방침
/// - 오픈소스 라이선스
/// 
/// 약관 내용은 lib/core/constants/legal_texts.dart에서 관리
/// ============================================================

class AppInfoScreen extends StatefulWidget {
  const AppInfoScreen({super.key});

  @override
  State<AppInfoScreen> createState() => _AppInfoScreenState();
}

class _AppInfoScreenState extends State<AppInfoScreen> {
  String _version = '';
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _version = info.version;
      _buildNumber = info.buildNumber;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      appBar: const MingrrAppBar(title: '앱 정보'),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.paddingM),
        children: [
          // 앱 로고 및 버전
          MingrrCard(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                const SizedBox(height: 20),
                // 앱 아이콘
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: AppOpacity.o10),
                    borderRadius: BorderRadius.circular(AppSizes.radiusL),
                  ),
                  child: Icon(
                    AppIcons.pet,
                    size: 40,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: AppSizes.gapL),
                Text(
                  '밍그르르',
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSizes.gapXS),
                Text(
                  '반려동물과 함께하는 일상',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSizes.gapL),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL, vertical: AppSizes.paddingS),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppSizes.radiusL),
                  ),
                  child: Text(
                    'v$_version ($_buildNumber)',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          
          const SizedBox(height: AppSizes.gapL),
          
          // 약관 및 정책
          MingrrCard(
            margin: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.paddingM),
                  child: Text(
                    '약관 및 정책',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                MingrrSettingsTile(
                  icon: AppIcons.description,
                  title: '이용약관',
                  onTap: () => _showTerms(context),
                ),
                MingrrSettingsTile(
                  icon: AppIcons.security,
                  title: '개인정보처리방침',
                  onTap: () => _showPrivacyPolicy(context),
                ),
                MingrrSettingsTile(
                  icon: AppIcons.developerMode,
                  title: '오픈소스 라이선스',
                  onTap: () => _showLicenses(context),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppSizes.gapXL),
          
          // 저작권
          Center(
            child: Text(
              '© 2025 MINGRR. All rights reserved.',
              style: theme.textTheme.labelSmall,
            ),
          ),
        ],
      ),
    );
  }

  /// 이용약관 표시
  void _showTerms(BuildContext context) {
    _showPolicySheet(context, title: '이용약관', content: termsOfService);
  }

  /// 개인정보처리방침 표시
  void _showPrivacyPolicy(BuildContext context) {
    _showPolicySheet(context, title: '개인정보처리방침', content: privacyPolicy);
  }

  void _showPolicySheet(BuildContext context, {required String title, required String content}) {
    showMingrrBottomSheet(
      context: context,
      title: title,
      height: 0.85,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingS),
        child: Text(
          content,
          style: AppTextStyles.bodyLarge(context).withColor(Theme.of(context).colorScheme.onSurfaceVariant).withHeight(1.6),
        ),
      ),
    );
  }

  void _showLicenses(BuildContext context) {
    showLicensePage(
      context: context,
      applicationName: '밍그르르',
      applicationVersion: 'v$_version',
      applicationIcon: Container(
        width: 60,
        height: 60,
        margin: const EdgeInsets.only(top: AppSizes.paddingL),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: AppOpacity.o10),
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
        ),
        child: Icon(
          AppIcons.pet,
          size: 30,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
