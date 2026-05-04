-- ============================================================
-- UrbanNest Analytics — European Housing Intelligence
-- FILE: AQ8_city_amenity_scorecard.sql
-- DESCRIPTION: City investment scorecard — board summary
-- STAKEHOLDER: Lars van Dijk — RentNest Netherlands | Market Strategy
-- DATASET: ha_listings | FILTER: is_price_outlier = FALSE
-- ============================================================

-- Business Question: Which cities score best across price,
--                    amenities, compliance, and supply volume?
-- Formula: amenity_score*40 + compliance_rate*0.3 + (1.0/price_rank)*30

-- FINDING: Milan #1 (score 124) on price dominance — not amenity quality
-- Padova hidden gem: highest amenity score (1.96) + 94.4% compliance
-- Ancona: 100% compliance — fully legal market despite lowest price
-- Naples last (score 73): only city below 50% compliance (41.2%)
-- NOTE: Use 1.0/median_price_rank NOT 1/median_price_rank
--       Integer division gives 0 for any rank > 1 — kills the formula

-- FORMULA WEIGHT ANALYSIS:
-- amenity_score * 40: max = 5 * 40 = 200 (dominant component)
-- compliance_rate * 0.3: max = 100 * 0.3 = 30
-- (1.0/rank) * 30: max = 1/1 * 30 = 30
-- Validate weights with board before presenting as final

WITH listing_scored AS (
    SELECT
        city,
        price,
        (CASE WHEN washing_machine = 'yes' THEN 1 ELSE 0 END
       + CASE WHEN tv = 'yes' THEN 1 ELSE 0 END
       + CASE WHEN balcony IN ('yes','shared','private') THEN 1 ELSE 0 END
       + CASE WHEN garden IN ('yes','shared','private') THEN 1 ELSE 0 END
       + CASE WHEN terrace IN ('yes','shared','private') THEN 1 ELSE 0 END)
                                                            AS amenity_count,
        CASE
            WHEN registration_possible = 'yes' THEN 1
            WHEN registration_possible = 'no'  THEN 0
            ELSE NULL
        END                                                 AS is_reg
    FROM ha_listings
    WHERE is_price_outlier = FALSE
),
city_stats AS (
    SELECT
        city,
        COUNT(*)                                            AS supply_volume,
        ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP
            (ORDER BY price)::NUMERIC, 2)                  AS median_price,
        ROUND(AVG(amenity_count)::NUMERIC, 3)              AS amenity_score,
        ROUND(AVG(is_reg) * 100.0, 1)                     AS compliance_rate
    FROM listing_scored
    GROUP BY city
    HAVING COUNT(*) >= 50
),
ranked AS (
    SELECT *,
        RANK() OVER (
            ORDER BY median_price DESC
        )                                                   AS median_price_rank
    FROM city_stats
)
SELECT
    city,
    supply_volume,
    median_price,
    median_price_rank,
    amenity_score,
    compliance_rate,
    ROUND(
        amenity_score * 40
        + compliance_rate * 0.3
        + (1.0 / median_price_rank) * 30
    , 2)                                                    AS overall_score,
    RANK() OVER (
        ORDER BY
            amenity_score * 40
            + compliance_rate * 0.3
            + (1.0 / median_price_rank) * 30 DESC
    )                                                       AS overall_rank
FROM ranked
ORDER BY overall_rank;
