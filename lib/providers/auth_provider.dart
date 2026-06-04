import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
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
    _authSubscription = _authService.authState.listen(_onAuthStateChanged);
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _userSubscription?.cancel();
    super.dispose();
  }

  void _onAuthStateChanged(User? user) {
    _userSubscription?.cancel();
    _userSubscription = null;
    _user = user;
    if (user != null) {
      setOnline().catchError((_) {});
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
        pushToken: pushToken,
      ));
    } else {
      if (pushToken != null) {
        await _databaseService.updatePushToken(user.uid, pushToken);
      }
      if (name != null && name != existing.name) {
        await _databaseService.updateName(user.uid, name);
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
