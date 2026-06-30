import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../../features/auth/models/user_model.dart';
import '../../features/chat/models/chat_model.dart';
import '../../features/chat/models/message_model.dart';
import '../../features/blog/models/post_model.dart';
import '../../features/blog/models/comment_model.dart';

import '../../features/mood/models/mood_entry.dart';
import '../../features/challenges/models/challenge_model.dart';
import '../../features/challenges/models/challenge_progress.dart';

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

  Future<void> updateEmail(String uid, String email) async {
    await _users.doc(uid).update({'email': email});
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

  Future<Chat?> getChat(String chatId) async {
    final doc = await _chats.doc(chatId).get();
    if (!doc.exists) return null;
    return Chat.fromMap(doc.data() as Map<String, dynamic>);
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
        .limit(50)
        .snapshots()
        .map((snap) {
      final chats = snap.docs
          .map((d) => Chat.fromMap(d.data() as Map<String, dynamic>))
          .where((c) => !c.archived)
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

  Future<void> archiveChat(String chatId, bool archived) async {
    await _chats.doc(chatId).update({'archived': archived});
  }

  Future<void> markAllChatsRead(String uid) async {
    final snap = await _chats.where('participants', arrayContains: uid).get();
    for (final doc in snap.docs) {
      final messages =
          await doc.reference.collection('messages').limit(100).get();
      final batch = FirebaseFirestore.instance.batch();
      var updated = 0;
      for (final msg in messages.docs) {
        final seenBy = List<String>.from(msg['seenBy'] ?? []);
        if (!seenBy.contains(uid)) {
          batch.update(msg.reference, {
            'seenBy': FieldValue.arrayUnion([uid]),
          });
          updated++;
        }
      }
      if (updated > 0) await batch.commit();
    }
  }

  Stream<List<Message>> messagesStream(String chatId) {
    return _chats
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map(
            (snap) => snap.docs.map((d) => Message.fromMap(d.data())).toList());
  }

  Stream<int> unreadCountStream(String chatId, String uid) {
    return _chats
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snap) => snap.docs.where((d) {
              final seenBy = List<String>.from(d['seenBy'] ?? []);
              return !seenBy.contains(uid);
            }).length);
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

  Future<void> updateBio(String uid, String bio) async {
    await _users.doc(uid).update({'bio': bio});
  }

  Future<void> clearChat(String chatId) async {
    final messages = await _chats.doc(chatId).collection('messages').get();
    final batch = _firestore.batch();
    for (final doc in messages.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    await _chats.doc(chatId).update({
      'lastMessage': '',
      'lastMessageTime': null,
      'lastMessageSender': '',
    });
  }

  Stream<List<Message>> sharedMediaStream(String chatId) {
    return _chats
        .doc(chatId)
        .collection('messages')
        .where('type', whereIn: ['image', 'audio'])
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots()
        .map(
            (snap) => snap.docs.map((d) => Message.fromMap(d.data())).toList());
  }

  Future<String> uploadImage(
      String chatId, String messageId, String filePath) async {
    final ref = _storage.ref().child('media/$chatId/$messageId.jpg');
    await ref.putFile(File(filePath));
    return await ref.getDownloadURL();
  }

  Future<String> uploadSticker(
      String chatId, String messageId, String filePath) async {
    final ref = _storage.ref().child('stickers/$chatId/$messageId.png');
    await ref.putFile(
        File(filePath), SettableMetadata(contentType: 'image/png'));
    return await ref.getDownloadURL();
  }

  Future<String> uploadAudio(
      String chatId, String messageId, String filePath) async {
    final ref = _storage.ref().child('media/$chatId/$messageId.m4a');
    await ref.putFile(File(filePath));
    return await ref.getDownloadURL();
  }

  Future<String> uploadFile(
      String chatId, String messageId, String filePath) async {
    final ext = filePath.split('.').last;
    final ref = _storage.ref().child('files/$chatId/$messageId.$ext');
    await ref.putFile(File(filePath));
    return await ref.getDownloadURL();
  }

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    String senderName = '',
    String text = '',
    String type = 'text',
    String? mediaUrl,
    List<String>? mediaUrls,
    int? duration,
    String? replyToId,
    String? replyToText,
    String? replyToSenderName,
    bool isForwarded = false,
    String? messageId,
    String? fileName,
    int? fileSize,
  }) async {
    final msgId = messageId ?? _uuid.v4();
    final now = DateTime.now();

    final msgData = {
      'id': msgId,
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'type': type,
      'timestamp': now,
      'seenBy': [senderId],
      'isForwarded': isForwarded,
    };
    if (mediaUrl != null) msgData['mediaUrl'] = mediaUrl;
    if (mediaUrls != null) msgData['mediaUrls'] = mediaUrls;
    if (duration != null) msgData['duration'] = duration;
    if (replyToId != null) msgData['replyToId'] = replyToId;
    if (replyToText != null) msgData['replyToText'] = replyToText;
    if (replyToSenderName != null)
      msgData['replyToSenderName'] = replyToSenderName;
    if (fileName != null) msgData['fileName'] = fileName;
    if (fileSize != null) msgData['fileSize'] = fileSize;

    await _chats.doc(chatId).collection('messages').doc(msgId).set(msgData);

    final displayText = type == 'text'
        ? text
        : type == 'image'
            ? '📷 Photo'
            : type == 'multi_image'
                ? '📷 ${mediaUrls?.length ?? 0} Photos'
                : type == 'sticker'
                    ? '📦 Sticker'
                    : type == 'file'
                        ? '📎 ${fileName ?? 'File'}'
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

  Future<String> createGroupChat({
    required String name,
    required List<String> participants,
    required String adminUid,
    String? photoUrl,
  }) async {
    final chatId = _uuid.v4();
    await _chats.doc(chatId).set({
      'id': chatId,
      'participants': participants,
      'lastMessage': '',
      'lastMessageTime': null,
      'lastMessageSender': '',
      'isGroup': true,
      'groupName': name,
      'groupPhoto': photoUrl,
      'adminIds': [adminUid],
    });
    return chatId;
  }

  Future<void> addGroupMember(String chatId, String uid) async {
    await _chats.doc(chatId).update({
      'participants': FieldValue.arrayUnion([uid]),
    });
  }

  Future<void> removeGroupMember(String chatId, String uid) async {
    await _chats.doc(chatId).update({
      'participants': FieldValue.arrayRemove([uid]),
    });
  }

  Future<void> updateGroupName(String chatId, String name) async {
    await _chats.doc(chatId).update({'groupName': name});
  }

  Stream<List<ChatUser>> chatParticipantsStream(String chatId) {
    return _chats.doc(chatId).snapshots().asyncMap((doc) async {
      final data = doc.data() as Map<String, dynamic>;
      final uids = List<String>.from(data['participants'] ?? []);
      final users = <ChatUser>[];
      for (final uid in uids) {
        final user = await getUser(uid);
        if (user != null) users.add(user);
      }
      return users;
    });
  }

  Future<void> deleteMessage(String chatId, String messageId) async {
    await _chats.doc(chatId).collection('messages').doc(messageId).delete();
    await _refreshLastMessage(chatId);
  }

  Future<void> toggleReaction({
    required String chatId,
    required String messageId,
    required String userId,
    required String emoji,
  }) async {
    final doc = _chats.doc(chatId).collection('messages').doc(messageId);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(doc);
      if (!snap.exists) return;
      final data = snap.data();
      final reactions =
          Map<String, String>.from(data?['reactions'] as Map? ?? {});
      if (reactions[userId] == emoji) {
        reactions.remove(userId);
      } else {
        reactions[userId] = emoji;
      }
      tx.update(doc, {'reactions': reactions});
    });
  }

  Future<void> batchDeleteMessages(
      String chatId, List<String> messageIds) async {
    final batch = _firestore.batch();
    for (final id in messageIds) {
      batch.delete(_chats.doc(chatId).collection('messages').doc(id));
    }
    await batch.commit();
    await _refreshLastMessage(chatId);
  }

  Future<void> _refreshLastMessage(String chatId) async {
    final snap = await _chats
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) {
      await _chats.doc(chatId).update({
        'lastMessage': '',
        'lastMessageTime': null,
        'lastMessageSender': '',
      });
      return;
    }
    final data = snap.docs.first.data();
    final type = data['type'] as String? ?? 'text';
    final text = data['text'] as String? ?? '';
    final senderId = data['senderId'] as String? ?? '';
    final mediaUrls = data['mediaUrls'] as List?;

    final displayText = type == 'text'
        ? text
        : type == 'image'
            ? '📷 Photo'
            : type == 'multi_image'
                ? '📷 ${mediaUrls?.length ?? 0} Photos'
                : type == 'sticker'
                    ? '📦 Sticker'
                    : type == 'file'
                        ? '📎 ${data['fileName'] as String? ?? 'File'}'
                        : '🎤 Voice message';

    await _chats.doc(chatId).update({
      'lastMessage': displayText,
      'lastMessageTime': data['timestamp'],
      'lastMessageSender': senderId,
    });
  }

  Future<void> editMessage(
      String chatId, String messageId, String newText) async {
    await _chats
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({'text': newText, 'isEdited': true});
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

  Future<void> blockUser(String uid, String blockedUid) async {
    await _users.doc(uid).update({
      'blockedUsers': FieldValue.arrayUnion([blockedUid]),
    });
  }

  Future<void> unblockUser(String uid, String blockedUid) async {
    await _users.doc(uid).update({
      'blockedUsers': FieldValue.arrayRemove([blockedUid]),
    });
  }

  Stream<List<String>> blockedUserIdsStream(String uid) {
    return _users.doc(uid).snapshots().map((snap) {
      final data = snap.data() as Map<String, dynamic>?;
      if (data == null) return <String>[];
      return List<String>.from(data['blockedUsers'] as List? ?? []);
    });
  }

  Future<List<ChatUser>> getBlockedUsers(String uid) async {
    final userSnap = await _users.doc(uid).get();
    final data = userSnap.data() as Map<String, dynamic>?;
    if (data == null) return [];
    final blockedIds = List<String>.from(data['blockedUsers'] as List? ?? []);
    if (blockedIds.isEmpty) return [];
    final userDocs =
        await _users.where(FieldPath.documentId, whereIn: blockedIds).get();
    return userDocs.docs
        .map((d) => ChatUser.fromMap(d.data() as Map<String, dynamic>))
        .toList();
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

  CollectionReference get _posts => _firestore.collection('posts');

  Future<void> createPost(Post post) async {
    await _posts.doc(post.id).set(post.toMap());
  }

  Future<void> updatePost(String postId, Map<String, dynamic> updates) async {
    await _posts.doc(postId).update(updates);
  }

  Future<void> deletePost(String postId) async {
    final comments = await _posts.doc(postId).collection('comments').get();
    final batch = _firestore.batch();
    for (final doc in comments.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_posts.doc(postId));
    await batch.commit();
  }

  Stream<List<Post>> allPostsStream() {
    return _posts
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Post.fromMap(d.data() as Map<String, dynamic>))
            .toList());
  }

  Stream<List<Post>> postsByTagStream(String tag) {
    return _posts.where('tags', arrayContains: tag).snapshots().map((snap) =>
        (snap.docs
            .map((d) => Post.fromMap(d.data() as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt))));
  }

  Future<Post?> getPost(String postId) async {
    final doc = await _posts.doc(postId).get();
    if (!doc.exists) return null;
    return Post.fromMap(doc.data() as Map<String, dynamic>);
  }

  Future<String> uploadPostCover(String postId, String filePath) async {
    final ref = _storage.ref().child('post_covers/$postId.jpg');
    await ref.putFile(File(filePath));
    return await ref.getDownloadURL();
  }

  Future<void> likePost(String postId, String uid) async {
    await _posts.doc(postId).update({
      'likedBy': FieldValue.arrayUnion([uid]),
      'likeCount': FieldValue.increment(1),
    });
  }

  Future<void> unlikePost(String postId, String uid) async {
    await _posts.doc(postId).update({
      'likedBy': FieldValue.arrayRemove([uid]),
      'likeCount': FieldValue.increment(-1),
    });
  }

  Future<void> addComment(String postId, Comment comment) async {
    await _posts
        .doc(postId)
        .collection('comments')
        .doc(comment.id)
        .set(comment.toMap());
    await _posts.doc(postId).update({
      'commentCount': FieldValue.increment(1),
    });
  }

  Stream<List<Comment>> commentsStream(String postId) {
    return _posts
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
            (snap) => snap.docs.map((d) => Comment.fromMap(d.data())).toList());
  }

  Future<void> deleteComment(String postId, String commentId) async {
    await _posts.doc(postId).collection('comments').doc(commentId).delete();
    await _posts.doc(postId).update({
      'commentCount': FieldValue.increment(-1),
    });
  }

  CollectionReference get _moods => _firestore.collection('moods');

  Future<void> saveMood(MoodEntry entry) async {
    final dayKey =
        '${entry.date.year}-${entry.date.month.toString().padLeft(2, '0')}-${entry.date.day.toString().padLeft(2, '0')}';
    final docId = '${entry.userId}_$dayKey';
    await _moods.doc(docId).set(entry.toMap());
  }

  Stream<List<MoodEntry>> userMoodsStream(String uid) {
    return _moods.where('userId', isEqualTo: uid).snapshots().map((snap) =>
        (snap.docs
            .map((d) => MoodEntry.fromMap(d.data() as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date))));
  }

  Future<void> deleteMood(String moodId) async {
    await _moods.doc(moodId).delete();
  }

  Future<MoodEntry?> getMoodForDate(String uid, DateTime date) async {
    final dayKey =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final docId = '${uid}_$dayKey';
    final doc = await _moods.doc(docId).get();
    if (!doc.exists) return null;
    return MoodEntry.fromMap(doc.data() as Map<String, dynamic>);
  }

  Future<void> deleteMoodByDate(String uid, DateTime date) async {
    final dayKey =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final docId = '${uid}_$dayKey';
    await _moods.doc(docId).delete();
  }

  CollectionReference get _challenges => _firestore.collection('challenges');
  CollectionReference get _challengeProgress =>
      _firestore.collection('challenge_progress');

  Future<void> createChallenge(Challenge challenge) async {
    await _challenges.doc(challenge.id).set(challenge.toMap());
  }

  Stream<List<Challenge>> userChallengesStream(String uid) {
    return _challenges
        .where('participants', arrayContains: uid)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Challenge.fromMap(d.data() as Map<String, dynamic>))
            .toList());
  }

  Future<Challenge?> getChallenge(String challengeId) async {
    final doc = await _challenges.doc(challengeId).get();
    if (!doc.exists) return null;
    return Challenge.fromMap(doc.data() as Map<String, dynamic>);
  }

  Future<void> updateChallenge(
      String challengeId, Map<String, dynamic> updates) async {
    await _challenges.doc(challengeId).update(updates);
  }

  Future<void> deleteChallenge(String challengeId) async {
    await _challenges.doc(challengeId).update({'status': 'cancelled'});
  }

  Future<void> archiveChallenge(String challengeId) async {
    await _challenges.doc(challengeId).update({'status': 'archived'});
  }

  Future<void> leaveChallenge(String challengeId, String uid) async {
    await _challenges.doc(challengeId).update({
      'participants': FieldValue.arrayRemove([uid]),
    });
  }

  Stream<ChallengeProgress?> myProgressStream(
      String challengeId, String userId) {
    return _challengeProgress.doc('${challengeId}_$userId').snapshots().map(
        (doc) => doc.exists
            ? ChallengeProgress.fromMap(doc.data() as Map<String, dynamic>)
            : null);
  }

  Future<ChallengeProgress?> getMyProgress(
      String challengeId, String userId) async {
    final doc = await _challengeProgress.doc('${challengeId}_$userId').get();
    if (!doc.exists) return null;
    return ChallengeProgress.fromMap(doc.data() as Map<String, dynamic>);
  }

  Stream<List<ChallengeProgress>> allMyProgressStream(String userId) {
    return _challengeProgress
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) =>
                ChallengeProgress.fromMap(d.data() as Map<String, dynamic>))
            .toList());
  }

  Future<void> markDayComplete(
      String challengeId, String userId, int dayIndex) async {
    final docId = '${challengeId}_$userId';
    final ref = _challengeProgress.doc(docId);
    final doc = await ref.get();
    if (doc.exists) {
      await ref.update({
        'completedDays': FieldValue.arrayUnion([dayIndex]),
        'lastUpdated': DateTime.now(),
      });
    } else {
      await ref.set({
        'id': docId,
        'challengeId': challengeId,
        'userId': userId,
        'completedDays': [dayIndex],
        'lastUpdated': DateTime.now(),
      });
    }
  }

  Future<void> markDayIncomplete(
      String challengeId, String userId, int dayIndex) async {
    final ref = _challengeProgress.doc('${challengeId}_$userId');
    await ref.update({
      'completedDays': FieldValue.arrayRemove([dayIndex]),
      'lastUpdated': DateTime.now(),
    });
  }

  Stream<ChallengeProgress?> challengeProgressStream(
      String challengeId, String userId) {
    return _challengeProgress.doc('${challengeId}_$userId').snapshots().map(
        (doc) => doc.exists
            ? ChallengeProgress.fromMap(doc.data() as Map<String, dynamic>)
            : null);
  }

  // ── Widget bubbles helpers ──

  CollectionReference get _habitLogs => _firestore.collection('habit_logs');

  Future<int> getCompletedHabitsToday(DateTime date) async {
    final dateString =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final snap =
        await _habitLogs.where('dateString', isEqualTo: dateString).get();
    return snap.docs
        .where(
            (d) => (d.data() as Map<String, dynamic>)['status'] == 'completed')
        .length;
  }

  Future<int> getActiveChallengesCount(String uid) async {
    final snap = await _challenges
        .where('participants', arrayContains: uid)
        .where('status', isEqualTo: 'active')
        .get();
    return snap.docs.length;
  }

  Future<int> countOnlineUsers(String uid) async {
    final snap = await _firestore
        .collection('users')
        .where(FieldPath.documentId, isNotEqualTo: uid)
        .where('online', isEqualTo: true)
        .get();
    return snap.docs.length;
  }
}
