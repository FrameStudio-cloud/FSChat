class Comment {
  final String id;
  final String authorId;
  final String authorName;
  final String authorPhotoUrl;
  final String content;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorPhotoUrl = '',
    required this.content,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'authorId': authorId,
        'authorName': authorName,
        'authorPhotoUrl': authorPhotoUrl,
        'content': content,
        'createdAt': createdAt,
      };

  factory Comment.fromMap(Map<String, dynamic> map) => Comment(
        id: map['id'] as String? ?? '',
        authorId: map['authorId'] as String? ?? '',
        authorName: map['authorName'] as String? ?? '',
        authorPhotoUrl: map['authorPhotoUrl'] as String? ?? '',
        content: map['content'] as String? ?? '',
        createdAt: (map['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      );
}
