-- ==============================================================================
-- 05: VALIDATION AND RESULTS (new in v2)
-- One result grid: row counts, revenue, segment sizes and 3 checks.
-- Expected results with the full dataset imported once:
--   raw rows 1,067,371 | after filters 805,549 | exact duplicates 26,124
--   clean rows 779,425 | customers 5,878 | orders 36,969 | revenue 17,374,804.25
--   all 3 CHECK rows = 0
-- ==============================================================================

WITH
raw_rows AS (
    SELECT COUNT(*) AS n FROM online_retail_raw
),
valid_rows AS (
    SELECT COUNT(*) AS n
    FROM online_retail_raw
    WHERE NULLIF(REPLACE(customer_id::TEXT, '.0', ''), '') IS NOT NULL
      AND quantity > 0
      AND unit_price > 0
      AND invoice_no NOT LIKE 'C%'
),
clean AS (
    SELECT
        COUNT(*)                    AS n,
        COUNT(DISTINCT customer_id) AS customers,
        COUNT(DISTINCT invoice_no)  AS orders,
        SUM(line_total)             AS revenue
    FROM transactions_clean
),
repeaters AS (
    SELECT COUNT(*) FILTER (WHERE frequency >= 2) AS n, COUNT(*) AS total
    FROM rfm_raw
),
seg AS (
    SELECT
        segment,
        COUNT(*)      AS customers,
        SUM(monetary) AS revenue,
        ROW_NUMBER() OVER (ORDER BY SUM(monetary) DESC) AS rn
    FROM rfm_segments
    GROUP BY segment
),
ties AS (
    SELECT
        (SELECT COUNT(*) FROM (SELECT recency_days FROM rfm_scored GROUP BY recency_days HAVING COUNT(DISTINCT r_score) > 1) a)
      + (SELECT COUNT(*) FROM (SELECT frequency    FROM rfm_scored GROUP BY frequency    HAVING COUNT(DISTINCT f_score) > 1) b)
      + (SELECT COUNT(*) FROM (SELECT monetary     FROM rfm_scored GROUP BY monetary     HAVING COUNT(DISTINCT m_score) > 1) c) AS n
),
results AS (
              SELECT 1 AS sort, 'Raw rows (online_retail_raw)' AS metric, n::NUMERIC AS value FROM raw_rows
    UNION ALL SELECT 2,  'Rows after filters',                n                            FROM valid_rows
    UNION ALL SELECT 3,  'Exact duplicate rows removed',      v.n - c.n                    FROM valid_rows v, clean c
    UNION ALL SELECT 4,  'Clean rows (transactions_clean)',   n                            FROM clean
    UNION ALL SELECT 5,  'Customers',                         customers                    FROM clean
    UNION ALL SELECT 6,  'Orders (distinct invoices)',        orders                       FROM clean
    UNION ALL SELECT 7,  'Total revenue (GBP)',               ROUND(revenue, 2)            FROM clean
    UNION ALL SELECT 8,  'Average order value (GBP)',         ROUND(revenue / orders, 2)   FROM clean
    UNION ALL SELECT 9,  'Repeat customers (2+ orders)',      n                            FROM repeaters
    UNION ALL SELECT 10, 'Repeat-purchase rate (%)',          ROUND(100.0 * n / total, 2)  FROM repeaters
    UNION ALL SELECT 20 + rn * 2, segment || ': customers',      customers                 FROM seg
    UNION ALL SELECT 21 + rn * 2, segment || ': revenue (GBP)',  ROUND(revenue, 2)         FROM seg
    UNION ALL SELECT 90, 'CHECK revenue: RFM minus clean table (should be 0)',
                         (SELECT SUM(monetary) FROM rfm_raw) - c.revenue                   FROM clean c
    UNION ALL SELECT 91, 'CHECK customers: segments minus clean table (should be 0)',
                         (SELECT COUNT(*) FROM rfm_segments) - c.customers                 FROM clean c
    UNION ALL SELECT 92, 'CHECK equal values with different scores (should be 0)', n      FROM ties
)
SELECT metric, value
FROM results
ORDER BY sort;
