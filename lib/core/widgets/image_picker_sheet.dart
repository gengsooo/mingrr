import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

/// ============================================================
/// 이미지 선택 바텀시트
/// 
/// 기능:
/// - 카메라 촬영
/// - 갤러리에서 선택
/// - 대표 아이콘 선택 (강아지/사람)
/// ============================================================

/// 대표 아이콘 타입
enum DefaultAvatarType {
  dog,    // 강아지용 아이콘
  person, // 사람용 아이콘
}

/// 대표 아이콘 데이터
class DefaultAvatar {
  final String id;
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  
  const DefaultAvatar({
    required this.id,
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
  });
}

/// 강아지용 대표 아이콘 목록
final List<DefaultAvatar> dogDefaultAvatars = [
  DefaultAvatar(
    id: 'dog_1',
    icon: Icons.pets,
    backgroundColor: const Color(0xFFFFE0B2),
    iconColor: const Color(0xFFFF9800),
  ),
  DefaultAvatar(
    id: 'dog_2',
    icon: Icons.pets,
    backgroundColor: const Color(0xFFBBDEFB),
    iconColor: const Color(0xFF2196F3),
  ),
  DefaultAvatar(
    id: 'dog_3',
    icon: Icons.pets,
    backgroundColor: const Color(0xFFC8E6C9),
    iconColor: const Color(0xFF4CAF50),
  ),
  DefaultAvatar(
    id: 'dog_4',
    icon: Icons.pets,
    backgroundColor: const Color(0xFFFFCDD2),
    iconColor: const Color(0xFFF44336),
  ),
  DefaultAvatar(
    id: 'dog_5',
    icon: Icons.pets,
    backgroundColor: const Color(0xFFE1BEE7),
    iconColor: const Color(0xFF9C27B0),
  ),
  DefaultAvatar(
    id: 'dog_6',
    icon: Icons.pets,
    backgroundColor: const Color(0xFFB2EBF2),
    iconColor: const Color(0xFF00BCD4),
  ),
  DefaultAvatar(
    id: 'dog_7',
    icon: Icons.pets,
    backgroundColor: const Color(0xFFFFF9C4),
    iconColor: const Color(0xFFFFC107),
  ),
  DefaultAvatar(
    id: 'dog_8',
    icon: Icons.pets,
    backgroundColor: const Color(0xFFD7CCC8),
    iconColor: const Color(0xFF795548),
  ),
];

/// 사람용 대표 아이콘 목록
final List<DefaultAvatar> personDefaultAvatars = [
  DefaultAvatar(
    id: 'person_1',
    icon: Icons.person,
    backgroundColor: const Color(0xFFFFE0B2),
    iconColor: const Color(0xFFFF9800),
  ),
  DefaultAvatar(
    id: 'person_2',
    icon: Icons.person,
    backgroundColor: const Color(0xFFBBDEFB),
    iconColor: const Color(0xFF2196F3),
  ),
  DefaultAvatar(
    id: 'person_3',
    icon: Icons.person,
    backgroundColor: const Color(0xFFC8E6C9),
    iconColor: const Color(0xFF4CAF50),
  ),
  DefaultAvatar(
    id: 'person_4',
    icon: Icons.person,
    backgroundColor: const Color(0xFFFFCDD2),
    iconColor: const Color(0xFFF44336),
  ),
  DefaultAvatar(
    id: 'person_5',
    icon: Icons.person,
    backgroundColor: const Color(0xFFE1BEE7),
    iconColor: const Color(0xFF9C27B0),
  ),
  DefaultAvatar(
    id: 'person_6',
    icon: Icons.person,
    backgroundColor: const Color(0xFFB2EBF2),
    iconColor: const Color(0xFF00BCD4),
  ),
  DefaultAvatar(
    id: 'person_7',
    icon: Icons.person,
    backgroundColor: const Color(0xFFFFF9C4),
    iconColor: const Color(0xFFFFC107),
  ),
  DefaultAvatar(
    id: 'person_8',
    icon: Icons.person,
    backgroundColor: const Color(0xFFD7CCC8),
    iconColor: const Color(0xFF795548),
  ),
];

/// 이미지 선택 결과
class ImagePickerResult {
  final XFile? imageFile;           // 선택한 이미지 파일
  final DefaultAvatar? defaultAvatar; // 선택한 대표 아이콘
  final bool cleared;               // 이미지 삭제 여부
  
  const ImagePickerResult({
    this.imageFile,
    this.defaultAvatar,
    this.cleared = false,
  });
  
  bool get hasImage => imageFile != null;
  bool get hasDefaultAvatar => defaultAvatar != null;
}

/// 이미지 선택 바텀시트 표시
Future<ImagePickerResult?> showImagePickerSheet(
  BuildContext context, {
  required String title,
  DefaultAvatarType avatarType = DefaultAvatarType.dog,
  String? currentImageUrl,
  DefaultAvatar? currentDefaultAvatar,
  bool allowClear = true,
}) async {
  return showModalBottomSheet<ImagePickerResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => ImagePickerSheet(
      title: title,
      avatarType: avatarType,
      currentImageUrl: currentImageUrl,
      currentDefaultAvatar: currentDefaultAvatar,
      allowClear: allowClear,
    ),
  );
}

