import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/pet_model.dart';
import '../../models/marketplace_model.dart';
import '../../models/group_model.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';
import '../widgets/common_widgets.dart';
import '../widgets/mingrr_bottom_sheet.dart';

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
  
  /// 반려동물 프로필 공유
  static Future<void> sharePet(BuildContext context, PetModel pet) async {
    final url = '$_baseUrl/pet/${pet.id}';
    final text = '${pet.name}을(를) 만나보세요! 🐕\n'
        '${pet.breed ?? "믹스견"} · ${pet.ageString}\n\n'
        '${AppStrings.appName}에서 확인하기:\n$url';
    
    await _share(context, text);
  }
  
  /// 반려동물 프로필 링크 복사
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
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              '공유하기',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          SizedBox(height: MediaQuery.of(context).padding.bottom + 10),
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
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}
