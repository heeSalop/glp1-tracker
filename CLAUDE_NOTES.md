# 🧠 CLAUDE_NOTES.md
> Drop this file into any Claude conversation to instantly restore full context.
> Last updated: March 2026

---

## 📌 Project Overview
**App Name:** GLP-1 Tracker  
**Goal:** A free, open-source alternative to the Pep GLP-1 Tracker app  
**Platform:** Flutter (Android + iOS from one codebase)  
**Data Storage:** Local only — SQLite via `sqflite`, no cloud, no accounts  
**GitHub:** https://github.com/heeSalop/glp1-tracker  
**Owner:** Torrie Cox

---

## 🏗️ Tech Stack
| Layer | Choice | Why |
|-------|--------|-----|
| Framework | Flutter (Dart) | Single codebase for Android + iOS |
| State Management | `provider` (ChangeNotifier) | Simple, lightweight |
| Database | `sqflite` | Local SQLite, no backend needed |
| Charts | `fl_chart` | Weight trend + med level decay curves |
| Notifications | `flutter_local_notifications` | Medication reminders |
| Timezone | `timezone` | Accurate notification scheduling |
| Date formatting | `intl` | Human-readable dates throughout |

---

## 📁 Project Structure
```
lib/
├── main.dart                        # Entry point, dark purple theme, Provider setup
├── database/
│   └── database_helper.dart         # SQLite — all 6 tables, full CRUD
├── providers/
│   └── app_provider.dart            # Central state (ChangeNotifier) — all business logic
├── services/
│   └── notification_service.dart    # Daily + weekly local notification scheduling
├── screens/
│   ├── home_screen.dart             # Dashboard + bottom nav (5 tabs)
│   ├── medication_screen.dart       # Log doses, reminders, injection map (3 sub-tabs)
│   ├── weight_screen.dart           # Weight trend chart + body measurements
│   ├── nutrition_screen.dart        # Meal logger + water tracker
│   └── med_level_screen.dart        # Half-life drug level calculator + decay chart
└── widgets/
    └── body_map_widget.dart         # CustomPainter body diagram, color-coded injection sites
```

---

## 🗄️ Database Schema (SQLite)
### `medication_logs`
| Column | Type | Notes |
|--------|------|-------|
| id | INTEGER PK | Auto-increment |
| medication_name | TEXT | e.g. "Ozempic" |
| medication_type | TEXT | "injection" or "pill" |
| dose | REAL | Numeric dose amount |
| dose_unit | TEXT | "mg", "mcg", "mL", "units" |
| injection_site | TEXT | Nullable, e.g. "Left Abdomen" |
| notes | TEXT | Nullable free-text |
| logged_at | TEXT | ISO 8601 datetime string |

### `medication_settings` (reminders)
| Column | Type | Notes |
|--------|------|-------|
| id | INTEGER PK | Also used as notification ID |
| medication_name | TEXT | |
| medication_type | TEXT | |
| dose | REAL | |
| dose_unit | TEXT | |
| frequency | TEXT | "daily" or "weekly" |
| reminder_hour | INTEGER | Nullable |
| reminder_minute | INTEGER | Nullable |
| reminder_day | INTEGER | Nullable, 1=Mon…7=Sun |
| is_active | INTEGER | 0 or 1 |

### `weight_logs`
| Column | Type |
|--------|------|
| id | INTEGER PK |
| weight | REAL |
| weight_unit | TEXT | "lbs", "kg", "stone" |
| logged_at | TEXT |
| notes | TEXT |

### `measurement_logs`
waist, hips, chest, left_arm, right_arm, left_thigh, right_thigh (all REAL, nullable), unit TEXT, logged_at TEXT

### `nutrition_logs`
meal_name, meal_type (breakfast/lunch/dinner/snack), calories, protein, carbs, fat, fiber (all REAL), logged_at TEXT

### `water_logs`
amount (REAL), unit TEXT ("oz", "mL", "cups"), logged_at TEXT

---

