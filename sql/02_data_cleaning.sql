-- ==============================================================================
-- 02: DATA CLEANING & STANDARDIZATION
-- Description: Cleans raw types, filters invalid transactions, and removes duplicates.
-- ==============================================================================

-- STEP 1: Standardize Data Types in Staging
UPDATE online_retail_raw
SET customer_id = REPLACE(customer_id, '.0', '');

ALTER TABLE online_retail_raw
ALTER COLUMN customer_id TYPE INTEGER
USING NULLIF(customer_id, '')::INTEGER;

ALTER TABLE online_retail_raw
ALTER COLUMN invoice_date TYPE TIMESTAMP
USING invoice_date::TIMESTAMP;

-- STEP 2: Create Clean Fact Table
-- Removes null customers, negative quantities, and cancelled orders
CREATE TABLE transactions_clean AS
SELECT
    invoice_no,
    customer_id,
    invoice_date,
    quantity,
    unit_price,
    ROUND(quantity * unit_price, 2) AS line_total,
    country
FROM online_retail_raw
WHERE customer_id IS NOT NULL
  AND quantity > 0
  AND unit_price > 0
  AND invoice_no NOT LIKE 'C%';

-- STEP 3: Remove Exact Row Duplicates using Physical Location (ctid)
-- Ensures revenue is not artificially inflated by system logging errors
DELETE FROM transactions_clean
WHERE ctid IN (
    SELECT ctid
    FROM (
        SELECT ctid,
               ROW_NUMBER() OVER (
                   PARTITION BY invoice_no, customer_id, invoice_date, quantity, unit_price
                   ORDER BY ctid
               ) as row_num
        FROM transactions_clean
    ) t
    WHERE t.row_num > 1
);