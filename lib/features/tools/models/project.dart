import 'package:flutter/material.dart';

class Project {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;
  final String? webUrl;
  final String? githubUrl;
  final String? playStoreUrl;
  final List<String> installationSteps;
  final List<String> features;

  const Project({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
    this.webUrl,
    this.githubUrl,
    this.playStoreUrl,
    this.installationSteps = const [],
    this.features = const [],
  });
}

final myProjects = [
  const Project(
    id: 'bible_app',
    title: 'Bible App',
    subtitle: 'Read, study & reflect',
    description:
        'A full-featured Bible study app with daily verses, book/chapter navigation, search, bookmarks, and highlighting. Built with Flutter.',
    icon: Icons.menu_book_rounded,
    color: Color(0xFF5C6BC0),
    webUrl: 'https://bible.fschat.com',
    githubUrl:
        'https://github.com/FrameStudio-cloud/shibani-bible/releases/tag/v1.0.0',
    installationSteps: [
      'Download the latest APK from GitHub Releases.',
      'Open the downloaded file on your Android device.',
      'Tap "Install" (enable "Install from unknown sources" if prompted).',
      'Open the app and start reading.',
    ],
    features: [
      'Offline Bible reading',
      'Daily verse notifications',
      'Bookmark & highlight verses',
      'Search by book, chapter, or keyword',
      'Dark mode support',
    ],
  ),
  const Project(
    id: 'keel',
    title: 'Keel',
    subtitle: 'Multi-tenant shop dashboard',
    description:
        'A mobile-friendly dashboard for small retail businesses — inventory, sales logging, social media scheduling, website management, WhatsApp/Telegram bots, and business settings. Built with React 19, Vite, Supabase.',
    icon: Icons.store_rounded,
    color: Color(0xFFEF6C00),
    webUrl: 'https://keel.framestudio.co.ke',
    githubUrl: 'https://github.com/FrameStudio-cloud/keel',
    installationSteps: [
      'Open keel.framestudio.co.ke in any browser.',
      'Create a shop during onboarding.',
      'Start adding products, logging sales, and managing your store.',
      'No installation needed — works on any device.',
    ],
    features: [
      'Dashboard KPIs — daily sales, top products, low stock alerts',
      'Inventory management with stock adjust & history',
      'Sales logging with auto-stock deduction & receipts',
      'Social media post scheduler (Instagram, TikTok)',
      'Website catalogue, banners, business info & gallery',
      'WhatsApp & Telegram bot management',
      'Multi-shop support with one account',
      'Dark mode & full data export',
    ],
  ),
  const Project(
    id: 'call_app',
    title: 'Web Calling App',
    subtitle: 'Browser-based voice & video',
    description:
        'A WebRTC-based calling app that works entirely in the browser. No download required — just share the link and call.',
    icon: Icons.video_call_rounded,
    color: Color(0xFF26A69A),
    webUrl: 'https://call.fschat.com',
    githubUrl: 'https://github.com/yourusername/call-app/releases',
    installationSteps: [
      'Open the web URL in any modern browser (Chrome, Firefox, Edge).',
      'Allow microphone and camera permissions when prompted.',
      'Share the room link with the person you want to call.',
      'No installation needed — works instantly in the browser.',
    ],
    features: [
      'Peer-to-peer voice & video calls',
      'No account required',
      'End-to-end encrypted',
      'Works on desktop and mobile browsers',
      'Screen sharing support',
    ],
  ),
];
