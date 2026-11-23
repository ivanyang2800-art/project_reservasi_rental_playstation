-- =====================================================================
--  Sistem Reservasi Rental PlayStation
--  Rancangan database (versi 1)
--  Target: MySQL 8.0 ke atas (juga jalan di MariaDB 10.4+)
--
--  Cara pakai (Beekeeper Studio / terminal):
--    1. Jalankan file ini  -> membuat database dan semua tabel
--    2. Jalankan seed.sql  -> mengisi data contoh
--
--  PERHATIAN: file ini MENGHAPUS tabel lama (DROP TABLE) supaya bisa
--  dijalankan ulang dari awal. Jangan jalankan di database yang datanya
--  ingin disimpan.
--
--  Penjelasan lengkap tiap tabel ada di docs/rancangan-database.md
-- =====================================================================

CREATE DATABASE IF NOT EXISTS rental_ps
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE rental_ps;

-- Hapus tabel lama. Urutannya dari tabel "anak" ke tabel "induk"
-- karena ada foreign key.
DROP TABLE IF EXISTS reservasi;
DROP TABLE IF EXISTS paket;
DROP TABLE IF EXISTS ruangan;
DROP TABLE IF EXISTS jenis_ps;
DROP TABLE IF EXISTS users;


-- ---------------------------------------------------------------------
-- 1. users
--    Semua akun: pengguna biasa dan admin dibedakan dengan kolom role.
-- ---------------------------------------------------------------------
CREATE TABLE users (
  id            INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  nama          VARCHAR(100)  NOT NULL,
  email         VARCHAR(100)  NOT NULL,
  no_hp         VARCHAR(20)   NULL,
  password_hash VARCHAR(255)  NOT NULL,   -- simpan hasil hash (bcrypt), BUKAN password asli
  role          ENUM('user', 'admin') NOT NULL DEFAULT 'user',
  created_at    DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  PRIMARY KEY (id),
  UNIQUE KEY uq_users_email (email)
) ENGINE = InnoDB;


-- ---------------------------------------------------------------------
-- 2. jenis_ps
--    Daftar jenis konsol: PS3, PS4, PS5.
--    Dibuat tabel sendiri (bukan ENUM) supaya kalau nanti ada jenis
--    baru, cukup tambah 1 baris tanpa mengubah struktur tabel.
-- ---------------------------------------------------------------------
CREATE TABLE jenis_ps (
  id    TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
  nama  VARCHAR(20)      NOT NULL,          -- contoh: 'PS5'

  PRIMARY KEY (id),
  UNIQUE KEY uq_jenis_ps_nama (nama)
) ENGINE = InnoDB;


