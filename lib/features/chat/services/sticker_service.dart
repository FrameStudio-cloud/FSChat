import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../core/services/local_storage_service.dart';
import '../models/sticker_model.dart';

class StickerService {
  static StickerService? _instance;
  List<StickerPack> _packs = [];
  bool _initialized = false;

  StickerService._();

  static StickerService get instance {
    _instance ??= StickerService._();
    return _instance!;
  }

  Future<void> init() async {
    if (_initialized) return;
    _packs = _builtInPacks();
    await _loadCustomPacks();
    _initialized = true;
  }

  Future<void> refresh() async {
    _packs = _builtInPacks();
    await _loadCustomPacks();
  }

  List<StickerPack> get packs => _packs;

  List<StickerPack> get builtInPacks =>
      _packs.where((p) => p.isBuiltIn).toList();

  List<StickerPack> get customPacks =>
      _packs.where((p) => !p.isBuiltIn).toList();

  StickerPack? getPack(String packId) {
    try {
      return _packs.firstWhere((p) => p.id == packId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadCustomPacks() async {
    try {
      final storage = await LocalStorageService.getInstance();
      final packIds = await storage.listStickerPackIds();
      for (final packId in packIds) {
        if (packId == 'cache' || packId == 'tmp') continue;
        final paths = await storage.listStickersInPack(packId);
        if (paths.isEmpty) continue;
        _packs.add(StickerPack(
          id: packId,
          name: packId == 'my_stickers' ? 'My Stickers' : packId,
          author: 'You',
          isBuiltIn: false,
          stickers: paths.map((p) {
            final name =
                p.split(Platform.pathSeparator).last.replaceAll('.jpg', '');
            return Sticker(id: name, packId: packId, localPath: p);
          }).toList(),
        ));
      }
    } catch (_) {}
  }

  static List<StickerPack> _builtInPacks() {
    return [
      StickerPack(
        id: 'wave',
        name: 'Wave',
        author: 'FSChat',
        isBuiltIn: true,
        stickers: [
          Sticker(id: 'wave_01', packId: 'wave', tags: ['hi', 'hello', 'hey']),
          Sticker(id: 'wave_02', packId: 'wave', tags: ['bye', 'goodbye']),
          Sticker(id: 'wave_03', packId: 'wave', tags: ['love', 'heart']),
          Sticker(
              id: 'wave_04', packId: 'wave', tags: ['lol', 'laugh', 'funny']),
          Sticker(id: 'wave_05', packId: 'wave', tags: ['sad', 'cry']),
          Sticker(id: 'wave_06', packId: 'wave', tags: ['cool', 'nice']),
          Sticker(id: 'wave_07', packId: 'wave', tags: ['angry', 'mad']),
          Sticker(id: 'wave_08', packId: 'wave', tags: ['clap', 'congrats']),
          Sticker(id: 'wave_09', packId: 'wave', tags: ['ok', 'done']),
          Sticker(id: 'wave_10', packId: 'wave', tags: ['party', 'celebrate']),
        ],
      ),
      StickerPack(
        id: 'reactions',
        name: 'Reactions',
        author: 'FSChat',
        isBuiltIn: true,
        stickers: [
          Sticker(
              id: 'react_01', packId: 'reactions', tags: ['like', 'thumbs']),
          Sticker(id: 'react_02', packId: 'reactions', tags: ['dislike']),
          Sticker(id: 'react_03', packId: 'reactions', tags: ['heart', 'love']),
          Sticker(id: 'react_04', packId: 'reactions', tags: ['fire', 'hot']),
          Sticker(
              id: 'react_05', packId: 'reactions', tags: ['100', 'perfect']),
          Sticker(id: 'react_06', packId: 'reactions', tags: ['clown', 'joke']),
          Sticker(
              id: 'react_07', packId: 'reactions', tags: ['smile', 'happy']),
          Sticker(id: 'react_08', packId: 'reactions', tags: ['cry', 'tears']),
        ],
      ),
    ];
  }

  static const Map<String, String> _emojiMap = {
    'wave_01': '👋',
    'wave_02': '✌️',
    'wave_03': '❤️',
    'wave_04': '😂',
    'wave_05': '😢',
    'wave_06': '😎',
    'wave_07': '😤',
    'wave_08': '👏',
    'wave_09': '👍',
    'wave_10': '🎉',
    'react_01': '👍',
    'react_02': '👎',
    'react_03': '❤️',
    'react_04': '🔥',
    'react_05': '💯',
    'react_06': '🤡',
    'react_07': '😊',
    'react_08': '😭',
  };

  static const List<Color> _emojiColors = [
    Color(0xFFFF6B6B),
    Color(0xFF4ECDC4),
    Color(0xFFFFE66D),
    Color(0xFF95E1D3),
    Color(0xFFF38181),
    Color(0xFFAA96DA),
    Color(0xFFFCBF49),
    Color(0xFFA8D8EA),
    Color(0xFF6C5B7B),
    Color(0xFFFCE38A),
  ];

  static Color _colorForSticker(String stickerId) =>
      _emojiColors[stickerId.hashCode.abs() % _emojiColors.length];

  static String _emojiForSticker(String stickerId) =>
      _emojiMap[stickerId] ?? '🤔';

  static Future<Uint8List> renderBuiltInStickerToBytes(
      String packId, String stickerId) async {
    final emoji = _emojiForSticker(stickerId);
    final bgColor = _colorForSticker(stickerId);
    const size = 256.0;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final rect = Rect.fromLTWH(0, 0, size, size);

    final bgPaint = Paint()..color = bgColor;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(32));
    canvas.drawRRect(rrect, bgPaint);

    final textStyle = ui.ParagraphStyle(
      textAlign: TextAlign.center,
      fontSize: 120,
      fontWeight: FontWeight.normal,
    );
    final textBuilder = ui.ParagraphBuilder(textStyle)
      ..pushStyle(ui.TextStyle(color: const Color(0xFF000000)))
      ..addText(emoji);
    final paragraph = textBuilder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: size));
    final yOffset = (size - paragraph.height) / 2;
    canvas.drawParagraph(paragraph, Offset(0, yOffset));

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  static Widget stickerPreview(String packId, String stickerId,
      {String? localPath}) {
    if (localPath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          File(localPath),
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _builtInPreview(packId, stickerId),
        ),
      );
    }
    return _builtInPreview(packId, stickerId);
  }

  static Widget _builtInPreview(String packId, String stickerId) {
    return Container(
      decoration: BoxDecoration(
        color: _colorForSticker(stickerId),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(_emojiForSticker(stickerId),
          style: const TextStyle(fontSize: 48)),
    );
  }
}
