# GLP-1 Tracker 💉
### A free, open-source GLP-1 medication tracker for everyone.

Built with Flutter — works on **Android & iOS** from a single codebase.
All data is stored **locally on-device** — no accounts, no cloud, no cost.

---

## Features
- 💉 **Medication Logger** — Log injections or pills with dose, time, and site
- ⏰ **Smart Reminders** — Weekly (for Ozempic/Mounjaro) or daily notifications
- 🗺️ **Injection Site Rotation Map** — Color-coded body diagram to prevent lipohypertrophy
- ⚖️ **Weight Tracking** — Log weight over time with trend chart
- 📏 **Body Measurements** — Track waist, hips, arms, thighs
- 🥗 **Nutrition Logging** — Calories, protein, carbs, fat, fiber per meal
- 💧 **Water Tracker** — Quick-add glasses with daily progress bar
- 📊 **Dashboard** — Today's summary at a glance

---

## Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.0+)
- Android Studio or VS Code with Flutter extension
- Android device/emulator OR iOS device/simulator

### Setup Steps

1. **Clone or copy** this project folder into your workspace

2. **Get dependencies**:
   ```bash
   flutter pub get
   ```

3. **Replace AndroidManifest.xml**:
   Copy the contents of `AndroidManifest_REPLACE_CONTENTS.xml` into:
   `android/app/src/main/AndroidManifest.xml`

4. **Run the app**:
   ```bash
   flutter run
   ```

---

## Project Structure
```
lib/
├── main.dart                    # App entry point & theme
├── database/
│   └── database_helper.dart     # SQLite CRUD operations
├── providers/
│   └── app_provider.dart        # State management (ChangeNotifier)
├── services/
│   └── notification_service.dart # Local notification scheduling
├── screens/
│   ├── home_screen.dart         # Dashboard + bottom nav
│   ├── medication_screen.dart   # Log doses, reminders, injection map
│   ├── weight_screen.dart       # Weight & measurements
│   └── nutrition_screen.dart    # Meals & water tracking
└── widgets/
    └── body_map_widget.dart     # CustomPainter body diagram
```

---

## Key Dependencies
| Package | Purpose |
|---------|---------|
| `sqflite` | Local SQLite database |
| `flutter_local_notifications` | Medication reminders |
| `provider` | State management |
| `fl_chart` | Weight trend chart |
| `timezone` | Accurate notification scheduling |
| `intl` | Date/time formatting |

---

## Contributing
PRs welcome! This is meant to be free for everyone on a GLP-1 journey.

## Disclaimer
This app is for informational tracking purposes only. Always consult your
physician before starting or adjusting any medication.
