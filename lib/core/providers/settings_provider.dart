import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  String _notificationSound = 'default';
  bool _notificationVibrate = true;
  bool _messagePreview = true;
  String _bubbleStyle = 'rounded';
  String _fontSize = 'medium';
  bool _readReceipts = true;

  String get notificationSound => _notificationSound;
  bool get notificationVibrate => _notificationVibrate;
  bool get messagePreview => _messagePreview;
  String get bubbleStyle => _bubbleStyle;
  String get fontSize => _fontSize;
  bool get readReceipts => _readReceipts;

  double get textScaleFactor {
    switch (_fontSize) {
      case 'small':
        return 0.85;
      case 'large':
        return 1.15;
      default:
        return 1.0;
    }
  }

  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _notificationSound = prefs.getString('notificationSound') ?? 'default';
    _notificationVibrate = prefs.getBool('notificationVibrate') ?? true;
    _messagePreview = prefs.getBool('messagePreview') ?? true;
    _bubbleStyle = prefs.getString('bubbleStyle') ?? 'rounded';
    _fontSize = prefs.getString('fontSize') ?? 'medium';
    _readReceipts = prefs.getBool('readReceipts') ?? true;
    notifyListeners();
  }

  Future<void> setNotificationSound(String value) async {
    _notificationSound = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notificationSound', value);
  }

  Future<void> setNotificationVibrate(bool value) async {
    _notificationVibrate = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationVibrate', value);
  }

  Future<void> setMessagePreview(bool value) async {
    _messagePreview = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('messagePreview', value);
  }

  Future<void> setBubbleStyle(String value) async {
    _bubbleStyle = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('bubbleStyle', value);
  }

  Future<void> setFontSize(String value) async {
    _fontSize = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fontSize', value);
  }

  Future<void> setReadReceipts(bool value) async {
    _readReceipts = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('readReceipts', value);
  }
}
