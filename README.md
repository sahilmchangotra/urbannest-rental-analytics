# UrbanNest Analytics — European Housing Intelligence

**SQL + Python + Tableau Data Analysis Portfolio | Italian Rental Market Intelligence**

Sahil Changotra • The Hague, Netherlands • 2026

---

## 📋 Repository Overview

| Field | Detail |
|---|---|
| Dataset | HousingAnywhere Italian Rental Listings |
| Source | Kaggle — European Rental Market Data |
| Raw Rows | 10,000 listings |
| Stage Rows | 8,916 (after DC1–DC4) |
| Clean Rows | 8,912 (after DC1–DC8, all cleaning steps) |
| Analytical Base | 7,727 listings (is_price_outlier = FALSE) |
| Country | Italy |
| Cities | 30 Italian cities — Milan, Rome, Florence, Bologna + 26 others |
| Qualifying Cities | 19 cities (≥ 30 listings) for analytical queries |
| Date Range | 2016-01-02 — 2020-02-09 |
| Reference Date | 2020-02-09 (MAX created_at — used for all age calculations) |
| SQL Stack | PostgreSQL / DataGrip |
| Python Stack | pandas · numpy · scipy · sklearn · statsmodels · matplotlib · seaborn |
| Tableau | Tableau Public — 4-dashboard story |
| Target Roles | Data Analyst — JET SODA Amsterdam · BOL Retail Media Netherlands · DLL Eindhoven |

---

## 🔄 Three-Phase Analytical Workflow

```
Phase 1 — SQL Cleaning               Phase 2 — SQL Analytics            Phase 3 — Python
──────────────────────────           ──────────────────────────          ──────────────────────────────────
DC1: Strip triple quotes      →      Q1–Q5: Phase 1 advanced SQL  →     Deep cleaning & feature engineering
DC2: Unify null types         →      AQ1–AQ8: Advanced analytics  →     EDA with visualisations
DC3: Drop missing city        →      City tiering, amenity score  →     Statistical hypothesis testing
DC4: Drop missing category    →      Furnished premium pivot      →     Regression modelling
DC5: Flag price outliers      →      Registration compliance      →     Assumption checks
DC6: Clean total_size         →      Listing survival analysis    →
DC7: Cast created_at          →      City investment scorecard    →
DC8: Remove duplicates        →                                   →
```

---

## 📁 Repository Structure

```
urbannest-rental-analytics/
├── sql/
│   ├── cleaning/
│   │   ├── DC1_strip_triple_quotes.sql
│   │   ├── DC2_unify_nulls.sql
│   │   ├── DC3_drop_missing_city.sql
│   │   ├── DC4_drop_missing_category.sql
│   │   ├── DC5_flag_price_outliers.sql
│   │   ├── DC6_clean_total_size.sql
│   │   ├── DC7_cast_created_at.sql
│   │   └── DC8_remove_duplicates.sql
│   ├── phase1/
│   │   └── 02_advanced_analytics.sql     ← Q1–Q5 Phase 1 questions
│   └── advanced/
│       ├── AQ1_city_market_tiering.sql
│       ├── AQ2_amenity_premium_stacking.sql
│       ├── AQ3_category_supply_concentration.sql
│       ├── AQ4_price_per_sqm.sql
│       ├── AQ5_furnished_premium_pivot.sql
│       ├── AQ6_registration_compliance.sql
│       ├── AQ7_listing_survival_analysis.sql
│       └── AQ8_city_amenity_scorecard.sql
├── notebooks/
│   ├── 01_data_cleaning.ipynb            ← ✅ Complete
│   ├── 02_eda_analysis.ipynb             ← ✅ Complete
│   ├── 03_hypothesis_testing.ipynb       ← ✅ Complete
│   └── 04_regression_analysis.ipynb      ← ✅ Complete
├── data/
│   ├── ha_data_assessment.csv            ← Raw source (never modified)
│   ├── ha_listings_raw.csv               ← Backup copy of raw data
│   ├── ha_data_clean.csv                 ← Cleaned dataset from NB1 (Python)
│   ├── listings_base.csv                 ← Tableau data source 1
│   ├── city_scorecard.csv                ← Tableau data source 2 (AQ8)
│   ├── furnished_premium.csv             ← Tableau data source 3 (AQ5)
│   ├── monthly_supply.csv                ← Tableau data source 4
│   └── data_dictionary.md                ← Column definitions
├── outputs/
│   ├── [EDA charts — NB2]
│   ├── [Hypothesis test charts — NB3]
│   └── [Regression diagnostic charts — NB4]
└── README.md
```

