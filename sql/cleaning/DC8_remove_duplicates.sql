-- ============================================================
-- UrbanNest Analytics — European Housing Intelligence
-- FILE: DC8_remove_duplicates.sql
-- DESCRIPTION: Detect and remove exact duplicate rows
-- STAKEHOLDER: Marco Ferretti — UrbanNest Italy | Operations
-- TABLE: ha_listings (modified in place)
-- ============================================================

-- ISSUE: Dataset contains exact duplicate rows
-- All 13 columns identical to another row

-- Step 1: Detect duplicate groups
SELECT
    city, category, created_at, price,
    furnished, total_size, registration_possible,
    washing_machine, tv, balcony, garden, terrace,
    COUNT(*) AS duplicate_count
FROM ha_listings
GROUP BY
    city, category, created_at, price,
    furnished, total_size, registration_possible,
    washing_machine, tv, balcony, garden, terrace
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;
-- Expected: 4 duplicate groups found

-- Step 2: Check total before
SELECT COUNT(*) AS total_before FROM ha_listings;
-- Expected: 8,916

-- Step 3: Remove exact duplicates using ctid
DELETE FROM ha_listings
WHERE ctid NOT IN (
    SELECT MIN(ctid)
    FROM ha_listings
    GROUP BY
        city, category, created_at, price,
        furnished, total_size, registration_possible,
        washing_machine, tv, balcony, garden, terrace
);

-- Step 4: Verify final row count
SELECT COUNT(*) AS final_row_count FROM ha_listings;
-- Expected: 8,912

-- Step 5: Confirm zero exact duplicates remain
SELECT COUNT(*) AS remaining_duplicates
FROM (
    SELECT
        city, category, created_at, price,
        furnished, total_size, registration_possible,
        washing_machine, tv, balcony, garden, terrace,
        COUNT(*) AS cnt
    FROM ha_listings
    GROUP BY
        city, category, created_at, price,
        furnished, total_size, registration_possible,
        washing_machine, tv, balcony, garden, terrace
    HAVING COUNT(*) > 1
) sub;
-- Expected: 0

-- DC8 ADDENDUM: Near-duplicate found during AQ4 investigation
-- Siena Shared Room €267/230sqm submitted twice on 2017-05-08
-- 09:34:10 vs 12:27:33 — 3-hour gap, all amenity fields identical
-- Decision: RETAIN — created_at differs, cannot confirm double
--           submission without platform logs
-- Pattern consistent with Milan 1-second pair found in DC8
-- Impact on AQ4 median: immaterial (1 of 68 valid Siena rows)

-- FINAL CLEAN DATASET SUMMARY:
-- Total rows:         8,912
-- Cities:             30
-- Categories:         4
-- Analytical base:    7,727 (is_price_outlier = FALSE)
-- Earliest listing:   2016-01-02
-- Latest listing:     2020-02-09
-- ref_date:           2020-02-09
