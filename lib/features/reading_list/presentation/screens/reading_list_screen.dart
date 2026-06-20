import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:isar/isar.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../data/datasources/book_local_source.dart';
import '../../data/models/book_model.dart';
import '../../domain/book_notifier.dart';
import '../widgets/star_rating.dart';
import 'reading_editor_screen.dart';

class ReadingListScreen extends StatefulWidget {
  const ReadingListScreen({super.key});

  @override
  State<ReadingListScreen> createState() => _ReadingListScreenState();
}

class _ReadingListScreenState extends State<ReadingListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  BookNotifier? _notifier;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final uid = context.read<AuthProvider>().user?.uid;
    if (uid != null && _notifier == null) {
      _notifier = BookNotifier(BookLocalSource());
      _notifier!.init(uid);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _notifier?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthProvider>().user?.uid;
    if (uid == null) return const SizedBox();

    final notifier = _notifier;
    if (notifier == null)
      return const Center(child: CircularProgressIndicator());

    return ListenableBuilder(
      listenable: notifier,
      builder: (context, _) {
        if (notifier.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Reading List'),
            centerTitle: false,
            bottom: TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: 'To Read (${notifier.toRead.length})'),
                Tab(text: 'Reading (${notifier.reading.length})'),
                Tab(text: 'Done (${notifier.completed.length})'),
                Tab(text: 'DNF (${notifier.dnf.length})'),
              ],
            ),
          ),
          body: notifier.books.isEmpty
              ? _buildEmptyState(context)
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildList(context, notifier.toRead, notifier),
                    _buildList(context, notifier.reading, notifier),
                    _buildList(context, notifier.completed, notifier),
                    _buildList(context, notifier.dnf, notifier),
                  ],
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _openEditor(context),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.menu_book_outlined,
              size: 64, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text('Your reading list is empty',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              )),
          const SizedBox(height: 8),
          Text('Add a book to start tracking',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              )),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _openEditor(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Book'),
          ),
        ],
      ),
    );
  }

  Widget _buildList(
      BuildContext context, List<Book> books, BookNotifier notifier) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (books.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined,
                size: 48, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text('Nothing here',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                )),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        final progress = book.progressPercent;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          elevation: 0,
          color: colorScheme.surfaceContainerLow,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: InkWell(
            onTap: () => _openEditor(context, book: book),
            onLongPress: () => _showOptions(context, book, notifier),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _statusColor(book.status, colorScheme)
                              .withAlpha(25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(_statusIcon(book.status),
                            color: _statusColor(book.status, colorScheme),
                            size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(book.title,
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                            if (book.author != null && book.author!.isNotEmpty)
                              Text(book.author!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant)),
                            if (book.status == ReadStatus.completed &&
                                book.rating > 0)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child:
                                    StarRating(rating: book.rating, size: 16),
                              ),
                          ],
                        ),
                      ),
                      if (book.status != ReadStatus.completed &&
                          book.status != ReadStatus.dnf)
                        GestureDetector(
                          onTap: () => notifier.advanceStatus(book.id),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: colorScheme.primary.withAlpha(25)),
                            child: Icon(
                              book.status == ReadStatus.toRead
                                  ? Icons.play_arrow_rounded
                                  : book.status == ReadStatus.reading
                                      ? Icons.check_rounded
                                      : Icons.radio_button_unchecked,
                              color: colorScheme.primary,
                              size: 20,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (book.totalPages > 0) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: colorScheme.onSurface.withAlpha(20),
                        valueColor: AlwaysStoppedAnimation(
                            _statusColor(book.status, colorScheme)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Page ${book.currentPage} / ${book.totalPages}',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                  if (book.tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: book.tags
                          .map((tag) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withAlpha(15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(tag,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                        color: colorScheme.primary,
                                        fontSize: 10)),
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _statusColor(ReadStatus status, ColorScheme cs) {
    switch (status) {
      case ReadStatus.toRead:
        return cs.primary;
      case ReadStatus.reading:
        return Colors.amber.shade700;
      case ReadStatus.completed:
        return Colors.green;
      case ReadStatus.dnf:
        return Colors.red.shade400;
    }
  }

  IconData _statusIcon(ReadStatus status) {
    switch (status) {
      case ReadStatus.toRead:
        return Icons.radio_button_unchecked;
      case ReadStatus.reading:
        return Icons.timelapse_rounded;
      case ReadStatus.completed:
        return Icons.check_circle_rounded;
      case ReadStatus.dnf:
        return Icons.cancel_outlined;
    }
  }

  void _showOptions(BuildContext context, Book book, BookNotifier notifier) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete'),
              onTap: () {
                Navigator.pop(ctx);
                notifier.deleteBook(book.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openEditor(BuildContext context, {Book? book}) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) =>
              ReadingEditorScreen(existingBook: book, notifier: _notifier!)),
    );
  }
}
