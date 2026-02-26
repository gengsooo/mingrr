import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/app_icons.dart';
import '../../constants/app_sizes.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../dividers/app_dividers.dart';
import '../mingrr_image.dart';
import '../mingrr_app_bar.dart';

/// ============================================================
/// MINGRR 폼 공통 컴포넌트 모음
/// 
/// 등록/수정 화면에서 사용되는 재사용 가능한 UI 컴포넌트
/// 
/// 포함 컴포넌트:
/// - MingrrSectionLabel: 섹션 라벨
/// - MingrrSwitchRow: 토글 스위치 행
/// - MingrrSwitchCard: 토글 스위치 카드 (여러 개 묶음)
/// - MingrrChipSelector: 칩 선택기 (단일/다중)
/// - MingrrImagePicker: 이미지 피커 (단일/다중)
/// - MingrrFormAppBar: 폼 화면용 앱바
/// ============================================================

// ===== 섹션 라벨 =====
/// 폼 섹션의 제목 라벨
/// 
/// 사용 예시:
/// ```dart
/// MingrrSectionLabel('카테고리')
/// MingrrSectionLabel('사진', isRequired: true)
/// MingrrSectionLabel('태그', suffix: '(선택)')
/// ```
class MingrrSectionLabel extends StatelessWidget {
  final String text;
  final bool isRequired;
  final String? suffix;

  const MingrrSectionLabel(
    this.text, {
    super.key,
    this.isRequired = false,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.gapS),
      child: Row(
        children: [
          Text(
            text,
            style: AppTextStyles.titleMedium(context).withWeight(FontWeight.w600),
          ),
          if (isRequired)
            Text(
              ' *',
              style: AppTextStyles.titleMedium(context).withWeight(FontWeight.w600).withColor(Theme.of(context).colorScheme.error),
            ),
          if (suffix != null)
            Text(
              ' $suffix',
              style: AppTextStyles.bodyLarge(context).withColor(Theme.of(context).colorScheme.onSurfaceVariant),
            ),
        ],
      ),
    );
  }
}

// ===== 토글 스위치 행 =====
/// 단일 토글 스위치 행
/// 
/// 사용 예시:
/// ```dart
/// MingrrSwitchRow(
///   title: '공개 모임',
///   subtitle: '누구나 모임을 볼 수 있습니다',
///   value: _isPublic,
///   onChanged: (value) => setState(() => _isPublic = value),
///   accentColor: accentColor,
/// )
/// ```
class MingrrSwitchRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color accentColor;
  final IconData? icon;

  const MingrrSwitchRow({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    required this.accentColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSizes.gapM),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.titleLarge(context).withWeight(FontWeight.w500),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: AppTextStyles.bodySmall(context).withColor(colorScheme.onSurfaceVariant),
                ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: Colors.white,
          activeTrackColor: accentColor,
          // 다크모드에서 OFF 상태 thumb이 track과 구분되도록 설정
          inactiveThumbColor: colorScheme.outline,
          inactiveTrackColor: colorScheme.surfaceContainerHighest,
          trackOutlineColor: WidgetStateProperty.all(colorScheme.outline),
        ),
      ],
    );
  }
}

// ===== 토글 스위치 카드 =====
/// 여러 토글 스위치를 카드로 묶어서 표시
/// 
/// 사용 예시:
/// ```dart
/// MingrrSwitchCard(
///   title: '설정',
///   accentColor: accentColor,
///   items: [
///     MingrrSwitchItem(title: '공개', subtitle: '설명', value: v1, onChanged: ...),
///     MingrrSwitchItem(title: '승인', subtitle: '설명', value: v2, onChanged: ...),
///   ],
/// )
/// ```
class MingrrSwitchItem {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData? icon;

  const MingrrSwitchItem({
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.icon,
  });
}

class MingrrSwitchCard extends StatelessWidget {
  final String? title;
  final List<MingrrSwitchItem> items;
  final Color accentColor;

