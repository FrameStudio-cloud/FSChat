import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/auth/models/user_model.dart';
import '../../shared/widgets/notification_banner.dart';

class NotificationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static FlutterLocalNotificationsPlugin? _localNotifications;
  static StreamSubscription<QuerySnapshot>? _chatSubscription;
  static String? _currentUid;
  static String? _fcmToken;
  static Map<String, dynamic>? _pendingInitialMessage;

  static final Map<String, DateTime> _lastNotifiedPerChat = {};

  static Future<void> init() async {
    _localNotifications = FlutterLocalNotificationsPlugin();
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    await _localNotifications!.initialize(
      const InitializationSettings(android: androidSettings),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
    _localNotifications!
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    try {
      final messaging = FirebaseMessaging.instance;

      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      _fcmToken = await messaging.getToken();

      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        _pendingInitialMessage = initialMessage.data;
      }

      messaging.onTokenRefresh.listen((token) {
        _fcmToken = token;
        _updateTokenInFirestore(token);
      });

      FirebaseMessaging.onMessage.listen(_onForegroundMessage);

      FirebaseMessaging.onMessageOpenedApp.listen(_onBackgroundMessageOpened);
    } catch (e) {
      debugPrint('FCM init failed: $e');
    }
  }

  static void handlePendingInitialMessage() {
    if (_pendingInitialMessage != null) {
      _navigateToChat(_pendingInitialMessage!);
      _pendingInitialMessage = null;
    }
  }

  static String? getPushToken() => _fcmToken;

  static void _updateTokenInFirestore(String token) {
    if (_currentUid != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUid)
          .update({'pushToken': token});
    }
  }

  static void _onForegroundMessage(RemoteMessage message) {
    final data = message.data;
    final title = message.notification?.title ?? '';
    final body = message.notification?.body ?? '';

    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;

    NotificationBanner.show(
      ctx,
      title: title,
      body: body,
      chatId: data['chatId'],
      senderId: data['senderId'],
      onTap: (data['chatId'] != null && data['senderId'] != null)
          ? () => _navigateToChat(data)
          : null,
    );
  }

  static void _onBackgroundMessageOpened(RemoteMessage message) {
    final data = message.data;
    if (data['chatId'] != null) {
      _navigateToChat(data);
    }
  }

  static void startListening(String uid) {
    _currentUid = uid;
    _chatSubscription?.cancel();
    final db = FirebaseFirestore.instance;
    _chatSubscription = db
        .collection('chats')
        .where('participants', arrayContains: uid)
        .snapshots()
        .listen((snap) async {
      for (final change in snap.docChanges) {
        if (change.type == DocumentChangeType.modified) {
          final data = change.doc.data()!;
          final lastSender = data['lastMessageSender'] as String?;
          if (lastSender == null || lastSender == uid) continue;

          final chatId = change.doc.id;
          final lastMsg = data['lastMessage'] as String? ?? '';

          final now = DateTime.now();
          final lastNotified = _lastNotifiedPerChat[chatId];
          if (lastNotified != null &&
              now.difference(lastNotified).inSeconds < 3) {
            continue;
          }
          _lastNotifiedPerChat[chatId] = now;

          final userDoc = await db.collection('users').doc(lastSender).get();
          if (userDoc.exists) {
            final senderName = userDoc['name'] as String? ?? 'Unknown';
            _showLocalNotification(chatId, senderName, lastMsg);
          }
        }
      }
    });
  }

  static void _showLocalNotification(String chatId, String title, String body) {
    _localNotifications?.show(
      chatId.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'fschat_messages',
          'FSChat Messages',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: chatId,
    );
  }

  static void _onNotificationTap(NotificationResponse response) {
    final chatId = response.payload;
    if (chatId == null || navigatorKey.currentContext == null) return;
    navigatorKey.currentState?.pushNamed('/chat', arguments: {
      'chatId': chatId,
    });
  }

  static void _navigateToChat(Map<String, dynamic> data) {
    final chatId = data['chatId'] as String?;
    final senderId = data['senderId'] as String?;
    if (chatId == null || senderId == null) return;

    NavigatorState? nav;
    try {
      nav = navigatorKey.currentState;
    } catch (_) {}

    if (nav == null) {
      _pendingInitialMessage = {'chatId': chatId, 'senderId': senderId};
      return;
    }

    FirebaseFirestore.instance
        .collection('users')
        .doc(senderId)
        .get()
        .then((doc) {
      if (!doc.exists) {
        nav?.pushNamed('/chat', arguments: {'chatId': chatId});
        return;
      }
      final otherUser = ChatUser.fromMap(doc.data() as Map<String, dynamic>);
      nav?.pushNamed(
        '/chat',
        arguments: {'chatId': chatId, 'otherUser': otherUser},
      );
    });
  }
}
