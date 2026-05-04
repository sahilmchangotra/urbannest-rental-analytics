-- ============================================================
-- UrbanNest Analytics — European Housing Intelligence
-- FILE: AQ7_listing_survival_analysis.sql
-- DESCRIPTION: Do overpriced listings linger longer on platform?
-- STAKEHOLDER: Priya Sharma — NestIndia | Pricing Analytics
-- DATASET: ha_listings | FILTER: is_price_outlier = FALSE
-- ============================================================

-- Business Question: Do overpriced listings linger longest?
-- One row in aged CTE = one listing (NTILE on raw rows)

-- HYPOTHESIS: Overpriced listings linger longer → REJECTED
-- FINDING: Cheap listings (Q1, avg €220) are oldest — 1,072 days median
-- Expensive listings (Q4, avg €700) are newest — 657 days median
-- Q1 vs Q4 gap: 415 days — consistent across both avg and median
-- POSSIBLE EXPLANATION: Platform launched with budget inventory (2016)
-- Premium listings added later (2018-2020) — making them newer by default
-- SQL cannot distinguish — booking/conversion data required to confirm

-- NOTE: age_days = ref_date - created_at
-- ref_date = MAX(DATE(created_at)) = 2020-02-09
-- NEVER use CURRENT_DATE for historical datasets

WITH ref AS (
    SELECT MAX(DATE(created_at)) AS max_date
    FROM ha_listings
),
aged AS (
    SELECT
        price,
        (r.max_date - DATE(created_at))                    AS age_days,
        NTILE(4) OVER (ORDER BY price ASC)                 AS price_quartile
    FROM ha_listings, ref r
    WHERE is_price_outlier = FALSE
)
SELECT
    price_quartile,
    COUNT(*)                                                AS listing_count,
    ROUND(AVG(price), 2)                                   AS avg_price,
    ROUND(AVG(age_days), 2)                                AS avg_age_days,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP
        (ORDER BY age_days::NUMERIC), 1)                   AS median_age_days
FROM aged
GROUP BY price_quartile
ORDER BY price_quartile;
