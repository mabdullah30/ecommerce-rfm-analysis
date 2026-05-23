-- ==============================================================================
-- 03: RFM METRIC CALCULATION & SCORING
-- Description: Calculates Recency, Frequency, and Monetary values and applies NTILE scoring.
-- ==============================================================================

-- STEP 1: Calculate Raw RFM Values
CREATE TABLE rfm_raw AS
WITH ref_date AS (
    -- Dynamically set the reference date to 1 day after the last recorded transaction
    SELECT MAX(invoice_date) + INTERVAL '1 day' AS today
    FROM transactions_clean
),
customer_stats AS (
    SELECT
        customer_id,
        MAX(invoice_date) AS last_purchase,
        COUNT(DISTINCT invoice_no) AS frequency,
        SUM(line_total) AS monetary
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

-- STEP 2: Assign 1-5 Scores using Window Functions (NTILE)
CREATE TABLE rfm_scored AS
SELECT
    customer_id,
    recency_days,
    frequency,
    monetary,
    -- Recency is reversed: lower days since last purchase = higher score
    6 - NTILE(5) OVER (ORDER BY recency_days ASC) AS r_score,
    NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
    NTILE(5) OVER (ORDER BY monetary ASC) AS m_score
FROM rfm_raw;

-- STEP 3: Create Combined RFM Score and Label
ALTER TABLE rfm_scored
ADD COLUMN rfm_score INT,
ADD COLUMN rfm_label VARCHAR(10);

UPDATE rfm_scored
SET
    rfm_score = r_score + f_score + m_score,
    rfm_label = CONCAT(r_score, f_score, m_score);