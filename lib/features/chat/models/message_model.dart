class Message {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final String type;
  final String? mediaUrl;
  final List<String>? mediaUrls;
  final int? duration;
  final String? replyToId;
  final String? replyToText;
  final String? replyToSenderName;
  final String? fileName;
  final int? fileSize;
  final DateTime timestamp;
  final List<String> seenBy;
  final bool isEdited;
  final bool isForwarded;
  final Map<String, String> reactions;

  Message({
    required this.id,
    required this.senderId,
    this.senderName = '',
    this.text = '',
    this.type = 'text',
    this.mediaUrl,
    this.mediaUrls,
    this.duration,
    this.replyToId,
    this.replyToText,
    this.replyToSenderName,
    this.fileName,
    this.fileSize,
    required this.timestamp,
    this.seenBy = const [],
    this.isEdited = false,
    this.isForwarded = false,
    this.reactions = const {},
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'senderId': senderId,
        'senderName': senderName,
        'text': text,
        'type': type,
        'mediaUrl': mediaUrl,
        'mediaUrls': mediaUrls,
        'duration': duration,
        'replyToId': replyToId,
        'replyToText': replyToText,
        'replyToSenderName': replyToSenderName,
        'fileName': fileName,
        'fileSize': fileSize,
        'timestamp': timestamp,
        'seenBy': seenBy,
        'isEdited': isEdited,
        'isForwarded': isForwarded,
        'reactions': reactions,
      };

  factory Message.fromMap(Map<String, dynamic> map) => Message(
        id: map['id'] ?? '',
        senderId: map['senderId'] ?? '',
        senderName: map['senderName'] ?? '',
        text: map['text'] ?? '',
        type: map['type'] ?? 'text',
        mediaUrl: map['mediaUrl'] as String?,
        mediaUrls: map['mediaUrls'] != null
            ? List<String>.from(map['mediaUrls'])
            : null,
        duration: map['duration'] as int?,
        replyToId: map['replyToId'] as String?,
        replyToText: map['replyToText'] as String?,
        replyToSenderName: map['replyToSenderName'] as String?,
        fileName: map['fileName'] as String?,
        fileSize: map['fileSize'] as int?,
        timestamp: (map['timestamp'] as dynamic)?.toDate() ?? DateTime.now(),
        seenBy: List<String>.from(map['seenBy'] ?? []),
        isEdited: map['isEdited'] as bool? ?? false,
        isForwarded: map['isForwarded'] as bool? ?? false,
        reactions: Map<String, String>.from(map['reactions'] as Map? ?? {}),
      );
}
