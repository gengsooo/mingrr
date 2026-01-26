import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/pet_model.dart';
import '../../models/marketplace_model.dart';
import '../../models/group_model.dart';
import '../../models/community_post_model.dart';
import '../../models/health_model.dart';
import '../constants/pet_constants.dart';
import '../constants/app_sizes.dart';
import '../theme/app_text_styles.dart';
import '../constants/app_strings.dart';
import '../widgets/common_widgets.dart';
import '../widgets/sheets/mingrr_bottom_sheet.dart';
import '../utils/responsive_utils.dart';

/// ============================================================
/// 공유 서비스
/// 
/// 기능:
/// - 반려동물 프로필 공유
/// - 상품 공유
/// - 소모임 공유
/// - 딥링크 생성
/// ============================================================
class ShareService {
  ShareService._();
  
  /// 앱 딥링크 기본 URL
  static const String _baseUrl = 'https://mingrr.app';
  
  // ===== 반려동물 공유 =====
  
  /// 반려동물 상세 공유
  static Future<void> sharePet(BuildContext context, PetModel pet) async {
    final url = '$_baseUrl/pet/${pet.id}';
    final genderEmoji = pet.gender == PetGender.male ? '♂️' : '♀️';
    final text = '${pet.name} $genderEmoji\n'
        '${pet.breed ?? "믹스견"} · ${pet.ageString}\n\n'
        '${AppStrings.appName}에서 확인하기:\n$url';
    
    await _share(context, text);
  }
  
  /// 반려동물 링크 복사
  static Future<void> copyPetLink(BuildContext context, String petId) async {
    final url = '$_baseUrl/pet/$petId';
    await _copyToClipboard(context, url);
  }
  
  // ===== 상품 공유 =====
  
  /// 상품 공유
  static Future<void> shareProduct(BuildContext context, ProductModel product) async {
    final url = '$_baseUrl/product/${product.id}';
    final priceText = product.price > 0 
        ? '${_formatPrice(product.price)}원' 
        : '나눔';
    final text = '${product.title}\n'
        '$priceText\n\n'
        '${AppStrings.appName}에서 확인하기:\n$url';
    
    await _share(context, text);
  }
  
  /// 상품 링크 복사
  static Future<void> copyProductLink(BuildContext context, String productId) async {
    final url = '$_baseUrl/product/$productId';
    await _copyToClipboard(context, url);
  }
  
  // ===== 소모임 공유 =====
  
  /// 소모임 공유
  static Future<void> shareGroup(BuildContext context, GroupModel group) async {
    final url = '$_baseUrl/group/${group.id}';
    final text = '${group.name}\n'
        '${group.description}\n\n'
        '멤버 ${group.memberIds.length}명이 함께하고 있어요!\n'
        '${AppStrings.appName}에서 확인하기:\n$url';
    
    await _share(context, text);
  }
  
  /// 소모임 링크 복사
  static Future<void> copyGroupLink(BuildContext context, String groupId) async {
    final url = '$_baseUrl/group/$groupId';
    await _copyToClipboard(context, url);
  }
  
  // ===== 알바 공유 =====
  
  /// 알바 공유
  static Future<void> shareJob(BuildContext context, JobModel job) async {
    final url = '$_baseUrl/job/${job.id}';
    final text = '${job.title}\n'
        '${job.typeString} · ${job.priceString}\n\n'
        '${AppStrings.appName}에서 확인하기:\n$url';
    
    await _share(context, text);
  }
  
  /// 알바 링크 복사
  static Future<void> copyJobLink(BuildContext context, String jobId) async {
    final url = '$_baseUrl/job/$jobId';
    await _copyToClipboard(context, url);
  }
  
  // ===== 커뮤니티 게시글 공유 =====
  
  /// 커뮤니티 게시글 공유
  static Future<void> sharePost(BuildContext context, CommunityPostModel post) async {
    final url = '$_baseUrl/post/${post.id}';
    final categoryEmoji = post.category.emoji;
    final titleText = post.title.isNotEmpty ? post.title : post.content;
    final previewText = titleText.length > 50 
        ? '${titleText.substring(0, 50)}...' 
        : titleText;
    final text = '$categoryEmoji ${post.category.label}\n'
        '$previewText\n\n'
        '${AppStrings.appName}에서 확인하기:\n$url';
    
    await _share(context, text);
  }
  
  /// 커뮤니티 게시글 링크 복사
  static Future<void> copyPostLink(BuildContext context, String postId) async {
    final url = '$_baseUrl/post/$postId';
    await _copyToClipboard(context, url);
  }
  
