class Chat {
  final String id;
  final List<String> participants;
  final String lastMessage;
  final DateTime? lastMessageTime;
  final String lastMessageSender;
  final bool pinned;

  Chat({
    required this.id,
    required this.participants,
    this.lastMessage = '',
    this.lastMessageTime,
    this.lastMessageSender = '',
    this.pinned = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'participants': participants,
        'lastMessage': lastMessage,
        'lastMessageTime': lastMessageTime,
        'lastMessageSender': lastMessageSender,
        'pinned': pinned,
      };

  factory Chat.fromMap(Map<String, dynamic> map) => Chat(
        id: map['id'] ?? '',
        participants: List<String>.from(map['participants'] ?? []),
        lastMessage: map['lastMessage'] ?? '',
        lastMessageTime: (map['lastMessageTime'] as dynamic)?.toDate(),
        lastMessageSender: map['lastMessageSender'] ?? '',
        pinned: map['pinned'] ?? false,
      );
}
