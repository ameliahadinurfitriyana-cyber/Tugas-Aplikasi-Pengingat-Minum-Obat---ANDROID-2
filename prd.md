# PRD - Medicine Reminder
**Version:** 1.0
**Platform:** Android
**Framework:** Flutter 3.x
**Database:** SQLite (sqflite)
**State Management:** Provider / Riverpod (disarankan Provider)
**Minimum Android:** Android 7.0 (API 24)

---

# 1. Nama Aplikasi

# 💊 MediCare Reminder

Aplikasi pengingat minum obat yang membantu pengguna mengatur jadwal konsumsi obat, memberikan notifikasi tepat waktu, mencatat riwayat konsumsi, dan memantau kepatuhan minum obat.

---

# 2. Tujuan

Membantu pengguna:

- Tidak lupa minum obat.
- Mengatur jadwal berbagai jenis obat.
- Mengetahui riwayat konsumsi obat.
- Melihat tingkat kepatuhan (Adherence Rate).
- Menyimpan data secara offline menggunakan SQLite.

---

# 3. Target Pengguna

- Pasien rawat jalan
- Lansia
- Orang tua
- Pengguna dengan penyakit kronis
- Semua orang yang membutuhkan pengingat obat

---

# 4. Teknologi

| Item | Teknologi |
|-------|-----------|
| Framework | Flutter |
| Database | sqflite |
| Notification | flutter_local_notifications |
| Timezone | timezone |
| State Management | Provider |
| Local Storage | SharedPreferences |
| Date Format | intl |
| Icon | Material Symbols |
| Animasi | Flutter Animate |

---

# 5. Warna Tema

Tema modern, clean, dan medical.

Primary
#3B82F6

Secondary
#10B981

Accent
#F59E0B

Background
#F8FAFC

Card
#FFFFFF

Danger
#EF4444

Success
#22C55E

Text Primary
#1F2937

Text Secondary
#6B7280

---

# 6. Font

Google Font

Poppins

Weight

- Regular
- Medium
- SemiBold
- Bold

---

# 7. Struktur Folder

```
lib/
│
├── core/
│   ├── theme/
│   ├── database/
│   ├── notification/
│   ├── utils/
│   └── constants/
│
├── models/
│   ├── medicine.dart
│   ├── reminder.dart
│   └── history.dart
│
├── services/
│   ├── database_service.dart
│   ├── notification_service.dart
│   └── reminder_service.dart
│
├── providers/
│
├── screens/
│   ├── splash/
│   ├── home/
│   ├── add_medicine/
│   ├── detail/
│   ├── history/
│   ├── settings/
│   └── statistics/
│
├── widgets/
│
└── main.dart
```

---

# 8. Database SQLite

## Table medicines

| Field | Type |
|--------|------|
| id | INTEGER PRIMARY KEY |
| name | TEXT |
| dosage | TEXT |
| type | TEXT |
| color | TEXT |
| notes | TEXT |
| stock | INTEGER |
| startDate | TEXT |
| endDate | TEXT |
| createdAt | TEXT |

---

## Table reminders

| Field | Type |
|--------|------|
| id | INTEGER PRIMARY KEY |
| medicineId | INTEGER |
| time | TEXT |
| repeatType | TEXT |
| days | TEXT |
| isActive | INTEGER |

---

## Table history

| Field | Type |
|--------|------|
| id | INTEGER PRIMARY KEY |
| medicineId | INTEGER |
| reminderId | INTEGER |
| date | TEXT |
| status | TEXT |
| createdAt | TEXT |

Status

- Taken
- Skipped
- Missed

---

# 9. Halaman Aplikasi

## 1. Splash Screen

Logo aplikasi

Animasi Fade

Nama

MediCare Reminder

Loading 2 detik

↓

Home

---

## 2. Home

Menampilkan

Greeting

```
Selamat Pagi 👋
```

Tanggal hari ini

Card statistik

- Total Obat
- Jadwal Hari Ini
- Sudah Diminum
- Terlewat

List jadwal hari ini

```
08:00
Paracetamol
500 mg

[Sudah diminum]
```

Floating Button

Tambah Obat

Bottom Navigation

- Home
- History
- Statistics
- Settings

---

## 3. Tambah Obat

Field

Nama Obat

Jenis

Dropdown

- Tablet
- Kapsul
- Sirup
- Tetes
- Suntik

Dosis

Contoh

500 mg

Jumlah stok

Tanggal mulai

