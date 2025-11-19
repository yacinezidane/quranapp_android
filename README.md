# Muslim DZ - Prayer Times App 🕌

A beautiful Flutter app for Muslims in Algeria with prayer times, Qibla compass, and adhan notifications.

## Features ✨

- 🕌 **Prayer Times** - Accurate prayer times for all 48 Algerian cities
- 🧭 **Qibla Compass** - Find the direction to Kaaba with cached location
- 🔔 **Adhan Notifications** - Automatic notifications with adhan sound at prayer times
- 📍 **Smart Location** - Auto-detect or manually select your city
- 💾 **Offline Support** - Cached prayer times work without internet
- 🌙 **Beautiful UI** - Modern gradient design with Arabic support

## Installation 🚀

### Prerequisites

- Flutter SDK (3.x or higher)
- Android SDK
- Java Development Kit (JDK)

### Setup

1. **Clone the repository:**
```bash
   git clone https://github.com/yacinezidane/quranapp_android.git
   cd quranapp_android
```

2. **Install dependencies:**
```bash
   flutter pub get
```

3. **Run the app:**
```bash
   flutter run
```

## Building for Production 📦

### Debug Build (for testing):
```bash
flutter build apk --debug
```

### Release Build (for distribution):
```bash
flutter build apk --release
```

APK location: `build/app/outputs/flutter-apk/app-release.apk`

## Development 🛠️

### Hot Reload Commands

While the app is running (`flutter run`), use these commands:

| Key | Command | Description | Speed |
|-----|---------|-------------|-------|
| **`r`** | Hot Reload | Updates UI instantly, keeps app state | ⚡ 1-3s |
| **`R`** | Hot Restart | Restarts entire app, resets state | ⚡ 5-10s |
| **`q`** | Quit | Stops the app and exits flutter run | - |
| **`h`** | Help | Shows all available commands | - |
| **`d`** | Detach | Keeps app running, exits flutter run | - |
| **`p`** | Performance Overlay | Toggle performance graphs | - |
| **`P`** | Construction Lines | Toggle widget construction lines | - |

**Pro tip:** Just save your Dart files (Ctrl+S) and hot reload happens automatically!

### Debug Mode 🐛

The app has a debug mode for testing notifications and features.

#### Enable Debug Mode

Edit `lib/config/debug_config.dart`:
```dart
class DebugConfig {
  // 🔧 TOGGLE THIS TO ENABLE/DISABLE DEBUG MODE
  static const bool isDebugMode = true;  // ← Set to true for development
}
```

**What debug mode shows:**
- 🐛 Debug menu icon (amber bug icon in app bar)
- 🏷️ "DEBUG MODE" banner at bottom-right
- 📝 Debug logs in console
- 🔔 Test notification buttons
- 📋 View scheduled notifications
- 🗑️ Clear all notifications

#### Disable Debug Mode (for production)
```dart
class DebugConfig {
  static const bool isDebugMode = false;  // ← Set to false for production
}
```

**Production build checklist:**
1. Set `isDebugMode = false` in `lib/config/debug_config.dart`
2. Run `flutter clean`
3. Build release APK: `flutter build apk --release`
4. Test the APK before distribution

### Debug Features

When debug mode is enabled:

**Test Notifications:**
- **Instant Notification** - Shows notification immediately with adhan
- **10 Second Notification** - Schedules test notification in 10 seconds
- **View Scheduled** - Shows all pending prayer notifications
- **Clear All** - Removes all scheduled notifications

**Console Logs:**
All debug operations are logged with `🐛 DEBUG:` prefix.

## Project Structure 📁
```
lib/
├── config/
│   └── debug_config.dart       # Debug mode configuration
├── pages/
│   ├── prayer_times_page.dart  # Prayer times & notifications
│   └── qibla_page.dart         # Qibla compass
├── services/
│   └── notifications_service.dart  # Notification handling
└── main.dart                   # App entry point

android/
└── app/
    └── src/
        └── main/
            ├── res/
            │   └── raw/
            │       └── adan.mp3    # Adhan audio file
            └── kotlin/
                └── MainActivity.kt  # Android entry point
```

## Technologies Used 🔧

- **Flutter** - UI framework
- **flutter_local_notifications** - Prayer notifications
- **flutter_compass** - Qibla direction
- **geolocator** - Location services
- **http** - API calls for prayer times
- **shared_preferences** - Local data storage
- **timezone** - Timezone handling

## API 🌐

Prayer times fetched from: [Aladhan API](https://aladhan.com/prayer-times-api)

## Permissions 📱

The app requires these Android permissions:

- **Location** - For Qibla compass and auto city detection
- **Notifications** - For prayer time alerts
- **Exact Alarms** - For precise prayer notifications
- **Vibration** - For notification vibration
- **Internet** - To fetch prayer times

## Contributing 🤝

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## Known Issues 🐞

- First build takes 1-2 minutes (normal for Flutter)
- Debug mode startup is slow (~20s), release mode is fast (~2-3s)
- Notification sound must be in `android/app/src/main/res/raw/`

## Troubleshooting 🔧

### Build fails with "MainActivity not found"
```bash
flutter clean
flutter pub get
flutter run
```

### Notifications not working
1. Check `adan.mp3` is in `android/app/src/main/res/raw/`
2. Enable debug mode and use test notifications
3. Check notification permissions in Android settings

### Hot reload not working
- Hot reload only works when app is running
- For native changes (Kotlin, AndroidManifest), use hot restart (`R`)
- If stuck, quit (`q`) and run `flutter run` again

## License 📄

This project is licensed under the MIT License - see the LICENSE file for details.

## Author 👨‍💻

**Yacine Zidane**
- GitHub: [@yacinezidane](https://github.com/yacinezidane)

## Acknowledgments 🙏

- Prayer times API by [Aladhan](https://aladhan.com/)
- Flutter team for the amazing framework
- Algerian Muslim community

---

**Made with ❤️ for Muslims in Algeria 🇩🇿**