  const MingrrSwitchCard({
    super.key,
    this.title,
    required this.items,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) MingrrSectionLabel(title!),
        Container(
          padding: const EdgeInsets.all(AppSizes.paddingL),
          decoration: BoxDecoration(
            color: context.inputBackground,
            borderRadius: BorderRadius.circular(AppSizes.radiusS),
          ),
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                MingrrSwitchRow(
                  title: items[i].title,
                  subtitle: items[i].subtitle,
                  value: items[i].value,
                  onChanged: items[i].onChanged,
                  accentColor: accentColor,
                  icon: items[i].icon,
                ),
                if (i < items.length - 1) const MingrrDivider.section(),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ===== 칩 선택기 =====
/// 칩 형태의 선택기 (카테고리, 타입 등)
/// 
/// 사용 예시:
/// ```dart
/// MingrrChipSelector<CategoryType>(
///   items: CategoryType.values,
///   selectedItem: _selectedCategory,
///   onSelected: (item) => setState(() => _selectedCategory = item),
///   labelBuilder: (item) => item.label,
///   accentColor: accentColor,
/// )
/// ```
class MingrrChipSelector<T> extends StatelessWidget {
  final List<T> items;
  final T? selectedItem;
  final Set<T>? selectedItems; // 다중 선택용
  final ValueChanged<T> onSelected;
  final String Function(T) labelBuilder;
  final String Function(T)? emojiBuilder;
  final IconData? Function(T)? iconBuilder;
  final Color accentColor;
  final bool multiSelect;

  const MingrrChipSelector({
    super.key,
    required this.items,
    this.selectedItem,
    this.selectedItems,
    required this.onSelected,
    required this.labelBuilder,
    this.emojiBuilder,
    this.iconBuilder,
    required this.accentColor,
    this.multiSelect = false,
  });

  bool _isSelected(T item) {
    if (multiSelect) {
      return selectedItems?.contains(item) ?? false;
    }
    return selectedItem == item;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final isSelected = _isSelected(item);
        final emoji = emojiBuilder?.call(item);
        final icon = iconBuilder?.call(item);
        final label = labelBuilder(item);
        
        return GestureDetector(
          onTap: () => onSelected(item),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppSizes.paddingS),
            decoration: BoxDecoration(
              color: isSelected ? accentColor : Colors.transparent,
              borderRadius: BorderRadius.circular(AppSizes.radiusL),
              border: Border.all(
                color: isSelected ? accentColor : colorScheme.outline,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 16,
                    color: isSelected ? Colors.white : colorScheme.onSurface,
                  ),
                  const SizedBox(width: AppSizes.gapSM),
                ],
                if (emoji != null)
                  Text(
                    '$emoji ',
                    style: AppTextStyles.bodySmall(context),
                  ),
                Text(
                  label,
                  style: AppTextStyles.bodySmall(context).copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? Colors.white : colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ===== 이미지 피커 =====
/// 이미지 선택 컴포넌트 (단일/다중)
/// 
/// 사용 예시 (다중):
/// ```dart
/// MingrrImagePicker(
///   existingUrls: _existingImageUrls,
///   selectedFiles: _selectedImages,
///   onPickImages: _pickImages,
///   onRemoveExisting: (index) => setState(() => _existingImageUrls.removeAt(index)),
///   onRemoveSelected: (index) => setState(() => _selectedImages.removeAt(index)),
///   maxImages: 5,
/// )
/// ```
/// 
/// 사용 예시 (단일):
/// ```dart
/// MingrrImagePicker.single(
///   existingUrl: _existingImageUrl,
///   selectedFile: _selectedImage,
///   onPickImage: _pickImage,
///   onRemove: () => setState(() { _existingImageUrl = null; _selectedImage = null; }),
///   height: 180,
/// )
/// ```
class MingrrImagePicker extends StatelessWidget {
  // 다중 이미지용
  final List<String>? existingUrls;
  final List<XFile>? selectedFiles;
  final VoidCallback? onPickImages;
  final void Function(int)? onRemoveExisting;
  final void Function(int)? onRemoveSelected;
  final int maxImages;
  
  // 단일 이미지용
  final String? existingUrl;
  final XFile? selectedFile;
  final VoidCallback? onPickImage;
  final VoidCallback? onRemove;
  final double? height;
  
  final bool isSingle;

  const MingrrImagePicker({
    super.key,
    required this.existingUrls,
    required this.selectedFiles,
    required this.onPickImages,
    required this.onRemoveExisting,
    required this.onRemoveSelected,
    this.maxImages = 10,
  })  : isSingle = false,
        existingUrl = null,
        selectedFile = null,
        onPickImage = null,
        onRemove = null,
        height = null;

  const MingrrImagePicker.single({
    super.key,
    this.existingUrl,
    this.selectedFile,
    required this.onPickImage,
    required this.onRemove,
    this.height = 180,
  })  : isSingle = true,
        existingUrls = null,
        selectedFiles = null,
        onPickImages = null,
        onRemoveExisting = null,
        onRemoveSelected = null,
        maxImages = 1;

  @override
  Widget build(BuildContext context) {
    if (isSingle) {
      return _buildSinglePicker(context);
    }
    return _buildMultiPicker(context);
  }

  Widget _buildSinglePicker(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasImage = existingUrl != null || selectedFile != null;
    
    return GestureDetector(
      onTap: onPickImage,
      child: Container(
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusS),
          border: Border.all(color: colorScheme.outline),
          image: selectedFile != null
              ? DecorationImage(
                  image: FileImage(File(selectedFile!.path)),
                  fit: BoxFit.cover,
                )
              : existingUrl != null
                  ? DecorationImage(
                      image: NetworkImage(existingUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
        ),
        child: hasImage
            ? Stack(
                children: [
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _RemoveButton(onTap: onRemove!),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(AppIcons.addPhoto, size: 48, color: colorScheme.outlineVariant),
                  const SizedBox(height: AppSizes.gapS),
                  Text('이미지 추가', style: TextStyle(color: colorScheme.outlineVariant)),
                ],
              ),
      ),
    );
  }

  Widget _buildMultiPicker(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final totalImages = (existingUrls?.length ?? 0) + (selectedFiles?.length ?? 0);
    
    return SizedBox(
      height: 80,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // 추가 버튼
          GestureDetector(
            onTap: totalImages < maxImages ? onPickImages : null,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.outline),
                borderRadius: BorderRadius.circular(AppSizes.radiusM),
                color: totalImages >= maxImages 
                    ? colorScheme.surfaceContainerHighest 
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    AppIcons.camera,
                    color: totalImages >= maxImages 
                        ? colorScheme.outline 
                        : colorScheme.outlineVariant,
                  ),
                  const SizedBox(height: AppSizes.gapXS),
                  Text(
                    '$totalImages/$maxImages',
                    style: AppTextStyles.caption(context).withColor(
                      totalImages >= maxImages 
                          ? colorScheme.outline 
                          : colorScheme.outlineVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSizes.gapS),
          // 기존 이미지
          if (existingUrls != null)
            ...existingUrls!.asMap().entries.map((entry) {
              return _ImageTile(
                imageUrl: entry.value,
                onRemove: () => onRemoveExisting?.call(entry.key),
              );
            }),
          // 새로 선택한 이미지
          if (selectedFiles != null)
            ...selectedFiles!.asMap().entries.map((entry) {
              return _ImageTile(
                file: File(entry.value.path),
                onRemove: () => onRemoveSelected?.call(entry.key),
              );
            }),
        ],
      ),
    );
  }
}

/// 이미지 타일 (내부용)
class _ImageTile extends StatelessWidget {
  final String? imageUrl;
  final File? file;
  final VoidCallback onRemove;

  const _ImageTile({
    this.imageUrl,
    this.file,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      margin: const EdgeInsets.only(right: AppSizes.paddingS),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusM),
            child: imageUrl != null
                ? MingrrImage.thumbnail(imageUrl: imageUrl, width: 80, height: 80)
                : Image.file(file!, width: 80, height: 80, fit: BoxFit.cover),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: _RemoveButton(onTap: onRemove),
          ),
        ],
      ),
    );
  }
}

