# 🎵 Flutter Spotify Clone

A Spotify-inspired music app built with Flutter for a university project.

---

## 📁 Project Structure

```
lib/
├── main.dart                   ← App entry, theme, navigation
├── models/
│   └── song.dart               ← Song & Playlist data models
├── data/
│   └── dummy_data.dart         ← Mock songs, playlists, search categories
├── providers/
│   └── player_provider.dart    ← Global playback state (Provider)
├── screens/
│   ├── home_screen.dart        ← Home tab (featured, carousels)
│   ├── search_screen.dart      ← Search tab (search bar + categories)
│   ├── library_screen.dart     ← Library tab (playlists, liked songs)
│   └── player_screen.dart      ← Full-screen now playing UI
└── widgets/
    └── mini_player.dart        ← Mini player bar above bottom nav
```

---

## 🚀 Getting Started

### 1. Install Flutter
Make sure Flutter is installed: https://docs.flutter.dev/get-started/install

### 2. Get dependencies
```bash
flutter pub get
```

### 3. Run the app
```bash
flutter run
```

---

## 📦 Dependencies

| Package | Purpose |
|---|---|
| `provider` | State management (PlayerProvider) |
| `just_audio` | Audio playback engine |
| `audio_service` | Background audio + lock screen controls |
| `cached_network_image` | Efficient network image loading & caching |

---

## 🎨 UI Features

- **Dark Spotify-like theme** — #121212 background, #1DB954 green accent
- **Home screen** — Quick access grid, featured playlist, horizontal carousels
- **Search screen** — Live search + coloured genre category grid
- **Library screen** — Liked songs, playlists, filter chips
- **Full-screen player** — Album art with scale animation, slider, all controls
- **Mini player** — Persistent bar above bottom nav with progress line

---

## 🔊 Adding Real Audio Playback (Next Step)

The `PlayerProvider` has TODO comments where you can connect `just_audio`:

```dart
// In player_provider.dart → playSong()
final player = AudioPlayer();
await player.setUrl(song.audioUrl);
await player.play();

// Listen to position updates:
player.positionStream.listen((pos) => updatePosition(pos));
```

For background audio support, wrap your app with `AudioServiceWidget` and
implement the `AudioHandler` interface from `audio_service`.

---

## 📱 Android Setup

In `android/app/src/main/AndroidManifest.xml`, add internet permission:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

For audio_service background playback, also add:
```xml
<uses-permission android:name="android.permission.WAKE_LOCK"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
```

---

## 💡 Ideas to Extend the Project

- Connect to a real music API (Deezer has a free tier, Jamendo for Creative Commons music)
- Add local file picker to play music from the device
- Implement a playlist detail screen
- Add animated waveform visualizer
- Add dark/light theme toggle
- Add user authentication with Firebase