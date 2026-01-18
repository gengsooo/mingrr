import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../../core/constants/app_sizes.dart';
import '../../../../../core/widgets/common_widgets.dart';
import '../../../../../core/widgets/mingrr_bottom_sheet.dart';

/// ============================================================
/// 앱 정보 화면
/// 
/// 기능:
/// - 버전 정보
/// - 이용약관
/// - 개인정보처리방침
/// - 오픈소스 라이선스
/// 
/// TODO: 실제 이용약관 및 개인정보처리방침 URL/내용 설정 필요
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
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.pets,
                    size: 40,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '밍그르',
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '반려동물과 함께하는 일상',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
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
                  padding: const EdgeInsets.only(bottom: 12),
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

  // TODO: 실제 이용약관 내용/URL로 변경
  void _showTerms(BuildContext context) {
    _showPolicySheet(
      context,
      title: '이용약관',
      content: '''
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
''',
    );
  }

  // TODO: 실제 개인정보처리방침 내용/URL로 변경
  void _showPrivacyPolicy(BuildContext context) {
    _showPolicySheet(
      context,
      title: '개인정보처리방침',
      content: '''
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
''',
    );
  }

  void _showPolicySheet(BuildContext context, {required String title, required String content}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.bottomSheetRadius)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: BottomSheetHandle()),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  content,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.6,
                  ),
                ),
              ),
            ),
          ],
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
        margin: const EdgeInsets.only(top: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
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
