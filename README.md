# ShopSmart SQL Analytics

A self-designed 6-table MySQL e-commerce database, built to practice 
real business analytics using pure SQL — no shortcuts, no downloaded datasets.

![MySQL](https://img.shields.io/badge/MySQL-8.0-4479A1?style=flat-square&logo=mysql&logoColor=white)
![SQL](https://img.shields.io/badge/SQL-Advanced-1e3a8a?style=flat-square)
![Method](https://img.shields.io/badge/Method-RFM%20Segmentation-7c3aed?style=flat-square)
![Framework](https://img.shields.io/badge/Framework-Cohort%20Analysis-0d9488?style=flat-square)
![Status](https://img.shields.io/badge/Status-In%20Progress-16a34a?style=flat-square)
![Git](https://img.shields.io/badge/Version%20Control-Git-F05032?style=flat-square&logo=git&logoColor=white)
![Last Commit](https://img.shields.io/github/last-commit/plabon-analytics/shopsmart-sql-analytics?style=flat-square)

---

## Contents
- [Database Schema](#database-schema)
- [RFM Customer Segmentation](#1-rfm-customer-segmentation)
- [MoM/YoY Growth Analysis](#2-month-over-month--year-over-year-growth)
- [Cohort Analysis](#3-cohort-analysis)

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

## Analyses

### 1. RFM Customer Segmentation
**Query:** [`queries/01_rfm_segmentation.sql`](queries/01_rfm_segmentation.sql)

Segments customers by Recency, Frequency, and Monetary value using 
NTILE(5) window functions and CASE-based scoring logic.

**Key finding:** Among 19 repeat customers, Champions and Loyal segments 
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

*More analyses (Cohort Analysis, Customer Retention, CLV) coming as this portfolio grows.*

## Author

Plabon Roy — BBA Business Analytics, Chandigarh University  
[LinkedIn](https://linkedin.com/in/plabon-roy-analytics) | [Kaggle](https://kaggle.com/pl9roy)
