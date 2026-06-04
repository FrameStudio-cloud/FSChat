# FSChat — by Frames Studio

A real-time messaging app built with Flutter and Firebase.

## Features

### Authentication
- Email & password sign up / sign in
- Auto-creates user profile on first sign-up

### One-on-One Chat
- Real-time messaging via Cloud Firestore
- Auto-scroll to latest messages
- Send button + keyboard action
- Typing indicator while the other user is composing

### Chat List
- All conversations sorted by latest message
- Shows last message preview and timestamp
- Online/offline green dot on avatars
- Empty state with prompt to start a chat

### Seen Status
- Double-check (✓✓) indicators when recipient has seen your message
- Single check (✓) for delivered but not yet seen

### Voice Messages
- Tap mic to record, tap stop/send bar to send
- Playback with seek bar and speed control

### Image Sharing
- Pick images from gallery and send inline
- Uploads to Firebase Storage

### Message Context Menu
- Long-press any message to Copy or Delete
- Sent messages show Copy + Delete; others' messages show Copy only

### Chat List Context Menu
- Long-press a chat to Pin/Unpin or Delete
- Pinned chats appear at the top

### Swipe to Reply
- Swipe right on any message to trigger reply mode
- Quoted message appears above the input bar

### @Mentions
- Type `@` in the message input to see user suggestions
- Tap a name to insert an @mention (highlighted in the bubble)
- Mentions are rendered with a distinctive color in the message

### Adaptive Input Box
- Message input expands from 1 to 5 lines as you type
- Send button stays anchored at the bottom-right
- FAB button to start a new chat
- Select from a list of registered users
- Creates or reopens existing chat thread

### User Presence
- Online / offline status shown in chat header and list
- Real-time updates via Firestore stream

### Dark Mode
- Toggle dark/light theme from Settings
- Full theme support throughout the app

### Push Notifications
- In-app snackbar notifications on foreground (OneSignal)
- Local notification fallback for Huawei devices (`flutter_local_notifications`)
- Background notifications delivered via Firestore listener

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter 3.41.6 (Dart 3.11.4) |
| Backend | Firebase (Cloud Firestore, Auth, Storage) |
| State | Provider (ChangeNotifier) |
| Push | OneSignal + Cloud Function (Node.js 22) |
| Platforms | Android (primary), iOS |

## Getting Started

### Prerequisites
- Flutter SDK 3.41.6+
- Java JDK 17+
- Android SDK
- A Firebase project
- OneSignal app (for push notifications)

### Setup
```bash
git clone https://github.com/FrameStudio-cloud/FSChat.git
cd fschat
flutter pub get
flutter run
```

## Build APK
```bash
flutter build apk --debug
```
Output: `build/app/outputs/flutter-apk/app-debug.apk`

## Project Structure
```
lib/
  main.dart                     — App entry point, routing, theme
  core/
    providers/                  — Shared state (theme, auth)
    services/                   — Shared services (database, notifications)
  features/
    auth/                       — Auth: login, register, user model
    chat/                       — Chat: list, messages, voice, images
    settings/                   — Profile, theme toggle, sign-out
  shared/
    models/                     — Shared models (menu actions)
```

## Roadmap
- [x] @Mentions
- [x] Pin chats
- [x] Swipe to reply
- [x] Message context menu (Copy/Delete)
- [x] Chat context menu (Pin/Unpin/Delete)
- [x] Local notifications fallback (Huawei)
- [ ] Group chats
- [ ] End-to-end encryption
- [ ] Message reactions
- [ ] Release signing & Play Store publish

---

Built with ❤️ by Frames Studio
