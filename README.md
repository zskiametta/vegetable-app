# 🥬 Vegetable App

**Sayur segar dari petani lokal, langsung ke dapurmu.**
Aplikasi mobile Flutter untuk belanja sayur: katalog dari API, detail produk, keranjang, pengiriman, pembayaran (QRIS / e-wallet / VA / bayar di tempat), riwayat pesanan, notifikasi, dan profil.

Tugas Akhir **BTNG 2026 · Divisi Mobile (Flutter)**
Dibuat oleh **Zaskia Metta Dwi Saputri**

Data sayur diambil dari **BTNG Sayur API 2026**: https://api-mobile.dnccudinus.org

---

## Cara menjalankan (VS Code, Windows)

1. Ekstrak zip ini ke folder baru, misalnya `D:\Flutter\vegetable_app`.
2. Klik dua kali **`setup.bat`**. Script ini akan:
   - membuat folder `android/` dan `web/` (`flutter create`),
   - menambahkan izin **INTERNET** (wajib supaya API bisa diakses dari APK),
   - mengunduh package (`flutter pub get`).
3. Buka folder di VS Code, sambungkan HP (USB debugging) atau nyalakan emulator, lalu:
   ```
   flutter run
   ```
4. Membuat APK:
   ```
   flutter build apk --release
   ```
   Hasilnya ada di `build\app\outputs\flutter-apk\app-release.apk`.

**Akun demo** (sudah terisi otomatis di form login):
- Nomor HP: `081234567890`
- Kata sandi: `zaskia123`

Bisa juga daftar akun baru lewat tab **Daftar**. Tombol **Lanjut dengan Google** berjalan dalam mode demo (masuk ke akun demo), karena login Google asli butuh konfigurasi Firebase/Google Cloud.

> HP/emulator perlu internet supaya data sayur dari API bisa dimuat.

---

## Endpoint API yang dipakai

| Method | Endpoint | Dipakai di |
|--------|----------|------------|
| GET | `/api/vegetables` | Beranda (daftar semua sayur, paket masak, gambar kategori) |
| GET | `/api/vegetables?kategori=...` | Filter kategori |
| GET | `/api/vegetables?cari=...` | Pencarian |
| GET | `/api/vegetables/:id` | Halaman detail |
| GET | `/api/vegetables/categories` | Bubble kategori |

Semua request ada di `lib/services/api_service.dart`.

## Halaman

| No | Halaman | Isi |
|----|---------|-----|
| 1 | Splash | Logo beranimasi |
| 2 | Masuk / Daftar | Tab pil, form nomor HP + kata sandi + validasi, indikator kekuatan sandi, login Google (demo) |
| 3 | Beranda | Sapaan, pencarian (API), urutkan, promo bento + klaim voucher, kategori (API), paket masak, produk masonry |
| 4 | Detail | Foto + thumbnail, pilih ukuran, info, deskripsi (API detail), ide masakan, sering dibeli bersama, favorit |
| 5 | Keranjang | Langkah 1/3 · ubah jumlah, geser untuk hapus, voucher, ringkasan |
| 6 | Pengiriman | Langkah 2/3 · alamat, pilih hari & jam antar, diantar / ambil sendiri, catatan kurir |
| 7 | Pembayaran | Langkah 3/3 · QRIS, GoPay/OVO/DANA, VA BCA/BRI, bayar di tempat + rincian biaya |
| 8 | Menunggu Bayar | Hitung mundur 15 menit, QR / nomor VA, cara bayar, cek status |
| 9 | Pembayaran Berhasil | Struk + status pesanan (Dibayar → Dikemas → Dikirim → Selesai) |
| 10 | Notifikasi | Filter, dikelompokkan per hari, tandai dibaca, geser untuk hapus, kartu voucher |
| 11 | Riwayat | Ringkasan belanja + grafik 4 minggu, tab Berlangsung/Selesai, detail pesanan, beli lagi |
| 12 | Profil | Level member & poin, pintasan, Edit Profil, Favorit, FAQ, Tentang, Keluar |

## Catatan pembayaran

Pembayaran **disimulasikan** (belum memakai payment gateway asli). Setelah memilih metode, tombol **Cek status bayar** menandai pesanan lunas. Pesanan yang tidak dibayar dalam 15 menit otomatis dibatalkan. Pesanan "bayar di tempat" langsung masuk tahap dikemas.

Aturan harga:
- Ongkir Rp5.000, gratis untuk belanja ≥ Rp50.000 atau ambil sendiri.
- Biaya layanan Rp1.000.
- Voucher `PANEN10`: diskon 10% (maks Rp10.000), min. belanja Rp20.000.

## Materi BTNG yang diterapkan

- **Widget dasar & layout**: Row, Column, Stack, ListView, Wrap, CustomPaint, ShaderMask, BackdropFilter
- **Dart fundamental**: class model, enum, record, switch expression, async/await
- **Form**: Form + TextFormField + validator (Masuk, Daftar, Edit Profil)
- **Async & API**: package `http`, `FutureBuilder`, loading & error state, pull to refresh
- **Navigation**: push/pop, pushReplacement, pushAndRemoveUntil, bottom navigation, bottom sheet, dialog
- **Penyimpanan lokal**: `shared_preferences` untuk akun, keranjang, favorit, pesanan, notifikasi

## Struktur folder

```
assets/
├── fonts/      Poppins (Regular, Medium, SemiBold, Bold)
└── images/     banner, foto latar, foto profil, gambar produk cadangan
lib/
├── main.dart
├── theme.dart                    # warna, bentuk "daun", format rupiah & tanggal
├── models/models.dart            # Sayur, Ukuran, ItemKeranjang, Metode, Pesanan, Notif
├── services/
│   ├── api_service.dart          # request ke API BTNG
│   └── store.dart                # data lokal (shared_preferences)
├── widgets/common.dart           # tombol, gambar, stepper, panel bawah, dll
└── pages/
    ├── splash_page.dart
    ├── auth_page.dart            # Masuk & Daftar
    ├── main_nav.dart             # navbar kaca + tombol keranjang
    ├── home_page.dart
    ├── detail_page.dart
    ├── keranjang_page.dart
    ├── pengiriman_page.dart
    ├── pembayaran_page.dart
    ├── menunggu_bayar_page.dart
    ├── sukses_page.dart
    ├── notifikasi_page.dart
    ├── riwayat_page.dart
    └── profil_page.dart          # + Edit Profil, Favorit, FAQ
```

## Palet warna

| Nama | Hex |
|------|-----|
| Hijau daun (utama) | `#2E5E2A` |
| Kuning (aksen) | `#F6DE5B` |
| Lime | `#C8E66A` |
| Latar | `#F4F9E8` |
| Teks | `#1F3A1C` |

---

© 2026 Zaskia Metta Dwi Saputri
