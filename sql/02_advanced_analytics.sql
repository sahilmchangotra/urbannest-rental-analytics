-- ============================================================
-- UrbanNest Analytics — European Housing Intelligence
-- FILE: 02_advanced_analytics.sql
-- DESCRIPTION: Advanced SQL Analytics — INTERVAL, Rolling
--              Averages, YoY Comparison, Discount Simulation
-- STAKEHOLDERS: Lars van Dijk (RentNest Netherlands)
--               Priya Sharma (NestIndia)
-- DATASET: ha_listings_clean
-- ============================================================


-- ============================================================
-- Q1: Listing Age Analysis using INTERVAL
-- Business Question: How does listing age affect pricing?
-- Stakeholder: Lars van Dijk
-- ============================================================

-- One row = one age bucket

WITH ref_date AS (
    SELECT MAX(DATE(created_at)) AS max_date
    FROM ha_listings_clean
),
listings_age AS (
    SELECT
        DATE(created_at)                AS created_at,
        ROUND(price::NUMERIC, 2)        AS price,
        r.max_date
    FROM ha_listings_clean, ref_date r
    WHERE is_price_outlier = FALSE
),
listings_bucket AS (
    SELECT
        *,
        (max_date - created_at)         AS days_old,
        CASE
            WHEN created_at >= max_date - INTERVAL '90 days'
                THEN 'Last 90 days'
            WHEN created_at >= max_date - INTERVAL '180 days'
                THEN '90-180 days'
            WHEN created_at >= max_date - INTERVAL '365 days'
                THEN '180-365 days'
            ELSE 'Over 1 year'
        END                             AS age_bucket
    FROM listings_age
)
SELECT
    age_bucket,
    COUNT(*)                                                AS total_listings,
    ROUND(AVG(price), 2)                                   AS avg_price,
    ROUND(PERCENTILE_CONT(0.5)
        WITHIN GROUP (ORDER BY price)::NUMERIC, 2)         AS median_price,
    MIN(created_at)                                        AS oldest_listing,
    MAX(created_at)                                        AS newest_listing
FROM listings_bucket
GROUP BY age_bucket
ORDER BY
    CASE age_bucket
        WHEN 'Last 90 days'   THEN 1
        WHEN '90-180 days'    THEN 2
        WHEN '180-365 days'   THEN 3
        ELSE 4
    END;

-- FINDING: Newest listings (last 90 days) priced 43% higher
--          than oldest (£554 vs £389)
-- INSIGHT: Italian rental prices rose significantly 2016→2020
-- NOTE: Use MAX(created_at) as ref date not CURRENT_DATE
--       for historical datasets


-- ============================================================
-- Q2: Monthly Listing Seasonality
-- Business Question: Which months see most new listings?
-- Stakeholder: Priya Sharma
-- ============================================================

-- One row in base CTE = one year + month

WITH listing_stats AS (
    SELECT
        EXTRACT(YEAR FROM created_at)           AS year,
        EXTRACT(MONTH FROM created_at)          AS month,
        COUNT(*)                                AS monthly_listings
    FROM ha_listings_clean
    WHERE is_price_outlier = FALSE
    GROUP BY
        EXTRACT(YEAR FROM created_at),
        EXTRACT(MONTH FROM created_at)
),
yoy_calc AS (
    SELECT
        *,
        LAG(monthly_listings, 12)
            OVER (ORDER BY year, month)         AS prev_year_listings,
        ROUND((monthly_listings
            - LAG(monthly_listings, 12)
                OVER (ORDER BY year, month))
            * 100.0
            / NULLIF(LAG(monthly_listings, 12)
                OVER (ORDER BY year, month), 0)
            , 2)                                AS yoy_growth_pct
    FROM listing_stats
),
monthly_avg AS (
    SELECT
        month,
        ROUND(AVG(monthly_listings), 2)         AS avg_monthly_listings,
        ROUND(AVG(yoy_growth_pct), 2)           AS avg_yoy_growth_pct
    FROM yoy_calc
    GROUP BY month
)
SELECT
    month,
    TO_CHAR(TO_DATE(month::TEXT, 'MM'), 'Month') AS month_name,
    avg_monthly_listings,
    avg_yoy_growth_pct,
    RANK() OVER (
        ORDER BY avg_monthly_listings DESC
    )                                           AS rank
FROM monthly_avg
ORDER BY rank;

-- FINDING: June #1 (255 avg listings) — summer peak
--          December #12 (97 avg listings) — lowest supply
-- INSIGHT: June-July peak driven by student housing cycle
--          Landlord acquisition campaigns needed April-May


-- ============================================================
-- Q3: 30-Day Rolling Average of New Listings Per City
-- Business Question: Which cities are gaining/losing
-- supply momentum?
-- Stakeholder: Lars van Dijk
-- ============================================================

-- One row in base CTE = one city + one day

