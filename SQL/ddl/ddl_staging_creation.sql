use instacart_raw;
go

-- Staging orders 
create table staging_orders_raw (
  order_id bigint primary key,  -- order identifier
  user_id bigint, --customer identifier
  eval_set varchar(20), --which evaluation set this order belongs in (see SET described below)
  order_number int,  --the order sequence number for this user (1 = first, n = nth)
  order_dow int, --the day of the week the order was placed on
  order_hour_of_day int, --the hour of the day the order was placed on
  days_since_prior int --days since the last order, capped at 30 (with NAs for order_number = 1)
);

-- Staging products
	create table staging_products_raw (
	product_id int primary key,  -- product identifier
	product_name nvarchar(max),  --name of the product
	aisle_id int, --foreign key
	department_id int --foreign key
);

-- Staging aisles
create table staging_aisles_raw (
	aisle_id int primary key,  --aisle identifier
	aisle varchar(200)   --the name of the aisle
);

-- Staging departments
create table staging_departments_raw (
	department_id int primary key,    --department identifier
	department varchar(200)    --the name of the department
);

-- Staging order_products
create table staging_order_products_raw (
	order_id int,	--foreign key
	product_id int,	--foreign key
	add_to_cart_order int,	--order in which each product was added to cart
	reordered int		--1 if this product has been ordered by this user in the past, 0 otherwise where SET is one of the four following evaluation sets (eval_set in orders)
);