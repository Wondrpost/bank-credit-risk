DROP TABLE IF EXISTS loan_features;

CREATE TABLE loan_features AS
WITH loan_dt AS (
  -- Tahap 1: rapikan loan, ubah tanggal, buat label default (B atau D = 1)
  SELECT loan_id, account_id,
         amount AS loan_amount,
         duration,
         payments,
         TO_DATE('19' || date::text, 'YYYYMMDD') AS loan_date,
         CASE WHEN status IN ('B','D') THEN 1 ELSE 0 END AS is_default
  FROM loan
),
trx AS (
  -- Tahap 2: rapikan transaksi, ubah tanggal
  SELECT account_id,
         TO_DATE('19' || date::text, 'YYYYMMDD') AS trx_date,
         type, amount, balance
  FROM trans
)
-- Tahap 3: gabungkan, hanya transaksi sebelum tanggal pinjaman
SELECT l.loan_id, l.account_id, l.loan_amount, l.duration, l.payments, l.is_default,
       COUNT(x.account_id)                                               AS n_trx,
       ROUND(AVG(x.balance)::numeric, 2)                                 AS avg_balance,
       MIN(x.balance)                                                    AS min_balance,
       COALESCE(SUM(CASE WHEN x.type =  'PRIJEM' THEN x.amount END), 0)  AS cash_in,
       COALESCE(SUM(CASE WHEN x.type <> 'PRIJEM' THEN x.amount END), 0)  AS cash_out
FROM loan_dt l
LEFT JOIN trx x
  ON x.account_id = l.account_id
 AND x.trx_date < l.loan_date          -- pagar anti-leakage
GROUP BY l.loan_id, l.account_id, l.loan_amount, l.duration, l.payments, l.is_default;

--cekk

SELECT COUNT(*) AS total, COUNT(DISTINCT loan_id) AS loan_unik
FROM loan_features;


-- Cek 2: lihat isinya
SELECT * FROM loan_features ORDER BY loan_id LIMIT 5;

-- Cek 3: 4,2,5
SELECT loan_id, n_trx
FROM loan_features
WHERE loan_id IN (5063, 5314, 6594);


-- Tabel khusus model: hanya pinjaman cair 1993-1997 (label sudah cukup matang)
DROP TABLE IF EXISTS loan_model;

CREATE TABLE loan_model AS
SELECT f.*,
       TO_DATE('19' || l.date::text, 'YYYYMMDD') AS loan_date
FROM loan_features f
JOIN loan l USING (loan_id)
WHERE l.date < 980101;          -- 980101 = 1 Januari 1998

--membuktikan bhawa loan dari tgl lebih dari 1 jaunari 1998 sudah tidak dipakai untuk pelatihan model
SELECT COUNT(*) AS n_loan,
       SUM(is_default) AS n_default,
       ROUND(100.0 * AVG(is_default)::numeric, 1) AS default_rate_pct,
       MIN(loan_date) AS loan_pertama,
       MAX(loan_date) AS loan_terakhir
FROM loan_model;
