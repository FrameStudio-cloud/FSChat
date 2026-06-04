import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class NotificationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static Future<void> init(String appId) async {
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    await OneSignal.initialize(appId);

    await OneSignal.Notifications.requestPermission(true);

    OneSignal.Notifications.addClickListener((event) {
      final data = event.notification.additionalData;
      if (data != null && data['chatId'] != null) {
        _navigateToChat(data);
      }
    });

    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      final data = event.notification.additionalData ?? {};
      final title = event.notification.title ?? '';
      final body = event.notification.body ?? '';

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
      event.preventDefault();
    });
  }

  static String? getUserId() {
    return OneSignal.User.pushSubscription.id;
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
