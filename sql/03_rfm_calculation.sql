-- ==============================================================================
-- 03: RFM CALCULATION AND SCORING (v2)
-- Calculates Recency, Frequency and Monetary values per customer, then scores
-- each 1-5 with PERCENT_RANK.
--
-- v2 fix: NTILE(5) put customers with identical values (for example, the many
-- one-order customers) into different scores, so results could change between
-- runs. PERCENT_RANK gives equal values the same score every time.
-- ==============================================================================

DROP TABLE IF EXISTS rfm_scored;
DROP TABLE IF EXISTS rfm_raw;

-- STEP 1: Raw RFM values
CREATE TABLE rfm_raw AS
WITH ref_date AS (
    -- reference date = 1 day after the last recorded transaction
    SELECT MAX(invoice_date) + INTERVAL '1 day' AS today
    FROM transactions_clean
),
customer_stats AS (
    SELECT
        customer_id,
        MAX(invoice_date)          AS last_purchase,
        COUNT(DISTINCT invoice_no) AS frequency,
        SUM(line_total)            AS monetary
    FROM transactions_clean
    GROUP BY customer_id
)
SELECT
    cs.customer_id,
    DATE_PART('day', rd.today - cs.last_purchase)::INT AS recency_days,
    cs.frequency,
    ROUND(cs.monetary, 2) AS monetary
FROM customer_stats cs
CROSS JOIN ref_date rd;

-- STEP 2: 1-5 scores (recency is reversed: fewer days = higher score)
CREATE TABLE rfm_scored AS
WITH ranked AS (
    SELECT
        customer_id,
        recency_days,
        frequency,
        monetary,
        PERCENT_RANK() OVER (ORDER BY recency_days DESC) AS r_pct,
        PERCENT_RANK() OVER (ORDER BY frequency ASC)     AS f_pct,
        PERCENT_RANK() OVER (ORDER BY monetary ASC)      AS m_pct
    FROM rfm_raw
),
scored AS (
    SELECT
        customer_id,
        recency_days,
        frequency,
        monetary,
        LEAST(5, FLOOR(r_pct * 5) + 1)::INT AS r_score,
        LEAST(5, FLOOR(f_pct * 5) + 1)::INT AS f_score,
        LEAST(5, FLOOR(m_pct * 5) + 1)::INT AS m_score
    FROM ranked
)
SELECT
    *,
    r_score + f_score + m_score                    AS rfm_score,
    CONCAT(r_score, f_score, m_score)::VARCHAR(10) AS rfm_label
FROM scored;