---

## 🗄️ Phase 1 — SQL Data Cleaning (DC1–DC8)

**Database:** PostgreSQL | **Table:** `ha_listings` | **Tool:** DataGrip
**Raw backup:** `ha_listings_raw` — never modified, recovery point for all cleaning steps

### Raw Data Issues Found

| DC Step | Column(s) Affected | Issue | Rows Affected | Action |
|---|---|---|---|---|
| DC1 | furnished, washing_machine, tv, balcony, garden, terrace, registration_possible | Values stored as `"yes"` (triple-quoted CSV artefact) | ~5,000+ cells | `TRIM(BOTH '"' FROM col)` |
| DC2 | All categorical columns | Three null types: real NULL, string `'null'`, empty string `''` | All 10,000 rows | `NULLIF(NULLIF(col, ''), 'null')` |
| DC3 | city | 596 rows with blank/null city — cannot assign to any market | 596 rows | DELETE |
| DC4 | category | 599 rows with blank/null category — room type unknown | 488 rows (post DC3) | DELETE |
| DC5 | price | Range: €0.01 to €190,205 — extreme outliers skew averages | 1,186 flagged | IQR flag added |
| DC6 | total_size | Stored as VARCHAR; values like 3,000/5,000/10,000 sqm impossible; `"80-100 m2"` non-numeric | 4,888 missing; 103 out-of-range | CAST + regex guard + range filter |
| DC7 | created_at | Already TIMESTAMP — verified, no action needed | 0 | Documented |
| DC8 | All columns | 5 exact duplicate rows found | 4 removed | ROW_NUMBER deduplication |

### DC5 — Price Outlier Flag: IQR Results

```
Q1 = €285  |  Q3 = €640  |  IQR = €355
Upper fence = €640 + (1.5 × €355) = €1,172.50
Lower fence = €285 − (1.5 × €355) = −€247.50 (no lower outliers)

KNOWN LIMITATION: IQR fence of €1,172.50 is conservative.
Legitimate premium listings in Milan/Florence (€1,200–€3,200) are
caught in the outlier flag because the dataset is dominated by
shared/private rooms (median ~€400) which compresses Q3 to €640.
Decision: flag retained. All AQ queries use WHERE is_price_outlier = FALSE.
```

### DC6 — total_size Notable Findings

```
Valid numeric count after cleaning: 4,220 rows
Values = 0 sqm: 7 rows (impossible — handled by BETWEEN 10 AND 400 in AQ4)
Values > 400 sqm: 34 rows (data entry errors)
Values < 10 sqm: 65 rows (includes 0 sqm)
Non-numeric value: "80-100 m2" (1 row) → nulled, row retained
Decision: total_size::NUMERIC BETWEEN 10 AND 400 applied in AQ4 only
```

### DC8 — Duplicate Investigation

```
Exact duplicates removed: 4 rows (3 groups × 2 duplicates)
Near-duplicate noted: Siena Shared Room €267/230sqm — submitted 3 times
  Row 1: 2017-04-26 (different garden value) → retained
  Row 2: 2017-05-08 09:34 → retained
  Row 3: 2017-05-08 12:27 (3-hour gap, identical) → pattern noted, retained
  Decision: created_at differs — cannot confirm double submission without platform logs
```

### Clean Dataset Summary

```
Total rows after DC1–DC8:  8,912
Cities:                    30
Categories:                4 (Shared Room · Private Room · Studio · Apartment)
Analytical base:           7,727 (is_price_outlier = FALSE)
Earliest listing:          2016-01-02
Latest listing:            2020-02-09
Reference date:            2020-02-09 (MAX created_at)
Rows removed from raw:     1,088 total
  → 596 missing city (DC3)
  → 488 missing category (DC4)
  → 4 exact duplicates (DC8)
```

---

## 🗄️ Phase 2 — SQL Advanced Analytics

### Phase 1 Questions (Q1–Q5)

