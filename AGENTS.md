# FSChat — Project Context

## Stack
- **Framework**: Flutter 3.41.6 (stable)
- **Platforms**: Android (primary), iOS (configured)
- **Auth**: Firebase Email/Password
- **Database**: Cloud Firestore
- **Storage**: Firebase Storage (images, audio)
- **State management**: Provider
- **Push**: OneSignal SDK v5.5.7 + `flutter_local_notifications` (Huawei fallback)
- **Cloud Function**: Node.js 22 (2nd Gen) — `sendMessageNotification` triggers on new message, sends via OneSignal REST API

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
- **Theme**: WhatsApp-style green (#075E54), dark mode toggle in Settings

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
  main.dart                     — App entry point, routing, theme
  core/
    providers/
      theme_provider.dart       — Dark/light mode toggle with shared_preferences
    services/
      database_service.dart     — Firestore CRUD (users, chats, messages, media)
      notification_service.dart — OneSignal init + flutter_local_notifications fallback, Firestore listener for bg notifications
  features/
    auth/
      models/
        user_model.dart         — ChatUser model (pushToken, online, lastSeen)
      providers/
        auth_provider.dart      — Auth state management, online/offline lifecycle
      screens/
        login_screen.dart       — Login/register form with name field
      services/
        auth_service.dart       — Firebase auth (email/password sign in/up)
    chat/
      models/
        chat_model.dart         — Chat model with participants, pinned, lastMessage
        message_model.dart      — Message model with type, mediaUrl, duration, replyToId/Text, seenBy
      screens/
        chat_list_screen.dart   — Chat list with swipe-delete, long-press context menu (Pin/Delete), FAB new chat
        chat_screen.dart        — Message view: send, image/audio, reply, typing indicator, online status, context menu (Copy/Delete), @mentions
      widgets/
        chat_tile.dart          — Chat list item with online dot, pin icon, time formatting
        message_bubble.dart     — Bubble with text/image/audio, reply quote, mention highlighting
    settings/
      screens/
        about_screen.dart       — App info
        settings_screen.dart    — Profile editing, dark mode toggle, sign-out
  shared/
    models/
      menu_action.dart          — Reusable MenuAction model for context menus
```

## Key behaviors
- First-time user fills name + email + password → account created in Auth + Firestore
- Returning user just signs in with email + password
- Chat list shows all conversations ordered by last message time (pinned chats first)
- **Online status**: set to `true` on app start/foreground, `false` on background/sign-out via `WidgetsBindingObserver`. Green dot on avatar in chat list + "online"/"offline" in chat header. Updates live via `userStream`.
- **Typing indicator**: writes to `chats/{chatId}/typing/{uid}` on keystroke, auto-stops after 2s idle. Other user sees "typing..." in green below the name in chat AppBar.
- New chat: tap FAB → select contact → creates or opens existing chat
- Messages: send → seen indicators (single/double check) → auto-scroll
- Empty state shown when no conversations exist
- **Swipe to delete chat**: swipe left → confirm dialog → deletes chat + all messages
- **Long-press context menu (message)**: Copy text, Delete own message
- **Long-press context menu (chat list)**: Pin/Unpin, Delete chat
- **Swipe to reply**: swipe right on any message → reply bar appears above input
- **@mentions**: type `@` + name → suggestion strip above input → tap to insert highlighted mention
- **Adaptive input box**: expands up to 5 lines as you type
- **Profile editing**: tap avatar or name in Settings to change photo/name
- **Dark mode persistence**: saved to SharedPreferences, survives restarts

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
- Release build needs signing key configured
- iOS build requires Mac

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
| **Architecture refactor breaks imports** | Build fails with `Error when reading '...'` | Files were copied but imports still use old relative paths. Fix each moved file's imports to point to new locations. Common offenders: `notification_service.dart`, `chat_screen.dart`, `settings_screen.dart`, `chat_tile.dart`. |
| **`flutter analyze` crashes** | `PathNotFoundException: Directory listing failed, path = 'C:\tools\flutter\examples\*'` | Flutter 3.41.6 bug — missing `examples/` directory. Use `flutter build apk --debug` instead — it compiles all Dart and catches import/type errors. |

## To revisit later
- Configure Huawei Push Kit in OneSignal (Settings → Platforms → Huawei → enter HMS credentials)
- Once configured: rebuild APK, test push notifications on lock screen & background
- Add message reactions (infrastructure in place via MenuAction model)
- Group chats
