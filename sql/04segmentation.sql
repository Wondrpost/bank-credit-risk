DROP TABLE IF EXISTS account_rfm;

CREATE TABLE account_rfm AS
WITH trx AS (
  SELECT account_id,
         TO_DATE('19' || date::text, 'YYYYMMDD') AS trx_date,
         type, amount, balance
  FROM trans
)
SELECT a.account_id,
       DATE '1998-12-31' - MAX(x.trx_date)                       AS recency_days,
       COUNT(*) FILTER (WHERE x.trx_date >= DATE '1998-01-01')   AS freq_12m,
       ROUND(COALESCE(SUM(x.amount) FILTER (
             WHERE x.type = 'PRIJEM' AND x.trx_date >= DATE '1998-01-01'), 0)::numeric, 0) AS cash_in_12m,
       ROUND((AVG(x.balance) FILTER (
             WHERE x.trx_date >= DATE '1998-01-01'))::numeric, 0) AS avg_bal_12m
FROM account a
LEFT JOIN trx x USING (account_id)
GROUP BY a.account_id;

SELECT COUNT(*) AS n_rekening,
       COUNT(*) FILTER (WHERE freq_12m = 0) AS tidak_aktif_di_1998,
       MIN(recency_days) AS recency_min,
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY recency_days) AS recency_median,
       MAX(recency_days) AS recency_max
FROM account_rfm;

DROP TABLE IF EXISTS account_profile;

CREATE TABLE account_profile AS
SELECT s.account_id, s.segmen_nama,
       EXISTS (SELECT 1 FROM loan l WHERE l.account_id = s.account_id) AS punya_loan,
       EXISTS (SELECT 1 FROM disp d JOIN card c ON c.disp_id = d.disp_id
               WHERE d.account_id = s.account_id)                      AS punya_kartu
FROM account_segment s;

-- Cross-selling: seberapa banyak tiap segmen sudah memakai produk lain
SELECT segmen_nama, COUNT(*) AS n_rekening,
       ROUND(100.0 * AVG(punya_loan::int), 1)  AS pct_punya_loan,
       ROUND(100.0 * AVG(punya_kartu::int), 1) AS pct_punya_kartu
FROM account_profile
GROUP BY 1
ORDER BY n_rekening DESC;

-- Risiko per segmen (hanya pinjaman 1993-1997)
SELECT s.segmen_nama, COUNT(*) AS n_loan, SUM(m.is_default) AS n_default,
       ROUND(100.0 * AVG(m.is_default), 1) AS default_rate_pct
FROM loan_model m
JOIN account_segment s USING (account_id)
GROUP BY 1
ORDER BY default_rate_pct DESC;