/// 삭제 버튼 (내부용)
class _RemoveButton extends StatelessWidget {
  final VoidCallback onTap;

  const _RemoveButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.paddingXS),
        decoration: const BoxDecoration(
          color: Colors.black54,
          shape: BoxShape.circle,
        ),
        child: const Icon(AppIcons.close, size: 14, color: Colors.white),
      ),
    );
  }
}

// ===== 폼 앱바 =====
/// 등록/수정 화면용 앱바
/// 
/// @deprecated [MingrrAppBar.form]을 대신 사용하세요.
/// 
/// 사용 예시:
/// ```dart
/// // 기존 (deprecated)
/// appBar: MingrrFormAppBar(
///   title: '글 작성',
///   onClose: () => Navigator.pop(context),
/// )
/// 
/// // 권장
/// appBar: MingrrAppBar.form(
///   title: '글 작성',
///   onClose: () => Navigator.pop(context),
/// )
/// ```
@Deprecated('MingrrAppBar.form()을 대신 사용하세요')
class MingrrFormAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onClose;
  final List<Widget>? actions;

  const MingrrFormAppBar({
    super.key,
    required this.title,
    required this.onClose,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    // MingrrAppBar.form()으로 위임
    return MingrrAppBar.form(
      title: title,
      onClose: onClose,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// ===== 선택 버튼 (지역, 날짜 등) =====
/// 선택 버튼 (탭하면 바텀시트나 다이얼로그 표시)
/// 
/// 사용 예시:
/// ```dart
/// MingrrSelectButton(
///   label: '지역',
///   value: _selectedLocation,
///   placeholder: '지역을 선택해주세요',
///   onTap: _showLocationSelector,
///   icon: Icons.location_on_outlined,
/// )
/// ```
class MingrrSelectButton extends StatelessWidget {
  final String label;
  final String? value;
  final String placeholder;
  final VoidCallback onTap;
  final IconData? icon;
  final bool isRequired;

  const MingrrSelectButton({
    super.key,
    required this.label,
    this.value,
    required this.placeholder,
    required this.onTap,
    this.icon,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasValue = value != null && value!.isNotEmpty;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MingrrSectionLabel(label, isRequired: isRequired),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL, vertical: AppSizes.paddingM),
            decoration: BoxDecoration(
              color: context.inputBackground,
              borderRadius: BorderRadius.circular(AppSizes.radiusS),
              border: Border.all(color: colorScheme.outline.withValues(alpha: AppOpacity.o30)),
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 20,
                    color: hasValue ? colorScheme.onSurface : colorScheme.outlineVariant,
                  ),
                  const SizedBox(width: AppSizes.gapM),
                ],
                Expanded(
                  child: Text(
                    hasValue ? value! : placeholder,
                    style: AppTextStyles.titleLarge(context).withWeight(FontWeight.w400).withColor(
                      hasValue ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Icon(
                  AppIcons.chevronRight,
                  color: colorScheme.outlineVariant,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ===== 동영상 피커 =====
/// 동영상 선택 컴포넌트
/// 
/// 사용 예시:
/// ```dart
/// MingrrVideoPicker(
///   existingUrl: _existingVideoUrl,
///   existingThumbnailUrl: _existingThumbnailUrl,
///   selectedFile: _selectedVideo,
///   onPickVideo: _pickVideo,
///   onRemove: () => setState(() { _existingVideoUrl = null; _selectedVideo = null; }),
/// )
/// ```
class MingrrVideoPicker extends StatelessWidget {
  final String? existingUrl;
  final String? existingThumbnailUrl;
  final XFile? selectedFile;
  final VoidCallback onPickVideo;
  final VoidCallback onRemove;
  final double height;

  const MingrrVideoPicker({
    super.key,
    this.existingUrl,
    this.existingThumbnailUrl,
    this.selectedFile,
    required this.onPickVideo,
    required this.onRemove,
    this.height = 180,
  });

  bool get _hasVideo => existingUrl != null || selectedFile != null;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return GestureDetector(
      onTap: _hasVideo ? null : onPickVideo,
      child: Container(
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusS),
          border: Border.all(color: colorScheme.outline),
        ),
        child: _hasVideo
            ? _buildVideoPreview(context)
            : _buildEmptyState(context),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(AppIcons.video, size: 48, color: colorScheme.outlineVariant),
        const SizedBox(height: AppSizes.gapS),
        Text('동영상 추가', style: AppTextStyles.bodySmall(context).copyWith(color: colorScheme.outlineVariant)),
        const SizedBox(height: AppSizes.gapXS),
        Text(
          '최대 1분, 100MB',
          style: AppTextStyles.caption(context).copyWith(color: colorScheme.outlineVariant),
        ),
      ],
    );
  }

  Widget _buildVideoPreview(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Stack(
      fit: StackFit.expand,
      children: [
        // 썸네일 또는 플레이스홀더
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSizes.radiusS),
          child: existingThumbnailUrl != null
              ? MingrrImage(
                  imageUrl: existingThumbnailUrl,
                  fit: BoxFit.cover,
                  errorWidget: _buildVideoPlaceholder(colorScheme),
                )
              : _buildVideoPlaceholder(colorScheme),
        ),
        // 재생 아이콘 오버레이
        Center(
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: AppOpacity.o50),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              AppIcons.play,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
        // 동영상 표시
        Positioned(
          left: 8,
          bottom: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingS, vertical: AppSizes.paddingXS),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: AppOpacity.o70),
              borderRadius: BorderRadius.circular(AppSizes.radiusXXS),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(AppIcons.video, color: Colors.white, size: 14),
                const SizedBox(width: AppSizes.gapXS),
                Text(
                  selectedFile != null ? '새 동영상' : '동영상',
                  style: AppTextStyles.caption(context).copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
        // 삭제 버튼
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: onRemove,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.all(AppSizes.paddingXS),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(AppIcons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoPlaceholder(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          AppIcons.video,
          size: 48,
          color: colorScheme.outlineVariant,
        ),
      ),
    );
  }
}

// ===== 미디어 피커 (이미지 + 동영상 통합) =====
/// 이미지와 동영상을 함께 선택할 수 있는 통합 미디어 피커
/// 
/// 사용 예시:
/// ```dart
/// MingrrMediaPicker(
///   existingImageUrls: _existingImageUrls,
///   selectedImages: _selectedImages,
///   existingVideoUrl: _existingVideoUrl,
///   selectedVideo: _selectedVideo,
///   onPickImages: _pickImages,
///   onPickVideo: _pickVideo,
///   onRemoveExistingImage: (index) => setState(() => _existingImageUrls.removeAt(index)),
///   onRemoveSelectedImage: (index) => setState(() => _selectedImages.removeAt(index)),
///   onRemoveVideo: () => setState(() { _existingVideoUrl = null; _selectedVideo = null; }),
///   maxImages: 5,
/// )
/// ```
class MingrrMediaPicker extends StatelessWidget {
  // 이미지
  final List<String> existingImageUrls;
  final List<XFile> selectedImages;
  final VoidCallback onPickImages;
  final void Function(int) onRemoveExistingImage;
  final void Function(int) onRemoveSelectedImage;
  final int maxImages;
  
  // 동영상
  final String? existingVideoUrl;
  final String? existingVideoThumbnailUrl;
  final XFile? selectedVideo;
  final VoidCallback onPickVideo;
  final VoidCallback onRemoveVideo;

  const MingrrMediaPicker({
    super.key,
    required this.existingImageUrls,
    required this.selectedImages,
    required this.onPickImages,
    required this.onRemoveExistingImage,
    required this.onRemoveSelectedImage,
    this.maxImages = 5,
    this.existingVideoUrl,
    this.existingVideoThumbnailUrl,
    this.selectedVideo,
    required this.onPickVideo,
    required this.onRemoveVideo,
  });

  bool get _hasVideo => existingVideoUrl != null || selectedVideo != null;
  int get _totalImages => existingImageUrls.length + selectedImages.length;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 이미지 피커
        SizedBox(
          height: 80,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // 이미지 추가 버튼
              _buildAddButton(
                context: context,
                icon: AppIcons.camera,
                label: '$_totalImages/$maxImages',
                onTap: _totalImages < maxImages ? onPickImages : null,
                isDisabled: _totalImages >= maxImages,
              ),
              const SizedBox(width: AppSizes.gapS),
              // 동영상 추가 버튼
              if (!_hasVideo)
                _buildAddButton(
                  context: context,
                  icon: AppIcons.video,
                  label: '동영상',
                  onTap: onPickVideo,
                ),
              if (!_hasVideo) const SizedBox(width: AppSizes.gapS),
              // 동영상 썸네일
              if (_hasVideo)
                _buildVideoThumbnail(context),
              if (_hasVideo) const SizedBox(width: AppSizes.gapS),
              // 기존 이미지
              ...existingImageUrls.asMap().entries.map((entry) {
                return _MediaTile(
                  imageUrl: entry.value,
                  onRemove: () => onRemoveExistingImage(entry.key),
                );
              }),
              // 새로 선택한 이미지
              ...selectedImages.asMap().entries.map((entry) {
                return _MediaTile(
                  file: File(entry.value.path),
                  onRemove: () => onRemoveSelectedImage(entry.key),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    bool isDisabled = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outline),
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          color: isDisabled ? colorScheme.surfaceContainerHighest : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isDisabled ? colorScheme.outline : colorScheme.outlineVariant,
            ),
            const SizedBox(height: AppSizes.gapXS),
            Text(
              label,
              style: AppTextStyles.caption(context).withColor(
                isDisabled ? colorScheme.outline : colorScheme.outlineVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoThumbnail(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        color: colorScheme.surfaceContainerHighest,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 썸네일
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusM),
            child: existingVideoThumbnailUrl != null
                ? MingrrImage(
                    imageUrl: existingVideoThumbnailUrl,
                    fit: BoxFit.cover,
                    errorWidget: _buildVideoIcon(colorScheme),
                  )
                : _buildVideoIcon(colorScheme),
          ),
          // 재생 아이콘
          Center(
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: AppOpacity.o50),
                shape: BoxShape.circle,
              ),
              child: const Icon(AppIcons.play, color: Colors.white, size: 18),
            ),
          ),
          // 삭제 버튼
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemoveVideo,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.all(AppSizes.paddingXS),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(AppIcons.close, size: 12, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoIcon(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: Icon(AppIcons.video, color: colorScheme.outlineVariant),
    );
  }
}

/// 미디어 타일 (내부용)
class _MediaTile extends StatelessWidget {
  final String? imageUrl;
  final File? file;
  final VoidCallback onRemove;

  const _MediaTile({
    this.imageUrl,
    this.file,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      margin: const EdgeInsets.only(right: AppSizes.paddingS),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusM),
            child: imageUrl != null
                ? MingrrImage.thumbnail(imageUrl: imageUrl, width: 80, height: 80)
                : Image.file(file!, width: 80, height: 80, fit: BoxFit.cover),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.all(AppSizes.paddingXS),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(AppIcons.close, size: 12, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
