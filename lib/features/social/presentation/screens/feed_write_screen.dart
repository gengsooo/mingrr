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
import '../../../../models/feed_model.dart';
import '../providers/feed_provider.dart';

/// ============================================================
/// 커뮤니티 피드 글쓰기 화면
/// ============================================================

class FeedWriteScreen extends ConsumerStatefulWidget {
  final FeedPostModel? post; // 수정 시 기존 게시글

  const FeedWriteScreen({super.key, this.post});

  @override
  ConsumerState<FeedWriteScreen> createState() => _FeedWriteScreenState();
}

class _FeedWriteScreenState extends ConsumerState<FeedWriteScreen> {
  final _contentController = TextEditingController();
  final _tagController = TextEditingController();
  
  FeedCategory _selectedCategory = FeedCategory.daily;
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
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = context.features.community;

    return Scaffold(
      backgroundColor: context.detailBackground,
      appBar: AppBar(
        title: Text(_isEditMode ? '글 수정' : '글 작성'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _onSubmit,
            child: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: accentColor,
                    ),
                  )
                : Text(
                    _isEditMode ? '수정' : '등록',
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 카테고리 선택
            const Text('카테고리', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSizes.gapS),
            _buildCategorySelector(accentColor),
            const SizedBox(height: AppSizes.gapXL),

            // 본문 입력
            const Text('내용', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSizes.gapS),
            Container(
              decoration: BoxDecoration(
                color: context.inputBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
              ),
              child: TextField(
                controller: _contentController,
                maxLines: 8,
                maxLength: 2000,
                decoration: InputDecoration(
                  hintText: '내용을 입력해주세요',
                  hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                  counterStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.gapXL),

            // 이미지 추가
            const Text('사진', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSizes.gapS),
            _buildImagePicker(accentColor),
            const SizedBox(height: AppSizes.gapXL),

            // 태그 입력
            const Text('태그', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSizes.gapS),
            _buildTagInput(accentColor),
            const SizedBox(height: AppSizes.gapXL),

            // 익명 설정
            _buildAnonymousSwitch(accentColor),
            
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector(Color accentColor) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: FeedCategory.values.map((category) {
        final isSelected = _selectedCategory == category;
        return GestureDetector(
          onTap: () => setState(() => _selectedCategory = category),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? accentColor : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? accentColor : Theme.of(context).colorScheme.outline,
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

  Widget _buildImagePicker(Color accentColor) {
    final totalImages = _existingImageUrls.length + _selectedImages.length;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 이미지 목록
        if (totalImages > 0) ...[
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // 기존 이미지
                ..._existingImageUrls.asMap().entries.map((entry) {
                  return _buildImageTile(
                    imageUrl: entry.value,
                    onRemove: () {
                      setState(() => _existingImageUrls.removeAt(entry.key));
                    },
                  );
                }),
                // 새로 선택한 이미지
                ..._selectedImages.asMap().entries.map((entry) {
                  return _buildImageTile(
                    file: File(entry.value.path),
                    onRemove: () {
                      setState(() => _selectedImages.removeAt(entry.key));
                    },
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        
        // 이미지 추가 버튼
        if (totalImages < 5)
          GestureDetector(
            onTap: _pickImages,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).colorScheme.outline),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate, color: accentColor),
                  const SizedBox(width: 8),
                  Text(
                    '사진 추가 ($totalImages/5)',
                    style: TextStyle(color: accentColor, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImageTile({String? imageUrl, File? file, required VoidCallback onRemove}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: imageUrl != null
                ? Image.network(imageUrl, width: 100, height: 100, fit: BoxFit.cover)
                : Image.file(file!, width: 100, height: 100, fit: BoxFit.cover),
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
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagInput(Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 태그 목록
        if (_tags.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tags.map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('#$tag', style: TextStyle(fontSize: 13, color: accentColor)),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => setState(() => _tags.remove(tag)),
                      child: Icon(Icons.close, size: 14, color: accentColor),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
        ],
        
        // 태그 입력 필드
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: context.inputBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
                ),
                child: TextField(
                  controller: _tagController,
                  decoration: InputDecoration(
                    hintText: '태그 입력 (최대 10개)',
                    hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    prefixText: '#',
                    prefixStyle: TextStyle(color: accentColor),
                  ),
                  onSubmitted: _addTag,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _addTag(_tagController.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: const Text('추가', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ],
    );
  }

  void _addTag(String tag) {
    final trimmed = tag.trim().replaceAll('#', '');
    if (trimmed.isNotEmpty && !_tags.contains(trimmed) && _tags.length < 10) {
      setState(() {
        _tags.add(trimmed);
        _tagController.clear();
      });
    }
  }

  Widget _buildAnonymousSwitch(Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.inputBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('익명으로 작성', style: TextStyle(fontWeight: FontWeight.w500)),
              Text(
                '닉네임이 "익명"으로 표시됩니다',
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          Switch(
            value: _isAnonymous,
            onChanged: (value) => setState(() => _isAnonymous = value),
            activeColor: Colors.white,
            activeTrackColor: accentColor,
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

      final notifier = ref.read(feedProviderNotifier.notifier);
      
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
