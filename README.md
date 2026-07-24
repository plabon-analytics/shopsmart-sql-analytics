# ShopSmart SQL Analytics

A self-designed 6-table MySQL e-commerce database, built to practice 
real business analytics using pure SQL — no shortcuts, no downloaded datasets.

## Database Schema

![ER Diagram](diagrams/shopsmart_er_diagram.png)

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

**Results:** [`results/summary_query_segment_distribution.csv`](results/summary_query_segment_distribution.csv) | [`results/ShopSmart_customer_segmentation.csv`](results/ShopSmart_customer_segmentation.csv)

**Techniques used:**
- 4 chained CTEs for readable, step-by-step logic
- NTILE(5) window function for score bucketing
- DATEDIFF for recency calculation
- CASE WHEN for business-friendly segment labels

---

*More analyses (MoM/YoY Growth, Cohort Analysis, Customer Retention, CLV) coming as this portfolio grows.*

## Author

Plabon Roy — BBA Business Analytics, Chandigarh University  
[LinkedIn](https://linkedin.com/in/plabon-roy-analytics) | [Kaggle](https://kaggle.com/pl9roy)