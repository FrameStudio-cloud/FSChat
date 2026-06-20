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
        title: Text(_isEditing ? 'Edit Post' : 'Create Post',
            style: theme.textTheme.titleMedium),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton(
              onPressed: isFormValid && !_isSubmitting ? _submitPost : null,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(_isEditing ? 'Save' : 'Publish'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                hintText: 'Post title...',
                hintStyle: theme.textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withAlpha(100),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: InputDecoration(
                labelText: 'Type',
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              items: Post.postTypes.map((type) {
                final icons = {
                  'article': '\u{1F4DD}',
                  'diary': '\u{1F4D6}',
                  'letter': '\u{1F48C}',
                  'poem': '\u{1F3AD}',
                  'journal': '\u{1F4D4}',
                };
                return DropdownMenuItem(
                  value: type,
                  child: Text(
                      '${icons[type] ?? ''}  ${type[0].toUpperCase()}${type.substring(1)}'),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedType = val);
              },
            ),
            const SizedBox(height: 16),
            Text('Tags', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: Post.defaultTags.map((tag) {
                final isSelected = _selectedTags.contains(tag);
                return FilterChip(
                  label: Text(tag),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedTags.add(tag);
                      } else {
                        _selectedTags.remove(tag);
                      }
                    });
                  },
                  selectedColor: colorScheme.primary.withAlpha(40),
                  checkmarkColor: colorScheme.primary,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child:
                        Text('Cover Image', style: theme.textTheme.labelLarge),
                  ),
                  TextButton.icon(
                    onPressed: _pickCoverImage,
                    icon: const Icon(Icons.image_outlined, size: 18),
                    label: Text(
                      _coverImagePath != null ? 'Change' : 'Add image',
                    ),
                  ),
                ],
              ),
            ),
            if (_coverImagePath != null && _coverImagePath!.startsWith('http'))
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    Image.network(
                      _coverImagePath!,
                      height: 160,
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
                          onPressed: () =>
                              setState(() => _coverImagePath = null),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (_coverImagePath != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    Image.file(
                      File(_coverImagePath!),
                      height: 160,
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
                          onPressed: () =>
                              setState(() => _coverImagePath = null),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (_coverImagePath != null) const SizedBox(height: 16),
            Row(
              children: [
                Text('Content', style: theme.textTheme.labelLarge),
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
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_isPreview)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.outlineVariant),
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
              TextField(
                controller: _contentController,
                maxLines: null,
                minLines: 10,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
                decoration: InputDecoration(
                  hintText:
                      'Write your post in markdown...\n\n## Heading\n**bold** *italic*\n- list\n> quote',
                  hintStyle: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant.withAlpha(80),
                    height: 1.6,
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
                onChanged: (_) => setState(() {}),
              ),
            const SizedBox(height: 32),
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
