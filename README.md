# 📝 Notes App (Flutter & Floor SQLite)

A modern, responsive, and feature-rich offline-first note-taking application built with **Flutter** and **Floor SQLite**. Designed with Material 3, reactive data streams, non-blocking background location tagging, multi-note selection, gesture controls, and safety mechanisms.

---

## ✨ Features

- **🏷️ Structured Organization (Title & Topic)**
  - Every note features a dedicated **Title**, **Topic / Category** (e.g., Work, Personal, Ideas, Study, Urgent), and detailed **Content**.
  - Quick-selection topic chips for effortless tagging and visual distinction in note cards.

- **📍 Non-Blocking Background Location Tagging**
  - Optional real-time GPS coordinate capture and reverse geocoding into human-readable place names.
  - **Zero-lag saving**: Tap *Save* and the screen closes immediately. Location resolution runs asynchronously in the background and silently updates SQLite when coordinates and addresses resolve.

- **✅ Multi-Select & Batch Deletion**
  - Long-press any note card to activate multi-select mode.
  - Select individual or multiple notes with a tap, view real-time selection counts, and batch-delete with a single action.
  - Includes a floating **SnackBar with Undo** to immediately recover deleted notes.

- **👈 Swipe-to-Delete with Instant Undo**
  - Swipe any note card to the left to delete it immediately.
  - Reversible via a floating SnackBar prompt.

- **📳 Shake Gesture with Safety Confirmation**
  - Utilizes device accelerometer sensors (`shake` package) to trigger a "Clear All Notes" action.
  - Protected by an explicit confirmation dialog to prevent accidental triggers while walking or moving.

- **🛡️ Unsaved Changes Guard**
  - Integrated with Flutter's `PopScope` to detect dirty form states and confirm before discarding edits.

- **⚡ Reactive Live Data**
  - Built on Floor's reactive SQLite streams (`Stream<List<Note>>`). Any change (user edits, deletions, or background geocoding updates) updates the UI automatically without manual refreshes.

---

## 🏗️ Architecture & Technology Stack

The project follows a clean, layered architectural pattern:

```
lib/
├── database/            # Floor SQLite database, DAOs, and migrations
│   ├── app_database.dart
│   ├── app_database.g.dart
│   └── note_dao.dart
├── models/              # Immutable data models
│   └── note.dart
├── screens/             # UI Presentation screens
│   ├── add_note_screen.dart
│   ├── edit_note_screen.dart
│   └── notes_screen.dart
├── services/            # Background orchestration & location resolvers
│   └── note_service.dart
├── widgets/             # Reusable UI components
│   └── note_card.dart
└── main.dart            # Application entrypoint & dependency setup
```

### Core Packages & Dependencies

| Category | Package | Purpose |
| :--- | :--- | :--- |
| **Persistence** | [`floor`](https://pub.dev/packages/floor) `^1.5.0` | Reactive SQLite abstraction layer |
| | [`sqflite`](https://pub.dev/packages/sqflite) `^2.3.0` | SQLite engine for Flutter |
| **Location & Geo** | [`geolocator`](https://pub.dev/packages/geolocator) `^14.0.3` | GPS coordinate resolution & permissions |
| | [`geocoding`](https://pub.dev/packages/geocoding) `^4.0.0` | Reverse geocoding (Lat/Lng -> Placename) |
| **Hardware** | [`shake`](https://pub.dev/packages/shake) `^3.0.0` | Device shake event detection |
| **Code Generation** | [`floor_generator`](https://pub.dev/packages/floor_generator) `^1.5.0` | Generates DAO and database implementations |
| | [`build_runner`](https://pub.dev/packages/build_runner) `^2.4.13` | Code generation orchestration tool |

---

## 🗄️ Database Migrations

The Floor SQLite database schema is at **Version 3**:

- **Version 1 (Initial)**: `id`, `title`, `content`, `latitude`, `longitude`, `createdAt`, `updatedAt`
- **Version 2 (`migration1to2`)**: Added `locationName TEXT` column for human-readable reverse geocoded places.
- **Version 3 (`migration2to3`)**: Added `topic TEXT` column for category tagging and topic chips.

All migrations are fully defined in [`app_database.dart`](file:///d:/notes_app02/lib/database/app_database.dart) ensuring zero data loss during version upgrades.

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>= 3.2.0 < 4.0.0`)
- Android Studio / Xcode / VS Code with Flutter extension
- Connected physical device or emulator

### Installation & Run

1. **Clone or navigate to the repository:**
   ```bash
   cd notes_app02
   ```

2. **Install Flutter packages:**
   ```bash
   flutter pub get
   ```

3. **Run code generation (Floor DAOs & Database):**
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. **Launch the application:**
   ```bash
   flutter run
   ```

---

## 📱 Platform Permissions

### Android (`android/app/src/main/AndroidManifest.xml`)
Location permissions required for GPS tagging:
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

### iOS (`ios/Runner/Info.plist`)
Location usage descriptions required for iOS devices:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app requires location access to tag notes with your current location.</string>
```

---

## 🧪 Testing & Verification

- **Run Widget and Unit Tests:**
  ```bash
  flutter test
  ```

- **Run Static Analysis:**
  ```bash
  flutter analyze
  ```

---

## 📄 License

This project is open-source and available under the [MIT License](LICENSE).
