import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/services/database_service.dart';
import '../models/post_model.dart';
import '../providers/blog_provider.dart';

class BlogEditorScreen extends StatefulWidget {
  final Post? post;

  const BlogEditorScreen({super.key, this.post});

  @override
  State<BlogEditorScreen> createState() => _BlogEditorScreenState();
}

class _BlogEditorScreenState extends State<BlogEditorScreen> {
  final _db = DatabaseService();
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  final _picker = ImagePicker();
  late String _selectedType;
  late Set<String> _selectedTags;
  bool _showAllTags = false;
  String? _coverImagePath;
  bool _isPreview = false;
  bool _isSubmitting = false;
  bool get _isEditing => widget.post != null;

  @override
  void initState() {
    super.initState();
    final post = widget.post;
    _titleController = TextEditingController(text: post?.title ?? '');
    _contentController = TextEditingController(text: post?.content ?? '');
    _selectedType = post?.type ?? 'article';
    _selectedTags = post?.tags.toSet() ?? {};
    _coverImagePath = post?.coverImage;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  int get _wordCount {
    final text = _contentController.text.trim();
    if (text.isEmpty) return 0;
    return text.split(RegExp(r'\s+')).length;
  }

  int get _charCount => _contentController.text.length;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isFormValid = _titleController.text.trim().isNotEmpty &&
        _contentController.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            if (_titleController.text.isNotEmpty ||
                _contentController.text.isNotEmpty) {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Discard post?'),
                  content:
                      const Text('Your content will be lost if you go back.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Keep editing'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pop(context);
                      },
                      child: const Text('Discard'),
                    ),
                  ],
                ),
              );
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(_isEditing ? 'Edit Entry' : 'New Entry',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            )),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton(
              onPressed: isFormValid && !_isSubmitting ? _submitPost : null,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                elevation: 2,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(_isEditing ? 'Save' : 'Publish',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TypeTileSelector(
              selectedType: _selectedType,
              onChanged: (type) => setState(() => _selectedType = type),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _titleController,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                hintText: 'Post title...',
                hintStyle: theme.textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 4),
            _CompactTagSelector(
              selectedTags: _selectedTags,
              allTags: Post.defaultTags,
              showAll: _showAllTags,
              onToggle: (tag) {
                setState(() {
                  if (_selectedTags.contains(tag)) {
                    _selectedTags.remove(tag);
                  } else {
                    _selectedTags.add(tag);
                  }
                });
              },
              onToggleShowAll: () =>
                  setState(() => _showAllTags = !_showAllTags),
            ),
            const SizedBox(height: 16),
            _CoverImagePicker(
              coverImagePath: _coverImagePath,
              onPick: _pickCoverImage,
              onClear: () => setState(() => _coverImagePath = null),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('Content',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    )),
                const Spacer(),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('Edit')),
                    ButtonSegment(value: true, label: Text('Preview')),
                  ],
                  selected: {_isPreview},
                  onSelectionChanged: (val) {
                    setState(() => _isPreview = val.first);
                  },
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: WidgetStatePropertyAll(
                      TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_isPreview)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: _contentController.text.trim().isEmpty
                    ? Text(
                        'Nothing to preview',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      )
                    : MarkdownBody(
                        data: _contentController.text,
                        styleSheet: MarkdownStyleSheet(
                          p: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
                        ),
                      ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TextField(
                  controller: _contentController,
                  maxLines: null,
                  minLines: 10,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                  decoration: InputDecoration(
                    hintText: 'Write your post in markdown...',
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      color:
                          colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      height: 1.6,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            if (!_isPreview) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  _MarkdownHint(text: '**bold**'),
                  const SizedBox(width: 4),
                  _MarkdownHint(text: '*italic*'),
                  const SizedBox(width: 4),
                  _MarkdownHint(text: '# heading'),
                  const SizedBox(width: 4),
                  _MarkdownHint(text: '- list'),
                  const SizedBox(width: 4),
                  _MarkdownHint(text: '> quote'),
                ],
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '$_wordCount words · $_charCount chars',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.outline,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _pickCoverImage() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() => _coverImagePath = file.path);
    }
  }

  Future<void> _submitPost() async {
    if (_titleController.text.trim().isEmpty ||
        _contentController.text.trim().isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      final provider = context.read<BlogProvider>();
      if (_isEditing) {
        final updates = <String, dynamic>{
          'title': _titleController.text.trim(),
          'content': _contentController.text.trim(),
          'excerpt': _contentController.text.trim().length > 150
              ? '${_contentController.text.trim().substring(0, 150)}...'
              : _contentController.text.trim(),
          'type': _selectedType,
          'tags': _selectedTags.toList(),
        };
        if (_coverImagePath != null && !_coverImagePath!.startsWith('http')) {
          final url =
              await _db.uploadPostCover(widget.post!.id, _coverImagePath!);
          updates['coverImage'] = url;
        } else if (_coverImagePath == null) {
          updates['coverImage'] = null;
        }
        await provider.updatePost(widget.post!.id, updates);
      } else {
        await provider.createPost(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          type: _selectedType,
          tags: _selectedTags.toList(),
          coverImagePath: _coverImagePath,
        );
      }
      if (context.mounted) Navigator.pop(context, true);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

class _TypeTileSelector extends StatelessWidget {
  final String selectedType;
  final ValueChanged<String> onChanged;

  const _TypeTileSelector({
    required this.selectedType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 62,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: Post.postTypes.map((type) {
          final isSelected = selectedType == type;
          final icons = {
            'article': '📝',
            'diary': '📖',
            'letter': '💌',
            'poem': '🎭',
            'journal': '📓',
          };
          final bgColor = isSelected
              ? (isDark
                  ? colorScheme.primary.withValues(alpha: 0.15)
                  : colorScheme.primary.withValues(alpha: 0.08))
              : colorScheme.surfaceContainerLow;
          final iconBg = isSelected
              ? colorScheme.primary
              : (isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.04));

          return GestureDetector(
            onTap: () => onChanged(type),
            child: Container(
              width: 58,
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        icons[type] ?? '📝',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    type[0].toUpperCase() + type.substring(1),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CompactTagSelector extends StatelessWidget {
  final Set<String> selectedTags;
  final List<String> allTags;
  final bool showAll;
  final ValueChanged<String> onToggle;
  final VoidCallback onToggleShowAll;

  const _CompactTagSelector({
    required this.selectedTags,
    required this.allTags,
    required this.showAll,
    required this.onToggle,
    required this.onToggleShowAll,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final visibleTags = showAll ? allTags : selectedTags.toList();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        ...visibleTags.map((tag) {
          final isSelected = selectedTags.contains(tag);
          return GestureDetector(
            onTap: () => onToggle(tag),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primary.withValues(alpha: 0.08)
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                isSelected || showAll ? '# $tag' : '# $tag',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          );
        }),
        if (!showAll && selectedTags.length < allTags.length)
          GestureDetector(
            onTap: onToggleShowAll,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(
                  color: colorScheme.outlineVariant,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '+ Add tag',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.outline,
                ),
              ),
            ),
          ),
        if (showAll)
          GestureDetector(
            onTap: onToggleShowAll,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Show less',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CoverImagePicker extends StatelessWidget {
  final String? coverImagePath;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const _CoverImagePicker({
    this.coverImagePath,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Cover image',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            if (coverImagePath != null)
              GestureDetector(
                onTap: onPick,
                child: Text(
                  'Change',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.primary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        if (coverImagePath != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              children: [
                coverImagePath!.startsWith('http')
                    ? Image.network(
                        coverImagePath!,
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      )
                    : Image.file(
                        File(coverImagePath!),
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      icon: const Icon(Icons.close,
                          size: 16, color: Colors.white),
                      onPressed: onClear,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          GestureDetector(
            onTap: onPick,
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color:
                    colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: colorScheme.outlineVariant,
                  width: 1.5,
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.image_outlined,
                    size: 24,
                    color: colorScheme.outline,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to add a cover image',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _MarkdownHint extends StatelessWidget {
  final String text;

  const _MarkdownHint({required this.text});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontFamily: 'monospace',
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}
