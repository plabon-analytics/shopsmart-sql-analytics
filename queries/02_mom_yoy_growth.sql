/*Analysis 2
Month-over-Month & Year-over-Year Growth*/

-- The Complete MoM + YoY Query
-- ============================================================
-- MONTH-OVER-MONTH & YEAR-OVER-YEAR GROWTH ANALYSIS
-- ShopSmart Revenue Trends
-- ============================================================

WITH
-- Step 1: Calculate monthly revenue
monthly_revenue AS (
    SELECT 
        YEAR(o.order_date)                           AS order_year,
        MONTH(o.order_date)                          AS order_month,
        DATE_FORMAT(o.order_date, '%Y-%m')           AS order_year_month,
        COUNT(DISTINCT o.order_id)                   AS total_orders,
        COUNT(DISTINCT o.customer_id)                AS unique_customers,
        ROUND(SUM(oi.unit_price * oi.quantity), 2)   AS revenue
    FROM orders AS o
    INNER JOIN order_items AS oi ON o.order_id = oi.order_id
    WHERE o.status = 'Delivered'
    GROUP BY 
        YEAR(o.order_date),
        MONTH(o.order_date),
        DATE_FORMAT(o.order_date, '%Y-%m')
),
-- Step 2: Add MoM comparison using LAG
mom_analysis AS (
    SELECT 
        order_year,
        order_month,
        order_year_month,
        total_orders,
        unique_customers,
        revenue,
        LAG(revenue) OVER(
            ORDER BY order_year, order_month
        )                                            AS prev_month_revenue,
        LAG(total_orders) OVER(
            ORDER BY order_year, order_month
        )                                            AS prev_month_orders
    FROM monthly_revenue
),
-- Step 3: Add YoY comparison using LAG with offset 12
yoy_analysis AS (
    SELECT 
        order_year,
        order_month,
        order_year_month,
        total_orders,
        unique_customers,
        revenue,
        prev_month_revenue,
        prev_month_orders,
        -- YoY: compare to same month last year (12 months back)
        LAG(revenue, 12) OVER(
            ORDER BY order_year, order_month
        )                                            AS same_month_last_year,
        LAG(total_orders, 12) OVER(
            ORDER BY order_year, order_month
        )                                            AS same_month_orders_last_year
    FROM mom_analysis
),
-- Step 4: Calculate growth percentages and labels
growth_final AS (
    SELECT 
        order_year,
        order_month,
        order_year_month,
        total_orders,
        unique_customers,
        revenue,
        -- MoM revenue change        
        prev_month_revenue,
        ROUND(revenue - prev_month_revenue, 2)       AS mom_change,
        ROUND((revenue - prev_month_revenue) * 100.0
            / NULLIF(prev_month_revenue, 0), 2)      AS mom_growth_pct,
        -- YoY revenue
        same_month_last_year,
        ROUND(revenue - same_month_last_year, 2)     AS yoy_change,
        ROUND((revenue - same_month_last_year) * 100.0
            / NULLIF(same_month_last_year, 0), 2)    AS yoy_growth_pct,
        -- Trend labels
        CASE 
            WHEN revenue > prev_month_revenue  THEN 'Growth'
            WHEN revenue < prev_month_revenue  THEN 'Decline'
            WHEN prev_month_revenue IS NULL    THEN 'First Month'
            ELSE 'Flat'
        END                                          AS mom_trend,
        -- 3-month moving average for smoothing
        ROUND(AVG(revenue) OVER(
            ORDER BY order_year, order_month
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ), 2)                                        AS moving_avg_3month,
        -- running total revenue
        ROUND(SUM(revenue) OVER(
			ORDER BY order_year, order_month
		), 2) 										AS running_total
    FROM yoy_analysis
)
SELECT *
FROM growth_final
ORDER BY order_year, order_month;


-- best month + how far above average
WITH month_revenue AS(
	SELECT
		YEAR(o.order_date) AS order_year,
        MONTH(o.order_date) AS order_month,
        ROUND(SUM(oi.quantity * oi.unit_price), 2) AS monthly_revenue
	FROM orders AS o
    LEFT JOIN order_items AS oi ON o.order_id = oi.order_id
    WHERE o.status = 'Delivered'
    GROUP BY YEAR(o.order_date), MONTH(o.order_date)
),
avg_revenue_monthly AS(
	SELECT
		order_year,
        order_month,
        monthly_revenue,
        ROUND(AVG(monthly_revenue) OVER(), 2)		AS avg_monthly_revenue,
        (monthly_revenue - ROUND(AVG(monthly_revenue) OVER(), 2))    AS reve_diff
	FROM month_revenue
)
SELECT
	*
FROM avg_revenue_monthly
ORDER BY monthly_revenue DESC
LIMIT 1;


-- declining months, sorted by biggest decline
WITH month_revenue AS(
	SELECT
		YEAR(o.order_date) AS order_year,
        MONTH(o.order_date) AS order_month,
        ROUND(SUM(oi.quantity * oi.unit_price), 2) AS monthly_revenue
	FROM orders AS o
    LEFT JOIN order_items AS oi ON o.order_id = oi.order_id
    WHERE o.status = 'Delivered'
    GROUP BY YEAR(o.order_date), MONTH(o.order_date)
),
mom_analysis AS(
	SELECT
		order_year,
        order_month,
        monthly_revenue,
        LAG(monthly_revenue) OVER(ORDER BY order_year, order_month)    AS pre_mon_revenue
	FROM month_revenue
    
)
SELECT
	*,
    ROUND(monthly_revenue - pre_mon_revenue, 2) AS decline_amount
FROM mom_analysis
WHERE monthly_revenue < pre_mon_revenue
ORDER BY decline_amount ASC;