--mengelompokan berdasarkan status
select status, count(*) as jumlah
from loan
group by status
order by status;

--mencari rentang
SELECT MIN(date) AS awal, MAX(date) AS akhir FROM trans;

--cek yg ganda
SELECT COUNT(*) AS total_loan,
       COUNT(DISTINCT loan_id) AS loan_unik
FROM loan;

--cek
SELECT COUNT(*) AS total_baris,
       COUNT(*) - COUNT(balance) AS balance_kosong,
       COUNT(*) - COUNT(amount)  AS amount_kosong
FROM trans;

--cek ada transaksi kosong
SELECT COUNT(*) AS loan_tanpa_transaksi
FROM loan l
WHERE NOT EXISTS (SELECT 1 FROM trans t WHERE t.account_id = l.account_id);

--rentang tanggal peminjaman
SELECT MIN(TO_DATE('19' || date::text, 'YYYYMMDD')) AS loan_pertama,
       MAX(TO_DATE('19' || date::text, 'YYYYMMDD')) AS loan_terakhir
FROM loan;

--10 pinjaman dengan riwayat transaksi paling sedikit sebelum pinjaman cair
WITH loan_dt AS (
  SELECT loan_id, account_id,
         TO_DATE('19' || date::text, 'YYYYMMDD') AS loan_date
  FROM loan
),
trx AS (
  SELECT account_id,
         TO_DATE('19' || date::text, 'YYYYMMDD') AS trx_date
  FROM trans
)
SELECT l.loan_id,
       COUNT(x.account_id) AS n_trx_sebelum_loan
FROM loan_dt l
LEFT JOIN trx x
  ON x.account_id = l.account_id
 AND x.trx_date < l.loan_date
GROUP BY l.loan_id
ORDER BY n_trx_sebelum_loan
LIMIT 10;

--jenis transaksi
SELECT DISTINCT type FROM trans;

-- Default rate per tahun pinjaman cair
SELECT 1900 + (date / 10000) AS tahun_loan,
       COUNT(*) AS n_loan,
       ROUND(100.0 * AVG(CASE WHEN status IN ('B','D') THEN 1 ELSE 0 END), 1) AS default_rate_pct
FROM loan
GROUP BY 1
ORDER BY 1;

