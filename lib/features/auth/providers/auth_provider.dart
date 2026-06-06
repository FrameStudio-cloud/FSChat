import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/notification_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier with WidgetsBindingObserver {
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();

  User? _user;
  ChatUser? _chatUser;
  bool _loading = true;

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<ChatUser?>? _userSubscription;

  User? get user => _user;
  ChatUser? get chatUser => _chatUser;
  bool get loading => _loading;
  bool get isSignedIn => _user != null;

  AuthProvider() {
    WidgetsBinding.instance.addObserver(this);
    _authSubscription = _authService.authState.listen(_onAuthStateChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSubscription?.cancel();
    _userSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setOnline();
    } else if (state == AppLifecycleState.paused) {
      setOffline();
    }
  }

  void _onAuthStateChanged(User? user) {
    _userSubscription?.cancel();
    _userSubscription = null;
    _user = user;
    if (user != null) {
      setOnline().catchError((_) {});
      NotificationService.startListening(user.uid);
      _userSubscription =
          _databaseService.userStream(user.uid).listen((chatUser) {
        _chatUser = chatUser;
        notifyListeners();
      });
      _loading = false;
      notifyListeners();
    } else {
      _chatUser = null;
      _loading = false;
      notifyListeners();
    }
  }

  Future<String?> signIn(String email, String password) async {
    _loading = true;
    notifyListeners();

    try {
      final credential = await _authService.signInWithEmail(email, password);
      final user = credential.user!;
      await _ensureUserExists(user);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Sign in failed';
    } catch (e) {
      return e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<String?> signUp(String email, String password, String name) async {
    _loading = true;
    notifyListeners();

    try {
      final credential = await _authService.signUp(email, password);
      final user = credential.user!;
      await user.updateDisplayName(name);
      await _ensureUserExists(user, name);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Registration failed';
    } catch (e) {
      return e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _ensureUserExists(User user, [String? displayName]) async {
    final existing = await _databaseService.getUser(user.uid);
    String? pushToken;
    try {
      pushToken = NotificationService.getUserId();
    } catch (_) {}

    final name = displayName ?? user.displayName;
    if (existing == null) {
      await _databaseService.createUser(ChatUser(
        uid: user.uid,
        name: name ?? 'User',
        photoUrl: user.photoURL ?? '',
        email: user.email ?? '',
        bio: 'Hey there! I am using FSChat',
        pushToken: pushToken,
      ));
    } else {
      if (pushToken != null) {
        await _databaseService.updatePushToken(user.uid, pushToken);
      }
      if (name != null && name != existing.name) {
        await _databaseService.updateName(user.uid, name);
      }
      if (existing.email.isEmpty && user.email != null) {
        await _databaseService.updateEmail(user.uid, user.email!);
      }
      if (existing.bio.isEmpty) {
        await _databaseService.updateBio(
            user.uid, 'Hey there! I am using FSChat');
      }
    }
  }

  Future<void> signOut() async {
    await setOffline();
    await _authService.signOut();
    _user = null;
    _chatUser = null;
    notifyListeners();
  }

  Future<void> setOnline() async {
    if (_user != null) {
      await _databaseService.updateOnlineStatus(_user!.uid, true);
    }
  }

  Future<void> setOffline() async {
    if (_user != null) {
      await _databaseService.updateOnlineStatus(_user!.uid, false);
    }
  }
}
