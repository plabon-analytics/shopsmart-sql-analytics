-- ===============================================================
-- MARKET BASKET ANALYSIS — ShopSmart
-- ===============================================================


SELECT
    p1.product_name AS product_a,
    p2.product_name AS product_b,
    COUNT(DISTINCT oi1.order_id) AS times_bought_together
FROM order_items AS oi1
INNER JOIN order_items AS oi2 
    ON oi1.order_id = oi2.order_id
    AND oi1.product_id < oi2.product_id
INNER JOIN orders AS o ON oi1.order_id = o.order_id
INNER JOIN products AS p1 ON oi1.product_id = p1.product_id
INNER JOIN products AS p2 ON oi2.product_id = p2.product_id
WHERE o.status IN ('Delivered', 'Returned')
GROUP BY p1.product_name, p2.product_name
ORDER BY times_bought_together DESC;