  // ===== 산책 기록 공유 =====
  
  /// 산책 기록 공유
  static Future<void> shareWalkRecord(
    BuildContext context, 
    WalkRecordModel record, {
    List<String> petNames = const [],
  }) async {
    final url = '$_baseUrl/walk/${record.id}';
    final durationText = _formatDuration(record.durationMinutes);
    final distanceText = record.distanceString;
    final petText = petNames.isNotEmpty ? petNames.join(', ') : '반려동물';
    final text = '🐕 $petText와 함께한 산책\n'
        '⏱️ $durationText · 📍 $distanceText\n\n'
        '${AppStrings.appName}에서 확인하기:\n$url';
    
    await _share(context, text);
  }
  
  /// 산책 기록 링크 복사
  static Future<void> copyWalkRecordLink(BuildContext context, String recordId) async {
    final url = '$_baseUrl/walk/$recordId';
    await _copyToClipboard(context, url);
  }
  
  // ===== 앱 공유 =====
  
  /// 앱 공유
  static Future<void> shareApp(BuildContext context) async {
    const text = '${AppStrings.appName} - 반려동물 커뮤니티 앱 🐕🐈\n\n'
        '반려동물 친구 찾기, 산책, 중고거래, 소모임까지!\n'
        '지금 바로 시작해보세요.\n\n'
        '$_baseUrl';
    
    await _share(context, text);
  }
  
  // ===== 내부 메서드 =====
  
  /// 공유 실행
  static Future<void> _share(BuildContext context, String text) async {
    // share_plus 패키지가 없으므로 바텀시트로 대체
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _ShareBottomSheet(text: text),
    );
  }
  
  /// 클립보드에 복사
  static Future<void> _copyToClipboard(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    
    if (context.mounted) {
      MingrrSnackBar.success(context, '링크가 복사되었습니다');
    }
  }
  
  /// 가격 포맷팅
  static String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
  
  /// 시간 포맷팅 (분 → 시간/분)
  static String _formatDuration(int minutes) {
    if (minutes < 60) return '$minutes분';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return mins > 0 ? '$hours시간 $mins분' : '$hours시간';
  }
  
  /// 거리 포맷팅 (m → km)
  static String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)}km';
    }
    return '${meters.toInt()}m';
  }
}

/// 공유 바텀시트
class _ShareBottomSheet extends StatelessWidget {
  final String text;
  
  const _ShareBottomSheet({required this.text});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(
        left: AppSizes.paddingL,
        right: AppSizes.paddingL,
        bottom: AppSizes.paddingL,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.bottomSheetRadius)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BottomSheetHandle(),
          // 제목
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingS),
            child: Text(
              '공유하기',
              style: AppTextStyles.headlineMedium(context).withWeight(FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          
          // 공유 옵션들
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildShareOption(
                context,
                icon: Icons.copy,
                label: '링크 복사',
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: text));
                  if (context.mounted) {
                    Navigator.pop(context);
                    MingrrSnackBar.success(context, '복사되었습니다');
                  }
                },
              ),
              _buildShareOption(
                context,
                icon: Icons.chat_bubble,
                label: '카카오톡',
                onTap: () {
                  Navigator.pop(context);
                  MingrrSnackBar.info(context, '카카오톡 공유는 SDK 설정 후 사용 가능합니다');
                },
              ),
              _buildShareOption(
                context,
                icon: Icons.message,
                label: '문자',
                onTap: () {
                  Navigator.pop(context);
                  MingrrSnackBar.info(context, '문자 공유는 네이티브 설정 후 사용 가능합니다');
                },
              ),
              _buildShareOption(
                context,
                icon: Icons.more_horiz,
                label: '더보기',
                onTap: () {
                  Navigator.pop(context);
                  MingrrSnackBar.info(context, 'share_plus 패키지 설치 후 사용 가능합니다');
                },
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // 공유 내용 미리보기
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSizes.paddingM),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(AppSizes.radiusS),
            ),
            child: Text(
              text,
              style: AppTextStyles.bodyMedium(context).withColor(Colors.grey[700]!),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          SizedBox(height: ResponsiveUtils.bottomPaddingWith(context, 10)),
        ],
      ),
    );
  }
  
  Widget _buildShareOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 24, color: Colors.grey[700]),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTextStyles.bodySmall(context).withColor(Colors.grey[700]!),
          ),
        ],
      ),
    );
  }
}
