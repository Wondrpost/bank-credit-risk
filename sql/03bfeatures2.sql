DROP TABLE IF EXISTS loan_model_v2;

CREATE TABLE loan_model_v2 AS
WITH trx AS (
  -- Tahap 1: rapikan transaksi, ubah tanggal
  SELECT account_id,
         TO_DATE('19' || date::text, 'YYYYMMDD') AS trx_date,
         type, amount, balance
  FROM trans
),
recent AS (
  -- Tahap 2: hitung aktivitas per periode, per pinjaman
  SELECT m.loan_id,
         COUNT(*) FILTER (
           WHERE x.trx_date >= m.loan_date - INTERVAL '3 months')         AS n_trx_last3m,
         COUNT(*) FILTER (
           WHERE x.trx_date <  m.loan_date - INTERVAL '3 months'
             AND x.trx_date >= m.loan_date - INTERVAL '6 months')         AS n_trx_prev3m,
         AVG(x.balance) FILTER (
           WHERE x.trx_date >= m.loan_date - INTERVAL '3 months')         AS avg_bal_last3m
  FROM loan_model m
  JOIN trx x
    ON x.account_id = m.account_id
   AND x.trx_date < m.loan_date                      -- pagar anti-leakage
  GROUP BY m.loan_id
)
-- Tahap 3: gabungkan ke tabel model, tambahkan rasio dan selisih
SELECT m.*,
       ROUND((m.cash_in / NULLIF(m.cash_out, 0))::numeric, 3)      AS cashin_cashout_ratio,
       COALESCE(r.n_trx_last3m, 0)                                 AS n_trx_last3m,
       COALESCE(r.n_trx_prev3m, 0)                                 AS n_trx_prev3m,
       COALESCE(r.n_trx_last3m, 0) - COALESCE(r.n_trx_prev3m, 0)   AS n_trx_change,
       ROUND(r.avg_bal_last3m::numeric, 2)                         AS avg_bal_last3m
FROM loan_model m
LEFT JOIN recent r USING (loan_id);

-- Cek 1
SELECT COUNT(*) AS total, COUNT(DISTINCT loan_id) AS loan_unik
FROM loan_model_v2;

-- Cek 2: lihat isinya, apakah angkanya masuk akal
SELECT loan_id, n_trx, cashin_cashout_ratio,
       n_trx_last3m, n_trx_prev3m, n_trx_change, avg_bal_last3m
FROM loan_model_v2
ORDER BY loan_id
LIMIT 8;	

-- Cek 3: berapa nilai kosong di dua kolom baru
SELECT COUNT(*) - COUNT(cashin_cashout_ratio) AS ratio_kosong,
       COUNT(*) - COUNT(avg_bal_last3m)       AS bal3m_kosong
FROM loan_model_v2;