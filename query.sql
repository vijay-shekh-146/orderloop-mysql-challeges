/* Question 1 — Total Sales Revenue by Product */


SELECT 
    p.id AS product_id,
    p.name AS product_name,
    SUM(oi.quantity * oi.price) AS total_revenue
FROM products p
JOIN order_items oi ON oi.product_id = p.id
GROUP BY p.id, p.name
ORDER BY total_revenue DESC;


/* Question 2 — Top 5 Customers by Spending */


SELECT 
    c.id AS customer_id,
    c.name,
    SUM(oi.quantity * oi.price) AS total_spending
FROM customers c
JOIN orders o ON o.customer_id = c.id
JOIN order_items oi ON oi.order_id = o.id
GROUP BY c.id, c.name
ORDER BY total_spending DESC
LIMIT 5;


/* Question 3 — Average Order Value per Customer */

SELECT 
    c.id AS customer_id,
    c.name,
    (SUM(oi.quantity * oi.price) / COUNT(DISTINCT o.id)) AS avg_order_value
FROM customers c
JOIN orders o ON o.customer_id = c.id
JOIN order_items oi ON oi.order_id = o.id
GROUP BY c.id, c.name
ORDER BY avg_order_value DESC;


/* Question 4 — Recent Orders (Last 30 Days) */

SELECT 
    o.id AS order_id,
    c.name AS customer_name,
    o.order_date,
    o.status
FROM orders o
JOIN customers c ON c.id = o.customer_id
WHERE o.order_date >= NOW() - INTERVAL 30 DAY
ORDER BY o.order_date DESC;


/* Question 5 — Running Total of Customer Spending (CTE) */

WITH order_totals AS (
    SELECT 
        o.customer_id,
        o.id AS order_id,
        o.order_date,
        SUM(oi.quantity * oi.price) AS order_total
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.id
    GROUP BY o.id
),
running_totals AS (
    SELECT
        customer_id,
        order_id,
        order_date,
        order_total,
        SUM(order_total) OVER (
            PARTITION BY customer_id
            ORDER BY order_date
        ) AS running_total
    FROM order_totals
)
SELECT *
FROM running_totals
ORDER BY customer_id, order_date;


/* Question 6 — Product Review Summary */

SELECT
    p.id AS product_id,
    p.name AS product_name,
    AVG(r.rating) AS avg_rating,
    COUNT(r.id) AS total_reviews
FROM products p
LEFT JOIN reviews r ON r.product_id = p.id
GROUP BY p.id, p.name
ORDER BY avg_rating DESC, total_reviews DESC;


/* Question 7 — Customers Without Orders */

SELECT 
    c.id,
    c.name
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id
WHERE o.id IS NULL;


/* Question 8 — Update Last Purchased Date */

UPDATE products p
JOIN (
    SELECT 
        oi.product_id,
        MAX(o.order_date) AS last_purchased
    FROM order_items oi
    JOIN orders o ON o.id = oi.order_id
    GROUP BY oi.product_id
) t ON t.product_id = p.id
SET p.last_purchased = t.last_purchased;


/* Question 9 — Transaction: Place an Order */

START TRANSACTION;

-- 1. Update stock
UPDATE products 
SET stock = stock - 2  -- example qty
WHERE id = 10
  AND stock >= 2;
  
-- Check stock availability
IF ROW_COUNT() = 0 THEN
    ROLLBACK;
END IF;

-- 2. Insert order
INSERT INTO orders (customer_id, order_date, status)
VALUES (5, NOW(), 'pending');

SET @order_id = LAST_INSERT_ID();

-- 3. Insert order items
INSERT INTO order_items (order_id, product_id, quantity, price)
VALUES 
    (@order_id, 10, 2, 199.00);

-- 4. Update last purchased on product
UPDATE products
SET last_purchased = NOW()
WHERE id = 10;

COMMIT;


/* Question 10 — Query Optimization & Indexing */

    /* I have Optimize - Question 2 */

  -- EXPLAIN
    
    SELECT 
        c.id, c.name,
        SUM(oi.quantity * oi.price)
    FROM customers c
    JOIN orders o ON o.customer_id = c.id
    JOIN order_items oi ON oi.order_id = o.id
    GROUP BY c.id;

-- Add Index 
    CREATE INDEX idx_orders_customer_id ON orders(customer_id);
    CREATE INDEX idx_order_items_order_id ON order_items(order_id);

-- Avoid SELECT *

/* Question 11 — Optimize the Given Query */

 -- Optimized Version

 SELECT 
    c.id AS customer_id,
    c.name,
    SUM(oi.quantity * oi.price) AS total_spent
FROM customers c
JOIN orders o ON o.customer_id = c.id
JOIN order_items oi ON oi.order_id = o.id
GROUP BY c.id, c.name
ORDER BY total_spent DESC;
