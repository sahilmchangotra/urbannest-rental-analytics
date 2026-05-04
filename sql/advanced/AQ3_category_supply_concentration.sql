-- ============================================================
-- UrbanNest Analytics — European Housing Intelligence
-- FILE: AQ3_category_supply_concentration.sql
-- DESCRIPTION: Category supply concentration per city
-- STAKEHOLDER: Marco Ferretti — UrbanNest Italy | Operations
-- DATASET: ha_listings | FILTER: is_price_outlier = FALSE
-- ============================================================

-- Business Question: Which cities are one-room-type markets?
-- One row in cat_counts CTE = one city + category combination

-- FINDING: 17 of 19 qualifying cities Concentrated in Private Room
-- Florence (57.74%) and Trento (46.93%) are Moderately Concentrated
-- Trento is the ONLY city where Private Room is NOT the top category
-- Zero Balanced cities — Private Room structurally dominates Italy

WITH cat_counts AS (
    SELECT
        city,
        category,
        COUNT(*)                                            AS cat_count,
        SUM(COUNT(*)) OVER (PARTITION BY city)             AS city_total,
        ROUND(COUNT(*) * 100.0
            / SUM(COUNT(*)) OVER (PARTITION BY city), 2)  AS cat_pct
    FROM ha_listings
    WHERE is_price_outlier = FALSE
    GROUP BY city, category
),
ranking AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY city
            ORDER BY cat_count DESC
        )                                                   AS rn
    FROM cat_counts
    WHERE city_total >= 30
)
SELECT
    city,
    city_total                                              AS total_listings,
    category                                                AS dominant_category,
    cat_pct                                                 AS dominant_pct,
    CASE
        WHEN cat_pct > 60  THEN 'Concentrated'
        WHEN cat_pct >= 40 THEN 'Moderately Concentrated'
        ELSE 'Balanced'
    END                                                     AS market_type
FROM ranking
WHERE rn = 1
ORDER BY dominant_pct DESC;
