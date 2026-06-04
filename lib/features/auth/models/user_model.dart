class ChatUser {
  final String uid;
  final String name;
  final String photoUrl;
  final DateTime? lastSeen;
  final bool online;
  final String? pushToken;

  ChatUser({
    required this.uid,
    required this.name,
    required this.photoUrl,
    this.lastSeen,
    this.online = false,
    this.pushToken,
  });

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'name': name,
        'photoUrl': photoUrl,
        'lastSeen': lastSeen,
        'online': online,
        'pushToken': pushToken,
      };

  factory ChatUser.fromMap(Map<String, dynamic> map) => ChatUser(
        uid: map['uid'] ?? '',
        name: map['name'] ?? '',
        photoUrl: map['photoUrl'] ?? '',
        lastSeen: (map['lastSeen'] as dynamic)?.toDate(),
        online: map['online'] ?? false,
        pushToken: map['pushToken'] as String?,
      );
}
