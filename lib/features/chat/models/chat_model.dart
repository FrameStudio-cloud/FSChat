class Chat {
  final String id;
  final List<String> participants;
  final String lastMessage;
  final DateTime? lastMessageTime;
  final String lastMessageSender;
  final bool pinned;
  final bool isGroup;
  final String? groupName;
  final String? groupPhoto;
  final List<String> adminIds;
  final bool archived;

  Chat({
    required this.id,
    required this.participants,
    this.lastMessage = '',
    this.lastMessageTime,
    this.lastMessageSender = '',
    this.pinned = false,
    this.isGroup = false,
    this.groupName,
    this.groupPhoto,
    this.adminIds = const [],
    this.archived = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'participants': participants,
        'lastMessage': lastMessage,
        'lastMessageTime': lastMessageTime,
        'lastMessageSender': lastMessageSender,
        'pinned': pinned,
        'isGroup': isGroup,
        'groupName': groupName,
        'groupPhoto': groupPhoto,
        'adminIds': adminIds,
        'archived': archived,
      };

  factory Chat.fromMap(Map<String, dynamic> map) => Chat(
        id: map['id'] ?? '',
        participants: List<String>.from(map['participants'] ?? []),
        lastMessage: map['lastMessage'] ?? '',
        lastMessageTime: (map['lastMessageTime'] as dynamic)?.toDate(),
        lastMessageSender: map['lastMessageSender'] ?? '',
        pinned: map['pinned'] ?? false,
        isGroup: map['isGroup'] ?? false,
        groupName: map['groupName'] as String?,
        groupPhoto: map['groupPhoto'] as String?,
        adminIds: List<String>.from(map['adminIds'] ?? []),
        archived: map['archived'] ?? false,
      );

  String get displayName => isGroup ? (groupName ?? 'Group') : '';
}
