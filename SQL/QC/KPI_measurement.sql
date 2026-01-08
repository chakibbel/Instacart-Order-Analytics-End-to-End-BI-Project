USE DWInstacart
GO

-- =====================================================
-- KPIs Calculations 
-- =====================================================


/* -----------------------------------------------------
🎯 A. CUSTOMER BEHAVIOR KPIs
------------------------------------------------------*/

/* Total number of customers */
SELECT COUNT(DISTINCT user_id) AS TOTAL_CUSTOMER
FROM dim_customer
GO

/* Returning  customers rate */
SELECT COUNT(user_id) *100 / 
	(SELECT COUNT(user_id) FROM dim_customer)  AS [returning_customer_rate %]
FROM dim_customer 
WHERE total_orders > 1
GO

/* Average Days Between Orders*/
SELECT 
    ROUND(AVG(avg_days_between_orders),2) as avg_days_between_orders,
    ROUND(COUNT(CASE WHEN avg_days_between_orders <= 7 THEN 1 END)* 100.0 / COUNT(*),2)  as weekly_shoppers_pct,
    ROUND(COUNT(CASE WHEN avg_days_between_orders <= 14 THEN 1 END)* 100.0 / COUNT(*),2)  as biweekly_shoppers_pct
FROM dim_customer
WHERE avg_days_between_orders IS NOT NULL;

/* Most Frequent Ordering Day */
SELECT first_order_dow, COUNT(first_order_dow) AS cnt
FROM dim_customer
GROUP BY first_order_dow
ORDER BY cnt DESC
GO

/* Customer Lifetime Value Proxy (Total Orders per Customer) */
SELECT 
    c.user_id,
    SUM(f.basket_size) AS total_items_purchased,
    COUNT(f.order_id) AS order_count,
    AVG(f.reordered_items) AS reorder_ratio,
    SUM(f.basket_size) * COUNT(f.order_id) * AVG(f.reordered_items) AS clv_proxy
FROM fact_order_summary f
JOIN dim_customer c ON c.customer_key = f.customer_key
GROUP BY c.user_id;

/* Customer Segmentation Distribution */
SELECT 
    CASE 
        WHEN total_orders >= 100 THEN '1. VIP (100+ orders)'
        WHEN total_orders >= 50 THEN '2. Loyal (50-99 orders)'
        WHEN total_orders >= 20 THEN '3. Regular (20-49 orders)'
        WHEN total_orders >= 5 THEN '4. Occasional (5-19 orders)'
        ELSE '5. New (1-4 orders)'
    END as customer_segment,
    COUNT(*) as customer_count,
    COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() as pct_of_customers,
    AVG(avg_days_between_orders) as avg_days_between_orders,
    AVG(total_orders) as avg_orders_in_segment
FROM dim_customer
GROUP BY 
    CASE 
        WHEN total_orders >= 100 THEN '1. VIP (100+ orders)'
        WHEN total_orders >= 50 THEN '2. Loyal (50-99 orders)'
        WHEN total_orders >= 20 THEN '3. Regular (20-49 orders)'
        WHEN total_orders >= 5 THEN '4. Occasional (5-19 orders)'
        ELSE '5. New (1-4 orders)'
    END
ORDER BY customer_segment;


/* -----------------------------------------------------
 🛒 B. ORDERING PATTERNS (USING fact_order_summary)
------------------------------------------------------*/

/* Total Orders */
SELECT COUNT(*) AS total_orders
FROM fact_order_summary
GO

/* Orders by Day of Week */
SELECT dd.day_name, count(fs.order_id) as total_orders
FROM fact_order_summary fs
JOIN dim_date dd ON (fs.date_key = dd.date_key)
GROUP BY dd.day_name
ORDER BY total_orders DESC
GO

/* Orders by Hour */
SELECT dt.hour_of_day, count(fs.order_id) as total_orders
FROM fact_order_summary fs
JOIN dim_time dt ON (fs.time_key = dt.time_key)
GROUP BY dt.hour_of_day
ORDER BY total_orders DESC
GO

/* Weekend vs Weekday Order Split */
SELECT dd.is_weekend, count(fs.order_id) as total_orders
FROM fact_order_summary fs
JOIN dim_date dd ON (fs.date_key = dd.date_key)
GROUP BY dd.is_weekend
ORDER BY total_orders DESC
GO

