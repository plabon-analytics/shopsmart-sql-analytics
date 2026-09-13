-- ===============================================================================================
-- CUSTOMER LIFETIME VALUE(CLV) ANALYSIS — ShopSmart
-- ===============================================================================================

/*technically valid, but algebraically equals total_revenue exactly, since purchase_frequency 
uses each customer's own lifespan as its denominator, which then cancels out.*/

WITH customer_summary AS (
    SELECT
        c.customer_id, c.full_name,
        COUNT(DISTINCT o.order_id)                                 AS total_orders,
        ROUND(SUM(oi.unit_price * oi.quantity), 2)                 AS total_revenue,
        TIMESTAMPDIFF(MONTH, MIN(o.order_date), MAX(o.order_date)) AS lifespan_months
    FROM customers AS c
    INNER JOIN orders AS o ON c.customer_id = o.customer_id
    INNER JOIN order_items AS oi ON o.order_id = oi.order_id
    WHERE o.status = 'Delivered'
    GROUP BY c.customer_id, c.full_name
)
SELECT
    customer_id, full_name, total_orders, total_revenue, lifespan_months,
    ROUND(total_revenue / total_orders, 2)                          AS aov,
    ROUND(total_orders / NULLIF(lifespan_months, 0), 4)             AS purchase_frequency,
    ROUND(
        (total_revenue / total_orders)
        * (total_orders / NULLIF(lifespan_months, 0))
        * lifespan_months
    , 2)                                                             AS historical_clv  -- = total_revenue
FROM customer_summary
ORDER BY historical_clv DESC;




/*purchase frequency uses a FIXED 12-month denominator (not each
customer's own lifespan), and lifespan uses one SHARED average across
the whole customer base — not each customer's own value multiplied back in.*/

WITH customer_summary AS (
    SELECT
        c.customer_id, c.full_name,
        COUNT(DISTINCT o.order_id)                                 AS total_orders,
        ROUND(SUM(oi.unit_price * oi.quantity), 2)                 AS total_revenue,
        TIMESTAMPDIFF(MONTH, MIN(o.order_date), MAX(o.order_date)) AS lifespan_months
    FROM customers AS c
    INNER JOIN orders AS o ON c.customer_id = o.customer_id
    INNER JOIN order_items AS oi ON o.order_id = oi.order_id
    WHERE o.status = 'Delivered'
    GROUP BY c.customer_id, c.full_name
),
business_avg AS (
    SELECT ROUND(AVG(lifespan_months), 1) AS avg_lifespan_months
    FROM customer_summary
    WHERE lifespan_months > 0
)
SELECT
    cs.customer_id, cs.full_name, cs.total_orders, cs.total_revenue,
    ROUND(cs.total_revenue / cs.total_orders, 2)   AS aov,
    ROUND(cs.total_orders / 12.0, 4)               AS purchase_freq_per_year,
    ba.avg_lifespan_months,
    ROUND(
        (cs.total_revenue / cs.total_orders)
        * (cs.total_orders / 12.0)
        * (ba.avg_lifespan_months / 12.0)
    , 2)                                            AS projected_clv
FROM customer_summary AS cs
CROSS JOIN business_avg AS ba
ORDER BY projected_clv DESC;