## ✅ Features Built
- [x] **Dashboard** — Tappable stat cards (water, calories, protein, weight, doses, med levels) each navigate to the relevant screen
- [x] **Medication Logger** — Log injections or pills (Ozempic, Wegovy, Mounjaro, Zepbound, etc.) with dose, site, notes. Swipe to delete.
- [x] **Medication Reminders** — Daily or weekly push notifications. Swipe to delete. FAB only shows on Log tab (not Reminders or Injection Map tabs).
- [x] **Injection Site Rotation Map** — CustomPainter body diagram. Color-coded: green = safe, yellow = 2-4 weeks, orange = 1-2 weeks, red = < 1 week. 8 zones total.
- [x] **Weight Tracking** — Log weight (lbs/kg/stone), fl_chart line chart with trend, total change summary card. Swipe to delete.
- [x] **Body Measurements** — Waist, hips, chest, arms, thighs in inches or cm
- [x] **Nutrition Logging** — Meals by type with full macros (calories, protein, carbs, fat, fiber). Daily totals shown on dashboard.
- [x] **Water Tracker** — Quick-add buttons (8oz, 16oz, 20oz), 8-glass icon progress, daily oz total. View/delete log history.
- [x] **Med Level Calculator** — Pharmacokinetic half-life decay chart per logged dose. Shows % active, estimated mg remaining, time since dose, next half-life countdown. Half-life breakdown table (5 half-lives). Scrollable dose selector.

---

## 💊 Half-Life Data (med_level_screen.dart)
| Medication | Half-Life | Type |
|-----------|-----------|------|
| Ozempic / Wegovy / Compounded Sema | 168h (~7 days) | Semaglutide |
| Mounjaro / Zepbound / Compounded Tirz | 120h (~5 days) | Tirzepatide |
| Saxenda | 13h | Liraglutide |
| Rybelsus | 168h | Oral Semaglutide |

---

## 🐛 Bugs Fixed During Build
1. **v1 Android embedding** — ran `flutter create --project-name tracker .` to regenerate Android boilerplate
2. **`uiLocalNotificationDateInterpretation` required param** — added to both `zonedSchedule` calls in `notification_service.dart`
3. **Core library desugaring** — added `isCoreLibraryDesugaringEnabled = true` and `coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")` to `android/app/build.gradle.kts`
4. **FAB showing on wrong tabs** — moved FAB out of parent `MedicationScreen` scaffold into `_LogTab` scaffold only
5. **Missing Scaffold closing paren** — `medication_screen.dart` line ~162 was missing `);` after ListView closes

---

## ⚙️ Android Config Notes
### `android/app/build.gradle.kts`
```kotlin
compileOptions {
    isCoreLibraryDesugaringEnabled = true
    sourceCompatibility = JavaVersion.VERSION_17
    targetCompatibility = JavaVersion.VERSION_17
}
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
```

### `AndroidManifest.xml` required permissions
```xml
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.VIBRATE"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
```

---

## 🚀 Planned / Future Features
- [ ] Side effect logging (nausea, fatigue, appetite changes, etc.)
- [ ] Progress photos with side-by-side comparison
- [ ] Weight loss goal setting with progress toward goal
- [ ] Export data to CSV
- [ ] Dark/light theme toggle
- [ ] Onboarding flow for new users
- [ ] Multi-medication stacking (show combined drug levels on one chart)
- [ ] Google Fit / Apple Health integration
- [ ] Play Store / App Store release

---

## 🔁 How to Resume This Project with Claude
1. Open a new Claude conversation at claude.ai
2. Paste this file's contents OR upload this file
3. Say something like:
   > *"Here are my Claude notes from a previous session. I'm continuing development on my GLP-1 Tracker Flutter app. Today I want to [add feature / fix bug / etc.]"*
4. Claude will have full context and can pick up right where we left off!

---

## 📦 pubspec.yaml dependencies
```yaml
dependencies:
  flutter:
    sdk: flutter
  sqflite: ^2.3.0
  path: ^1.8.3
  flutter_local_notifications: ^17.1.2
  provider: ^6.1.2
  intl: ^0.19.0
  fl_chart: ^0.68.0
  permission_handler: ^11.3.1
  timezone: ^0.9.4
```