/* -----------------------------------------------------
 📦 C. PRODUCT-LEVEL KPIs
------------------------------------------------------*/

/* Top 10 Best-Selling Products */
SELECT TOP 10 
    p.product_name,
    SUM(f.product_quantity) AS total_quantity
FROM dbo.fact_order_details f
JOIN dbo.dim_product p ON p.product_key = f.product_key
GROUP BY p.product_name
ORDER BY total_quantity DESC;

/* Most Reordered Products */
SELECT TOP 10
    p.product_name,
    SUM(CASE WHEN f.is_reordered = 1 THEN 1 ELSE 0 END) AS total_reorders
FROM dbo.fact_order_details f
JOIN dbo.dim_product p ON p.product_key = f.product_key
GROUP BY p.product_name
ORDER BY total_reorders DESC;

/* Organic vs Non-Organic Product Share */
SELECT
	(CASE WHEN p.is_organic = 1 THEN 'Organic' ELSE 'Not Organic' END) AS [Is Organic], 
	SUM(f.product_quantity) as total_sold
FROM fact_order_details f
JOIN dim_product p ON p.product_key = f.product_key
GROUP BY p.is_organic

/* Department-Level Order Distribution */
SELECT d.[department], COUNT(f.order_id) AS total_orders
FROM [dbo].[fact_order_details] f
JOIN [dbo].[dim_product] p ON (f.[product_key] = p.[product_key])
JOIN [dbo].[dim_department] d ON (p.[department_id] = d.[department_id])
GROUP BY d.[department]
ORDER BY total_orders DESC
GO

/* -----------------------------------------------------
🧺 D. BASKET / ORDER VALUE KPIs
------------------------------------------------------*/

/* Average Basket Size*/
SELECT AVG([basket_size]) AS avg_basket_size
FROM [dbo].[fact_order_summary]
GO

/* Average Number of Products per Order */
SELECT AVG([total_products]) AS avg_products_per_order
FROM [dbo].[fact_order_summary]
GO

/* Reorder Ratio */
SELECT SUM([reordered_items]) * 100 / SUM([total_items]) AS [reodered_ratio_%]
FROM [dbo].[fact_order_summary]
GO

/* Basket Distribution */
SELECT 
    CASE 
        WHEN total_items = 1 THEN '1. Single Item'
        WHEN total_items BETWEEN 2 AND 5 THEN '2. Small (2-5 items)'
        WHEN total_items BETWEEN 6 AND 15 THEN '3. Medium (6-15 items)'
        WHEN total_items BETWEEN 16 AND 30 THEN '4. Large (16-30 items)'
        ELSE '5. Extra Large (31+ items)'
    END as basket_size_category,
    COUNT(*) as order_count,
    COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() as pct_of_orders,
    AVG(total_items) as avg_items,
    AVG(reorder_ratio) * 100 as avg_reorder_ratio_pct
FROM fact_order_summary
GROUP BY 
    CASE 
        WHEN total_items = 1 THEN '1. Single Item'
        WHEN total_items BETWEEN 2 AND 5 THEN '2. Small (2-5 items)'
        WHEN total_items BETWEEN 6 AND 15 THEN '3. Medium (6-15 items)'
        WHEN total_items BETWEEN 16 AND 30 THEN '4. Large (16-30 items)'
        ELSE '5. Extra Large (31+ items)'
    END
ORDER BY basket_size_category;

/* -----------------------------------------------------
⏳ E. TIME-INTELLIGENCE KPIs
------------------------------------------------------*/

/* Peak Ordering Hour */
SELECT TOP 1
	t.hour_of_day, 
	COUNT(f.order_id) AS total_orders
FROM [dbo].[fact_order_details] f
JOIN [dbo].[dim_time] t ON (f.time_key = t.time_key)
GROUP BY t.hour_of_day
ORDER BY total_orders DESC
GO

/* Peak Ordering Day */
SELECT TOP 1
	d.[day_name], 
	COUNT(f.order_id) AS total_orders
FROM [dbo].[fact_order_details] f
JOIN [dbo].[dim_date] d ON (f.[date_key] = d.[date_key])
GROUP BY d.[day_name]
ORDER BY total_orders DESC
GO

/*  */