import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../../features/auth/models/user_model.dart';
import '../../features/chat/models/chat_model.dart';
import '../../features/chat/models/message_model.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = Uuid();

  CollectionReference get _users => _firestore.collection('users');
  CollectionReference get _chats => _firestore.collection('chats');

  Future<void> createUser(ChatUser user) async {
    await _users.doc(user.uid).set(user.toMap());
  }

  Future<void> updatePushToken(String uid, String token) async {
    await _users.doc(uid).update({'pushToken': token});
  }

  Future<void> updateName(String uid, String name) async {
    await _users.doc(uid).update({'name': name});
  }

  Future<void> updateOnlineStatus(String uid, bool online) async {
    await _users.doc(uid).update({
      'online': online,
      'lastSeen': DateTime.now(),
    });
  }

  Future<ChatUser?> getUser(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return ChatUser.fromMap(doc.data() as Map<String, dynamic>);
  }

  Stream<ChatUser?> userStream(String uid) {
    return _users.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return ChatUser.fromMap(doc.data() as Map<String, dynamic>);
    });
  }

  Stream<List<ChatUser>> allUsers(String currentUid) {
    return _users.snapshots().map((snap) => snap.docs
        .map((d) => ChatUser.fromMap(d.data() as Map<String, dynamic>))
        .where((u) => u.uid != currentUid)
        .toList());
  }

  Future<String> getOrCreateChat(String uid1, String uid2) async {
    final chatId = _generateChatId(uid1, uid2);
    final chatDoc = await _chats.doc(chatId).get();
    if (!chatDoc.exists) {
      await _chats.doc(chatId).set({
        'id': chatId,
        'participants': [uid1, uid2],
        'lastMessage': '',
        'lastMessageTime': null,
        'lastMessageSender': '',
      });
    }
    return chatId;
  }

  Stream<Chat> chatStream(String chatId) {
    return _chats
        .doc(chatId)
        .snapshots()
        .map((doc) => Chat.fromMap(doc.data() as Map<String, dynamic>));
  }

  Stream<List<Chat>> userChats(String uid) {
    return _chats
        .where('participants', arrayContains: uid)
        .snapshots()
        .map((snap) {
      final chats = snap.docs
          .map((d) => Chat.fromMap(d.data() as Map<String, dynamic>))
          .toList();
      chats.sort((a, b) {
        if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
        final aTime = a.lastMessageTime ?? DateTime(2000);
        final bTime = b.lastMessageTime ?? DateTime(2000);
        return bTime.compareTo(aTime);
      });
      return chats;
    });
  }

  Stream<List<Message>> messagesStream(String chatId) {
    return _chats
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map(
            (snap) => snap.docs.map((d) => Message.fromMap(d.data())).toList());
  }

  Future<String> uploadProfilePhoto(String uid, String filePath) async {
    final ref = _storage.ref().child('profile_photos/$uid.jpg');
    await ref.putFile(File(filePath));
    return await ref.getDownloadURL();
  }

  Future<void> updateUserName(String uid, String name) async {
    await _users.doc(uid).update({'name': name});
  }

  Future<void> updateUserPhoto(String uid, String url) async {
    await _users.doc(uid).update({'photoUrl': url});
  }

  Future<String> uploadImage(
      String chatId, String messageId, String filePath) async {
    final ref = _storage.ref().child('media/$chatId/$messageId.jpg');
    await ref.putFile(File(filePath));
    return await ref.getDownloadURL();
  }

  Future<String> uploadAudio(
      String chatId, String messageId, String filePath) async {
    final ref = _storage.ref().child('media/$chatId/$messageId.m4a');
    await ref.putFile(File(filePath));
    return await ref.getDownloadURL();
  }

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    String text = '',
    String type = 'text',
    String? mediaUrl,
    int? duration,
    String? replyToId,
    String? replyToText,
  }) async {
    final msgId = _uuid.v4();
    final now = DateTime.now();

    final msgData = {
      'id': msgId,
      'senderId': senderId,
      'text': text,
      'type': type,
      'timestamp': now,
      'seenBy': [senderId],
    };
    if (mediaUrl != null) msgData['mediaUrl'] = mediaUrl;
    if (duration != null) msgData['duration'] = duration;
    if (replyToId != null) msgData['replyToId'] = replyToId;
    if (replyToText != null) msgData['replyToText'] = replyToText;

    await _chats.doc(chatId).collection('messages').doc(msgId).set(msgData);

    final displayText = type == 'text'
        ? text
        : type == 'image'
            ? '📷 Photo'
            : '🎤 Voice message';

    await _chats.doc(chatId).update({
      'lastMessage': displayText,
      'lastMessageTime': now,
      'lastMessageSender': senderId,
    });
  }

  Future<void> markMessagesAsSeen({
    required String chatId,
    required String uid,
    required List<Message> messages,
  }) async {
    final batch = _firestore.batch();
    for (final msg in messages) {
      if (!msg.seenBy.contains(uid)) {
        final ref = _chats.doc(chatId).collection('messages').doc(msg.id);
        batch.update(ref, {
          'seenBy': FieldValue.arrayUnion([uid])
        });
      }
    }
    await batch.commit();
  }

  String _generateChatId(String uid1, String uid2) {
    final ids = [uid1, uid2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  Future<void> deleteMessage(String chatId, String messageId) async {
    await _chats.doc(chatId).collection('messages').doc(messageId).delete();
  }

  Future<void> deleteChat(String chatId) async {
    final messages = await _chats.doc(chatId).collection('messages').get();
    final batch = _firestore.batch();
    for (final doc in messages.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_chats.doc(chatId));
    await batch.commit();
  }

  Future<void> togglePinChat(String chatId, bool pinned) async {
    await _chats.doc(chatId).update({'pinned': pinned});
  }

  Future<void> setTyping(String chatId, String uid, bool isTyping) async {
    if (isTyping) {
      await _chats.doc(chatId).collection('typing').doc(uid).set({
        'isTyping': true,
        'timestamp': DateTime.now(),
      });
    } else {
      await _chats.doc(chatId).collection('typing').doc(uid).delete();
    }
  }

  Stream<bool> typingStream(String chatId, String uid) {
    return _chats
        .doc(chatId)
        .collection('typing')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists);
  }
}
