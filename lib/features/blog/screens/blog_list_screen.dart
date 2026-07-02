import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/database_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/post_model.dart';
import '../providers/blog_provider.dart';
import '../widgets/post_card.dart';
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal'),
        centerTitle: false,
      ),
      body: StreamBuilder<List<Post>>(
        stream: _db.allPostsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Something went wrong',
                  style: theme.textTheme.bodyMedium),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var posts = snapshot.data!;

          final totalPosts = posts.length;
          final totalLikes = posts.fold<int>(0, (s, p) => s + p.likeCount);
          final totalComments =
              posts.fold<int>(0, (s, p) => s + p.commentCount);

          final tagCounts = <String, int>{};
          for (final p in posts) {
            for (final t in p.tags) {
              tagCounts[t] = (tagCounts[t] ?? 0) + 1;
            }
          }
          final sortedTags = tagCounts.keys.toList()
            ..sort((a, b) => tagCounts[b]!.compareTo(tagCounts[a]!));

          final query = _searchController.text.trim().toLowerCase();
          if (_selectedTag != null) {
            posts = posts.where((p) => p.tags.contains(_selectedTag)).toList();
          }
          if (query.isNotEmpty) {
            posts = posts
                .where((p) =>
                    p.title.toLowerCase().contains(query) ||
                    p.excerpt.toLowerCase().contains(query))
                .toList();
          }

          return Column(
            children: [
              _StatsRow(
                totalPosts: totalPosts,
                totalLikes: totalLikes,
                totalComments: totalComments,
              ),
              _SearchField(
                controller: _searchController,
                onChanged: () => setState(() {}),
              ),
              _SectionHeader(
                icon: Icons.explore_rounded,
                title: 'Browse',
              ),
              _FilterShelf(
                tags: sortedTags,
                tagCounts: tagCounts,
                selectedTag: _selectedTag,
                onTagSelected: (tag) {
                  setState(() {
                    _selectedTag = _selectedTag == tag ? null : tag;
                  });
                },
              ),
              _SectionHeader(
                icon: Icons.article_rounded,
                title: 'Recent Posts',
              ),
              Expanded(
                child: posts.isEmpty
                    ? _EmptyState(
                        isSearch: query.isNotEmpty || _selectedTag != null,
                      )
                    : RefreshIndicator(
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
                      ),
              ),
            ],
          );
        },
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
}

class _StatsRow extends StatelessWidget {
  final int totalPosts;
  final int totalLikes;
  final int totalComments;

  const _StatsRow({
    required this.totalPosts,
    required this.totalLikes,
    required this.totalComments,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          _StatTile(
            icon: Icons.description_rounded,
            value: '$totalPosts',
            label: 'Posts',
            color: colorScheme.primary,
          ),
          const SizedBox(width: 10),
          _StatTile(
            icon: Icons.favorite_rounded,
            value: '$totalLikes',
            label: 'Likes',
            color: Colors.red.shade400,
          ),
          const SizedBox(width: 10),
          _StatTile(
            icon: Icons.chat_rounded,
            value: '$totalComments',
            label: 'Comments',
            color: Colors.blue.shade400,
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 14),
            ),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                    height: 1.1,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onChanged;

  const _SearchField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: 'Search posts...',
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
        onChanged: (_) => onChanged(),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _FilterShelf extends StatelessWidget {
  final List<String> tags;
  final Map<String, int> tagCounts;
  final String? selectedTag;
  final ValueChanged<String> onTagSelected;

  const _FilterShelf({
    required this.tags,
    required this.tagCounts,
    this.selectedTag,
    required this.onTagSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 80,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _FilterTile(
            icon: Icons.grid_view_rounded,
            label: 'All',
            count: tagCounts.values.fold(0, (s, c) => s + c),
            isActive: selectedTag == null,
            onTap: () => onTagSelected(''),
          ),
          const SizedBox(width: 10),
          ...tags.map((tag) => Padding(
                padding: const EdgeInsets.only(right: 10),
                child: _FilterTile(
                  icon: null,
                  label: tag,
                  count: tagCounts[tag] ?? 0,
                  isActive: selectedTag == tag,
                  onTap: () => onTagSelected(tag),
                ),
              )),
        ],
      ),
    );
  }
}

class _FilterTile extends StatelessWidget {
  final IconData? icon;
  final String label;
  final int count;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterTile({
    this.icon,
    required this.label,
    required this.count,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isActive
        ? (isDark
            ? colorScheme.primary.withValues(alpha: 0.15)
            : colorScheme.primary.withValues(alpha: 0.08))
        : colorScheme.surfaceContainerLow;
    final iconBg = isActive
        ? colorScheme.primary
        : (isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.04));
    final labelColor =
        isActive ? colorScheme.primary : colorScheme.onSurfaceVariant;
    final countColor = isActive ? colorScheme.primary : colorScheme.outline;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 68,
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(7),
              ),
              child: icon != null
                  ? Icon(icon,
                      color: isActive
                          ? Colors.white
                          : colorScheme.onSurfaceVariant,
                      size: 13)
                  : Center(
                      child: Text(
                        _emojiForTag(label),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: labelColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: countColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _emojiForTag(String tag) {
    const map = {
      'design': '🎨',
      'tech': '⚙️',
      'technology': '⚙️',
      'life': '🌿',
      'poetry': '🎭',
      'poem': '🎭',
      'ideas': '💡',
      'idea': '💡',
      'journal': '📓',
      'diary': '📖',
      'letter': '💌',
      'article': '📝',
      'writing': '✍️',
      'travel': '🌍',
      'food': '🍳',
      'music': '🎵',
      'art': '🖼️',
      'health': '💪',
      'fitness': '💪',
      'productivity': '⚡',
      'code': '💻',
      'personal': '👤',
      'nature': '🌿',
      'photography': '📷',
    };
    return map[tag.toLowerCase()] ?? '🏷️';
  }
}

class _EmptyState extends StatelessWidget {
  final bool isSearch;

  const _EmptyState({required this.isSearch});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              isSearch ? Icons.search_off_rounded : Icons.article_outlined,
              size: 32,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isSearch ? 'No posts found' : 'No entries yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isSearch
                ? 'Try a different search term or filter'
                : 'Tap + to write your first journal entry',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