**Standard filter:** `WHERE is_price_outlier = FALSE`

| # | Business Question | Stakeholder | SQL Concepts | Key Finding |
|---|---|---|---|---|
| Q1 | How does listing age affect pricing? | Lars van Dijk (RentNest NL) | INTERVAL buckets, PERCENTILE_CONT, CTE, MAX(date) ref_date | Newest listings (last 90 days) priced 43% higher — €554 vs €389. Real price inflation 2016→2020 |
| Q2 | Which months see most new listings? | Priya Sharma (NestIndia) | LAG(12) YoY, RANK(), two-layer aggregation | June #1 (255 avg listings) — student housing cycle. December lowest supply |
| Q3 | Which cities are gaining/losing supply momentum? | Lars van Dijk | 30-day rolling avg, ROWS BETWEEN 29 PRECEDING, PARTITION BY city | Bologna peaks in June. Rolling avg reveals true supply momentum per city |
| Q4 | Which cities show real price inflation vs seasonal noise? | Priya Sharma | LAG(12) PARTITION BY city, PERCENTILE_CONT, YoY % | Florence strongest inflation (+73% Jan 2019). Milan most stable (±10-30% YoY) |
| Q5 | Impact of 10% discount (Premium) and 5% (Mid-range) per city | Lars van Dijk | NTILE(3), CASE discount, FILTER(WHERE), revenue impact | Milan highest absolute impact €84,868 (9.37%). Budget cities (Bologna, Parma) unaffected |

---

### Advanced Analytics Questions (AQ1–AQ8)

**Standard filter:** `WHERE is_price_outlier = FALSE` | **Qualifying cities:** ≥ 30 listings

#### AQ1 — City Market Tiering
**Stakeholder:** Lars van Dijk — RentNest Netherlands
**Concepts:** NTILE(3) on city medians · PERCENTILE_CONT · HAVING ≥ 30 · RANK() within tier

| Tier | Cities | Median Price Range |
|---|---|---|
| Premium | Milan, Rome, Florence, Verona, Brescia, Turin | €420–€600 |
| Mid-Tier | Venice, Bari, Padova, Pavia, Pisa, Naples | €300–€400 |
| Emerging | Siena, Bologna, Trento, Parma, Trieste, Catania, Ancona | €200–€300 |

**Key findings:**
- Milan leads Premium tier at €600 — €100 above Rome/Florence
- 19 of 30 cities qualify (≥ 30 listings); 11 excluded for thin data
- Bologna (Emerging, €280) has more listings (1,695) than Rome (Premium, €500, 446)
- Verona in Premium with only 31 listings — treat cautiously

---

#### AQ2 — Amenity Premium Stacking
**Stakeholder:** Priya Sharma — NestIndia
**Concepts:** Per-row CASE scoring · GROUP BY amenity count · CROSS JOIN baseline · NULLIF

| Amenity Count | Listings | Avg Price | Reliability |
|---|---|---|---|
| 0 | 3 | €577 | ⚠️ Unreliable (n=3) |
| 1 | 130 | €296 | ✅ Reliable |
| 2 | 464 | €392 | ✅ Reliable |
| 3 | 313 | €346 | ✅ Reliable |

**Key finding:** Zero-amenity baseline (n=3) is statistically unreliable — 2 Rome listings at €580/€1,000 inflate the average to €577. Amenity stacking does not linearly increase price. City and category are stronger determinants (confirmed by NB4 regression R²=0.617).

---

#### AQ3 — Category Supply Concentration
**Stakeholder:** Marco Ferretti — UrbanNest Italy
**Concepts:** SUM(COUNT(*)) OVER (PARTITION BY city) · ROW_NUMBER top-per-group · Two-level aggregation

| Market Type | Cities | Count |
|---|---|---|
| Concentrated (>60% Private Room) | Bari (90.9%), Brescia (88.2%), Trieste (80.2%), Pavia (80%), Parma (78.5%), Rome (78%), Catania (72.1%), Naples (71.9%), Pisa (71.4%), Ancona (70.8%), Milan (70.4%), Venice (68.8%), Padova (68.8%), Siena (65.7%), Bologna (64.5%), Verona (64.5%), Turin (61.3%) | 17 |
| Moderately Concentrated | Florence (57.7%), Trento (46.9% — Shared Room dominant) | 2 |
| Balanced | None | 0 |

