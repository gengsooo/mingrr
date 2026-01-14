import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/feature_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/mingrr_bottom_sheet.dart';
import '../../../../core/widgets/tag_input.dart';
import '../../../../models/community_post_model.dart';
import '../providers/community_provider.dart';

/// ============================================================
/// 커뮤니티(Community) 게시글 작성 화면
/// 
/// 소셜 > 커뮤니티 > 글쓰기
/// 게시글 작성/수정, 이미지/동영상 업로드, 태그, 익명 설정
/// ============================================================

class CommunityWriteScreen extends ConsumerStatefulWidget {
  final CommunityPostModel? post; // 수정 시 기존 게시글

  const CommunityWriteScreen({super.key, this.post});

  @override
  ConsumerState<CommunityWriteScreen> createState() => _CommunityWriteScreenState();
}

class _CommunityWriteScreenState extends ConsumerState<CommunityWriteScreen> {
  final _contentController = TextEditingController();
  
  CommunityCategory _selectedCategory = CommunityCategory.daily;
  final List<XFile> _selectedImages = [];
  final List<String> _existingImageUrls = [];
  final List<String> _tags = [];
  bool _isAnonymous = false;
  bool _isLoading = false;

  bool get _isEditMode => widget.post != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      final post = widget.post!;
      _contentController.text = post.content;
      _selectedCategory = post.category;
      _existingImageUrls.addAll(post.imageUrls);
      _tags.addAll(post.tags);
      _isAnonymous = post.isAnonymous;
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Color get _accentColor {
    final features = Theme.of(context).extension<FeatureColors>();
    return features?.social ?? const Color(0xFF4DB6AC);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: context.detailBackground,
      appBar: AppBar(
        title: Text(_isEditMode ? '글 수정' : '글 작성'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 사진
            const Text('사진', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSizes.gapS),
            _buildImagePicker(),
            const SizedBox(height: AppSizes.gapXL),

            // 카테고리 선택
            const Text('카테고리', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSizes.gapS),
            _buildCategorySelector(),
            const SizedBox(height: AppSizes.gapXL),

            // 본문 입력
            const Text('내용', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSizes.gapS),
            Container(
              decoration: BoxDecoration(
                color: context.inputBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
              ),
              child: TextField(
                controller: _contentController,
                maxLines: 6,
                maxLength: 2000,
                decoration: InputDecoration(
                  hintText: '내용을 입력해주세요',
                  hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                  counterStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.gapL),

            // 태그 입력
            MingrrTagInput(
              tags: _tags,
              onTagsChanged: (tags) => setState(() {
                _tags.clear();
                _tags.addAll(tags);
              }),
              accentColor: _accentColor,
              labelText: '태그 (선택)',
            ),
            const SizedBox(height: AppSizes.gapXL),

            // 익명 설정
            _buildAnonymousSwitch(),
            
            const SizedBox(height: AppSizes.gapXXL),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomButton(),
    );
  }

  Widget _buildBottomButton() {
    return MingrrSubmitButtonBar(
      label: _isEditMode ? '수정' : '등록',
      onPressed: _onSubmit,
      isLoading: _isLoading,
      backgroundColor: _accentColor,
    );
  }

  Widget _buildCategorySelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: CommunityCategory.values.map((category) {
        final isSelected = _selectedCategory == category;
        return GestureDetector(
          onTap: () => setState(() => _selectedCategory = category),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? _accentColor : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? _accentColor : Theme.of(context).colorScheme.outline,
              ),
            ),
            child: Text(
              '${category.emoji} ${category.label}',
              style: TextStyle(
                fontSize: 13,
                color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildImagePicker() {
    final totalImages = _existingImageUrls.length + _selectedImages.length;
    
    return SizedBox(
      height: 80,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // 추가 버튼
          GestureDetector(
            onTap: _pickImages,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).colorScheme.outline),
                borderRadius: BorderRadius.circular(AppSizes.radiusM),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt, color: Theme.of(context).colorScheme.outlineVariant),
                  const SizedBox(height: 4),
                  Text('$totalImages/5', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.outlineVariant)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 기존 이미지
          ..._existingImageUrls.asMap().entries.map((entry) {
            return _buildImageTile(
              imageUrl: entry.value,
              onRemove: () => setState(() => _existingImageUrls.removeAt(entry.key)),
            );
          }),
          // 새로 선택한 이미지
          ..._selectedImages.asMap().entries.map((entry) {
            return _buildImageTile(
              file: File(entry.value.path),
              onRemove: () => setState(() => _selectedImages.removeAt(entry.key)),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildImageTile({String? imageUrl, File? file, required VoidCallback onRemove}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusM),
            child: imageUrl != null
                ? Image.network(imageUrl, width: 80, height: 80, fit: BoxFit.cover)
                : Image.file(file!, width: 80, height: 80, fit: BoxFit.cover),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnonymousSwitch() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.inputBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('익명으로 작성', style: TextStyle(fontWeight: FontWeight.w500)),
                Text(
                  '닉네임이 "익명"으로 표시됩니다',
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Switch(
            value: _isAnonymous,
            onChanged: (value) => setState(() => _isAnonymous = value),
            activeColor: Colors.white,
            activeTrackColor: _accentColor,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Theme.of(context).colorScheme.outlineVariant,
            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final remaining = 5 - (_existingImageUrls.length + _selectedImages.length);
    
    if (remaining <= 0) return;
    
    final images = await picker.pickMultiImage(
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 80,
    );
    
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images.take(remaining));
      });
    }
  }

  Future<void> _onSubmit() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      MingrrSnackBar.warning(context, '내용을 입력해주세요');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final firebase = FirebaseService();
      
      // 새 이미지 업로드
      final List<String> uploadedUrls = [..._existingImageUrls];
      for (final image in _selectedImages) {
        final url = await firebase.uploadImage(
          File(image.path),
          'feeds/${const Uuid().v4()}',
        );
        uploadedUrls.add(url);
      }

      final notifier = ref.read(communityNotifierProvider.notifier);
      
      if (_isEditMode) {
        await notifier.updatePost(
          postId: widget.post!.id,
          content: content,
          imageUrls: uploadedUrls,
          tags: _tags,
        );
        if (mounted) {
          Navigator.pop(context, true);
          MingrrSnackBar.success(context, '글이 수정되었습니다');
        }
      } else {
        final postId = await notifier.createPost(
          category: _selectedCategory,
          content: content,
          imageUrls: uploadedUrls,
          tags: _tags,
          isAnonymous: _isAnonymous,
        );
        
        if (mounted && postId != null) {
          Navigator.pop(context, true);
          MingrrSnackBar.success(context, '글이 등록되었습니다');
        }
      }
    } catch (e) {
      if (mounted) {
        MingrrSnackBar.error(context, '오류가 발생했습니다: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
