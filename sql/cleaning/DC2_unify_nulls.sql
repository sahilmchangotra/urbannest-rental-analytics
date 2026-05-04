-- ============================================================
-- UrbanNest Analytics — European Housing Intelligence
-- FILE: DC2_unify_nulls.sql
-- DESCRIPTION: Unify three null representations into real NULL
--              string 'null' + empty string '' + real NULL
-- STAKEHOLDER: Marco Ferretti — UrbanNest Italy | Operations
-- TABLE: ha_listings (modified in place)
-- ============================================================

-- ISSUE: Three ways of saying missing data coexist in dataset:
-- 1. Real NULL (Python None on load)
-- 2. String 'null' (4-character text value)
-- 3. Empty string '' (zero-length text)
-- A WHERE col IS NULL check misses 'null' strings entirely

-- Step 1: Inspect all three types in furnished column
SELECT
    COUNT(*) FILTER (WHERE furnished IS NULL)           AS true_null,
    COUNT(*) FILTER (WHERE furnished = 'null')          AS string_null,
    COUNT(*) FILTER (WHERE furnished = '')              AS empty_string,
    COUNT(*) FILTER (WHERE furnished IS NOT NULL
                      AND furnished != 'null'
                      AND furnished != '')              AS real_values
FROM ha_listings;

-- Step 2: Unify all null types across all columns
-- Pattern: NULLIF(NULLIF(col, ''), 'null')
-- Inner NULLIF: '' → NULL
-- Outer NULLIF: 'null' → NULL
-- True NULLs pass through unchanged
UPDATE ha_listings
SET
    city                   = NULLIF(NULLIF(city, ''), 'null'),
    category               = NULLIF(NULLIF(category, ''), 'null'),
    furnished              = NULLIF(NULLIF(furnished, ''), 'null'),
    washing_machine        = NULLIF(NULLIF(washing_machine, ''), 'null'),
    tv                     = NULLIF(NULLIF(tv, ''), 'null'),
    balcony                = NULLIF(NULLIF(balcony, ''), 'null'),
    garden                 = NULLIF(NULLIF(garden, ''), 'null'),
    terrace                = NULLIF(NULLIF(terrace, ''), 'null'),
    registration_possible  = NULLIF(NULLIF(registration_possible, ''), 'null'),
    total_size             = NULLIF(NULLIF(total_size, ''), 'null');

-- Step 3: Verify — should return 0
SELECT COUNT(*)
FROM ha_listings
WHERE furnished = 'null'
   OR furnished = ''
   OR washing_machine = 'null'
   OR washing_machine = '';
-- Expected: 0
