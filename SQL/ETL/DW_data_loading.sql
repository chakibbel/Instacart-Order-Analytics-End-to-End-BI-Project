-- =====================================================
-- LOADING DIMENSION TABLES
-- =====================================================
USE DWInstacart
GO

-- Loading data into dim_customer
INSERT INTO dim_customer (user_id, total_orders, max_order_number, avg_days_between_orders, first_order_dow, first_order_hour)
SELECT 
    user_id,
    COUNT(DISTINCT order_id) as total_orders,
    MAX(order_number) as max_order_number,
    AVG(days_since_prior) as avg_days_between_orders,
    MIN(order_dow) as first_order_dow,
    MIN(order_hour_of_day) as first_order_hour
FROM [instacart_raw].[dbo].[orders_clean]
WHERE user_id IS NOT NULL
GROUP BY user_id;

-- Loading data into dim_product
INSERT INTO dim_product (product_id, product_name, aisle_id, aisle, department_id, department, is_organic)
SELECT 
    p.product_id,
    p.product_name,
    p.aisle_id,
    a.aisle,
    p.department_id,
    d.department,
    CASE 
        WHEN LOWER(p.product_name) LIKE '%organic%' THEN 1 
        ELSE 0 
    END as is_organic
FROM [instacart_raw].[dbo].[products_clean] p
LEFT JOIN [instacart_raw].[dbo].[aisles_clean] a ON p.aisle_id = a.aisle_id
LEFT JOIN [instacart_raw].[dbo].[departments_clean] d ON p.department_id = d.department_id;

-- Loading data into dim_date
INSERT INTO dim_date (order_id, order_dow, day_name, is_weekend)
SELECT DISTINCT
    order_id,
    order_dow,
    CASE order_dow
        WHEN 0 THEN 'Sunday'
        WHEN 1 THEN 'Monday'
        WHEN 2 THEN 'Tuesday'
        WHEN 3 THEN 'Wednesday'
        WHEN 4 THEN 'Thursday'
        WHEN 5 THEN 'Friday'
        WHEN 6 THEN 'Saturday'
    END as day_name,
    CASE 
        WHEN order_dow IN (0, 6) THEN 1 
        ELSE 0 
    END as is_weekend
FROM [instacart_raw].[dbo].[orders_clean]

-- Loading data into dim_time
INSERT INTO dim_time (hour_of_day, time_period, is_peak_hour)
SELECT DISTINCT
    order_hour_of_day as hour_of_day,
    CASE 
        WHEN order_hour_of_day BETWEEN 6 AND 11 THEN 'Morning'
        WHEN order_hour_of_day BETWEEN 12 AND 17 THEN 'Afternoon'
        WHEN order_hour_of_day BETWEEN 18 AND 21 THEN 'Evening'
        ELSE 'Night'
    END as time_period,
    CASE 
        WHEN order_hour_of_day BETWEEN 10 AND 15 THEN 1 
        ELSE 0 
    END as is_peak_hour
FROM [instacart_raw].[dbo].[orders_clean]
ORDER BY hour_of_day;

-- Loading data into dim_aisle
INSERT INTO dim_aisle (aisle_id, aisle)
SELECT 
    aisle_id,
    aisle
FROM [instacart_raw].[dbo].[aisles_clean];

-- Loading data into dim_department
INSERT INTO dim_department (department_id, department)
SELECT 
    department_id,
    department
FROM [instacart_raw].[dbo].[departments_clean];

-- =====================================================
-- LOADING DATA INTO FACT TABLES 
-- =====================================================

-- Loading data into fact_order_details
INSERT INTO fact_order_details (
    order_id, customer_key, product_key, date_key, time_key,
    order_number, days_since_prior, add_to_cart_order, reordered, eval_set,
    product_quantity, is_reordered, is_first_order
)
SELECT 
    op.order_id,
    dc.customer_key,
    dp.product_key,
    dd.date_key,
    dt.time_key,
    o.order_number,
    o.days_since_prior,
    op.add_to_cart_order,
    op.reordered,
    o.eval_set,
    1 as product_quantity,
    CASE WHEN op.reordered = 1 THEN 1 ELSE 0 END as is_reordered,
    CASE WHEN o.order_number = 1 THEN 1 ELSE 0 END as is_first_order
FROM [instacart_raw].[dbo].[order_products_clean] op
INNER JOIN [instacart_raw].[dbo].[orders_clean] o ON op.order_id = o.order_id
INNER JOIN dim_customer dc ON o.user_id = dc.user_id
INNER JOIN dim_product dp ON op.product_id = dp.product_id
INNER JOIN dim_date dd ON o.order_id = dd.order_id
INNER JOIN dim_time dt ON o.order_hour_of_day = dt.hour_of_day;

-- Loading data into fact_order_summary
INSERT INTO fact_order_summary (
    order_id, customer_key, date_key, time_key,
    order_number, days_since_prior, eval_set,
    total_products, total_items, reordered_items,
    avg_add_to_cart_order, basket_size, reorder_ratio
)
SELECT 
    o.order_id,
    dc.customer_key,
    dd.date_key,
    dt.time_key,
    o.order_number,
    o.days_since_prior,
    o.eval_set,
    COUNT(DISTINCT op.product_id) as total_products,
    COUNT(*) as total_items,
    SUM(op.reordered) as reordered_items,
    AVG(op.add_to_cart_order) as avg_add_to_cart_order,
    MAX(op.add_to_cart_order) as basket_size,
    CASE 
        WHEN COUNT(*) > 0 THEN CAST(SUM(op.reordered) AS FLOAT) / COUNT(*) 
        ELSE 0 
    END as reorder_ratio
FROM [instacart_raw].[dbo].[orders_clean] o
INNER JOIN dim_customer dc ON o.user_id = dc.user_id
INNER JOIN dim_date dd ON o.order_id = dd.order_id
INNER JOIN dim_time dt ON o.order_hour_of_day = dt.hour_of_day
LEFT JOIN [instacart_raw].[dbo].[order_products_clean] op ON o.order_id = op.order_id
GROUP BY 
    o.order_id, dc.customer_key, dd.date_key, dt.time_key,
    o.order_number, o.days_since_prior, o.eval_set;
