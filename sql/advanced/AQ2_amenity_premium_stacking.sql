-- ============================================================
-- UrbanNest Analytics — European Housing Intelligence
-- FILE: AQ2_amenity_premium_stacking.sql
-- DESCRIPTION: Price premium by amenity count vs zero-amenity baseline
-- STAKEHOLDER: Priya Sharma — NestIndia | Pricing Analytics
-- DATASET: ha_listings | FILTER: is_price_outlier = FALSE
-- ============================================================

-- Business Question: Does having more amenities mean higher price?
-- One row in scored CTE = one listing with amenity_count derived

-- FINDING: Zero-amenity baseline has only 3 listings (avg €577)
-- Rome Studio €1,000 + Rome Private Room €580 + Ancona Shared Room €150
-- Negative premiums across all groups are an artefact of thin baseline
-- INSIGHT: Amenity stacking does not drive price — city does
-- Confirmed by NB4 regression: R²=0.013 (size only) → R²=0.617 (+ city)

WITH scored AS (
    SELECT
        price,
        (CASE WHEN washing_machine = 'yes' THEN 1 ELSE 0 END
       + CASE WHEN tv = 'yes' THEN 1 ELSE 0 END
       + CASE WHEN balcony IN ('yes','shared','private') THEN 1 ELSE 0 END)
                                                            AS amenity_count
    FROM ha_listings
    WHERE is_price_outlier = FALSE
        AND washing_machine IS NOT NULL
        AND tv IS NOT NULL
        AND balcony IS NOT NULL
),
baseline AS (
    SELECT AVG(price) AS base_avg
    FROM scored
    WHERE amenity_count = 0
)
SELECT
    amenity_count,
    COUNT(*)                                                AS listing_count,
    ROUND(AVG(price)::NUMERIC, 2)                          AS avg_price,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP
        (ORDER BY price)::NUMERIC, 2)                      AS median_price,
    ROUND((AVG(price) - base_avg) * 100.0
        / NULLIF(base_avg, 0), 2)                          AS pct_premium_vs_no_amenities,
    CASE
        WHEN COUNT(*) < 10 THEN 'Unreliable — thin sample'
        ELSE 'Reliable'
    END                                                     AS sample_reliability
FROM scored
CROSS JOIN baseline
GROUP BY amenity_count, base_avg
ORDER BY amenity_count;
