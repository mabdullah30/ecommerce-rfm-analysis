-- ==============================================================================
-- 04: BUSINESS SEGMENTATION
-- Maps RFM scores to 9 marketing segments (rules unchanged from v1).
-- ==============================================================================

DROP TABLE IF EXISTS rfm_segments;

CREATE TABLE rfm_segments AS
SELECT
    customer_id,
    recency_days,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    rfm_score,
    rfm_label,
    CASE
        -- 1. Best customers: bought recently, buy often, spend a lot
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
        -- 2. High-value customers who haven't returned
        WHEN r_score <= 2 AND f_score >= 4 AND m_score >= 4 THEN 'Cant Lose Them'
        -- 3. Consistent shoppers: good recency and frequency
        WHEN r_score >= 3 AND f_score >= 3                  THEN 'Loyal Customers'
        -- 4. Recent shoppers with few orders
        WHEN r_score >= 4 AND f_score <= 2                  THEN 'New Customers'
        -- 5. Promising: mid recency, frequency still low
        WHEN r_score = 3  AND f_score <= 2                  THEN 'Potential Loyalists'
        -- 6. Slipping away: bought often, but not recently
        WHEN r_score <= 2 AND f_score >= 3                  THEN 'At Risk'
        -- 7. Almost lost: low recency, low frequency
        WHEN r_score <= 2 AND f_score = 2                   THEN 'Hibernating'
        -- 8. Lost: lowest recency and frequency
        WHEN r_score <= 1 AND f_score <= 1                  THEN 'Lost'
        -- 9. Remaining mid-tier scores
        ELSE 'Needs Attention'
    END AS segment
FROM rfm_scored;
