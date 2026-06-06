import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  String _wallpaper = '';
  String _wallpaperImagePath = '';

  ThemeMode get themeMode => _themeMode;
  String get wallpaper => _wallpaper;
  String get wallpaperImagePath => _wallpaperImagePath;

  Future<void> loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('dark_mode') ?? false;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;

    _wallpaper = prefs.getString('wallpaper') ?? '';
    if (_wallpaper == 'image') {
      _wallpaperImagePath = await _computeWallpaperPath();
      final file = File(_wallpaperImagePath);
      if (!await file.exists()) {
        _wallpaper = '';
        _wallpaperImagePath = '';
      }
    }

    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _themeMode = value ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', value);
  }

  Future<void> setWallpaper(String value) async {
    _wallpaper = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('wallpaper', value);
  }

  Future<void> setWallpaperImage(String sourcePath) async {
    _wallpaperImagePath = await _computeWallpaperPath();
    final dir = File(_wallpaperImagePath).parent;
    await dir.create(recursive: true);
    final saved = await FlutterImageCompress.compressAndGetFile(
      sourcePath,
      _wallpaperImagePath,
      quality: 70,
      minWidth: 1080,
      minHeight: 1920,
    );
    if (saved != null) {
      await setWallpaper('image');
    }
  }

  Future<void> removeWallpaper() async {
    if (_wallpaperImagePath.isNotEmpty) {
      final file = File(_wallpaperImagePath);
      if (await file.exists()) await file.delete();
    }
    _wallpaperImagePath = '';
    await setWallpaper('');
  }

  BoxDecoration? get wallpaperDecoration {
    if (_wallpaper.isEmpty) return null;
    if (_wallpaper == 'image' && _wallpaperImagePath.isNotEmpty) {
      return BoxDecoration(
        image: DecorationImage(
          image: FileImage(File(_wallpaperImagePath)),
          fit: BoxFit.cover,
        ),
      );
    }
    try {
      final color = Color(int.parse(_wallpaper.replaceFirst('#', '0xff')));
      return BoxDecoration(color: color);
    } catch (_) {
      return null;
    }
  }

  Future<String> _computeWallpaperPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/fschat/wallpapers/current.jpg';
  }
}