WITH qualifying_cities AS (
    SELECT city
    FROM ha_listings_clean
    WHERE is_price_outlier = FALSE
    GROUP BY city
    HAVING COUNT(*) >= 100
),
city_listings AS (
    SELECT
        city,
        DATE(created_at)                        AS listing_date,
        COUNT(*)                                AS daily_listings
    FROM ha_listings_clean
    WHERE is_price_outlier = FALSE
        AND city IN (SELECT city FROM qualifying_cities)
    GROUP BY city, DATE(created_at)
),
rolling_avg AS (
    SELECT
        *,
        ROUND(AVG(daily_listings) OVER (
            PARTITION BY city
            ORDER BY listing_date
            ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
        ), 2)                                   AS rolling_30d_avg
    FROM city_listings
)
SELECT
    city,
    listing_date,
    daily_listings,
    rolling_30d_avg
FROM rolling_avg
ORDER BY city, listing_date;

-- FINDING: Bologna peaks in June — student housing cycle
-- INSIGHT: 30-day rolling smooths day-to-day noise
--          revealing true supply momentum per city
-- NOTE: PARTITION BY city resets rolling average per city
--       29 PRECEDING + CURRENT ROW = 30 day window


-- ============================================================
-- Q4: Same Month Last Year — Price Comparison Per City
-- Business Question: Which cities show real price inflation
-- vs seasonal noise?
-- Stakeholder: Priya Sharma
-- ============================================================

-- One row in base CTE = one city + year + month

WITH qualifying_cities AS (
    SELECT city
    FROM ha_listings_clean
    WHERE is_price_outlier = FALSE
    GROUP BY city
    HAVING COUNT(*) >= 100
),
city_listings AS (
    SELECT
        city,
        EXTRACT(YEAR FROM created_at)           AS year,
        EXTRACT(MONTH FROM created_at)          AS month,
        ROUND(PERCENTILE_CONT(0.5)
            WITHIN GROUP (ORDER BY price)::NUMERIC, 2) AS median_price
    FROM ha_listings_clean
    WHERE is_price_outlier = FALSE
        AND city IN (SELECT city FROM qualifying_cities)
    GROUP BY
        city,
        EXTRACT(YEAR FROM created_at),
        EXTRACT(MONTH FROM created_at)
),
previous_year_median AS (
    SELECT
        *,
        LAG(median_price, 12) OVER (
            PARTITION BY city
            ORDER BY year, month
        )                                       AS prev_year_median
    FROM city_listings
),
yoy_change AS (
    SELECT
        *,
        ROUND((median_price - prev_year_median)
            * 100.0
            / NULLIF(prev_year_median, 0), 2)   AS yoy_price_change_pct
    FROM previous_year_median
)
SELECT
    city,
    year,
    month,
    median_price,
    prev_year_median,
    yoy_price_change_pct
FROM yoy_change
WHERE prev_year_median IS NOT NULL
ORDER BY city, year, month;

-- FINDING: Florence strongest inflation — Jan 2019 +73%
--          Milan most stable — consistent ±10-30% YoY
--          Pisa Feb 2020 +300% — low volume, unreliable
-- INSIGHT: LAG(12) PARTITION BY city = same month last year
--          per city independently — no cross-city bleed
-- NOTE: Extreme spikes in low-volume months are unreliable
--       median — flag when monthly_listings < 5


-- ============================================================
-- Q5: Discount Simulation — Premium & Mid-range Tiers
-- Business Question: Impact of 10% discount on Premium
-- and 5% on Mid-range listings per city
-- Stakeholder: Lars van Dijk
-- ============================================================

-- One row in base CTE = one listing (NTILE needs raw rows!)

WITH listings_tiered AS (
    SELECT
        city,
        price,
        NTILE(3) OVER (ORDER BY price ASC)      AS ntile_rank
    FROM ha_listings_clean
    WHERE is_price_outlier = FALSE
),
discount_applied AS (
    SELECT
        city,
        price,
        CASE
            WHEN ntile_rank = 3 THEN 'Premium'
            WHEN ntile_rank = 2 THEN 'Mid-range'
            WHEN ntile_rank = 1 THEN 'Budget'
        END                                     AS tier,
        CASE
            WHEN ntile_rank = 3 THEN ROUND(price * 0.90, 2)
            WHEN ntile_rank = 2 THEN ROUND(price * 0.95, 2)
            ELSE price
        END                                     AS discounted_price
    FROM listings_tiered
)
SELECT
    city,
    COUNT(*)                                    AS total_listings,
    ROUND(SUM(price), 2)                        AS original_revenue,
    ROUND(SUM(discounted_price), 2)             AS discounted_revenue,
    ROUND(SUM(price)
        - SUM(discounted_price), 2)             AS revenue_impact,
    ROUND((SUM(price) - SUM(discounted_price))
        * 100.0 / SUM(price), 2)               AS pct_impact,
    COUNT(*) FILTER(WHERE tier = 'Premium')     AS premium_count,
    COUNT(*) FILTER(WHERE tier = 'Mid-range')   AS mid_range_count,
    COUNT(*) FILTER(WHERE tier = 'Budget')      AS budget_count
FROM discount_applied
GROUP BY city
ORDER BY revenue_impact DESC;

-- FINDING: Milan highest absolute impact £84,868 (9.37%)
--          Bologna lowest % impact (3.38%) — budget market
--          Modena + Messina zero impact — all Budget tier
-- INSIGHT: Blanket discount campaigns don't work for
--          budget-heavy cities like Bologna and Parma
--          Premium discounts most effective in Milan/Florence
-- NOTE: NTILE needs raw listing rows — never GROUP BY before!