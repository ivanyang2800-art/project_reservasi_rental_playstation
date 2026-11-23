# Flowchart Pengguna

Alur dari sisi pengguna (pelanggan rental). Diagram ditulis dengan **Mermaid**, jadi otomatis tampil sebagai gambar di GitHub. Kalau ingin digambar ulang di Figma atau draw.io, ikuti kotak dan panahnya saja.

**Cara baca simbol:**

| Bentuk | Arti |
|---|---|
| Oval `([ ])` | Mulai / Selesai |
| Kotak `[ ]` | Langkah yang dilakukan pengguna atau sistem |
| Belah ketupat `{ }` | Keputusan / pengecekan (jawabannya Ya atau Tidak) |
| Jajaran genjang `[/ /]` | Input dari pengguna atau output yang ditampilkan |

Kotak berawalan **Sistem:** dikerjakan oleh aplikasi/backend, bukan oleh pengguna.

---

## 1. Daftar dan Login

```mermaid
flowchart TD
    A([Mulai]) --> B[Buka aplikasi]
    B --> C{Sudah punya akun?}

    C -- Belum --> D[/Isi nama, email, no HP, password/]
    D --> E{"Sistem: data lengkap dan email belum dipakai?"}
    E -- Tidak --> E1[/Tampil pesan kesalahan/] --> D
    E -- Ya --> F[Sistem: simpan akun baru] --> G

    C -- Sudah --> G[/Isi email dan password/]
    G --> H{"Sistem: email dan password cocok?"}
    H -- Tidak --> H1[/Tampil pesan: email atau password salah/] --> G
    H -- Ya --> I([Masuk ke Beranda])
```

## 2. Membuat Reservasi

Ini alur utama aplikasi.

```mermaid
flowchart TD
    A([Beranda]) --> B[/Pilih tanggal main/]
    B --> C{Pilih jenis sewa}

    C -- Per jam --> D[/Pilih jam mulai dan durasi/]
    C -- Paket --> E[/"Pilih paket (Malam / Pelajar), jam sudah ditentukan"/]

    D --> F
    E --> F["Sistem: cek jadwal semua ruangan pada waktu tersebut"]

    F --> G[/"Tampil daftar ruangan: TERSEDIA bisa diklik, PENUH abu-abu dan tidak bisa diklik"/]
    G --> G1[/"Filter opsional: VIP / Regular dan PS3 / PS4 / PS5"/]
    G1 --> H{Ada ruangan tersedia?}
    H -- Tidak --> B
    H -- Ya --> I[/Pilih satu ruangan yang tersedia/]

    I --> J["Sistem: hitung total harga"]
    J --> K[/"Tampil ringkasan: ruangan, jenis PS, waktu, total harga"/]
    K --> L{Lanjut pesan?}
    L -- Tidak --> B
    L -- Ya --> M{"Sistem: cek ulang, jadwal masih kosong?"}

    M -- Tidak --> M1[/Tampil pesan: ruangan baru saja dipesan orang lain/] --> F
    M -- Ya --> N["Sistem: simpan reservasi dengan status MENUNGGU"]
    N --> O[/"Tampil kode reservasi dan cara pembayaran"/]
    O --> P[Pengguna bayar manual ke admin, di tempat atau transfer]
    P --> Q([Menunggu persetujuan admin])
```

**Cara sistem menghitung harga:**

- **Per jam:** `durasi (jam) x harga per jam ruangan`. Contoh: 2 jam di VIP 2 (Rp25.000/jam) = Rp50.000.
- **Paket:** harga tetap sesuai paket, tidak dikali jam. Contoh: Paket Malam VIP = Rp100.000.

**Kapan ruangan dianggap PENUH:** jika ada reservasi lain di ruangan itu yang statusnya *Menunggu* atau *Disetujui* dan waktunya bertabrakan dengan waktu yang dipilih. Ruangan yang sedang *perbaikan* juga tampil abu-abu.

## 3. Riwayat dan Status Reservasi

```mermaid
flowchart TD
    A([Beranda]) --> B[Buka menu Riwayat]
    B --> C[/"Tampil daftar reservasi beserta statusnya"/]
    C --> D[/Pilih salah satu reservasi/]
    D --> E{Status apa?}

    E -- Menunggu --> F{Ingin membatalkan?}
    F -- Ya --> G["Sistem: ubah status jadi DIBATALKAN, jadwal ruangan kosong lagi"] --> Z
    F -- Tidak --> Z

    E -- Disetujui --> H[/"Tampil detail: datang sesuai jadwal dan tunjukkan kode reservasi"/] --> Z
    E -- Ditolak --> I[/Tampil alasan penolakan dari admin/] --> Z
    E -- "Selesai / Dibatalkan" --> J[/Tampil detail saja/] --> Z

    Z([Selesai])
```

Pengguna hanya bisa membatalkan selama status masih **Menunggu**. Setelah disetujui admin, pembatalan harus lewat admin (dibahas lagi nanti kalau dibutuhkan).
