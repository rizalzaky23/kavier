# Panduan Deploy License Server — TERPISAH dari Backend Lain

## Strategi: Isolated Deployment (Port 8001)

**Server IP**: `20.39.192.91`

License server akan diinstall sebagai **project Laravel baru yang sepenuhnya terpisah**,
berjalan di **port 8001**. Tidak ada kode yang di-share dengan Laravel lain.

```
Port 80   → Backend lama Anda (tidak diubah sama sekali)
Port 8001 → License Server (baru, terpisah)
```

---

## Langkah 1: SSH ke Server

```bash
ssh user@20.39.192.91
```

---

## Langkah 2: Install Laravel Baru di Direktori Terpisah

```bash
# Masuk ke direktori web
cd /var/www

# Install Laravel baru — BUKAN di folder yang sama dengan backend lama
composer create-project laravel/laravel pos_license

# Masuk ke folder baru
cd /var/www/pos_license
```

---

## Langkah 3: Upload Semua File License Server

Dari komputer lokal Anda, upload semua isi folder `license_server/`:

```bash
# Jalankan dari root project Anda (pos_ready_full/)

# Models
scp license_server/app/Models/LicenseUser.php   user@20.39.192.91:/var/www/pos_license/app/Models/
scp license_server/app/Models/MasterAdmin.php   user@20.39.192.91:/var/www/pos_license/app/Models/

# Controllers
ssh user@20.39.192.91 "mkdir -p /var/www/pos_license/app/Http/Controllers/Api"
ssh user@20.39.192.91 "mkdir -p /var/www/pos_license/app/Http/Controllers/Master"

scp license_server/app/Http/Controllers/Api/LicenseController.php        user@20.39.192.91:/var/www/pos_license/app/Http/Controllers/Api/
scp license_server/app/Http/Controllers/Master/AuthController.php         user@20.39.192.91:/var/www/pos_license/app/Http/Controllers/Master/
scp license_server/app/Http/Controllers/Master/UserController.php         user@20.39.192.91:/var/www/pos_license/app/Http/Controllers/Master/

# Middleware
scp license_server/app/Http/Middleware/MasterAuth.php   user@20.39.192.91:/var/www/pos_license/app/Http/Middleware/

# Migrations & Seeder
scp license_server/database/migrations/2024_01_01_000001_create_license_users_table.php   user@20.39.192.91:/var/www/pos_license/database/migrations/
scp license_server/database/migrations/2024_01_01_000002_create_master_admins_table.php   user@20.39.192.91:/var/www/pos_license/database/migrations/
scp license_server/database/seeders/DatabaseSeeder.php   user@20.39.192.91:/var/www/pos_license/database/seeders/

# Views
ssh user@20.39.192.91 "mkdir -p /var/www/pos_license/resources/views/master/users"

scp license_server/resources/views/master/login.blade.php      user@20.39.192.91:/var/www/pos_license/resources/views/master/
scp license_server/resources/views/master/layout.blade.php     user@20.39.192.91:/var/www/pos_license/resources/views/master/
scp license_server/resources/views/master/dashboard.blade.php  user@20.39.192.91:/var/www/pos_license/resources/views/master/
scp license_server/resources/views/master/users/index.blade.php   user@20.39.192.91:/var/www/pos_license/resources/views/master/users/
scp license_server/resources/views/master/users/create.blade.php  user@20.39.192.91:/var/www/pos_license/resources/views/master/users/
scp license_server/resources/views/master/users/edit.blade.php    user@20.39.192.91:/var/www/pos_license/resources/views/master/users/

# Routes (REPLACE routes yang ada)
scp license_server/routes/api.php   user@20.39.192.91:/var/www/pos_license/routes/
scp license_server/routes/web.php   user@20.39.192.91:/var/www/pos_license/routes/
```

---

## Langkah 4: Daftarkan Middleware di Laravel Baru

SSH ke server, edit file `bootstrap/app.php`:

```bash
ssh user@20.39.192.91
nano /var/www/pos_license/bootstrap/app.php
```

Cari bagian `->withMiddleware(...)` dan tambahkan alias:

```php
->withMiddleware(function (Middleware $middleware) {
    $middleware->alias([
        'master.auth' => \App\Http\Middleware\MasterAuth::class,
    ]);
})
```

> Jika menggunakan Laravel 10 (bukan 11), daftarkan di `app/Http/Kernel.php` di bagian `$routeMiddleware`.

---

## Langkah 5: Hapus `$connection` dari Models (Database Sama)

Karena ini Laravel baru dengan database sendiri, **hapus baris `$connection`** dari kedua model:

