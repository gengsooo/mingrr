import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/feature_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/form_strings.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/utils/video_utils.dart';
import '../../../../core/utils/image_utils.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/mingrr_bottom_sheet.dart';
import '../../../../core/widgets/form_components.dart';
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
  XFile? _selectedVideo;
  String? _existingVideoUrl;
  String? _existingVideoThumbnailUrl;
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
      _existingVideoUrl = post.videoUrl;
      _existingVideoThumbnailUrl = post.videoThumbnailUrl;
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
    return Scaffold(
      backgroundColor: context.detailBackground,
      appBar: MingrrFormAppBar(
        title: _isEditMode ? ScreenTitles.communityEdit : ScreenTitles.communityWrite,
        onClose: () => Navigator.pop(context),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 사진/동영상
            MingrrSectionLabel(
              '미디어',
              suffix: '(사진 최대 ${ImageLimits.maxImageCount}장, 동영상 ${VideoLimits.maxDurationSeconds}초)',
            ),
            MingrrMediaPicker(
              existingImageUrls: _existingImageUrls,
              selectedImages: _selectedImages,
              onPickImages: _pickImages,
              onRemoveExistingImage: (index) => setState(() => _existingImageUrls.removeAt(index)),
              onRemoveSelectedImage: (index) => setState(() => _selectedImages.removeAt(index)),
              maxImages: ImageLimits.maxImageCount,
              existingVideoUrl: _existingVideoUrl,
              existingVideoThumbnailUrl: _existingVideoThumbnailUrl,
              selectedVideo: _selectedVideo,
              onPickVideo: _pickVideo,
              onRemoveVideo: () => setState(() {
                _existingVideoUrl = null;
                _existingVideoThumbnailUrl = null;
                _selectedVideo = null;
              }),
            ),
            const SizedBox(height: AppSizes.gapXL),

            // 카테고리 선택
            const MingrrSectionLabel(FormStrings.labelCategory),
            MingrrChipSelector<CommunityCategory>(
              items: CommunityCategory.values,
              selectedItem: _selectedCategory,
              onSelected: (category) => setState(() => _selectedCategory = category),
              labelBuilder: (category) => category.label,
              iconBuilder: (category) => category.icon,
              accentColor: _accentColor,
            ),
            const SizedBox(height: AppSizes.gapXL),

            // 본문 입력
            const MingrrSectionLabel(FormStrings.labelContent, isRequired: true),
            MingrrTextField(
              controller: _contentController,
              maxLines: 6,
              hintText: FormStrings.hintContent,
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
              labelText: '${FormStrings.labelTag} (${FormStrings.optional})',
            ),
            const SizedBox(height: AppSizes.gapXL),

            // 익명 설정
            MingrrSwitchCard(
              accentColor: _accentColor,
              items: [
                MingrrSwitchItem(
                  title: SwitchStrings.anonymous,
                  subtitle: SwitchStrings.anonymousDesc,
                  value: _isAnonymous,
                  onChanged: (value) => setState(() => _isAnonymous = value),
                ),
              ],
            ),
            
            const SizedBox(height: AppSizes.gapXXL),
          ],
        ),
      ),
      bottomNavigationBar: MingrrSubmitButtonBar(
        label: _isEditMode ? FormStrings.edit : FormStrings.submit,
        onPressed: _onSubmit,
        isLoading: _isLoading,
        backgroundColor: _accentColor,
      ),
    );
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final remaining = ImageLimits.maxImageCount - (_existingImageUrls.length + _selectedImages.length);
    
    if (remaining <= 0) {
      MingrrSnackBar.warning(context, '이미지는 최대 ${ImageLimits.maxImageCount}장까지 업로드 가능합니다');
      return;
    }
    
    final images = await picker.pickMultiImage(
      maxWidth: ImageLimits.maxResolution.toDouble(),
      maxHeight: ImageLimits.maxResolution.toDouble(),
      imageQuality: ImageLimits.imageQuality,
    );
    
    if (images.isNotEmpty) {
      // 각 이미지 파일 크기 검사
      final validImages = <XFile>[];
      for (final image in images.take(remaining)) {
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
          continue;
        }
        validImages.add(image);
      }
      
      if (validImages.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(validImages);
        });
      }
    }
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final video = await picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: Duration(seconds: VideoLimits.maxDurationSeconds),
    );
    
    if (video != null) {
      // 동영상 유효성 검사
      final validation = await VideoUtils.validateVideo(video.path);
      if (!validation.isValid) {
        if (mounted) {
          MingrrSnackBar.warning(context, validation.errorMessage ?? '동영상을 업로드할 수 없습니다');
        }
        return;
      }
      setState(() => _selectedVideo = video);
    }
  }

  Future<void> _onSubmit() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      MingrrSnackBar.warning(context, FormStrings.errorContentRequired);
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

      // 동영상 업로드 및 썸네일 자동 생성
      String? videoUrl = _existingVideoUrl;
      String? videoThumbnailUrl = _existingVideoThumbnailUrl;
      if (_selectedVideo != null) {
        final videoId = const Uuid().v4();
        
        // 썸네일 생성
        final thumbnailFile = await VideoUtils.generateThumbnail(_selectedVideo!.path);
        
        // 비디오와 썸네일 업로드
        final result = await firebase.uploadVideoWithThumbnail(
          File(_selectedVideo!.path),
          'feeds/videos/$videoId',
          thumbnailFile: thumbnailFile,
          thumbnailPath: thumbnailFile != null ? 'feeds/thumbnails/$videoId.jpg' : null,
        );
        
        videoUrl = result['videoUrl'];
        videoThumbnailUrl = result['thumbnailUrl'];
        
        // 임시 썸네일 파일 삭제
        if (thumbnailFile != null && await thumbnailFile.exists()) {
          await thumbnailFile.delete();
        }
      }

      final notifier = ref.read(communityNotifierProvider.notifier);
      
      if (_isEditMode) {
        await notifier.updatePost(
          postId: widget.post!.id,
          content: content,
          imageUrls: uploadedUrls,
          videoUrl: videoUrl,
          videoThumbnailUrl: videoThumbnailUrl,
          tags: _tags,
        );
        if (mounted) {
          Navigator.pop(context, true);
          MingrrSnackBar.success(context, FormStrings.successUpdated);
        }
      } else {
        final postId = await notifier.createPost(
          category: _selectedCategory,
          content: content,
          imageUrls: uploadedUrls,
          videoUrl: videoUrl,
          videoThumbnailUrl: videoThumbnailUrl,
          tags: _tags,
          isAnonymous: _isAnonymous,
        );
        
        if (mounted && postId != null) {
          Navigator.pop(context, true);
          MingrrSnackBar.success(context, FormStrings.successCreated);
        }
      }
    } catch (e) {
      if (mounted) {
        MingrrSnackBar.error(context, '${FormStrings.errorGeneral}: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
