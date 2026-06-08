import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/local_storage_service.dart';
import '../../../shared/widgets/image_editor_screen.dart';
import '../services/sticker_service.dart';

class StickerCreatorScreen extends StatefulWidget {
  const StickerCreatorScreen({super.key});

  @override
  State<StickerCreatorScreen> createState() => _StickerCreatorScreenState();
}

class _StickerCreatorScreenState extends State<StickerCreatorScreen> {
  File? _source;
  File? _cropped;
  bool _saving = false;
  bool _processing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _pickImage());
  }

  Future<void> _pickImage() async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (!mounted) return;
      if (file == null) {
        Navigator.pop(context);
        return;
      }
      setState(() => _source = File(file.path));
      await _cropToSquare();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Could not open gallery: $e');
    }
  }

  Future<void> _cropToSquare() async {
    if (_source == null) return;
    setState(() => _processing = true);
    try {
      final bytes = await _source!.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      final side = image.width < image.height ? image.width : image.height;
      final offsetX = (image.width - side) ~/ 2;
      final offsetY = (image.height - side) ~/ 2;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final paint = Paint()..filterQuality = FilterQuality.high;

      canvas.drawImageRect(
        image,
        Rect.fromLTWH(offsetX.toDouble(), offsetY.toDouble(), side.toDouble(),
            side.toDouble()),
        Rect.fromLTWH(0, 0, 256, 256),
        paint,
      );

      final picture = recorder.endRecording();
      final resized = await picture.toImage(256, 256);
      final byteData = await resized.toByteData(format: ui.ImageByteFormat.png);

      final dir = Directory.systemTemp;
      final outPath =
          '${dir.path}/sticker_cropped_${const Uuid().v4().split('-').first}.png';
      await File(outPath).writeAsBytes(byteData!.buffer.asUint8List());

      if (!mounted) return;
      setState(() {
        _cropped = File(outPath);
        _processing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to process image: $e';
        _processing = false;
      });
    }
  }

  Future<void> _saveSticker() async {
    if (_cropped == null) return;
    setState(() => _saving = true);
    try {
      final storage = await LocalStorageService.getInstance();
      final stickerId = const Uuid().v4().split('-').first;
      await storage.saveStickerToPack('my_stickers', stickerId, _cropped!.path);
      await StickerService.instance.refresh();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sticker added!'),
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Failed to save: $e');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _openEditor() async {
    if (_cropped == null) return;
    final editedPath = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => ImageEditorScreen(
          sourcePath: _cropped!.path,
          outputSize: const Size(256, 256),
        ),
      ),
    );
    if (editedPath != null && mounted) {
      setState(() => _cropped = File(editedPath));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Sticker'),
        actions: [
          if (_cropped != null && !_processing) ...[
            TextButton(
              onPressed: _saving ? null : _openEditor,
              child: const Text('Edit'),
            ),
            TextButton(
              onPressed: _saving ? null : _saveSticker,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ],
      ),
      body: Center(
        child: _error != null
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              )
            : _processing
                ? const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Processing image...'),
                    ],
                  )
                : _cropped != null
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(
                              _cropped!,
                              width: 256,
                              height: 256,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Tap Save to add to your stickers',
                            style: TextStyle(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      )
                    : const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Opening gallery...'),
                        ],
                      ),
      ),
    );
  }
}