/// 이미지 선택 바텀시트 위젯
class ImagePickerSheet extends StatefulWidget {
  final String title;
  final DefaultAvatarType avatarType;
  final String? currentImageUrl;
  final DefaultAvatar? currentDefaultAvatar;
  final bool allowClear;
  
  const ImagePickerSheet({
    super.key,
    required this.title,
    this.avatarType = DefaultAvatarType.dog,
    this.currentImageUrl,
    this.currentDefaultAvatar,
    this.allowClear = true,
  });

  @override
  State<ImagePickerSheet> createState() => _ImagePickerSheetState();
}

class _ImagePickerSheetState extends State<ImagePickerSheet> {
  final ImagePicker _imagePicker = ImagePicker();
  XFile? _selectedImage;
  DefaultAvatar? _selectedDefaultAvatar;
  
  List<DefaultAvatar> get _avatars => widget.avatarType == DefaultAvatarType.dog
      ? dogDefaultAvatars
      : personDefaultAvatars;
  
  @override
  void initState() {
    super.initState();
    _selectedDefaultAvatar = widget.currentDefaultAvatar;
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: AppSizes.paddingL,
        right: AppSizes.paddingL,
        top: AppSizes.paddingL,
        bottom: MediaQuery.of(context).padding.bottom + AppSizes.paddingL,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // 타이틀
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          
          // 미리보기
          Center(
            child: _buildPreview(),
          ),
          const SizedBox(height: 24),
          
          // 카메라/갤러리 버튼
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.camera_alt,
                  label: '카메라',
                  onTap: _pickFromCamera,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.photo_library,
                  label: '갤러리',
                  onTap: _pickFromGallery,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // 대표 아이콘 선택
          const Text(
            '또는 대표 아이콘 선택',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          
          // 아이콘 그리드
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _avatars.map((avatar) => _buildAvatarOption(avatar)).toList(),
          ),
          const SizedBox(height: 24),
          
          // 하단 버튼
          Row(
            children: [
              if (widget.allowClear && (widget.currentImageUrl != null || widget.currentDefaultAvatar != null))
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context, const ImagePickerResult(cleared: true));
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('삭제'),
                  ),
                ),
              if (widget.allowClear && (widget.currentImageUrl != null || widget.currentDefaultAvatar != null))
                const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: (_selectedImage != null || _selectedDefaultAvatar != null)
                      ? () {
                          Navigator.pop(context, ImagePickerResult(
                            imageFile: _selectedImage,
                            defaultAvatar: _selectedDefaultAvatar,
                          ));
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.divider,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('저장'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildPreview() {
    Widget content;
    
    if (_selectedImage != null) {
      // 선택한 이미지 표시
      content = ClipOval(
        child: kIsWeb
            ? Image.network(
                _selectedImage!.path,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              )
            : Image.file(
                File(_selectedImage!.path),
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
      );
    } else if (_selectedDefaultAvatar != null) {
      // 선택한 대표 아이콘 표시
      content = Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: _selectedDefaultAvatar!.backgroundColor,
          shape: BoxShape.circle,
        ),
        child: Icon(
          _selectedDefaultAvatar!.icon,
          size: 50,
          color: _selectedDefaultAvatar!.iconColor,
        ),
      );
    } else if (widget.currentImageUrl != null) {
      // 기존 이미지 표시
      content = ClipOval(
        child: Image.network(
          widget.currentImageUrl!,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildDefaultPreview(),
        ),
      );
    } else if (widget.currentDefaultAvatar != null) {
      // 기존 대표 아이콘 표시
      content = Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: widget.currentDefaultAvatar!.backgroundColor,
          shape: BoxShape.circle,
        ),
        child: Icon(
          widget.currentDefaultAvatar!.icon,
          size: 50,
          color: widget.currentDefaultAvatar!.iconColor,
        ),
      );
    } else {
      content = _buildDefaultPreview();
    }
    
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.divider, width: 2),
      ),
      child: content,
    );
  }
  
  Widget _buildDefaultPreview() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: AppColors.background,
        shape: BoxShape.circle,
      ),
      child: Icon(
        widget.avatarType == DefaultAvatarType.dog ? Icons.pets : Icons.person,
        size: 50,
        color: AppColors.textHint,
      ),
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAvatarOption(DefaultAvatar avatar) {
    final isSelected = _selectedDefaultAvatar?.id == avatar.id;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDefaultAvatar = avatar;
          _selectedImage = null; // 이미지 선택 해제
        });
      },
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: avatar.backgroundColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 3,
          ),
        ),
        child: Icon(
          avatar.icon,
          size: 28,
          color: avatar.iconColor,
        ),
      ),
    );
  }
  
  Future<void> _pickFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = image;
          _selectedDefaultAvatar = null; // 대표 아이콘 선택 해제
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('카메라 접근 실패: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }
  
  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = image;
          _selectedDefaultAvatar = null; // 대표 아이콘 선택 해제
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('갤러리 접근 실패: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }
}
