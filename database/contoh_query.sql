-- =====================================================================
--  Contoh query yang nanti dipakai oleh backend (API)
--  Jalankan setelah schema.sql dan seed.sql untuk mencoba.
--
--  Variabel @... dipakai supaya mudah dicoba di Beekeeper Studio:
--  ganti nilainya lalu jalankan ulang query-nya.
--  Di backend, variabel ini diganti parameter (tanda ?) dari input
--  pengguna.
-- =====================================================================

USE rental_ps;


-- ---------------------------------------------------------------------
-- 1. DAFTAR RUANGAN + STATUS untuk jadwal yang dipilih (sewa per jam)
--    Pengguna memilih tanggal, jam mulai, dan durasi.
--    Ruangan "PENUH" kalau ada reservasi berstatus 'menunggu' atau
--    'disetujui' yang waktunya BERTABRAKAN dengan jadwal yang dipilih.
--
--    Aturan bertabrakan (overlap) dua jadwal A dan B:
--      A.mulai < B.selesai  DAN  A.selesai > B.mulai
-- ---------------------------------------------------------------------
SET @mulai   = TIMESTAMP(CURDATE(), '15:00:00');
SET @selesai = @mulai + INTERVAL 2 HOUR;          -- durasi 2 jam

SELECT
  r.id,
  r.nama,
  r.kategori,
  j.nama          AS jenis_ps,
  r.harga_per_jam,
  CASE
    WHEN r.status <> 'aktif' THEN 'TIDAK TERSEDIA'   -- perbaikan / nonaktif
    WHEN EXISTS (
      SELECT 1
      FROM reservasi x
      WHERE x.ruangan_id = r.id
        AND x.status IN ('menunggu', 'disetujui')
        AND x.waktu_mulai < @selesai
        AND x.waktu_selesai > @mulai
    ) THEN 'PENUH'
    ELSE 'TERSEDIA'
  END AS status_jadwal
FROM ruangan r
JOIN jenis_ps j ON j.id = r.jenis_ps_id
WHERE r.status <> 'nonaktif'          -- ruangan nonaktif tidak ditampilkan sama sekali
-- AND r.kategori = 'VIP'             -- filter opsional
-- AND j.nama = 'PS5'                 -- filter opsional
ORDER BY r.kategori DESC, r.nama;


-- ---------------------------------------------------------------------
-- 2. HITUNG HARGA sewa per jam
--    total = durasi (jam) x harga_per_jam ruangan
-- ---------------------------------------------------------------------
SET @ruangan_id = 3;   -- Regular 3

SELECT
  r.nama,
  TIMESTAMPDIFF(HOUR, @mulai, @selesai)                   AS durasi_jam,
  r.harga_per_jam,
  TIMESTAMPDIFF(HOUR, @mulai, @selesai) * r.harga_per_jam AS total_harga
FROM ruangan r
WHERE r.id = @ruangan_id;


-- ---------------------------------------------------------------------
-- 3. SEWA PAKET: ubah jam paket menjadi waktu mulai & selesai
--    Kalau jam_selesai <= jam_mulai, paket selesai di hari berikutnya.
--    Harga = harga paket (tidak dikali jam).
-- ---------------------------------------------------------------------
SET @tanggal  = CURDATE();
SET @paket_id = 2;     -- Paket Malam VIP

SELECT
  p.nama,
  p.kategori_ruangan,
  TIMESTAMP(@tanggal, p.jam_mulai) AS waktu_mulai,
  CASE
    WHEN p.jam_selesai <= p.jam_mulai
      THEN TIMESTAMP(@tanggal + INTERVAL 1 DAY, p.jam_selesai)
    ELSE TIMESTAMP(@tanggal, p.jam_selesai)
  END AS waktu_selesai,
  p.harga AS total_harga
FROM paket p
WHERE p.id = @paket_id AND p.aktif = 1;
-- Setelah dapat waktu_mulai & waktu_selesai, pakai query nomor 1
-- dengan tambahan filter: AND r.kategori = p.kategori_ruangan


