-- ============================================================
-- UrbanNest Analytics — European Housing Intelligence
-- FILE: AQ6_registration_compliance.sql
-- DESCRIPTION: Registration compliance rate and price premium
-- STAKEHOLDER: Marco Ferretti — UrbanNest Italy | Operations
-- DATASET: ha_listings | FILTER: is_price_outlier = FALSE
-- ============================================================

-- Business Question: Does legal registration status affect price?
-- One row in city_comp CTE = one city (dual FILTER aggregation)

-- FINDING: All 12 qualifying cities show High compliance (>66%)
-- Bologna (-10.21%) and Rome (-9.76%): non-registerable listings
-- price HIGHER — high-end landlords avoid registration for tax reasons
-- Milan (+1.42%, n=1,029): compliance does not move price at scale
-- Florence (66.49%): only Medium city — lowest compliance among majors

WITH city_comp AS (
    SELECT
        city,
        COUNT(*)                                            AS total_listings,
        COUNT(*) FILTER
            (WHERE registration_possible = 'yes')          AS registerable_count,
        ROUND(AVG(price) FILTER
            (WHERE registration_possible = 'yes')::NUMERIC, 2)
                                                            AS avg_price_registerable,
        ROUND(AVG(price) FILTER
            (WHERE registration_possible = 'no')::NUMERIC, 2)
                                                            AS avg_price_not_registerable
    FROM ha_listings
    WHERE is_price_outlier = FALSE
        AND registration_possible IS NOT NULL
    GROUP BY city
    HAVING COUNT(*) >= 30
)
SELECT
    city,
    total_listings,
    registerable_count,
    ROUND(registerable_count * 100.0 / total_listings, 1) AS registerable_pct,
    avg_price_registerable,
    avg_price_not_registerable,
    ROUND((avg_price_registerable - avg_price_not_registerable) * 100.0
        / NULLIF(avg_price_not_registerable, 0), 2)        AS price_premium_pct,
    CASE
        WHEN registerable_count * 100.0 / total_listings > 70
            THEN 'High'
        WHEN registerable_count * 100.0 / total_listings >= 40
            THEN 'Medium'
        ELSE 'Low'
    END                                                     AS compliance_flag
FROM city_comp
ORDER BY registerable_pct DESC;
