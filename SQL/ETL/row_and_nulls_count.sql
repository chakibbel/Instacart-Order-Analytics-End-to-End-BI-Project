use instacart_raw
go

select COUNT(aisle)  as numbre_of_rows
from staging_aisles_raw;

select COUNT(DISTINCT aisle) as count_distinct
from staging_aisles_raw;


/*** Checking for NULL values ***/

-- Table staging_orders_raw
SELECT 
	SUM(CASE WHEN [order_id] IS NULL then 1 else 0 end) as order_id_nulls,
	SUM(CASE WHEN [user_id] IS NULL then 1 else 0 end) as user_id_nulls,
	SUM(CASE WHEN [eval_set] IS NULL then 1 else 0 end) as eval_set_nulls,
	SUM(CASE WHEN [order_number] IS NULL then 1 else 0 end) as order_number_nulls,
	SUM(CASE WHEN [order_dow] IS NULL then 1 else 0 end) as order_dow_nulls,
	SUM(CASE WHEN [order_hour_of_day] IS NULL then 1 else 0 end) as order_hour_of_day_nulls,
	SUM(CASE WHEN [days_since_prior] IS NULL then 1 else 0 end) as days_since_prior_nulls
from [staging_orders_raw];

-- Table staging_aisles_raw
SELECT 
	SUM(CASE WHEN [aisle_id] IS NULL then 1 else 0 end) as aisle_id_nulls,
	SUM(CASE WHEN [aisle] IS NULL then 1 else 0 end) as aisle_nulls
from [staging_aisles_raw];

-- Table staging_departments_raw
SELECT 
	SUM(CASE WHEN [department_id] IS NULL then 1 else 0 end) as department_id_nulls,
	SUM(CASE WHEN [department] IS NULL then 1 else 0 end) as department_nulls
from [staging_departments_raw];

-- Table staging_order_products_raw
SELECT 
	SUM(CASE WHEN [order_id] IS NULL then 1 else 0 end) as order_id_nulls,
	SUM(CASE WHEN [product_id] IS NULL then 1 else 0 end) as product_id_nulls,
	SUM(CASE WHEN [add_to_cart_order] IS NULL then 1 else 0 end) as add_to_cart_order_nulls,
	SUM(CASE WHEN [reordered] IS NULL then 1 else 0 end) as reordered_nulls
from [staging_order_products_raw];

-- staging_products_raw
SELECT 
	SUM(CASE WHEN [product_id] IS NULL then 1 else 0 end) as product_id_nulls,
	SUM(CASE WHEN [product_name] IS NULL then 1 else 0 end) as product_name_nulls,
	SUM(CASE WHEN [aisle_id] IS NULL then 1 else 0 end) as aisle_id_nulls,
	SUM(CASE WHEN [department_id] IS NULL then 1 else 0 end) as department_id_nulls
from [staging_products_raw];