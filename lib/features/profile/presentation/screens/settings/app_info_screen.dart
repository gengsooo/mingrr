import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../../core/constants/app_sizes.dart';
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
/// 약관 내용 변경 시 아래 상수만 수정하면 됩니다:
/// - [_termsOfService] : 이용약관
/// - [_privacyPolicy] : 개인정보처리방침
/// ============================================================

// TODO: 실제 이용약관 내용으로 교체 필요 (법률 검토 후)
const String _termsOfService = '''
제1조 (목적)
이 약관은 밍그르(이하 "회사")가 제공하는 서비스의 이용조건 및 절차, 회사와 회원 간의 권리, 의무 및 책임사항 등을 규정함을 목적으로 합니다.

제2조 (정의)
1. "서비스"란 회사가 제공하는 반려동물 관련 모든 서비스를 의미합니다.
2. "회원"이란 회사와 서비스 이용계약을 체결하고 회원 아이디를 부여받은 자를 의미합니다.

제3조 (약관의 효력 및 변경)
1. 이 약관은 서비스를 이용하고자 하는 모든 회원에게 적용됩니다.
2. 회사는 필요한 경우 약관을 변경할 수 있으며, 변경된 약관은 공지사항을 통해 공지합니다.

[이하 약관 내용 계속...]

※ 본 약관은 예시이며, 실제 서비스 출시 전 법률 검토가 필요합니다.
''';

// TODO: 실제 개인정보처리방침 내용으로 교체 필요 (법률 검토 후)
const String _privacyPolicy = '''
밍그르(이하 "회사")는 개인정보보호법에 따라 이용자의 개인정보 보호 및 권익을 보호하고 개인정보와 관련한 이용자의 고충을 원활하게 처리할 수 있도록 다음과 같은 처리방침을 두고 있습니다.

1. 개인정보의 처리 목적
회사는 다음의 목적을 위하여 개인정보를 처리합니다.
- 회원 가입 및 관리
- 서비스 제공
- 마케팅 및 광고에의 활용

2. 개인정보의 처리 및 보유 기간
회사는 법령에 따른 개인정보 보유·이용기간 또는 정보주체로부터 개인정보를 수집 시에 동의받은 개인정보 보유·이용기간 내에서 개인정보를 처리·보유합니다.

3. 개인정보의 제3자 제공
회사는 원칙적으로 이용자의 개인정보를 제3자에게 제공하지 않습니다.

[이하 개인정보처리방침 내용 계속...]

※ 본 개인정보처리방침은 예시이며, 실제 서비스 출시 전 법률 검토가 필요합니다.
''';

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
      appBar: AppBar(
        title: const Text('앱 정보'),
      ),
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
                    Icons.pets,
                    size: 40,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: AppSizes.gapL),
                Text(
                  '밍그르',
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
                  icon: Icons.description_outlined,
                  title: '이용약관',
                  onTap: () => _showTerms(context),
                ),
                MingrrSettingsTile(
                  icon: Icons.privacy_tip_outlined,
                  title: '개인정보처리방침',
                  onTap: () => _showPrivacyPolicy(context),
                ),
                MingrrSettingsTile(
                  icon: Icons.code,
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
    _showPolicySheet(context, title: '이용약관', content: _termsOfService);
  }

  /// 개인정보처리방침 표시
  void _showPrivacyPolicy(BuildContext context) {
    _showPolicySheet(context, title: '개인정보처리방침', content: _privacyPolicy);
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
      applicationName: '밍그르',
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
          Icons.pets,
          size: 30,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
