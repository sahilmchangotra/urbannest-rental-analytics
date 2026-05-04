-- ============================================================
-- UrbanNest Analytics — European Housing Intelligence
-- FILE: DC3_drop_missing_city.sql
-- DESCRIPTION: Remove rows with missing city — cannot assign
--              to any market segment
-- STAKEHOLDER: Marco Ferretti — UrbanNest Italy | Operations
-- TABLE: ha_listings (modified in place)
-- ============================================================

-- ISSUE: 596 rows have NULL city after DC2 unification
-- Every analytical question is city-level — these rows are unusable
-- City cannot be imputed from price or category alone

-- Step 1: Confirm count before deletion
SELECT COUNT(*) AS missing_city_rows
FROM ha_listings
WHERE city IS NULL;
-- Expected: 596 rows

-- Step 2: Check total before
SELECT COUNT(*) AS total_before FROM ha_listings;
-- Expected: 10,000

-- Step 3: Delete missing city rows
DELETE FROM ha_listings
WHERE city IS NULL;

-- Step 4: Verify count after
SELECT COUNT(*) AS total_after FROM ha_listings;
-- Expected: 9,404

-- DECISION: Dropped — city cannot be imputed
-- ROWS REMOVED: 596
