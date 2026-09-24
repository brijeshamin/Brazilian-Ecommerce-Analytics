-- OLIST BRAZILIAN E-COMMERCE ANALYSIS
-- PostgreSQL SQL Portfolio Project
-- Author: Brijesh Amin

-- =====================================================
-- SECTION 1: ORDER & TRANSACTION ANALYSIS
-- =====================================================

-- Query #1: Total Orders
-- Business Question: How many orders are in the dataset?
SELECT COUNT(*) AS total_orders FROM orders;

-- Query #2: Total Transaction Value
-- Business Question: What is the total transaction value generated from product prices and freight charges?
SELECT ROUND(SUM(price + freight_value), 2) AS total_transaction_value
FROM order_items;

-- Query #3: Average Transaction Value
-- Business Question: What is the average transaction value per order?
SELECT ROUND(SUM(price + freight_value) / COUNT(DISTINCT order_id), 2) AS average_transaction_value
FROM order_items;

-- Query #4: Unique Customers
-- Business Question: How many unique customers are represented in the dataset?
SELECT COUNT(DISTINCT customer_unique_id) AS unique_customers
FROM customers;

-- Query #5: Repeat Customers
-- Business Question: How many customers placed more than one order?
SELECT COUNT(*) AS repeat_customers
FROM (
    SELECT c.customer_unique_id
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id
    HAVING COUNT(*) > 1
) AS customer_orders;

-- Query #6: Repeat Customer Rate
-- Business Question: What percentage of unique customers placed more than one order?
WITH customer_order_counts AS (
    SELECT c.customer_unique_id, COUNT(o.order_id) AS order_count
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id
)
SELECT ROUND(
    100.0 * COUNT(*) FILTER (WHERE order_count > 1) / COUNT(*), 2
) AS repeat_customer_rate
FROM customer_order_counts;

-- Query #7: Monthly Order Trend
-- Business Question: How many orders were placed each month?
SELECT DATE_TRUNC('month', order_purchase_timestamp)::date AS month,
       COUNT(*) AS total_orders
FROM orders
GROUP BY 1
ORDER BY 1;

-- Query #8: Monthly Transaction Value
-- Business Question: How does transaction value change from month to month?
SELECT DATE_TRUNC('month', o.order_purchase_timestamp)::date AS month,
       ROUND(SUM(oi.price + oi.freight_value), 2) AS monthly_transaction_value
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY 1
ORDER BY 1;

-- Query #9: Highest Transaction Value Month
-- Business Question: Which month generated the highest transaction value?
SELECT DATE_TRUNC('month', o.order_purchase_timestamp)::date AS month,
       ROUND(SUM(oi.price + oi.freight_value), 2) AS monthly_transaction_value
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY 1
ORDER BY monthly_transaction_value DESC
LIMIT 1;


-- =====================================================
-- SECTION 2: PRODUCT & CATEGORY ANALYSIS
-- =====================================================

-- Query #10: Transaction Value by Product Category
-- Business Question: Which product categories generate the highest transaction value?
SELECT COALESCE(ct.product_category_name_english, p.product_category_name, 'Unknown') AS category,
       ROUND(SUM(oi.price + oi.freight_value), 2) AS transaction_value
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
LEFT JOIN category_translation ct ON p.product_category_name = ct.product_category_name
GROUP BY 1
ORDER BY transaction_value DESC;

-- Query #11: Top 10 Categories by Transaction Value
-- Business Question: What are the top 10 product categories based on transaction value?
SELECT COALESCE(ct.product_category_name_english, p.product_category_name, 'Unknown') AS category,
       ROUND(SUM(oi.price + oi.freight_value), 2) AS transaction_value
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
LEFT JOIN category_translation ct ON p.product_category_name = ct.product_category_name
GROUP BY 1
ORDER BY transaction_value DESC
LIMIT 10;

-- Query #12: Orders by Product Category
-- Business Question: Which product categories have the highest number of orders?
SELECT COALESCE(ct.product_category_name_english, p.product_category_name, 'Unknown') AS category,
       COUNT(DISTINCT oi.order_id) AS total_orders
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
LEFT JOIN category_translation ct ON p.product_category_name = ct.product_category_name
GROUP BY 1
ORDER BY total_orders DESC
LIMIT 10;

-- Query #13: Average Transaction Value by Category
-- Business Question: Which product categories have the highest average transaction value per order?
SELECT COALESCE(ct.product_category_name_english, p.product_category_name, 'Unknown') AS category,
       COUNT(DISTINCT oi.order_id) AS total_orders,
       ROUND(SUM(oi.price + oi.freight_value), 2) AS transaction_value,
       ROUND(SUM(oi.price + oi.freight_value) / COUNT(DISTINCT oi.order_id), 2) AS avg_transaction_value
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
LEFT JOIN category_translation ct ON p.product_category_name = ct.product_category_name
GROUP BY 1
HAVING COUNT(DISTINCT oi.order_id) >= 100
ORDER BY avg_transaction_value DESC
LIMIT 10;


