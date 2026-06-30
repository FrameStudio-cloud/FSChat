import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/project.dart';

class ProjectDetailScreen extends StatelessWidget {
  final Project project;
  const ProjectDetailScreen({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(project.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  project.color.withValues(alpha: 0.15),
                  project.color.withValues(alpha: 0.05)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: project.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(project.icon, color: project.color, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(project.title,
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(project.subtitle,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('About',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(project.description,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5)),
          if (project.features.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Features',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...project.features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle_rounded,
                          size: 18, color: Colors.green.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(f, style: theme.textTheme.bodyMedium)),
                    ],
                  ),
                )),
          ],
          if (project.installationSteps.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Installation',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...project.installationSteps.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: project.color.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Text('${e.key + 1}',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: project.color)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                          child:
                              Text(e.value, style: theme.textTheme.bodyMedium)),
                    ],
                  ),
                )),
          ],
          if (project.webUrl != null ||
              project.githubUrl != null ||
              project.playStoreUrl != null) ...[
            const SizedBox(height: 24),
            Text('Links',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            if (project.webUrl != null)
              _LinkButton(
                icon: Icons.language_rounded,
                label: 'Open Web App',
                color: project.color,
                onTap: () => _openUrl(context, project.webUrl!),
              ),
            if (project.githubUrl != null)
              _LinkButton(
                icon: Icons.code_rounded,
                label: 'GitHub Releases',
                color: Colors.grey.shade700,
                onTap: () => _openUrl(context, project.githubUrl!),
              ),
            if (project.playStoreUrl != null)
              _LinkButton(
                icon: Icons.shop_rounded,
                label: 'Play Store',
                color: Colors.green.shade600,
                onTap: () => _openUrl(context, project.playStoreUrl!),
              ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open link')),
      );
    }
  }
}

class _LinkButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _LinkButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(label,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w500)),
                ),
                Icon(Icons.open_in_new_rounded, size: 18, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
