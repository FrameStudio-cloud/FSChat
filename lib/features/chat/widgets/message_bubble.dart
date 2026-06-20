import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../models/message_model.dart';
import 'reaction_bar.dart';
import 'reaction_display.dart';
import '../../../shared/utils/gallery_saver.dart';

class MessageBubble extends StatefulWidget {
  final Message message;
  final bool isOwn;
  final void Function(Offset globalPosition)? onLongPress;
  final VoidCallback? onSwipeReply;
  final bool isSelecting;
  final bool isSelected;
  final VoidCallback? onTap;
  final Future<void> Function(String emoji)? onReact;
  final String currentUserId;
  final String searchQuery;
  final bool isFailed;
  final VoidCallback? onRetry;
  final bool isGroup;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isOwn,
    this.onLongPress,
    this.onSwipeReply,
    this.isSelecting = false,
    this.isSelected = false,
    this.onTap,
    this.onReact,
    this.currentUserId = '',
    this.searchQuery = '',
    this.isFailed = false,
    this.onRetry,
    this.isGroup = false,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  OverlayEntry? _reactionOverlay;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _reactionOverlay?.remove();
    _reactionOverlay = null;
  }

  void _showReactionBar(BuildContext context, Offset globalPosition) {
    _removeOverlay();

    final overlay = Overlay.of(context);
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final bubblePos = box.localToGlobal(Offset.zero);

    _reactionOverlay = OverlayEntry(
      builder: (ctx) {
        return GestureDetector(
          onTap: _removeOverlay,
          behavior: HitTestBehavior.translucent,
          child: Stack(
            children: [
              Positioned(
                left: bubblePos.dx,
                top: (bubblePos.dy - 56).clamp(8.0, double.infinity),
                child: Material(
                  color: Colors.transparent,
                  child: ReactionBar(
                    currentEmoji:
                        widget.message.reactions[widget.currentUserId] ?? '',
                    onTap: (emoji) async {
                      await widget.onReact?.call(emoji);
                      _removeOverlay();
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    overlay.insert(_reactionOverlay!);
  }

  @override
  Widget build(BuildContext context) {
    Widget bubbleContent = _buildContent(context);

    if (widget.isFailed) {
      bubbleContent = Stack(
        children: [
          bubbleContent,
          Positioned(
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: widget.onRetry,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning_rounded,
                    color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bubbleStyle = Theme.of(context).extension<BubbleStyle>()!;
    final ownRadius = bubbleStyle.ownRadius;
    final otherRadius = bubbleStyle.otherRadius;

    final bubble = Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.7,
      ),
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: widget.isOwn ? ownRadius : otherRadius,
        gradient: widget.isOwn
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [AppColors.ownBubbleDarkStart, AppColors.ownBubbleDarkEnd]
                    : [
                        AppColors.ownBubbleLightStart,
                        AppColors.ownBubbleLightEnd
                      ],
              )
            : null,
        color: widget.isOwn
            ? null
            : (isDark ? AppColors.otherBubbleDark : AppColors.otherBubbleLight),
        boxShadow: [
          widget.isOwn ? bubbleStyle.ownShadow : bubbleStyle.otherShadow,
        ],
      ),
      child: ClipRRect(
        borderRadius: widget.isOwn ? ownRadius : otherRadius,
        child: Stack(
          children: [
            bubbleContent,
            if (widget.isOwn)
              Positioned(
                right: -1,
                bottom: 0,
                child: CustomPaint(
                  size: const Size(10, 10),
                  painter: _BubbleTailPainter(
                    color: isDark
                        ? AppColors.ownBubbleDarkEnd
                        : AppColors.ownBubbleLightEnd,
                    isOwn: true,
                  ),
                ),
              )
            else
              Positioned(
                left: -1,
                bottom: 0,
                child: CustomPaint(
                  size: const Size(10, 10),
                  painter: _BubbleTailPainter(
                    color: isDark
                        ? AppColors.otherBubbleDark
                        : AppColors.otherBubbleLight,
                    isOwn: false,
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    return Align(
      alignment: widget.isOwn ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.isSelecting && !widget.isOwn)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: _SelectionCheck(
                isSelected: widget.isSelected,
                onTap: widget.onTap,
              ),
            ),
          Flexible(
            child: GestureDetector(
              onHorizontalDragEnd: widget.isSelecting
                  ? null
                  : (details) {
                      if (details.primaryVelocity != null &&
                          details.primaryVelocity! > 50) {
                        widget.onSwipeReply?.call();
                      }
                    },
              onTap: widget.isFailed
                  ? widget.onRetry
                  : (widget.isSelecting ? widget.onTap : null),
              onLongPressStart: widget.isSelecting
                  ? null
                  : (details) {
                      _showReactionBar(context, details.globalPosition);
                      widget.onLongPress?.call(details.globalPosition);
                    },
              child: bubble,
            ),
          ),
          if (widget.isSelecting && widget.isOwn)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: _SelectionCheck(
                isSelected: widget.isSelected,
                onTap: widget.onTap,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.message.replyToText != null &&
            widget.message.replyToText!.isNotEmpty)
          _buildReplyQuote(context),
        switch (widget.message.type) {
          'image' || 'multi_image' => _ImageContent(
              message: widget.message,
              isOwn: widget.isOwn,
              currentUserId: widget.currentUserId,
              isGroup: widget.isGroup),
          'audio' => _AudioContent(
              message: widget.message,
              isOwn: widget.isOwn,
              currentUserId: widget.currentUserId,
              isGroup: widget.isGroup),
          'sticker' => _StickerContent(
              message: widget.message,
              isOwn: widget.isOwn,
              currentUserId: widget.currentUserId,
              isGroup: widget.isGroup),
          'file' => _FileContent(
              message: widget.message,
              isOwn: widget.isOwn,
              currentUserId: widget.currentUserId,
              isGroup: widget.isGroup),
          _ => _TextContent(
              message: widget.message,
              isOwn: widget.isOwn,
              currentUserId: widget.currentUserId,
              searchQuery: widget.searchQuery,
              isGroup: widget.isGroup),
        },
      ],
    );
  }

  Widget _buildReplyQuote(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: widget.isOwn ? Colors.black45 : const Color(0xFFE65100),
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.message.replyToSenderName != null
                ? 'Reply to ${widget.message.replyToSenderName}'
                : 'Reply',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: widget.isOwn
                  ? (Theme.of(context).brightness == Brightness.dark
                      ? Colors.white54
                      : Colors.black54)
                  : const Color(0xFFE65100),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            widget.message.replyToText!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[400]
                  : Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _TextContent extends StatelessWidget {
  final Message message;
  final bool isOwn;
  final String currentUserId;
  final String searchQuery;
  final bool isGroup;
  const _TextContent({
    required this.message,
    required this.isOwn,
    required this.currentUserId,
    this.searchQuery = '',
    this.isGroup = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isGroup && !isOwn && message.senderName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                message.senderName,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFE65100),
                ),
              ),
            ),
          if (message.isForwarded)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.reply_rounded,
                      size: 12,
                      color: isOwn
                          ? (Theme.of(context).brightness == Brightness.dark
                              ? Colors.white54
                              : Colors.black45)
                          : Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Forwarded',
                    style: TextStyle(
                      fontSize: 11,
                      color: isOwn
                          ? (Theme.of(context).brightness == Brightness.dark
                              ? Colors.white54
                              : Colors.black45)
                          : Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          _buildText(context),
          const SizedBox(height: 2),
          _MetaRow(message: message, isOwn: isOwn),
          ReactionDisplay(
            reactions: message.reactions,
            currentUserId: currentUserId,
          ),
        ],
      ),
    );
  }

  Widget _buildText(BuildContext context) {
    final text = message.text;
    final mentionColor = isOwn ? Colors.black87 : const Color(0xFFE65100);
    final defaultColor =
        isOwn && Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : null;
    final editedColor = isOwn
        ? (Theme.of(context).brightness == Brightness.dark
            ? Colors.white38
            : Colors.black45)
        : Colors.grey;

    List<TextSpan> _buildSpans() {
      final spans = <TextSpan>[];
      final mentionRegex = RegExp(r'@(\w+)');

      if (searchQuery.isNotEmpty) {
        final highlightColor =
            isOwn ? const Color(0xFFFFF176) : const Color(0xFFFFF176);
        int i = 0;
        while (i < text.length) {
          final queryIdx = text.toLowerCase().indexOf(searchQuery, i);
          if (queryIdx == -1) {
            spans.add(TextSpan(text: text.substring(i)));
            break;
          }
          if (queryIdx > i) {
            spans.add(TextSpan(text: text.substring(i, queryIdx)));
          }
          spans.add(TextSpan(
            text: text.substring(queryIdx, queryIdx + searchQuery.length),
            style: TextStyle(
              fontSize: 16,
              backgroundColor: highlightColor,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ));
          i = queryIdx + searchQuery.length;
        }
        return spans;
      }

      final mentionMatches = mentionRegex.allMatches(text);
      if (mentionMatches.isEmpty) {
        spans.add(TextSpan(text: text));
        return spans;
      }

      int lastEnd = 0;
      for (final m in mentionMatches) {
        if (m.start > lastEnd) {
          spans.add(TextSpan(text: text.substring(lastEnd, m.start)));
        }
        spans.add(TextSpan(
          text: m.group(0),
          style: TextStyle(
            fontSize: 16,
            color: mentionColor,
            fontWeight: FontWeight.w600,
          ),
        ));
        lastEnd = m.end;
      }
      if (lastEnd < text.length) {
        spans.add(TextSpan(text: text.substring(lastEnd)));
      }
      return spans;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text.rich(
            TextSpan(
                style: TextStyle(fontSize: 16, color: defaultColor),
                children: _buildSpans()),
          ),
        ),
        if (message.isEdited)
          Text(' edited', style: TextStyle(fontSize: 11, color: editedColor)),
      ],
    );
  }
}

class _ImageContent extends StatelessWidget {
  final Message message;
  final bool isOwn;
  final String currentUserId;
  final bool isGroup;
  const _ImageContent({
    required this.message,
    required this.isOwn,
    required this.currentUserId,
    this.isGroup = false,
  });

  @override
  Widget build(BuildContext context) {
    if (message.type == 'multi_image' &&
        message.mediaUrls != null &&
        message.mediaUrls!.isNotEmpty) {
      return _MultiImageGrid(
        urls: message.mediaUrls!,
        isOwn: isOwn,
        message: message,
        currentUserId: currentUserId,
      );
    }
    return GestureDetector(
      onTap: () => _showFullscreen(context, message.mediaUrl ?? ''),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isGroup && !isOwn && message.senderName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
              child: Text(
                message.senderName,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFE65100),
                ),
              ),
            ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: CachedNetworkImage(
              imageUrl: message.mediaUrl ?? '',
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                height: 200,
                color: Colors.grey[200],
                child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              errorWidget: (_, __, ___) => Container(
                height: 150,
                color: Colors.grey[200],
                child: const Center(
                    child: Icon(Icons.broken_image, color: Colors.grey)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MetaRow(message: message, isOwn: isOwn),
                ReactionDisplay(
                  reactions: message.reactions,
                  currentUserId: currentUserId,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFullscreen(BuildContext context, String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.download_rounded),
                tooltip: 'Save to gallery',
                onPressed: () async {
                  final ok = await saveImageToGallery(url);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text(ok ? 'Saved to gallery' : 'Failed to save'),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          body: Center(
            child: InteractiveViewer(
              child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }
}

class _MultiImageGrid extends StatelessWidget {
  final List<String> urls;
  final bool isOwn;
  final Message message;
  final String currentUserId;
  const _MultiImageGrid({
    required this.urls,
    required this.isOwn,
    required this.message,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final maxVisible = 4;
    final visible = urls.take(maxVisible).toList();
    final remaining = urls.length - maxVisible;

    return GestureDetector(
      onTap: () => _showFullscreen(context, urls.first),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
              children: List.generate(visible.length, (i) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: visible[i],
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      ),
                    ),
                    if (i == maxVisible - 1 && remaining > 0)
                      Container(
                        color: Colors.black54,
                        child: Center(
                          child: Text(
                            '+$remaining',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              }),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MetaRow(message: message, isOwn: isOwn),
                ReactionDisplay(
                  reactions: message.reactions,
                  currentUserId: currentUserId,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFullscreen(BuildContext context, String url) {
    final initialIndex = urls.indexOf(url);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ImageGallery(
          urls: urls,
          initialIndex: initialIndex >= 0 ? initialIndex : 0,
        ),
      ),
    );
  }
}

class _ImageGallery extends StatefulWidget {
  final List<String> urls;
  final int initialIndex;
  const _ImageGallery({
    required this.urls,
    required this.initialIndex,
  });

  @override
  State<_ImageGallery> createState() => _ImageGalleryState();
}

class _ImageGalleryState extends State<_ImageGallery> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('${_currentIndex + 1} / ${widget.urls.length}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Save to gallery',
            onPressed: () async {
              final ok = await saveImageToGallery(widget.urls[_currentIndex]);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok ? 'Saved to gallery' : 'Failed to save'),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (i) => setState(() => _currentIndex = i),
        children: widget.urls.map((url) {
          return Center(
            child: InteractiveViewer(
              child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _AudioContent extends StatefulWidget {
  final Message message;
  final bool isOwn;
  final String currentUserId;
  final bool isGroup;
  const _AudioContent({
    required this.message,
    required this.isOwn,
    required this.currentUserId,
    this.isGroup = false,
  });

  @override
  State<_AudioContent> createState() => _AudioContentState();
}

class _AudioContentState extends State<_AudioContent> {
  final AudioPlayer _player = AudioPlayer();
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      await _player.setUrl(widget.message.mediaUrl ?? '');
      _player.positionStream.listen((p) {
        if (mounted) setState(() => _position = p);
      });
      _player.durationStream.listen((d) {
        if (mounted) {
          setState(() => _duration = d ?? Duration.zero);
          _isLoading = false;
        }
      });
      _player.playerStateStream.listen((state) {
        if (mounted) setState(() => _isPlaying = state.playing);
      });
      await _player.load();
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (_isPlaying) {
      _player.pause();
    } else {
      _player.play();
    }
  }

  String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.message.duration != null
        ? Duration(seconds: widget.message.duration!)
        : _duration;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.isGroup &&
              !widget.isOwn &&
              widget.message.senderName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 2),
              child: Text(
                widget.message.senderName,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFE65100),
                ),
              ),
            ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  _isLoading
                      ? Icons.hourglass_top
                      : _isPlaying
                          ? Icons.pause_circle_filled_rounded
                          : Icons.play_circle_fill_rounded,
                  color: widget.isOwn
                      ? (Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black87)
                      : const Color(0xFFE65100),
                  size: 32,
                ),
                onPressed: _isLoading ? null : _togglePlay,
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 100,
                    child: SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 3,
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 5),
                        overlayShape:
                            const RoundSliderOverlayShape(overlayRadius: 12),
                        activeTrackColor: widget.isOwn
                            ? (Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black87)
                            : const Color(0xFFE65100),
                        inactiveTrackColor:
                            Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[600]
                                : Colors.grey[300],
                        thumbColor: widget.isOwn
                            ? (Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black87)
                            : const Color(0xFFE65100),
                      ),
                      child: Slider(
                        value: total.inSeconds > 0
                            ? _position.inSeconds
                                .clamp(0, total.inSeconds)
                                .toDouble()
                            : 0,
                        max: total.inSeconds > 0
                            ? total.inSeconds.toDouble()
                            : 1,
                        onChanged: (v) =>
                            _player.seek(Duration(seconds: v.toInt())),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Row(
                      children: [
                        Text(
                          _fmt(_position),
                          style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.grey[400]
                                  : Colors.grey[600]),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _fmt(total),
                          style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.grey[500]
                                  : Colors.grey[400]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  if (widget.isOwn) ...[
                    const SizedBox(height: 4),
                    _SeenIcon(message: widget.message),
                  ],
                ],
              ),
            ],
          ),
          ReactionDisplay(
            reactions: widget.message.reactions,
            currentUserId: widget.currentUserId,
          ),
        ],
      ),
    );
  }
}

class _StickerContent extends StatelessWidget {
  final Message message;
  final bool isOwn;
  final String currentUserId;
  final bool isGroup;
  const _StickerContent({
    required this.message,
    required this.isOwn,
    required this.currentUserId,
    this.isGroup = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isGroup && !isOwn && message.senderName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                message.senderName,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFE65100),
                ),
              ),
            ),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: message.mediaUrl ?? '',
              width: 150,
              height: 150,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                width: 150,
                height: 150,
                color: Colors.grey[100],
                child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              errorWidget: (_, __, ___) => Container(
                width: 150,
                height: 150,
                color: Colors.grey[100],
                child: const Center(
                    child: Text('😕', style: TextStyle(fontSize: 40))),
              ),
            ),
          ),
          const SizedBox(height: 4),
          _MetaRow(message: message, isOwn: isOwn),
          ReactionDisplay(
            reactions: message.reactions,
            currentUserId: currentUserId,
          ),
        ],
      ),
    );
  }
}

class _FileContent extends StatelessWidget {
  final Message message;
  final bool isOwn;
  final String currentUserId;
  final bool isGroup;
  const _FileContent({
    required this.message,
    required this.isOwn,
    required this.currentUserId,
    this.isGroup = false,
  });

  void _openFile(BuildContext context) async {
    final url = message.mediaUrl;
    if (url == null || url.isEmpty) return;
    try {
      final dir = await getTemporaryDirectory();
      final localPath = '${dir.path}/${message.fileName ?? 'file'}';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final file = File(localPath);
        await file.writeAsBytes(response.bodyBytes);
        await OpenFile.open(localPath);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to download file')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  String _formatFileSize(int? bytes) {
    if (bytes == null) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  IconData _fileIcon(String? name) {
    if (name == null) return Icons.insert_drive_file_rounded;
    final ext = name.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'doc':
      case 'docx':
        return Icons.description_rounded;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart_rounded;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow_rounded;
      case 'zip':
      case 'rar':
        return Icons.folder_zip_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openFile(context),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isGroup && !isOwn && message.senderName.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  message.senderName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.brand,
                  ),
                ),
              ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_fileIcon(message.fileName),
                    size: 36, color: const Color(0xFFE65100)),
                const SizedBox(width: 10),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.fileName ?? 'File',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (message.fileSize != null)
                        Text(
                          _formatFileSize(message.fileSize),
                          style:
                              TextStyle(fontSize: 11, color: Colors.grey[500]),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            _MetaRow(message: message, isOwn: isOwn),
            ReactionDisplay(
              reactions: message.reactions,
              currentUserId: currentUserId,
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final Message message;
  final bool isOwn;
  const _MetaRow({required this.message, required this.isOwn});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatTime(message.timestamp),
          style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[400]
                  : Colors.grey[600]),
        ),
        if (isOwn) ...[
          const SizedBox(width: 4),
          _SeenIcon(message: message),
        ],
      ],
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _SelectionCheck extends StatelessWidget {
  final bool isSelected;
  final VoidCallback? onTap;

  const _SelectionCheck({
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected ? const Color(0xFFE65100) : Colors.transparent,
            border: Border.all(
              color: isSelected ? const Color(0xFFE65100) : Colors.grey,
              width: 2,
            ),
          ),
          child: isSelected
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : null,
        ),
      ),
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  final Color color;
  final bool isOwn;

  _BubbleTailPainter({required this.color, required this.isOwn});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    if (isOwn) {
      path.moveTo(size.width, 0);
      path.lineTo(size.width, size.height);
      path.lineTo(size.width - 8, size.height);
      path.close();
    } else {
      path.moveTo(0, 0);
      path.lineTo(0, size.height);
      path.lineTo(8, size.height);
      path.close();
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BubbleTailPainter old) => old.color != color;
}

class _SeenIcon extends StatelessWidget {
  final Message message;
  const _SeenIcon({required this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Icon(
      message.seenBy.length > 1 ? Icons.done_all : Icons.done,
      size: 16,
      color: message.seenBy.length > 1
          ? Colors.blue[400]
          : (isDark ? Colors.grey[400] : Colors.grey[600]),
    );
  }
}
