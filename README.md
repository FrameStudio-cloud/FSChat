# FSChat — by Frames Studio

A real-time messaging app with built-in wellness tools — mood tracker, habit tracker, challenges, journal, and reading list. Built with Flutter and Firebase.

## Features

### Messaging
- **Real-time chat** via Cloud Firestore with auto-scroll
- **Voice messages** — record, send, play with seek bar
- **Images** — pick from gallery, upload to Firebase Storage, inline display
- **Stickers** — built-in emoji packs + custom sticker creator
- **@Mentions** — type `@` to suggest and highlight users
- **Swipe to reply** — swipe right on any message to quote it
- **Message reactions** — tap to add/remove emoji reactions
- **Seen status** — single check (delivered) / double check (seen)
- **Typing indicator** — real-time while the other user is composing
- **Online/offline** — green dot on avatars, updates live via Firestore

### Chat List
- Pinned chats appear at top (long-press to pin/unpin)
- Swipe left to delete with confirmation
- Three-dot overflow menu: Settings, Archive, Mark all read
- **Widget bubbles** — horizontal stat row above the list: Mood, Habits, Journal, Challenges, Reading, Online count

### Wellness Tools
- **Mood Tracker** — 3-tab dashboard (Today/Calendar/Insights), color-coded emoji history, weekly heatmap, streaks, trends, daily check-in reminder
- **Habit Tracker** — 3-tab dashboard (Today/Calendar/Insights), boolean & quantifiable habit types, categories, target counts, streak tracking, daily reminder
- **Journal** — write and browse blog-style posts with tags
- **Challenges** — time-bound challenges with day-by-day progress tracking, deadline reminder
- **Reading List** — track books, star ratings, daily reading reminder

### Notifications
- **FCM push** (Cloud Functions: message, post, challenge, comment notifications)
- **Flutter Local Notifications** — foreground fallback on devices without Google Play Services
- **Scheduled reminders** — habit daily reminders, streak milestones, mood check-in (20:00), reading reminder (19:00), challenge deadline (1 day before), low mood pattern alert

### Contact Info
- Tap avatar or name in chat header to open detailed contact screen
- Large photo (tappable fullscreen), bio, email, online/last seen
- Shared media gallery with swipeable PageView
- Clear chat, Block user

### Settings
- Cover-style profile banner with avatar + camera overlay
- Appearance: dark/light mode toggle, custom wallpaper (solid colors or gallery image)
- Notification preferences, Privacy, Account actions

### Navigation
- Bottom nav with 4 tabs: Chats, Contacts, Journal, Tools
- Tools tab groups: Habits, Mood Tracker, Challenges, Reading List

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter 3.41.6 (Dart 3.11.4) |
| Backend | Firebase (Cloud Firestore, Auth, Storage, Functions) |
| State | Provider (ChangeNotifier) |
| Push | Firebase Cloud Messaging + flutter_local_notifications |
| Local DB | Isar (habits, reading list) |
| Platforms | Android (primary), iOS (configured) |

## Getting Started

### Prerequisites
- Flutter SDK 3.41.6+
- Java JDK 17+
- Android SDK
- A Firebase project with Auth, Firestore, Storage, and FCM enabled

### Setup
```bash
git clone https://github.com/FrameStudio-cloud/FSChat.git
cd fschat
flutter pub get
flutter run
```

### Build APK
```powershell
$env:JAVA_HOME = "C:\Program Files\Eclipse Adoptium\jdk-17.0.19.10-hotspot"
$env:ANDROID_HOME = "C:\Users\Administrator\AppData\Local\Android\Sdk"
flutter build apk --debug
```
Output: `build/app/outputs/flutter-apk/app-debug.apk`

## Project Structure
```
lib/
  main.dart                     — App entry point, routing, theme, notifications
  core/
    theme/                      — AppColors, AppTheme, BubbleStyle
    providers/                  — ThemeProvider (dark mode + wallpaper)
    services/                   — DatabaseService, NotificationService, LocalStorageService, IsarService
  features/
    auth/                       — Login, register, user model, online/offline lifecycle
    chat/                       — Chat list, messages, stickers, voice, images, contact info
    home/                       — Bottom nav with 4 tabs
    contacts/                   — All users list with search + online dots
    settings/                   — Profile, appearance, wallpaper, about
    habits/                     — Habit tracker (3-tab dashboard, categories, quantifiable/boolean)
    mood/                       — Mood tracker (3-tab dashboard, calendar, insights)
    challenges/                 — Challenges with day-by-day progress
    blog/                       — Journal posts with tags and comments
    reading_list/               — Reading list with star ratings
    tools/                      — Tools hub screen
  shared/
    widgets/                    — Image editor, notification banner
```

## Releases

| Version | Highlights |
|---------|-----------|
| v1.3.1 | Bug fixes: bubbles overflow, FAB overlap, challenge rules, graph height |
| v1.3.0 | Mood & Habit redesigns (3-tab dashboards), widget bubbles, warm amber bubbles |
| v1.2.0 | Visual redesign, notification system rewrite, theme system |
| v1.1.0 | Sticker system, FCM push, reply + mention + reaction features |
| v1.0.0 | Initial release — messaging, auth, voice, images |

---

Built with ❤️ by Frames Studio
