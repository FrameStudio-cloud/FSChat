# FSChat — Project Context (Updated 2026-06-20)

## Architecture overview
- **Navigation**: BottomNavigationBar with 3 tabs (Chats, Calls, Contacts), managed by HomeScreen. Spring-animated with ScaleTransition on icon swap.
- **Wallpaper**: local-only, accessible from Settings → Wallpaper. Stores compressed image in `{docDir}/fschat/wallpapers/current.jpg` or solid color HEX in SharedPreferences.
- **Online/offline**: Firestore `online` bool + `lastSeen` timestamp, updated via WidgetsBindingObserver lifecycle hooks (resumed → online, paused → offline)
- **UserInfoScreen**: accessible by tapping avatar/name in chat header — shows photo, bio, email, online status, action buttons (Voice/Video/Message — call buttons are placeholders), shared media gallery with swipeable PageView, Clear chat, Block user
- **Theme system**: `AppColors` named tokens in `lib/core/theme/app_colors.dart`, `BubbleStyle` ThemeExtension + `AppTheme` in `app_theme.dart`

## Stack
- **Framework**: Flutter 3.41.6 (stable), Dart 3.11.4
- **Platforms**: Android (primary), iOS (configured)
- **Auth**: Firebase Email/Password
- **Database**: Cloud Firestore
- **Storage**: Firebase Storage (images, audio, stickers)
- **State management**: Provider
- **Push**: Firebase Cloud Messaging (FCM) + `flutter_local_notifications` (foreground/local fallback)
- **Local storage**: path_provider + flutter_image_compress (wallpapers, stickers, cache)
- **Cloud Function**: Node.js 22 (2nd Gen) — `sendMessageNotification` triggers on new message, sends via FCM `admin.messaging().send()`

## Key packages
- `firebase_messaging: ^15.2.0` — FCM push notifications
- `flutter_local_notifications: ^18.0.1` — foreground notification display
- `path_provider: ^2.1.5` — app documents directory for wallpapers/cache
- `flutter_image_compress: ^2.4.0` — compress wallpaper/sticker images before saving
- `just_audio: ^0.9.42` — voice message playback
- `record: ^5.1.2` — voice message recording
- `image_picker: ^1.1.2` — gallery/camera for images and wallpapers
- `provider: ^6.1.2` — state management
- `shared_preferences: ^2.2.2` — theme + wallpaper + tip index persistence
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

## Push Notifications (FCM)
- **Removed**: OneSignal SDK replaced with `firebase_messaging` + FCM
- **Cloud Function**: sends via `admin.messaging().send()` directly (no third-party API)
- **Huawei**: FCM doesn't work without Google Play Services → foreground notifications fallback via `flutter_local_notifications` Firestore listener
- **Cold-start handling**: `getInitialMessage()` stores pending notification data, `handlePendingInitialMessage()` navigates via `addPostFrameCallback`
- **Duplicate prevention**: 3-second `_lastNotifiedPerChat` debounce map prevents FCM + Firestore listener double-firing