-- ---------------------------------------------------------------------
-- 4. SIMPAN RESERVASI dengan aman (cek bentrok sekali lagi)
--    Dicek ulang karena bisa saja ada orang lain yang memesan ruangan
--    yang sama beberapa detik sebelumnya.
--    "FOR UPDATE" mengunci baris ruangan sampai COMMIT, jadi dua orang
--    tidak bisa menyimpan pesanan untuk ruangan yang sama bersamaan.
-- ---------------------------------------------------------------------
START TRANSACTION;

SELECT id FROM ruangan WHERE id = @ruangan_id FOR UPDATE;

-- Kalau hasilnya > 0 berarti bentrok: backend melakukan ROLLBACK dan
-- memberi pesan "ruangan baru saja dipesan orang lain".
SELECT COUNT(*) AS jumlah_bentrok
FROM reservasi
WHERE ruangan_id = @ruangan_id
  AND status IN ('menunggu', 'disetujui')
  AND waktu_mulai < @selesai
  AND waktu_selesai > @mulai;

-- Kalau 0, simpan:
INSERT INTO reservasi (kode, user_id, ruangan_id, paket_id, waktu_mulai, waktu_selesai, total_harga)
VALUES (CONCAT('RSV-', DATE_FORMAT(CURDATE(), '%Y%m%d'), '-0099'),
        3, @ruangan_id, NULL, @mulai, @selesai, 20000);

COMMIT;


-- ---------------------------------------------------------------------
-- 5. RIWAYAT RESERVASI milik satu pengguna
-- ---------------------------------------------------------------------
SET @user_id = 2;   -- Budi

SELECT
  rv.kode,
  r.nama                         AS ruangan,
  j.nama                         AS jenis_ps,
  COALESCE(p.nama, 'Per jam')    AS jenis_sewa,
  rv.waktu_mulai,
  rv.waktu_selesai,
  rv.total_harga,
  rv.status,
  rv.catatan_admin
FROM reservasi rv
JOIN ruangan  r ON r.id = rv.ruangan_id
JOIN jenis_ps j ON j.id = r.jenis_ps_id
LEFT JOIN paket p ON p.id = rv.paket_id
WHERE rv.user_id = @user_id
ORDER BY rv.waktu_mulai DESC;


-- ---------------------------------------------------------------------
-- 6. PENGGUNA MEMBATALKAN (hanya boleh saat status masih 'menunggu')
-- ---------------------------------------------------------------------
UPDATE reservasi
SET status = 'dibatalkan'
WHERE kode = CONCAT('RSV-', DATE_FORMAT(CURDATE(), '%Y%m%d'), '-0099')
  AND user_id = 3
  AND status = 'menunggu';


-- ---------------------------------------------------------------------
-- 7. ADMIN: daftar reservasi yang menunggu persetujuan
-- ---------------------------------------------------------------------
SELECT
  rv.id,
  rv.kode,
  u.nama          AS pemesan,
  u.no_hp,
  r.nama          AS ruangan,
  rv.waktu_mulai,
  rv.waktu_selesai,
  rv.total_harga,
  rv.created_at   AS dipesan_pada
FROM reservasi rv
JOIN users   u ON u.id = rv.user_id
JOIN ruangan r ON r.id = rv.ruangan_id
WHERE rv.status = 'menunggu'
ORDER BY rv.waktu_mulai;


-- ---------------------------------------------------------------------
-- 8. ADMIN: setujui atau tolak
-- ---------------------------------------------------------------------
SET @admin_id = 1;

-- Setujui (pembayaran sudah diterima)
UPDATE reservasi
SET status = 'disetujui', diproses_oleh = @admin_id, diproses_pada = NOW()
WHERE kode = CONCAT('RSV-', DATE_FORMAT(CURDATE(), '%Y%m%d'), '-0002')
  AND status = 'menunggu';

-- Tolak (jadwal otomatis kosong lagi karena status bukan menunggu/disetujui)
UPDATE reservasi
SET status = 'ditolak', catatan_admin = 'Belum ada pembayaran',
    diproses_oleh = @admin_id, diproses_pada = NOW()
WHERE kode = CONCAT('RSV-', DATE_FORMAT(CURDATE(), '%Y%m%d'), '-0004')
  AND status = 'menunggu';

-- Tandai selesai setelah pengguna selesai main
UPDATE reservasi
SET status = 'selesai'
WHERE kode = CONCAT('RSV-', DATE_FORMAT(CURDATE(), '%Y%m%d'), '-0001')
  AND status = 'disetujui';
