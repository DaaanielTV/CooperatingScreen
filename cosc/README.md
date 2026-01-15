# CooperatingScreen Flutter App

Flutter mobile application for cross-device screen sharing.

## Prerequisites

- Flutter SDK (3.0.0 or higher)
- Dart SDK (3.0.0 or higher)
- Android Studio / Xcode
- Git

## Setup

1. **Install dependencies:**
   ```bash
   cd cosc
   flutter pub get
   ```

2. **Configure Supabase:**
   - Update `lib/main.dart` with your Supabase URL and Anon Key
   - Or use environment variables (recommended for production)

3. **Run the app:**
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── models/          # Data models (Device, PairingSession, etc.)
├── screens/         # UI screens
├── services/        # Business logic (Supabase, Signaling)
├── utils/           # Utility functions
├── widgets/         # Reusable widgets
└── main.dart       # App entry point
```

## Features (Phase 1)

- ✅ Device registration with unique serial
- ✅ Local device persistence
- ✅ Supabase authentication setup
- ⏳ Device pairing system (Phase 2)
- ⏳ WebRTC connection (Phase 3)
- ⏳ Screen sharing (Phase 3)

## Development

### Hot Reload
```bash
flutter run
# Press 'r' in terminal for hot reload
```

### Build Release
```bash
flutter build apk      # Android
flutter build ios      # iOS
```

## Testing

```bash
flutter test
```

## Documentation

See [../Readme.md](../Readme.md) for the complete technical plan.
