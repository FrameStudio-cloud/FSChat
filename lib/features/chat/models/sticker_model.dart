class StickerPack {
  final String id;
  final String name;
  final String author;
  final bool isBuiltIn;
  final List<Sticker> stickers;

  StickerPack({
    required this.id,
    required this.name,
    this.author = 'Kairos',
    this.isBuiltIn = false,
    required this.stickers,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'author': author,
        'isBuiltIn': isBuiltIn,
      };

  factory StickerPack.fromMap(Map<String, dynamic> map) => StickerPack(
        id: map['id'] ?? '',
        name: map['name'] ?? '',
        author: map['author'] ?? 'Kairos',
        isBuiltIn: map['isBuiltIn'] ?? false,
        stickers: [],
      );
}

class Sticker {
  final String id;
  final String packId;
  final String? localPath;
  final String? remoteUrl;
  final List<String> tags;

  Sticker({
    required this.id,
    required this.packId,
    this.localPath,
    this.remoteUrl,
    this.tags = const [],
  });
}
