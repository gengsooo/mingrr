import 'package:flutter/material.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../constants/app_sizes.dart';

/// ============================================================
/// 공통 태그 입력 컴포넌트
/// 
/// 사용처: 커뮤니티 글작성, 소모임 만들기 등
/// 
/// 특징:
/// - 태그 입력 필드 + 태그 목록 표시
/// - 엔터키로 태그 추가
/// - 태그 클릭으로 삭제
/// - 최대 개수 제한
/// - 중복 태그 방지
/// ============================================================

class MingrrTagInput extends StatefulWidget {
  /// 현재 태그 목록
  final List<String> tags;
  
  /// 태그 변경 콜백
  final ValueChanged<List<String>> onTagsChanged;
  
  /// 강조 색상
  final Color accentColor;
  
  /// 최대 태그 개수 (기본값: 10)
  final int maxTags;
  
  /// 힌트 텍스트
  final String? hintText;
  
  /// 라벨 텍스트
  final String? labelText;

  const MingrrTagInput({
    super.key,
    required this.tags,
    required this.onTagsChanged,
    required this.accentColor,
    this.maxTags = 10,
    this.hintText,
    this.labelText,
  });

  @override
  State<MingrrTagInput> createState() => _MingrrTagInputState();
}

class _MingrrTagInputState extends State<MingrrTagInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _addTag(String value) {
    final tag = value.trim().replaceAll('#', '').replaceAll(' ', '');
    if (tag.isEmpty) return;
    if (widget.tags.contains(tag)) {
      _controller.clear();
      return;
    }
    if (widget.tags.length >= widget.maxTags) {
      _controller.clear();
      return;
    }
    
    final newTags = [...widget.tags, tag];
    widget.onTagsChanged(newTags);
    _controller.clear();
  }

  void _removeTag(String tag) {
    final newTags = widget.tags.where((t) => t != tag).toList();
    widget.onTagsChanged(newTags);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final canAddMore = widget.tags.length < widget.maxTags;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 라벨
        if (widget.labelText != null) ...[
          Text(
            widget.labelText!,
            style: AppTextStyles.labelLarge(context).copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSizes.gapS),
        ],
        
        // 태그 입력 필드
        Container(
          decoration: BoxDecoration(
            color: context.inputBackground,
            borderRadius: BorderRadius.circular(AppSizes.radiusS),
            border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            enabled: canAddMore,
            decoration: InputDecoration(
              hintText: canAddMore 
                  ? (widget.hintText ?? '태그 입력 후 엔터 (${widget.tags.length}/${widget.maxTags})')
                  : '최대 ${widget.maxTags}개까지 추가 가능',
              hintStyle: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL, vertical: AppSizes.paddingM),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 16, right: AppSizes.paddingXS),
                child: Text(
                  '#',
                  style: TextStyle(
                    color: widget.accentColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            ),
            style: AppTextStyles.bodyMedium(context),
            textInputAction: TextInputAction.done,
            onSubmitted: _addTag,
          ),
        ),
        
        // 태그 목록
        if (widget.tags.isNotEmpty) ...[
          const SizedBox(height: AppSizes.gapM),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.tags.map((tag) => _TagChip(
              tag: tag,
              accentColor: widget.accentColor,
              onRemove: () => _removeTag(tag),
            )).toList(),
          ),
        ],
      ],
    );
  }
}

/// 태그 칩 위젯
class _TagChip extends StatelessWidget {
  final String tag;
  final Color accentColor;
  final VoidCallback onRemove;

  const _TagChip({
    required this.tag,
    required this.accentColor,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 10, top: 6, bottom: 6, right: AppSizes.paddingXS),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '#$tag',
            style: TextStyle(
              fontSize: 13,
              color: accentColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          GestureDetector(
            onTap: onRemove,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingS, vertical: AppSizes.paddingXS),
              child: Icon(
                Icons.close,
                size: 14,
                color: accentColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
