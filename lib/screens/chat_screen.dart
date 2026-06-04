import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import '../widgets/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final DatabaseService _db = DatabaseService();
  final ImagePicker _imagePicker = ImagePicker();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final Uuid _uuid = Uuid();

  late String chatId;
  late String otherUid;
  ChatUser? _otherUser;
  Timer? _typingTimer;
  bool _isRecording = false;
  bool _recordingReady = false;
  bool _isUploading = false;
  final Stopwatch _recordStopwatch = Stopwatch();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    chatId = args['chatId'] as String;
    final u = args['otherUser'] as ChatUser;
    otherUid = u.uid;
    _otherUser = u;
  }

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _db.setTyping(chatId, otherUid, false);
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _textController.text.trim().isNotEmpty;
    final uid = context.read<AuthProvider>().user!.uid;
    _db.setTyping(chatId, uid, hasText);

    _typingTimer?.cancel();
    if (hasText) {
      _typingTimer = Timer(const Duration(seconds: 2), () {
        _db.setTyping(chatId, uid, false);
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _typingTimer?.cancel();
    final uid = context.read<AuthProvider>().user!.uid;
    await _db.setTyping(chatId, uid, false);
    try {
      await _db.sendMessage(chatId: chatId, senderId: uid, text: text);
      _textController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e')),
        );
      }
    }
  }

  Future<void> _deleteMessage(String msgId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete message'),
        content: const Text('Delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _db.deleteMessage(chatId, msgId);
    }
  }

  void _showAttachmentSheet() {
    _hideKeyboard();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Attach',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _attachOption(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    color: Colors.purple,
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                  _attachOption(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _attachOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final file = await _imagePicker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1280,
    );
    if (file == null) return;

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.file(
                File(file.path),
                width: double.infinity,
                height: 300,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF075E54),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Send'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isUploading = true);
    try {
      final uid = context.read<AuthProvider>().user!.uid;
      final msgId = _uuid.v4();
      final url = await _db.uploadImage(chatId, msgId, file.path);
      await _db.sendMessage(
        chatId: chatId,
        senderId: uid,
        text: '',
        type: 'image',
        mediaUrl: url,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send image: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _toggleRecording() {
    if (_isRecording) {
      _stopRecordingAndSend();
    } else {
      _startRecording();
    }
  }

  void _hideKeyboard() {
    FocusScope.of(context).unfocus();
  }

  Future<void> _startRecording() async {
    _hideKeyboard();
    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) return;

    final dir = Directory.systemTemp;
    final path =
        '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

    setState(() => _isRecording = true);

    await _audioRecorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 64000,
      ),
      path: path,
    );

    _recordingReady = true;

    setState(() {
      _recordStopwatch.reset();
      _recordStopwatch.start();
    });
  }

  Future<void> _stopRecordingAndSend() async {
    if (!_isRecording) return;
    await Future.doWhile(() => !_recordingReady);

    _recordStopwatch.stop();
    final duration = _recordStopwatch.elapsed.inSeconds;

    String? path;
    try {
      path = await _audioRecorder.stop();
    } catch (_) {}

    _recordingReady = false;
    setState(() => _isRecording = false);

    if (path == null || duration < 1) return;

    if (!mounted) return;
    final uid = context.read<AuthProvider>().user!.uid;

    setState(() => _isUploading = true);
    try {
      final msgId = _uuid.v4();
      final url = await _db.uploadAudio(chatId, msgId, path);
      await _db.sendMessage(
        chatId: chatId,
        senderId: uid,
        text: '',
        type: 'audio',
        mediaUrl: url,
        duration: duration,
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = context.watch<AuthProvider>().user!.uid;

    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder(
          stream: _db.userStream(otherUid),
          builder: (context, snap) {
            final liveUser = snap.data ?? _otherUser;
            if (liveUser != null) _otherUser = liveUser;
            return Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: liveUser?.photoUrl.isNotEmpty == true
                      ? NetworkImage(liveUser!.photoUrl)
                      : null,
                  child: liveUser?.photoUrl.isEmpty == true
                      ? Text(liveUser!.name[0].toUpperCase(),
                          style: const TextStyle(fontSize: 14))
                      : null,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(liveUser?.name ?? '',
                        style: const TextStyle(fontSize: 16)),
                    StreamBuilder(
                      stream: _db.typingStream(chatId, otherUid),
                      builder: (context, typingSnap) {
                        final isTyping = typingSnap.data ?? false;
                        if (isTyping) {
                          return const Text(
                            'typing...',
                            style: TextStyle(
                                fontSize: 12, color: Colors.greenAccent),
                          );
                        }
                        final isDark =
                            Theme.of(context).brightness == Brightness.dark;
                        return Text(
                          liveUser?.online == true ? 'online' : 'offline',
                          style: TextStyle(
                            fontSize: 12,
                            color: liveUser?.online == true
                                ? Colors.green[300]
                                : (isDark ? Colors.grey[400] : Colors.grey),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
      body: Column(
        children: [
          if (_isUploading)
            const LinearProgressIndicator(
              backgroundColor: Colors.transparent,
            ),
          Expanded(
            child: _MessageList(
              chatId: chatId,
              otherUser: _otherUser,
              currentUid: currentUid,
              scrollController: _scrollController,
              onDeleteMessage: _deleteMessage,
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 4,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      child: _isRecording
          ? _buildRecordingBar()
          : Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.add_circle_outline,
                      color: Color(0xFF075E54)),
                  onPressed: _showAttachmentSheet,
                ),
                Expanded(
                  child: TextField(
                    controller: _textController,
                    style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      hintText: 'Type a message',
                      hintStyle: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[500]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 4),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _textController,
                  builder: (context, value, _) {
                    return value.text.trim().isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.send,
                                color: Color(0xFF075E54)),
                            onPressed: _sendMessage,
                          )
                        : GestureDetector(
                            onTap: _toggleRecording,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                color: Color(0xFF075E54),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _isRecording ? Icons.stop : Icons.mic,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          );
                  },
                ),
              ],
            ),
    );
  }

  Widget _buildRecordingBar() {
    return _RecordingBar(
      stopwatch: _recordStopwatch,
      onTap: _toggleRecording,
    );
  }
}

class _MessageList extends StatelessWidget {
  final String chatId;
  final ChatUser? otherUser;
  final String currentUid;
  final ScrollController scrollController;
  final Future<void> Function(String) onDeleteMessage;

  const _MessageList({
    required this.chatId,
    required this.otherUser,
    required this.currentUid,
    required this.scrollController,
    required this.onDeleteMessage,
  });

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();
    return StreamBuilder(
      stream: db.messagesStream(chatId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final messages = snapshot.data ?? [];

        final unseen =
            messages.where((m) => !m.seenBy.contains(currentUid)).toList();
        if (unseen.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            db.markMessagesAsSeen(
              chatId: chatId,
              uid: currentUid,
              messages: unseen,
            );
          });
        }

        if (messages.isEmpty) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Center(
            child: Text(
              'Say hello to ${otherUser?.name ?? ''}!',
              style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[500]),
            ),
          );
        }

        final reversed = messages.reversed.toList();
        return ListView.builder(
          controller: scrollController,
          reverse: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: reversed.length,
          itemBuilder: (_, i) {
            final msg = reversed[i];
            final isOwn = msg.senderId == currentUid;
            return MessageBubble(
              message: msg,
              isOwn: isOwn,
              onLongPress: isOwn ? () => onDeleteMessage(msg.id) : null,
            );
          },
        );
      },
    );
  }
}

class _RecordingBar extends StatefulWidget {
  final Stopwatch stopwatch;
  final VoidCallback onTap;

  const _RecordingBar({
    required this.stopwatch,
    required this.onTap,
  });

  @override
  State<_RecordingBar> createState() => _RecordingBarState();
}

class _RecordingBarState extends State<_RecordingBar> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final elapsed = widget.stopwatch.elapsed;
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        height: 50,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF075E54),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _formatDuration(elapsed),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            const Text(
              'Tap to send',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }
}
