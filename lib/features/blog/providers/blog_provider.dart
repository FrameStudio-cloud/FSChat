import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/database_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';

class BlogProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final Uuid _uuid = Uuid();
  AuthProvider? _authProvider;

  void setAuthProvider(AuthProvider auth) {
    _authProvider = auth;
  }

  String? get currentUid => _authProvider?.user?.uid;
  String? get currentName =>
      _authProvider?.chatUser?.name ?? _authProvider?.user?.displayName;
  String? get currentPhotoUrl => _authProvider?.chatUser?.photoUrl;

  Future<void> createPost({
    required String title,
    required String content,
    required String type,
    required List<String> tags,
    String? coverImagePath,
  }) async {
    final uid = currentUid;
    if (uid == null) return;

    final postId = _uuid.v4();
    final now = DateTime.now();
    final excerpt =
        content.length > 150 ? '${content.substring(0, 150)}...' : content;

    String? coverUrl;
    if (coverImagePath != null) {
      coverUrl = await _db.uploadPostCover(postId, coverImagePath);
    }

    final post = Post(
      id: postId,
      authorId: uid,
      authorName: currentName ?? 'Unknown',
      authorPhotoUrl: currentPhotoUrl ?? '',
      title: title,
      content: content,
      excerpt: excerpt,
      type: type,
      tags: tags,
      coverImage: coverUrl,
      createdAt: now,
      updatedAt: now,
    );

    await _db.createPost(post);
  }

  Future<void> updatePost(String postId, Map<String, dynamic> updates) async {
    updates['updatedAt'] = DateTime.now();
    await _db.updatePost(postId, updates);
  }

  Future<void> deletePost(String postId) async {
    await _db.deletePost(postId);
  }

  Future<void> likePost(String postId) async {
    final uid = currentUid;
    if (uid == null) return;
    await _db.likePost(postId, uid);
  }

  Future<void> unlikePost(String postId) async {
    final uid = currentUid;
    if (uid == null) return;
    await _db.unlikePost(postId, uid);
  }

  Future<void> addComment(String postId, String content) async {
    final uid = currentUid;
    if (uid == null) return;
    final comment = Comment(
      id: _uuid.v4(),
      authorId: uid,
      authorName: currentName ?? 'Unknown',
      authorPhotoUrl: currentPhotoUrl ?? '',
      content: content,
      createdAt: DateTime.now(),
    );
    await _db.addComment(postId, comment);
  }

  Future<void> deleteComment(String postId, String commentId) async {
    await _db.deleteComment(postId, commentId);
  }
}
