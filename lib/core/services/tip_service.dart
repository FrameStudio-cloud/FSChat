import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TipService {
  static const _prefKey = 'tip_index';

  static const _tips = [
    'Long-press a message, then tap Select to choose multiple messages and delete them in one go',
    'Tap the + button, then Multi to send up to 10 photos at once',
    'Swipe right on any message to reply with a quoted preview',
    'Type @ followed by a name to mention someone in the chat',
    'Tap the wallpaper icon in the chat header to set a custom background',
    'Long-press your own message to Edit it (within 15 minutes) or Delete for everyone',
    'Hold the mic button to record a voice message — tap to send when done',
    'Tap an image to view it fullscreen; pinch to zoom in and out',
    'Tap a multi-image bubble to open the gallery — swipe left/right through all photos',
    'Toggle dark mode in Settings for a comfortable night-time experience',
    'Long-press a chat in the list to Pin it to the top or Delete the conversation',
    'Tap the sticker icon to browse built-in stickers or create your own custom stickers',
  ];

  static int get tipCount => _tips.length;

  static String tipAt(int index) => _tips[index % _tips.length];

  static Future<int> getNextIndex() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_prefKey) ?? 0;
  }

  static Future<void> advanceIndex() async {
    final prefs = await SharedPreferences.getInstance();
    final next = ((prefs.getInt(_prefKey) ?? 0) + 1) % _tips.length;
    await prefs.setInt(_prefKey, next);
  }

  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
  }

  static Future<void> showNext(BuildContext context) async {
    final idx = await getNextIndex();
    final tip = _tips[idx];
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('💡 $tip'),
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'Got it',
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
    await advanceIndex();
  }
}
