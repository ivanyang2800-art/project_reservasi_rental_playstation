# Flowchart Admin

Alur dari sisi admin (pemilik / penjaga rental). Simbol sama seperti di [flowchart-pengguna.md](flowchart-pengguna.md):
oval = mulai/selesai, kotak = langkah, belah ketupat = keputusan, jajaran genjang = input/output.

---

## 1. Login dan Menu Utama

Admin memakai halaman login yang sama dengan pengguna. Sistem melihat kolom `role` di tabel `users` untuk menentukan halaman mana yang dibuka.

```mermaid
flowchart TD
    A([Mulai]) --> B[/Isi email dan password/]
    B --> C{"Sistem: email dan password cocok?"}
    C -- Tidak --> C1[/Tampil pesan kesalahan/] --> B
    C -- Ya --> D{"Sistem: role = admin?"}
    D -- Tidak --> D1([Masuk ke Beranda pengguna])
    D -- Ya --> E[/"Dashboard admin: jumlah reservasi menunggu, jadwal hari ini"/]

    E --> F{Pilih menu}
    F -- Kelola Reservasi --> G([Lihat bagian 2])
    F -- Kelola Ruangan --> H([Lihat bagian 3])
    F -- Kelola Paket --> I([Lihat bagian 4])
    F -- Logout --> J([Selesai])
```

## 2. Kelola Reservasi (Persetujuan Pembayaran)

Pembayaran dilakukan **di luar aplikasi** (bayar di tempat atau transfer). Admin mengecek sendiri apakah uang sudah diterima, lalu menyetujui atau menolak di aplikasi.

```mermaid
flowchart TD
    A([Menu Kelola Reservasi]) --> B[/"Tampil daftar reservasi berstatus MENUNGGU"/]
    B --> C[/Pilih satu reservasi/]
    C --> D[/"Tampil detail: kode, pemesan, no HP, ruangan, waktu, total harga"/]
    D --> E[Admin cek pembayaran manual]
    E --> F{"Sudah bayar sesuai total harga?"}

    F -- Ya --> G["Sistem: ubah status jadi DISETUJUI, catat admin dan waktu"]
    G --> H[/Pengguna melihat status Disetujui di Riwayat/]

    F -- Belum --> I{"Tolak sekarang? (misal tidak bayar sampai batas waktu)"}
    I -- Tidak, tunggu dulu --> B
    I -- Ya --> J[/Isi alasan penolakan/]
    J --> K["Sistem: ubah status jadi DITOLAK, jadwal ruangan kosong lagi"]
    K --> L[/Pengguna melihat status Ditolak dan alasannya/]

    H --> M{"Pengguna sudah selesai main?"}
    M -- Belum --> N([Kembali ke daftar])
    M -- Ya --> O["Sistem: ubah status jadi SELESAI"]
    O --> N
    L --> N
```

## 3. Kelola Ruangan

Setiap ruangan hanya berisi **satu jenis PS**.

```mermaid
flowchart TD
    A([Menu Kelola Ruangan]) --> B[/"Tampil daftar ruangan: nama, kategori, jenis PS, harga per jam, status"/]
    B --> C{Pilih aksi}

    C -- Tambah --> D[/"Isi nama, kategori VIP/Regular, jenis PS, harga per jam, deskripsi"/]
    C -- Ubah --> D2[/Pilih ruangan lalu ubah datanya/]
    D --> E
    D2 --> E{"Sistem: data lengkap, harga > 0, nama belum dipakai?"}
    E -- Tidak --> E1[/Tampil pesan kesalahan/] --> C
    E -- Ya --> F[Sistem: simpan ruangan] --> B

    C -- Ubah status --> G[/"Pilih status: Aktif / Perbaikan / Nonaktif"/]
    G --> H["Sistem: simpan status. Ruangan Perbaikan tampil abu-abu, Nonaktif disembunyikan dari pengguna"]
    H --> B
```

Ruangan **tidak dihapus** dari database supaya riwayat reservasi lama tetap lengkap. Sebagai gantinya, admin mengubah statusnya menjadi *Nonaktif*.

## 4. Kelola Paket

Paket = sewa ruangan dengan jam dan harga yang sudah ditentukan (misal Paket Malam 22:00 sampai 06:00, Paket Pelajar 13:00 sampai 17:00).

```mermaid
flowchart TD
    A([Menu Kelola Paket]) --> B[/"Tampil daftar paket: nama, kategori ruangan, jam mulai, jam selesai, harga, aktif"/]
    B --> C{Pilih aksi}

    C -- "Tambah / Ubah" --> D[/"Isi nama paket, kategori ruangan VIP/Regular, jam mulai, jam selesai, harga, keterangan"/]
    D --> E{"Sistem: data lengkap, jam mulai beda dengan jam selesai, harga > 0?"}
    E -- Tidak --> E1[/Tampil pesan kesalahan/] --> D
    E -- Ya --> F[Sistem: simpan paket] --> B

    C -- "Aktifkan / Nonaktifkan" --> G["Sistem: ubah kolom aktif. Paket nonaktif tidak tampil di aplikasi pengguna"]
    G --> B
```
