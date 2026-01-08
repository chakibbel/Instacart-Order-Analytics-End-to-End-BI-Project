USE instacart_raw
GO

/*** Create and load clean tables  ***/

SELECT *
INTO [dbo].[departments_clean]
FROM [dbo].[staging_departments_raw];

SELECT *
INTO [dbo].[order_products_clean]
FROM [dbo].[staging_order_products_raw];

SELECT *
INTO [dbo].[orders_clean]
FROM [dbo].[staging_orders_raw];

SELECT *
INTO [dbo].[products_clean]
FROM [dbo].[staging_products_raw];

/***  QC orders_clean ***/

-- QC1.3 - Check invalid order_hour_of_day or negative days_since_prior
SELECT *
FROM orders_clean
WHERE order_hour_of_day NOT BETWEEN 0 AND 23
   OR (days_since_prior IS NOT NULL AND days_since_prior < 0); -- Returned no values as desired



