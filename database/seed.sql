-- =====================================================================
--  Data contoh untuk dicoba (jalankan SETELAH schema.sql)
--
--  Semua akun contoh memakai password: password123
--  (yang disimpan adalah hash bcrypt-nya, bukan teks password)
--
--  Tanggal reservasi memakai CURDATE() (tanggal hari ini), jadi data
--  contoh selalu terlihat "hari ini" kapan pun file ini dijalankan.
--  Harga di bawah hanya contoh, silakan ganti.
-- =====================================================================

USE rental_ps;

-- Akun -----------------------------------------------------------------
INSERT INTO users (id, nama, email, no_hp, password_hash, role) VALUES
  (1, 'Admin Rental', 'admin@rentalps.test', '081200000001',
      '$2b$10$YEqs3W0ZPKRJ/SjBma.aK.px2a9o0cOiI1d8QYHoV5zhYvdgZWSEK', 'admin'),
  (2, 'Budi',         'budi@contoh.test',    '081200000002',
      '$2b$10$YEqs3W0ZPKRJ/SjBma.aK.px2a9o0cOiI1d8QYHoV5zhYvdgZWSEK', 'user'),
  (3, 'Siti',         'siti@contoh.test',    '081200000003',
      '$2b$10$YEqs3W0ZPKRJ/SjBma.aK.px2a9o0cOiI1d8QYHoV5zhYvdgZWSEK', 'user');

-- Jenis PS ---------------------------------------------------------------
INSERT INTO jenis_ps (id, nama) VALUES
  (1, 'PS3'),
  (2, 'PS4'),
  (3, 'PS5');

-- Ruangan (1 ruangan = 1 jenis PS) -----------------------------------------
INSERT INTO ruangan (id, nama, kategori, jenis_ps_id, harga_per_jam, deskripsi, status) VALUES
  (1, 'Regular 1', 'REGULAR', 1,  8000, 'TV 32 inch, 2 stik',                'aktif'),
  (2, 'Regular 2', 'REGULAR', 2, 10000, 'TV 32 inch, 2 stik',                'aktif'),
  (3, 'Regular 3', 'REGULAR', 2, 10000, 'TV 32 inch, 2 stik',                'aktif'),
  (4, 'Regular 4', 'REGULAR', 3, 15000, 'TV 43 inch, 2 stik',                'aktif'),
  (5, 'VIP 1',     'VIP',     2, 20000, 'TV 50 inch, sofa, AC, 4 stik',      'aktif'),
  (6, 'VIP 2',     'VIP',     3, 25000, 'TV 55 inch, sofa, AC, 4 stik',      'aktif'),
  (7, 'VIP 3',     'VIP',     3, 25000, 'TV 55 inch, sofa, AC, 4 stik',      'perbaikan');

-- Paket (jam & harga sudah ditentukan) ---------------------------------------
INSERT INTO paket (id, nama, kategori_ruangan, jam_mulai, jam_selesai, harga, keterangan) VALUES
  (1, 'Paket Malam',   'REGULAR', '22:00:00', '06:00:00',  50000, '8 jam, selesai besok pagi'),
  (2, 'Paket Malam',   'VIP',     '22:00:00', '06:00:00', 100000, '8 jam, selesai besok pagi'),
  (3, 'Paket Pelajar', 'REGULAR', '13:00:00', '17:00:00',  25000, '4 jam, tunjukkan kartu pelajar saat datang'),
  (4, 'Paket Pelajar', 'VIP',     '13:00:00', '17:00:00',  50000, '4 jam, tunjukkan kartu pelajar saat datang');

-- Reservasi contoh ----------------------------------------------------------
INSERT INTO reservasi
  (kode, user_id, ruangan_id, paket_id, waktu_mulai, waktu_selesai, total_harga,
   status, catatan_admin, diproses_oleh, diproses_pada)
VALUES
  -- Budi, sewa per jam 2 jam di Regular 2 (PS4), sudah disetujui admin
  (CONCAT('RSV-', DATE_FORMAT(CURDATE(), '%Y%m%d'), '-0001'), 2, 2, NULL,
   TIMESTAMP(CURDATE(), '14:00:00'), TIMESTAMP(CURDATE(), '16:00:00'), 20000,
   'disetujui', NULL, 1, NOW()),

  -- Siti, sewa per jam 2 jam di VIP 2 (PS5), masih menunggu persetujuan
  (CONCAT('RSV-', DATE_FORMAT(CURDATE(), '%Y%m%d'), '-0002'), 3, 6, NULL,
   TIMESTAMP(CURDATE(), '15:00:00'), TIMESTAMP(CURDATE(), '17:00:00'), 50000,
   'menunggu', NULL, NULL, NULL),

  -- Budi, Paket Pelajar Regular di Regular 4, ditolak (tidak mengisi jadwal)
  (CONCAT('RSV-', DATE_FORMAT(CURDATE(), '%Y%m%d'), '-0003'), 2, 4, 3,
   TIMESTAMP(CURDATE(), '13:00:00'), TIMESTAMP(CURDATE(), '17:00:00'), 25000,
   'ditolak', 'Belum ada pembayaran sampai batas waktu', 1, NOW()),

  -- Siti, Paket Malam VIP di VIP 1, malam ini sampai besok pagi
  (CONCAT('RSV-', DATE_FORMAT(CURDATE(), '%Y%m%d'), '-0004'), 3, 5, 2,
   TIMESTAMP(CURDATE(), '22:00:00'), TIMESTAMP(CURDATE() + INTERVAL 1 DAY, '06:00:00'), 100000,
   'menunggu', NULL, NULL, NULL),

  -- Budi, kemarin, sudah selesai main
  (CONCAT('RSV-', DATE_FORMAT(CURDATE() - INTERVAL 1 DAY, '%Y%m%d'), '-0001'), 2, 1, NULL,
   TIMESTAMP(CURDATE() - INTERVAL 1 DAY, '19:00:00'), TIMESTAMP(CURDATE() - INTERVAL 1 DAY, '22:00:00'), 24000,
   'selesai', NULL, 1, NOW() - INTERVAL 1 DAY);