**Key finding:** Private Room structurally dominates the Italian rental market. Zero balanced cities. Trento is the only city where Private Room is not the top category.

---

#### AQ4 — Price Per Square Metre
**Stakeholder:** Priya Sharma — NestIndia
**Concepts:** NULLIF + TRIM + ::NUMERIC CAST on sparse string · range filter 10–400 sqm · PERCENTILE_CONT

| City | Valid Listings | Median Price/sqm |
|---|---|---|
| Naples | 26 | €6.22 |
| Florence | 567 | €5.98 |
| Milan | 806 | €5.91 |
| Rome | 248 | €5.31 |
| Siena | 68 | €5.04 |
| ... | ... | ... |
| Parma | 34 | €2.67 |

**Key finding:** Naples charges more per sqm than Milan (€6.22 vs €5.91) despite lower absolute price (€300 vs €600). Smaller unit sizes inflate per-sqm rate. Absolute price and price per sqm tell completely different stories.
**Data quality note:** Siena max of €81.82/sqm driven by single listing (€900/11sqm) at boundary of valid range. Median (€5.04) unaffected.

---

#### AQ5 — Furnished Premium by City × Category
**Stakeholder:** Lars van Dijk — RentNest Netherlands
**Concepts:** FILTER(WHERE) cross-tab pivot · NULLIF for missing cells · LIMIT top-8 cities

| City | Apartment | Private Room | Shared Room | Studio |
|---|---|---|---|---|
| Bologna | +20.3% | -4.5% | +5.4% | +74%⚠️ |
| Florence | -6.0% | +3.5% | +24.9% | -11.6% |
| Milan | -7.7% | -1.9% | +3.0% | -6.1% |
| Pisa | -20.3% | -2.8% | -3.3% | +10.2% |
| Rome | +0.3% | -11.9% | +47.3% | -3.2% |
| Siena | — | +23.4% | +47.5% | +6.0% |
| Trento | — | -8.6% | -8.8% | — |
| Turin | +38.7% | +6.5% | +9.2% | -27.3% |

**Key finding:** Furnished premium is not consistent — varies wildly by city AND category. Shared Rooms show strongest furnished premium (Rome +47.3%, Siena +47.5%). Furnished apartments in Milan charge 7.7% LESS than unfurnished.
**Data quality flag:** Bologna Studio +74% based on only 2 unfurnished listings (n=2 baseline) — statistically unreliable.

---

#### AQ6 — Registration Compliance Rate
**Stakeholder:** Marco Ferretti — UrbanNest Italy
**Concepts:** FILTER(WHERE) dual aggregation · CTE to avoid alias reuse · NULLIF price premium

| City | Compliance Rate | Price Premium (Registerable vs Not) | Flag |
|---|---|---|---|
| Brescia | 98.18% | +71.78% | High |
| Padova | 94.44% | +9.79% | High |
| Milan | 88.63% | +1.42% | High |
| Pisa | 87.33% | +5.33% | High |
| Bologna | 77.51% | -10.21% | High |
| Rome | 71.09% | -9.76% | High |
| Florence | 66.49% | +6.34% | Medium |

**Key finding:** All 12 qualifying cities show High compliance (>66%). Counter-intuitive finding: Bologna and Rome non-registerable listings price HIGHER than registerable ones. Hypothesis: high-end landlords avoid registration for tax reasons — premium properties, low compliance. Milan (n=1,029): compliance does not move price (+1.42%).

---

#### AQ7 — Listing Survival Analysis
**Stakeholder:** Priya Sharma — NestIndia
**Concepts:** NTILE(4) on raw rows · ref_date CTE (MAX not CURRENT_DATE) · Date arithmetic

| Price Quartile | Avg Price | Avg Age (days) | Median Age (days) |
|---|---|---|---|
| Q1 (cheapest) | €220 | 1,058 | 1,072 |
| Q2 | €311 | 971 | 988 |
| Q3 | €426 | 705 | 704 |
| Q4 (most expensive) | €700 | 644 | 657 |

**Hypothesis tested:** Do overpriced listings linger longer?
**Result: REJECTED** — cheap listings linger longest. Q1 listings are 414 days older than Q4 on average. Two possible explanations: (1) platform launched with budget inventory in 2016, premium listings came later; (2) cheap listings genuinely convert slower. SQL cannot distinguish — booking data required.

