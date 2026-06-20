import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class LocalStorageService {
  static LocalStorageService? _instance;
  late final String _appDir;

  LocalStorageService._();

  static Future<LocalStorageService> getInstance() async {
    if (_instance == null) {
      _instance = LocalStorageService._();
      await _instance!._init();
    }
    return _instance!;
  }

  Future<void> _init() async {
    final docDir = await getApplicationDocumentsDirectory();
    _appDir = '${docDir.path}/fschat';
    await Directory('$_appDir/wallpapers').create(recursive: true);
    await Directory('$_appDir/cache').create(recursive: true);
    await Directory('$_appDir/stickers').create(recursive: true);
  }

  String get stickersDir => '$_appDir/stickers';

  Future<String> saveStickerToPack(
      String packId, String stickerId, String sourcePath) async {
    final dir = Directory('$stickersDir/$packId');
    await dir.create(recursive: true);
    final target = '${dir.path}/$stickerId.jpg';
    final file = await FlutterImageCompress.compressAndGetFile(
      sourcePath,
      target,
      quality: 80,
      minWidth: 256,
      minHeight: 256,
    );
    return file?.path ?? target;
  }

  String stickerLocalPath(String packId, String stickerId) {
    return '$stickersDir/$packId/$stickerId.jpg';
  }

  Future<List<String>> listStickerPackIds() async {
    final dir = Directory(stickersDir);
    if (!await dir.exists()) return [];
    return dir
        .listSync()
        .whereType<Directory>()
        .map((d) => d.path.split(Platform.pathSeparator).last)
        .toList();
  }

  Future<List<String>> listStickersInPack(String packId) async {
    final dir = Directory('$stickersDir/$packId');
    if (!await dir.exists()) return [];
    return dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.jpg'))
        .map((f) => f.path)
        .toList();
  }

  String get wallpaperPath => '$_appDir/wallpapers/current.jpg';
  String get wallpaperDir => '$_appDir/wallpapers';

  Future<String?> saveWallpaper(String sourcePath) async {
    final target = wallpaperPath;
    final file = await FlutterImageCompress.compressAndGetFile(
      sourcePath,
      target,
      quality: 70,
      minWidth: 1080,
      minHeight: 1920,
    );
    return file?.path;
  }

  Future<void> removeWallpaper() async {
    final file = File(wallpaperPath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<bool> hasWallpaperImage() async {
    return await File(wallpaperPath).exists();
  }

  Future<File?> getCachedProfilePhoto(String uid) async {
    final file = File('$_appDir/cache/profile_$uid.jpg');
    if (await file.exists()) return file;
    return null;
  }

  Future<String> cacheProfilePhoto(String uid, String url) async {
    final file = File('$_appDir/cache/profile_$uid.jpg');
    // Download and compress would go here
    return file.path;
  }
}
