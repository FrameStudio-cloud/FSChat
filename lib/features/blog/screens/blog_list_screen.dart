import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/database_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/post_model.dart';
import '../providers/blog_provider.dart';
import '../widgets/post_card.dart';
import '../widgets/tag_chip_row.dart';
import 'blog_post_screen.dart';
import 'blog_editor_screen.dart';

class BlogListScreen extends StatefulWidget {
  const BlogListScreen({super.key});

  @override
  State<BlogListScreen> createState() => _BlogListScreenState();
}

class _BlogListScreenState extends State<BlogListScreen> {
  final _db = DatabaseService();
  String? _selectedTag;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final blogProvider = context.read<BlogProvider>();
    blogProvider.setAuthProvider(context.read<AuthProvider>());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal'),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search posts...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          TagChipRow(
            tags: Post.defaultTags,
            selectedTag: _selectedTag,
            onTagSelected: (tag) {
              setState(() {
                _selectedTag = _selectedTag == tag ? null : tag;
              });
            },
          ),
          Expanded(
            child: _selectedTag != null
                ? StreamBuilder<List<Post>>(
                    stream: _db.postsByTagStream(_selectedTag!),
                    builder: (context, snapshot) =>
                        _buildList(context, snapshot),
                  )
                : StreamBuilder<List<Post>>(
                    stream: _db.allPostsStream(),
                    builder: (context, snapshot) =>
                        _buildList(context, snapshot),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider.value(
              value: context.read<BlogProvider>(),
              child: const BlogEditorScreen(),
            ),
          ),
        ),
        child: const Icon(Icons.edit_rounded),
      ),
    );
  }

  Widget _buildList(BuildContext context, AsyncSnapshot<List<Post>> snapshot) {
    final theme = Theme.of(context);

    if (snapshot.hasError) {
      return Center(
        child: Text('Something went wrong', style: theme.textTheme.bodyMedium),
      );
    }

    if (!snapshot.hasData) {
      return const Center(child: CircularProgressIndicator());
    }

    var posts = snapshot.data!;
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      posts = posts
          .where((p) =>
              p.title.toLowerCase().contains(query) ||
              p.excerpt.toLowerCase().contains(query))
          .toList();
    }

    if (posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.article_outlined,
                size: 64, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              query.isNotEmpty ? 'No posts found' : 'No journal entries yet',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              query.isNotEmpty
                  ? 'Try a different search term'
                  : 'Tap + to write your first post',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 4, bottom: 88),
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
          return PostCard(
            post: post,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChangeNotifierProvider.value(
                  value: context.read<BlogProvider>(),
                  child: BlogPostScreen(postId: post.id),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
