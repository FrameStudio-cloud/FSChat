import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _header(context),
          const SizedBox(height: 24),
          _section(
              'How it works',
              '1. Create an account with your email and password\n'
                  '2. Tap the + button to start a new conversation\n'
                  '3. Select a contact from the list\n'
                  '4. Send text messages, voice notes, or images\n'
                  '5. See when your messages are delivered and read',
              Icons.touch_app_outlined,
              theme),
          const SizedBox(height: 16),
          _section(
              'Features',
              '• Real-time messaging via Cloud Firestore\n'
                  '• Voice messages — tap mic to record, tap to send\n'
                  '• Image sharing from your gallery\n'
                  '• Typing indicators when someone is composing\n'
                  '• Online/offline presence with green dot\n'
                  '• Seen status (single/double check)\n'
                  '• Dark mode toggle\n'
                  '• Pin chats to the top\n'
                  '• Swipe to reply with quoted message preview\n'
                  '• @mentions — type @ to tag someone\n'
                  '• Context menus — long-press to Copy, Delete, or Pin\n'
                  '• Adaptive input box — expands up to 5 lines\n'
                  '• Push notifications (in-app + local fallback)',
              Icons.star_outline,
              theme),
          const SizedBox(height: 16),
          _section(
              'About FSChat',
              'FSChat (Frames Studio Chat) is a real-time messaging '
                  'app built with Flutter and Firebase. It demonstrates '
                  'modern mobile development practices including real-time '
                  'data sync, user authentication, and rich media messaging.',
              Icons.info_outline,
              theme),
          const SizedBox(height: 16),
          _infoRow('Version', '1.0.0', theme),
          _infoRow('Developer', 'Frames Studio', theme),
          _infoRow(
              'Built with', 'Flutter 3.41.6 · Firebase · OneSignal', theme),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: const Color(0xFF075E54),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Center(
            child: Text('FS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                )),
          ),
        ),
        const SizedBox(height: 12),
        Text('FSChat',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text('by Frames Studio',
            style: TextStyle(color: Colors.grey[500], fontSize: 13)),
      ],
    );
  }

  Widget _section(String title, String body, IconData icon, ThemeData theme) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: const Color(0xFF075E54)),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    )),
              ],
            ),
            const SizedBox(height: 10),
            Text(body,
                style: TextStyle(
                  fontSize: 13.5,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                  height: 1.5,
                )),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              )),
          Text(value, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}