---

#### AQ8 — City Amenity Scorecard
**Stakeholder:** Lars van Dijk — RentNest Netherlands (board presentation)
**Concepts:** 5-amenity per-row scoring · Three-CTE chain · RANK() for two metrics · Composite score formula
**Formula:** `overall_score = amenity_score × 40 + compliance_rate × 0.3 + (1.0/median_price_rank) × 30`

| Rank | City | Score | Amenity Score | Compliance | Median Price |
|---|---|---|---|---|---|
| 1 | Milan | 124 | 1.69 | 88.6% | €600 |
| 2 | Padova | 111 | 1.96 | 94.4% | €350 |
| 3 | Siena | 105 | 1.88 | 87.3% | €300 |
| 4 | Venice | 100 | 1.71 | 87.8% | €400 |
| 5 | Ancona | 98 | 1.65 | 100% | €200 |
| ... | ... | ... | ... | ... | ... |
| 16 | Naples | 73 | 1.41 | 41.2% | €300 |

**Key findings:**
- Milan #1 on price dominance — not amenity quality
- Padova hidden gem: highest amenity score (1.96) + 94.4% compliance
- Ancona: 100% registration compliance — fully legal market
- Naples last: only city below 50% compliance (41.2%)
- Formula heavily favours amenity_score (max contribution 200 vs 30 each for price/compliance)

---

### SQL Golden Rules Applied Throughout

| Rule | Application |
|---|---|
| `is_price_outlier = FALSE` | Standard filter on all AQ queries |
| NTILE on raw rows | AQ1 (on city medians), AQ7 (on listing rows) — never GROUP BY before NTILE |
| LAG granularity | Q2, Q4 — aggregate first, then LAG |
| PERCENTILE_CONT in CTE | Q1, Q4, AQ1, AQ4, AQ8 — own GROUP BY required |
| MAX(created_at) not CURRENT_DATE | Q1, AQ7 — historical dataset, ref_date = 2020-02-09 |
| PARTITION BY resets window | Q3, Q4 — per-city rolling avg and YoY |
| FILTER(WHERE) dual aggregation | AQ5, AQ6 — no subquery needed |
| LOD expressions for sort | Tableau: FIXED [City] for Private Room % sort |
| NULLIF division guard | AQ2, AQ4, AQ5, AQ6 — prevents division by zero |
| CTE chain for aliases | AQ6, AQ8 — cannot reference alias in same SELECT |
| 1.0 not 1 for division | AQ8 overall_score — integer division kills formula |

---

## 📊 Tableau Dashboard

