import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../data/models/book_model.dart';
import '../../domain/book_notifier.dart';
import '../widgets/star_rating.dart';

class ReadingEditorScreen extends StatefulWidget {
  final Book? existingBook;
  final BookNotifier notifier;

  const ReadingEditorScreen({
    super.key,
    this.existingBook,
    required this.notifier,
  });

  @override
  State<ReadingEditorScreen> createState() => _ReadingEditorScreenState();
}

class _ReadingEditorScreenState extends State<ReadingEditorScreen> {
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _totalPagesController = TextEditingController();
  final _currentPageController = TextEditingController();
  final _notesController = TextEditingController();
  ReadStatus _status = ReadStatus.toRead;
  int _rating = 0;
  Set<String> _selectedTags = {};
  bool _isSubmitting = false;

  bool get _isEditing => widget.existingBook != null;

  static const _tagOptions = [
    'Fiction',
    'Non-Fiction',
    'Sci-Fi',
    'Self-Help',
    'Finance',
    'Psychology',
    'Philosophy',
    'History',
  ];

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final b = widget.existingBook!;
      _titleController.text = b.title;
      _authorController.text = b.author ?? '';
      _totalPagesController.text =
          b.totalPages > 0 ? b.totalPages.toString() : '';
      _currentPageController.text =
          b.currentPage > 0 ? b.currentPage.toString() : '';
      _notesController.text = b.notes;
      _status = b.status;
      _rating = b.rating;
      _selectedTags = b.tags.toSet();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _totalPagesController.dispose();
    _currentPageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isFormValid = _titleController.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Book' : 'Add Book'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton(
              onPressed: isFormValid && !_isSubmitting ? _save : null,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save'),
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
              autofocus: !_isEditing,
              style: theme.textTheme.titleLarge,
              decoration: InputDecoration(
                labelText: 'Title',
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _authorController,
              decoration: InputDecoration(
                labelText: 'Author',
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _totalPagesController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'Total pages',
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _currentPageController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'Current page',
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Status', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<ReadStatus>(
              segments: const [
                ButtonSegment(value: ReadStatus.toRead, label: Text('To Read')),
                ButtonSegment(
                    value: ReadStatus.reading, label: Text('Reading')),
                ButtonSegment(value: ReadStatus.completed, label: Text('Done')),
                ButtonSegment(value: ReadStatus.dnf, label: Text('DNF')),
              ],
              selected: {_status},
              onSelectionChanged: (v) => setState(() => _status = v.first),
            ),
            if (_status == ReadStatus.completed) ...[
              const SizedBox(height: 16),
              Text('Rating', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              StarRating(
                  rating: _rating,
                  size: 32,
                  onTap: (r) => setState(() => _rating = r)),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Notes',
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),
            Text('Tags', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tagOptions.map((tag) {
                final isSelected = _selectedTags.contains(tag);
                return FilterChip(
                  label: Text(tag),
                  selected: isSelected,
                  selectedColor: colorScheme.primary.withAlpha(40),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  onSelected: (s) => setState(() {
                    if (s) {
                      _selectedTags.add(tag);
                    } else {
                      _selectedTags.remove(tag);
                    }
                  }),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _isSubmitting = true);
    try {
      final uid = context.read<AuthProvider>().user!.uid;
      final totalPages = int.tryParse(_totalPagesController.text) ?? 0;
      final currentPage = int.tryParse(_currentPageController.text) ?? 0;

      if (_isEditing) {
        await widget.notifier.updateBook(
          widget.existingBook!.id,
          title: _titleController.text.trim(),
          author: _authorController.text.trim(),
          totalPages: totalPages,
          currentPage: currentPage,
          status: _status,
          notes: _notesController.text.trim(),
          tags: _selectedTags.toList(),
        );
        if (_rating > 0) {
          await widget.notifier.updateRating(widget.existingBook!.id, _rating);
        }
      } else {
        await widget.notifier.addBook(
          userId: uid,
          title: _titleController.text.trim(),
          author: _authorController.text.trim(),
          totalPages: totalPages,
          notes: _notesController.text.trim(),
          tags: _selectedTags.toList(),
        );
      }
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
