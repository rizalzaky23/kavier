# POS App — Dokumentasi API

**Base URL:** `http://localhost:8000/api`  
**Authentication:** Bearer Token (Laravel Sanctum)  
**Format respons:** `application/json`

---

## 🔑 Authentication

### POST /auth/login
Login dan dapatkan token.

**Request:**
```json
{
  "email": "admin@pos.com",
  "password": "password"
}
```

**Response 200:**
```json
{
  "message": "Login berhasil.",
  "token": "1|abc123...",
  "user": {
    "id": 1,
    "name": "Admin POS",
    "email": "admin@pos.com",
    "role": "admin"
  }
}
```

**Error 422:**
```json
{ "message": "Validasi gagal.", "errors": { "email": ["Email atau password salah."] } }
```

---

### POST /auth/logout
*(Requires token)*

**Response 200:**
```json
{ "message": "Logout berhasil." }
```

---

### GET /auth/me
*(Requires token)* Dapatkan data user yang sedang login.

**Response 200:**
```json
{ "user": { "id": 1, "name": "...", "email": "...", "role": "admin" } }
```

---

## 📂 Categories

### GET /categories
Daftar semua kategori.

**Response:**
```json
{
  "data": [
    { "id": 1, "name": "Makanan", "icon": "restaurant", "products_count": 4 }
  ]
}
```

### POST /categories *(Admin only)*
```json
{ "name": "Makanan", "icon": "restaurant" }
```

### PUT /categories/{id} *(Admin only)*
```json
{ "name": "Makanan Berat", "is_active": true }
```

### DELETE /categories/{id} *(Admin only)*
Gagal jika kategori memiliki produk.

---

## 📦 Products

### GET /products
**Query params:**
| Param | Tipe | Keterangan |
|-------|------|-----------|
| search | string | Cari nama produk |
| category_id | int | Filter kategori |
| is_active | boolean | Filter status |
| per_page | int | Pagination |

**Response:**
```json
{
  "data": [
    {
      "id": 1,
      "category_id": 1,
      "name": "Nasi Goreng",
      "price": "25000.00",
      "stock": 50,
      "low_stock_threshold": 5,
      "image": "abc123.jpg",
      "image_url": "http://localhost:8000/storage/products/abc123.jpg",
      "is_low_stock": false,
      "category": { "id": 1, "name": "Makanan" }
    }
  ]
}
```

### GET /products/low-stock
Produk dengan stok ≤ low_stock_threshold.

### GET /products/{id}
Detail satu produk.

### POST /products *(Admin only)*
**Content-Type:** `multipart/form-data`
```
name:               string (required)
category_id:        int    (required)
price:              number (required)
stock:              int    (required)
description:        string (optional)
image:              file   (optional, max 2MB, jpg/png/webp)
low_stock_threshold: int   (optional, default 5)
```

### PUT /products/{id} *(Admin only)*
Field sama dengan POST, semua optional.

### DELETE /products/{id} *(Admin only)*

---

## 💳 Transactions

### GET /transactions
**Query params:** `date_from`, `date_to`, `status`, `per_page`

**Response:**
```json
{
  "data": {
    "data": [
      {
        "id": 1,
        "invoice_number": "INV-20240417-0001",
        "subtotal": "43000.00",
        "tax": "4300.00",
        "discount": "0.00",
        "total": "47300.00",
        "paid_amount": "50000.00",
        "change_amount": "2700.00",
        "payment_method": "cash",
        "status": "completed",
        "created_at": "2024-04-17T10:00:00.000000Z",
        "user": { "id": 1, "name": "Admin POS" }
      }
    ]
  }
}
```

### GET /transactions/{id}
Detail transaksi + detail item.

### POST /transactions
Buat transaksi baru (kasir). **Stok otomatis dikurangi.**

**Request:**
```json
{
  "items": [
    { "product_id": 1, "quantity": 2 },
    { "product_id": 5, "quantity": 1 }
  ],
  "discount": 5000,
  "paid_amount": 70000,
  "payment_method": "cash",
  "tax_percentage": 10,
  "notes": "Meja 5"
}
```

**Response 201:**
```json
{
  "message": "Transaksi berhasil.",
  "data": { ...transaction }
}
```

**Error 422 (stok tidak cukup):**
```json
{ "message": "Stok produk 'Nasi Goreng' tidak cukup. Tersisa: 2." }
```

### PATCH /transactions/{id}/cancel *(Admin only)*
Batalkan transaksi. **Stok dikembalikan.**

---

## 📊 Reports

### GET /reports/summary
**Query params:** `period` (daily|weekly|monthly|custom), `date_from`, `date_to`

**Response:**
```json
{
  "data": {
    "period": { "from": "2024-04-17", "to": "2024-04-17" },
    "total_revenue": 1250000,
    "total_tax": 125000,
    "total_discount": 20000,
    "total_transactions": 15,
    "by_payment_method": [
      { "payment_method": "cash",    "count": 10, "revenue": 800000 },
      { "payment_method": "digital", "count": 5,  "revenue": 450000 }
    ]
  }
}
```

### GET /reports/top-products
**Query params:** `period`

**Response:**
```json
{
  "data": [
    { "product_name": "Kopi Susu", "total_qty": 45, "total_revenue": 675000 }
  ]
}
```

### GET /reports/daily-chart
Data 30 hari terakhir untuk grafik.

**Response:**
```json
{
  "data": [
    { "date": "2024-04-17", "revenue": 350000, "count": 8 }
  ]
}
```

### GET /reports/export
**Query params:** `period`, `date_from`, `date_to`

Download file Excel `.xlsx` laporan transaksi.

---

## ⚠️ Error Codes

| Code | Arti |
|------|------|
| 200 | OK |
| 201 | Created |
| 401 | Unauthenticated – token tidak valid/tidak ada |
| 403 | Forbidden – role tidak memiliki akses |
| 404 | Not found |
| 422 | Validation error |
| 500 | Server error |
