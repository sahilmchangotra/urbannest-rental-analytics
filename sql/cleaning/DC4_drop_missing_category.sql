-- ============================================================
-- UrbanNest Analytics — European Housing Intelligence
-- FILE: DC4_drop_missing_category.sql
-- DESCRIPTION: Remove rows with missing category — room type
--              unknown, cannot be used in segmentation
-- STAKEHOLDER: Marco Ferretti — UrbanNest Italy | Operations
-- TABLE: ha_listings (modified in place)
-- ============================================================

-- ISSUE: 599 rows have NULL category after DC2
-- category (Shared Room/Private Room/Studio/Apartment) is used
-- in every segmentation and pricing query

-- Step 1: Inspect overlap between missing city and category
SELECT
    COUNT(*) FILTER (WHERE city IS NULL)                AS missing_city,
    COUNT(*) FILTER (WHERE category IS NULL)            AS missing_category,
    COUNT(*) FILTER (WHERE city IS NULL
                      AND category IS NULL)             AS missing_both
FROM ha_listings;

-- Step 2: Check count before deletion
SELECT COUNT(*) AS total_before FROM ha_listings;
-- Expected: 9,404 (after DC3)

-- Step 3: Delete missing category rows
DELETE FROM ha_listings
WHERE category IS NULL;

-- Step 4: Verify
SELECT COUNT(*) AS total_after FROM ha_listings;
-- Expected: 8,916

-- DECISION: Dropped — room type cannot be imputed
-- ROWS REMOVED: 488 (some rows lost both city AND category in DC3)
