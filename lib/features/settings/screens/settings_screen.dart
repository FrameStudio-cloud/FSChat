import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/services/database_service.dart';
import '../../../shared/utils/avatar_helper.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/models/user_model.dart';
import 'about_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DatabaseService _db = DatabaseService();
  final ImagePicker _picker = ImagePicker();

  static const _wallpaperColors = [
    '',
    '#F5F5DC',
    '#FFF8E1',
    '#E8F5E9',
    '#E0F7FA',
    '#E3F2FD',
    '#F3E5F5',
    '#FFEBEE',
  ];

  Future<void> _editName(ChatUser user) async {
    final controller = TextEditingController(text: user.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter your name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      await _db.updateUserName(user.uid, name);
    }
  }

  Future<void> _editBio(ChatUser user) async {
    final controller = TextEditingController(text: user.bio);
    final bio = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit bio'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          maxLength: 100,
          decoration: const InputDecoration(
            hintText: "What's on your mind?",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (bio != null) {
      await _db.updateBio(user.uid, bio);
    }
  }

  Future<void> _changePhoto(String uid) async {
    final file = await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80, maxWidth: 512);
    if (file == null) return;
    final url = await _db.uploadProfilePhoto(uid, file.path);
    await _db.updateUserPhoto(uid, url);
  }

  void _showWallpaperPicker() {
    final theme = context.read<ThemeProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Chat Wallpaper',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              Text('DEFAULT',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[500])),
              const SizedBox(height: 8),
              _wallpaperOption(
                ctx,
                label: 'No wallpaper',
                isSelected: theme.wallpaper.isEmpty,
                onTap: () {
                  theme.removeWallpaper();
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 16),
              Text('COLORS',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[500])),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _wallpaperColors
                    .where((c) => c.isNotEmpty)
                    .map((c) => GestureDetector(
                          onTap: () {
                            theme.setWallpaper(c);
                            Navigator.pop(ctx);
                          },
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color:
                                  Color(int.parse(c.replaceFirst('#', '0xff'))),
                              borderRadius: BorderRadius.circular(12),
                              border: theme.wallpaper == c
                                  ? Border.all(color: AppColors.brand, width: 3)
                                  : null,
                            ),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
              Text('CUSTOM IMAGE',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[500])),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.brand.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:
                      const Icon(Icons.image_outlined, color: AppColors.brand),
                ),
                title: const Text('Choose from gallery'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final file = await ImagePicker().pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 80,
                    maxWidth: 1080,
                    maxHeight: 1920,
                  );
                  if (file != null) {
                    await context
                        .read<ThemeProvider>()
                        .setWallpaperImage(file.path);
                  }
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _wallpaperOption(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? const Color(0xFF2D2D2D) : Colors.grey[50],
      borderRadius: BorderRadius.circular(12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[700] : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: isSelected
              ? const Icon(Icons.check, color: AppColors.brand)
              : const Icon(Icons.wallpaper_outlined, color: AppColors.brand),
        ),
        title: Text(label),
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: AppColors.brand, size: 20)
            : null,
        onTap: onTap,
      ),
    );
  }

  Widget _buildCoverProfile(ChatUser? user) {
    if (user == null) return const SizedBox();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [AppColors.brandDark, AppColors.surfaceDark]
              : [AppColors.brand, AppColors.brandLight],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 20),
          child: Column(
            children: [
              GestureDetector(
                onTap: () => _changePhoto(user.uid),
                child: Stack(
                  children: [
                    avatarWidget(
                      radius: 40,
                      photoUrl: user.photoUrl,
                      name: user.name,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.brand,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt,
                            size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => _editName(user),
                child: Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => _editBio(user),
                child: Text(
                  user.bio.isNotEmpty ? user.bio : 'Tap to add bio',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.8),
                    fontStyle:
                        user.bio.isEmpty ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey[500],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _settingsCard(List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: Column(children: children),
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? iconColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tileIconColor = iconColor ?? AppColors.brand;
    return ListTile(
      leading: Icon(icon, color: tileIconColor),
      title: Text(title, style: const TextStyle(fontSize: 15)),
      subtitle: subtitle != null
          ? Text(subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]))
          : null,
      trailing: trailing ?? Icon(Icons.chevron_right, color: Colors.grey[400]),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = context.watch<ThemeProvider>();
    final isDark = theme.themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _buildCoverProfile(auth.chatUser),
          _sectionHeader('APPEARANCE'),
          _settingsCard([
            SwitchListTile(
              secondary:
                  const Icon(Icons.dark_mode_rounded, color: AppColors.brand),
              title: const Text('Dark mode'),
              value: isDark,
              onChanged: (v) => theme.setDarkMode(v),
            ),
            _settingsTile(
              icon: Icons.wallpaper_rounded,
              title: 'Wallpaper',
              subtitle: theme.wallpaper.isEmpty ? 'Default' : 'Custom',
              onTap: _showWallpaperPicker,
            ),
          ]),
          _sectionHeader('NOTIFICATIONS'),
          _settingsCard([
            _settingsTile(
              icon: Icons.volume_up_outlined,
              title: 'Message sound',
              subtitle: 'Coming soon',
              onTap: () => _comingSoon(),
            ),
            _buildDivider(),
            _settingsTile(
              icon: Icons.vibration_outlined,
              title: 'Vibrate',
              subtitle: 'Coming soon',
              onTap: () => _comingSoon(),
            ),
            _buildDivider(),
            _settingsTile(
              icon: Icons.notifications_outlined,
              title: 'Message preview',
              subtitle: 'Coming soon',
              onTap: () => _comingSoon(),
            ),
          ]),
          _sectionHeader('CHATS'),
          _settingsCard([
            _settingsTile(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'Bubble style',
              subtitle: 'Coming soon',
              onTap: () => _comingSoon(),
            ),
            _buildDivider(),
            _settingsTile(
              icon: Icons.text_fields_rounded,
              title: 'Font size',
              subtitle: 'Coming soon',
              onTap: () => _comingSoon(),
            ),
          ]),
          _sectionHeader('PRIVACY'),
          _settingsCard([
            _settingsTile(
              icon: Icons.done_all_rounded,
              title: 'Read receipts',
              subtitle: 'Coming soon',
              onTap: () => _comingSoon(),
            ),
            _buildDivider(),
            _settingsTile(
              icon: Icons.block_rounded,
              title: 'Blocked users',
              subtitle: 'Coming soon',
              onTap: () => _comingSoon(),
            ),
          ]),
          _sectionHeader('ACCOUNT'),
          _settingsCard([
            _settingsTile(
              icon: Icons.info_outline_rounded,
              title: 'About',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AboutScreen()),
              ),
            ),
            _buildDivider(),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.red),
              title:
                  const Text('Sign out', style: TextStyle(color: Colors.red)),
              trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
              onTap: _confirmSignOut,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            ),
          ]),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, indent: 56, color: Colors.grey[200]);
  }

  void _comingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _confirmSignOut() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
              context.read<AuthProvider>().signOut();
            },
            child: const Text('Sign out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