```bash
nano /var/www/pos_license/app/Models/LicenseUser.php
# Hapus baris: protected $connection = 'license';

nano /var/www/pos_license/app/Models/MasterAdmin.php
# Hapus baris: protected $connection = 'license';
```

---

## Langkah 6: Konfigurasi `.env`

```bash
cd /var/www/pos_license
cp .env.example .env
php artisan key:generate
nano .env
```

Isi `.env`:

```env
APP_NAME="POS License Server"
APP_ENV=production
APP_DEBUG=false
APP_TIMEZONE=Asia/Jakarta
APP_URL=http://20.39.192.91:8001

LOG_LEVEL=error

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=pos_license
DB_USERNAME=root
DB_PASSWORD=password_mysql_anda

CACHE_STORE=file
SESSION_DRIVER=file
SESSION_LIFETIME=480
```

---

## Langkah 7: Buat Database

```bash
mysql -u root -p
```

```sql
CREATE DATABASE pos_license CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
EXIT;
```

---

## Langkah 8: Migrate & Seed

```bash
cd /var/www/pos_license

php artisan migrate
php artisan db:seed
```

---

## Langkah 9: Set Permission

```bash
chmod -R 775 /var/www/pos_license/storage
chmod -R 775 /var/www/pos_license/bootstrap/cache
chown -R www-data:www-data /var/www/pos_license
```

---

## Langkah 10: Jalankan di Port 8001

### Opsi A — Cara Cepat (php artisan serve)

Cocok jika server sudah punya PHP CLI. Jalankan sebagai background process:

```bash
cd /var/www/pos_license
nohup php artisan serve --host=0.0.0.0 --port=8001 > /var/log/pos_license.log 2>&1 &
echo $! > /var/run/pos_license.pid
```

Cek apakah berjalan:
```bash
curl http://localhost:8001/master/login
```

### Opsi B — Nginx Virtual Host (Direkomendasikan untuk Production)

Buat file konfigurasi Nginx baru:

```bash
nano /etc/nginx/sites-available/pos_license
```

Isi:

```nginx
server {
    listen 8001;
    server_name 20.39.192.91;

    root /var/www/pos_license/public;
    index index.php index.html;

    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}
```

Aktifkan dan reload:

```bash
# Aktifkan site
ln -s /etc/nginx/sites-available/pos_license /etc/nginx/sites-enabled/

# Test konfigurasi
nginx -t

# Reload Nginx
systemctl reload nginx

# Buka port 8001 di firewall (jika ada UFW)
ufw allow 8001/tcp
```

---

## Langkah 11: Pastikan CORS Aktif

```bash
nano /var/www/pos_license/config/cors.php
```

Pastikan:

```php
'paths'           => ['api/*'],
'allowed_origins' => ['*'],
'allowed_methods' => ['*'],
'allowed_headers' => ['*'],
```

---

## Langkah 12: Test Endpoint dari Komputer Lokal

```bash
# Test API verify
curl -X POST http://20.39.192.91:8001/api/license/verify \
  -H "Content-Type: application/json" \
  -d '{"email":"demo@toko.com","password":"demo1234"}'

# Expected response:
# {"valid":true,"code":"LICENSE_VALID","license_end":"2024-xx-xx",...}
```

```bash
# Test Web Panel — buka di browser:
# http://20.39.192.91:8001/master/login
```

---

## Ringkasan Akses

| URL | Keterangan |
|-----|------------|
| `http://20.39.192.91:8001/master/login` | 🔑 Login Web Master Panel |
| `http://20.39.192.91:8001/master/dashboard` | 📊 Dashboard |
| `http://20.39.192.91:8001/master/users` | 👥 Kelola User & Lisensi |
| `http://20.39.192.91:8001/api/license/verify` | 📱 API Flutter — POST verify |
| `http://20.39.192.91:8001/api/license/check` | 📱 API Flutter — POST re-check |

## Default Super Admin

- **Email**: `superadmin@josephscrd.my.id`
- **Password**: `superadmin123`

> ⚠️ Ganti password segera setelah pertama login!

---

## Mengapa Ini Tidak Bisa Konflik?

```
Port 80   → Backend Lama    → Database lama    → Folder /var/www/backend_lama/
Port 8001 → License Server  → Database baru    → Folder /var/www/pos_license/
```

✅ Port berbeda → tidak ada collision jaringan  
✅ Folder berbeda → tidak ada file yang berbagi  
✅ Database berbeda → data 100% terpisah  
✅ Process berbeda → crash satu tidak mempengaruhi yang lain  
