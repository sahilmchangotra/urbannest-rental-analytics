-- ============================================================
-- UrbanNest Analytics — European Housing Intelligence
-- FILE: AQ5_furnished_premium_pivot.sql
-- DESCRIPTION: Furnished premium % by city × category cross-tab
-- STAKEHOLDER: Lars van Dijk — RentNest Netherlands | Market Strategy
-- DATASET: ha_listings | FILTER: is_price_outlier = FALSE
-- ============================================================

-- Business Question: Does furnished premium vary by city AND category?
-- One row in final SELECT = one city (4 premium columns via FILTER)

-- FINDING: Furnished premium is NOT consistent across city + category
-- Shared Rooms show strongest premium: Rome +47.3%, Siena +47.5%
-- Furnished apartments in Milan charge 7.7% LESS than unfurnished
-- DATA QUALITY FLAG: Bologna Studio +74% based on n=2 unfurnished
-- listings — statistically unreliable. Treat as directional only.

WITH base AS (
    SELECT city, category, furnished, price
    FROM ha_listings
    WHERE is_price_outlier = FALSE
        AND furnished IN ('yes', 'no')
),
top_cities AS (
    SELECT city
    FROM base
    GROUP BY city
    ORDER BY COUNT(*) DESC
    LIMIT 8
)
SELECT
    city,
    ROUND(
        (AVG(price) FILTER (WHERE category='Apartment' AND furnished='yes')
       - AVG(price) FILTER (WHERE category='Apartment' AND furnished='no'))
        * 100.0
        / NULLIF(AVG(price) FILTER (WHERE category='Apartment'
            AND furnished='no'), 0)
    , 2)                                                    AS apartment_furnished_prem_pct,
    ROUND(
        (AVG(price) FILTER (WHERE category='Private Room' AND furnished='yes')
       - AVG(price) FILTER (WHERE category='Private Room' AND furnished='no'))
        * 100.0
        / NULLIF(AVG(price) FILTER (WHERE category='Private Room'
            AND furnished='no'), 0)
    , 2)                                                    AS private_room_furnished_prem_pct,
    ROUND(
        (AVG(price) FILTER (WHERE category='Shared Room' AND furnished='yes')
       - AVG(price) FILTER (WHERE category='Shared Room' AND furnished='no'))
        * 100.0
        / NULLIF(AVG(price) FILTER (WHERE category='Shared Room'
            AND furnished='no'), 0)
    , 2)                                                    AS shared_room_furnished_prem_pct,
    ROUND(
        (AVG(price) FILTER (WHERE category='Studio' AND furnished='yes')
       - AVG(price) FILTER (WHERE category='Studio' AND furnished='no'))
        * 100.0
        / NULLIF(AVG(price) FILTER (WHERE category='Studio'
            AND furnished='no'), 0)
    , 2)                                                    AS studio_furnished_prem_pct
FROM base
WHERE city IN (SELECT city FROM top_cities)
GROUP BY city
ORDER BY city;
