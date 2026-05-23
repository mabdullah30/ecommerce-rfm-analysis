-- ==============================================================================
-- 01: STAGING ENVIRONMENT SETUP
-- Description: Creates the raw staging table for the online retail dataset.
-- ==============================================================================

CREATE TABLE online_retail_raw (
    invoice_no VARCHAR(50),
    stock_code VARCHAR(50),
    description VARCHAR(255),
    quantity INT,
    invoice_date VARCHAR(50),
    unit_price NUMERIC,
    customer_id VARCHAR(50),
    country VARCHAR(100)
);