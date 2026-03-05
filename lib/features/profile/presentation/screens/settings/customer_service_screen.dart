import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/constants/app_icons.dart';
import '../../../../../core/constants/app_sizes.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/common_widgets.dart';
import '../../../../../core/widgets/sheets/mingrr_bottom_sheet.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../../../core/utils/error_handler.dart';

/// ============================================================
/// 고객센터 화면
/// 
/// 기능:
/// - 1:1 문의 (카카오톡 채널 또는 이메일)
/// - FAQ (자주 묻는 질문)
/// - 공지사항
/// 
/// TODO: 실제 카카오톡 채널 URL 및 이메일 주소 설정 필요
/// TODO: FAQ 및 공지사항 데이터 연동 필요
/// ============================================================

class CustomerServiceScreen extends StatelessWidget {
  const CustomerServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: const MingrrAppBar(title: '고객센터'),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.paddingM),
        children: [
          // 문의하기
          MingrrCard(
            margin: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.paddingM),
                  child: Text(
                    '문의하기',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                MingrrSettingsTile(
                  icon: AppIcons.chatBubbleOutlined,
                  title: '카카오톡 문의',
                  subtitle: '평일 10:00 ~ 18:00 (주말/공휴일 휴무)',
                  iconColor: const Color(0xFF3C1E1E),
                  iconBackgroundColor: const Color(0xFFFEE500).withValues(alpha: AppOpacity.o20),
                  onTap: () => _openKakaoChannel(context),
                ),
                MingrrSettingsTile(
                  icon: AppIcons.email,
                  title: '이메일 문의',
                  subtitle: 'support@mingrr.com',
                  onTap: () => _sendEmail(context),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppSizes.gapL),
          
          // FAQ
          MingrrCard(
            margin: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.paddingM),
                  child: Text(
                    '자주 묻는 질문',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                ..._buildFaqItems(context),
              ],
            ),
          ),
          
          const SizedBox(height: AppSizes.gapL),
          
          // 공지사항
          MingrrCard(
            margin: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '공지사항',
                      style: theme.textTheme.titleLarge,
                    ),
                    TextButton(
                      onPressed: () => _showAllNotices(context),
                      child: const Text('전체보기'),
                    ),
                  ],
                ),
                ..._buildNoticeItems(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 카카오톡 채널 열기
  Future<void> _openKakaoChannel(BuildContext context) async {
    // TODO: 실제 카카오톡 채널 URL로 변경 필요
    const kakaoChannelUrl = 'https://pf.kakao.com/_mingrr';
    
    try {
      final uri = Uri.parse(kakaoChannelUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          MingrrSnackBar.info(context, '카카오톡 채널 준비 중입니다');
        }
      }
    } catch (e) {
      if (context.mounted) {
        ErrorHandler.showError(context, e, tag: 'CustomerService', operation: '카카오톡 열기');
      }
    }
  }

  /// 이메일 문의 열기
  Future<void> _sendEmail(BuildContext context) async {
    // TODO: 실제 이메일 주소로 변경 필요
    const email = 'support@mingrr.com';
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=[밍그르르] 문의드립니다',
    );
    
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (context.mounted) {
          MingrrSnackBar.info(context, '이메일 앱을 열 수 없습니다');
        }
      }
    } catch (e) {
      if (context.mounted) {
        ErrorHandler.showError(context, e, tag: 'CustomerService', operation: '이메일 열기');
      }
    }
  }

  List<Widget> _buildFaqItems(BuildContext context) {
    final theme = Theme.of(context);
    
    final faqList = [
      {
        'question': '반려동물은 어떻게 등록하나요?',
        'answer': '프로필 화면에서 "내 반려동물" 섹션의 "추가" 버튼을 눌러 등록할 수 있습니다.',
      },
      {
        'question': '산책 기록은 어디서 확인하나요?',
        'answer': '홈 화면 또는 프로필 화면의 "활동 기록"에서 확인할 수 있습니다.',
      },
      {
        'question': '데이팅 매칭은 어떻게 이루어지나요?',
        'answer': '데이팅 탭에서 마음에 드는 반려동물에게 좋아요를 보내면, 상대방도 좋아요를 보낼 경우 매칭됩니다.',
      },
      {
        'question': '회원 탈퇴는 어떻게 하나요?',
        'answer': '프로필 > 설정 > 계정 관리 > 회원 탈퇴에서 진행할 수 있습니다.',
      },
    ];

    return faqList.map((faq) => ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text(
        faq['question']!,
        style: theme.textTheme.bodyMedium,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSizes.paddingL),
          child: Text(
            faq['answer']!,
            style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
          ),
        ),
      ],
    )).toList();
  }

  List<Widget> _buildNoticeItems(BuildContext context) {
    final theme = Theme.of(context);
    
    final notices = [
      {
        'title': '[안내] 밍그르르 서비스 오픈!',
        'date': '2025.01.10',
        'isNew': true,
      },
      {
        'title': '[업데이트] v1.0.0 업데이트 안내',
        'date': '2025.01.10',
        'isNew': true,
      },
      {
        'title': '[이벤트] 오픈 기념 이벤트 안내',
        'date': '2025.01.10',
        'isNew': false,
      },
    ];

    return notices.map((notice) => ListTile(
      contentPadding: EdgeInsets.zero,
      title: Row(
        children: [
          if (notice['isNew'] == true) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: AppSizes.paddingXXS),
              margin: const EdgeInsets.only(right: AppSizes.paddingS),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                borderRadius: BorderRadius.circular(AppSizes.radiusS),
              ),
              child: Text(
                'NEW',
                style: AppTextStyles.labelSmall(context).withWeight(FontWeight.w600).withColor(Colors.white),
              ),
            ),
          ],
          Expanded(
            child: Text(
              notice['title'] as String,
              style: theme.textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      subtitle: Text(
        notice['date'] as String,
        style: theme.textTheme.labelSmall,
      ),
      onTap: () => _showNoticeDetail(context, notice),
    )).toList();
  }

  void _showAllNotices(BuildContext context) {
    MingrrSnackBar.info(context, '공지사항 전체 목록 준비 중입니다');
  }

  void _showNoticeDetail(BuildContext context, Map<String, dynamic> notice) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: ResponsiveUtils.heightPercent(context, 0.7),
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.bottomSheetRadius)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: BottomSheetHandle()),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingS),
              child: Text(
                notice['title'] as String,
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppSizes.gapS),
            Text(
              notice['date'] as String,
              style: theme.textTheme.labelSmall,
            ),
            const SizedBox(height: 20),
            const MingrrDivider(),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  '공지사항 내용이 여기에 표시됩니다.\n\n'
                  '밍그르르를 이용해 주셔서 감사합니다.\n\n'
                  '더 좋은 서비스로 보답하겠습니다.',
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
