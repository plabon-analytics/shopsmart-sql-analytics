-- ============================================================
-- ROLLING AVERAGE ANALYSIS — ShopSmart
-- Smoothing short-term volatility to reveal underlying trend
-- ============================================================

-- 1. Revenue: 3-month rolling average
WITH monthly_revenue AS (
    SELECT 
        DATE_FORMAT(o.order_date, '%Y-%m')           AS order_year_month,
        ROUND(SUM(oi.unit_price * oi.quantity), 2)   AS revenue
    FROM orders AS o
    INNER JOIN order_items AS oi ON o.order_id = oi.order_id
    WHERE o.status = 'Delivered'
    GROUP BY DATE_FORMAT(o.order_date, '%Y-%m')
)
SELECT
    order_year_month,
    revenue,
    ROUND(AVG(revenue) OVER (
        ORDER BY order_year_month
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2) AS rolling_3month_avg
FROM monthly_revenue
ORDER BY order_year_month;




-- 2. Order volume: 3-month rolling average (business question: 
--    "is order frequency trending up or down, independent of revenue?")
WITH monthly_orders AS (
    SELECT 
        DATE_FORMAT(o.order_date, '%Y-%m')           AS order_year_month,
        COUNT(DISTINCT o.order_id)                   AS total_orders
    FROM orders AS o
    INNER JOIN order_items AS oi ON o.order_id = oi.order_id
    WHERE o.status = 'Delivered'
    GROUP BY DATE_FORMAT(o.order_date, '%Y-%m')
)
SELECT
    order_year_month,
    total_orders,
    ROUND(AVG(total_orders) OVER (
        ORDER BY order_year_month
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2) AS rolling_3month_orders
FROM monthly_orders
ORDER BY order_year_month;