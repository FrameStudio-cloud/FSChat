class Post {
  final String id;
  final String authorId;
  final String authorName;
  final String authorPhotoUrl;
  final String title;
  final String content;
  final String excerpt;
  final String type;
  final List<String> tags;
  final String? coverImage;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int likeCount;
  final List<String> likedBy;
  final int commentCount;

  Post({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorPhotoUrl = '',
    required this.title,
    required this.content,
    required this.excerpt,
    this.type = 'article',
    this.tags = const [],
    this.coverImage,
    required this.createdAt,
    required this.updatedAt,
    this.likeCount = 0,
    this.likedBy = const [],
    this.commentCount = 0,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'authorId': authorId,
        'authorName': authorName,
        'authorPhotoUrl': authorPhotoUrl,
        'title': title,
        'content': content,
        'excerpt': excerpt,
        'type': type,
        'tags': tags,
        'coverImage': coverImage,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'likeCount': likeCount,
        'likedBy': likedBy,
        'commentCount': commentCount,
      };

  factory Post.fromMap(Map<String, dynamic> map) => Post(
        id: map['id'] as String? ?? '',
        authorId: map['authorId'] as String? ?? '',
        authorName: map['authorName'] as String? ?? '',
        authorPhotoUrl: map['authorPhotoUrl'] as String? ?? '',
        title: map['title'] as String? ?? '',
        content: map['content'] as String? ?? '',
        excerpt: map['excerpt'] as String? ?? '',
        type: map['type'] as String? ?? 'article',
        tags: (map['tags'] as List?)?.map((e) => e as String).toList() ?? [],
        coverImage: map['coverImage'] as String?,
        createdAt: (map['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
        updatedAt: (map['updatedAt'] as dynamic)?.toDate() ?? DateTime.now(),
        likeCount: map['likeCount'] as int? ?? 0,
        likedBy:
            (map['likedBy'] as List?)?.map((e) => e as String).toList() ?? [],
        commentCount: map['commentCount'] as int? ?? 0,
      );

  static const postTypes = ['article', 'diary', 'letter', 'poem', 'journal'];
  static const defaultTags = [
    'Pain',
    'Psychology',
    'Body',
    'Strength',
    'Weakness'
  ];

  String get typeIcon {
    switch (type) {
      case 'article':
        return '\u{1F4DD}';
      case 'diary':
        return '\u{1F4D6}';
      case 'letter':
        return '\u{1F48C}';
      case 'poem':
        return '\u{1F3AD}';
      case 'journal':
        return '\u{1F4D4}';
      default:
        return '\u{1F4DD}';
    }
  }
}
