import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class ImageEditorScreen extends StatefulWidget {
  final String sourcePath;
  final Size outputSize;

  const ImageEditorScreen({
    super.key,
    required this.sourcePath,
    this.outputSize = const Size(512, 512),
  });

  @override
  State<ImageEditorScreen> createState() => _ImageEditorScreenState();
}

class _TextOverlay {
  String text;
  double fontSize;
  Color? bgColor;
  Offset position;

  _TextOverlay({
    required this.text,
    this.fontSize = 32,
    this.bgColor,
    this.position = Offset.zero,
  });
}

class _DrawingPath {
  final Color color;
  final double strokeWidth;
  final List<Offset> points;

  _DrawingPath({
    required this.color,
    this.strokeWidth = 4,
    required this.points,
  });
}

enum _EditorTool { pen, text, erase }

class _ImageEditorScreenState extends State<ImageEditorScreen> {
  final List<_DrawingPath> _paths = [];
  final List<_DrawingPath> _eraserPaths = [];
  final List<_TextOverlay> _texts = [];
  _DrawingPath? _currentPath;
  _DrawingPath? _currentEraserPath;
  _EditorTool _activeTool = _EditorTool.pen;
  Color _penColor = Colors.red;
  double _penWidth = 4;
  double _textFontSize = 32;
  Color? _textBgColor;
  ui.Image? _sourceImage;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final bytes = await File(widget.sourcePath).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: 1024);
      final frame = await codec.getNextFrame();
      setState(() {
        _sourceImage = frame.image;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load image: $e';
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    if (_sourceImage == null) return;

    try {
      final outSize = widget.outputSize;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      final hasErase = _eraserPaths.isNotEmpty;
      if (hasErase) {
        canvas.saveLayer(
            Rect.fromLTWH(0, 0, outSize.width, outSize.height), Paint());
      }

      final scaleX = outSize.width / widget.outputSize.width;
      final scaleY = outSize.height / widget.outputSize.height;

      final paint = Paint()..filterQuality = FilterQuality.high;
      canvas.drawImageRect(
        _sourceImage!,
        Rect.fromLTWH(0, 0, _sourceImage!.width.toDouble(),
            _sourceImage!.height.toDouble()),
        Rect.fromLTWH(0, 0, outSize.width, outSize.height),
        paint,
      );

      if (hasErase) {
        for (final path in _eraserPaths) {
          _drawEraserPathOnCanvas(canvas, path, scaleX);
        }
        canvas.restore();
      }

      for (final path in _paths) {
        if (path.points.length < 2) continue;
        final pathPaint = Paint()
          ..color = path.color
          ..strokeWidth = path.strokeWidth * scaleX
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;

        final uiPath = ui.Path();
        uiPath.moveTo(path.points[0].dx * scaleX, path.points[0].dy * scaleY);
        for (int i = 1; i < path.points.length; i++) {
          uiPath.lineTo(path.points[i].dx * scaleX, path.points[i].dy * scaleY);
        }
        canvas.drawPath(uiPath, pathPaint);
      }

      for (final text in _texts) {
        final posX = text.position.dx * scaleX;
        final posY = text.position.dy * scaleY;

        if (text.bgColor != null) {
          final textStyle = ui.ParagraphStyle(
            textAlign: TextAlign.left,
            fontSize: text.fontSize * scaleX,
          );
          final textBuilder = ui.ParagraphBuilder(textStyle)
            ..pushStyle(ui.TextStyle(color: const Color(0xFF000000)))
            ..addText(text.text);
          final para = textBuilder.build();
          para.layout(const ui.ParagraphConstraints(width: 500));

          final bgPaint = Paint()..color = text.bgColor!;
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                  posX - 4, posY - 2, para.width + 8, para.height + 4),
              const Radius.circular(4),
            ),
            bgPaint,
          );
        }

        final textStyle = ui.ParagraphStyle(
          textAlign: TextAlign.left,
          fontSize: text.fontSize * scaleX,
        );
        final painter = ui.ParagraphBuilder(textStyle)
          ..pushStyle(ui.TextStyle(color: const Color(0xFF000000)))
          ..addText(text.text);
        final para = painter.build();
        para.layout(const ui.ParagraphConstraints(width: 500));
        canvas.drawParagraph(para, Offset(posX, posY));
      }

      final picture = recorder.endRecording();
      final image =
          await picture.toImage(outSize.width.toInt(), outSize.height.toInt());
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      final outDir = Directory.systemTemp;
      final outPath =
          '${outDir.path}/edited_${const Uuid().v4().split('-').first}.png';
      await File(outPath).writeAsBytes(byteData!.buffer.asUint8List());

      if (mounted) Navigator.pop(context, outPath);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    }
  }

  void _addTextAt(Offset position) {
    showDialog(
      context: context,
      builder: (ctx) => _TextInputDialog(
        initialText: '',
        initialFontSize: _textFontSize,
        initialBgColor: _textBgColor,
        onDone: (text, fontSize, bgColor) {
          setState(() {
            _texts.add(_TextOverlay(
              text: text,
              fontSize: fontSize,
              bgColor: bgColor,
              position: position,
            ));
          });
        },
      ),
    );
  }

  void _editText(int index) {
    final existing = _texts[index];
    showDialog(
      context: context,
      builder: (ctx) => _TextInputDialog(
        initialText: existing.text,
        initialFontSize: existing.fontSize,
        initialBgColor: existing.bgColor,
        onDone: (text, fontSize, bgColor) {
          setState(() {
            _texts[index].text = text;
            _texts[index].fontSize = fontSize;
            _texts[index].bgColor = bgColor;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Image')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Image')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Image'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Done'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Stack(
                children: [
                  CustomPaint(
                    size: widget.outputSize,
                    painter: _EditorPainter(
                      sourceImage: _sourceImage,
                      paths: _paths,
                      currentPath: _currentPath,
                      eraserPaths: _eraserPaths,
                      currentEraserPath: _currentEraserPath,
                    ),
                  ),
                  ..._texts.asMap().entries.map((entry) {
                    final i = entry.key;
                    final t = entry.value;
                    return Positioned(
                      left: t.position.dx,
                      top: t.position.dy,
                      child: GestureDetector(
                        onTap: () => _editText(i),
                        onPanUpdate: (d) => setState(() {
                          _texts[i].position += d.delta;
                        }),
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 300),
                          decoration: t.bgColor != null
                              ? BoxDecoration(
                                  color: t.bgColor,
                                  borderRadius: BorderRadius.circular(4),
                                )
                              : null,
                          padding: t.bgColor != null
                              ? const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 1)
                              : EdgeInsets.zero,
                          child: Text(
                            t.text,
                            style: TextStyle(
                              fontSize: t.fontSize,
                              color: t.bgColor == Colors.black
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  Positioned.fill(
                    child: _activeTool == _EditorTool.pen
                        ? GestureDetector(
                            onPanStart: _onPanStart,
                            onPanUpdate: _onPanUpdate,
                            onPanEnd: _onPanEnd,
                            behavior: HitTestBehavior.translucent,
                          )
                        : _activeTool == _EditorTool.erase
                            ? GestureDetector(
                                onPanStart: _onEraserPanStart,
                                onPanUpdate: _onEraserPanUpdate,
                                onPanEnd: _onEraserPanEnd,
                                behavior: HitTestBehavior.translucent,
                              )
                            : GestureDetector(
                                onTapUp: (details) =>
                                    _addTextAt(details.localPosition),
                                behavior: HitTestBehavior.translucent,
                              ),
                  ),
                ],
              ),
            ),
          ),
          _buildToolbar(),
        ],
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    _currentPath = _DrawingPath(
        color: _penColor,
        strokeWidth: _penWidth,
        points: [details.localPosition]);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    _currentPath?.points.add(details.localPosition);
    setState(() {});
  }

  void _onPanEnd(DragEndDetails details) {
    if (_currentPath != null) {
      setState(() {
        _paths.add(_currentPath!);
        _currentPath = null;
      });
    }
  }

  void _onEraserPanStart(DragStartDetails details) {
    _currentEraserPath = _DrawingPath(
        color: Colors.white,
        strokeWidth: _penWidth,
        points: [details.localPosition]);
  }

  void _onEraserPanUpdate(DragUpdateDetails details) {
    _currentEraserPath?.points.add(details.localPosition);
    setState(() {});
  }

  void _drawEraserPathOnCanvas(Canvas canvas, _DrawingPath path, double scale) {
    if (path.points.length < 2) return;
    final paint = Paint()
      ..blendMode = BlendMode.clear
      ..strokeWidth = path.strokeWidth * scale
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final uiPath = Path();
    uiPath.moveTo(path.points[0].dx * scale, path.points[0].dy * scale);
    for (int i = 1; i < path.points.length; i++) {
      uiPath.lineTo(path.points[i].dx * scale, path.points[i].dy * scale);
    }
    canvas.drawPath(uiPath, paint);
  }

  void _onEraserPanEnd(DragEndDetails details) {
    if (_currentEraserPath != null) {
      setState(() {
        _eraserPaths.add(_currentEraserPath!);
        _currentEraserPath = null;
      });
    }
  }

  Widget _buildToolbar() {
    const colors = [
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.green,
      Colors.cyan,
      Colors.blue,
      Colors.purple,
      Colors.black,
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E1E1E)
            : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _toolButton(Icons.brush, 'Pen', _EditorTool.pen),
              const SizedBox(width: 4),
              _toolButton(Icons.text_fields, 'Text', _EditorTool.text),
              const SizedBox(width: 4),
              _toolButton(Icons.auto_fix_high, 'Erase', _EditorTool.erase),
              const Spacer(),
              if (_paths.isNotEmpty || _texts.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.undo),
                  onPressed: _undo,
                  tooltip: 'Undo',
                ),
              if (_paths.isNotEmpty || _texts.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    setState(() {
                      _paths.clear();
                      _eraserPaths.clear();
                      _texts.clear();
                    });
                  },
                  tooltip: 'Reset',
                ),
            ],
          ),
          if (_activeTool == _EditorTool.pen) ...[
            const SizedBox(height: 4),
            Row(
              children: colors.map((c) {
                final isSelected = _penColor.value == c.value;
                return GestureDetector(
                  onTap: () => setState(() => _penColor = c),
                  child: Container(
                    width: 28,
                    height: 28,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                  color: c.withValues(alpha: 0.5),
                                  blurRadius: 4)
                            ]
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  const Icon(Icons.line_weight, size: 18),
                  Expanded(
                    child: Slider(
                      value: _penWidth,
                      min: 2,
                      max: 12,
                      divisions: 10,
                      label: _penWidth.round().toString(),
                      onChanged: (v) => setState(() => _penWidth = v),
                    ),
                  ),
                  Text('${_penWidth.round()}'),
                ],
              ),
            ),
          ],
          if (_activeTool == _EditorTool.text) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  const Text('Bg:', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 8),
                  _bgOption('None', null),
                  _bgOption('White', Colors.white),
                  _bgOption('Black', Colors.black),
                  const Spacer(),
                  const Icon(Icons.text_fields, size: 18),
                  Expanded(
                    child: Slider(
                      value: _textFontSize,
                      min: 12,
                      max: 72,
                      divisions: 20,
                      label: '${_textFontSize.round()}',
                      onChanged: (v) => setState(() => _textFontSize = v),
                    ),
                  ),
                  Text('${_textFontSize.round()}'),
                ],
              ),
            ),
          ],
          if (_activeTool == _EditorTool.erase) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  const Icon(Icons.line_weight, size: 18),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Slider(
                      value: _penWidth,
                      min: 2,
                      max: 40,
                      divisions: 19,
                      label: _penWidth.round().toString(),
                      onChanged: (v) => setState(() => _penWidth = v),
                    ),
                  ),
                  Text('${_penWidth.round()}'),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _bgOption(String label, Color? color) {
    final isSelected = _textBgColor?.value == color?.value;
    return GestureDetector(
      onTap: () => setState(() => _textBgColor = color),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[400]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color == Colors.black ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _toolButton(IconData icon, String label, _EditorTool tool) {
    final isActive = _activeTool == tool;
    return GestureDetector(
      onTap: () => setState(() => _activeTool = tool),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 20,
                color: isActive
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isActive
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[600],
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _undo() {
    setState(() {
      if (_texts.isNotEmpty &&
          (_paths.isEmpty && _eraserPaths.isEmpty ||
              _texts.last.position.dy >
                  (_paths.isNotEmpty ? _paths.last.points.last.dy : 0))) {
        _texts.removeLast();
      } else if (_eraserPaths.isNotEmpty) {
        _eraserPaths.removeLast();
      } else if (_paths.isNotEmpty) {
        _paths.removeLast();
      }
    });
  }
}

class _EditorPainter extends CustomPainter {
  final ui.Image? sourceImage;
  final List<_DrawingPath> paths;
  final _DrawingPath? currentPath;
  final List<_DrawingPath> eraserPaths;
  final _DrawingPath? currentEraserPath;

  _EditorPainter({
    required this.sourceImage,
    required this.paths,
    this.currentPath,
    this.eraserPaths = const [],
    this.currentEraserPath,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (sourceImage != null) {
      final hasErase = eraserPaths.isNotEmpty || currentEraserPath != null;
      if (hasErase) {
        canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());
      }

      final paint = Paint()..filterQuality = FilterQuality.high;
      canvas.drawImageRect(
        sourceImage!,
        Rect.fromLTWH(0, 0, sourceImage!.width.toDouble(),
            sourceImage!.height.toDouble()),
        Rect.fromLTWH(0, 0, size.width, size.height),
        paint,
      );

      if (hasErase) {
        for (final path in eraserPaths) {
          _drawEraserPath(canvas, path);
        }
        if (currentEraserPath != null) {
          _drawEraserPath(canvas, currentEraserPath!);
        }
        canvas.restore();
      }
    }

    for (final path in paths) {
      _drawPath(canvas, path);
    }
    if (currentPath != null) {
      _drawPath(canvas, currentPath!);
    }
  }

  void _drawEraserPath(Canvas canvas, _DrawingPath path) {
    if (path.points.length < 2) return;
    final paint = Paint()
      ..blendMode = BlendMode.clear
      ..strokeWidth = path.strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final uiPath = Path();
    uiPath.moveTo(path.points[0].dx, path.points[0].dy);
    for (int i = 1; i < path.points.length; i++) {
      uiPath.lineTo(path.points[i].dx, path.points[i].dy);
    }
    canvas.drawPath(uiPath, paint);
  }

  void _drawPath(Canvas canvas, _DrawingPath path) {
    if (path.points.length < 2) return;
    final paint = Paint()
      ..color = path.color
      ..strokeWidth = path.strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final uiPath = Path();
    uiPath.moveTo(path.points[0].dx, path.points[0].dy);
    for (int i = 1; i < path.points.length; i++) {
      uiPath.lineTo(path.points[i].dx, path.points[i].dy);
    }
    canvas.drawPath(uiPath, paint);
  }

  @override
  bool shouldRepaint(_EditorPainter oldDelegate) => true;
}

class _TextInputDialog extends StatefulWidget {
  final String initialText;
  final double initialFontSize;
  final Color? initialBgColor;
  final void Function(String text, double fontSize, Color? bgColor) onDone;

  const _TextInputDialog({
    required this.initialText,
    required this.initialFontSize,
    required this.initialBgColor,
    required this.onDone,
  });

  @override
  State<_TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<_TextInputDialog> {
  late TextEditingController _controller;
  late double _fontSize;
  Color? _bgColor;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _fontSize = widget.initialFontSize;
    _bgColor = widget.initialBgColor;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Text'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Type your text...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Size:', style: TextStyle(fontSize: 12)),
              Expanded(
                child: Slider(
                  value: _fontSize,
                  min: 12,
                  max: 72,
                  divisions: 20,
                  label: '${_fontSize.round()}',
                  onChanged: (v) => setState(() => _fontSize = v),
                ),
              ),
              Text('${_fontSize.round()}'),
            ],
          ),
          Row(
            children: [
              const Text('Bg:', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 8),
              _option('None', null),
              _option('White', Colors.white),
              _option('Black', Colors.black),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_controller.text.trim().isNotEmpty) {
              widget.onDone(
                _controller.text.trim(),
                _fontSize,
                _bgColor,
              );
              Navigator.pop(context);
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }

  Widget _option(String label, Color? color) {
    final isSelected = _bgColor?.value == color?.value;
    return GestureDetector(
      onTap: () => setState(() => _bgColor = color),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[400]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color == Colors.black ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}
