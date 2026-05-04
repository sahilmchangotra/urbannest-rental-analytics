-- ============================================================
-- UrbanNest Analytics — European Housing Intelligence
-- FILE: DC6_clean_total_size.sql
-- DESCRIPTION: Clean total_size column — null out non-numeric
--              values, document impossible sizes
-- STAKEHOLDER: Marco Ferretti — UrbanNest Italy | Operations
-- TABLE: ha_listings (modified in place)
-- ============================================================

-- ISSUE: total_size stored as VARCHAR
-- Contains impossible values: 3,000 / 5,000 / 10,000 sqm
-- Contains non-numeric value: '"80-100 m2"' (1 row)
-- 4,888 of 10,000 rows missing

-- Step 1: Inspect current state
SELECT
    COUNT(*)                                            AS total_rows,
    COUNT(*) FILTER (WHERE total_size ~ '^[0-9.]+$')   AS numeric_size_count,
    MIN(CASE WHEN total_size ~ '^[0-9.]+$'
        THEN total_size::NUMERIC END)                   AS min_size,
    MAX(CASE WHEN total_size ~ '^[0-9.]+$'
        THEN total_size::NUMERIC END)                   AS max_size,
    COUNT(*) FILTER (WHERE total_size ~ '^[0-9.]+$'
        AND total_size::NUMERIC > 400)                  AS above_400,
    COUNT(*) FILTER (WHERE total_size ~ '^[0-9.]+$'
        AND total_size::NUMERIC < 10)                   AS below_10
FROM (
    SELECT NULLIF(NULLIF(TRIM(BOTH '"' FROM total_size), 'null'), '')
        AS total_size
    FROM ha_listings
) sub;

-- Step 2: Check for non-numeric pollutants
SELECT total_size, COUNT(*)
FROM ha_listings
WHERE TRIM(BOTH '"' FROM total_size) !~ '^[0-9.]+$'
    AND TRIM(BOTH '"' FROM total_size) NOT IN ('null', '')
    AND total_size IS NOT NULL
GROUP BY 1;
-- Found: '"80-100 m2"' — 1 row

-- DECISION: '80-100 m2' (1 row) → total_size = NULL, row retained
-- Rationale: row has valid city/category/price — only size unusable
-- The regex guard '^[0-9.]+$' handles this automatically

-- Step 3: Null out non-numeric and empty total_size values
UPDATE ha_listings
SET total_size = NULL
WHERE total_size IS NOT NULL
  AND (
      TRIM(BOTH '"' FROM total_size) !~ '^[0-9.]+$'
   OR TRIM(BOTH '"' FROM total_size) IN ('null', '')
  );

-- Step 4: Verify — should return 0 rows
SELECT total_size, COUNT(*)
FROM ha_listings
WHERE total_size IS NOT NULL
  AND TRIM(BOTH '"' FROM total_size) !~ '^[0-9.]+$'
GROUP BY 1;

-- Step 5: Final size column health check
SELECT
    COUNT(*)                    AS total_rows,
    COUNT(total_size)           AS non_null_size,
    MIN(total_size::NUMERIC)    AS min_size,
    MAX(total_size::NUMERIC)    AS max_size,
    COUNT(*) FILTER (WHERE total_size::NUMERIC > 400) AS above_400,
    COUNT(*) FILTER (WHERE total_size::NUMERIC < 10)  AS below_10
FROM ha_listings
WHERE total_size IS NOT NULL;
-- Expected: 4,220 non-null | min=0 | max=10,000 | 34 above 400 | 65 below 10

-- NOTE: total_size = 0 — 7 rows found (impossible value)
-- Included in below_10 count of 65
-- Handled in AQ4 via BETWEEN 10 AND 400 — no UPDATE needed
-- NOTE: Effective valid size count = 4,220
-- (5,112 from Python pre-dates null unification — SQL count is correct)
