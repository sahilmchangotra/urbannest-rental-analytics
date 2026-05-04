-- ============================================================
-- UrbanNest Analytics — European Housing Intelligence
-- FILE: DC1_strip_triple_quotes.sql
-- DESCRIPTION: Strip triple-quoted string artefacts from all
--              boolean/categorical columns
-- STAKEHOLDER: Marco Ferretti — UrbanNest Italy | Operations
-- TABLE: ha_listings (modified in place)
-- ============================================================

-- ISSUE: All categorical columns stored with surrounding double
-- quotes e.g. '"yes"' instead of 'yes' — CSV export artefact

-- Step 1: Inspect before cleaning
SELECT DISTINCT furnished
FROM ha_listings
ORDER BY 1;
-- Expected: '"yes"', '"no"', '"null"', '""', NULL

-- Step 2: Clean all 7 affected columns
UPDATE ha_listings
SET
    furnished              = NULLIF(NULLIF(TRIM(BOTH '"' FROM furnished), ''), 'null'),
    washing_machine        = NULLIF(NULLIF(TRIM(BOTH '"' FROM washing_machine), ''), 'null'),
    tv                     = NULLIF(NULLIF(TRIM(BOTH '"' FROM tv), ''), 'null'),
    balcony                = NULLIF(NULLIF(TRIM(BOTH '"' FROM balcony), ''), 'null'),
    garden                 = NULLIF(NULLIF(TRIM(BOTH '"' FROM garden), ''), 'null'),
    terrace                = NULLIF(NULLIF(TRIM(BOTH '"' FROM terrace), ''), 'null'),
    registration_possible  = NULLIF(NULLIF(TRIM(BOTH '"' FROM registration_possible), ''), 'null');

-- Step 3: Verify — should return 0 rows
SELECT DISTINCT furnished
FROM ha_listings
WHERE furnished LIKE '"%"'
   OR furnished = '';
-- Expected: 0 rows

-- FINDING: '"yes"' → 'yes' | '"no"' → 'no' | '""' → NULL
-- NOTE: Run DC1 before DC2 — otherwise '"null"' won't match
--       after stripping and DC2's 'null' check will miss it