-- =====================================================
-- SECTION 3: GEOGRAPHIC ANALYSIS
-- =====================================================

-- Query #14: Orders by Brazilian State
-- Business Question: Which Brazilian states have the highest number of orders?
SELECT c.customer_state AS state, COUNT(*) AS total_orders
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY c.customer_state
ORDER BY total_orders DESC;

-- Query #15: Transaction Value by State
-- Business Question: Which Brazilian states generate the highest transaction value?
SELECT c.customer_state AS state,
       COUNT(DISTINCT o.order_id) AS total_orders,
       ROUND(SUM(oi.price + oi.freight_value), 2) AS transaction_value
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY c.customer_state
ORDER BY transaction_value DESC;


-- =====================================================
-- SECTION 4: PAYMENT & CUSTOMER EXPERIENCE
-- =====================================================

-- Query #16: Payment Method Analysis
-- Business Question: Which payment methods are used most frequently and what is their transaction value?
SELECT payment_type,
       COUNT(*) AS payment_count,
       ROUND(SUM(payment_value), 2) AS total_payment_value,
       ROUND(AVG(payment_value), 2) AS average_payment_value
FROM order_payments
GROUP BY payment_type
ORDER BY total_payment_value DESC;

-- Query #17: Review Score Analysis
-- Business Question: How are customers rating their orders?
SELECT review_score,
       COUNT(*) AS review_count,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS review_percentage
FROM order_reviews
GROUP BY review_score
ORDER BY review_score;

-- Query #18: Average Review Score by Product Category
-- Business Question: Which product categories have the highest average customer review scores?
WITH order_category_reviews AS (
    SELECT DISTINCT
        r.order_id,
        r.review_score,
        COALESCE(ct.product_category_name_english, p.product_category_name, 'Unknown') AS category
    FROM order_reviews r
    JOIN order_items oi ON r.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    LEFT JOIN category_translation ct ON p.product_category_name = ct.product_category_name
)
SELECT category,
       COUNT(*) AS reviewed_orders,
       ROUND(AVG(review_score), 2) AS average_review_score
FROM order_category_reviews
GROUP BY category
HAVING COUNT(*) >= 100
ORDER BY average_review_score DESC;


-- =====================================================
-- SECTION 5: DELIVERY & OPERATIONS
-- =====================================================

-- Query #19: Order Status Analysis
-- Business Question: What is the distribution of orders across different order statuses?
SELECT order_status,
       COUNT(*) AS order_count,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS percentage
FROM orders
GROUP BY order_status
ORDER BY order_count DESC;

-- Query #20: Average Delivery Time
-- Business Question: How many days does it take for an order to be delivered to the customer?
SELECT ROUND(
    AVG(EXTRACT(EPOCH FROM (
        order_delivered_customer_date - order_purchase_timestamp
    )) / 86400), 2
) AS average_delivery_days
FROM orders
WHERE order_delivered_customer_date IS NOT NULL;

-- Query #21: Late vs. On-Time Delivery
-- Business Question: What percentage of delivered orders arrived late versus on time?
SELECT CASE
           WHEN order_delivered_customer_date > order_estimated_delivery_date
           THEN 'Late'
           ELSE 'On Time'
       END AS delivery_status,
       COUNT(*) AS order_count,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS percentage
FROM orders
WHERE order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL
GROUP BY 1
ORDER BY order_count DESC;

-- Query #22: Average Delivery Time by State
-- Business Question: Which Brazilian states have the longest average delivery times?
SELECT c.customer_state AS state,
       COUNT(*) AS delivered_orders,
       ROUND(AVG(EXTRACT(EPOCH FROM (
           o.order_delivered_customer_date - o.order_purchase_timestamp
       )) / 86400), 2) AS avg_delivery_days
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state
HAVING COUNT(*) >= 100
ORDER BY avg_delivery_days DESC;

-- Query #23: Review Score vs. Delivery Performance
-- Business Question: Do late deliveries have different customer review scores compared with on-time deliveries?
WITH delivery_reviews AS (
    SELECT r.order_id,
           r.review_score,
           CASE
               WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
               THEN 'Late'
               ELSE 'On Time'
           END AS delivery_status
    FROM orders o
    JOIN order_reviews r ON o.order_id = r.order_id
    WHERE o.order_delivered_customer_date IS NOT NULL
      AND o.order_estimated_delivery_date IS NOT NULL
)
SELECT delivery_status,
       COUNT(DISTINCT order_id) AS reviewed_orders,
       ROUND(
           100.0 * COUNT(DISTINCT order_id)
           / SUM(COUNT(DISTINCT order_id)) OVER (), 2
       ) AS percentage_of_reviewed_orders,
       ROUND(AVG(review_score), 2) AS average_review_score
