import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/constants/app_sizes.dart';
import '../../../../../core/widgets/common_widgets.dart';
import '../../../../../core/widgets/mingrr_bottom_sheet.dart';

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
      appBar: AppBar(
        title: const Text('고객센터'),
      ),
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
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    '문의하기',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                MingrrSettingsTile(
                  icon: Icons.chat_bubble_outline,
                  title: '카카오톡 문의',
                  subtitle: '평일 10:00 ~ 18:00 (주말/공휴일 휴무)',
                  iconColor: const Color(0xFF3C1E1E),
                  iconBackgroundColor: const Color(0xFFFEE500).withValues(alpha: 0.2),
                  onTap: () => _openKakaoChannel(context),
                ),
                MingrrSettingsTile(
                  icon: Icons.email_outlined,
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
                  padding: const EdgeInsets.only(bottom: 12),
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

  // TODO: 실제 카카오톡 채널 URL로 변경
  Future<void> _openKakaoChannel(BuildContext context) async {
    const kakaoChannelUrl = 'https://pf.kakao.com/_xxxxx'; // TODO: 실제 URL로 변경
    
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
        MingrrSnackBar.error(context, '카카오톡을 열 수 없습니다');
      }
    }
  }

  // TODO: 실제 이메일 주소로 변경
  Future<void> _sendEmail(BuildContext context) async {
    const email = 'support@mingrr.com'; // TODO: 실제 이메일로 변경
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=[밍그르] 문의드립니다',
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
        MingrrSnackBar.error(context, '이메일을 열 수 없습니다');
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
          padding: const EdgeInsets.only(bottom: 16),
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
        'title': '[안내] 밍그르 서비스 오픈!',
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
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'NEW',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
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
        height: MediaQuery.of(context).size.height * 0.7,
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
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                notice['title'] as String,
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              notice['date'] as String,
              style: theme.textTheme.labelSmall,
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  '공지사항 내용이 여기에 표시됩니다.\n\n'
                  '밍그르를 이용해 주셔서 감사합니다.\n\n'
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
