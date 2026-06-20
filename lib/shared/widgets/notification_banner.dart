import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/avatar_helper.dart';

class NotificationBanner {
  static OverlayEntry? _currentEntry;
  static Timer? _dismissTimer;

  static void show(
    BuildContext context, {
    required String title,
    required String body,
    String? chatId,
    String? senderId,
    VoidCallback? onTap,
  }) {
    _dismissCurrent();

    _currentEntry = OverlayEntry(
      builder: (_) => _NotificationBannerOverlay(
        title: title,
        body: body,
        onTap: onTap ??
            (chatId != null && senderId != null
                ? () => _navigateToChat(context, chatId, senderId)
                : null),
        onDismiss: _clearEntry,
      ),
    );

    Overlay.of(context).insert(_currentEntry!);
  }

  static void _dismissCurrent() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _currentEntry?.remove();
    _currentEntry = null;
  }

  static void _clearEntry() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _currentEntry?.remove();
    _currentEntry = null;
  }

  static void _navigateToChat(
      BuildContext context, String chatId, String senderId) {
    final nav = Navigator.of(context);
    nav.pushNamed('/chat', arguments: {
      'chatId': chatId,
      // otherUser will be resolved by ChatScreen.didChangeDependencies
      // from the chatId if not provided — but we attempt a minimal lookup
    });
  }
}

class _NotificationBannerOverlay extends StatefulWidget {
  final String title;
  final String body;
  final VoidCallback? onTap;
  final VoidCallback onDismiss;

  const _NotificationBannerOverlay({
    required this.title,
    required this.body,
    this.onTap,
    required this.onDismiss,
  });

  @override
  State<_NotificationBannerOverlay> createState() =>
      _NotificationBannerOverlayState();
}

class _NotificationBannerOverlayState extends State<_NotificationBannerOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward();

    _dismissTimer = Timer(const Duration(seconds: 4), _dismiss);
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topPadding = MediaQuery.of(context).padding.top;

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          bottom: false,
          child: GestureDetector(
            onTap: () {
              widget.onTap?.call();
              _dismiss();
            },
            child: Container(
              margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  left: 8,
                  top: 8,
                  bottom: 8,
                  right: 4,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundImage: getAvatar(null, widget.title),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: theme.colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.body,
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.65),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded,
                          size: 20,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.4)),
                      onPressed: _dismiss,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
