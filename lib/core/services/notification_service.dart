import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/models/user_model.dart';
import '../../shared/widgets/notification_banner.dart';

class NotificationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static FlutterLocalNotificationsPlugin? _localNotifications;
  static StreamSubscription<QuerySnapshot>? _chatSubscription;
  static StreamSubscription<QuerySnapshot>? _postSubscription;
  static String? _currentUid;
  static String? _fcmToken;
  static Map<String, dynamic>? _pendingInitialMessage;

  static final Map<String, DateTime> _lastNotifiedPerChat = {};

  static const String _channelChat = 'fschat_messages';
  static const String _channelReminders = 'fschat_reminders';
  static const String _channelAlerts = 'fschat_alerts';

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
      tz_data.initializeTimeZones();
    } catch (e) {
      debugPrint('Timezone init failed: $e');
    }

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
      _routeFromData(_pendingInitialMessage!);
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

    final type = data['type'] as String? ?? 'chat';
    VoidCallback? onTap;
    if (type == 'post') {
      onTap = () => _navigateToPost(data);
    } else if (type == 'challenge') {
      onTap = () => _navigateToGeneric('/challenges');
    } else if (data['chatId'] != null) {
      onTap = () => _navigateToChat(data);
    }

    NotificationBanner.show(
      ctx,
      title: title,
      body: body,
      onTap: onTap,
    );
  }

  static void _onBackgroundMessageOpened(RemoteMessage message) {
    _routeFromData(message.data);
  }

  static void _routeFromData(Map<String, dynamic> data) {
    final type = data['type'] as String? ?? 'chat';
    if (type == 'post') {
      _navigateToPost(data);
    } else if (type == 'challenge') {
      _navigateToGeneric('/challenges');
    } else if (data['chatId'] != null) {
      _navigateToChat(data);
    }
  }

  static void startListening(String uid) {
    _currentUid = uid;
    _chatSubscription?.cancel();
    _postSubscription?.cancel();
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
            final payload = jsonEncode({
              'type': 'chat',
              'chatId': chatId,
            });
            _showLocalNotification(
              chatId.hashCode,
              senderName,
              lastMsg,
              payload,
              senderName: senderName,
            );
          }
        }
      }
    });

    _postSubscription = db
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .listen((snap) async {
      for (final change in snap.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data == null) continue;
          final authorId = data['authorId'] as String?;
          if (authorId == null || authorId == uid) continue;

          final postId = change.doc.id;
          final authorName = data['authorName'] as String? ?? 'Someone';
          final title = data['title'] as String? ?? 'New journal entry';

          final now = DateTime.now();
          final lastNotified = _lastNotifiedPerChat['post_$postId'];
          if (lastNotified != null &&
              now.difference(lastNotified).inSeconds < 3) {
            continue;
          }
          _lastNotifiedPerChat['post_$postId'] = now;

          final payload = jsonEncode({
            'type': 'post',
            'postId': postId,
          });
          _showLocalNotification(
            'post_$postId'.hashCode,
            authorName,
            title,
            payload,
          );
        }
      }
    });
  }

  static Future<AndroidNotificationDetails> _androidDetails(
      String channelId, String channelName) async {
    final prefs = await SharedPreferences.getInstance();
    final sound = prefs.getString('notificationSound') ?? 'default';
    final vibrate = prefs.getBool('notificationVibrate') ?? true;
    final soundSrc = sound == 'default' ? null : sound;
    return AndroidNotificationDetails(
      channelId,
      channelName,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: soundSrc != null || vibrate,
      sound: soundSrc != null
          ? RawResourceAndroidNotificationSound(soundSrc)
          : null,
      enableVibration: vibrate,
    );
  }

  static void _showLocalNotification(
    int id,
    String title,
    String body,
    String payload, {
    String? senderName,
  }) async {
    final android = await _androidDetails(_channelChat, 'FSChat Messages');
    final prefs = await SharedPreferences.getInstance();
    final showPreview = prefs.getBool('messagePreview') ?? true;
    final displayBody = showPreview || senderName == null
        ? body
        : 'New message from $senderName';
    _localNotifications?.show(
      id,
      title,
      displayBody,
      NotificationDetails(android: android),
      payload: payload,
    );
  }

  static void _onNotificationTap(NotificationResponse response) {
    final rawPayload = response.payload;
    if (rawPayload == null || navigatorKey.currentContext == null) return;

    try {
      final decoded = jsonDecode(rawPayload) as Map<String, dynamic>;
      final type = decoded['type'] as String? ?? 'chat';

      switch (type) {
        case 'chat':
          final chatId = decoded['chatId'] as String?;
          if (chatId != null) {
            navigatorKey.currentState?.pushNamed('/chat', arguments: {
              'chatId': chatId,
            });
          }
          break;
        case 'post':
          final postId = decoded['postId'] as String?;
          if (postId != null) {
            navigatorKey.currentState?.pushNamed('/blog/post', arguments: {
              'postId': postId,
            });
          }
          break;
        case 'mood':
          navigatorKey.currentState?.pushNamed('/mood', arguments: {
            'date': decoded['date'],
          });
          break;
        default:
          final route = decoded['route'] as String? ?? '/habits';
          navigatorKey.currentState?.pushNamed(route);
      }
    } catch (_) {
      // Legacy plain-text payload — treat as chatId
      final chatId = rawPayload;
      navigatorKey.currentState?.pushNamed('/chat', arguments: {
        'chatId': chatId,
      });
    }
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

  static void _navigateToPost(Map<String, dynamic> data) {
    final postId = data['postId'] as String?;
    if (postId == null) return;
    navigatorKey.currentState?.pushNamed('/blog/post', arguments: {
      'postId': postId,
    });
  }

  static void _navigateToGeneric(String route) {
    navigatorKey.currentState?.pushNamed(route);
  }

  // ============ Scheduled Reminders ============

  static Future<void> scheduleDailyReminder({
    required String id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required String payload,
  }) async {
    await _cancelScheduledReminder(id);
    final location = tz.local;
    final now = tz.TZDateTime.now(location);
    var scheduledDate =
        tz.TZDateTime(location, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final android =
        await _androidDetails(_channelReminders, 'FSChat Reminders');
    await _localNotifications?.zonedSchedule(
      id.hashCode,
      title,
      body,
      scheduledDate,
      NotificationDetails(android: android),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  static Future<void> _cancelScheduledReminder(String id) async {
    await _localNotifications?.cancel(id.hashCode);
  }

  // == Habit reminder ==

  static Future<void> scheduleHabitReminder({
    required String habitId,
    required String habitName,
    required int hour,
    required int minute,
  }) async {
    final id = 'habit_reminder_$habitId';
    final payload = jsonEncode({
      'type': 'habit',
      'route': '/habits',
    });
    await scheduleDailyReminder(
      id: id,
      title: 'Habit Reminder',
      body: 'Time to: $habitName',
      hour: hour,
      minute: minute,
      payload: payload,
    );
  }

  static Future<void> cancelHabitReminder(String habitId) async {
    await _cancelScheduledReminder('habit_reminder_$habitId');
  }

  // == Mood reminder ==

  static Future<void> scheduleMoodReminder({
    required int hour,
    required int minute,
  }) async {
    final payload = jsonEncode({
      'type': 'mood',
      'route': '/mood',
      'date': DateTime.now().toIso8601String().substring(0, 10),
    });
    await scheduleDailyReminder(
      id: 'mood_reminder',
      title: 'Mood Check-in',
      body: 'How are you feeling today?',
      hour: hour,
      minute: minute,
      payload: payload,
    );
  }

  static Future<void> cancelMoodReminder() async {
    await _cancelScheduledReminder('mood_reminder');
  }

  // == Reading reminder ==

  static Future<void> scheduleReadingReminder({
    required int hour,
    required int minute,
  }) async {
    final payload = jsonEncode({
      'type': 'reading',
      'route': '/reading',
    });
    await scheduleDailyReminder(
      id: 'reading_reminder',
      title: 'Reading List',
      body: 'Time for today\'s reading',
      hour: hour,
      minute: minute,
      payload: payload,
    );
  }

  static Future<void> cancelReadingReminder() async {
    await _cancelScheduledReminder('reading_reminder');
  }

  // == Challenge deadline ==

  static Future<void> scheduleChallengeDeadline({
    required String challengeId,
    required String title,
    required DateTime endDate,
  }) async {
    final id = 'challenge_deadline_$challengeId';
    await _cancelScheduledReminder(id);
    final location = tz.local;
    final scheduleDate = endDate.subtract(const Duration(days: 1));
    if (scheduleDate.isBefore(DateTime.now())) return;

    final tzDate = tz.TZDateTime.from(scheduleDate, location);

    final payload = jsonEncode({
      'type': 'challenge',
      'route': '/challenges',
      'challengeId': challengeId,
    });

    final android =
        await _androidDetails(_channelReminders, 'FSChat Reminders');
    await _localNotifications?.zonedSchedule(
      id.hashCode,
      'Challenge Ending Soon',
      '"$title" ends tomorrow!',
      tzDate,
      NotificationDetails(android: android),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  static Future<void> cancelChallengeDeadline(String challengeId) async {
    await _cancelScheduledReminder('challenge_deadline_$challengeId');
  }

  // == Streak milestone ==

  static Future<void> showStreakMilestone({
    required String habitName,
    required int streak,
    required String habitId,
  }) async {
    final milestoneKey = 'streak_${habitId}_$streak';
    final payload = jsonEncode({
      'type': 'habit',
      'route': '/habits',
    });
    final android = await _androidDetails(_channelAlerts, 'FSChat Alerts');
    await _localNotifications?.show(
      milestoneKey.hashCode,
      '🔥 $streak-day Streak!',
      'You\'re on fire with "$habitName"! Keep it up!',
      NotificationDetails(android: android),
      payload: payload,
    );
  }

  // == Mood pattern alert ==

  static Future<void> showMoodPatternAlert() async {
    final payload = jsonEncode({
      'type': 'mood',
      'route': '/mood',
      'date': DateTime.now().toIso8601String().substring(0, 10),
    });
    final android = await _androidDetails(_channelAlerts, 'FSChat Alerts');
    await _localNotifications?.show(
      'mood_pattern_alert'.hashCode,
      'We noticed you\'ve been feeling down',
      'Want to check in? Tap to log your mood.',
      NotificationDetails(android: android),
      payload: payload,
    );
  }
}
