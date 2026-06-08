import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/auth/models/user_model.dart';

class NotificationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static FlutterLocalNotificationsPlugin? _localNotifications;
  static StreamSubscription<QuerySnapshot>? _chatSubscription;
  static String? _fcmToken;

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

      messaging.onTokenRefresh.listen((token) {
        _fcmToken = token;
      });

      FirebaseMessaging.onMessage.listen(_onForegroundMessage);

      FirebaseMessaging.onMessageOpenedApp.listen(_onBackgroundMessageOpened);
    } catch (e) {
      debugPrint('FCM init failed: $e');
    }
  }

  static String? getPushToken() => _fcmToken;

  static void _onForegroundMessage(RemoteMessage message) {
    final data = message.data;
    final title = message.notification?.title ?? '';
    final body = message.notification?.body ?? '';

    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;

    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text('$title: $body'),
        duration: const Duration(seconds: 4),
        action: data['chatId'] != null
            ? SnackBarAction(
                label: 'Open',
                onPressed: () => _navigateToChat(data),
              )
            : null,
      ),
    );
  }

  static void _onBackgroundMessageOpened(RemoteMessage message) {
    final data = message.data;
    if (data['chatId'] != null) {
      _navigateToChat(data);
    }
  }

  static void startListening(String uid) {
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
          if (lastSender != null && lastSender != uid) {
            final lastMsg = data['lastMessage'] as String? ?? '';
            final chatId = change.doc.id;
            final userDoc = await db.collection('users').doc(lastSender).get();
            if (userDoc.exists) {
              final senderName = userDoc['name'] as String? ?? 'Unknown';
              _showLocalNotification(chatId, senderName, lastMsg);
            }
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
    if (chatId != null && navigatorKey.currentContext != null) {
      navigatorKey.currentState?.pushNamed('/chat', arguments: {
        'chatId': chatId,
      });
    }
  }

  static void _navigateToChat(Map<String, dynamic> data) {
    final chatId = data['chatId'] as String?;
    final senderId = data['senderId'] as String?;
    if (chatId == null || senderId == null) return;

    FirebaseFirestore.instance
        .collection('users')
        .doc(senderId)
        .get()
        .then((doc) {
      if (!doc.exists) return;
      final otherUser = ChatUser.fromMap(doc.data() as Map<String, dynamic>);
      navigatorKey.currentState?.pushNamed(
        '/chat',
        arguments: {'chatId': chatId, 'otherUser': otherUser},
      );
    });
  }
}
