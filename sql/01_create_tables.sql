-- ==============================================================================
-- 01: STAGING TABLE
-- Creates the raw staging table for the UCI Online Retail II dataset.
-- Import the CSV ONCE (pgAdmin: right-click online_retail_raw > Import/Export Data).
-- Importing twice doubles every row. Check after import:
--     SELECT COUNT(*) FROM online_retail_raw;   -- expected 1,067,371
-- ==============================================================================

CREATE TABLE IF NOT EXISTS online_retail_raw (
    invoice_no   VARCHAR(50),
    stock_code   VARCHAR(50),
    description  VARCHAR(255),
    quantity     INT,
    invoice_date VARCHAR(50),
    unit_price   NUMERIC,
    customer_id  VARCHAR(50),
    country      VARCHAR(100)
);
