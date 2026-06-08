class Message {
  final String id;
  final String senderId;
  final String text;
  final String type;
  final String? mediaUrl;
  final int? duration;
  final String? replyToId;
  final String? replyToText;
  final String? replyToSenderName;
  final DateTime timestamp;
  final List<String> seenBy;

  Message({
    required this.id,
    required this.senderId,
    this.text = '',
    this.type = 'text',
    this.mediaUrl,
    this.duration,
    this.replyToId,
    this.replyToText,
    this.replyToSenderName,
    required this.timestamp,
    this.seenBy = const [],
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'senderId': senderId,
        'text': text,
        'type': type,
        'mediaUrl': mediaUrl,
        'duration': duration,
        'replyToId': replyToId,
        'replyToText': replyToText,
        'replyToSenderName': replyToSenderName,
        'timestamp': timestamp,
        'seenBy': seenBy,
      };

  factory Message.fromMap(Map<String, dynamic> map) => Message(
        id: map['id'] ?? '',
        senderId: map['senderId'] ?? '',
        text: map['text'] ?? '',
        type: map['type'] ?? 'text',
        mediaUrl: map['mediaUrl'] as String?,
        duration: map['duration'] as int?,
        replyToId: map['replyToId'] as String?,
        replyToText: map['replyToText'] as String?,
        replyToSenderName: map['replyToSenderName'] as String?,
        timestamp: (map['timestamp'] as dynamic)?.toDate() ?? DateTime.now(),
        seenBy: List<String>.from(map['seenBy'] ?? []),
      );
}
