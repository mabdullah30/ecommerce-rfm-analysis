-- ==============================================================================
-- 04: BUSINESS SEGMENTATION
-- Description: Maps statistical RFM scores to actionable marketing segments.
-- ==============================================================================

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
        -- 1. Best Customers: Bought recently, buy often, spend a lot
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
        
        -- 2. High-Value At Risk: Used to spend big and often, but haven't returned
        WHEN r_score <= 2 AND f_score >= 4 AND m_score >= 4 THEN 'Cant Lose Them'
        
        -- 3. Consistent Shoppers: Good recency and frequency
        WHEN r_score >= 3 AND f_score >= 3 THEN 'Loyal Customers'
        
        -- 4. Recent Shoppers: High recency, but low frequency
        WHEN r_score >= 4 AND f_score <= 2 THEN 'New Customers'
        
        -- 5. Promising: Good recency, but frequency hasn't peaked yet
        WHEN r_score = 3 AND f_score <= 2 THEN 'Potential Loyalists'
        
        -- 6. Slipping Away: High frequency, but recency is dropping
        WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk'
        
        -- 7. Almost Lost: Low recency, low frequency
        WHEN r_score <= 2 AND f_score = 2 THEN 'Hibernating'
        
        -- 8. Lost: Lowest scores across the board
        WHEN r_score <= 1 AND f_score <= 1 THEN 'Lost'
        
        -- 9. Catch-all for remaining mid-tier scores
        ELSE 'Needs Attention'
    END AS segment
FROM rfm_scored;