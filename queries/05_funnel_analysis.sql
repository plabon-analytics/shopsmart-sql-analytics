-- ============================================================
-- FUNNEL ANALYSIS — ShopSmart Customer Journey
-- ============================================================

WITH
-- Step 1: All customers who signed up
step1_signups AS (
    SELECT 
        customer_id,
        full_name,
        segment,
        signup_date
    FROM customers
),

-- Step 2: Customers who placed at least one order
step2_ordered AS (
    SELECT DISTINCT customer_id
    FROM orders
),

-- Step 3: Customers who had at least one delivered order
step3_delivered AS (
    SELECT DISTINCT customer_id
    FROM orders
    WHERE status = 'Delivered'
),

-- Step 4: Customers who placed 2+ delivered orders
--         (came back for a second purchase)
step4_repeat AS (
    SELECT customer_id
    FROM orders
    WHERE status = 'Delivered'
    GROUP BY customer_id
    HAVING COUNT(DISTINCT order_id) >= 2
),

-- Step 5: High value customers (total spend > 50000)
step5_highvalue AS (
    SELECT o.customer_id
    FROM orders AS o
    INNER JOIN order_items AS oi ON o.order_id = oi.order_id
    WHERE o.status = 'Delivered'
    GROUP BY o.customer_id
    HAVING SUM(oi.unit_price * oi.quantity) > 50000
),

-- Combine all steps into one funnel view
funnel_counts AS (
    SELECT 
        1                                            AS step_number,
        'Signed Up'                                  AS step_name,
        COUNT(*)                                     AS customers_count
    FROM step1_signups
    
    UNION ALL
    
    SELECT 2, 'Placed Any Order',
        COUNT(*) FROM step2_ordered
    
    UNION ALL
    
    SELECT 3, 'Had Delivered Order',
        COUNT(*) FROM step3_delivered
    
    UNION ALL
    
    SELECT 4, 'Repeat Purchase (2+ orders)',
        COUNT(*) FROM step4_repeat
    
    UNION ALL
    
    SELECT 5, 'High Value (>₹50k spent)',
        COUNT(*) FROM step5_highvalue
)

-- Final output with conversion rates
SELECT 
    step_number,
    step_name,
    customers_count,
    FIRST_VALUE(customers_count) OVER(
        ORDER BY step_number
    )                                                AS total_signups,
    -- Conversion from previous step
    COALESCE(LAG(customers_count) OVER(ORDER BY step_number), 0)        AS prev_step_customers,
    LAG(customers_count) OVER(ORDER BY step_number) - customers_count	AS customers_lost,
    ROUND(customers_count * 100.0 / NULLIF(
        LAG(customers_count) OVER(ORDER BY step_number)
    , 0), 1)                                         AS step_conversion_pct,
    -- Conversion from very first step
    ROUND(customers_count * 100.0 / NULLIF(
        FIRST_VALUE(customers_count) OVER(ORDER BY step_number)
    , 0), 1)                                         AS overall_conversion_pct
FROM funnel_counts
ORDER BY step_number;