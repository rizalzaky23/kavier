# POS App — Panduan Instalasi & Setup

## 📦 Struktur Project

```
pos_ready_full/
├── backend/          ← Laravel 10 REST API
├── frontend/         ← Flutter App (mobile/desktop)
└── pos_web/          ← Web UI (HTML/JS, langsung jalan di browser)
```

---

## 🗄️ Backend (Laravel)

### Kebutuhan Sistem
- PHP 8.1+
- Composer
- MySQL 8.0+
- Node.js (opsional, untuk asset)

### Langkah Instalasi

```bash
# 1. Masuk ke folder backend
cd pos_ready_full/backend

# 2. Install dependencies
composer install

# 3. Copy .env dan generate app key
cp .env.example .env
php artisan key:generate

# 4. Edit konfigurasi database di .env
#    DB_DATABASE=pos_db
#    DB_USERNAME=root
#    DB_PASSWORD=yourpassword

# 5. Buat database
mysql -u root -p -e "CREATE DATABASE pos_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

# 6. Jalankan migration & seeder
php artisan migrate --seed

# 7. Buat symlink storage
php artisan storage:link

# 8. Jalankan server (default: http://localhost:8000)
php artisan serve
```

### Akun Demo
| Email | Password | Role |
|-------|----------|------|
| admin@pos.com | password | Admin |
| kasir@pos.com | password | Kasir |

---

## 📱 Frontend Flutter

### Kebutuhan Sistem
- Flutter SDK 3.0+
- Dart SDK 3.0+
- Android Studio / VS Code

### Install Flutter (jika belum ada)

```bash
# macOS via Homebrew
brew install --cask flutter

# Atau download manual dari:
# https://flutter.dev/docs/get-started/install/macos

# Verifikasi
flutter doctor
```

### Langkah Instalasi Flutter App

```bash
# 1. Masuk ke folder frontend
cd pos_ready_full/frontend

# 2. Update URL backend di:
#    lib/core/services/api_service.dart
#    static const String baseUrl = 'http://localhost:8000/api';

# 3. Install dependencies
flutter pub get

# 4. Jalankan app
flutter run                    # pilih device
flutter run -d chrome          # web browser
flutter run -d macos           # macOS desktop
flutter run -d android         # Android (perlu emulator/device)
```

---

## 🌐 Web UI (Langsung Jalan)

Tidak perlu instalasi! Cukup buka browser:

```bash
# Pastikan backend sudah jalan (http://localhost:8000)

# Buka langsung di Chrome/Firefox
open pos_ready_full/pos_web/index.html

# ATAU jalankan dengan live server (VS Code extension)
# ATAU gunakan Python simple server:
cd pos_ready_full/pos_web
python3 -m http.server 3000
# Buka: http://localhost:3000
```

---

## ⚙️ Konfigurasi Penting

### 1. Pajak Default
Edit di `.env` backend:
```env
TAX_PERCENTAGE=10
```

### 2. CORS (untuk Web UI)
Edit `config/cors.php` di backend — sudah dikonfigurasi `allowed_origins: ['*']` untuk development.
Untuk production, ganti dengan domain spesifik.

### 3. Storage Gambar
Jalankan `php artisan storage:link` agar gambar produk bisa diakses.

---

## 🗃️ Database Schema

```sql
users              → id, name, email, password, role, is_active
categories         → id, name, icon, is_active
products           → id, category_id, name, description, price, stock, low_stock_threshold, image, is_active
transactions       → id, user_id, invoice_number, subtotal, tax, discount, total, paid_amount, change_amount, payment_method, status
transaction_details→ id, transaction_id, product_id, product_name, product_price, quantity, subtotal
personal_access_tokens (Sanctum)
```

---

## 🔗 Relasi Database

```
users ──────────────── transactions
categories ─────────── products ──── transaction_details ─── transactions
```

---

## 🚀 Production Deployment

### Backend
```bash
# Set environment
APP_ENV=production
APP_DEBUG=false

# Optimize
php artisan config:cache
php artisan route:cache
php artisan view:cache
php artisan optimize
```

### Web UI
Upload folder `pos_web/` ke web hosting mana pun (Netlify, Vercel, dll).
Update `API.baseUrl` di `assets/js/app.js` ke URL production backend.

---

## 🐛 Troubleshooting

| Masalah | Solusi |
|---------|--------|
| `CORS error` di browser | Pastikan `config/cors.php` sudah benar |
| `401 Unauthorized` | Token expired, login ulang |
| Gambar tidak muncul | Jalankan `php artisan storage:link` |
| `flutter: command not found` | Install Flutter SDK terlebih dahulu |
| Database connection error | Periksa konfigurasi DB di `.env` |