Tanggal selesai

Catatan

Warna

Color Picker

Jam Pengingat

Bisa lebih dari satu

Contoh

08:00

13:00

20:00

Repeat

- Setiap Hari
- Senin-Jumat
- Custom

Button

Simpan

---

## 4. Detail Obat

Informasi lengkap

Nama

Jenis

Dosis

Stok

Jadwal

Riwayat

Button

Edit

Delete

---

## 5. History

List seluruh riwayat

Filter

Hari ini

Minggu

Bulan

Status

Taken

Skipped

Missed

---

## 6. Statistics

Grafik

Adherence Rate

Contoh

92%

Jumlah

Sudah diminum

Terlewat

Skip

Progress mingguan

Progress bulanan

---

## 7. Settings

Dark Mode

Backup Database

Restore Database

Notifikasi

Tentang aplikasi

Versi aplikasi

---

# 10. Notification

Local Notification

Judul

```
Saatnya Minum Obat 💊
```

Isi

```
Paracetamol
500 mg

Jam 08:00
```

Action

✅ Sudah diminum

⏰ Ingatkan lagi

❌ Lewati

---

# 11. Flow Pengguna

Splash

↓

Home

↓

Tambah Obat

↓

Simpan SQLite

↓

Jadwal dibuat

↓

Notification muncul

↓

User klik

↓

Riwayat tersimpan

↓

Statistik diperbarui

---

# 12. Validasi

Nama wajib

Minimal 2 karakter

Jam wajib

Tanggal selesai

>= tanggal mulai

Stok

>=0

---

# 13. Fitur Utama

## CRUD Obat

Tambah

Edit

Delete

Cari

---

## Reminder

Multiple reminder

Repeat harian

Repeat mingguan

Repeat custom

Notification lokal

---

## History

Sudah diminum

Lewat

Skip

Filter

---

## Statistik

Adherence Rate

Grafik mingguan

Grafik bulanan

Total obat

---

## Backup

Export SQLite

Import SQLite

---

# 14. UI Style

Modern

Material 3

Rounded

Radius

20

Shadow

Soft Shadow

Card

Elevated

Animation

Fade

Slide

Scale

Hero

Lottie

---

# 15. Dashboard

```
-------------------------------------

Selamat Pagi 👋

18 Januari 2026

-------------------------

Total Obat

12

Hari Ini

5

Sudah

3

Terlewat

1

-------------------------

Jadwal Hari Ini

08.00

Paracetamol

500 mg

[Sudah diminum]

-------------------------

13.00

Vitamin C

1000 mg

[Tunda]

-------------------------

20.00

Amoxicillin

500 mg

[Belum]

-------------------------

+

Tambah Obat

-------------------------------------
```

---

# 16. User Story

Sebagai pengguna

Saya ingin

menambahkan obat

Agar

saya tidak lupa minum obat.

---

Sebagai pengguna

Saya ingin

menerima notifikasi tepat waktu

Agar

obat diminum sesuai jadwal.

---

Sebagai pengguna

Saya ingin

melihat riwayat

Agar

mengetahui apakah saya sudah minum obat.

---

Sebagai pengguna

Saya ingin

melihat statistik

Agar

mengetahui tingkat kepatuhan saya.

---

# 17. Future Feature

Login akun

Sinkronisasi Cloud

Firebase

Google Drive Backup

Barcode Scanner Obat

Scan Resep Dokter

AI Pengingat

Widget Home Screen

Smart Watch Notification

Family Sharing

Voice Reminder

Foto Obat

OCR Nama Obat

---

# 18. Package Flutter

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
  lottie:
  fl_chart:
  flutter_slidable:
  animations:
  uuid:
```

---

# 19. Estimasi Pengembangan

| Modul | Estimasi |
|---------|----------|
| UI | 2 Hari |
| SQLite | 1 Hari |
| Notification | 2 Hari |
| History | 1 Hari |
| Statistik | 1 Hari |
| Testing | 1 Hari |

Total

≈ 8 Hari

---

# 20. Target Akhir

Aplikasi modern dengan tampilan profesional bergaya Material Design 3 yang mampu:

- Menyimpan data obat secara offline menggunakan SQLite.
- Menampilkan jadwal minum obat harian.
- Mengirim notifikasi lokal secara otomatis.
- Mencatat riwayat konsumsi obat.
- Menampilkan statistik kepatuhan pengguna.
- Berjalan cepat, ringan, dan tanpa koneksi internet.