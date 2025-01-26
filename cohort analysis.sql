WITH month_order AS (
    SELECT 
        DISTINCT
        user_id,
        DATE_TRUNC('month', order_date)::date AS cohort_month -- Bulan cohort
    FROM sales
),
cohort_data AS (
    SELECT 
        m0.cohort_month, -- Bulan cohort
        DATE_TRUNC('month', m1.order_date)::date AS order_month, -- Bulan transaksi
        COUNT(DISTINCT m1.user_id) AS user_count -- Jumlah pengguna unik
    FROM month_order AS m0
    JOIN sales AS m1
        ON m0.user_id = m1.user_id
    WHERE m1.order_date >= m0.cohort_month -- Transaksi setelah cohort
    GROUP BY m0.cohort_month, DATE_TRUNC('month', m1.order_date)
),
cohort_base AS (
    SELECT 
        cohort_month,
        MAX(CASE WHEN order_month = cohort_month THEN user_count ELSE 0 END) AS initial_users -- Pengguna awal (Offset 0)
    FROM cohort_data
    GROUP BY cohort_month
)
SELECT 
    c.cohort_month,
    DATE_PART('month', AGE(c.order_month, c.cohort_month)) AS month_offset, -- Selisih bulan
    c.user_count,
    (c.user_count::NUMERIC / b.initial_users) AS retention_rate -- Retention Rate skala 0-1
FROM cohort_data c
JOIN cohort_base b
    ON c.cohort_month = b.cohort_month
ORDER BY c.cohort_month, month_offset;
