# ShopSmart SQL Analytics

A self-designed 6-table MySQL e-commerce database, built to practice 
real business analytics using pure SQL — no shortcuts, no downloaded datasets.

![MySQL](https://img.shields.io/badge/MySQL-8.0-4479A1?style=flat-square&logo=mysql&logoColor=white)
![SQL](https://img.shields.io/badge/SQL-Advanced-1e3a8a?style=flat-square)
![Analyses](https://img.shields.io/badge/Analyses-8-7c3aed?style=flat-square)
![Techniques](https://img.shields.io/badge/Techniques-Window%20Functions%20%7C%20CTEs-0d9488?style=flat-square)
![Status](https://img.shields.io/badge/Status-8%20Analyses%20Completed-16a34a?style=flat-square)
![Git](https://img.shields.io/badge/Version%20Control-Git-F05032?style=flat-square&logo=git&logoColor=white)
![Last Commit](https://img.shields.io/github/last-commit/plabon-analytics/shopsmart-sql-analytics?style=flat-square)

---

## Contents
- [Database Schema](#database-schema)
<<<<<<< HEAD
- [Quick Start](#quick-start)
- [Analyses at a Glance](#analyses-at-a-glance)
- [1. RFM Customer Segmentation](#1-rfm-customer-segmentation)
- [2. MoM/YoY Growth Analysis](#2-month-over-month--year-over-year-growth)
- [3. Cohort Analysis](#3-cohort-analysis)
- [4. Customer Retention Analysis](#4-customer-retention-analysis)
- [5. Funnel Analysis](#5-funnel-analysis)
- [6. Rolling Average Analysis](#6-rolling-average-analysis)
- [7. Customer Lifetime Value (CLV) Analysis](#7-customer-lifetime-value-clv-analysis)
- [8. Market Basket Analysis](#8-market-basket-analysis)
- [Roadmap](#roadmap)
=======
- [RFM Customer Segmentation](#1-rfm-customer-segmentation)
- [MoM/YoY Growth Analysis](#2-month-over-month--year-over-year-growth)
- [Cohort Analysis](#3-cohort-analysis)
- [Customer Retention Analysis](#4-customer-retention-analysis)
- [Funnel Analysis](#5-funnel-analysis)
>>>>>>> 873e03e86c70997a97f997aa8baf3408ee1dc7fe

## Database Schema

![ER Diagram](diagrams/ER_diagram.png)

**6 tables:**
- `customers` — 50 Indian customers across 3 segments (Premium, Standard, Budget)
- `products` — 30 products across 7 categories
- `orders` — order history with status tracking
- `order_items` — bridge table for order-product relationships
- `returns` — return records with reasons
- `marketing_campaigns` — 10 campaigns across 5 channels

Full schema: [`schema/shopsmart_setup.sql`](schema/shopsmart_setup.sql)

## Quick Start

1. Run [`schema/shopsmart_setup.sql`](schema/shopsmart_setup.sql) in MySQL Workbench to create the database
2. Run any query from `queries/` against the `shopsmart` schema
3. Compare your output against the corresponding CSV in `results/`

## Analyses at a Glance

| # | Analysis | Key Finding | Techniques |
|---|----------|--------------|------------|
| 1 | RFM Segmentation | 47% of customers drive 74% of revenue | NTILE, CTEs, CASE |
| 2 | MoM/YoY Growth | 2023 dip (-25%) → 2024 recovery (+40%) | LAG, Moving Avg, Running Total |
| 3 | Cohort Analysis | Retention concentrated in a few long-tenured customers | PERIOD_DIFF, Pivot |
| 4 | Customer Retention | 0% strict MoM retention — reorder cycles are 2+ months apart | Self-Join, PERIOD_DIFF |
| 5 | Funnel Analysis | 42% signup→order conversion is the biggest leak, not loyalty | UNION ALL, LAG, FIRST_VALUE |
| 6 | Rolling Average | Order volume is stable; revenue volatility comes from order size | Moving Average Window |
| 7 | CLV Analysis | Fixed a formula that silently collapsed to total revenue | TIMESTAMPDIFF, CROSS JOIN |
| 8 | Market Basket | Top pair: boAt Airdopes 141 + Himalaya Face Wash (4 orders) | Self-Join |

## Analyses

### 1. RFM Customer Segmentation
**Query:** [`queries/01_rfm_segmentation.sql`](queries/01_rfm_segmentation.sql)

Segments customers by Recency, Frequency, and Monetary value using 
NTILE(5) window functions and CASE-based scoring logic.

**Key finding:** Among 19 repeat customers, the Champions and Loyal segments 
(47% of customers) generate 74% of total revenue. At Risk customers 
represent ₹4.1L in recoverable revenue.

**Results:** [`results/01_summary_query_segment_distribution.csv`](results/01_summary_query_segment_distribution.csv) | [`results/01_ShopSmart_customer_segmentation.csv`](results/01_ShopSmart_customer_segmentation.csv)

**Techniques used:**
- 4 chained CTEs for readable, step-by-step logic
- NTILE(5) window function for score bucketing
- DATEDIFF for recency calculation
- CASE WHEN for business-friendly segment labels

---

### 2. Month-over-Month & Year-over-Year Growth
**Query:** [`queries/02_mom_yoy_growth.sql`](queries/02_mom_yoy_growth.sql)

Tracks monthly revenue trends using LAG window functions for MoM 
and YoY comparisons, plus a 3-month moving average and running 
total for trend smoothing.

**Key findings:**
- Annual revenue grew from ₹7.36L (2022) to ₹8.71L (2025), with 
  a dip in 2023 (-25.3%) followed by a strong recovery in 2024 (+39.9%)
- Best single month was January 2022 (₹1.35L), sitting ₹72K above 
  the overall monthly average
- Revenue is highly volatile month-to-month (swings from +2,900% 
  to -98%), driven by low monthly order volume (1-3 orders/month) — 
  revenue is order-concentrated rather than a steady stream

**Results:** [`results/02_monthly_growth_trends.csv`](results/02_monthly_growth_trends.csv) | [`results/02_best_month_analysis.csv`](results/02_best_month_analysis.csv) | [`results/02_declining_months.csv`](results/02_declining_months.csv)

**Techniques used:**
- LAG() for both 1-month (MoM) and 12-month (YoY) comparisons
- Window-based 3-month moving average (ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)
- Running total via SUM() OVER()
- CASE-based trend labeling (Growth/Decline/Flat/First Month)

---

### 3. Cohort Analysis
**Query:** [`queries/03_cohort_analysis.sql`](queries/03_cohort_analysis.sql)

Tracks customer retention by grouping customers into monthly cohorts 
based on their first order, then measuring what percentage of each 
cohort placed repeat orders in subsequent months using PERIOD_DIFF 
for month-gap calculation.

**Key findings:**
- Retention drops sharply after month 0 across nearly all cohorts, 
  with most repeat activity concentrated in a small number of 
  long-tenured customers rather than spread evenly across each cohort
- A handful of customers account for the majority of repeat orders 
  seen months or even years after their first purchase

**Note on cohort size:** This analysis uses a practice database of 50 
customers designed to demonstrate SQL methodology, not to model 
production-scale behavior. Most cohorts contain just 1-2 customers, 
so individual purchase timing dominates the retention percentages — 
this produces discontinuous month numbers rather than smooth curves. 
The underlying technique (PERIOD_DIFF-based cohort tracking, retention 
rate calculation) is identical to what's used on production data; 
at larger scale, the same query would be expected to produce smoother, 
more continuous retention trends.

**Results:** [`results/03_cohort_retention.csv`](results/03_cohort_retention.csv) | [`results/03_cohort_pivot_heatmap.csv`](results/03_cohort_pivot_heatmap.csv)

**Techniques used:**
- PERIOD_DIFF() for calculating month-gap between first order and 
  subsequent orders
- Multi-CTE chain to build cohort assignment, activity counts, and 
  retention percentages step by step
- CASE-based pivot to reshape long-format retention data into a 
  wide heatmap view (month 0, 1, 2, 3, 6, 9, 12, 16, 19, 24, 30)

---

### 4. Customer Retention Analysis
**Query:** [`queries/04_retention_analysis.sql`](queries/04_retention_analysis.sql)

Tracks month-by-month customer activity to measure true month-over-month 
retention — whether a customer who purchased in one calendar month also 
purchased in the immediately following month.

**Key finding:**
0% of customer activity across all 55 months (Jan 2022 – May 2026) 
qualifies as strict month-over-month retention — no customer in this 
dataset made purchases in two consecutive calendar months. Verified 
directly against raw order data (a standalone self-join check outside 
the main query confirmed zero customer-pairs with back-to-back monthly 
purchases), ruling out a query logic error.

This reveals something concrete about purchase behavior in this dataset: 
repeat customers exist (confirmed in the RFM and Cohort analyses), but 
their reorder cycles are consistently spaced 2+ months apart. Strict 
month-over-month retention is the wrong lens for this purchase pattern — 
a bi-monthly or quarterly retention window would likely surface the 
loyalty that these stricter monthly checks miss entirely.

**Results:** [`results/04_retention_analysis_mom.csv`](results/04_retention_analysis_mom.csv)

**Techniques used:**
- Self-join with PERIOD_DIFF to detect exact 1-month purchase gaps
- LEFT JOIN + CASE to classify each customer-month as Retained vs. 
  New/Reactivated
- Independent sanity-check query used to verify the result against 
  raw order data before treating it as a finding, not a bug

---

### 5. Funnel Analysis
**Query:** [`queries/05_funnel_analysis.sql`](queries/05_funnel_analysis.sql)

Tracks the customer journey through 5 stages — signup, first order, 
delivered order, repeat purchase, and high-value status (>₹50k spent) — 
using UNION ALL to build a funnel view with step-by-step and 
overall conversion rates via LAG and FIRST_VALUE window functions.

**Key findings:**
- The steepest drop-off happens at the very first stage: only 42% of 
  signed-up customers (21 of 50) ever placed an order — this is the 
  single biggest leak in the funnel, larger than every later stage combined
- Once a customer completes one delivered order, retention through the 
  rest of the funnel is strong: 90.5% place a 2nd order, and 94.1% of 
  repeat buyers cross ₹50k in total spend
- The business implication: this dataset's growth problem is acquisition-
  to-first-purchase conversion, not loyalty — customers who buy once 
  are highly likely to become high-value repeat buyers

<<<<<<< HEAD
**Results:** [`results/05_funnel_conversion.csv`](results/05_funnel_conversion.csv)
=======
**Results:** [`results/05_funnel_analysis.csv`](results/05_funnel_analysis.csv)
>>>>>>> 873e03e86c70997a97f997aa8baf3408ee1dc7fe

**Techniques used:**
- UNION ALL to stack 5 independently defined customer segments into 
  one funnel table
- LAG() for step-over-step conversion rate
- FIRST_VALUE() for conversion rate relative to total signups
- HAVING clauses to define repeat-purchase and high-value thresholds

---

<<<<<<< HEAD
### 6. Rolling Average Analysis
**Query:** [`queries/06_rolling_average_analysis.sql`](queries/06_rolling_average_analysis.sql)

Smooths month-to-month volatility using a 3-month rolling average, 
applied separately to revenue and order volume — a complement to the 
MoM/YoY analysis, which measures period-over-period *change* rather 
than the underlying *trend direction*.

**Key finding:** Order volume stays remarkably stable across the entire 
4.5-year period — the smoothed average never leaves a 1.5–2.7 orders/
month band. Revenue, meanwhile, swings dramatically even after 
smoothing (~₹35K to ~₹100K). This confirms that ShopSmart's revenue 
volatility is driven almost entirely by order size, not order frequency 
— customers aren't buying more or less often, some months just happen 
to include larger purchases.

**Results:** [`results/06_revenue_3month_rolling_average.csv`](results/06_revenue_3month_rolling_average.csv) | [`results/06_order_value_3month_rolling_average.csv`](results/06_order_value_3month_rolling_average.csv)

**Techniques used:**
- Window function moving average (`ROWS BETWEEN 2 PRECEDING AND CURRENT ROW`)
- Applied to two distinct metrics (revenue, order volume) from the same base query

---

### 7. Customer Lifetime Value (CLV) Analysis
**Query:** [`queries/07_clv_analysis.sql`](queries/07_clv_analysis.sql)

Calculates CLV two ways to illustrate a common analytical pitfall: the 
standard CLV formula (AOV × Purchase Frequency × Lifespan) mathematically 
collapses to just total revenue when frequency is computed using each 
customer's *own* lifespan as the denominator — the terms cancel out 
algebraically.

**Key findings:**
- **Historical CLV** (naive formula) exactly equals total revenue for 
  every customer — e.g., top customer Rohan Mehta shows ₹4,96,991, 
  identical to his revenue total. It also breaks entirely for 
  single-order customers, returning NULL, since dividing by their own 
  0-month lifespan is undefined.
- **Projected CLV** (fixed 12-month frequency denominator + a shared 
  average lifespan across the customer base) produces genuinely 
  differentiated values — the same customer's projected value is 
  ₹1,27,699, a realistic forward estimate rather than a repackaged 
  historical number. This version also correctly handles single-order 
  customers instead of nulling them out.

**Results:** [`results/07_historical_clv.csv`](results/07_historical_clv.csv) | [`results/07_projected_clv.csv`](results/07_projected_clv.csv)

**Techniques used:**
- TIMESTAMPDIFF for customer lifespan calculation
- CROSS JOIN to apply a business-wide average against every customer row
- Two formula variants included deliberately, to document and correct 
  a common CLV calculation mistake rather than hide it

---

### 8. Market Basket Analysis
**Query:** [`queries/08_market_basket_analysis.sql`](queries/08_market_basket_analysis.sql)

Identifies which products are frequently purchased together using a 
self-join on `order_items`, filtering to Delivered and Returned orders 
to capture genuine purchase intent.

**Key finding:** Top pair is boAt Airdopes 141 + Himalaya Face Wash, 
co-occurring in 4 orders — an electronics + personal-care pairing 
spanning different categories. With small overall co-occurrence counts 
(the dataset's order volume limits sample size here, consistent with 
earlier analyses), this reads as a directional signal for potential 
cross-category bundling rather than a statistically strong affinity claim.

**Results:** [`results/08_market_basket_pairs.csv`](results/08_market_basket_pairs.csv)

**Techniques used:**
- Self-join with `oi1.product_id < oi2.product_id` to avoid duplicate/
  mirrored pairs
- Multi-table join (order_items → orders → products ×2) to resolve 
  readable product names

---

## Roadmap
- [x] RFM Customer Segmentation
- [x] Month-over-Month & Year-over-Year Growth
- [x] Cohort Analysis
- [x] Customer Retention Analysis
- [x] Funnel Analysis
- [x] Rolling Average Analysis
- [x] Customer Lifetime Value (CLV) Analysis
- [x] Market Basket Analysis
=======
*More analyses (Rolling Averages for Business KPIs, CLV, Market Basket Analysis) coming as this portfolio grows.*
>>>>>>> 873e03e86c70997a97f997aa8baf3408ee1dc7fe

## Author

Plabon Roy — BBA Business Analytics, Chandigarh University  
[LinkedIn](https://linkedin.com/in/plabon-roy-analytics) | [Kaggle](https://kaggle.com/pl9roy)