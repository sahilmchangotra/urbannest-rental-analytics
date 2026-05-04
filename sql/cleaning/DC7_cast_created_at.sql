-- ============================================================
-- UrbanNest Analytics — European Housing Intelligence
-- FILE: DC7_cast_created_at.sql
-- DESCRIPTION: Verify created_at data type and document
--              reference date for all analytical queries
-- STAKEHOLDER: Marco Ferretti — UrbanNest Italy | Operations
-- TABLE: ha_listings
-- ============================================================

-- Step 1: Check current data type
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'ha_listings'
  AND column_name = 'created_at';
-- Expected: data_type = 'timestamp without time zone'
-- Result: already TIMESTAMP — no action needed

-- Step 2: Validate date range
SELECT
    MIN(DATE(created_at))                           AS earliest_listing,
    MAX(DATE(created_at))                           AS latest_listing,
    COUNT(DISTINCT DATE_TRUNC('year', created_at))  AS years_covered,
    MAX(DATE(created_at))                           AS ref_date
FROM ha_listings;
-- Expected: 2016-01-02 to 2020-02-09 — 5 years of data

-- FINDING: created_at already stored as TIMESTAMP in ha_listings
-- Data range: 2016-01-02 to 2020-02-09
-- Total rows: 8,916 (post DC3 + DC4 deletions)
-- DC7 requires zero action — column type already correct

-- RULE for all AQ queries:
-- Always use MAX(DATE(created_at)) as reference date
-- NEVER use CURRENT_DATE — this is a historical dataset
-- ref_date = 2020-02-09