-- ---------------------------------------------------------------------
-- 3. ruangan
--    Setiap ruangan berisi SATU jenis PS saja (jenis_ps_id).
--    Harga per jam disimpan di ruangan, jadi ruangan VIP PS5 bisa
--    lebih mahal dari ruangan Regular PS3.
--    "Penuh" TIDAK disimpan di sini: penuh atau tidaknya dihitung dari
--    tabel reservasi untuk tanggal & jam yang dipilih pengguna.
-- ---------------------------------------------------------------------
CREATE TABLE ruangan (
  id             INT UNSIGNED     NOT NULL AUTO_INCREMENT,
  nama           VARCHAR(50)      NOT NULL,     -- contoh: 'VIP 1', 'Regular 3'
  kategori       ENUM('REGULAR', 'VIP') NOT NULL,
  jenis_ps_id    TINYINT UNSIGNED NOT NULL,
  harga_per_jam  INT UNSIGNED     NOT NULL,     -- dalam Rupiah
  deskripsi      VARCHAR(255)     NULL,         -- contoh: 'TV 50 inch, sofa, AC'
  status         ENUM('aktif', 'perbaikan', 'nonaktif') NOT NULL DEFAULT 'aktif',
  created_at     DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at     DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  PRIMARY KEY (id),
  UNIQUE KEY uq_ruangan_nama (nama),
  KEY idx_ruangan_filter (kategori, jenis_ps_id),
  CONSTRAINT fk_ruangan_jenis_ps
    FOREIGN KEY (jenis_ps_id) REFERENCES jenis_ps (id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT          -- jenis PS tidak bisa dihapus kalau masih dipakai ruangan
) ENGINE = InnoDB;


-- ---------------------------------------------------------------------
-- 4. paket
--    Paket = sewa ruangan dengan jam dan harga yang sudah ditentukan
--    (contoh: Paket Malam 22:00-06:00, Paket Pelajar 13:00-17:00).
--    Satu baris paket berlaku untuk satu kategori ruangan, jadi
--    "Paket Malam" untuk VIP dan Regular adalah 2 baris dengan harga
--    berbeda.
--    Kalau jam_selesai <= jam_mulai artinya paket lewat tengah malam
--    dan selesai di hari berikutnya (contoh 22:00 -> 06:00).
-- ---------------------------------------------------------------------
CREATE TABLE paket (
  id                INT UNSIGNED NOT NULL AUTO_INCREMENT,
  nama              VARCHAR(50)  NOT NULL,      -- contoh: 'Paket Malam'
  kategori_ruangan  ENUM('REGULAR', 'VIP') NOT NULL,
  jam_mulai         TIME         NOT NULL,
  jam_selesai       TIME         NOT NULL,
  harga             INT UNSIGNED NOT NULL,      -- harga total paket, dalam Rupiah
  keterangan        VARCHAR(255) NULL,          -- contoh: 'Wajib tunjukkan kartu pelajar'
  aktif             TINYINT(1)   NOT NULL DEFAULT 1,   -- 1 = tampil di aplikasi, 0 = disembunyikan
  created_at        DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at        DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  PRIMARY KEY (id),
  UNIQUE KEY uq_paket_nama_kategori (nama, kategori_ruangan),
  CONSTRAINT chk_paket_jam CHECK (jam_mulai <> jam_selesai)
) ENGINE = InnoDB;


-- ---------------------------------------------------------------------
-- 5. reservasi
--    Satu baris = satu pesanan ruangan.
--    paket_id NULL   -> sewa per jam (harga = durasi x harga_per_jam)
--    paket_id terisi -> sewa paket   (harga = harga paket)
--    total_harga disimpan supaya riwayat tidak berubah walaupun admin
--    mengganti harga di kemudian hari.
--
--    Alur status:
--      menunggu   -> pesanan baru, pengguna belum dikonfirmasi bayar
--      disetujui  -> admin sudah terima pembayaran (manual)
--      ditolak    -> admin menolak (misal tidak bayar)
--      dibatalkan -> pengguna membatalkan saat masih 'menunggu'
--      selesai    -> pengguna sudah selesai main
--    Status 'menunggu' dan 'disetujui' dianggap MENGISI jadwal ruangan.
-- ---------------------------------------------------------------------
CREATE TABLE reservasi (
  id             INT UNSIGNED NOT NULL AUTO_INCREMENT,
  kode           VARCHAR(20)  NOT NULL,         -- contoh: 'RSV-20261123-0001', ditunjukkan ke admin saat bayar
  user_id        INT UNSIGNED NOT NULL,
  ruangan_id     INT UNSIGNED NOT NULL,
  paket_id       INT UNSIGNED NULL,
  waktu_mulai    DATETIME     NOT NULL,
  waktu_selesai  DATETIME     NOT NULL,
  total_harga    INT UNSIGNED NOT NULL,         -- dalam Rupiah
  status         ENUM('menunggu', 'disetujui', 'ditolak', 'dibatalkan', 'selesai')
                              NOT NULL DEFAULT 'menunggu',
  catatan_admin  VARCHAR(255) NULL,             -- contoh: alasan ditolak
  diproses_oleh  INT UNSIGNED NULL,             -- id admin yang menyetujui/menolak
  diproses_pada  DATETIME     NULL,
  created_at     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  PRIMARY KEY (id),
  UNIQUE KEY uq_reservasi_kode (kode),
  KEY idx_reservasi_jadwal (ruangan_id, waktu_mulai, waktu_selesai),  -- mempercepat cek bentrok
  KEY idx_reservasi_user (user_id),
  KEY idx_reservasi_status (status),
  CONSTRAINT chk_reservasi_waktu CHECK (waktu_selesai > waktu_mulai),

  CONSTRAINT fk_reservasi_user
    FOREIGN KEY (user_id) REFERENCES users (id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_reservasi_ruangan
    FOREIGN KEY (ruangan_id) REFERENCES ruangan (id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_reservasi_paket
    FOREIGN KEY (paket_id) REFERENCES paket (id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_reservasi_admin
    FOREIGN KEY (diproses_oleh) REFERENCES users (id)
    ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE = InnoDB;