**Published:** [UrbanNest Italian Rental Analytics — Interactive Story](https://public.tableau.com/app/profile/sahil.changotra/viz/UrbanNest-Italian-Rental-Analytics-2016-2020/UrbanNestAnalytics#2)

### 4-Dashboard Story Structure

| Story Point | Dashboard | Charts | Key Message |
|---|---|---|---|
| 1 | Market Overview | Category mix stacked bar (AQ3) + City median price bar (AQ1) | Private Room dominates 17/19 cities · Milan leads at €600 |
| 2 | Market Trends | Monthly supply + rolling 3M avg · Supply vs price dual axis | June peaks every year · Median price rose 96% (2016→2020) |
| 3 | Pricing Intelligence | City median price bar (tiered) + Furnished premium heatmap (AQ5) | Furnished premium varies wildly by city AND category |
| 4 | City Investment Scorecard | Overall scorecard bar (AQ8) + Compliance rate bar (AQ6) | Milan #1 · Padova hidden gem · Naples lowest compliance |

### Tableau Data Sources

| CSV | Powers | Key Fields |
|---|---|---|
| listings_base.csv | KPI cards, city bar, category mix | city, category, price, furnished, amenity_count, is_reg, is_price_outlier |
| city_scorecard.csv | AQ8 scorecard, compliance chart | city, overall_score, overall_rank, amenity_score, compliance_rate, price_tier |
| furnished_premium.csv | AQ5 heatmap | city, category, premium_pct, reliability |
| monthly_supply.csv | Seasonality line, dual axis chart | listing_month, monthly_listings, median_price, rolling_3m_avg |

---

## 📓 Phase 3 — Python Notebooks

### Notebook 1 — Data Cleaning
**Libraries:** pandas, numpy

| Task | Detail |
|---|---|
| Raw rows | 10,000 |
| Clean rows | 8,874 |
| Rows removed | 1,126 (duplicates, nulls, invalid entries) |
| Output | ha_data_clean.csv exported for all downstream notebooks |

---

### Notebook 2 — Exploratory Data Analysis
**Libraries:** pandas, matplotlib, seaborn

| Analysis | Finding |
|---|---|
| Price distribution | Right-skewed — majority of listings €200–€800/month |
| City medians | Milan highest, Southern cities (Catania, Palermo) lowest |
| Category breakdown | Shared Rooms cheapest, Apartments most expensive |
| Furnished premium | Furnished listings consistently price higher across all cities |
| Supply trend | Listings grew significantly 2016→2019, dip in 2020 |

---

### Notebook 3 — Hypothesis Testing
**Libraries:** scipy.stats, matplotlib, seaborn

All three hypotheses tested at α = 0.05:

| # | Hypothesis | Test Used | Result | p-value |
|---|---|---|---|---|
| H1 | Furnished listings price > Unfurnished | Mann-Whitney U (one-tailed) | ✅ REJECT H0 | 0.000006 |
| H2 | Milan median price > Overall market median | One-sample t-test (one-tailed) | ✅ REJECT H0 | ≈0 (t=34.26) |
| H3 | Private Rooms price < Studios | Mann-Whitney U (one-tailed) | ✅ REJECT H0 | ≈0 |

---

### Notebook 4 — Regression Analysis
**Libraries:** sklearn, statsmodels, matplotlib, seaborn

#### Model Comparison

| Model | Features | R² | Interpretation |
|---|---|---|---|
| Simple Linear Regression | total_size only | 0.013 | 1.3% variance explained |
| Basic OLS | total_size + furnished + tv + washing_machine | 0.044 | 4.4% variance explained |
| Full OLS | + city (one-hot) + category (one-hot) | 0.617 | 61.7% variance explained ✅ |

#### Key Coefficients — Full OLS Model

**Category impact vs Apartment baseline:**

| Category | Coefficient | Significance |
|---|---|---|
| Shared Room | -€418/month | *** p<0.001 |
| Private Room | -€288/month | *** p<0.001 |
| Studio | -€136/month | *** p<0.001 |

**Top city premiums vs base city:**

| City | Premium | Significance |
|---|---|---|
| Milan | +€464/month | *** p<0.001 |
| Florence | +€381/month | *** p<0.001 |
| Rome | +€346/month | *** p<0.001 |
| Bolzano | +€336/month | *** p<0.001 |
| Venice | +€265/month | *** p<0.001 |

**Amenity features:**

| Feature | Coefficient | Significant? |
|---|---|---|
| Furnished | +€18/month | ✅ Yes (p=0.001) |
| Total size | +€0.08/sqm | ✅ Weakly (p=0.031) |
| TV | +€3.5/month | ❌ No (p=0.477) |
| Washing machine | -€14.7/month | ❌ No (p=0.081) |

#### Assumption Checks

| Assumption | Method | Result |
|---|---|---|
| Linearity | Scatterplots | ✅ Acceptable |
| Normality | Histogram + Q-Q plot | ⚠️ Slight right skew (0.355) — acceptable at n=3,405 |
| Constant Variance | Fitted vs residuals | ⚠️ Mild heteroscedasticity at higher price ranges |
| No Multicollinearity | VIF scores | ✅ All VIF < 5 (max: 4.52 washing_machine) |

**Business Insight:**
> City and listing type explain 61.7% of rental price variance. Amenities like TV and washing machine add no statistically significant premium. Landlords should price primarily based on city and room type — not amenity features. Milan commands a €464/month premium over the base city, making location the single most powerful pricing lever.

---

## 🔑 Key Findings Across All Phases

| Finding | Value | Source |
|---|---|---|
| Raw → clean rows (SQL) | 10,000 → 8,912 | DC1–DC8 |
| Analytical base | 7,727 listings | DC5 (is_price_outlier = FALSE) |
| IQR outlier fence | Upper: €1,172.50 · Lower: −€247.50 | DC5 |
| total_size valid range | 4,220 rows (10–400 sqm) | DC6 |
| Newest listings premium | 43% higher (€554 vs €389) | Q1 |
| Peak supply month | June (255 avg listings) — student cycle | Q2 |
| Strongest city inflation | Florence +73% Jan 2019 YoY | Q4 |
| Most stable city pricing | Milan ±10-30% YoY | Q4 |
| Highest discount impact | Milan — €84,868 (9.37%) | Q5 |
| City tiers (19 cities) | 6 Premium · 6 Mid-Tier · 7 Emerging | AQ1 |
| Amenity stacking | Non-linear — city dominates, not amenities | AQ2 |
| Category concentration | 17/19 cities Concentrated in Private Room | AQ3 |
| Naples price/sqm | €6.22 — higher than Milan (€5.91) | AQ4 |
| Strongest furnished premium | Rome Shared Room +47.3% | AQ5 |
| Furnished apt premium | Milan -7.7% — furnished = cheaper for apartments | AQ5 |
| Compliance leader | Ancona 100% · Naples lowest 41.2% | AQ6 |
| Listing survival finding | Cheap listings linger longest (opposite of hypothesis) | AQ7 |
| City scorecard #1 | Milan (score 124) — price dominance | AQ8 |
| Hidden gem city | Padova (score 111) — highest amenity score 1.96 | AQ8 |
| Raw → clean rows (Python) | 10,000 → 8,874 | NB1 |
| Full model R² | 0.617 — city + category explain 62% of price | NB4 |
| Most expensive city premium | Milan +€464/month | NB4 |
| Cheapest listing type | Shared Room -€418/month vs Apartment | NB4 |
| VIF max score | 4.52 (washing_machine) — no multicollinearity | NB4 |

---

## 🛠️ Methods & Libraries Used

| Method | Tool / Library | Phase |
|---|---|---|
| Triple-quote stripping | PostgreSQL TRIM(BOTH '"') | DC1 |
| Null unification | PostgreSQL NULLIF chain | DC2 |
| Price outlier flagging | PostgreSQL IQR method | DC5 |
| String-to-numeric CAST | PostgreSQL NULLIF + ::NUMERIC | DC6 |
| Duplicate removal | PostgreSQL ROW_NUMBER PARTITION BY all cols | DC8 |
| INTERVAL age buckets | PostgreSQL | Q1 |
| LAG(12) YoY comparison | PostgreSQL | Q2, Q4 |
| 30-day rolling average | PostgreSQL ROWS BETWEEN | Q3 |
| NTILE(3) tier segmentation | PostgreSQL | Q5, AQ1 |
| PERCENTILE_CONT median | PostgreSQL | Q1, Q4, AQ1, AQ4, AQ8 |
| FILTER(WHERE) pivot | PostgreSQL | AQ5, AQ6 |
| LOD expressions | Tableau | Dashboard sort |
| Dual axis chart | Tableau | Market Trends dashboard |
| Highlight actions | Tableau | Dashboard interactivity |
| Data cleaning, deduplication | pandas, numpy | NB1 |
| Price distribution, city medians | matplotlib, seaborn | NB2 |
| Mann-Whitney U test | scipy.stats | NB3 |
| One-sample t-test | scipy.stats | NB3 |
| Simple linear regression | sklearn | NB4 |
| OLS multiple regression | statsmodels | NB4 |
| VIF multicollinearity check | statsmodels | NB4 |
| Q-Q plot, residual analysis | statsmodels, matplotlib | NB4 |
| One-hot encoding | pandas get_dummies | NB4 |
| Train/test split (80/20) | sklearn | NB4 |

---

## 👤 About

| Field | Detail |
|---|---|
| Name | Sahil Changotra |
| Location | The Hague, Netherlands |
| GitHub | [github.com/sahilmchangotra](https://github.com/sahilmchangotra) |
| Tableau | [public.tableau.com/app/profile/sahil.changotra](https://public.tableau.com/app/profile/sahil.changotra) |
| Target Roles | Data Analyst — JET SODA Amsterdam · BOL Retail Media Netherlands · DLL Eindhoven · Myntra |
| Portfolio | Project 2 of 5 — Active Portfolio Development 2026 |