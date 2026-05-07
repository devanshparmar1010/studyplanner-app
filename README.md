# 📚 Smart Study Planner

A fully offline-first Flutter application for managing study subjects, topics, and scheduling sessions — with real-time progress tracking and a smart priority engine.

## ✨ Features

| Feature | Description |
|---------|-------------|
| 📖 **Subjects & Topics** | Create subjects, add topics with estimated time and status tracking |
| 📅 **Session Scheduling** | Schedule study sessions with date/time picker and duration validation |
| 📊 **Progress Dashboard** | Visual charts (fl_chart) showing per-subject and overall completion % |
| 🎯 **Priority Engine** | Automatically surfaces the next topic to study based on lowest completion |
| 🔍 **Smart Search** | Filter topics by keyword, status, and subject simultaneously |
| 💾 **Offline-First** | All data persisted locally with Hive — works without internet |
| 🔄 **Sync Service** | Queues mutations offline and flushes to backend when connectivity restores |
| 🌙 **Dark Mode** | Full Material 3 light/dark theme support |

## 📸 Screenshots

> _Screenshots will be added after device testing_

| Dashboard | Subjects | Schedule |
|-----------|----------|----------|
| _(coming soon)_ | _(coming soon)_ | _(coming soon)_ |

| Progress | Search | |
|----------|--------|---|
| _(coming soon)_ | _(coming soon)_ | |

## 🏗️ Architecture

```
lib/
├── core/
│   ├── hive_init.dart       # Hive box initialization
│   ├── router.dart          # GoRouter with StatefulShellRoute
│   └── sync_service.dart    # Offline queue + connectivity flush
├── models/
│   ├── subject.dart         # Hive @HiveType model
│   ├── topic.dart           # Hive @HiveType model + TopicStatus enum
│   └── study_session.dart   # Hive @HiveType model
├── providers/
│   ├── subject_provider.dart    # StateNotifier for subjects
│   ├── topic_provider.dart      # StateNotifier for topics + family provider
│   ├── session_provider.dart    # StateNotifier for sessions
│   ├── progress_provider.dart   # Computed: completion %, priority engine
│   └── search_provider.dart     # Search/filter state
└── features/
    ├── dashboard/           # Stat cards, bar chart, next-to-study card
    ├── subjects/            # Expandable subject list, topic CRUD
    ├── schedule/            # Session form + upcoming sessions list
    ├── progress/            # Per-subject progress bars
    └── search/              # Live search with filter chips
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK ≥ 3.11
- Dart SDK ≥ 3.11
- Android Studio / Xcode (for device/emulator)

### Setup

```bash
# 1. Clone the repository
git clone https://github.com/devanshparmar1010/studyplanner-app.git
cd studyplanner-app

# 2. Install dependencies
flutter pub get

# 3. Run the app
flutter run

# For release build
flutter build apk --release       # Android
flutter build ios --release        # iOS
```

### Regenerate Hive adapters (if models change)

```bash
dart run build_runner build --delete-conflicting-outputs
```

## 📦 Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_riverpod` | ^2.6.1 | State management |
| `hive_flutter` | ^1.1.0 | Offline local storage |
| `go_router` | ^14.6.2 | Declarative navigation |
| `fl_chart` | ^0.69.0 | Progress bar charts |
| `connectivity_plus` | ^6.1.4 | Network detection |
| `uuid` | ^4.5.1 | Unique ID generation |
| `intl` | ^0.19.0 | Date/time formatting |

## 🔄 Data Flow

```
UI Widget
   ↓ (watch/read)
Riverpod Provider
   ↓ (mutation)
StateNotifier → Hive box (persist) → SyncService.enqueue()
   ↑                                       ↓ (on reconnect)
   └──────── state update ──────  Flush pending ops to API
```

## 📝 License

This project is for academic submission purposes.
