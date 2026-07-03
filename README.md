# 💊 MediCare Reminder

> A modern Flutter application for managing medication schedules, sending reminder notifications, tracking medication history, and monitoring medication adherence — all working completely offline.

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter" />
  <img src="https://img.shields.io/badge/Platform-Android-success" />
  <img src="https://img.shields.io/badge/Database-SQLite-blue" />
  <img src="https://img.shields.io/badge/UI-Material%203-purple" />
  <img src="https://img.shields.io/badge/License-MIT-green" />
</p>

---

## 📖 About

**MediCare Reminder** is a medication reminder application built with **Flutter** that helps users manage medication schedules, receive reminder notifications, record medication history, and monitor medication adherence.

The application is fully **offline**, using **SQLite** as its local database, making it lightweight, fast, and reliable without requiring an internet connection.

---

## ✨ Features

- 💊 Manage medications (Create, Read, Update, Delete)
- ⏰ Multiple reminder schedules
- 🔔 Local notification reminders
- 📅 Daily medication schedule
- 📜 Medication history
- 📊 Adherence statistics
- 🌙 Dark Mode
- 💾 Backup & Restore SQLite Database
- 📱 Modern Material Design 3 Interface
- ⚡ 100% Offline

---

## 📱 Screenshots

<table align="center">
<tr>
<td align="center"><b>Splash</b></td>
<td align="center"><b>Home</b></td>
<td align="center"><b>Add Medicine</b></td>
</tr>

<tr>
<td>
<img src="https://github.com/user-attachments/assets/d3848c86-effb-4176-a08a-d5e0ff216f5e" width="220">
</td>

<td>
<img src="https://github.com/user-attachments/assets/0c7d289b-ba01-4514-895f-46e35780da9c" width="220">
</td>

<td>
<img src="https://github.com/user-attachments/assets/5547a287-5280-43c0-8c11-47d3f924cacc" width="220">
</td>
</tr>

<tr>
<td align="center"><b>History</b></td>
<td align="center"><b>Statistics</b></td>
<td align="center"><b>Settings</b></td>
</tr>

<tr>
<td>
<img src="https://github.com/user-attachments/assets/3e8b57c1-d6fe-4d53-9559-8394ee6cbf7f" width="220">
</td>

<td>
<img src="https://github.com/user-attachments/assets/a79e653d-c5b4-4444-8572-5ea9e8c485dc" width="220">
</td>

<td>
<img src="https://github.com/user-attachments/assets/a8954a4a-ab0b-4680-aeb3-406a9b144310" width="220">
</td>
</tr>
</table>

## 🚀 Technology Stack

| Technology | Description |
|------------|-------------|
| Flutter 3.x | Cross-platform Framework |
| Provider | State Management |
| SQLite (sqflite) | Local Database |
| flutter_local_notifications | Local Notifications |
| SharedPreferences | Local Storage |
| timezone | Notification Scheduling |
| intl | Date Formatting |
| Flutter Animate | UI Animations |
| Material 3 | UI Design |

---

## 📂 Project Structure

```
lib/
│
├── core/
│   ├── constants/
│   ├── database/
│   ├── notification/
│   ├── theme/
│   └── utils/
│
├── models/
├── providers/
├── services/
├── screens/
├── widgets/
└── main.dart
```

---

## 🎨 UI Preview

### Dashboard

```
Good Morning 👋

18 January 2026

────────────────────

💊 Total Medicines : 12

📅 Today Schedule  : 5

✅ Taken           : 3

❌ Missed          : 1

────────────────────

08:00

Paracetamol

500 mg

[Taken]

────────────────────

13:00

Vitamin C

1000 mg

[Remind Later]

────────────────────

20:00

Amoxicillin

500 mg

[Pending]

────────────────────

      ➕ Add Medicine
```

---

## 📦 Packages

```yaml
dependencies:
  flutter:
    sdk: flutter

  provider:
  sqflite:
  path:
  intl:
  google_fonts:
  flutter_local_notifications:
  timezone:
  flutter_native_timezone:
  shared_preferences:
  fl_chart:
  flutter_slidable:
  lottie:
  animations:
  uuid:
```

---

## 🚀 Getting Started

Clone this repository

```bash
git clone https://github.com/yourusername/medicare-reminder.git
```

Go to project folder

```bash
cd medicare-reminder
```

Install dependencies

```bash
flutter pub get
```

Run application

```bash
flutter run
```

---

## 📦 Build APK

```bash
flutter build apk --release
```

APK output

```
build/app/outputs/flutter-apk/app-release.apk
```

---

## 📊 Main Modules

- Splash Screen
- Dashboard
- Medication Management
- Reminder Scheduler
- Local Notification
- Medication History
- Statistics & Adherence Rate
- Settings
- Backup & Restore

---

## 🎯 Future Roadmap

- Firebase Authentication
- Cloud Synchronization
- Google Drive Backup
- Barcode Medicine Scanner
- OCR Prescription Scanner
- AI Smart Reminder
- Home Screen Widget
- Wear OS Support
- Family Sharing
- Voice Reminder
- Medicine Photo Recognition

---

## ❤️ Built With

- Flutter
- Provider
- SQLite
- Material Design 3

---

## 👨‍💻 Developer

**MelDroid.Dev**

Creating modern mobile applications with Flutter.

---

## ⭐ Support

If you like this project, don't forget to give it a **⭐ Star** on GitHub!

Your support motivates further development.

---

## 📄 License

This project is licensed under the **MIT License**.
