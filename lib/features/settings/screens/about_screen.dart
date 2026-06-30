import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/tip_service.dart';
import '../../../core/theme/app_colors.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _version = '1.2.0+1';
  static const _repoUrl = 'https://github.com/FrameStudio-cloud/FSChat';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _header(context),
          const SizedBox(height: 24),
          _featureSection(context),
          const SizedBox(height: 16),
          _tipsSection(context, theme, isDark),
          const SizedBox(height: 16),
          _techStackSection(theme, isDark),
          const SizedBox(height: 16),
          _linksSection(context, isDark),
          const SizedBox(height: 16),
          _infoSection(theme),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: AppColors.brand,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.brand.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Center(
            child: Text('FS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                )),
          ),
        ),
        const SizedBox(height: 16),
        Text('FSChat',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text('Version $_version',
            style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        const SizedBox(height: 2),
        GestureDetector(
          onTap: () {
            Clipboard.setData(
                const ClipboardData(text: 'https://framestudio.co.ke'));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('framestudio.co.ke copied'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          child: Text('by Frames Studio',
              style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        ),
      ],
    );
  }

  Widget _featureSection(BuildContext context) {
    final features = [
      ('Real-time messaging', 'Cloud Firestore sync', Icons.chat_rounded),
      ('Voice messages', 'Record and send with one tap', Icons.mic_rounded),
      ('Image sharing', 'Gallery & camera support', Icons.image_rounded),
      (
        'Push notifications',
        'FCM + local fallback',
        Icons.notifications_rounded
      ),
      (
        'Dark mode',
        'Comfortable night-time experience',
        Icons.dark_mode_rounded
      ),
      (
        'Stickers',
        'Built-in & custom sticker packs',
        Icons.emoji_emotions_rounded
      ),
    ];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.star_outline_rounded,
                    size: 20, color: AppColors.brand),
                const SizedBox(width: 8),
                const Text('Features',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            ...features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Icon(f.$3, size: 18, color: Colors.grey[400]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(f.$1, style: const TextStyle(fontSize: 14)),
                            Text(f.$2,
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[500])),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _tipsSection(BuildContext context, ThemeData theme, bool isDark) {
    final tips = List.generate(TipService.tipCount, (i) => TipService.tipAt(i));
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: const Icon(Icons.lightbulb_outline,
              size: 20, color: AppColors.brand),
          title: const Text('Tips',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          subtitle: Text('${tips.length} tips to get the most out of FSChat',
              style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...tips.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• ',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.brand,
                            fontWeight: FontWeight.bold,
                          )),
                      Expanded(
                        child: Text(t, style: const TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Reset tips'),
                onPressed: () {
                  TipService.reset();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Tips reset — they will show again'),
                        behavior: SnackBarBehavior.floating),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _techStackSection(ThemeData theme, bool isDark) {
    final chips = [
      'Flutter 3.41.6',
      'Dart 3.11.4',
      'Firebase',
      'Cloud Firestore',
      'Provider',
      'FCM',
      'Isar'
    ];
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.build_outlined,
                    size: 20, color: AppColors.brand),
                const SizedBox(width: 8),
                const Text('Tech stack',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: chips
                  .map((c) => Chip(
                        label: Text(c, style: const TextStyle(fontSize: 12)),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        side: BorderSide.none,
                        backgroundColor: AppColors.brand.withValues(alpha: 0.1),
                        labelStyle: const TextStyle(color: AppColors.brand),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _linksSection(BuildContext context, bool isDark) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.code_rounded,
                size: 20, color: AppColors.brand),
            title:
                const Text('GitHub repository', style: TextStyle(fontSize: 14)),
            subtitle:
                const Text('View source code', style: TextStyle(fontSize: 12)),
            trailing: Icon(Icons.open_in_new_rounded,
                size: 18, color: Colors.grey[400]),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_repoUrl),
                  behavior: SnackBarBehavior.floating,
                  action: SnackBarAction(
                    label: 'Copy',
                    onPressed: () {
                      // Would copy to clipboard
                    },
                  ),
                ),
              );
            },
          ),
          Divider(
              height: 1, indent: 16, endIndent: 16, color: Colors.grey[200]),
          ListTile(
            leading: const Icon(Icons.new_releases_outlined,
                size: 20, color: AppColors.brand),
            title: const Text("What's new", style: TextStyle(fontSize: 14)),
            subtitle: const Text('View release notes',
                style: TextStyle(fontSize: 12)),
            trailing: Icon(Icons.open_in_new_rounded,
                size: 18, color: Colors.grey[400]),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$_repoUrl/releases/tag/v$_version'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _infoSection(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          _infoRow('Developer', 'Frames Studio', theme),
          _infoRow('Website', 'framestudio.co.ke', theme),
          _infoRow('Platform', 'Android', theme),
          _infoRow('Framework', 'Flutter', theme),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
