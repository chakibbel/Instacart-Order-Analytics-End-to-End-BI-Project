USE DWInstacart
GO

-- =====================================================
-- DIMENSION TABLES CREATION
-- =====================================================

-- Dimension: Customer
-- Contains customer-level attributes and ordering behavior
CREATE TABLE dim_customer (
    customer_key INT IDENTITY PRIMARY KEY,
    user_id INTEGER NOT NULL UNIQUE,
    total_orders INTEGER,
    max_order_number INTEGER,
    avg_days_between_orders REAL,
    first_order_dow INTEGER,
    first_order_hour INTEGER,
);

-- Dimension: Product
-- Contains product hierarchy with aisle and department
CREATE TABLE dim_product (
    product_key INTEGER IDENTITY PRIMARY KEY,
    product_id INTEGER NOT NULL UNIQUE,
    product_name TEXT,
    aisle_id INTEGER,
    aisle TEXT,
    department_id INTEGER,
    department TEXT,
    is_organic INTEGER,
);

-- Dimension: Date
-- Date dimension for temporal analysis
CREATE TABLE dim_date (
    date_key INTEGER IDENTITY PRIMARY KEY,
    order_id INTEGER NOT NULL UNIQUE,
    order_dow INTEGER,
    day_name TEXT,
    is_weekend INTEGER
);

-- Dimension: Time
-- Time of day dimension for hourly analysis
CREATE TABLE dim_time (
    time_key INTEGER IDENTITY PRIMARY KEY,
    hour_of_day INTEGER NOT NULL UNIQUE,
    time_period TEXT,
    is_peak_hour INTEGER
);

-- Dimension: Aisle
-- Standalone aisle dimension for detailed analysis
CREATE TABLE dim_aisle (
    aisle_key INTEGER IDENTITY PRIMARY KEY,
    aisle_id INTEGER NOT NULL UNIQUE,
    aisle TEXT
);

-- Dimension: Department
-- Standalone department dimension for high-level analysis
CREATE TABLE dim_department (
    department_key INTEGER IDENTITY PRIMARY KEY,
    department_id INTEGER NOT NULL UNIQUE,
    department TEXT
);

-- =====================================================
-- FACT TABLES (WITH SURROGATE KEY REFERENCES)
-- =====================================================

-- Fact Table: Order Details (Main Fact Table)
-- Granularity: One row per product per order
CREATE TABLE fact_order_details (
    order_detail_key INTEGER IDENTITY PRIMARY KEY,
    order_id INTEGER NOT NULL,
    customer_key INTEGER NOT NULL,
    product_key INTEGER NOT NULL,
    date_key INTEGER NOT NULL,
    time_key INTEGER NOT NULL,
    order_number INTEGER,
    days_since_prior INTEGER,
    add_to_cart_order INTEGER,
    reordered INTEGER,
    eval_set TEXT,
    product_quantity INTEGER,
    is_reordered INTEGER,
    is_first_order INTEGER,

-- Add FOREIGN KEY constraints
FOREIGN KEY (customer_key) REFERENCES dim_customer(customer_key),
FOREIGN KEY (product_key) REFERENCES dim_product(product_key),
FOREIGN KEY (date_key) REFERENCES dim_date(date_key),
FOREIGN KEY (time_key) REFERENCES dim_time(time_key)
);

-- Fact Table: Order Summary (Aggregated Fact Table)
-- Granularity: One row per order
CREATE TABLE fact_order_summary (
    order_summary_key INTEGER IDENTITY PRIMARY KEY,
    order_id INTEGER NOT NULL UNIQUE,
    customer_key INTEGER NOT NULL,
    date_key INTEGER NOT NULL,
    time_key INTEGER NOT NULL,
    order_number INTEGER,
    days_since_prior INTEGER,
    eval_set TEXT,
    total_products INTEGER,
    total_items INTEGER,
    reordered_items INTEGER,
    avg_add_to_cart_order REAL,
    basket_size INTEGER,
    reorder_ratio REAL,
    FOREIGN KEY (customer_key) REFERENCES dim_customer(customer_key),
    FOREIGN KEY (date_key) REFERENCES dim_date(date_key),
    FOREIGN KEY (time_key) REFERENCES dim_time(time_key)
);



