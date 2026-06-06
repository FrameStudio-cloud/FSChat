# FSChat — Project Context (Updated 2026-06-07)

## Architecture overview
- **Navigation**: BottomNavigationBar with 3 tabs (Chats, Calls, Contacts), managed by HomeScreen
- **Wallpaper**: local-only, stores compressed image in `{docDir}/fschat/wallpapers/current.jpg` or solid color HEX in SharedPreferences
- **Online/offline**: Firestore `online` bool + `lastSeen` timestamp, updated via WidgetsBindingObserver lifecycle hooks (resumed → online, paused → offline)
- **UserInfoScreen**: accessible by tapping avatar/name in chat header — shows photo, bio, email, online status, action buttons (Voice/Video/Message — call buttons are placeholders), shared media gallery with swipeable PageView, Clear chat, Block user

## Stack
- **Framework**: Flutter 3.41.6 (stable), Dart 3.11.4
- **Platforms**: Android (primary), iOS (configured)
- **Auth**: Firebase Email/Password
- **Database**: Cloud Firestore
- **Storage**: Firebase Storage (images, audio)
- **State management**: Provider
- **Push**: OneSignal SDK v5.5.7 + `flutter_local_notifications` (Huawei fallback)
- **Local storage**: path_provider + flutter_image_compress (wallpapers, cache)
- **Cloud Function**: Node.js 22 (2nd Gen) — `sendMessageNotification` triggers on new message, sends via OneSignal REST API

## Key packages
- `onesignal_flutter: ^5.2.0` — push notifications
- `flutter_local_notifications: ^18.0.1` — local notification fallback (Huawei)
- `path_provider: ^2.1.5` — app documents directory for wallpapers/cache
- `flutter_image_compress: ^2.4.0` — compress wallpaper images before saving
- `just_audio: ^0.9.42` — voice message playback
- `record: ^5.1.2` — voice message recording
- `image_picker: ^1.1.2` — gallery/camera for images and wallpapers
- `provider: ^6.1.2` — state management
- `shared_preferences: ^2.2.2` — theme + wallpaper persistence
- `cloud_firestore: ^5.6.12` — real-time data
- `firebase_storage: ^12.3.7` — media uploads
- `firebase_auth: ^5.5.0` — authentication

## Project location
`C:\Users\Administrator\OneDrive\Dokumenter\whatsapp_clone`

## Firebase
- **Project**: `whatsapp-clone-79f5c`
- **Auth enabled**: Email/Password
- **Android package**: `com.yourapp.whatsapp_clone`
- **iOS bundle**: `com.yourapp.whatsappClone`
- **Web client ID**: `834309171417-tj0rk47s872vqmppeje5vf3tj42ivjta.apps.googleusercontent.com`
- **Firebase config files**: `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`
- **Debug SHA-1 fingerprint**: `C7:C2:CE:1A:4E:32:E8:5D:E4:44:E3:EA:57:B2:47:73:7E:D3:7C:1D`

## OneSignal
- **App ID**: `7f9abadb-2c15-4019-80c6-a6d2393dc282`
- **REST API Key**: set as env var `ONESIGNAL_REST_KEY` (in `functions/.env`)
- **Status**: Huawei Push Kit NOT configured → system/bg notifications don't deliver on Huawei
- **To fix later**: enable Huawei Platform in OneSignal Settings → need HMS credentials from Huawei Developer account

