-- ============================================================
-- UrbanNest Analytics — European Housing Intelligence
-- FILE: DC5_flag_price_outliers.sql
-- DESCRIPTION: Flag price outliers using IQR method
--              Adds is_price_outlier boolean column
-- STAKEHOLDER: Marco Ferretti — UrbanNest Italy | Operations
-- TABLE: ha_listings (modified in place)
-- ============================================================

-- ISSUE: price ranges from €0.01 to €190,205
-- Extreme values inflate every average and distort analysis
-- Decision: flag rather than drop — preserves data for audit

-- Step 1: Inspect price distribution
SELECT
    MIN(price)                                              AS min_price,
    MAX(price)                                              AS max_price,
    ROUND(AVG(price)::NUMERIC, 2)                           AS avg_price,
    ROUND(PERCENTILE_CONT(0.25) WITHIN GROUP
        (ORDER BY price)::NUMERIC, 2)                       AS q1,
    ROUND(PERCENTILE_CONT(0.75) WITHIN GROUP
        (ORDER BY price)::NUMERIC, 2)                       AS q3,
    ROUND(PERCENTILE_CONT(0.99) WITHIN GROUP
        (ORDER BY price)::NUMERIC, 2)                       AS p99
FROM ha_listings;

-- Step 2: Calculate IQR fences
-- Q1=285, Q3=640, IQR=355
-- Upper fence = 640 + (1.5 × 355) = 1,172.50
-- Lower fence = 285 - (1.5 × 355) = -247.50 (no lower outliers)
WITH iqr AS (
    SELECT
        PERCENTILE_CONT(0.25) WITHIN GROUP
            (ORDER BY price)::NUMERIC AS q1,
        PERCENTILE_CONT(0.75) WITHIN GROUP
            (ORDER BY price)::NUMERIC AS q3
    FROM ha_listings
)
SELECT
    q1, q3,
    q3 - q1                         AS iqr,
    q1 - 1.5 * (q3 - q1)           AS lower_fence,
    q3 + 1.5 * (q3 - q1)           AS upper_fence
FROM iqr;

-- Step 3: Add the flag column
ALTER TABLE ha_listings
ADD COLUMN IF NOT EXISTS is_price_outlier BOOLEAN DEFAULT FALSE;

-- Step 4: Set flag using IQR fences
WITH iqr AS (
    SELECT
        PERCENTILE_CONT(0.25) WITHIN GROUP
            (ORDER BY price)::NUMERIC AS q1,
        PERCENTILE_CONT(0.75) WITHIN GROUP
            (ORDER BY price)::NUMERIC AS q3
    FROM ha_listings
)
UPDATE ha_listings
SET is_price_outlier = CASE
    WHEN price < (q1 - 1.5 * (q3 - q1))
      OR price > (q3 + 1.5 * (q3 - q1))
    THEN TRUE
    ELSE FALSE
END
FROM iqr;

-- Step 5: Verify distribution
SELECT
    is_price_outlier,
    COUNT(*)                        AS listing_count,
    ROUND(AVG(price), 2)            AS avg_price
FROM ha_listings
GROUP BY is_price_outlier;
-- Expected: FALSE ~7,730 | TRUE ~1,186

-- KNOWN LIMITATION: IQR fence of €1,172.50 is conservative
-- Legitimate premium listings in Milan/Florence (€1,200–€3,200)
-- are caught in the outlier flag because dataset is dominated by
-- shared/private rooms (median ~€400) compressing Q3 to €640
-- Decision: flag retained as-is
-- All AQ queries use WHERE is_price_outlier = FALSE