FROM delivery_reviews
GROUP BY delivery_status
ORDER BY delivery_status;

-- Query #24: Average Review Score by Payment Type
-- Business Question: Do average customer review scores differ by payment method?
WITH order_payment_types AS (
    SELECT DISTINCT order_id, payment_type
    FROM order_payments
)
SELECT opt.payment_type,
       COUNT(DISTINCT r.order_id) AS reviewed_orders,
       ROUND(AVG(r.review_score), 2) AS average_review_score
FROM order_payment_types opt
JOIN order_reviews r ON opt.order_id = r.order_id
GROUP BY opt.payment_type
ORDER BY average_review_score DESC;


-- =====================================================
-- SECTION 6: SELLER ANALYSIS
-- =====================================================

-- Query #25: Top Sellers by Transaction Value
-- Business Question: Which sellers generate the highest transaction value?
SELECT oi.seller_id,
       s.seller_city,
       s.seller_state,
       COUNT(DISTINCT oi.order_id) AS total_orders,
       COUNT(*) AS items_sold,
       ROUND(SUM(oi.price + oi.freight_value), 2) AS transaction_value
FROM order_items oi
JOIN sellers s ON oi.seller_id = s.seller_id
GROUP BY oi.seller_id, s.seller_city, s.seller_state
ORDER BY transaction_value DESC
LIMIT 10;

-- Query #26: Top Sellers by Number of Orders
-- Business Question: Which sellers handle the highest number of orders?
SELECT oi.seller_id,
       s.seller_city,
       s.seller_state,
       COUNT(DISTINCT oi.order_id) AS total_orders,
       COUNT(*) AS items_sold,
       ROUND(SUM(oi.price + oi.freight_value), 2) AS transaction_value
FROM order_items oi
JOIN sellers s ON oi.seller_id = s.seller_id
GROUP BY oi.seller_id, s.seller_city, s.seller_state
ORDER BY total_orders DESC
LIMIT 10;

-- Query #27: Seller Performance by State
-- Business Question: Which Brazilian states have the highest seller activity and transaction value?
SELECT s.seller_state AS state,
       COUNT(DISTINCT s.seller_id) AS total_sellers,
       COUNT(DISTINCT oi.order_id) AS total_orders,
       COUNT(*) AS items_sold,
       ROUND(SUM(oi.price + oi.freight_value), 2) AS transaction_value
FROM sellers s
JOIN order_items oi ON s.seller_id = oi.seller_id
GROUP BY s.seller_state
ORDER BY transaction_value DESC;

-- Query #28: Seller Average Transaction Value
-- Business Question: What is the average transaction value per order for each seller?
SELECT oi.seller_id,
       s.seller_city,
       s.seller_state,
       COUNT(DISTINCT oi.order_id) AS total_orders,
       ROUND(SUM(oi.price + oi.freight_value), 2) AS transaction_value,
       ROUND(
           SUM(oi.price + oi.freight_value) / COUNT(DISTINCT oi.order_id), 2
       ) AS avg_transaction_value
FROM order_items oi
JOIN sellers s ON oi.seller_id = s.seller_id
GROUP BY oi.seller_id, s.seller_city, s.seller_state
HAVING COUNT(DISTINCT oi.order_id) >= 20
ORDER BY avg_transaction_value DESC
LIMIT 10;


-- =====================================================
-- SECTION 7: PRODUCT-LEVEL ANALYSIS
-- =====================================================

-- Query #29: Product Performance Analysis
-- Business Question: Which products generate the highest transaction value and how many units have been sold?
SELECT oi.product_id,
       COALESCE(ct.product_category_name_english, p.product_category_name, 'Unknown') AS category,
       COUNT(*) AS items_sold,
       COUNT(DISTINCT oi.order_id) AS total_orders,
       ROUND(SUM(oi.price + oi.freight_value), 2) AS transaction_value
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
LEFT JOIN category_translation ct ON p.product_category_name = ct.product_category_name
GROUP BY oi.product_id,
         COALESCE(ct.product_category_name_english, p.product_category_name, 'Unknown')
ORDER BY transaction_value DESC
LIMIT 10;

-- Query #30: Top Products by Sales Volume
-- Business Question: Which products are sold in the highest quantities?
SELECT oi.product_id,
       COALESCE(ct.product_category_name_english, p.product_category_name, 'Unknown') AS category,
       COUNT(*) AS items_sold,
       COUNT(DISTINCT oi.order_id) AS total_orders,
       ROUND(SUM(oi.price + oi.freight_value), 2) AS transaction_value
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
LEFT JOIN category_translation ct ON p.product_category_name = ct.product_category_name
GROUP BY oi.product_id,
         COALESCE(ct.product_category_name_english, p.product_category_name, 'Unknown')
