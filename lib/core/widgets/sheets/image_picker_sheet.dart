import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/app_sizes.dart';
import '../../theme/app_text_styles.dart';
import '../../services/image_service.dart';
import '../dialogs/dialog_buttons.dart';
import '../common_widgets.dart';
import 'mingrr_bottom_sheet.dart';
import '../../utils/responsive_utils.dart';

/// ============================================================
/// 이미지 선택 바텀시트
/// 
/// 기능:
/// - 카메라 촬영
/// - 갤러리에서 선택
/// - 대표 아이콘 선택 (반려동물/사람)
/// ============================================================

/// 대표 아이콘 타입
enum DefaultAvatarType {
  pet,    // 반려동물용 아이콘
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

/// 반려동물용 대표 아이콘 목록
final List<DefaultAvatar> petDefaultAvatars = [
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
  DefaultAvatarType avatarType = DefaultAvatarType.pet,
  String? currentImageUrl,
  DefaultAvatar? currentDefaultAvatar,
  bool allowClear = true,
  bool enableCrop = true,
  ImageCropStyle cropStyle = ImageCropStyle.circle,
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
      enableCrop: enableCrop,
      cropStyle: cropStyle,
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
  final bool enableCrop;
  final ImageCropStyle cropStyle;
  
  const ImagePickerSheet({
    super.key,
    required this.title,
    this.avatarType = DefaultAvatarType.pet,
    this.currentImageUrl,
    this.currentDefaultAvatar,
    this.allowClear = true,
    this.enableCrop = true,
    this.cropStyle = ImageCropStyle.circle,
  });

  @override
  State<ImagePickerSheet> createState() => _ImagePickerSheetState();
}

class _ImagePickerSheetState extends State<ImagePickerSheet> {
  final ImagePicker _imagePicker = ImagePicker();
  XFile? _selectedImage;
  DefaultAvatar? _selectedDefaultAvatar;
  
  List<DefaultAvatar> get _avatars => widget.avatarType == DefaultAvatarType.pet
      ? petDefaultAvatars
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
        bottom: ResponsiveUtils.bottomPaddingWith(context, AppSizes.paddingL),
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSizes.radiusL)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BottomSheetHandle(),
          // 타이틀
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingS),
            child: Text(
              widget.title,
              style: AppTextStyles.headlineMedium(context).withWeight(FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSizes.gapM),
          
          // 미리보기
          Center(
            child: _buildPreview(),
          ),
          const SizedBox(height: AppSizes.gapXL),
          
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
              const SizedBox(width: AppSizes.gapM),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.photo_library,
                  label: '갤러리',
                  onTap: _pickFromGallery,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.gapLL),
          
          // 대표 아이콘 선택
          Text(
            '또는 대표 아이콘 선택',
            style: AppTextStyles.titleMedium(context).withColor(Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSizes.gapM),
          
          // 아이콘 그리드
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _avatars.map((avatar) => _buildAvatarOption(avatar)).toList(),
          ),
          const SizedBox(height: AppSizes.gapXL),
          
          // 하단 버튼
          Row(
            children: [
              if (widget.allowClear && (widget.currentImageUrl != null || widget.currentDefaultAvatar != null))
                Expanded(
                  child: MingrrDialogButton.destructiveOutlined(
                    text: '삭제',
                    onPressed: () {
                      Navigator.pop(context, const ImagePickerResult(cleared: true));
                    },
                  ),
                ),
              if (widget.allowClear && (widget.currentImageUrl != null || widget.currentDefaultAvatar != null))
                const SizedBox(width: AppSizes.gapM),
              Expanded(
                flex: 2,
                child: MingrrButton(
                  text: '저장',
                  onPressed: (_selectedImage != null || _selectedDefaultAvatar != null)
                      ? () {
                          Navigator.pop(context, ImagePickerResult(
                            imageFile: _selectedImage,
                            defaultAvatar: _selectedDefaultAvatar,
                          ));
                        }
                      : null,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  textColor: Colors.white,
                  height: 48,
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
        border: Border.all(color: Theme.of(context).colorScheme.outline, width: 2),
      ),
      child: content,
    );
  }
  
  Widget _buildDefaultPreview() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        shape: BoxShape.circle,
      ),
      child: Icon(
        widget.avatarType == DefaultAvatarType.pet ? Icons.pets : Icons.person,
        size: 50,
        color: Theme.of(context).colorScheme.outlineVariant,
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
      borderRadius: BorderRadius.circular(AppSizes.radiusS),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingL),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: AppOpacity.o10),
          borderRadius: BorderRadius.circular(AppSizes.radiusS),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: AppSizes.gapS),
            Text(
              label,
              style: AppTextStyles.titleMedium(context),
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
            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
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
        maxWidth: ImageLimits.maxResolution.toDouble(),
        maxHeight: ImageLimits.maxResolution.toDouble(),
        imageQuality: ImageLimits.imageQuality,
      );
      
      if (image != null) {
        await _processImage(image);
      }
    } catch (e) {
      if (mounted) {
        MingrrSnackBar.error(context, '카메라 접근 실패: $e');
      }
    }
  }
  
  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: ImageLimits.maxResolution.toDouble(),
        maxHeight: ImageLimits.maxResolution.toDouble(),
        imageQuality: ImageLimits.imageQuality,
      );
      
      if (image != null) {
        await _processImage(image);
      }
    } catch (e) {
      if (mounted) {
        MingrrSnackBar.error(context, '갤러리 접근 실패: $e');
      }
    }
  }
  
  Future<void> _processImage(XFile image) async {
    // 파일 크기 검사
    if (!kIsWeb) {
      final file = File(image.path);
      final fileSize = await file.length();
      if (fileSize > ImageLimits.maxFileSizeBytes) {
        if (mounted) {
          final sizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(1);
          MingrrSnackBar.warning(
            context, 
            '이미지 크기가 너무 큽니다 (${sizeMB}MB). 최대 ${ImageLimits.maxFileSizeMB}MB까지 업로드 가능합니다',
          );
        }
        return;
      }
    }

    // 크롭 기능 활성화 & 모바일인 경우만 크롭 적용
    if (widget.enableCrop && !kIsWeb) {
      final result = await ImageService.instance.crop(
        context: context,
        imagePath: image.path,
        style: widget.cropStyle,
      );
      
      if (result != null) {
        setState(() {
          _selectedImage = XFile(result.path);
          _selectedDefaultAvatar = null;
        });
        return;
      }
    }
    
    // 크롭 비활성화, 웹, 또는 크롭 취소 시 원본 사용
    setState(() {
      _selectedImage = image;
      _selectedDefaultAvatar = null;
    });
  }
}
