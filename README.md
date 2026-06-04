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

### Chat List
- All conversations sorted by latest message
- Shows last message preview and timestamp
- Empty state with prompt to start a chat

### Seen Status
- Double-check (✓✓) indicators when recipient has seen your message
- Single check (✓) for delivered but not yet seen

### New Conversations
- FAB button to start a new chat
- Select from a list of registered users
- Creates or reopens existing chat thread

### User Presence
- Online / offline status shown in chat header
- Profile photos from Google account

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter 3.41.6 (Dart 3.11.4) |
| Backend | Firebase (Cloud Firestore, Auth) |
| State | Provider (ChangeNotifier) |
| Platforms | Android, iOS |

## Screenshots

*(Add screenshots here)*

## Getting Started

### Prerequisites
- Flutter SDK 3.41.6+
- Java JDK 17+
- Android SDK
- A Firebase project

### Setup
```bash
git clone <repo-url>
cd fschat
flutter pub get
flutter run
```

## Build APK
```bash
flutter build apk --debug
```
Output: `build/app/outputs/flutter-apk/app-debug.apk`

## Roadmap
- [ ] Push notifications
- [ ] Group chats
- [ ] Voice messages
- [ ] Image sharing
- [ ] End-to-end encryption
- [ ] Release signing & Play Store publish

---

Built with ❤️ by Frames Studio
