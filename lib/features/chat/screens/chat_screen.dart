import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/models/user_model.dart';
import '../../../core/services/database_service.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../shared/models/menu_action.dart';
import '../models/message_model.dart';
import '../widgets/message_bubble.dart';
import 'user_info_screen.dart';

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
  Message? _replyingTo;
  String? _mentionQuery;
  List<ChatUser> _mentionUsers = [];
  StreamSubscription<List<ChatUser>>? _mentionSubscription;
  String? _currentUid;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthProvider>().user!.uid;
      _currentUid = uid;
      _db.allUsers(uid).first.then((users) {
        if (mounted) setState(() => _mentionUsers = users);
      });
      _mentionSubscription = _db.allUsers(uid).listen((users) {
        if (mounted) setState(() => _mentionUsers = users);
      });
    });
  }

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
  void dispose() {
    _typingTimer?.cancel();
    _db.setTyping(chatId, otherUid, false);
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    _mentionSubscription?.cancel();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _textController.text;
    final sel = _textController.selection;
    final cursorPos = sel.isValid ? sel.baseOffset : text.length;
    final hasText = text.trim().isNotEmpty;
    final uid = context.read<AuthProvider>().user!.uid;
    _db.setTyping(chatId, uid, hasText);

    _typingTimer?.cancel();
    if (hasText) {
      _typingTimer = Timer(const Duration(seconds: 2), () {
        _db.setTyping(chatId, uid, false);
      });
    }

    final hasAt = text.contains('@');
    if (hasAt && cursorPos > 0) {
      final before = text.substring(0, cursorPos);
      final atIdx = before.lastIndexOf('@');
      if (atIdx >= 0 && (atIdx == 0 || before[atIdx - 1] == ' ')) {
        final afterAt = before.substring(atIdx);
        if (!afterAt.contains(' ')) {
          if (_mentionQuery == null) setState(() => _mentionQuery = '');
          return;
        }
      }
    }
    if (_mentionQuery != null) setState(() => _mentionQuery = null);
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _typingTimer?.cancel();
    final uid = context.read<AuthProvider>().user!.uid;
    final replyTo = _replyingTo;
    setState(() => _replyingTo = null);
    await _db.setTyping(chatId, uid, false);
    try {
      await _db.sendMessage(
        chatId: chatId,
        senderId: uid,
        text: text,
        replyToId: replyTo?.id,
        replyToText: replyTo?.text.isNotEmpty == true
            ? replyTo!.text
            : replyTo?.type == 'image'
                ? '📷 Photo'
                : '🎤 Voice message',
      );
      _textController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e')),
        );
      }
    }
  }

  Widget _buildReplyPreview() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF0F0F0),
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF075E54),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Reply',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF075E54),
                  ),
                ),
                Text(
                  _replyingTo?.text.isNotEmpty == true
                      ? _replyingTo!.text
                      : _replyingTo?.type == 'image'
                          ? '📷 Photo'
                          : '🎤 Voice message',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => setState(() => _replyingTo = null),
          ),
        ],
      ),
    );
  }

  void _showMessageMenu(Message msg, Offset pos) {
    final uid = context.read<AuthProvider>().user!.uid;
    final isOwn = msg.senderId == uid;

    final actions = [
      if (msg.type == 'text')
        MenuAction(
          label: 'Copy',
          icon: Icons.copy_rounded,
          onTap: () {
            Clipboard.setData(ClipboardData(text: msg.text));
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Copied'), duration: Duration(seconds: 1)),
              );
            }
          },
        ),
      if (isOwn)
        MenuAction(
          label: 'Delete',
          icon: Icons.delete_rounded,
          isDestructive: true,
          onTap: () => _deleteMessage(msg.id),
        ),
    ];

    if (actions.isEmpty) return;

    final items = actions
        .map((a) => PopupMenuItem<int>(
              value: actions.indexOf(a),
              child: ListTile(
                dense: true,
                leading:
                    Icon(a.icon, color: a.isDestructive ? Colors.red : null),
                title: Text(a.label,
                    style: a.isDestructive
                        ? const TextStyle(color: Colors.red)
                        : null),
              ),
            ))
        .toList();

    showMenu<int>(
      context: context,
      position: RelativeRect.fromLTRB(pos.dx, pos.dy, pos.dx + 1, pos.dy + 1),
      items: items,
    ).then((index) {
      if (index != null) actions[index].onTap();
    });
  }

  void _insertMention(ChatUser user) {
    final text = _textController.text;
    final atIdx = text.lastIndexOf('@');
    if (atIdx < 0) {
      setState(() => _mentionQuery = null);
      return;
    }
    int endIdx = atIdx + 1;
    while (endIdx < text.length && text[endIdx] != ' ') {
      endIdx++;
    }
    final newText =
        '${text.substring(0, atIdx)}@${user.name} ${text.substring(endIdx)}';
    final newCursor = atIdx + user.name.length + 2;
    _textController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursor),
    );
  }

  Widget _buildMentionSuggestions() {
    if (_mentionQuery == null) return const SizedBox();
    final filtered = _mentionUsers.where((u) => u.uid != _currentUid).toList();
    if (filtered.isEmpty) return const SizedBox();
    final maxHeight =
        MediaQuery.of(context).viewInsets.bottom > 0 ? 120.0 : 180.0;
    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF2D2D2D)
            : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: filtered.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 56),
        itemBuilder: (_, i) {
          final user = filtered[i];
          return ListTile(
            dense: true,
            leading: CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF075E54),
              backgroundImage:
                  user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null,
              child: user.photoUrl.isEmpty
                  ? Text(user.name[0].toUpperCase(),
                      style: const TextStyle(fontSize: 12, color: Colors.white))
                  : null,
            ),
            title: Text(user.name,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black87,
                )),
            onTap: () => _insertMention(user),
          );
        },
      ),
    );
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
      final replyTo = _replyingTo;
      setState(() => _replyingTo = null);
      await _db.sendMessage(
        chatId: chatId,
        senderId: uid,
        text: '',
        type: 'image',
        mediaUrl: url,
        replyToId: replyTo?.id,
        replyToText: replyTo != null
            ? (replyTo.text.isNotEmpty
                ? replyTo.text
                : replyTo.type == 'image'
                    ? '📷 Photo'
                    : '🎤 Voice message')
            : null,
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

  void _showWallpaperPicker(BuildContext context) {
    final theme = context.read<ThemeProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

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
                                  ? Border.all(
                                      color: const Color(0xFF075E54), width: 3)
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
                    color: const Color(0xFF075E54).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.image_outlined,
                      color: Color(0xFF075E54)),
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
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? const Color(0xFF075E54) : null,
              )),
        ),
      ),
    );
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
      final replyTo = _replyingTo;
      setState(() => _replyingTo = null);
      await _db.sendMessage(
        chatId: chatId,
        senderId: uid,
        text: '',
        type: 'audio',
        mediaUrl: url,
        duration: duration,
        replyToId: replyTo?.id,
        replyToText: replyTo != null
            ? (replyTo.text.isNotEmpty
                ? replyTo.text
                : replyTo.type == 'image'
                    ? '📷 Photo'
                    : '🎤 Voice message')
            : null,
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
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UserInfoScreen(
                        user: liveUser ?? _otherUser!,
                        chatId: chatId,
                      ),
                    ),
                  ),
                  child: Hero(
                    tag: 'avatar_${liveUser?.uid ?? _otherUser!.uid}',
                    child: CircleAvatar(
                      radius: 16,
                      backgroundImage: liveUser?.photoUrl.isNotEmpty == true
                          ? NetworkImage(liveUser!.photoUrl)
                          : null,
                      child: liveUser?.photoUrl.isEmpty == true
                          ? Text(liveUser!.name[0].toUpperCase(),
                              style: const TextStyle(fontSize: 14))
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UserInfoScreen(
                            user: liveUser ?? _otherUser!,
                            chatId: chatId,
                          ),
                        ),
                      ),
                      child: Text(liveUser?.name ?? '',
                          style: const TextStyle(fontSize: 16)),
                    ),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.wallpaper_rounded),
            tooltip: 'Change wallpaper',
            onPressed: () => _showWallpaperPicker(context),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isUploading)
            const LinearProgressIndicator(
              backgroundColor: Colors.transparent,
            ),
          Expanded(
            child: Consumer<ThemeProvider>(
              builder: (context, theme, _) {
                final deco = theme.wallpaperDecoration;
                return Container(
                  decoration: deco,
                  child: _MessageList(
                    chatId: chatId,
                    otherUser: _otherUser,
                    currentUid: currentUid,
                    scrollController: _scrollController,
                    onMessageMenu: _showMessageMenu,
                    onSwipeReply: (msg) {
                      setState(() => _replyingTo = msg);
                    },
                  ),
                );
              },
            ),
          ),
          if (_replyingTo != null) _buildReplyPreview(),
          _buildMentionSuggestions(),
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
                    minLines: 1,
                    maxLines: 5,
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
                        vertical: 14,
                      ),
                    ),
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
  final void Function(Message msg, Offset pos) onMessageMenu;
  final void Function(Message) onSwipeReply;

  const _MessageList({
    required this.chatId,
    required this.otherUser,
    required this.currentUid,
    required this.scrollController,
    required this.onMessageMenu,
    required this.onSwipeReply,
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
              onLongPress: (pos) => onMessageMenu(msg, pos),
              onSwipeReply: () => onSwipeReply(msg),
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
