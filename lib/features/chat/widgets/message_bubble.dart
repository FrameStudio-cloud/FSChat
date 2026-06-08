import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/message_model.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isOwn;
  final void Function(Offset globalPosition)? onLongPress;
  final VoidCallback? onSwipeReply;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isOwn,
    this.onLongPress,
    this.onSwipeReply,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! > 50) {
          onSwipeReply?.call();
        }
      },
      child: Align(
        alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
        child: GestureDetector(
          onLongPressStart: (details) =>
              onLongPress?.call(details.globalPosition),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 12),
            decoration: BoxDecoration(
              color: isOwn
                  ? (Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF1B5E20)
                      : const Color(0xFFDCF8C6))
                  : (Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[800]
                      : Colors.white),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isOwn ? 16 : 4),
                bottomRight: Radius.circular(isOwn ? 4 : 16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isOwn ? 16 : 4),
                bottomRight: Radius.circular(isOwn ? 4 : 16),
              ),
              child: _buildContent(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (message.replyToText != null && message.replyToText!.isNotEmpty)
          _buildReplyQuote(context),
        switch (message.type) {
          'image' => _ImageContent(message: message, isOwn: isOwn),
          'audio' => _AudioContent(message: message, isOwn: isOwn),
          'sticker' => _StickerContent(message: message, isOwn: isOwn),
          _ => _TextContent(message: message, isOwn: isOwn),
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
            color: isOwn ? Colors.black45 : const Color(0xFF075E54),
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.replyToSenderName != null
                ? 'Reply to ${message.replyToSenderName}'
                : 'Reply',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isOwn
                  ? (Theme.of(context).brightness == Brightness.dark
                      ? Colors.white54
                      : Colors.black54)
                  : const Color(0xFF075E54),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            message.replyToText!,
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
  const _TextContent({required this.message, required this.isOwn});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildText(context),
          const SizedBox(height: 2),
          _MetaRow(message: message, isOwn: isOwn),
        ],
      ),
    );
  }

  Widget _buildText(BuildContext context) {
    final text = message.text;
    final mentionColor = isOwn ? Colors.black87 : const Color(0xFF075E54);
    final defaultColor =
        isOwn && Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : null;

    final regex = RegExp(r'@(\w+)');
    final matches = regex.allMatches(text);
    if (matches.isEmpty) {
      return Text(text, style: TextStyle(fontSize: 16, color: defaultColor));
    }

    final spans = <TextSpan>[];
    int lastEnd = 0;
    for (final m in matches) {
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

    return Text.rich(
      TextSpan(
          style: TextStyle(fontSize: 16, color: defaultColor), children: spans),
    );
  }
}

class _ImageContent extends StatelessWidget {
  final Message message;
  final bool isOwn;
  const _ImageContent({required this.message, required this.isOwn});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showFullscreen(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.network(
            message.mediaUrl ?? '',
            width: double.infinity,
            fit: BoxFit.cover,
            loadingBuilder: (_, child, progress) {
              if (progress == null) return child;
              return Container(
                height: 200,
                color: Colors.grey[200],
                child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2)),
              );
            },
            errorBuilder: (_, __, ___) => Container(
              height: 150,
              color: Colors.grey[200],
              child: const Center(
                  child: Icon(Icons.broken_image, color: Colors.grey)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
            child: _MetaRow(message: message, isOwn: isOwn),
          ),
        ],
      ),
    );
  }

  void _showFullscreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.network(message.mediaUrl ?? '', fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }
}

class _AudioContent extends StatefulWidget {
  final Message message;
  final bool isOwn;
  const _AudioContent({required this.message, required this.isOwn});

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
      child: Row(
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
                  : const Color(0xFF075E54),
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
                        : const Color(0xFF075E54),
                    inactiveTrackColor:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[600]
                            : Colors.grey[300],
                    thumbColor: widget.isOwn
                        ? (Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black87)
                        : const Color(0xFF075E54),
                  ),
                  child: Slider(
                    value: total.inSeconds > 0
                        ? _position.inSeconds
                            .clamp(0, total.inSeconds)
                            .toDouble()
                        : 0,
                    max: total.inSeconds > 0 ? total.inSeconds.toDouble() : 1,
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
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[400]
                              : Colors.grey[600]),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _fmt(total),
                      style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).brightness == Brightness.dark
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
    );
  }
}

class _StickerContent extends StatelessWidget {
  final Message message;
  final bool isOwn;
  const _StickerContent({required this.message, required this.isOwn});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              message.mediaUrl ?? '',
              width: 150,
              height: 150,
              fit: BoxFit.cover,
              loadingBuilder: (_, child, progress) {
                if (progress == null) return child;
                return Container(
                  width: 150,
                  height: 150,
                  color: Colors.grey[100],
                  child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2)),
                );
              },
              errorBuilder: (_, __, ___) => Container(
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
        ],
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
