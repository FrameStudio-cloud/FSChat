class ChatUser {
  final String uid;
  final String name;
  final String photoUrl;
  final String email;
  final String bio;
  final DateTime? lastSeen;
  final bool online;
  final String? pushToken;

  ChatUser({
    required this.uid,
    required this.name,
    required this.photoUrl,
    this.email = '',
    this.bio = '',
    this.lastSeen,
    this.online = false,
    this.pushToken,
  });

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'name': name,
        'photoUrl': photoUrl,
        'email': email,
        'bio': bio,
        'lastSeen': lastSeen,
        'online': online,
        'pushToken': pushToken,
      };

  factory ChatUser.fromMap(Map<String, dynamic> map) => ChatUser(
        uid: map['uid'] ?? '',
        name: map['name'] ?? '',
        photoUrl: map['photoUrl'] ?? '',
        email: map['email'] ?? '',
        bio: map['bio'] ?? '',
        lastSeen: (map['lastSeen'] as dynamic)?.toDate(),
        online: map['online'] ?? false,
        pushToken: map['pushToken'] as String?,
      );
}
