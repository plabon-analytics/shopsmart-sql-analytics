/*Analysis 1 —
RFM Analysis*/

-- The Complete RFM Query

-- ============================================================
-- RFM ANALYSIS — ShopSmart Customer Segmentation
-- ============================================================

WITH 
-- Step 1: Calculate raw RFM metrics per customer
rfm_base AS (
    SELECT 
        c.customer_id,
        c.full_name,
        c.segment                                AS customer_segment,
        c.city,
        MAX(o.order_date)                        AS last_order_date,
        DATEDIFF(CURDATE(), MAX(o.order_date))   AS recency_days,
        COUNT(DISTINCT o.order_id)               AS frequency,
        ROUND(SUM(oi.unit_price * oi.quantity), 2) AS monetary
    FROM customers AS c
    INNER JOIN orders      AS o  ON c.customer_id = o.customer_id
    INNER JOIN order_items AS oi ON o.order_id    = oi.order_id
    WHERE o.status = 'Delivered'
    GROUP BY c.customer_id, c.full_name, c.segment, c.city
),
-- Step 2: Score each customer 1-5 on R, F, M
rfm_scores AS (
    SELECT 
        customer_id,
        full_name,
        customer_segment,
        city,
        last_order_date,
        recency_days,
        frequency,
        monetary,
        -- Recency: lower days = more recent = higher score
        NTILE(5) OVER(ORDER BY recency_days DESC)  AS r_score,
        -- Frequency: more orders = higher score
        NTILE(5) OVER(ORDER BY frequency ASC)    AS f_score,
        -- Monetary: more spending = higher score
        NTILE(5) OVER(ORDER BY monetary ASC)     AS m_score
    FROM rfm_base
),
-- Step 3: Calculate combined score and assign segment label
rfm_segmented AS (
    SELECT 
        customer_id,
        full_name,
        customer_segment,
        city,
        last_order_date,
        recency_days,
        frequency,
        monetary,
        r_score,
        f_score,
        m_score,
        r_score + f_score + m_score              AS rfm_score,
        CASE 
            WHEN r_score + f_score + m_score >= 13 THEN 'Champion'
            WHEN r_score + f_score + m_score >= 10 THEN 'Loyal Customer'
            WHEN r_score + f_score + m_score >= 7  THEN 'Potential Loyalist'
            WHEN r_score + f_score + m_score >= 4  THEN 'At Risk'
            ELSE 'Lost'
        END                                      AS rfm_segment
    FROM rfm_scores
)
-- Final output: full customer RFM table
SELECT 
    customer_id,
    full_name,
    customer_segment,
    city,
    last_order_date,
    recency_days,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    rfm_score,
    rfm_segment
FROM rfm_segmented
ORDER BY rfm_score DESC, monetary DESC;




-- RFM Summary Query — Segment Distribution
WITH rfm_base AS (
    SELECT 
        c.customer_id,
        MAX(o.order_date)                        AS last_order_date,
        DATEDIFF(CURDATE(), MAX(o.order_date))   AS recency_days,
        COUNT(DISTINCT o.order_id)               AS frequency,
        ROUND(SUM(oi.unit_price * oi.quantity), 2) AS monetary
    FROM customers AS c
    INNER JOIN orders      AS o  ON c.customer_id = o.customer_id
    INNER JOIN order_items AS oi ON o.order_id    = oi.order_id
    WHERE o.status = 'Delivered'
    GROUP BY c.customer_id
),
rfm_scores AS (
    SELECT 
        customer_id,
        recency_days,
        frequency,
        monetary,
        NTILE(5) OVER(ORDER BY recency_days DESC)  AS r_score,
        NTILE(5) OVER(ORDER BY frequency ASC)    AS f_score,
        NTILE(5) OVER(ORDER BY monetary ASC)     AS m_score
    FROM rfm_base
),
rfm_segmented AS (
    SELECT 
        customer_id,
        monetary,
        r_score + f_score + m_score              AS rfm_score,
        CASE 
            WHEN r_score + f_score + m_score >= 13 THEN 'Champion'
            WHEN r_score + f_score + m_score >= 10 THEN 'Loyal Customer'
            WHEN r_score + f_score + m_score >= 7  THEN 'Potential Loyalist'
            WHEN r_score + f_score + m_score >= 4  THEN 'At Risk'
            ELSE 'Lost'
        END                                      AS rfm_segment
    FROM rfm_scores
)
SELECT 
    rfm_segment,
    COUNT(*)                                     AS customer_count,
    ROUND(AVG(monetary), 2)                      AS avg_spending,
    ROUND(SUM(monetary), 2)                      AS total_revenue,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) AS pct_of_customers
FROM rfm_segmented
GROUP BY rfm_segment
ORDER BY 
    CASE rfm_segment
        WHEN 'Champion'           THEN 1
        WHEN 'Loyal Customer'     THEN 2
        WHEN 'Potential Loyalist' THEN 3
        WHEN 'At Risk'            THEN 4
        WHEN 'Lost'               THEN 5
    END;