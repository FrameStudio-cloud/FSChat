# FSChat — Project Context

## Stack
- **Framework**: Flutter 3.41.6 (stable)
- **Platforms**: Android (primary), iOS (configured)
- **Auth**: Firebase Email/Password
- **Database**: Cloud Firestore
- **State management**: Provider
- **Push**: OneSignal SDK v5.5.7 (Huawei not configured → notifications only work in-app as snackbars)
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
- **To fix later**: enable Huawei platform in OneSignal Settings → need HMS credentials from Huawei Developer account

## App branding
- **Name**: FSChat (Frames Studio Chat)
- **Icon**: Green background (#075E54) with white "FS" text
- **Theme**: WhatsApp-style green (#075E54)

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
  models/
    user_model.dart             — ChatUser model (pushToken field)
    chat_model.dart             — Chat model with participants
    message_model.dart          — Message model with seenBy
  services/
    auth_service.dart           — Firebase auth (email/password sign in/up)
    database_service.dart       — Firestore CRUD (users, chats, messages)
    notification_service.dart   — OneSignal init, foreground snackbar, tap navigation
  providers/
    auth_provider.dart          — Auth state management, saves pushToken on sign-in
  screens/
    login_screen.dart           — Login/register form
    chat_list_screen.dart       — Chat list with search + online dots in dialog
    chat_screen.dart            — Message view with send/seen
  widgets/
    chat_tile.dart              — Chat list item (with online dot, time formatting)
    message_bubble.dart         — Individual message bubble
```

## Key behaviors
- First-time user fills name + email + password → account created in Auth + Firestore
- Returning user just signs in with email + password
- Chat list shows all conversations ordered by last message time
- **Online status**: set to `true` on app start/foreground, `false` on background/sign-out via `WidgetsBindingObserver`. Green dot on avatar in chat list + "online"/"offline" in chat header. Updates live via `userStream`.
- **Typing indicator**: writes to `chats/{chatId}/typing/{uid}` on keystroke, auto-stops after 2s idle. Other user sees "typing..." in green below the name in chat AppBar.
- New chat: tap FAB → select contact → creates or opens existing chat
- Messages: send → seen indicators (single/double check) → auto-scroll
- Empty state shown when no conversations exist

## Demo accounts
- `demo@fschat.com` / `demo123` — main test user
- `mwendeashley920@gmail.com` — Ashley Mwende (used as sender in tests)
- `lewisirungu489@gmail.com` — Lewis irungu

## Cloud Function
- **Deployed name**: `sendMessageNotification` (2nd Gen, Node.js 22)
- **Trigger**: Firestore `chats/{chatId}/messages/{messageId}` on create
- **Behavior**: reads sender name, gets recipient's `pushToken`, sends via OneSignal API
- **Secrets**: `ONESIGNAL_REST_KEY` in `functions/.env`

## Known limitations
- **Push notifications**: Huawei Push Kit not configured → no bg/lock-screen notifications on this phone. Foreground snackbars work.
- Release build needs signing key configured
- iOS build requires Mac

## To revisit later
- Configure Huawei Push Kit in OneSignal (Settings → Platforms → Huawei → enter HMS credentials)
- Once configured: rebuild APK, test push notifications on lock screen & background
