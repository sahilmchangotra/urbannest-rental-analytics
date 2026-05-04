-- ============================================================
-- UrbanNest Analytics — European Housing Intelligence
-- FILE: AQ4_price_per_sqm.sql
-- DESCRIPTION: Price per square metre by city
-- STAKEHOLDER: Priya Sharma — NestIndia | Pricing Analytics
-- DATASET: ha_listings | FILTER: is_price_outlier = FALSE
-- ============================================================

-- Business Question: Where do renters pay most per sqm?
-- One row in size_cast CTE = one listing with safe numeric cast

-- FINDING: Naples charges more per sqm (€6.22) than Milan (€5.91)
-- despite lower absolute price (€300 vs €600) — smaller unit sizes
-- Siena max of €81.82/sqm driven by single listing (€900/11sqm)
-- 11sqm is at boundary of valid range — median (€5.04) unaffected
-- KEY INSIGHT: Absolute price and price per sqm tell different stories

WITH size_cast AS (
    SELECT
        city,
        price,
        total_size::NUMERIC                                 AS size_sqm
    FROM ha_listings
    WHERE is_price_outlier = FALSE
        AND total_size IS NOT NULL
),
valid AS (
    SELECT
        city,
        price,
        ROUND(price / NULLIF(size_sqm, 0), 2)              AS price_per_sqm
    FROM size_cast
    WHERE size_sqm BETWEEN 10 AND 400
)
SELECT
    city,
    COUNT(*)                                                AS valid_listing_count,
    ROUND(AVG(price_per_sqm), 2)                           AS avg_price_per_sqm,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP
        (ORDER BY price_per_sqm)::NUMERIC, 2)              AS median_price_per_sqm,
    ROUND(MIN(price_per_sqm), 2)                           AS min_price_per_sqm,
    ROUND(MAX(price_per_sqm), 2)                           AS max_price_per_sqm
FROM valid
GROUP BY city
HAVING COUNT(*) >= 20
ORDER BY median_price_per_sqm DESC;
