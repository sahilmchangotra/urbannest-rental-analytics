-- ============================================================
-- UrbanNest Analytics — European Housing Intelligence
-- FILE: AQ1_city_market_tiering.sql
-- DESCRIPTION: City market tiering using NTILE(3) on median price
-- STAKEHOLDER: Lars van Dijk — RentNest Netherlands | Market Strategy
-- DATASET: ha_listings | FILTER: is_price_outlier = FALSE
-- ============================================================

-- Business Question: Which cities are Premium, Mid-Tier, Emerging?
-- One row in listing_base CTE = one city (aggregated median)

-- FINDING: Milan leads Premium at €600 — €100 above Rome/Florence
-- 19 of 30 cities qualify (≥30 listings)
-- Bologna (Emerging €280) has more listings than Rome (Premium €500)
-- Verona in Premium with only 31 listings — treat cautiously

WITH listing_base AS (
    SELECT
        city,
        COUNT(*)                                            AS listing_count,
        ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP
            (ORDER BY price)::NUMERIC, 2)                  AS median_price
    FROM ha_listings
    WHERE is_price_outlier = FALSE
    GROUP BY city
    HAVING COUNT(*) >= 30
),
quantiled AS (
    SELECT
        *,
        NTILE(3) OVER (ORDER BY median_price ASC)          AS price_quantile
    FROM listing_base
)
SELECT
    city,
    listing_count,
    median_price,
    CASE
        WHEN price_quantile = 1 THEN 'Emerging'
        WHEN price_quantile = 2 THEN 'Mid-Tier'
        WHEN price_quantile = 3 THEN 'Premium'
    END                                                     AS price_tier,
    RANK() OVER (
        PARTITION BY price_quantile
        ORDER BY median_price DESC
    )                                                       AS rank_in_tier
FROM quantiled
ORDER BY median_price DESC;
