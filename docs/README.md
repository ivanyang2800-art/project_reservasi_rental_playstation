# Dokumentasi Sistem Reservasi Rental PlayStation

Versi pertama rancangan. Fitur akan bertambah, jadi dokumen ini akan diperbarui.

| Dokumen | Isi |
|---|---|
| [flowchart-pengguna.md](flowchart-pengguna.md) | Alur pengguna: daftar/login, membuat reservasi, riwayat |
| [flowchart-admin.md](flowchart-admin.md) | Alur admin: login, persetujuan reservasi, kelola ruangan, kelola paket |
| [rancangan-database.md](rancangan-database.md) | ERD, penjelasan tabel, alur status, cara cek bentrok |
| [`../database/`](../database) | File SQL: `schema.sql`, `seed.sql`, `contoh_query.sql` |

## Daftar Fitur (versi 1)

**Pengguna**
1. Daftar akun dan login.
2. Memilih tanggal, lalu memilih jenis sewa: **per jam** (pilih jam mulai dan durasi) atau **paket** (Malam / Pelajar, jam sudah ditentukan).
3. Melihat daftar ruangan. Ruangan yang penuh di jam itu tampil abu-abu dan tidak bisa diklik.
4. Memfilter ruangan VIP / Regular dan PS3 / PS4 / PS5.
5. Melihat total harga otomatis sesuai pilihan.
6. Memesan, lalu mendapat kode reservasi dengan status *Menunggu*.
7. Membayar di luar aplikasi, lalu menunggu persetujuan admin.
8. Melihat riwayat dan status reservasi, serta membatalkan selama masih *Menunggu*.

**Admin**
1. Login (halaman sama, dibedakan oleh role).
2. Menyetujui atau menolak reservasi setelah mengecek pembayaran manual.
3. Menandai reservasi selesai.
4. Mengelola ruangan (tambah, ubah, ubah status aktif / perbaikan / nonaktif).
5. Mengelola paket (tambah, ubah, aktif / nonaktif).

## Keputusan yang Sudah Ditetapkan

- Setiap ruangan hanya berisi **satu jenis PS**.
- **Paket Pelajar** adalah sewa ruangan dengan jam dan harga sendiri (sama seperti Paket Malam).
- **Pembayaran manual** di luar aplikasi, admin yang menyetujui. Tidak ada pembayaran di dalam aplikasi.

## Asumsi (silakan koreksi kalau tidak sesuai)

Hal-hal berikut belum dibahas, jadi saya isi dengan pilihan yang paling umum:

1. **Harga per jam ditentukan per ruangan.** Jadi VIP PS5 bisa lebih mahal dari Regular PS3.
2. **Harga paket dibedakan per kategori ruangan** (VIP / Regular), tidak dibedakan per jenis PS.
3. **Durasi sewa per jam dalam jam bulat** (1, 2, 3 jam, dst).
4. **Paket Pelajar tidak dicek di aplikasi.** Pengguna cukup menunjukkan kartu pelajar ke admin saat datang.
5. **Pesanan berstatus Menunggu langsung mengunci jadwal** supaya tidak ada dua orang memesan ruangan yang sama. Kalau pengguna tidak membayar, admin menolaknya dan jadwal kosong lagi.
6. **Tidak ada upload bukti transfer** untuk versi ini. Bisa ditambah nanti (lihat bagian "Cara Menambah Fitur Nanti" di rancangan database).
7. **Ruangan dan paket tidak dihapus**, hanya dinonaktifkan, supaya riwayat reservasi lama tetap utuh.
8. **Jam buka rental belum dibatasi.** Nanti bisa ditambah tabel pengaturan.

## Catatan Teknis Penting

Aplikasi React Native **tidak bisa langsung terhubung ke MySQL**. Dibutuhkan **backend (API)** di tengah, contohnya Node.js + Express atau PHP (Laravel / PHP native). Alurnya:

```
Aplikasi React Native  --(HTTP/JSON)-->  Backend API  --(SQL)-->  MySQL
```

Query di `database/contoh_query.sql` nanti dipakai di backend tersebut. Pengecekan seperti "login valid?", "ruangan penuh?", dan "jadwal bentrok?" di flowchart semuanya dikerjakan oleh backend.
