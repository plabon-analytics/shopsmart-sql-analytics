-- ============================================================
-- CUSTOMER RETENTION ANALYSIS — ShopSmart
-- Month-by-Month Active Customer Tracking
-- ============================================================


WITH
-- Step 1: Get all months each customer was active
customer_monthly_activity AS (
    SELECT 
        customer_id,
        DATE_FORMAT(order_date, '%Y-%m')           AS active_month
    FROM orders 
    WHERE status = 'Delivered'
    GROUP BY customer_id,			# Here we use GROUP BY purely for deduplication, not for calculation.
             DATE_FORMAT(order_date, '%Y-%m')
),
-- Step 2: For each active month, check if customer was also active the previous month
retention_check AS (
    SELECT 
        curr.customer_id,
        curr.active_month                            AS current_month,
        prev.active_month                            AS prev_month,
        CASE 
            WHEN prev.customer_id IS NOT NULL THEN 'Retained'
            ELSE 'New or Reactivated'
        END                                          AS retention_status
    FROM customer_monthly_activity AS curr
    LEFT JOIN customer_monthly_activity AS prev
        ON curr.customer_id = prev.customer_id       -- same customer
        AND PERIOD_DIFF(				-- A JOIN's ON clause can have MULTIPLE conditions connected with AND
            EXTRACT(YEAR_MONTH FROM STR_TO_DATE(
                CONCAT(curr.active_month, '-01'), '%Y-%m-%d')),
            EXTRACT(YEAR_MONTH FROM STR_TO_DATE(			    #'2022-01' → CONCAT → '2022-01-01' → STR_TO_DATE → 2022-01-01 → EXTRACT → 202201
                CONCAT(prev.active_month, '-01'), '%Y-%m-%d'))
        ) = 1                                        -- exactly 1 month apart
),
-- Step 3: Add churned customers
--         (active last month but not this month)
churn_check AS (
    SELECT 
        prev.customer_id,
        prev.active_month                            AS churned_month,
        'Churned'                                    AS retention_status
    FROM customer_monthly_activity AS prev
    WHERE NOT EXISTS (
        SELECT 1
        FROM customer_monthly_activity AS curr
        WHERE curr.customer_id = prev.customer_id
        AND PERIOD_DIFF(
            EXTRACT(YEAR_MONTH FROM STR_TO_DATE(
                CONCAT(curr.active_month, '-01'), '%Y-%m-%d')),
            EXTRACT(YEAR_MONTH FROM STR_TO_DATE(
                CONCAT(prev.active_month, '-01'), '%Y-%m-%d'))
        ) = 1
    )
),
-- Step 4: Monthly summary
monthly_retention AS (
    SELECT 
        current_month                                AS month,
        COUNT(DISTINCT CASE WHEN retention_status = 'Retained'
            THEN customer_id END)                    AS retained_customers,
        COUNT(DISTINCT CASE WHEN retention_status = 'New or Reactivated'
            THEN customer_id END)                    AS new_reactivated,
        COUNT(DISTINCT customer_id)                  AS total_active
    FROM retention_check
    GROUP BY current_month
)
SELECT 
    month,
    total_active,
    retained_customers,
    new_reactivated,
    ROUND(retained_customers * 100.0 /
        NULLIF(total_active, 0), 1)                  AS retention_rate_pct,
    ROUND(new_reactivated * 100.0 /
        NULLIF(total_active, 0), 1)                  AS new_reactivated_pct
FROM monthly_retention
ORDER BY month;