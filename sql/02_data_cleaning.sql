-- ==============================================================================
-- 02: DATA CLEANING (v2)
-- Builds transactions_clean from online_retail_raw. The raw table is not changed.
-- Keeps valid sales only and removes exact duplicate rows (identical in every column).
--
-- v2 fix: v1 matched duplicates on invoice, customer, date, quantity and price only,
-- so it also deleted different products on the same invoice that had the same
-- quantity and price. v2 compares every column.
-- Note: the dataset's two yearly sheets overlap on 1-9 Dec 2010, so those rows
-- appear twice in the combined file. Exact-duplicate removal handles this.
-- ==============================================================================

DROP TABLE IF EXISTS transactions_clean;

CREATE TABLE transactions_clean AS
WITH typed AS (
    SELECT
        invoice_no,
        stock_code,
        description,
        -- works whether customer_id is text ('13085.0') or already INTEGER
        NULLIF(REPLACE(customer_id::TEXT, '.0', ''), '')::INTEGER AS customer_id,
        invoice_date::TIMESTAMP AS invoice_date,
        quantity,
        unit_price,
        country
    FROM online_retail_raw
)
SELECT DISTINCT                      -- DISTINCT on every column = exact duplicates only
    invoice_no,
    stock_code,
    description,
    customer_id,
    invoice_date,
    quantity,
    unit_price,
    ROUND((quantity * unit_price)::NUMERIC, 2) AS line_total,
    country
FROM typed
WHERE customer_id IS NOT NULL        -- guest checkouts cannot be segmented
  AND quantity > 0                   -- returns
  AND unit_price > 0                 -- free items and adjustments
  AND invoice_no NOT LIKE 'C%';      -- cancelled invoices
