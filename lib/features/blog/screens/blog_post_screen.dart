import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/services/database_service.dart';
import '../../../shared/utils/avatar_helper.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/models/user_model.dart';
import '../models/post_model.dart';
import '../widgets/comment_section.dart';
import '../providers/blog_provider.dart';

class BlogPostScreen extends StatefulWidget {
  final String postId;

  const BlogPostScreen({super.key, required this.postId});

  @override
  State<BlogPostScreen> createState() => _BlogPostScreenState();
}

class _BlogPostScreenState extends State<BlogPostScreen> {
  final _db = DatabaseService();
  bool _isLiked = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentUid = context.watch<AuthProvider>().user?.uid;
    final blogProvider = context.watch<BlogProvider>();

    return Scaffold(
      body: StreamBuilder<Post?>(
        stream: _db.allPostsStream().map(
            (posts) => posts.where((p) => p.id == widget.postId).firstOrNull),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
                child: Text('Failed to load post',
                    style: theme.textTheme.bodyMedium));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final post = snapshot.data!;
          final isOwner = post.authorId == currentUid;

          if (!_isLiked && currentUid != null) {
            _isLiked = post.likedBy.contains(currentUid);
          }

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: post.coverImage != null ? 240 : 120,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: post.coverImage != null
                      ? CachedNetworkImage(
                          imageUrl: post.coverImage!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorWidget: (_, __, ___) => const SizedBox.shrink(),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                colorScheme.primaryContainer,
                                colorScheme.primary.withAlpha(50),
                              ],
                            ),
                          ),
                        ),
                ),
                actions: [
                  if (isOwner)
                    PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'delete') {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete post?'),
                              content: const Text(
                                  'This will permanently delete this post and all comments.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await blogProvider.deletePost(widget.postId);
                            if (context.mounted) Navigator.pop(context);
                          }
                        } else if (value == 'edit') {
                          // TODO: navigate to editor with pre-filled data
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                            value: 'edit',
                            child: Row(children: [
                              Icon(Icons.edit_outlined, size: 18),
                              SizedBox(width: 8),
                              Text('Edit')
                            ])),
                        const PopupMenuItem(
                            value: 'delete',
                            child: Row(children: [
                              Icon(Icons.delete_outline,
                                  size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete',
                                  style: TextStyle(color: Colors.red))
                            ])),
                      ],
                    ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(post.typeIcon,
                              style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              post.title,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          avatarWidget(
                            radius: 16,
                            photoUrl: post.authorPhotoUrl,
                            name: post.authorName,
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                post.authorName,
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                DateFormat('MMMM d, yyyy')
                                    .format(post.createdAt),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (post.tags.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 6,
                          children: post.tags
                              .map((tag) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary.withAlpha(25),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      tag,
                                      style:
                                          theme.textTheme.labelSmall?.copyWith(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ],
                      const SizedBox(height: 20),
                      MarkdownBody(
                        data: post.content,
                        styleSheet: MarkdownStyleSheet(
                          h1: theme.textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          h2: theme.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                          h3: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          p: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
                          listBullet: theme.textTheme.bodyLarge,
                          blockquoteDecoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                color: colorScheme.primary,
                                width: 3,
                              ),
                            ),
                            color: colorScheme.surfaceContainerHighest,
                          ),
                          blockquotePadding: const EdgeInsets.all(12),
                          code: theme.textTheme.bodyMedium?.copyWith(
                            fontFamily: 'monospace',
                            backgroundColor:
                                colorScheme.surfaceContainerHighest,
                          ),
                          codeblockDecoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          codeblockPadding: const EdgeInsets.all(12),
                          horizontalRuleDecoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: colorScheme.outlineVariant,
                                width: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            if (currentUid == null) return;
                            if (_isLiked) {
                              await blogProvider.unlikePost(widget.postId);
                            } else {
                              await blogProvider.likePost(widget.postId);
                            }
                            if (context.mounted) {
                              setState(() => _isLiked = !_isLiked);
                            }
                          },
                          icon: Icon(
                            _isLiked ? Icons.favorite : Icons.favorite_border,
                            color: _isLiked ? Colors.red : null,
                          ),
                          label: Text(
                            _isLiked
                                ? 'Liked (${post.likeCount + (_isLiked == post.likedBy.contains(currentUid) ? 0 : _isLiked ? 1 : -1)})'
                                : 'Like (${post.likeCount})',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _isLiked ? Colors.red : null,
                            side: BorderSide(
                              color: _isLiked
                                  ? Colors.red.withAlpha(100)
                                  : colorScheme.outline,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: CommentSection(
                  postId: widget.postId,
                  commentsStream: _db.commentsStream(widget.postId),
                  onAddComment: (content) =>
                      blogProvider.addComment(widget.postId, content),
                  onDeleteComment: (commentId) =>
                      blogProvider.deleteComment(widget.postId, commentId),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          );
        },
      ),
    );
  }
}