## App branding
- **Name**: FSChat (Frames Studio Chat)
- **Icon**: Green background (#075E54) with white "FS" text
- **Theme**: WhatsApp-style green (#075E54), dark mode toggle in Settings (persisted via SharedPreferences)
- **Wallpaper**: custom wallpaper per session (colors or local image, stored in app documents dir)

## Flutter SDK
- **Location**: `C:\tools\flutter`
- **Path added**: `C:\tools\flutter\bin` (user PATH)
- **Java JDK**: `C:\Program Files\Eclipse Adoptium\jdk-17.0.19.10-hotspot`
- **Android SDK**: `C:\Users\Administrator\AppData\Local\Android\Sdk`

## Build commands
```powershell
$env:Path = "C:\tools\flutter\bin\;$env:JAVA_HOME\bin;$env:Path"
$env:JAVA_HOME = "C:\Program Files\Eclipse Adoptium\jdk-17.0.19.10-hotspot"
$env:ANDROID_HOME = "C:\Users\Administrator\AppData\Local\Android\Sdk"
cd ~\OneDrive\Dokumenter\whatsapp_clone
flutter build apk --debug
```

## APK output
`build\app\outputs\flutter-apk\app-debug.apk`

## Project structure
```
lib/
  main.dart                     — App entry point, routing, theme, SplashApp
  core/
    providers/
      theme_provider.dart       — Dark/light mode + wallpaper (SharedPreferences + local file)
    services/
      database_service.dart     — Firestore CRUD (users, chats, messages, media, block, clear)
      notification_service.dart — OneSignal init + flutter_local_notifications fallback, Firestore listener for bg notifications
      local_storage_service.dart — App dirs, wallpaper save/remove, cache
  features/
    auth/
      models/
        user_model.dart         — ChatUser (uid, name, photoUrl, email, bio, lastSeen, online, pushToken)
      providers/
        auth_provider.dart      — Auth state, online/offline via WidgetsBindingObserver, _ensureUserExists
      screens/
        login_screen.dart       — Login/register form with name field
      services/
        auth_service.dart       — Firebase auth (email/password sign in/up)
    chat/
      models/
        chat_model.dart         — Chat (id, participants, lastMessage, lastMessageTime, lastMessageSender, pinned)
        message_model.dart      — Message (id, senderId, text, type, mediaUrl, duration, replyToId, replyToText, seenBy, timestamp)
      screens/
        chat_list_screen.dart   — Chat list with swipe-delete, long-press menu, FAB new chat
        chat_screen.dart        — Message view: send text/image/audio, reply, @mentions, typing, online, wallpaper picker
        user_info_screen.dart   — Contact info: photo, bio, email, online, Voice/Video/Message buttons, shared media, clear/block
      widgets/
        chat_tile.dart          — Chat list item with online dot, pin icon, time formatting
        message_bubble.dart     — Bubble with text/image/audio, reply quote, mention highlighting
    home/
      screens/
        home_screen.dart        — BottomNavigationBar with 3 tabs: Chats, Calls, Contacts
    calls/
      screens/
        call_log_screen.dart    — Shell: empty state, no call history yet
    contacts/
      screens/
        contacts_screen.dart    — All users list with search + online dots, tap to start chat
    settings/
      screens/
        about_screen.dart       — App info with feature list
        settings_screen.dart    — Profile (name, photo, bio), dark mode toggle, About, sign-out
  shared/
    models/
      menu_action.dart          — Reusable MenuAction model for context menus
```

## Key behaviors
- First-time user fills name + email + password → account created in Auth + Firestore with default bio "Hey there! I am using FSChat"
- Returning user just signs in with email + password; email and bio backfilled if missing
- Chat list shows all conversations ordered by last message time (pinned chats first)
- **Online status**: set to `true` on app start/foreground, `false` on background/sign-out via `WidgetsBindingObserver`. Green dot on avatar in chat list + "online"/"offline" in chat header. Updates live via `userStream`.
- **Typing indicator**: writes to `chats/{chatId}/typing/{uid}` on keystroke, auto-stops after 2s idle. Other user sees "typing..." in green below the name in chat AppBar.
- New chat: tap FAB → select contact → creates or opens existing chat
- Messages: send → seen indicators (single/double check) → auto-scroll
- Empty state shown when no conversations exist
- **Swipe to delete chat**: swipe left → confirm dialog → deletes chat + all messages
- **Long-press context menu (message)**: Copy text, Delete own message
- **Long-press context menu (chat list)**: Pin/Unpin, Delete chat (via bottom sheet)
- **Swipe to reply**: swipe right on any message → reply bar appears above input. Clears after every send (text, image, voice).
- **@mentions**: type `@` + name → suggestion strip above input → tap to insert highlighted mention
- **Adaptive input box**: expands up to 5 lines as you type
- **Profile editing**: tap avatar or name in Settings to change photo/name; bio editable in Settings card
- **Dark mode persistence**: ThemeProvider loaded via ChangeNotifierProvider.value in main.dart (single instance), survives restarts
- **Wallpaper**: tap wallpaper icon in chat AppBar → bottom sheet: No wallpaper, 7 color swatches, or Choose from gallery. Image compressed (70%, 1080x1920) and saved to `{docDir}/fschat/wallpapers/current.jpg`. Rendered via Consumer<ThemeProvider> behind message list.
- **UserInfoScreen**: tap avatar or name in chat header → large photo (tappable for fullscreen Hero), bio, email, online/last seen, action buttons (Voice/Video placeholder snackbars, Message pops back), shared media horizontal scroll (images open in swipeable PageView), Clear chat, Block user.
- **Contacts tab**: lists all registered users with search bar + online dots, tap to open chat directly.

## Demo accounts
- `demo@fschat.com` / `demo123` — main test user
- `mwendeashley920@gmail.com` — Ashley Mwende (used as sender in tests)
- `lewisirungu489@gmail.com` — Lewis irungu

## Cloud Function
- **Deployed name**: `sendMessageNotification` (2nd Gen, Node.js 22)
- **Trigger**: Firestore `chats/{chatId}/messages/{messageId}` on create
- **Behavior**: reads sender name, gets recipient's `pushToken`, sends via OneSignal API
- **Secrets**: `ONESIGNAL_REST_KEY` in `functions/.env`

## Media support
- **Images**: pick from camera/gallery → preview → upload to Firebase Storage → inline display with tap-to-fullscreen
- **Audio**: hold mic → recording bar with timer → release → upload `.m4a` → playback with play/pause + progress slider
- Audio playback uses `just_audio` package
- Image viewing uses `InteractiveViewer` for pinch-to-zoom

## Known limitations
- **Push notifications**: Huawei Push Kit not configured → no bg/lock-screen notifications on this phone. Foreground snackbars + local notification fallback.
- **NavigationService.navigatorKey not wired** → tapping notification to open chat may crash (ChatScreen expects otherUser)
- **Cloud Function uses legacy OneSignal API** — `include_subscription_ids` with raw pushToken (vs external_user_id)
- Release build needs signing key configured
- iOS build requires Mac

## Bugs fixed
- **Dark mode not persisting**: ThemeProvider was instantiated twice (once in `_init()`, once in `MultiProvider`). Fixed: use `ChangeNotifierProvider.value` with the loaded instance. `main.dart:60`.
- **Reply stale on image/voice send**: `_replyingTo` only cleared in `_sendMessage()`. Fixed: capture to local var + clear before await in `_sendMessage`, `_pickImage`, and `_stopRecordingAndSend`. `chat_screen.dart`.
- **All users show online permanently**: No `WidgetsBindingObserver` → online never set to false on background. Fixed: `AuthProvider` now extends `ChangeNotifier with WidgetsBindingObserver`, flips online in `didChangeAppLifecycleState`. `auth_provider.dart`.

## Common Issues & Fixes

| Issue | Symptom | Fix |
|-------|---------|-----|
| **Black screen on Huawei** | App installs but shows black/blank screen | `android/app/src/main/kotlin/.../MainActivity.kt`: override `configureFlutterEngine` with `flutterEngine.dartExecutor.binaryMessenger` + `PlatformAndroidRenderer` set to `renderMode: PlatformRenderMode.texture`. Add `<meta-data android:name="EnableImpeller" android:value="false" />` in `AndroidManifest.xml` under `<application>`. |
| **Record package build fails** | `record` package fails to compile | Add `dependency_overrides: record_platform_interface: 1.2.0` to `pubspec.yaml`. Compatible with `record: ^5.2.0` on Flutter 3.41.6. |
| **flutter_local_notifications build fails** | `coreLibraryDesugaringEnabled` required | `android/app/build.gradle.kts`: add `isCoreLibraryDesugaringEnabled = true` in `compileOptions` and `coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")` in `dependencies`. |
| **"User" shown instead of name** | Chat header or list shows "User" for known contacts | `auth_provider.dart:_ensureUserExists()` — update Firestore `name` field on every sign-in if `auth.currentUser?.displayName` differs from stored name. |
| **Screen flickers during recording** | Full screen rebuilds every second while recording | Extract `_RecordingBar` into its own `StatefulWidget` with its own `Timer` so `setState` doesn't cascade to parent. |
| **Chat blinks/flashes on message** | Message list flickers when new message arrives or keyboard opens | Extract `StreamBuilder<List<Message>>` into its own `_MessageList` widget isolate rebuild scope from keyboard/recording bar changes. |
| **Chat scrolls to top randomly** | ListView jumps to top when typing or recording | Switch from `reverse: false` + manual `scrollController.animateTo(0)` to `reverse: true` on `ListView.builder`. Anchors bottom automatically. |
| **Send/mic button doesn't swap** | Mic icon stays when text is entered (or vice versa) | Wrap send/mic row in `ValueListenableBuilder<TextEditingValue>` listening to `_textController`. Only the button row rebuilds, not the whole screen. |
| **Dark mode unreadable text** | White text on light bubble or vice versa in dark mode | Use theme-aware colors: `Theme.of(context).brightness == Brightness.dark` for bubble backgrounds, timestamps, seen icons, and audio controls. |
| **Image send fails silently** | Selected image doesn't send; no error shown | Enable Firebase Storage in Firebase Console (Storage → Get Started → set rules). Add try/catch with `SnackBar` in `chat_screen.dart:_sendImage()`. |
| **App won't install — permissions** | `adb install` fails with INSTALL_FAILED_PERMISSION | Remove `CAMERA` and `READ_EXTERNAL_STORAGE` from `AndroidManifest.xml`. Install with `adb install -r -g` to auto-grant remaining permissions (RECORD_AUDIO). |
| **All users show as online** | Every contact shows green dot even when offline | `AuthProvider` was missing `WidgetsBindingObserver`. Set `online: false` in `didChangeAppLifecycleState(paused)` — see `auth_provider.dart`. |
| **Dark mode resets on restart** | Theme always starts in light mode | ThemeProvider created twice in `main.dart`. Use `ChangeNotifierProvider.value` with the preloaded instance. |
| **Reply leaks to next message** | Old reply quote appears on subsequent sends | `_replyingTo` not cleared in `_pickImage()` or `_stopRecordingAndSend()`. Fixed: capture to local var + setState null before await in all send methods. |
| **flutter_image_compress build fails** | Missing package | Run `flutter pub get` after adding `flutter_image_compress: ^2.4.0` to pubspec.yaml. |
| **Architecture refactor breaks imports** | Build fails with `Error when reading '...'` | Files were copied but imports still use old relative paths. Fix each moved file's imports to point to new locations. Common offenders: `notification_service.dart`, `chat_screen.dart`, `settings_screen.dart`, `chat_tile.dart`. |
| **`flutter analyze` crashes** | `PathNotFoundException: Directory listing failed, path = 'C:\tools\flutter\examples\*'` | Flutter 3.41.6 bug — missing `examples/` directory. Use `flutter build apk --debug` instead — it compiles all Dart and catches import/type errors. |

## To revisit later
- Configure Huawei Push Kit in OneSignal (Settings → Platforms → Huawei → enter HMS credentials)
- Once configured: rebuild APK, test push notifications on lock screen & background
- Add message reactions (infrastructure in place via MenuAction model)
- Group chats
