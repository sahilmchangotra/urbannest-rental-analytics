# UrbanNest Analytics — European Housing Intelligence

**SQL + Python Data Analysis Portfolio | Rental Market Intelligence**

Sahil Changotra • The Hague, Netherlands • March 2026

---

## 📋 Repository Overview

| Field | Detail |
|---|---|
| Dataset | HousingAnywhere Italian Rental Listings |
| Source | Kaggle — European Rental Market Data |
| Raw Rows | 10,000 listings |
| Clean Rows | 8,874 (after NB1 cleaning) |
| Country | Italy |
| Cities | 25+ Italian cities including Milan, Rome, Florence, Bologna |
| Date Range | 2016 — 2020 |
| SQL Stack | PostgreSQL / DataGrip |
| Python Stack | pandas • numpy • scipy • sklearn • statsmodels • matplotlib • seaborn |
| Target Roles | Data Analyst — JET SODA Amsterdam \| BOL Retail Media Netherlands |

---

## 🔄 Two-Phase Analytical Workflow

This project follows a real-world two-phase approach:

```
Phase 1 — SQL                          Phase 2 — Python
─────────────────────────────          ──────────────────────────────────
Data exploration & profiling    →      Deep cleaning & feature engineering
Advanced analytics (INTERVAL,   →      EDA with visualisations
  Rolling Avg, YoY, NTILE)      →      Statistical hypothesis testing
Business questions answered     →      Regression modelling & assumptions
```

---

## 📁 Repository Structure

```
urbannest-rental-analytics/
├── sql/
│   └── 02_advanced_analytics.sql     ← 5 advanced SQL questions
├── notebooks/
│   ├── 01_data_cleaning.ipynb        ← ✅ Complete
│   ├── 02_eda_analysis.ipynb         ← ✅ Complete
│   ├── 03_hypothesis_testing.ipynb   ← ✅ Complete
│   └── 04_regression_analysis.ipynb  ← ✅ Complete
├── data/
│   ├── ha_data_clean.csv             ← Cleaned dataset from NB1
│   └── data_dictionary.md            ← Column definitions
├── outputs/
│   ├── 01_missing_values.png
│   ├── 02_price_distribution.png
│   ├── 03_city_median_price.png
│   ├── 04_category_breakdown.png
│   ├── 05_furnished_vs_unfurnished.png
│   ├── 06_city_category_heatmap.png
│   ├── 07_supply_trend.png
│   ├── 08_outlier_comparison.png
│   ├── h1_furnished_vs_unfurnished.png
│   ├── h2_milan_vs_market.png
│   ├── h3_private_vs_studio.png
│   ├── hypothesis_summary.png
│   ├── nb4_linearity_check.png
│   ├── nb4_normality_check.png
│   ├── nb4_constant_variance_check.png
│   ├── nb4_normality_full_model.png
│   ├── nb4_constant_variance_full_model.png
│   └── nb4_simple_regression.png
└── README.md
```

---

## 🗄️ Phase 1 — SQL Analysis

**Database:** PostgreSQL | **Table:** `ha_listings_clean` | **Tool:** DataGrip

**Standard filter applied to all queries:**
```sql
WHERE is_price_outlier = FALSE
```

### SQL Question Bank

| # | Business Question | Stakeholder | SQL Concepts | Key Finding |
|---|---|---|---|---|
| Q1 | Listing age analysis — how does age affect pricing? | Lars van Dijk (RentNest NL) | INTERVAL buckets, PERCENTILE_CONT, CTE | Newest listings (last 90 days) priced 43% higher than oldest (€554 vs €389) |
| Q2 | Monthly listing seasonality — which months see most new listings? | Priya Sharma (NestIndia) | LAG(12), YoY growth %, RANK(), two-layer aggregation | June #1 (255 avg listings) — student housing cycle. December lowest supply |
| Q3 | 30-day rolling avg of new listings per city — supply momentum | Lars van Dijk | ROWS BETWEEN 29 PRECEDING, PARTITION BY city, min 100 listings | Bologna peaks in June. Rolling avg reveals true supply momentum per city |
| Q4 | Same month last year price comparison per city — real inflation vs noise | Priya Sharma | LAG(12) PARTITION BY city, PERCENTILE_CONT, YoY % | Florence strongest inflation (+73% Jan 2019). Milan most stable (±10-30% YoY) |
| Q5 | Discount simulation — 10% Premium, 5% Mid-range per city | Lars van Dijk | NTILE(3), CASE discount, FILTER(WHERE), revenue impact | Milan highest absolute impact €84,868 (9.37%). Budget cities unaffected |