ORDER BY items_sold DESC
LIMIT 10;

-- Query #31: Product Price & Freight Analysis
-- Business Question: How do product prices and freight costs compare across product categories?
SELECT COALESCE(ct.product_category_name_english, p.product_category_name, 'Unknown') AS category,
       COUNT(*) AS items_sold,
       ROUND(SUM(oi.price), 2) AS product_value,
       ROUND(SUM(oi.freight_value), 2) AS freight_value,
       ROUND(SUM(oi.price + oi.freight_value), 2) AS transaction_value,
       ROUND(AVG(oi.freight_value), 2) AS avg_freight_per_item
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
LEFT JOIN category_translation ct ON p.product_category_name = ct.product_category_name
GROUP BY COALESCE(ct.product_category_name_english, p.product_category_name, 'Unknown')
ORDER BY transaction_value DESC;


-- =====================================================
-- SECTION 8: CUSTOMER ANALYSIS & RETENTION
-- =====================================================

-- Query #32: Top Customers by Transaction Value
-- Business Question: Which customers have generated the highest transaction value?
SELECT c.customer_unique_id,
       c.customer_city,
       c.customer_state,
       COUNT(DISTINCT o.order_id) AS total_orders,
       COUNT(*) AS items_purchased,
       ROUND(SUM(oi.price + oi.freight_value), 2) AS transaction_value,
       ROUND(
           SUM(oi.price + oi.freight_value) / COUNT(DISTINCT o.order_id), 2
       ) AS avg_transaction_value
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY c.customer_unique_id, c.customer_city, c.customer_state
ORDER BY transaction_value DESC
LIMIT 10;

-- Query #33: New vs Repeat Customer Analysis
-- Business Question: How many customers are new versus repeat customers, and how much transaction value does each group generate?
WITH customer_orders AS (
    SELECT c.customer_unique_id, COUNT(DISTINCT o.order_id) AS total_orders
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id
),
customer_value AS (
    SELECT c.customer_unique_id,
           SUM(oi.price + oi.freight_value) AS transaction_value
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY c.customer_unique_id
)
SELECT CASE
           WHEN co.total_orders = 1 THEN 'New Customer'
           ELSE 'Repeat Customer'
       END AS customer_type,
       COUNT(*) AS total_customers,
       ROUND(SUM(COALESCE(cv.transaction_value, 0)), 2) AS transaction_value,
       ROUND(AVG(COALESCE(cv.transaction_value, 0)), 2) AS avg_customer_transaction_value
FROM customer_orders co
LEFT JOIN customer_value cv ON co.customer_unique_id = cv.customer_unique_id
GROUP BY CASE
             WHEN co.total_orders = 1 THEN 'New Customer'
             ELSE 'Repeat Customer'
         END
ORDER BY transaction_value DESC;

-- Query #34: Average Customer Value by State
-- Business Question: Which Brazilian states have the highest average customer transaction value?
WITH customer_value AS (
    SELECT c.customer_unique_id,
           c.customer_state,
           SUM(oi.price + oi.freight_value) AS transaction_value
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY c.customer_unique_id, c.customer_state
)
SELECT customer_state AS state,
       COUNT(*) AS total_customers,
       ROUND(SUM(transaction_value), 2) AS transaction_value,
       ROUND(AVG(transaction_value), 2) AS avg_customer_value
FROM customer_value
GROUP BY customer_state
HAVING COUNT(*) >= 100
ORDER BY avg_customer_value DESC;

-- Query #35: Monthly Customer Acquisition & Retention
-- Business Question: How does customer acquisition and returning-customer activity change over time?
WITH customer_first_order AS (
    SELECT c.customer_unique_id,
           MIN(o.order_purchase_timestamp) AS first_order_date
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id
),
monthly_customer_activity AS (
    SELECT DISTINCT
           DATE_TRUNC('month', o.order_purchase_timestamp)::date AS month,
           c.customer_unique_id
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
)
SELECT mca.month,
       COUNT(*) AS active_customers,
       COUNT(*) FILTER (
           WHERE DATE_TRUNC('month', cfo.first_order_date)::date = mca.month
       ) AS new_customers,
       COUNT(*) FILTER (
           WHERE DATE_TRUNC('month', cfo.first_order_date)::date < mca.month
       ) AS returning_customers
FROM monthly_customer_activity mca
JOIN customer_first_order cfo
    ON mca.customer_unique_id = cfo.customer_unique_id
GROUP BY mca.month
ORDER BY mca.month;

-- =====================================================
-- END OF OLIST E-COMMERCE SQL ANALYSIS
-- =====================================================
