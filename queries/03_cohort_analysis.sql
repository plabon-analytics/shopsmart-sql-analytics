/*Analysis 3
Cohort Analysis*/

-- ============================================================
-- COHORT ANALYSIS — ShopSmart Customer Retention
-- ============================================================

WITH
-- STEP 1: find each customer's cohort (first order month)
first_orders AS (
    SELECT 
        customer_id,
        MIN(order_date)                              AS first_order_date,
        DATE_FORMAT(MIN(order_date), '%Y-%m')        AS cohort_month
    FROM orders
    WHERE status = 'Delivered'
    GROUP BY customer_id
),
-- STEP 2: attach cohort to every order + calculate month gap
customer_orders AS (
    SELECT 
		o.customer_id,
        o.order_date,
        fo.cohort_month,
        fo.first_order_date,
        -- Month number: 0 = first month, 1 = one month later, etc.
        PERIOD_DIFF(			# PERIOD_DIFF(202207, 202203) = 4 → the order was placed 4 months after the first order.
            EXTRACT(YEAR_MONTH FROM o.order_date),
            EXTRACT(YEAR_MONTH FROM fo.first_order_date)
        )                                            AS month_number_of_order
    FROM orders AS o
    INNER JOIN first_orders AS fo ON o.customer_id = fo.customer_id
    WHERE o.status = 'Delivered'
),
-- STEP 3: count active customers per cohort per month
cohort_activity AS (
    SELECT 
        cohort_month,
        month_number_of_order,
        COUNT(DISTINCT customer_id)                  AS active_customers
    FROM customer_orders
    GROUP BY cohort_month, month_number_of_order
),
-- STEP 4: Get cohort sizes (month 0 count = original cohort size)
cohort_sizes AS (
    SELECT 
        cohort_month,
        month_number_of_order,
        active_customers                             AS cohort_size
    FROM cohort_activity
    WHERE month_number_of_order = 0
),
-- STEP 5: Calculate retention rates
cohort_retention AS (
    SELECT 
        ca.cohort_month,
        ca.month_number_of_order,
        ca.active_customers,
        cs.cohort_size,
        ROUND(ca.active_customers * 100.0 / 
            NULLIF(cs.cohort_size, 0), 1)            AS retention_pct
    FROM cohort_activity AS ca
    INNER JOIN cohort_sizes AS cs ON ca.cohort_month = cs.cohort_month
)
SELECT 
    cohort_month,
    month_number_of_order,
    cohort_size,
    active_customers,
    retention_pct
FROM cohort_retention
ORDER BY cohort_month, month_number_of_order;


-- Cohort Pivot — The Heatmap View

WITH first_orders AS (
    SELECT 
        customer_id,
        MIN(order_date)                              AS first_order_date,
        DATE_FORMAT(MIN(order_date), '%Y-%m')        AS cohort_month
    FROM orders
    WHERE status = 'Delivered'
    GROUP BY customer_id
),
customer_orders AS (
    SELECT 
        o.customer_id,
        fo.cohort_month,
        fo.first_order_date,
        PERIOD_DIFF(
            EXTRACT(YEAR_MONTH FROM o.order_date),
            EXTRACT(YEAR_MONTH FROM fo.first_order_date)
        )                                            AS month_number_of_order
    FROM orders AS o
    INNER JOIN first_orders AS fo ON o.customer_id = fo.customer_id
    WHERE o.status = 'Delivered'
),
cohort_activity AS (
    SELECT 
        cohort_month,
        month_number_of_order,
        COUNT(DISTINCT customer_id)                  AS active_customers
    FROM customer_orders
    GROUP BY cohort_month, month_number_of_order
),
cohort_sizes AS (
    SELECT cohort_month,
    active_customers                                 AS cohort_size
    FROM cohort_activity
    WHERE month_number_of_order = 0
)
SELECT 
    ca.cohort_month,
    cs.cohort_size,
    -- Month 0 is always 100%
    ROUND(MAX(CASE WHEN month_number_of_order = 0
        THEN active_customers * 100.0 / cs.cohort_size END), 1) AS m0,
    ROUND(MAX(CASE WHEN month_number_of_order = 1
        THEN active_customers * 100.0 / cs.cohort_size END), 1) AS m1,
    ROUND(MAX(CASE WHEN month_number_of_order = 2
        THEN active_customers * 100.0 / cs.cohort_size END), 1) AS m2,
    ROUND(MAX(CASE WHEN month_number_of_order = 3
        THEN active_customers * 100.0 / cs.cohort_size END), 1) AS m3,
    ROUND(MAX(CASE WHEN month_number_of_order = 6
        THEN active_customers * 100.0 / cs.cohort_size END), 1) AS m6,
	ROUND(MAX(CASE WHEN month_number_of_order = 9
        THEN active_customers * 100.0 / cs.cohort_size END), 1) AS m9,
    ROUND(MAX(CASE WHEN month_number_of_order = 12
        THEN active_customers * 100.0 / cs.cohort_size END), 1) AS m12,
	ROUND(MAX(CASE WHEN month_number_of_order = 16
        THEN active_customers * 100.0 / cs.cohort_size END), 1) AS m16,
	ROUND(MAX(CASE WHEN month_number_of_order = 19
        THEN active_customers * 100.0 / cs.cohort_size END), 1) AS m19,
    ROUND(MAX(CASE WHEN month_number_of_order = 24
        THEN active_customers * 100.0 / cs.cohort_size END), 1) AS m24,
	ROUND(MAX(CASE WHEN month_number_of_order = 30
        THEN active_customers * 100.0 / cs.cohort_size END), 1) AS m30
FROM cohort_activity AS ca
INNER JOIN cohort_sizes AS cs ON ca.cohort_month = cs.cohort_month
GROUP BY ca.cohort_month, cs.cohort_size
ORDER BY ca.cohort_month;