### SQL Golden Rules Applied

| Rule | Application |
|---|---|
| NTILE needs raw rows | Q5 — never GROUP BY before NTILE |
| LAG granularity | Q2, Q4 — aggregate first, then LAG |
| PERCENTILE_CONT separate CTE | Q1, Q4 — own GROUP BY required |
| MAX(date) not CURRENT_DATE | Q1 — historical dataset, use MAX(created_at) |
| PARTITION BY resets window | Q3, Q4 — per-city rolling avg and YoY |

---

## 📓 Phase 2 — Python Notebooks

### Notebook 1 — Data Cleaning
**Libraries:** pandas, numpy

| Task | Detail |
|---|---|
| Raw rows | 10,000 |
| Clean rows | 8,874 |
| Rows removed | 1,126 (duplicates, nulls, invalid entries) |
| Output | ha_data_clean.csv exported for all downstream notebooks |
| Key columns | city, category, price, furnished, total_size |

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
| Outlier comparison | Price outliers removed — distribution normalises significantly |

---

### Notebook 3 — Hypothesis Testing
**Libraries:** scipy.stats, matplotlib, seaborn

All three hypotheses tested at α = 0.05:

| # | Hypothesis | Test Used | Result | p-value |
|---|---|---|---|---|
| H1 | Furnished listings price > Unfurnished | Mann-Whitney U (one-tailed) | ✅ REJECT H0 | 0.000006 |
| H2 | Milan median price > Overall market median | One-sample t-test (one-tailed) | ✅ REJECT H0 | 0.000000 (t=34.26) |
| H3 | Private Rooms price < Studios | Mann-Whitney U (one-tailed) | ✅ REJECT H0 | 0.000000 |

**All three null hypotheses rejected at p < 0.05** — results are statistically significant.

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
| Linearity | Scatterplots — features vs price | ✅ Acceptable |
| Normality | Histogram + Q-Q plot of residuals | ⚠️ Slight right skew (0.355) — acceptable at n=3,405 |
| Constant Variance | Fitted values vs residuals scatterplot | ⚠️ Mild heteroscedasticity at higher price ranges |
| No Multicollinearity | VIF scores | ✅ All VIF < 5 (max: 4.52 washing_machine) |

#### Business Insight

> City and listing type (category) explain **61.7% of rental price variance** in Italian listings. Amenities like TV and washing machine add no statistically significant premium. Landlords should price primarily based on city and room type — not amenity features. Milan commands a €464/month premium over the base city, making location the single most powerful pricing lever.

---

## 🔑 Key Findings Across All Phases

| Finding | Value | Source |
|---|---|---|
| Newest listings priced higher | 43% premium — €554 vs €389 | SQL Q1 |
| Peak supply month | June (255 avg listings) — student cycle | SQL Q2 |
| Lowest supply month | December (97 avg listings) | SQL Q2 |
| Strongest city price inflation | Florence +73% Jan 2019 YoY | SQL Q4 |
| Most stable city pricing | Milan ±10-30% YoY | SQL Q4 |
| Highest discount impact city | Milan — €84,868 revenue impact | SQL Q5 |
| Raw → clean rows | 10,000 → 8,874 | NB1 |
| Milan median price premium | Significantly above market (t=34.26) | NB3 |
| Furnished vs unfurnished | Statistically significant price difference | NB3 |
| Private rooms vs studios | Private rooms significantly cheaper | NB3 |
| Best single predictor | City — not size or amenities | NB4 |
| Full model R² | 0.617 — city + category explain 62% of price | NB4 |
| Most expensive city | Milan (+€464/month premium) | NB4 |
| Cheapest listing type | Shared Room (-€418/month vs Apartment) | NB4 |
| VIF max score | 4.52 (washing_machine) — no multicollinearity | NB4 |

---

## 🛠️ Methods & Libraries Used

| Method | Tool / Library | Phase |
|---|---|---|
| INTERVAL age buckets | PostgreSQL | SQL Q1 |
| LAG(12) YoY comparison | PostgreSQL | SQL Q2, Q4 |
| 30-day rolling average | PostgreSQL ROWS BETWEEN | SQL Q3 |
| NTILE(3) tier segmentation | PostgreSQL | SQL Q5 |
| PERCENTILE_CONT median | PostgreSQL | SQL Q1, Q4 |
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
| Target Roles | Data Analyst — JET SODA Amsterdam \| BOL Retail Media Netherlands \| DLL Eindhoven |
| Session | March 2026 — Active Portfolio Development |