## App branding
- **Name**: FSChat (Frames Studio Chat)
- **Icon**: Orange background (#E65100) with white "FS" text
- **Theme**: Brand orange (`AppColors.brand` = `#E65100`), dark mode toggle in Settings → Appearance
- **Wallpaper**: custom wallpaper per session, managed from Settings → Wallpaper

## Theme System
- `lib/core/theme/app_colors.dart` — Named color constants: `brand` (#E65100), `brandLight`, `brandDark`, `online` (#25D366), `ownBubbleLight`/`ownBubbleDark`, `otherBubbleLight`/`otherBubbleDark`, `surfaceDark`, `inputDark`
- `lib/core/theme/app_theme.dart` — `BubbleStyle` ThemeExtension (own/other corner radii, shadows, gradients). `AppTheme.light` / `AppTheme.dark` replaces raw `ThemeData(colorSchemeSeed:)`.
- Used by `message_bubble.dart` for gradient own bubbles, `_BubbleTailPainter`, and `chat_screen.dart`.

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
  main.dart                     — App entry point, routing, AppTheme, SplashApp + notification postFrameCallback
  core/
    theme/
      app_colors.dart           — Named color tokens (brand orange, online green, bubble greens, etc.)
      app_theme.dart            — BubbleStyle ThemeExtension + AppTheme.light / AppTheme.dark
    providers/
      theme_provider.dart       — Dark/light mode + wallpaper (SharedPreferences + local file)
    services/
      database_service.dart     — Firestore CRUD (users, chats, messages, media, block, clear, archive, uploadSticker)
      notification_service.dart — FCM init + flutter_local_notifications, cold-start/debounce/navigator fallback
      local_storage_service.dart — App dirs, wallpaper save/remove, stickers save/list, cache
      tip_service.dart          — Tip of the day (snackbar on chat open — removed, now only in About page)
      isar_service.dart         — Isar local database (reading list, habits)
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
        chat_model.dart         — Chat (id, participants, lastMessage, lastMessageTime, lastMessageSender, pinned, archived)
        message_model.dart      — Message (id, senderId, text, type, mediaUrl, duration, replyToId, replyToText, seenBy, timestamp, reactions)
        sticker_model.dart      — StickerPack / Sticker models (packId, localPath, remoteUrl, tags)
      screens/
        chat_list_screen.dart   — Chat list with swipe-delete, long-press menu, FAB new chat, three-dot overflow menu
        chat_screen.dart        — Message view: send text/image/audio/sticker, reply, @mentions, typing, online, wallpaper
        user_info_screen.dart   — Contact info: photo, bio, email, online, Voice/Video/Message buttons, shared media, clear/block
        create_group_screen.dart — New group creation
        sticker_creator_screen.dart — Create custom stickers from gallery photos
      services/
        sticker_service.dart     — Singleton: built-in + custom sticker packs, render built-in to PNG, preview
      widgets/
        chat_tile.dart          — Chat list item with online dot, pin icon, time formatting
        message_bubble.dart     — Bubble with text/image/audio/sticker, reply quote, mention highlighting, gradient + tail painter
        sticker_picker.dart     — Bottom sheet: pack bar + grid, built-in and custom stickers
        sticker_suggestion_bar.dart — Inline horizontal sticker suggestions from typed keywords (cached queries)
        reaction_bar.dart       — Emoji reaction picker
        reaction_display.dart   — Show reactions on messages
    home/
      screens/
        home_screen.dart        — BottomNavigationBar (spring-animated, scale transitions) with 3 tabs
    calls/
      screens/
        call_log_screen.dart    — Shell: empty state, no call history yet
    contacts/
      screens/
        contacts_screen.dart    — All users list with search + online dots, tap to start chat
    settings/
      screens/
        about_screen.dart       — App info: version, features grid, collapsible tips, tech stack chips, GitHub links
        settings_screen.dart    — Cover-style profile banner, grouped sections (Appearance/Wallpaper, Notifications, Chats, Privacy, Account)
    habits/
      data/datasources/         — HabitLocalSource (Isar), HabitRemoteSource
      data/models/              — HabitModel, HabitLogModel (with Isar generated files)
      data/repositories/        — HabitRepository
      domain/                   — HabitNotifier
      presentation/screens/     — HabitsListScreen, HabitEditorScreen
      presentation/widgets/     — HabitTile, StreakCalendar, HeatmapPainter, DailyNoteDialog
    reading_list/
      data/datasources/         — BookLocalSource (Isar)
      data/models/              — BookModel (with Isar generated files)
      domain/                   — BookNotifier
      presentation/screens/     — ReadingListScreen, ReadingEditorScreen
      presentation/widgets/     — StarRating
    blog/
      models/                   — PostModel, CommentModel
      providers/                — BlogProvider
      screens/                  — BlogListScreen, BlogPostScreen, BlogEditorScreen
      widgets/                  — PostCard, CommentSection, TagChipRow
    mood/
      models/                   — MoodEntry
      screens/                  — MoodListScreen, MoodEditorScreen
    challenges/
      models/                   — ChallengeModel, ChallengeProgress
      screens/                  — ChallengesListScreen, ChallengeDetailScreen, ChallengeEditorScreen
    tools/
      screens/                  — ToolsScreen
  shared/
    models/
      menu_action.dart          — Reusable MenuAction model for context menus
    utils/
      avatar_helper.dart        — CircleAvatar with DiceBear fallback
      gallery_saver.dart        — Save images to device gallery
    widgets/
      image_editor_screen.dart  — Crop, rotate, draw on images before sending
      notification_banner.dart  — In-app notification banner widget
```

## Key behaviors
- First-time user fills name + email + password → account created in Auth + Firestore with default bio "Hey there! I am using FSChat"
- Returning user just signs in with email + password; email and bio backfilled if missing
- Chat list shows all conversations ordered by last message time (pinned chats first, archived chats hidden)
- Chat list three-dot overflow menu: Settings, Archive (shows snackbar "No archived chats"), Mark all read (batch update)
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
- **Sticker suggestions**: type a word ≥ 2 chars → horizontal bar with matching stickers by tag (cached query results)
- **Adaptive input box**: expands up to 5 lines as you type
- **Profile editing**: cover-style banner in Settings with gradient, avatar + camera overlay, tappable name/bio
- **Dark mode persistence**: ThemeProvider loaded via ChangeNotifierProvider.value in main.dart (single instance), survives restarts
- **Wallpaper**: managed from Settings → Appearance → Wallpaper. Bottom sheet: No wallpaper, 7 color swatches, or Choose from gallery. Image compressed (70%, 1080x1920) and saved to `{docDir}/fschat/wallpapers/current.jpg`. Rendered via Consumer<ThemeProvider> behind message list.
- **UserInfoScreen**: tap avatar or name in chat header → large photo (tappable for fullscreen Hero), bio, email, online/last seen, action buttons (Voice/Video placeholder snackbars, Message pops back), shared media horizontal scroll (images open in swipeable PageView), Clear chat, Block user.
- **Contacts tab**: lists all registered users with search bar + online dots, tap to open chat directly.

## Stickers
- **Built-in packs**: "Wave" (10 stickers) and "Reactions" (8 stickers) — each sticker has tags for keyword matching
- **Custom stickers**: created via Sticker Creator (gallery → crop to 256×256 → save as .jpg to `{appDir}/fschat/stickers/my_stickers/`)
- **Sending**: built-in stickers rendered as 256×256 PNG via `ui.PictureRecorder`, custom stickers uploaded from local file, both uploaded to Firebase Storage as PNG and stored as `type: 'sticker'` Firestore message
- **Picker**: modal bottom sheet with pack bar + grid, plus inline suggestion bar from text input
- **Local storage**: `{appDir}/fschat/stickers/{packId}/{stickerId}.jpg`

## Demo accounts
- `demo@fschat.com` / `demo123` — main test user
- `mwendeashley920@gmail.com` — Ashley Mwende (used as sender in tests)
- `lewisirungu489@gmail.com` — Lewis irungu

## Cloud Function
- **Deployed name**: `sendMessageNotification` (2nd Gen, Node.js 22)
- **Trigger**: Firestore `chats/{chatId}/messages/{messageId}` on create
- **Behavior**: reads sender name, gets recipient's `pushToken`, sends via FCM `admin.messaging().send()`
- **Secrets**: `ONESIGNAL_REST_KEY` in `functions/.env`

## Media support
- **Images**: pick from camera/gallery → preview → upload to Firebase Storage → inline display with tap-to-fullscreen
- **Audio**: hold mic → recording bar with timer → release → upload `.m4a` → playback with play/pause + progress slider
- **Stickers**: built-in emoji rendered as PNG or custom JPG → uploaded as PNG to `stickers/{chatId}/{msgId}.png`
- Audio playback uses `just_audio` package
- Image viewing uses `InteractiveViewer` for pinch-to-zoom

## Known limitations
- **Push notifications**: Huawei Push Kit not configured → no bg/lock-screen notifications on this phone. Foreground snackbars + local notification fallback.
- **Cloud Function sends via FCM** — uses `admin.messaging().send()` with recipient FCM token
- **Habits/Reading list/Blog/Mood/Challenges/Tools**: frontend code exists but backend (`DatabaseService`) methods are not yet wired — pre-existing LSP errors
- Release build needs signing key configured
- iOS build requires Mac

## Bugs fixed
- **Chat reactions don't show on user's own screen after tapping**: `onReact` callback in `MessageBubble` was typed as `void Function(String emoji)?` causing the `db.toggleReaction()` Future to be unawaited. Fixed: changed to `Future<void> Function(String emoji)?`, made overlay `onTap` async with `await`, added try/catch with SnackBar error feedback in `chat_screen.dart`. `message_bubble.dart:17`, `chat_screen.dart:1075`.
- **Dark mode not persisting**: ThemeProvider was instantiated twice (once in `_init()`, once in `MultiProvider`). Fixed: use `ChangeNotifierProvider.value` with the loaded instance. `main.dart:60`.
- **Reply stale on image/voice send**: `_replyingTo` only cleared in `_sendMessage()`. Fixed: capture to local var + clear before await in `_sendMessage`, `_pickImage`, and `_stopRecordingAndSend`. `chat_screen.dart`.
- **All users show online permanently**: No `WidgetsBindingObserver` → online never set to false on background. Fixed: `AuthProvider` now extends `ChangeNotifier with WidgetsBindingObserver`, flips online in `didChangeAppLifecycleState`. `auth_provider.dart`.
- **Notification cold-start crash**: navigatorKey not wired, `getInitialMessage()` missing, no debounce for duplicate FCM+Firesore notifications, fallback missing when `otherUser` fetch fails. Fixed: wired navigatorKey in `main.dart`, added `getInitialMessage()` + `handlePendingInitialMessage()` via `addPostFrameCallback`, 3-second `_lastNotifiedPerChat` debounce map, graceful `chatId`-only fallback. `notification_service.dart`, `main.dart`.
- **Sticker preview path mismatch**: `stickerLocalPath()` returned `.png` extension but files saved as `.jpg`. Fixed: changed extension to `.jpg`. `local_storage_service.dart:45`.
- **Sticker emoji/colors duplicated**: `renderBuiltInStickerToBytes()` and `_builtInPreview()` had identical emoji maps and color arrays. Fixed: extracted static `_emojiMap` and `_emojiColors` constants. `sticker_service.dart`.
- **Sticker suggestion bar perf**: `_findMatches()` iterated all packs on every rebuild. Fixed: converted to `StatefulWidget` with query caching. `sticker_suggestion_bar.dart`.

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
- Huawei background notifications won't work without Google Play Services — can't fix without HMS
- Once configured: rebuild APK, test push notifications on lock screen & background
- Wire Habits/Reading list screens to actual DatabaseService methods (currently have LSP errors)
- Group chats
- Implement actual notification settings (sound, vibrate, preview)
- Implement privacy settings (read receipts, blocked users list)
- Implement chat settings (bubble style, font size)
